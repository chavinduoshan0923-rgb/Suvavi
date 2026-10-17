import json;
import os;
import urllib.request;
import from services.carepathService { DoctorProfile, get_triage_guidance }

# Emergency phrases are checked in code BEFORE the AI is called.
glob RED_FLAGS: list[str] = [
    "chest pain", "can't breathe", "cannot breathe", "trouble breathing",
    "difficulty breathing", "shortness of breath", "severe bleeding", "unconscious",
    "fainted", "stroke", "face drooping", "weakness on one side", "slurred speech",
    "seizure", "coughing blood", "vomiting blood", "overdose", "suicidal"
];

def build_system_prompt(doctors: list[DoctorProfile], specialties: list[str]) -> str {
    lines = "";
    for d in doctors {
        lines = lines + "- " + d.full_name + " | " + d.specialty + " | " + d.hospital + "\n";
    }
    if lines == "" { lines = "(no doctors are listed yet)\n"; }
    spec_text = ", ".join(specialties);
    if spec_text == "" { spec_text = "General Physician"; }

    return "You are the Carepath care assistant inside a hospital patient portal. "
        + "Your job: understand the patient's symptoms through a short conversation, say what conditions could plausibly explain them, and recommend the correct specialist.\n\n"
        + "ABOUT THIS SITE (Carepath patient portal):\n"
        + "- Patients sign in, complete a profile (intake), and use the Overview page, the Appointments page and the Lab results page.\n"
        + "- Appointments page: choose an available doctor, add a short symptom summary, then book. Booked visits can be cancelled there.\n"
        + "- Overview page: this chat, plus quick booking for a consultation or a lab test.\n"
        + "- Lab results page: lab staff upload results; patients download them as text files.\n"
        + "- Reminders and confirmations are sent by WhatsApp.\n\n"
        + "DOCTORS CURRENTLY AVAILABLE (name | specialty | hospital):\n" + lines + "\n"
        + "SPECIALTIES YOU MAY RECOMMEND (use the exact spelling): " + spec_text + "\n\n"
        + "RULES:\n"
        + "1. If the symptoms are unclear, ask at most two short follow-up questions (how long, how severe, other symptoms, age group). After the patient answers, or when the first message is already clear, give your assessment.\n"
        + "2. In your assessment list up to 3 possible conditions that could explain the symptoms, in plain language, using wording like 'could be consistent with'. Never state a definite diagnosis, never prescribe medicines or doses.\n"
        + "3. Recommend exactly ONE specialty from the list above. If nothing fits, recommend General Physician if listed, otherwise leave specialty empty and say no suitable doctor is listed yet.\n"
        + "4. If symptoms could be life-threatening, set urgency to emergency and tell the patient to go to the nearest emergency department or call their local emergency number now.\n"
        + "5. Tell the patient they can book on the Appointments page. Keep replies under 120 words, warm and clear, English only.\n"
        + "6. Only discuss health concerns and this portal. Politely decline anything else.\n\n"
        + "Respond with ONLY a JSON object, no markdown fences, in exactly this shape:\n"
        + "{\"reply\": \"text shown to the patient\", \"specialty\": \"one specialty from the list or empty string\", "
        + "\"urgency\": \"routine or soon or urgent or emergency\", \"possible_conditions\": [\"condition\"]}";
}

def call_gemini(system_text: str, turns: list[dict]) -> str {
    key = os.environ.get("GEMINI_API_KEY", "");
    if key == "" { raise Exception("GEMINI_API_KEY is not set on the server"); }
    model = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash");

    contents = [];
    for t in turns {
        role = "user" if t["role"] == "user" else "model";
        contents.append({"role": role, "parts": [{"text": t["text"]}]});
    }
    payload = {
        "systemInstruction": {"parts": [{"text": system_text}]},
        "contents": contents,
        "generationConfig": {"temperature": 0.3, "maxOutputTokens": 2048, "responseMimeType": "application/json"}
    };
    headers = {"Content-Type": "application/json"};
    # Keys starting with "AQ." are Vertex AI express-mode keys; others are Google AI Studio keys.
    if key.startswith("AQ.") {
        url = "https://aiplatform.googleapis.com/v1/publishers/google/models/" + model + ":generateContent?key=" + key;
    } else {
        url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent";
        headers["x-goog-api-key"] = key;
    }
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers, method="POST");
    resp = urllib.request.urlopen(req, timeout=25);
    data = json.loads(resp.read().decode());
    return data["candidates"][0]["content"]["parts"][0]["text"];
}

def parse_model_json(raw: str) -> dict {
    text = raw.strip();
    if text.startswith("```") {
        text = text.strip("`");
        if text.startswith("json") { text = text[4:]; }
    }
    return json.loads(text.strip());
}

def:priv chat_with_assistant(messages: list[dict]) -> dict {
    doctors = [root.shared -->][?:DoctorProfile];
    specialties: list[str] = [];
    for d in doctors {
        if d.specialty not in specialties { specialties.append(d.specialty); }
    }

    last_user = "";
    for m in messages {
        if m["role"] == "user" { last_user = str(m["text"]); }
    }
    lowered = last_user.lower();
    for flag in RED_FLAGS {
        if flag in lowered {
            return {
                "reply": "Your symptoms may be serious. Please go to the nearest emergency department or call your local emergency number now. Do not wait for an appointment.",
                "specialty": "", "urgency": "emergency", "emergency": True,
                "doctors": [], "possible_conditions": [], "source": "rules", "error": ""
            };
        }
    }

    # Keep the last 12 turns; Gemini requires the first turn to be from the user.
    turns: list[dict] = [];
    for m in messages[-12:] {
        if len(turns) == 0 and m["role"] != "user" { continue; }
        turns.append({"role": str(m["role"]), "text": str(m["text"])[:1500]});
    }

    try {
        raw = call_gemini(build_system_prompt(doctors, specialties), turns);
        data = parse_model_json(raw);

        specialty = "";
        wanted = str(data.get("specialty", "")).strip().lower();
        for s in specialties {
            if s.lower() == wanted { specialty = s; }
        }
        urgency = str(data.get("urgency", "routine")).lower();
        matches = [{"name": d.full_name, "hospital": d.hospital} for d in doctors if d.specialty == specialty and specialty != ""];
        return {
            "reply": str(data.get("reply", "")),
            "specialty": specialty,
            "urgency": urgency,
            "emergency": urgency == "emergency",
            "doctors": matches,
            "possible_conditions": data.get("possible_conditions", []),
            "source": "ai",
            "error": ""
        };
    } except Exception as e {
        fallback = get_triage_guidance(last_user);
        specialty = "";
        wanted = str(fallback["specialty"]).lower();
        for s in specialties {
            if s.lower() == wanted { specialty = s; }
        }
        matches = [{"name": d.full_name, "hospital": d.hospital} for d in doctors if d.specialty == specialty and specialty != ""];
        return {
            "reply": "I couldn't reach the AI assistant just now, so here is a basic suggestion from keywords. " + str(fallback["message"]),
            "specialty": specialty,
            "urgency": "emergency" if fallback["emergency"] else "routine",
            "emergency": fallback["emergency"],
            "doctors": matches,
            "possible_conditions": [],
            "source": "fallback",
            "error": str(e)[:160]
        };
    }
}
