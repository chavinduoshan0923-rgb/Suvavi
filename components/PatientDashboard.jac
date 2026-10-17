import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.badge { Badge }
import from "@jac/runtime" { Link }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@jac/runtime" { jacIsLoggedIn, jacLogout, useNavigate, Navigate }
import from "@hugeicons/core-free-icons" { Calendar01Icon, Clock01Icon, UserIcon, Search01Icon, File01Icon, CheckmarkCircle01Icon, Alert01Icon }
sv import from ..services.carepathService { Appointment, PatientProfile, get_patient_dashboard, get_patient_profile, book_appointment, cancel_appointment }

sv import from ..services.assistantService { chat_with_assistant }

def:pub PatientDashboard() -> JsxElement {
    nav = useNavigate();
    has chat: list[dict] = [{"role": "assistant", "text": "Hi, I'm the Carepath care assistant. Tell me what you're feeling and I'll help work out which specialist to see. I can't diagnose, but I can point you in the right direction."}];
    has chat_input: str = "";
    has chat_busy: bool = False;
    has chat_specialty: str = "";
    has chat_doctors: list[dict] = [];
    has chat_note: str = "";
    has emergency: bool = False;
    has booking_type: str = "Consultation";
    has appointments: list[Appointment] = [];
    has patient_profile: PatientProfile | None = None;
    has booked: bool = False;
    has busy: bool = False;
    has notice: str = "";

    async can with entry {
        if jacIsLoggedIn() {
            appointments = await get_patient_dashboard();
            patient_profile = await get_patient_profile();
        }
    }

    def handle_logout(e: MouseEvent) { jacLogout(); nav("/login"); }
    def handle_type(e: ChangeEvent) { booking_type = e.target.value; booked = False; }
    def handle_chat_input(e: ChangeEvent) { chat_input = e.target.value; }
    async def send_chat() -> None {
        text = chat_input.strip();
        if text == "" or chat_busy { return; }
        history = chat + [{"role": "user", "text": text}];
        chat = history;
        chat_input = "";
        chat_busy = True;
        chat_note = "";
        result = await chat_with_assistant(history);
        chat = history + [{"role": "assistant", "text": result["reply"] as str}];
        emergency = result["emergency"] as bool;
        chat_specialty = result["specialty"] as str;
        chat_doctors = result["doctors"] as list[dict];
        if (result["error"] as str) != "" { chat_note = "AI offline: " + (result["error"] as str); }
        chat_busy = False;
    }
    def handle_chat_send(e: MouseEvent) { send_chat(); }
    def handle_chat_key(e: any) { if e.key == "Enter" { send_chat(); } }
    def handle_chat_reset(e: MouseEvent) {
        chat = [chat[0]];
        chat_input = "";
        chat_specialty = "";
        chat_doctors = [];
        chat_note = "";
        emergency = False;
    }
    async def handle_book(e: MouseEvent) -> None {
        if not emergency and not busy {
            busy = True;
            reason = "";
            for m in chat {
                if m["role"] == "user" { reason = m["text"] as str; }
            }
            label = "Dr. Maya Chen" if booking_type == "Consultation" else "Complete blood count";
            speciality = "Cardiology" if booking_type == "Consultation" else "Laboratory";
            result = await book_appointment(label, speciality, "Northside Medical Center", "Friday, October 24 · 11:30 AM", booking_type, booking_type.lower() + "-friday-1130", reason);
            notice = result["message"] as str;
            booked = result["ok"] as bool;
            appointments = await get_patient_dashboard();
            busy = False;
        }
    }
    async def handle_cancel(slot_key: str) -> None {
        result = await cancel_appointment(slot_key);
        notice = result["message"] as str;
        appointments = await get_patient_dashboard();
    }

    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="min-h-screen bg-muted/40 text-foreground">
        <div className="mx-auto flex min-h-screen w-full max-w-[1440px] gap-4 p-3 sm:p-5">
            <aside className="hidden w-60 shrink-0 flex-col rounded-2xl border bg-card p-5 shadow-sm md:flex">
                <div className="flex items-center gap-3 pb-9">
                    <div className="flex size-10 items-center justify-center rounded-xl bg-primary text-primary-foreground"><span className="text-lg font-semibold">c</span></div>
                    <div><p className="font-semibold tracking-tight">Carepath</p><p className="text-xs text-muted-foreground">Patient portal</p></div>
                </div>
                <p className="mb-3 px-2 text-xs font-medium uppercase tracking-wide text-muted-foreground">Your care</p>
                <div className="flex flex-col gap-1">
                    <Link to="/" className="flex items-center gap-3 rounded-lg bg-primary/10 px-3 py-2.5 text-sm font-medium text-primary"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-4" /> Overview</Link>
                    <Link to="/patient/appointments" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm text-muted-foreground hover:bg-muted"><HugeiconsIcon icon={Clock01Icon} strokeWidth={2} className="size-4" /> Appointments</Link>
                    <Link to="/patient/lab-results" className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm text-muted-foreground hover:bg-muted"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-4" /> Lab results</Link>
                </div>
                <div className="mt-auto rounded-xl bg-muted/70 p-4">
                    <p className="text-sm font-medium">Need help?</p><p className="mt-1 text-xs leading-relaxed text-muted-foreground">Our care team is here to help you find the right care.</p>
                    <Button variant="outline" size="sm" className="mt-3 w-full">Contact care team</Button>
                </div>
            </aside>
            <main className="min-w-0 flex-1 rounded-2xl border bg-background p-4 shadow-sm sm:p-7">
                <header className="mb-8 flex flex-wrap items-center justify-between gap-4 border-b pb-5">
                    <div className="flex items-center gap-3 md:hidden"><div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold">c</div><span className="font-semibold">Carepath</span></div>
                    <div className="hidden md:block"><p className="text-sm text-muted-foreground">Monday, October 20</p><p className="text-sm font-medium">Your care, all in one place</p></div>
                    <div className="flex items-center gap-3"><div className="text-right"><p className="text-sm font-medium">Patient account</p><p className="text-xs text-muted-foreground">Signed in</p></div><Button variant="outline" size="sm" onClick={handle_logout}>Sign out</Button><div className="flex size-10 items-center justify-center rounded-full bg-primary/10 text-primary"><HugeiconsIcon icon={UserIcon} strokeWidth={2} className="size-5" /></div></div>
                </header>
                <section className="mb-7 flex flex-wrap items-end justify-between gap-4">
                    <div><p className="mb-2 text-xs font-medium uppercase tracking-widest text-primary">Your health, in focus</p><h1 className="text-3xl font-semibold tracking-tight">{("Good morning, " + patient_profile.full_name) if patient_profile is not None else "Your care overview"}</h1><p className="mt-2 text-sm text-muted-foreground">Here’s your care overview. What can we help with today?</p></div>
                    <div className="flex gap-2"><Link to="/patient/appointments" className="rounded-lg border px-3 py-2 text-sm font-medium hover:border-primary">Appointments</Link><Link to="/patient/lab-results" className="rounded-lg border px-3 py-2 text-sm font-medium hover:border-primary">Lab results</Link></div>
                </section>
                <section className="grid gap-5 xl:grid-cols-[1.25fr_0.75fr]">
                    <Card className="overflow-hidden border-primary/20 shadow-sm">
                        <CardHeader className="border-b bg-primary/[0.04] pb-4"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Search01Icon} strokeWidth={2} className="size-5" /></div><div><CardTitle>Care assistant</CardTitle><p className="mt-1 text-sm text-muted-foreground">Chat about your symptoms and get a specialist recommendation.</p></div></div></CardHeader>
                        <CardContent className="flex flex-col gap-4 pt-5">
                            <div className="flex max-h-80 min-h-40 flex-col gap-3 overflow-y-auto rounded-xl bg-muted/40 p-3">
                                {for (idx, msg) in enumerate(chat) {
                                    <div key={str(idx)} className={"flex " + ("justify-end" if msg["role"] == "user" else "justify-start")}><div className={"max-w-[85%] whitespace-pre-wrap rounded-2xl px-3.5 py-2 text-sm " + ("bg-primary text-primary-foreground" if msg["role"] == "user" else "border bg-background")}>{msg["text"]}</div></div>
                                }}
                                {chat_busy and <p className="text-xs text-muted-foreground">The assistant is thinking...</p>}
                            </div>
                            {emergency and <div className="flex items-start gap-3 rounded-xl border border-destructive/30 bg-destructive/5 p-4 text-destructive"><HugeiconsIcon icon={Alert01Icon} strokeWidth={2} className="mt-0.5 size-5 shrink-0" /><p className="text-sm font-semibold">Seek urgent care now. Do not wait for an appointment.</p></div>}
                            {chat_specialty != "" and <div className="rounded-xl border border-primary/20 bg-primary/5 p-4">
                                <p className="text-xs font-medium uppercase tracking-wide text-primary">Recommended specialist</p>
                                <p className="mt-1 text-base font-semibold">{chat_specialty}</p>
                                {for (i, doc) in enumerate(chat_doctors) {
                                    <p key={str(i)} className="mt-1 text-sm text-muted-foreground">{doc["name"]} · {doc["hospital"]}</p>
                                }}
                                {len(chat_doctors) == 0 and <p className="mt-1 text-sm text-muted-foreground">No doctor is listed for this specialty yet.</p>}
                                <Link to="/patient/appointments" className="mt-3 inline-block text-sm font-medium text-primary hover:underline">Book an appointment</Link>
                            </div>}
                            <div className="flex gap-2">
                                <input value={chat_input} onChange={handle_chat_input} onKeyDown={handle_chat_key} placeholder="Describe your symptoms..." className="h-10 flex-1 rounded-lg border border-input bg-background px-3 text-sm outline-none placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-ring" />
                                <Button onClick={handle_chat_send} disabled={chat_busy}>Send</Button>
                                <Button variant="outline" onClick={handle_chat_reset}>New chat</Button>
                            </div>
                            {chat_note != "" and <p className="text-xs text-muted-foreground">{chat_note}</p>}
                            <p className="text-xs leading-relaxed text-muted-foreground">This assistant gives general guidance only. It is not a diagnosis and is not a substitute for professional medical advice.</p>
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>Book an appointment</CardTitle><p className="text-sm text-muted-foreground">Choose a visit and reserve a time.</p></CardHeader>
                        <CardContent className="flex flex-col gap-4">
                            <label htmlFor="visit-type" className="text-sm font-medium">Appointment type</label>
                            <select id="visit-type" value={booking_type} onChange={handle_type} className="h-10 rounded-lg border border-input bg-background px-3 text-sm outline-none focus:ring-2 focus:ring-ring"><option>Consultation</option><option>Lab test</option></select>
                            <div className="rounded-xl bg-muted/60 p-4"><p className="text-sm font-medium">Northside Medical Center</p><p className="mt-1 text-sm text-muted-foreground">{booking_type == "Consultation" and "Dr. Maya Chen · Cardiology"}{booking_type == "Lab test" and "Complete blood count · Laboratory"}</p><div className="mt-3 flex items-center gap-2 text-sm text-muted-foreground"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-4" /> Friday, October 24 <span className="text-border">·</span> 11:30 AM</div></div>
                            <Button onClick={handle_book} disabled={emergency or busy} className="w-full">{booking_type == "Consultation" and "Book consultation"}{booking_type == "Lab test" and "Book lab test"}</Button>
                            {notice != "" and <p className={"text-sm font-medium " + ("text-primary" if booked else "text-destructive")}>{notice}</p>}
                            <p className="text-xs text-muted-foreground">Demo booking · A WhatsApp confirmation would be sent.</p>
                        </CardContent>
                    </Card>
                </section>
                <section className="mt-7 grid gap-5 xl:grid-cols-[1.25fr_0.75fr]">
                    <Card className="shadow-sm"><CardHeader className="flex flex-row items-center justify-between"><div><CardTitle>Upcoming appointments</CardTitle><p className="mt-1 text-sm text-muted-foreground">Your scheduled visits</p></div><Badge variant="outline">{str(len(appointments))} visits</Badge></CardHeader><CardContent className="flex flex-col gap-3">
                        {for (idx, appt) in enumerate(appointments) {
                            <div key={str(idx)} className="flex flex-wrap items-center gap-3 rounded-xl border p-4">
                                <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={Calendar01Icon} strokeWidth={2} className="size-5" /></div>
                                <div className="min-w-0 flex-1"><p className="text-sm font-semibold">{appt.doctor}</p><p className="mt-0.5 text-sm text-muted-foreground">{appt.specialty} · {appt.kind}</p><p className="mt-1 text-xs text-muted-foreground">{appt.place}</p></div>
                                <div className="text-sm sm:text-right"><p className="font-medium">{appt.when}</p><Badge variant="secondary" className="mt-1">{appt.status}</Badge></div>
                                {appt.status == "Confirmed" and <Button variant="outline" size="sm" onClick={lambda { handle_cancel(appt.slot_key); }}>Cancel</Button>}
                            </div>
                        }}
                    </CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Recent lab results</CardTitle><p className="text-sm text-muted-foreground">Your latest reports</p></CardHeader><CardContent className="flex flex-col gap-3">
                        <div className="flex items-center gap-3 rounded-xl border p-4"><div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-5" /></div><div className="min-w-0 flex-1"><p className="text-sm font-semibold">Your lab reports</p><p className="mt-1 text-xs text-muted-foreground">View completed results shared by your clinic.</p></div><Link to="/patient/lab-results" className="text-sm font-medium text-primary hover:underline">View results</Link></div>
                        <p className="px-1 text-xs text-muted-foreground">For questions about your results, contact your care team.</p>
                    </CardContent></Card>
                </section>
                <footer className="mt-7 border-t pt-4 text-center text-xs text-muted-foreground">Carepath demo · Your health information belongs to you.</footer>
            </main>
        </div>
    </div>;
}
