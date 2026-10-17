import from "@jac/runtime" { Link, jacLogout, useNavigate }
sv import from ..services.carepathService { Appointment, get_doctor_dashboard, cancel_appointment }
import from "@jac/runtime" { jacIsLoggedIn, Navigate }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.badge { Badge }


def:pub DoctorDashboard() -> JsxElement {
    nav = useNavigate();
    def handle_logout(e: MouseEvent) { jacLogout(); nav("/login"); }
    has appointments: list[Appointment] = [];
    has notice: str = "";
    has doctor_username: str = "";
    async can with entry {
        if jacIsLoggedIn() {
            profile_response = await fetch("/user/me");
            profile_data = await profile_response.json();
            if profile_data["ok"] as bool { doctor_username = profile_data["data"]["username"] as str; }
            appointments = await get_doctor_dashboard(doctor_username);
        }
    }
    async def handle_cancel(appointment_id: str) -> None {
        result = await cancel_appointment(appointment_id);
        notice = result["message"] as str;
        appointments = await get_doctor_dashboard(doctor_username);
    }
    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="min-h-screen bg-muted/40 p-4 sm:p-8">
        <main className="mx-auto flex w-full max-w-5xl flex-col gap-6">
            <header className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-sm text-muted-foreground">Carepath · Clinician workspace</p><h1 className="mt-1 text-3xl font-semibold tracking-tight">Doctor schedule</h1><p className="mt-2 text-sm text-muted-foreground">Your appointments and patient notes for today.</p></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></header>
            <div className="grid gap-4 sm:grid-cols-3"><Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Today’s visits</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(len(appointments))}</p></CardContent></Card><Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Clinic</p><p className="mt-2 text-base font-semibold">Northside Medical</p></CardContent></Card><Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Specialty</p><p className="mt-2 text-base font-semibold">Cardiology</p></CardContent></Card></div>
            <Card className="shadow-sm"><CardHeader><CardTitle>Today’s schedule</CardTitle><p className="text-sm text-muted-foreground">Appointment time, patient, and reported symptoms.</p></CardHeader><CardContent className="flex flex-col gap-3">
                {notice != "" and <p className="rounded-lg bg-primary/10 p-3 text-sm text-primary">{notice}</p>}
                {if len(appointments) == 0 { <div className="rounded-xl border border-dashed p-8 text-center"><p className="font-medium">No appointments scheduled</p><p className="mt-1 text-sm text-muted-foreground">Your day is clear for now.</p></div>; skip; }}
                {for appointment in appointments {
                    <article key={appointment.slot_key} className="flex flex-wrap items-center gap-4 rounded-xl border p-4"><div className="min-w-24 rounded-lg bg-primary/10 px-3 py-2 text-center text-sm font-semibold text-primary">{appointment.when}</div><div className="min-w-0 flex-1"><p className="font-semibold">{appointment.patient}</p><p className="text-sm text-muted-foreground">{appointment.specialty} · {appointment.kind}</p><p className="mt-1 text-sm">{appointment.symptoms if appointment.symptoms != "" else "No symptom summary provided."}</p></div><Badge variant="secondary">{appointment.status}</Badge><Button variant="outline" size="sm" onClick={lambda { handle_cancel(appointment.slot_key); }}>Cancel</Button></article>
                }}
            </CardContent></Card>
        </main>
    </div>;
}
