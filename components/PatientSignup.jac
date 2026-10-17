import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.input { Input }
import from .ui.button { Button }
import from "@jac/runtime" { Link, useNavigate, jacSignup, jacLogin }


def:pub PatientSignup() -> JsxElement {
    nav = useNavigate();
    has username: str = "";
    has email: str = "";
    has password: str = "";
    has message: str = "";
    has busy: bool = False;

    def handle_username(e: ChangeEvent) { username = e.target.value; message = ""; }
    def handle_email(e: ChangeEvent) { email = e.target.value; message = ""; }
    def handle_password(e: ChangeEvent) { password = e.target.value; message = ""; }
    async def handle_signup(e: MouseEvent) -> None {
        if username.strip() == "" or email.strip() == "" or password == "" {
            message = "Enter a username, email, and password to create your account.";
        } elif len(password) < 8 {
            message = "Choose a password with at least 8 characters.";
        } elif not busy {
            busy = True;
            signup_result: dict | None = None;
            login_ok: bool = False;
            signup_result = await jacSignup([{"type": "username", "value": username.strip()}, {"type": "email", "value": email.strip()}], {"type": "password", "password": password}, {"username": username.strip(), "email": email.strip(), "role": "patient"});
            if not signup_result["success"] {
                message = signup_result["error"] as str;
                busy = False;
            } else {
                login_ok = await jacLogin(username.strip(), password);
                busy = False;
                if login_ok { nav("/patient/intake"); }
                else { message = "Your account was created, but sign in did not complete. Return to patient sign in."; }
            }
        }
    }

    return <div className="min-h-screen bg-muted/40 p-4 sm:p-8"><main className="mx-auto grid min-h-[calc(100vh-4rem)] w-full max-w-6xl overflow-hidden rounded-2xl border bg-background shadow-sm lg:grid-cols-[0.85fr_1.15fr]">
        <aside className="flex flex-col justify-between bg-primary p-7 text-primary-foreground sm:p-10"><div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 text-lg font-semibold">c</div><span className="text-lg font-semibold">Carepath</span></div><div className="my-12 max-w-md"><p className="mb-3 text-sm font-medium text-primary-foreground/75">PATIENT ACCOUNT</p><h1 className="text-balance text-4xl font-semibold leading-tight tracking-tight">Your care, ready when you are.</h1><p className="mt-4 leading-relaxed text-primary-foreground/80">Create a username and password to access the patient portal and complete your care profile.</p></div><p className="text-sm text-primary-foreground/75">Use a unique username and keep your password private.</p></aside>
        <section className="flex items-center justify-center p-6 sm:p-10"><div className="w-full max-w-md"><p className="text-sm font-medium text-primary">PATIENT REGISTRATION</p><CardTitle className="mt-2 text-2xl">Create your account</CardTitle><p className="mt-2 text-sm text-muted-foreground">After signing up, you can complete your patient intake.</p><Card className="mt-6 shadow-sm"><CardHeader><CardTitle>Account details</CardTitle></CardHeader><CardContent className="flex flex-col gap-4"><div className="flex flex-col gap-2"><label htmlFor="signup-username" className="text-sm font-medium">Username</label><Input id="signup-username" autoComplete="username" value={username} onChange={handle_username} placeholder="Choose a username" className="h-10" /></div><div className="flex flex-col gap-2"><label htmlFor="signup-email" className="text-sm font-medium">Email address</label><Input id="signup-email" type="email" autoComplete="email" value={email} onChange={handle_email} placeholder="you@example.com" className="h-10" /></div><div className="flex flex-col gap-2"><label htmlFor="signup-password" className="text-sm font-medium">Password</label><Input id="signup-password" type="password" autoComplete="new-password" value={password} onChange={handle_password} placeholder="At least 8 characters" className="h-10" /></div>{message != "" and <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{message}</p>}<Button onClick={handle_signup} disabled={busy} className="w-full">{("Creating account..." if busy else "Create patient account")}</Button><p className="text-xs leading-relaxed text-muted-foreground">Patient self-signup is enabled for this portal. Clinic staff accounts are created separately by an administrator.</p></CardContent></Card><p className="mt-5 text-center text-sm text-muted-foreground">Already have an account? <Link to="/login" className="font-medium text-primary hover:underline">Sign in</Link></p></div></section>
    </main></div>;
}
