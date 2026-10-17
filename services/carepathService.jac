import os;
import uuid;
import from datetime { datetime }

node Appointment {
    has patient: str = "Alex Morgan";
    has doctor: str = "Dr. Maya Chen";
    has specialty: str = "Cardiology";
    has place: str = "Northside Medical Center";
    has when: str = "Friday, October 24 · 11:30 AM";
    has kind: str = "Consultation";
    has slot_key: str = "consultation-friday-1130";
    has symptoms: str = "";
    has status: str = "Confirmed";
}

# Private copy of a patient's profile (lives under the patient's own root).
node PatientProfile {
    has full_name: str = "";
    has date_of_birth: str = "";
    has phone: str = "";
    has email: str = "";
    has address: str = "";
    has medical_notes: str = "";
    has username: str = "";
    has shared_key: str = "";
}

# Copy of the profile in the shared graph so the administrator can view it.
node PatientDirectoryEntry {
    has shared_key: str = "";
    has username: str = "";
    has full_name: str = "";
    has date_of_birth: str = "";
    has phone: str = "";
    has email: str = "";
    has address: str = "";
    has medical_notes: str = "";
}

node DoctorProfile {
    has full_name: str = "";
    has specialty: str = "General Medicine";
    has hospital: str = "Northside Medical Center";
    has username: str = "";
}

node LabStaffProfile {
    has full_name: str = "";
    has hospital: str = "Northside Medical Center";
    has username: str = "";
}

node LabResult {
    has patient: str = "";
    has test_name: str = "";
    has completed_at: str = "";
    has result_text: str = "";
}


# ---------------------------------------------------------------
# Patient
# ---------------------------------------------------------------
def:priv save_patient_intake(username: str, full_name: str, date_of_birth: str, phone: str, email: str, address: str, medical_notes: str) -> dict {
    if username.strip() == "" or full_name.strip() == "" or date_of_birth.strip() == "" or phone.strip() == "" or email.strip() == "" or address.strip() == "" {
        return {"ok": False, "message": "Complete all required fields before continuing."};
    }
    profiles = [root -->][?:PatientProfile];
    key = "";
    if len(profiles) > 0 {
        profile = profiles[0];
        profile.full_name = full_name;
        profile.date_of_birth = date_of_birth;
        profile.phone = phone;
        profile.email = email;
        profile.address = address;
        profile.medical_notes = medical_notes;
        profile.username = username;
        if profile.shared_key == "" { profile.shared_key = str(uuid.uuid4()); }
        key = profile.shared_key;
    } else {
        key = str(uuid.uuid4());
        root ++> PatientProfile(username=username, full_name=full_name, date_of_birth=date_of_birth, phone=phone, email=email, address=address, medical_notes=medical_notes, shared_key=key);
    }

    found = False;
    for entry in [root.shared -->][?:PatientDirectoryEntry] {
        if entry.shared_key == key {
            entry.username = username;
            entry.full_name = full_name;
            entry.date_of_birth = date_of_birth;
            entry.phone = phone;
            entry.email = email;
            entry.address = address;
            entry.medical_notes = medical_notes;
            found = True;
        }
    }
    if not found {
        entry = root.shared ++> PatientDirectoryEntry(shared_key=key, username=username, full_name=full_name, date_of_birth=date_of_birth, phone=phone, email=email, address=address, medical_notes=medical_notes);
        _ = grant(entry, level=ReadPerm);
    }
    return {"ok": True, "message": "Patient details saved."};
}


def:pub get_triage_guidance(symptoms: str) -> dict {
    text = symptoms.lower();
    emergency = "chest pain" in text or "trouble breathing" in text or "shortness of breath" in text or "stroke" in text or "face drooping" in text or "weakness on one side" in text or "slurred speech" in text;
    if emergency {
        return {"emergency": True, "message": "Your symptoms may need urgent attention. Please seek emergency care now.", "specialty": "Emergency care"};
    }
    specialty = "General Physician";
    if "skin" in text or "rash" in text { specialty = "Dermatology"; }
    elif "heart" in text or "chest" in text { specialty = "Cardiology"; }
    elif "joint" in text or "bone" in text { specialty = "Orthopedics"; }
    elif "eye" in text or "vision" in text { specialty = "Ophthalmology"; }
    elif "stomach" in text or "digest" in text { specialty = "Gastroenterology"; }
    return {"emergency": False, "message": "Suggested specialty: " + specialty, "specialty": specialty};
}


def:priv get_patient_dashboard() -> list[Appointment] {
    matches: list[Appointment] = [];
    profiles = [root -->][?:PatientProfile];
    if len(profiles) == 0 { return matches; }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.patient == profiles[0].full_name { matches = matches + [appointment]; }
    }
    return matches;
}


def:priv get_patient_profile() -> PatientProfile | None {
    profiles = [root -->][?:PatientProfile];
    if len(profiles) > 0 { return profiles[0]; }
    return None;
}


def:priv list_patient_appointments() -> list[Appointment] {
    matches: list[Appointment] = [];
    profiles = [root -->][?:PatientProfile];
    if len(profiles) == 0 { return matches; }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.patient == profiles[0].full_name { matches = matches + [appointment]; }
    }
    return matches;
}


# Lab results are written by lab staff into the shared graph; a patient sees
# the ones whose patient name matches their profile.
def:priv list_patient_lab_results() -> list[LabResult] {
    matches: list[LabResult] = [];
    profiles = [root -->][?:PatientProfile];
    if len(profiles) == 0 { return matches; }
    for result in [root.shared -->][?:LabResult] {
        if result.patient == profiles[0].full_name { matches = matches + [result]; }
    }
    return matches;
}


def:pub list_doctors() -> list[DoctorProfile] {
    return [root.shared -->][?:DoctorProfile];
}


def:priv book_appointment(doctor: str, specialty: str, place: str, when: str, kind: str, slot_key: str, symptoms: str) -> dict {
    profiles = [root -->][?:PatientProfile];
    if len(profiles) == 0 { return {"ok": False, "message": "Complete your patient profile before booking."}; }
    patient = profiles[0].full_name;
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.slot_key == slot_key and appointment.status == "Confirmed" {
            return {"ok": False, "message": "That time was just booked. Please choose another slot."};
        }
    }
    appointment = root.shared ++> Appointment(patient=patient, doctor=doctor, specialty=specialty, place=place, when=when, kind=kind, slot_key=slot_key, symptoms=symptoms);
    # WritePerm so doctors, lab staff and the administrator can update status.
    _ = grant(appointment, level=WritePerm);
    return {"ok": True, "message": "Appointment confirmed."};
}


def:priv cancel_appointment(appointment_id: str) -> dict {
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.slot_key == appointment_id and appointment.status == "Confirmed" {
            appointment.status = "Cancelled";
            return {"ok": True, "message": "Appointment cancelled."};
        }
    }
    return {"ok": False, "message": "Appointment was not found or is already cancelled."};
}


# ---------------------------------------------------------------
# Doctor
# ---------------------------------------------------------------
def:priv verify_doctor_user(username: str) -> bool {
    for doctor in [root.shared -->][?:DoctorProfile] {
        if doctor.username == username { return True; }
    }
    return False;
}


def:priv get_doctor_dashboard(doctor_username: str) -> list[Appointment] {
    matches: list[Appointment] = [];
    doctor_name = "";
    for doctor in [root.shared -->][?:DoctorProfile] {
        if doctor.username == doctor_username { doctor_name = doctor.full_name; }
    }
    if doctor_name == "" { return matches; }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.doctor == doctor_name and appointment.status == "Confirmed" {
            matches = matches + [appointment];
        }
    }
    return matches;
}


# ---------------------------------------------------------------
# Lab staff
# ---------------------------------------------------------------
def:priv verify_lab_user(username: str) -> bool {
    for staff in [root.shared -->][?:LabStaffProfile] {
        if staff.username == username { return True; }
    }
    return False;
}


def:priv get_lab_queue(lab_username: str) -> list[dict] {
    rows: list[dict] = [];
    allowed = False;
    for staff in [root.shared -->][?:LabStaffProfile] {
        if staff.username == lab_username { allowed = True; }
    }
    if not allowed { return rows; }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.kind == "Lab test" and appointment.status == "Confirmed" {
            rows.append({"slot_key": appointment.slot_key, "patient": appointment.patient, "test": appointment.doctor, "place": appointment.place, "when": appointment.when});
        }
    }
    return rows;
}


def:priv save_lab_result(lab_username: str, slot_key: str, result_text: str) -> dict {
    allowed = False;
    for staff in [root.shared -->][?:LabStaffProfile] {
        if staff.username == lab_username { allowed = True; }
    }
    if not allowed { return {"ok": False, "message": "This account is not provisioned as lab staff."}; }
    if result_text.strip() == "" { return {"ok": False, "message": "Enter the result text first."}; }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.slot_key == slot_key and appointment.kind == "Lab test" and appointment.status == "Confirmed" {
            result = root.shared ++> LabResult(patient=appointment.patient, test_name=appointment.doctor, completed_at=datetime.now().strftime("%Y-%m-%d %H:%M"), result_text=result_text);
            _ = grant(result, level=ReadPerm);
            appointment.status = "Completed";
            return {"ok": True, "message": "Result saved and shared with the patient."};
        }
    }
    return {"ok": False, "message": "Lab booking not found or already completed."};
}


# ---------------------------------------------------------------
# Administrator (every function re-checks the admin password)
# ---------------------------------------------------------------
def:priv get_admin_overview(admin_password: str) -> dict {
    if admin_password != os.environ.get("APP_ADMIN_PASSWORD", "admin123") {
        return {"ok": False, "message": "Administrator access denied."};
    }
    appointments: list[dict] = [];
    by_doctor: dict = {};
    for appointment in [root.shared -->][?:Appointment] {
        row = {"slot_key": appointment.slot_key, "patient": appointment.patient, "doctor": appointment.doctor, "specialty": appointment.specialty, "place": appointment.place, "when": appointment.when, "kind": appointment.kind, "symptoms": appointment.symptoms, "status": appointment.status};
        appointments.append(row);
        if appointment.doctor not in by_doctor { by_doctor[appointment.doctor] = []; }
        by_doctor[appointment.doctor].append(row);
    }
    calendar = [{"doctor": name, "items": items} for (name, items) in by_doctor.items()];
    patients: list[dict] = [];
    for entry in [root.shared -->][?:PatientDirectoryEntry] {
        patients.append({"full_name": entry.full_name, "username": entry.username, "date_of_birth": entry.date_of_birth, "phone": entry.phone, "email": entry.email, "address": entry.address, "medical_notes": entry.medical_notes});
    }
    doctors = [{"full_name": d.full_name, "specialty": d.specialty, "hospital": d.hospital, "username": d.username} for d in [root.shared -->][?:DoctorProfile]];
    lab_staff = [{"full_name": s.full_name, "hospital": s.hospital, "username": s.username} for s in [root.shared -->][?:LabStaffProfile]];
    return {"ok": True, "appointments": appointments, "calendar": calendar, "patients": patients, "doctors": doctors, "lab_staff": lab_staff};
}


# Call after the Jac login account for the doctor has been created.
def:priv admin_add_doctor(admin_password: str, full_name: str, specialty: str, hospital: str, username: str) -> dict {
    if admin_password != os.environ.get("APP_ADMIN_PASSWORD", "admin123") {
        return {"ok": False, "message": "Administrator access denied."};
    }
    if full_name.strip() == "" or specialty.strip() == "" or username.strip() == "" {
        return {"ok": False, "message": "Doctor name, specialty, and username are required."};
    }
    for doctor in [root.shared -->][?:DoctorProfile] {
        if doctor.username == username { return {"ok": False, "message": "That doctor username already exists."}; }
    }
    doctor = root.shared ++> DoctorProfile(full_name=full_name, specialty=specialty, hospital=hospital, username=username);
    _ = grant(doctor, level=ReadPerm);
    return {"ok": True, "message": "Doctor added to the clinic directory."};
}


def:priv admin_add_lab_staff(admin_password: str, full_name: str, hospital: str, username: str) -> dict {
    if admin_password != os.environ.get("APP_ADMIN_PASSWORD", "admin123") {
        return {"ok": False, "message": "Administrator access denied."};
    }
    if full_name.strip() == "" or username.strip() == "" {
        return {"ok": False, "message": "Lab staff name and username are required."};
    }
    for staff in [root.shared -->][?:LabStaffProfile] {
        if staff.username == username { return {"ok": False, "message": "That lab staff username already exists."}; }
    }
    staff = root.shared ++> LabStaffProfile(full_name=full_name, hospital=hospital, username=username);
    _ = grant(staff, level=ReadPerm);
    return {"ok": True, "message": "Lab staff added to the clinic directory."};
}


def:priv admin_cancel_appointment(admin_password: str, slot_key: str) -> dict {
    if admin_password != os.environ.get("APP_ADMIN_PASSWORD", "admin123") {
        return {"ok": False, "message": "Administrator access denied."};
    }
    for appointment in [root.shared -->][?:Appointment] {
        if appointment.slot_key == slot_key and appointment.status == "Confirmed" {
            appointment.status = "Cancelled";
            return {"ok": True, "message": "Appointment cancelled."};
        }
    }
    return {"ok": False, "message": "Appointment was not found or is already cancelled."};
}
