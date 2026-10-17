import from "@jac/runtime" { Link, useNavigate, jacLogin, jacLogout, jacSignup }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.badge { Badge }
import from .ui.input { Input }
sv import from ..services.carepathService { get_admin_overview, admin_add_doctor, admin_add_lab_staff, admin_cancel_appointment }

def:pub AdminDashboard() -> JsxElement {
    nav = useNavigate();
    has admin_user: str = "admin";
    has admin_password: str = "";
    has logged_in: bool = False;
    has auth_message: str = "";
    has busy: bool = False;
    has tab: str = "overview";
    has notice: str = "";
    has overview: dict = {"appointments": [], "calendar": [], "patients": [], "doctors": [], "lab_staff": []};
    has staff_role: str = "doctor";
    has sf_name: str = "";
    has sf_specialty: str = "";
    has sf_hospital: str = "Northside Medical Center";
    has sf_username: str = "";
    has sf_password: str = "";

    def handle_admin_user(e: ChangeEvent) { admin_user = e.target.value; auth_message = ""; }
    def handle_admin_password(e: ChangeEvent) { admin_password = e.target.value; auth_message = ""; }
    def handle_staff_role(e: ChangeEvent) { staff_role = e.target.value; notice = ""; }
    def handle_sf_name(e: ChangeEvent) { sf_name = e.target.value; }
    def handle_sf_specialty(e: ChangeEvent) { sf_specialty = e.target.value; }
    def handle_sf_hospital(e: ChangeEvent) { sf_hospital = e.target.value; }
    def handle_sf_username(e: ChangeEvent) { sf_username = e.target.value; }
    def handle_sf_password(e: ChangeEvent) { sf_password = e.target.value; }
    def show_overview(e: MouseEvent) { tab = "overview"; }
    def show_patients(e: MouseEvent) { tab = "patients"; }
    def show_calendar(e: MouseEvent) { tab = "calendar"; }
    def show_appointments(e: MouseEvent) { tab = "appointments"; }
    def show_staff(e: MouseEvent) { tab = "staff"; }

    async def load_data() -> None {
        data = await get_admin_overview(admin_password);
        if data["ok"] as bool {
            overview = data;
        } else {
            notice = data["message"] as str;
        }
    }

    async def handle_admin_login(e: MouseEvent) -> None {
        if admin_user.strip() == "" or admin_password == "" {
            auth_message = "Enter your administrator username and password.";
            return;
        }
        if busy { return; }
        busy = True;
        auth_message = "";
        ok: bool = False;
        ok = await jacLogin(admin_user.strip(), admin_password);
        if not ok and admin_user.strip() == "admin" and admin_password == "admin123" {
            # First run: create the built-in administrator login, then sign in.
            created = await jacSignup([{"type": "username", "value": "admin"}, {"type": "email", "value": "admin@carepath.local"}], {"type": "password", "password": "admin123"}, {"username": "admin", "email": "admin@carepath.local", "role": "admin"});
            if created["success"] as bool {
                ok = await jacLogin("admin", "admin123");
            }
        }
        if not ok {
            busy = False;
            auth_message = "Administrator sign-in failed. Check your credentials.";
            return;
        }
        data = await get_admin_overview(admin_password);
        busy = False;
        if data["ok"] as bool {
            overview = data;
            logged_in = True;
        } else {
            jacLogout();
            auth_message = "This account does not have administrator access.";
        }
    }

    async def handle_create_staff(e: MouseEvent) -> None {
        uname = sf_username.strip();
        if sf_name.strip() == "" or uname == "" or len(sf_password) < 8 or (staff_role == "doctor" and sf_specialty.strip() == "") {
            notice = "Enter a name, a username, a temporary password of at least 8 characters, and a specialty for doctors.";
            return;
        }
        if busy { return; }
        busy = True;
        email = uname + "@carepath.local";
        created = await jacSignup([{"type": "username", "value": uname}, {"type": "email", "value": email}], {"type": "password", "password": sf_password}, {"username": uname, "email": email, "role": staff_role});
        if not (created["success"] as bool) {
            notice = created["error"] as str;
            busy = False;
            return;
        }
        # Signing up may switch the session to the new user, so sign the admin back in.
        relogin: bool = False;
        relogin = await jacLogin(admin_user.strip(), admin_password);
        result: dict = {};
        if staff_role == "doctor" {
            result = await admin_add_doctor(admin_password, sf_name.strip(), sf_specialty.strip(), sf_hospital.strip(), uname);
        } else {
            result = await admin_add_lab_staff(admin_password, sf_name.strip(), sf_hospital.strip(), uname);
        }
        notice = result["message"] as str;
        if result["ok"] as bool {
            sf_name = "";
            sf_specialty = "";
            sf_username = "";
            sf_password = "";
        }
        busy = False;
        await load_data();
    }

    async def handle_cancel(slot_key: str) -> None {
        result = await admin_cancel_appointment(admin_password, slot_key);
        notice = result["message"] as str;
        await load_data();
    }

    def handle_logout(e: MouseEvent) {
        logged_in = False;
        admin_password = "";
        jacLogout();
        nav("/login");
    }

    appointments = overview["appointments"] as list[dict];
    calendar = overview["calendar"] as list[dict];
    patients = overview["patients"] as list[dict];
    doctors = overview["doctors"] as list[dict];
    lab_staff = overview["lab_staff"] as list[dict];
    confirmed = len([a for a in appointments if a["status"] == "Confirmed"]);

    return <div className="min-h-screen bg-muted/40 p-4 sm:p-8">
        {if not logged_in {
            <main className="flex min-h-[calc(100vh-4rem)] items-center justify-center">
                <Card className="w-full max-w-md shadow-sm">
                    <CardHeader><p className="text-sm font-medium text-primary">CAREPATH ADMIN</p><CardTitle className="text-2xl">Administrator sign in</CardTitle><p className="text-sm text-muted-foreground">Sign in to manage patients, staff accounts and the clinic calendar.</p></CardHeader>
                    <CardContent className="flex flex-col gap-4">
                        <div className="flex flex-col gap-2"><label htmlFor="admin-username" className="text-sm font-medium">Admin username</label><Input id="admin-username" value={admin_user} onChange={handle_admin_user} placeholder="admin" autoComplete="username" /></div>
                        <div className="flex flex-col gap-2"><label htmlFor="admin-password" className="text-sm font-medium">Admin password</label><Input id="admin-password" type="password" value={admin_password} onChange={handle_admin_password} placeholder="Administrator password" autoComplete="current-password" /></div>
                        {auth_message != "" and <p role="alert" className="rounded-lg bg-destructive/5 p-3 text-sm text-destructive">{auth_message}</p>}
                        <Button onClick={handle_admin_login} disabled={busy} className="w-full">{("Signing in..." if busy else "Sign in to clinic admin")}</Button>
                        <Link to="/login" className="text-center text-sm text-primary hover:underline">Back to sign in</Link>
                    </CardContent>
                </Card>
            </main>
        } else {
            <main className="mx-auto flex w-full max-w-6xl flex-col gap-6">
                <header className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-sm text-muted-foreground">Carepath · Administration</p><h1 className="mt-1 text-3xl font-semibold tracking-tight">Clinic overview</h1><p className="mt-2 text-sm text-muted-foreground">Patients, staff accounts, calendars and appointments.</p></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></header>
                <div className="flex flex-wrap gap-2">
                    <Button size="sm" variant={("secondary" if tab == "overview" else "outline")} onClick={show_overview}>Overview</Button>
                    <Button size="sm" variant={("secondary" if tab == "patients" else "outline")} onClick={show_patients}>Patient profiles</Button>
                    <Button size="sm" variant={("secondary" if tab == "calendar" else "outline")} onClick={show_calendar}>Calendar</Button>
                    <Button size="sm" variant={("secondary" if tab == "appointments" else "outline")} onClick={show_appointments}>All appointments</Button>
                    <Button size="sm" variant={("secondary" if tab == "staff" else "outline")} onClick={show_staff}>Doctors and lab staff</Button>
                </div>
                {notice != "" and <p role="status" className="rounded-lg bg-primary/10 p-3 text-sm text-primary">{notice}</p>}

                {tab == "overview" and <section className="grid gap-4 sm:grid-cols-5">
                    <Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Appointments</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(len(appointments))}</p></CardContent></Card>
                    <Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Confirmed</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(confirmed)}</p></CardContent></Card>
                    <Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Patient profiles</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(len(patients))}</p></CardContent></Card>
                    <Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Doctors</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(len(doctors))}</p></CardContent></Card>
                    <Card className="shadow-sm"><CardContent className="pt-5"><p className="text-sm text-muted-foreground">Lab staff</p><p className="mt-2 text-3xl font-semibold tabular-nums">{str(len(lab_staff))}</p></CardContent></Card>
                </section>}

                {tab == "patients" and <Card className="shadow-sm"><CardHeader><CardTitle>Patient profiles</CardTitle><p className="text-sm text-muted-foreground">Details patients saved during intake. A patient appears here after saving their intake form.</p></CardHeader><CardContent className="grid gap-3 lg:grid-cols-2">
                    {len(patients) == 0 and <div className="rounded-xl border border-dashed p-6 text-center lg:col-span-2"><p className="text-sm font-medium">No patient profiles yet</p></div>}
                    {for (idx, patient) in enumerate(patients) {
                        <article key={str(idx)} className="rounded-xl border p-4">
                            <p className="font-semibold">{patient["full_name"]}</p>
                            <p className="mt-1 text-xs text-muted-foreground">{patient["username"]} · {patient["email"]}</p>
                            <p className="mt-2 text-sm">Date of birth: {patient["date_of_birth"]}</p>
                            <p className="text-sm">Phone: {patient["phone"]}</p>
                            <p className="text-sm">Address: {patient["address"]}</p>
                            <p className="mt-2 text-sm text-muted-foreground">Medical notes: {(patient["medical_notes"] if patient["medical_notes"] != "" else "None provided")}</p>
                        </article>
                    }}
                </CardContent></Card>}

                {tab == "calendar" and <div className="flex flex-col gap-4">
                    {len(calendar) == 0 and <Card className="shadow-sm"><CardContent className="p-8 text-center"><p className="font-medium">No scheduled visits yet</p></CardContent></Card>}
                    {for (gi, group) in enumerate(calendar) {
                        <Card key={str(gi)} className="shadow-sm"><CardHeader><CardTitle>{group["doctor"]}</CardTitle><p className="text-sm text-muted-foreground">{str(len(group["items"] as list[dict]))} appointments</p></CardHeader><CardContent className="flex flex-col gap-2">
                            {for (ii, item) in enumerate(group["items"] as list[dict]) {
                                <div key={str(ii)} className="flex flex-wrap items-center gap-3 rounded-lg border p-3 text-sm"><span className="min-w-48 font-medium">{item["when"]}</span><span className="flex-1">{item["patient"]} · {item["kind"]}</span><Badge variant="secondary">{item["status"]}</Badge></div>
                            }}
                        </CardContent></Card>
                    }}
                </div>}

                {tab == "appointments" and <Card className="shadow-sm"><CardHeader><CardTitle>All appointments</CardTitle><p className="text-sm text-muted-foreground">Clinic-wide booking schedule.</p></CardHeader><CardContent className="flex flex-col gap-3">
                    {len(appointments) == 0 and <div className="rounded-xl border border-dashed p-8 text-center"><p className="font-medium">No appointments yet</p></div>}
                    {for (index, appointment) in enumerate(appointments) {
                        <article key={str(index)} className="flex flex-wrap items-center gap-3 rounded-xl border p-4"><div className="min-w-0 flex-1"><p className="font-semibold">{appointment["patient"]}</p><p className="text-sm text-muted-foreground">{appointment["doctor"]} · {appointment["specialty"]} · {appointment["kind"]}</p><p className="mt-1 text-xs text-muted-foreground">{appointment["place"]} · {appointment["when"]}</p>{appointment["symptoms"] != "" and <p className="mt-1 text-xs">Symptoms: {appointment["symptoms"]}</p>}</div><Badge variant="secondary">{appointment["status"]}</Badge>{appointment["status"] == "Confirmed" and <Button variant="outline" size="sm" onClick={lambda { handle_cancel(appointment["slot_key"] as str); }}>Cancel</Button>}</article>
                    }}
                </CardContent></Card>}

                {tab == "staff" and <section className="grid gap-5 lg:grid-cols-2">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Create staff account</CardTitle><p className="text-sm text-muted-foreground">Creates a login and adds the person to the clinic directory.</p></CardHeader><CardContent className="flex flex-col gap-3">
                        <select value={staff_role} onChange={handle_staff_role} className="h-10 rounded-lg border border-input bg-background px-3 text-sm"><option value="doctor">Doctor</option><option value="lab">Lab staff</option></select>
                        <Input value={sf_name} onChange={handle_sf_name} placeholder="Full name" />
                        {staff_role == "doctor" and <Input value={sf_specialty} onChange={handle_sf_specialty} placeholder="Specialty (for example Cardiology)" />}
                        <Input value={sf_hospital} onChange={handle_sf_hospital} placeholder="Hospital or branch" />
                        <Input value={sf_username} onChange={handle_sf_username} placeholder="Login username" autoComplete="off" />
                        <Input type="password" value={sf_password} onChange={handle_sf_password} placeholder="Temporary password (8+ characters)" autoComplete="new-password" />
                        <Button onClick={handle_create_staff} disabled={busy}>{("Creating..." if busy else "Create account")}</Button>
                    </CardContent></Card>
                    <div className="flex flex-col gap-5">
                        <Card className="shadow-sm"><CardHeader><CardTitle>Doctors</CardTitle></CardHeader><CardContent className="flex flex-col gap-2">
                            {len(doctors) == 0 and <p className="text-sm text-muted-foreground">No doctors yet.</p>}
                            {for (di, doctor) in enumerate(doctors) {
                                <div key={str(di)} className="rounded-lg border p-3 text-sm"><p className="font-medium">{doctor["full_name"]}</p><p className="text-xs text-muted-foreground">{doctor["specialty"]} · {doctor["hospital"]} · {doctor["username"]}</p></div>
                            }}
                        </CardContent></Card>
                        <Card className="shadow-sm"><CardHeader><CardTitle>Lab staff</CardTitle></CardHeader><CardContent className="flex flex-col gap-2">
                            {len(lab_staff) == 0 and <p className="text-sm text-muted-foreground">No lab staff yet.</p>}
                            {for (li, staff) in enumerate(lab_staff) {
                                <div key={str(li)} className="rounded-lg border p-3 text-sm"><p className="font-medium">{staff["full_name"]}</p><p className="text-xs text-muted-foreground">{staff["hospital"]} · {staff["username"]}</p></div>
                            }}
                        </CardContent></Card>
                    </div>
                </section>}
            </main>
        }}
    </div>;
}
