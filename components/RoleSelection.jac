import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.input { Input }
import from .ui.button { Button }
import from "@jac/runtime" { Link, useNavigate, jacLogin, jacLogout, jacIsLoggedIn }
sv import from ..services.carepathService { verify_doctor_user, verify_lab_user }


def:pub RoleSelection() -> JsxElement {
    nav = useNavigate();
    has username: str = "";
    has password: str = "";
    has message: str = "";
    has busy: bool = False;
    has staff_mode: bool = False;
    has staff_role: str = "doctor";

    def handle_username(e: ChangeEvent) { username = e.target.value; message = ""; }
    def handle_password(e: ChangeEvent) { password = e.target.value; message = ""; }
    async def handle_login(e: MouseEvent) -> None {
        if username.strip() == "" or password == "" {
            message = "Enter your username and password.";
        } elif not busy {
            busy = True;
            ok: bool = False;
            ok = await jacLogin(username.strip(), password);
            busy = False;
            if ok { nav("/patient/intake"); }
            else { message = "We couldn’t sign you in. Check your credentials or ask the clinic administrator for help."; }
        }
    }
    def handle_staff_role(e: ChangeEvent) { staff_role = e.target.value; message = ""; }
    def show_staff_login(e: MouseEvent) { staff_mode = True; message = ""; }
    def show_patient_login(e: MouseEvent) { staff_mode = False; message = ""; }
    async def handle_staff_login(e: MouseEvent) {
        if staff_role == "admin" {
            nav("/clinic-admin");
        } elif username.strip() == "" or password == "" {
            message = "Enter your staff username and password.";
        } elif not busy {
            busy = True;
            ok: bool = False;
            ok = await jacLogin(username.strip(), password);
            if not ok {
                busy = False;
                message = "Staff sign-in failed. Ask the administrator to provision your account.";
            } else {
                is_member: bool = False;
                if staff_role == "doctor" {
                    is_member = await verify_doctor_user(username.strip());
                } else {
                    is_member = await verify_lab_user(username.strip());
                }
                busy = False;
                if is_member {
                    if staff_role == "doctor" { nav("/doctor"); } else { nav("/lab"); }
                } else {
                    jacLogout();
                    message = "This account is not provisioned for the selected staff role.";
                }
            }
        }
    }
    def handle_logout(e: MouseEvent) {
        jacLogout();
        message = "You have been signed out.";
    }

    return <div className="min-h-screen bg-muted/40 p-4 sm:p-8">
        <main className="mx-auto grid min-h-[calc(100vh-4rem)] w-full max-w-6xl overflow-hidden rounded-2xl border bg-background shadow-sm lg:grid-cols-[0.85fr_1.15fr]">
            <aside className="flex flex-col justify-between bg-primary p-7 text-primary-foreground sm:p-10"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 text-lg font-semibold">c</div><span className="text-lg font-semibold">Carepath</span></div><div className="my-12 max-w-md"><p className="mb-3 text-sm font-medium text-primary-foreground/75">PATIENT PORTAL</p><h1 className="text-balance text-4xl font-semibold leading-tight tracking-tight">Care that starts with you.</h1><p className="mt-4 leading-relaxed text-primary-foreground/80">Sign in to manage visits, find the right care, and review your lab results.</p></div><p className="text-sm text-primary-foreground/75">Use an account provided by your clinic, or create a patient account.</p></aside>
            <section className="flex flex-col justify-center p-6 sm:p-10">
                <div className="mx-auto w-full max-w-md">
                    <p className="text-sm font-medium text-primary">WELCOME TO CAREPATH</p><div className="mt-2 flex flex-wrap gap-2"><Button variant={("secondary" if not staff_mode else "outline")} size="sm" onClick={show_patient_login}>Patient</Button><Button variant={("secondary" if staff_mode else "outline")} size="sm" onClick={show_staff_login}>Staff</Button></div><h2 className="mt-3 text-2xl font-semibold tracking-tight">{("Staff sign in" if staff_mode else "Patient sign in")}</h2><p className="mt-2 text-sm text-muted-foreground">{("Use credentials created by your clinic administrator." if staff_mode else "Enter your Carepath username and password.")}</p>
                    {jacIsLoggedIn() and <div className="mt-5 rounded-xl border border-primary/20 bg-primary/5 p-4"><p className="text-sm font-medium">You are currently signed in.</p><Button variant="outline" size="sm" className="mt-3" onClick={handle_logout}>Sign out</Button></div>}
                    <div className="mt-6 flex flex-col gap-4">{staff_mode and <div className="flex flex-col gap-2"><label htmlFor="staff-role" className="text-sm font-medium">Staff role</label><select id="staff-role" value={staff_role} onChange={handle_staff_role} className="h-10 rounded-lg border border-input bg-background px-3 text-sm"><option value="doctor">Doctor</option><option value="lab">Laboratory staff</option><option value="admin">Clinic administrator</option></select></div>}<div className="flex flex-col gap-2"><label htmlFor="patient-username" className="text-sm font-medium">Username</label><Input id="patient-username" autoComplete="username" value={username} onChange={handle_username} placeholder="Your clinic username" className="h-10" /></div><div className="flex flex-col gap-2"><label htmlFor="patient-password" className="text-sm font-medium">Password</label><Input id="patient-password" type="password" autoComplete="current-password" value={password} onChange={handle_password} placeholder="Your password" className="h-10" /></div>{if staff_mode { <Button onClick={handle_staff_login} disabled={busy} className="w-full">{("Signing in..." if busy else ("Continue to administrator sign in" if staff_role == "admin" else "Sign in to staff workspace"))}</Button> } else { <Button onClick={handle_login} disabled={busy} className="w-full">{("Signing in..." if busy else "Sign in")}</Button> }}</div>
                    {message != "" and <p role="alert" className="mt-4 rounded-lg border border-primary/20 bg-primary/5 p-3 text-sm">{message}</p>}
                    <p className="mt-5 text-center text-sm text-muted-foreground">Need an account? <Link to="/patient/signup" className="font-medium text-primary hover:underline">Create a patient account</Link></p>
                    <div className="mt-8 border-t pt-5"><p className="text-xs text-muted-foreground">Administrator access uses a separate secure sign-in. Doctor and lab staff accounts are provisioned by your clinic administrator.</p></div>
                </div>
            </section>
        </main>
    </div>;
}
