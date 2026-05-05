export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type UserRole = 'student' | 'teacher' | 'internal_verifier' | 'admin'
export type ProfileStatus = 'pending' | 'active' | 'suspended' | 'archived'
export type VerificationStatus = 'pending' | 'approved' | 'rejected' | 'requires_resubmission'
export type EnrolmentStatus = 'active' | 'completed' | 'withdrawn' | 'suspended'
export type CourseStatus = 'draft' | 'active' | 'archived'
export type SubmissionStatus = 'draft' | 'submitted' | 'under_review' | 'feedback_provided' | 'resubmission_required' | 'passed' | 'failed' | 'withdrawn'
export type GradeDecision = 'pass' | 'merit' | 'distinction' | 'refer' | 'resubmit' | 'fail'
export type IVDecision = 'approved' | 'changes_required' | 'rejected' | 'remarked'
export type EvidenceType = 'identity_verification' | 'induction_record' | 'attendance_record' | 'submission' | 'feedback' | 'plagiarism_report' | 'internal_verification' | 'declaration' | 'communication' | 'support_record' | 'grade_record' | 'certificate'
export type SupportCategory = 'academic' | 'technical' | 'pastoral' | 'admin' | 'complaint'
export type TicketStatus = 'open' | 'in_progress' | 'waiting' | 'resolved' | 'closed'
export type AttendanceStatus = 'present' | 'absent' | 'late' | 'excused'
export type PolicyType = 'assessment' | 'plagiarism' | 'authenticity' | 'data_protection' | 'learner_support' | 'complaints' | 'equality' | 'safeguarding'

export interface Profile { id: string; role: UserRole; first_name: string; last_name: string; email: string; phone?: string; date_of_birth?: string; nationality?: string; address?: Json; status: ProfileStatus; identity_verified: boolean; induction_completed: boolean; avatar_url?: string; metadata: Json; created_at: string; updated_at: string }
export interface Course { id: string; title: string; pearson_qualification_code: string; pearson_qualification_title?: string; level?: string; description?: string; total_credits?: number; duration_weeks?: number; delivery_mode: 'distance'|'blended'|'classroom'; status: CourseStatus; approval_status: 'pending'|'dlsa_submitted'|'approved'|'rejected'; cover_image_url?: string; created_by?: string; created_at: string; updated_at: string }
export interface Module { id: string; course_id: string; title: string; unit_code?: string; learning_outcomes?: Json; assessment_criteria?: Json; position: number; credits?: number; created_at: string }
export interface Lesson { id: string; module_id: string; title: string; content_html?: string; video_url?: string; duration_minutes?: number; resources: Json; position: number; is_mandatory: boolean; created_at: string }
export interface Enrolment { id: string; student_id: string; course_id: string; status: EnrolmentStatus; enrolled_at: string; completed_at?: string; final_grade?: string; certificate_url?: string }
export interface Assignment { id: string; course_id: string; module_id?: string; title: string; brief: string; learning_outcomes_covered?: Json; assessment_criteria_covered?: Json; due_date?: string; max_word_count?: number; requires_video_presentation: boolean; requires_oral_questioning: boolean; resubmission_allowed: boolean; resubmission_deadline_days: number; attachment_urls: Json; created_by?: string; created_at: string }
export interface Submission { id: string; assignment_id: string; student_id: string; attempt_number: number; file_url?: string; video_url?: string; word_count?: number; authenticity_declaration: boolean; authenticity_declaration_text?: string; authenticity_declared_at?: string; ai_use_declared: boolean; ai_tools_used?: Json; ai_use_notes?: string; submission_ip?: string; submission_user_agent?: string; status: SubmissionStatus; submitted_at: string; created_at: string }
export interface AssessmentFeedback { id: string; submission_id: string; assessor_id: string; grade?: string; marks_awarded?: Json; overall_feedback: string; strengths?: string; improvements?: string; decision: GradeDecision; feedback_audio_url?: string; oral_questioning_notes?: string; created_at: string }
export interface InternalVerification { id: string; submission_id?: string; feedback_id?: string; verifier_id: string; sampling_method?: string; sample_reason?: string; agrees_with_assessment?: boolean; decision: IVDecision; comments: string; recommendations?: string; original_grade?: string; recommended_grade?: string; created_at: string }
export interface EvidenceVault { id: string; student_id: string; course_id?: string; enrolment_id?: string; evidence_type: EvidenceType; source_table?: string; source_id?: string; file_url?: string; description?: string; metadata?: Json; retention_until: string; archived: boolean; archived_at?: string; created_at: string }
export interface LiveSession { id: string; course_id: string; module_id?: string; teacher_id: string; title: string; description?: string; zoom_meeting_id?: string; zoom_join_url?: string; zoom_password?: string; starts_at: string; ends_at: string; recording_url?: string; recording_duration_minutes?: number; attendance_taken: boolean; created_at: string }
export interface PlagiarismReport { id: string; submission_id: string; tool_name: string; similarity_score?: number; ai_detection_score?: number; report_url?: string; report_data?: Json; flagged: boolean; reviewer_notes?: string; reviewed_by?: string; created_at: string }
