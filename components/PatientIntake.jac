import from "@jac/runtime" { Link, useNavigate, jacIsLoggedIn, Navigate }
sv import from ..services.carepathService { save_patient_intake, get_patient_profile }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.input { Input }


def:pub PatientIntake() -> JsxElement {
    nav = useNavigate();
    has step: int = 1;
    has full_name: str = "";
    has date_of_birth: str = "";
    has phone: str = "";
    has email: str = "";
    has address: str = "";
    has medical_notes: str = "";
    has error_message: str = "";
    has saving: bool = False;

    async can with entry {
        if jacIsLoggedIn() {
            profile = await get_patient_profile();
            if profile is not None {
                full_name = profile.full_name;
                date_of_birth = profile.date_of_birth;
                phone = profile.phone;
                email = profile.email;
                address = profile.address;
                medical_notes = profile.medical_notes;
                step = 2;
            }
        }
    }

    def handle_name(e: ChangeEvent) { full_name = e.target.value; error_message = ""; }
    def handle_dob(e: ChangeEvent) { date_of_birth = e.target.value; error_message = ""; }
    def handle_phone(e: ChangeEvent) { phone = e.target.value; error_message = ""; }
    def handle_email(e: ChangeEvent) { email = e.target.value; error_message = ""; }
    def handle_address(e: ChangeEvent) { address = e.target.value; error_message = ""; }
    def handle_notes(e: ChangeEvent) { medical_notes = e.target.value; }
    def go_next(e: MouseEvent) {
        if full_name.strip() == "" or date_of_birth.strip() == "" or phone.strip() == "" or email.strip() == "" {
            error_message = "Please complete your name, date of birth, phone, and email to continue.";
        } else {
            error_message = "";
            step = 2;
        }
    }
    def go_back(e: MouseEvent) { step = 1; error_message = ""; }
    async def finish_registration(e: MouseEvent) -> None {
        if address.strip() == "" {
            error_message = "Please enter your home address to finish registration.";
        } elif not saving {
            saving = True;
            result = await save_patient_intake(email, full_name, date_of_birth, phone, email, address, medical_notes);
            is_saved = result["ok"] as bool;
            if is_saved {
                nav("/");
            } else {
                error_message = result["message"] as str;
                saving = False;
            }
        }
    }

    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="grid min-h-screen bg-muted/40 lg:grid-cols-[0.8fr_1.2fr]">
        <aside className="hidden flex-col justify-between bg-primary p-10 text-primary-foreground lg:flex">
            <div className="flex items-center gap-3"><div className="flex size-10 items-center justify-center rounded-xl bg-primary-foreground/15 text-lg font-semibold">c</div><span className="text-lg font-semibold">Carepath</span></div>
            <div className="max-w-md"><p className="mb-3 text-sm font-medium text-primary-foreground/75">PATIENT REGISTRATION</p><h1 className="text-balance text-4xl font-semibold leading-tight tracking-tight">A little about you helps us care for you.</h1><p className="mt-4 leading-relaxed text-primary-foreground/80">Share the essentials so your care team can prepare for your visit. You can review everything before continuing.</p></div>
            <p className="text-sm text-primary-foreground/75">Your information is used for this Carepath demo experience.</p>
        </aside>
        <main className="flex min-h-screen flex-col p-5 sm:p-8 lg:p-12">
            <header className="flex items-center justify-between"><div className="flex items-center gap-3 lg:hidden"><div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground font-semibold">c</div><span className="font-semibold">Carepath</span></div><Link to="/login" className="ml-auto text-sm font-medium text-primary hover:underline">Back to role selection</Link></header>
            <div className="flex flex-1 items-center justify-center py-8">
                <Card className="w-full max-w-2xl shadow-sm">
                    <CardHeader className="border-b pb-5"><p className="text-sm font-medium text-primary">STEP {str(step)} OF 2</p><CardTitle className="mt-1 text-2xl">{("Your details" if step == 1 else "Care and address")}</CardTitle><p className="text-sm text-muted-foreground">{("Start with your contact details. Required fields are marked." if step == 1 else "Add your address and anything helpful for your care team.")}</p><div className="mt-3 flex gap-2"><div className={"h-1.5 flex-1 rounded-full " + ("bg-primary" if step >= 1 else "bg-muted")}></div><div className={"h-1.5 flex-1 rounded-full " + ("bg-primary" if step >= 2 else "bg-muted")}></div></div></CardHeader>
                    <CardContent className="pt-6">
                        {step == 1 and <div className="grid gap-5 sm:grid-cols-2">
                            <div className="flex flex-col gap-2 sm:col-span-2"><label htmlFor="full-name" className="text-sm font-medium">Full name <span className="text-destructive">*</span></label><Input id="full-name" autoComplete="name" value={full_name} onChange={handle_name} placeholder="For example, Alex Morgan" className="h-10" /></div>
                            <div className="flex flex-col gap-2"><label htmlFor="date-of-birth" className="text-sm font-medium">Date of birth <span className="text-destructive">*</span></label><Input id="date-of-birth" type="text" autoComplete="bday" value={date_of_birth} onChange={handle_dob} placeholder="YYYY-MM-DD" className="h-10" /></div>
                            <div className="flex flex-col gap-2"><label htmlFor="phone" className="text-sm font-medium">Phone number <span className="text-destructive">*</span></label><Input id="phone" type="tel" autoComplete="tel" value={phone} onChange={handle_phone} placeholder="Your contact number" className="h-10" /></div>
                            <div className="flex flex-col gap-2 sm:col-span-2"><label htmlFor="email" className="text-sm font-medium">Email address <span className="text-destructive">*</span></label><Input id="email" type="email" autoComplete="email" value={email} onChange={handle_email} placeholder="you@example.com" className="h-10" /></div>
                        </div>}
                        {step == 2 and <div className="flex flex-col gap-5">
                            <div className="flex flex-col gap-2"><label htmlFor="address" className="text-sm font-medium">Home address <span className="text-destructive">*</span></label><Input id="address" autoComplete="street-address" value={address} onChange={handle_address} placeholder="Street, city, and postal code" className="h-10" /></div>
                            <div className="flex flex-col gap-2"><label htmlFor="medical-notes" className="text-sm font-medium">Important medical information <span className="font-normal text-muted-foreground">(optional)</span></label><textarea id="medical-notes" value={medical_notes} onChange={handle_notes} placeholder="Allergies, current medications, or relevant medical history" className="min-h-28 w-full resize-y rounded-lg border border-input bg-background px-3 py-2.5 text-sm shadow-sm outline-none placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-ring" /></div>
                            <div className="rounded-xl bg-muted/60 p-4"><p className="text-sm font-semibold">Review your contact details</p><p className="mt-2 text-sm text-muted-foreground">{full_name} · {date_of_birth}</p><p className="text-sm text-muted-foreground">{phone} · {email}</p></div>
                        </div>}
                        {error_message != "" and <p role="alert" className="mt-4 rounded-lg border border-destructive/30 bg-destructive/5 p-3 text-sm text-destructive">{error_message}</p>}
                        <div className="mt-7 flex flex-wrap justify-between gap-3 border-t pt-5">{step == 1 and <div className="text-xs text-muted-foreground">Your details stay in this demo workspace.</div>}{step == 2 and <Button variant="outline" onClick={go_back}>Back</Button>}{step == 1 and <Button className="ml-auto" onClick={go_next}>Continue to care details</Button>}{step == 2 and <Button className="ml-auto" onClick={finish_registration} disabled={saving}>{("Saving details..." if saving else "Save and enter patient portal")}</Button>}</div>
                    </CardContent>
                </Card>
            </div>
            <footer className="text-center text-xs text-muted-foreground">Carepath demo · This is not a real patient account or medical record system.</footer>
        </main>
    </div>;
}
