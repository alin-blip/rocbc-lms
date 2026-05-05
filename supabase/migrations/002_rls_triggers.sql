-- ============================================
-- ROCBC — Migration 002: RLS + Triggers + Storage
-- ============================================

-- HANDLE UPDATED_AT
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.handle_updated_at();
create trigger courses_updated_at before update on public.courses
  for each row execute function public.handle_updated_at();
create trigger support_tickets_updated_at before update on public.support_tickets
  for each row execute function public.handle_updated_at();

-- AUTO-LOG SUBMISSION ACTIVITY
create or replace function public.log_submission_activity()
returns trigger as $$
begin
  insert into public.activity_logs (user_id, action, entity_type, entity_id, metadata)
  values (
    new.student_id,
    'submission_' || tg_op,
    'submission',
    new.id,
    jsonb_build_object('assignment_id', new.assignment_id, 'status', new.status)
  );
  return new;
end;
$$ language plpgsql;

create trigger log_submission_changes after insert or update on public.submissions
  for each row execute function public.log_submission_activity();

-- AUTO-ARCHIVE SUBMISSION TO EVIDENCE VAULT
create or replace function public.archive_submission_evidence()
returns trigger as $$
begin
  insert into public.evidence_vault (
    student_id, course_id, evidence_type, source_table, source_id, 
    file_url, description, metadata
  )
  select 
    new.student_id,
    a.course_id,
    'submission',
    'submissions',
    new.id,
    new.file_url,
    'Submission for ' || a.title,
    jsonb_build_object(
      'authenticity_declared', new.authenticity_declaration,
      'ai_declared', new.ai_use_declared,
      'attempt', new.attempt_number
    )
  from public.assignments a where a.id = new.assignment_id;
  return new;
end;
$$ language plpgsql;

create trigger archive_submission after insert on public.submissions
  for each row when (new.status = 'submitted')
  execute function public.archive_submission_evidence();

-- AUTO-LOG FEEDBACK TO EVIDENCE VAULT
create or replace function public.archive_feedback_evidence()
returns trigger as $$
begin
  insert into public.evidence_vault (
    student_id, course_id, evidence_type, source_table, source_id, description, metadata
  )
  select 
    s.student_id,
    a.course_id,
    'feedback',
    'assessment_feedback',
    new.id,
    'Assessment feedback: ' || new.decision,
    jsonb_build_object('assessor_id', new.assessor_id, 'decision', new.decision)
  from public.submissions s
  join public.assignments a on a.id = s.assignment_id
  where s.id = new.submission_id;
  return new;
end;
$$ language plpgsql;

create trigger archive_feedback after insert on public.assessment_feedback
  for each row execute function public.archive_feedback_evidence();

-- AUTO-LOG IV TO EVIDENCE VAULT
create or replace function public.archive_iv_evidence()
returns trigger as $$
begin
  insert into public.evidence_vault (
    student_id, course_id, evidence_type, source_table, source_id, description, metadata
  )
  select 
    s.student_id,
    a.course_id,
    'internal_verification',
    'internal_verifications',
    new.id,
    'IV decision: ' || new.decision,
    jsonb_build_object('verifier_id', new.verifier_id, 'decision', new.decision)
  from public.submissions s
  join public.assignments a on a.id = s.assignment_id
  where s.id = new.submission_id;
  return new;
end;
$$ language plpgsql;

create trigger archive_iv after insert on public.internal_verifications
  for each row execute function public.archive_iv_evidence();

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
alter table public.profiles enable row level security;
alter table public.student_verifications enable row level security;
alter table public.courses enable row level security;
alter table public.enrolments enable row level security;
alter table public.submissions enable row level security;
alter table public.assessment_feedback enable row level security;
alter table public.internal_verifications enable row level security;
alter table public.activity_logs enable row level security;
alter table public.evidence_vault enable row level security;

-- Helper function for role
create or replace function public.get_user_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql stable security definer;

-- PROFILES
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Admins can view all profiles" on public.profiles
  for select using (public.get_user_role() in ('admin','internal_verifier'));
create policy "Teachers can view their students" on public.profiles
  for select using (
    public.get_user_role() = 'teacher' and exists (
      select 1 from public.enrolments e
      join public.live_sessions ls on ls.course_id = e.course_id
      where e.student_id = profiles.id and ls.teacher_id = auth.uid()
    )
  );

-- STUDENT VERIFICATIONS
create policy "Students see own verifications" on public.student_verifications
  for select using (student_id = auth.uid());
create policy "Staff can manage verifications" on public.student_verifications
  for all using (public.get_user_role() in ('admin','internal_verifier'));

-- COURSES
create policy "Students see active courses" on public.courses
  for select using (status = 'active' or public.get_user_role() in ('teacher','internal_verifier','admin'));
create policy "Admin can manage courses" on public.courses
  for all using (public.get_user_role() = 'admin');

-- ENROLMENTS
create policy "Students see own enrolments" on public.enrolments
  for select using (student_id = auth.uid());

-- SUBMISSIONS
create policy "Students see own submissions" on public.submissions
  for select using (student_id = auth.uid());
create policy "Students can create own submissions" on public.submissions
  for insert with check (student_id = auth.uid() and authenticity_declaration = true);
create policy "Staff see all submissions" on public.submissions
  for select using (public.get_user_role() in ('teacher','internal_verifier','admin'));

-- ASSESSMENT FEEDBACK
create policy "Students see own feedback" on public.assessment_feedback
  for select using (
    exists (select 1 from public.submissions s where s.id = submission_id and s.student_id = auth.uid())
  );
create policy "Staff manage feedback" on public.assessment_feedback
  for all using (public.get_user_role() in ('teacher','internal_verifier','admin'));

-- INTERNAL VERIFICATIONS
create policy "IV staff only" on public.internal_verifications
  for all using (public.get_user_role() in ('internal_verifier','admin'));

-- ACTIVITY LOGS
create policy "Admins read all logs" on public.activity_logs
  for select using (public.get_user_role() = 'admin');
create policy "System can insert logs" on public.activity_logs
  for insert with check (true);

-- EVIDENCE VAULT
create policy "Students see own evidence" on public.evidence_vault
  for select using (student_id = auth.uid());
create policy "Staff see all evidence" on public.evidence_vault
  for select using (public.get_user_role() in ('teacher','internal_verifier','admin'));
create policy "System inserts evidence" on public.evidence_vault
  for insert with check (true);

-- ============================================
-- STORAGE BUCKET POLICIES
-- ============================================

-- Buckets de creat manual in Supabase Dashboard:
-- 1. identity-documents (PRIVATE)
-- 2. assignment-submissions (PRIVATE)
-- 3. video-presentations (PRIVATE)
-- 4. course-materials (PUBLIC for enrolled)
-- 5. plagiarism-reports (PRIVATE — staff only)
-- 6. certificates (PRIVATE)
-- 7. evidence-archive (PRIVATE — admin/IV only)
-- 8. policies (PUBLIC)

-- Exemplu policy pentru identity-documents bucket:
-- (se configureaza in Supabase Dashboard sau via Management API)
/*
BEGIN;
  -- Insert bucket
  INSERT INTO storage.buckets (id, name, public) 
  VALUES ('identity-documents', 'identity-documents', false);
  
  -- RLS: only student can upload own documents
  CREATE POLICY "Students upload own ID" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'identity-documents' 
      AND auth.role() = 'authenticated'
      AND (storage.foldername(name))[1] = auth.uid()::text
    );
  
  -- RLS: only owner + admin can read
  CREATE POLICY "Own and admin read ID" ON storage.objects
    FOR SELECT USING (
      bucket_id = 'identity-documents'
      AND (
        (storage.foldername(name))[1] = auth.uid()::text
        OR public.get_user_role() IN ('admin', 'internal_verifier')
      )
    );
COMMIT;
*/