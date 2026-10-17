import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn, jacLogout, useNavigate }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from "@hugeicons/react" { HugeiconsIcon }
import from "@hugeicons/core-free-icons" { File01Icon }
sv import from ..services.carepathService { LabResult, list_patient_lab_results }

def:pub PatientLabResults() -> JsxElement {
    nav = useNavigate();
    has results: list[LabResult] = [];
    has loading: bool = True;
    has error_message: str = "";
    async can with entry {
        if jacIsLoggedIn() {
            results = await list_patient_lab_results();
            loading = False;
        }
    }
    def handle_logout(e: MouseEvent) { jacLogout(); nav("/login"); }
    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="min-h-screen bg-muted/40 p-4 sm:p-7"><main className="mx-auto flex w-full max-w-6xl flex-col gap-6 rounded-2xl border bg-background p-5 shadow-sm sm:p-8">
        <header className="flex flex-wrap items-center justify-between gap-4"><div><Link to="/" className="text-sm font-medium text-primary hover:underline">Back to overview</Link><h1 className="mt-3 text-3xl font-semibold tracking-tight">Lab results</h1><p className="mt-2 text-sm text-muted-foreground">Review completed tests and download reports shared with your account.</p></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></header>
        <Card className="shadow-sm"><CardHeader><CardTitle>Your lab reports</CardTitle><p className="text-sm text-muted-foreground">Reports are private to your patient account.</p></CardHeader><CardContent className="flex flex-col gap-3">{loading and <p className="text-sm text-muted-foreground">Loading your lab results...</p>}{error_message != "" and <p role="alert" className="rounded-lg bg-destructive/5 p-3 text-sm text-destructive">{error_message}</p>}{if not loading and len(results) == 0 { <div className="rounded-xl border border-dashed p-8 text-center"><div className="mx-auto mb-3 flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-5" /></div><p className="font-medium">No lab results available</p><p className="mt-1 text-sm text-muted-foreground">Completed reports will appear here when your clinic shares them.</p></div>; skip; }}{for result in results { <article key={result.test_name + result.completed_at} className="flex flex-wrap items-center gap-3 rounded-xl border p-4"><div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary"><HugeiconsIcon icon={File01Icon} strokeWidth={2} className="size-5" /></div><div className="min-w-0 flex-1"><p className="font-semibold">{result.test_name}</p><p className="mt-1 text-xs text-muted-foreground">{result.completed_at}</p></div><a href={"data:text/plain;charset=utf-8," + encodeURIComponent(result.result_text)} download={result.test_name + "-result.txt"} className="text-sm font-medium text-primary hover:underline">Download report</a></article> }}</CardContent></Card>
    </main></div>;
}
