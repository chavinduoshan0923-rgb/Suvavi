import from "@jac/runtime" { jacLogout, useNavigate, jacIsLoggedIn, Navigate }
sv import from ..services.carepathService { get_lab_queue, save_lab_result }
import from .ui.button { Button }
import from .ui.card { Card, CardHeader, CardTitle, CardContent }
import from .ui.badge { Badge }


def:pub LabDashboard() -> JsxElement {
    nav = useNavigate();
    has lab_username: str = "";
    has queue: list[dict] = [];
    has drafts: dict = {};
    has notice: str = "";

    def handle_logout(e: MouseEvent) { jacLogout(); nav("/login"); }
    def set_draft(key: str, value: str) -> None { drafts = {**drafts, key: value}; }

    async def load_queue(name: str) -> None {
        queue = await get_lab_queue(name);
    }

    async can with entry {
        if jacIsLoggedIn() {
            profile_response = await fetch("/user/me");
            profile_data = await profile_response.json();
            if profile_data["ok"] as bool {
                lab_username = profile_data["data"]["username"] as str;
                await load_queue(lab_username);
            }
        }
    }

    async def handle_save(slot_key: str) -> None {
        text = "";
        if slot_key in drafts { text = drafts[slot_key] as str; }
        result = await save_lab_result(lab_username, slot_key, text);
        notice = result["message"] as str;
        await load_queue(lab_username);
    }

    if not jacIsLoggedIn() { return <Navigate to="/login" replace={True} />; }
    return <div className="min-h-screen bg-muted/40 p-4 sm:p-8">
        <main className="mx-auto flex w-full max-w-5xl flex-col gap-6">
            <header className="flex flex-wrap items-center justify-between gap-3"><div><p className="text-sm text-muted-foreground">Carepath · Laboratory workspace</p><h1 className="mt-1 text-3xl font-semibold tracking-tight">Lab queue</h1><p className="mt-2 text-sm text-muted-foreground">Confirmed lab bookings waiting for a result.</p></div><Button variant="outline" onClick={handle_logout}>Sign out</Button></header>
            {notice != "" and <p role="status" className="rounded-lg bg-primary/10 p-3 text-sm text-primary">{notice}</p>}
            <Card className="shadow-sm"><CardHeader><CardTitle>Pending lab tests</CardTitle><p className="text-sm text-muted-foreground">Enter the result text. The patient can download it from their Lab results page.</p></CardHeader><CardContent className="flex flex-col gap-3">
                {len(queue) == 0 and <div className="rounded-xl border border-dashed p-8 text-center"><p className="font-medium">No pending lab tests</p><p className="mt-1 text-sm text-muted-foreground">New lab bookings will appear here.</p></div>}
                {for (idx, item) in enumerate(queue) {
                    <article key={str(idx)} className="flex flex-col gap-3 rounded-xl border p-4">
                        <div className="flex flex-wrap items-center justify-between gap-2"><div><p className="font-semibold">{item["test"]}</p><p className="text-sm text-muted-foreground">{item["patient"]} · {item["place"]} · {item["when"]}</p></div><Badge variant="secondary">Awaiting result</Badge></div>
                        <textarea value={(drafts[item["slot_key"] as str] if (item["slot_key"] as str) in drafts else "")} onChange={lambda e: any -> None { set_draft(item["slot_key"] as str, e.target.value); }} placeholder="Type the result or report text" className="min-h-24 w-full resize-y rounded-lg border border-input bg-background px-3 py-2.5 text-sm shadow-sm outline-none placeholder:text-muted-foreground focus-visible:ring-2 focus-visible:ring-ring" />
                        <Button className="w-fit" onClick={lambda { handle_save(item["slot_key"] as str); }}>Save result</Button>
                    </article>
                }}
            </CardContent></Card>
        </main>
    </div>;
}
