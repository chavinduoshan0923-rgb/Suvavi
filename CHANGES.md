# Changes in this version

## 1. Gemini care assistant (patient Overview page)
- `components/PatientDashboard.jac`: the "Find the right care" box is now a chat (history, typing state, emergency banner, recommended specialist + matching doctors, link to book).
- `services/assistantService.jac` (new): `chat_with_assistant` builds a system prompt from the site's content (portal pages and the live doctor directory), checks emergency phrases in code first, calls Gemini, validates the specialty against the doctors that actually exist, and falls back to the old keyword triage if the AI call fails.

### Required environment variables (never commit the key)
```
GEMINI_API_KEY=<your key>          # keys starting "AQ." use the Vertex AI express endpoint, others use Google AI Studio
GEMINI_MODEL=gemini-2.5-flash      # optional
APP_ADMIN_PASSWORD=admin123        # optional, this is the default
```

## 2. Administrator (username `admin`, password `admin123`)
- Sign in at `/clinic-admin` (or Staff > Clinic administrator on the login page). The first successful sign-in with admin/admin123 creates the account.
- Tabs: Overview, Patient profiles, Calendar (grouped by doctor), All appointments (with cancel), Doctors and lab staff (create accounts).
- `services/carepathService.jac`: admin functions now take the admin password and re-check it. Patient intake also writes a copy to the shared graph so the admin can read profiles.

## 3. Supporting changes
- New lab staff role: `LabDashboard.jac` (`/lab`), directory + `get_lab_queue` / `save_lab_result`. Lab results are shared and shown to the matching patient.
- Appointments are granted WritePerm so doctors, lab staff and admins can update status.
- `jac.toml`: project name/title, platform admin renamed to `sysadmin` to avoid clashing with the app admin.
- Staff login (`RoleSelection.jac`) supports doctor, lab staff and admin; the old URL-token admin flow was removed.
