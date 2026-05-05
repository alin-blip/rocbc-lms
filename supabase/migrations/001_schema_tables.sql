-- ============================================
-- ROCBC — PEARSON DISTANCE LEARNING PLATFORM
-- Migration 001: Core Schema (22 tables)
-- ============================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- 1. PROFILES (extends auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('student','teacher','internal_verifier','admin')),
  first_name text not null,
  last_name text not null,
  email text not null unique,
  phone text,
  date_of_birth date,
  nationality text,
  address jsonb,
  status text not null default 'pending' check (status in ('pending','active','suspended','archived')),
  identity_verified boolean default false,
  induction_completed boolean default false,
  avatar_url text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index idx_profiles_role on public.profiles(role);
create index idx_profiles_status on public.profiles(status);

-- 2. STUDENT IDENTITY VERIFICATION
create table public.student_verifications (
  id uuid primary key default uuid_generate_v4(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  id_document_type text check (id_document_type in ('passport','national_id','driving_license')),
  id_document_url text not null,
  selfie_url text,
  liveness_video_url text,
  verification_status text not null default 'pending' check (verification_status in ('pending','approved','rejected','requires_resubmission')),
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  rejection_reason text,
  notes text,
  created_at timestamptz default now()
);
create index idx_verifications_student on public.student_verifications(student_id);
create index idx_verifications_status on public.student_verifications(verification_status);

-- 3. COURSES
create table public.courses (
  id uuid primary key default uuid_generate_v4(),
  title text not null,
  pearson_qualification_code text not null,
  pearson_qualification_title text,
  level text,
  description text,
  total_credits int,
  duration_weeks int,
  delivery_mode text default 'distance' check (delivery_mode in ('distance','blended','classroom')),
  status text default 'draft' check (status in ('draft','active','archived')),
  approval_status text default 'pending' check (approval_status in ('pending','dlsa_submitted','approved','rejected')),
  cover_image_url text,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index idx_courses_status on public.courses(status);

-- 4. MODULES
create table public.modules (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.courses(id) on delete cascade,
  title text not null,
  unit_code text,
  learning_outcomes jsonb,
  assessment_criteria jsonb,
  position int not null default 0,
  credits int,
  created_at timestamptz default now()
);
create index idx_modules_course on public.modules(course_id);

-- 5. LESSONS
create table public.lessons (
  id uuid primary key default uuid_generate_v4(),
  module_id uuid not null references public.modules(id) on delete cascade,
  title text not null,
  content_html text,
  video_url text,
  duration_minutes int,
  resources jsonb default '[]'::jsonb,
  position int not null default 0,
  is_mandatory boolean default true,
  created_at timestamptz default now()
);
create index idx_lessons_module on public.lessons(module_id);

-- 6. ENROLMENTS
create table public.enrolments (
  id uuid primary key default uuid_generate_v4(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  status text default 'active' check (status in ('active','completed','withdrawn','suspended')),
  enrolled_at timestamptz default now(),
  completed_at timestamptz,
  final_grade text,
  certificate_url text,
  unique(student_id, course_id)
);
create index idx_enrolments_student on public.enrolments(student_id);
create index idx_enrolments_course on public.enrolments(course_id);

-- 7. INDUCTIONS
create table public.inductions (
  id uuid primary key default uuid_generate_v4(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  video_watched boolean default false,
  quiz_passed boolean default false,
  quiz_score int,
  quiz_attempts int default 0,
  policies_accepted boolean default false,
  policies_accepted_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz default now()
);

-- 8. LIVE SESSIONS
create table public.live_sessions (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.courses(id),
  module_id uuid references public.modules(id),
  teacher_id uuid not null references public.profiles(id),
  title text not null,
  description text,
  zoom_meeting_id text,
  zoom_join_url text,
  zoom_password text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  recording_url text,
  recording_duration_minutes int,
  attendance_taken boolean default false,
  created_at timestamptz default now()
);
create index idx_live_sessions_course on public.live_sessions(course_id);
create index idx_live_sessions_starts on public.live_sessions(starts_at);

-- 9. ATTENDANCE
create table public.attendance (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid not null references public.live_sessions(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status text not null check (status in ('present','absent','late','excused')),
  joined_at timestamptz,
  left_at timestamptz,
  duration_minutes int,
  notes text,
  recorded_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  unique(session_id, student_id)
);
create index idx_attendance_session on public.attendance(session_id);
create index idx_attendance_student on public.attendance(student_id);

-- 10. ASSIGNMENTS
create table public.assignments (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.courses(id),
  module_id uuid references public.modules(id),
  title text not null,
  brief text not null,
  learning_outcomes_covered jsonb,
  assessment_criteria_covered jsonb,
  due_date timestamptz,
  max_word_count int,
  requires_video_presentation boolean default false,
  requires_oral_questioning boolean default false,
  resubmission_allowed boolean default true,
  resubmission_deadline_days int default 14,
  attachment_urls jsonb default '[]'::jsonb,
  created_by uuid references public.profiles(id),
  created_at timestamptz default now()
);
create index idx_assignments_course on public.assignments(course_id);

-- 11. SUBMISSIONS (CRITICAL — autenticitate)
create table public.submissions (
  id uuid primary key default uuid_generate_v4(),
  assignment_id uuid not null references public.assignments(id),
  student_id uuid not null references public.profiles(id),
  attempt_number int default 1,
  file_url text,
  video_url text,
  word_count int,
  authenticity_declaration boolean not null default false,
  authenticity_declaration_text text,
  authenticity_declared_at timestamptz,
  ai_use_declared boolean default false,
  ai_tools_used jsonb,
  ai_use_notes text,
  submission_ip text,
  submission_user_agent text,
  status text default 'submitted' check (status in ('draft','submitted','under_review','feedback_provided','resubmission_required','passed','failed','withdrawn')),
  submitted_at timestamptz default now(),
  created_at timestamptz default now()
);
create index idx_submissions_assignment on public.submissions(assignment_id);
create index idx_submissions_student on public.submissions(student_id);
create index idx_submissions_status on public.submissions(status);

-- 12. ASSESSMENT FEEDBACK
create table public.assessment_feedback (
  id uuid primary key default uuid_generate_v4(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  assessor_id uuid not null references public.profiles(id),
  grade text,
  marks_awarded jsonb,
  overall_feedback text not null,
  strengths text,
  improvements text,
  decision text not null check (decision in ('pass','merit','distinction','refer','resubmit','fail')),
  feedback_audio_url text,
  oral_questioning_notes text,
  created_at timestamptz default now()
);
create index idx_feedback_submission on public.assessment_feedback(submission_id);

-- 13. PLAGIARISM REPORTS
create table public.plagiarism_reports (
  id uuid primary key default uuid_generate_v4(),
  submission_id uuid not null references public.submissions(id) on delete cascade,
  tool_name text not null check (tool_name in ('turnitin','copyleaks','originality_ai','manual')),
  similarity_score numeric(5,2),
  ai_detection_score numeric(5,2),
  report_url text,
  report_data jsonb,
  flagged boolean default false,
  reviewer_notes text,
  reviewed_by uuid references public.profiles(id),
  created_at timestamptz default now()
);

-- 14. INTERNAL VERIFICATIONS
create table public.internal_verifications (
  id uuid primary key default uuid_generate_v4(),
  submission_id uuid references public.submissions(id),
  feedback_id uuid references public.assessment_feedback(id),
  verifier_id uuid not null references public.profiles(id),
  sampling_method text check (sampling_method in ('random','targeted','full','new_assessor')),
  sample_reason text,
  agrees_with_assessment boolean,
  decision text not null check (decision in ('approved','changes_required','rejected','remarked')),
  comments text not null,
  recommendations text,
  original_grade text,
  recommended_grade text,
  created_at timestamptz default now()
);
create index idx_iv_submission on public.internal_verifications(submission_id);

-- 15. ACTIVITY LOGS
create table public.activity_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid references public.profiles(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz default now()
);
create index idx_activity_user on public.activity_logs(user_id);
create index idx_activity_action on public.activity_logs(action);
create index idx_activity_entity on public.activity_logs(entity_type, entity_id);
create index idx_activity_created on public.activity_logs(created_at desc);

-- 16. SUPPORT TICKETS
create table public.support_tickets (
  id uuid primary key default uuid_generate_v4(),
  student_id uuid not null references public.profiles(id),
  assigned_to uuid references public.profiles(id),
  category text check (category in ('academic','technical','pastoral','admin','complaint')),
  subject text not null,
  message text not null,
  priority text default 'medium' check (priority in ('low','medium','high','urgent')),
  status text default 'open' check (status in ('open','in_progress','waiting','resolved','closed')),
  resolution_notes text,
  resolved_at timestamptz,
  first_response_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 17. FORUM THREADS
create table public.forum_threads (
  id uuid primary key default uuid_generate_v4(),
  course_id uuid not null references public.courses(id),
  module_id uuid references public.modules(id),
  author_id uuid not null references public.profiles(id),
  title text not null,
  content text not null,
  is_pinned boolean default false,
  is_locked boolean default false,
  created_at timestamptz default now()
);

-- 18. FORUM POSTS
create table public.forum_posts (
  id uuid primary key default uuid_generate_v4(),
  thread_id uuid not null references public.forum_threads(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  content text not null,
  parent_post_id uuid references public.forum_posts(id),
  created_at timestamptz default now()
);

-- 19. EVIDENCE VAULT (retenție 5 ani)
create table public.evidence_vault (
  id uuid primary key default uuid_generate_v4(),
  student_id uuid not null references public.profiles(id),
  course_id uuid references public.courses(id),
  enrolment_id uuid references public.enrolments(id),
  evidence_type text not null check (evidence_type in ('identity_verification','induction_record','attendance_record','submission','feedback','plagiarism_report','internal_verification','declaration','communication','support_record','grade_record','certificate')),
  source_table text,
  source_id uuid,
  file_url text,
  description text,
  metadata jsonb,
  retention_until date not null default (current_date + interval '5 years'),
  archived boolean default false,
  archived_at timestamptz,
  created_at timestamptz default now()
);
create index idx_evidence_student on public.evidence_vault(student_id);
create index idx_evidence_type on public.evidence_vault(evidence_type);
create index idx_evidence_retention on public.evidence_vault(retention_until);

-- 20. POLICIES (versionate)
create table public.policies (
  id uuid primary key default uuid_generate_v4(),
  policy_type text not null check (policy_type in ('assessment','plagiarism','authenticity','data_protection','learner_support','complaints','equality','safeguarding')),
  version text not null,
  title text not null,
  content_html text not null,
  effective_from date not null,
  effective_until date,
  is_active boolean default true,
  created_at timestamptz default now(),
  unique(policy_type, version)
);

-- 21. POLICY ACCEPTANCES
create table public.policy_acceptances (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.profiles(id),
  policy_id uuid not null references public.policies(id),
  accepted_at timestamptz default now(),
  ip_address text,
  user_agent text,
  unique(user_id, policy_id)
);

-- 22. STAFF TRAINING RECORDS
create table public.staff_training_records (
  id uuid primary key default uuid_generate_v4(),
  staff_id uuid not null references public.profiles(id),
  training_type text not null,
  training_title text not null,
  provider text,
  completed_at date not null,
  certificate_url text,
  expires_at date,
  notes text,
  created_at timestamptz default now()
);