import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogout, useNavigate }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.badge { Badge }
import from .ui.input { Input }
sv import from ..services.carepathService { Appointment, DoctorProfile, PatientProfile, get_patient_profile, list_patient_appointments, list_doctors, book_appointment, cancel_appointment }

def:pub PatientAppointments() -> JsxElement {
    nav = useNavigate();
    has patient_name: str = "";
    has patient_profile: PatientProfile | None = None;
    has appointments: list[Appointment] = [];
    has doctors: list[DoctorProfile] = [];
    has selected_doctor: str = "";
    has symptoms: str = "";
    has notice: str = "";
    has loading: bool = True;
    async can with entry {
        if jacIsLoggedIn() {
            patient_profile = await get_patient_profile();
            if patient_profile is not None { patient_name = patient_profile.full_name; }
            appointments = await list_patient_appointments();
            doctors = await list_doctors();
            if len(doctors) > 0 { selected_doctor = doctors[0].full_name; }
            loading = False;
        }
    }
    def handle_symptoms(e: ChangeEvent) { symptoms = e.target.value; }
    def handle_doctor(e: ChangeEvent) { selected_doctor = e.target.value; }
    def handle_logout(e: MouseEvent) { jacLogout(); nav("/login"); }
    async def handle_book(e: MouseEvent) {
        if selected_doctor == "" or patient_name == "" {
            notice = "Complete your patient profile and ask the clinic to add an available doctor before booking.";
            return;
        }
        doctor_name = selected_doctor;
        specialty = "General Medicine";
        clinic = "Northside Medical Center";
        for doctor in doctors {
            if doctor.full_name == selected_doctor {
                specialty = doctor.specialty;
                clinic = doctor.hospital;
            }
        }
        result = await book_appointment(doctor_name, specialty, clinic, "Next available · 11:30 AM", "Consultation", "consult-" + selected_doctor.lower().replace(" ", "-") + "-1130", symptoms);
        notice = result["message"] as str;
        appointments = await list_patient_appointments();
    }
    async def handle_cancel(slot: str) {
        result = await cancel_appointment(slot);
        notice = result["message"] as str;
        appointments = await list_patient_appointments();
    }
    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="min-h-screen bg-muted/40 p-4 sm:p-7"><main className="mx-auto flex w-full max-w-6xl flex-col gap-6 rounded-2xl border bg-background p-5 shadow-sm sm:p-8">
        <header className="flex flex-wrap items-center justify-between gap-4"><div><Link to="/" className="text-sm font-medium text-primary hover:underline">Back to overview</Link><h1 className="mt-3 text-3xl font-semibold tracking-tight">Appointments</h1><p className="mt-2 text-sm text-muted-foreground">Choose a doctor, review upcoming visits, and manage bookings.</p></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></header>
        <Card className="shadow-sm"><CardHeader><CardTitle>Book a consultation</CardTitle><p className="text-sm text-muted-foreground">Select a doctor and share a short symptom summary.</p></CardHeader><CardContent className="grid gap-4 sm:grid-cols-2"><div className="flex flex-col gap-2"><label htmlFor="doctor-choice" className="text-sm font-medium">Available doctor</label><select id="doctor-choice" value={selected_doctor} onChange={handle_doctor} className="h-10 rounded-lg border border-input bg-background px-3 text-sm">{for doctor in doctors { <option key={doctor.username}>{doctor.full_name}</option> }}</select>{len(doctors) == 0 and <p className="text-xs text-muted-foreground">No doctors are listed yet. Please contact the clinic.</p>}</div><div className="flex flex-col gap-2"><label htmlFor="symptoms-summary" className="text-sm font-medium">Symptoms (optional)</label><Input id="symptoms-summary" value={symptoms} onChange={handle_symptoms} placeholder="Briefly describe what you need help with" /></div><Button onClick={handle_book} className="sm:col-span-2">Book consultation</Button></CardContent></Card>
        {notice != "" and <p role="status" className="rounded-lg bg-primary/10 p-3 text-sm text-primary">{notice}</p>}
        <Card className="shadow-sm"><CardHeader><CardTitle>Your upcoming visits</CardTitle><p className="text-sm text-muted-foreground">Appointments attached to your patient account.</p></CardHeader><CardContent className="flex flex-col gap-3">{loading and <p className="text-sm text-muted-foreground">Loading appointments...</p>}{if not loading and len(appointments) == 0 { <div className="rounded-xl border border-dashed p-8 text-center"><p className="font-medium">No appointments yet</p><p className="mt-1 text-sm text-muted-foreground">Book a consultation above to get started.</p></div>; skip; }}{for appointment in appointments { <div key={appointment.slot_key} className="flex flex-wrap items-center gap-4 rounded-xl border p-4"><div className="min-w-0 flex-1"><p className="font-semibold">{appointment.doctor}</p><p className="text-sm text-muted-foreground">{appointment.specialty} · {appointment.kind}</p><p className="mt-1 text-sm">{appointment.when}</p></div><Badge variant="secondary">{appointment.status}</Badge>{appointment.status == "Confirmed" and <Button variant="outline" size="sm" onClick={lambda { handle_cancel(appointment.slot_key); }}>Cancel</Button>}</div> }}</CardContent></Card>
    </main></div>;
}
