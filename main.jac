import from services.carepathService { Appointment, PatientProfile, PatientDirectoryEntry, DoctorProfile, LabStaffProfile, LabResult, get_patient_dashboard, get_patient_profile, list_patient_appointments, list_patient_lab_results, list_doctors, verify_doctor_user, verify_lab_user, get_doctor_dashboard, get_lab_queue, save_lab_result, get_admin_overview, admin_add_doctor, admin_add_lab_staff, admin_cancel_appointment, get_triage_guidance, book_appointment, cancel_appointment, save_patient_intake }
import from services.assistantService { chat_with_assistant }
import from components.RoleSelection { RoleSelection }
import from components.PatientSignup { PatientSignup }
import from components.PatientIntake { PatientIntake }
import from components.PatientDashboard { PatientDashboard }
import from components.PatientAppointments { PatientAppointments }
import from components.PatientLabResults { PatientLabResults }
import from components.DoctorDashboard { DoctorDashboard }
import from components.AdminDashboard { AdminDashboard }
import from components.LabDashboard { LabDashboard }
import ".styles.global.css";
import from "@jac/runtime" { Router, Routes, Route, Navigate }

def:pub app() -> JsxElement {
    return <Router><Routes><Route path="/login" element={<RoleSelection />} /><Route path="/patient/signup" element={<PatientSignup />} /><Route path="/patient/intake" element={<PatientIntake />} /><Route path="/patient/appointments" element={<PatientAppointments />} /><Route path="/patient/lab-results" element={<PatientLabResults />} /><Route path="/" element={<PatientDashboard />} /><Route path="/doctor" element={<DoctorDashboard />} /><Route path="/lab" element={<LabDashboard />} /><Route path="/clinic-admin" element={<AdminDashboard />} /><Route path="*" element={<Navigate to="/login" replace={True} />} /></Routes></Router>;
}
