# Prompt Lovable — ROCBC Pearson Distance Learning Platform

Copiază acest prompt în Lovable pentru a genera UI-ul complet.

---

Build a Pearson-compliant Distance Learning Platform for ROCBC...

CONTEXT:
ROCBC is a Pearson-approved education centre. This platform enables compliant distance learning delivery and must satisfy Pearson's DLSA (Distance Learning Self-Assessment) requirements across 9 domains: Governance, Technology, Staff, Learner Support, Course Design, Programme Structure, Teaching & Learning, Engagement, and Assessment.

TECH STACK:
- React + TypeScript + Tailwind
- Supabase (auth, database, storage, edge functions)
- shadcn/ui components
- Zustand for state
- React Query for data fetching
- Recharts for analytics

DESIGN SYSTEM:
- Primary: deep navy #1E2A47
- Accent gold: #D4A843
- Pearson red: #ED1C24 (sparingly for flags)
- Badges: pending=amber, approved=emerald, rejected=red, under_review=blue
- Typography: Inter (UI), Lora (content)
- Responsive + dark mode

ROLES: student, teacher, internal_verifier, admin

ROUTES:

PUBLIC: /, /login, /register, /policies/:type, /courses
STUDENT /student/*: dashboard, onboarding (ID→selfie→policies→quiz), courses/:id, lessons/:id, live-classes, assignments/:id (submission form), submissions/:id, forum, support, profile
TEACHER /teacher/*: dashboard, courses, students, live-classes, attendance/:sessionId, marking, marking/:submissionId, forum
IV /iv/*: dashboard, sampling, queue, verify/:submissionId, reports
ADMIN /admin/*: dashboard, users, users/:id, identity-queue, courses, courses/:id/builder, policies, staff-training, evidence-vault, audit-logs, dlsa, audit-pack, reports

KEY COMPONENTS:

1. IdentityVerificationFlow — upload ID, selfie capture, submit→pending, admin approve
2. InductionWizard — watch video, accept policies, pass quiz (70% threshold)
3. AssignmentSubmissionForm — brief panel, file upload, MANDATORY authenticity checkbox, MANDATORY AI use declaration, Submit disabled until declaration ticked
4. MarkingInterface — submission viewer, rubric, feedback, plagiarism report, oral questioning notes
5. InternalVerificationInterface — submission + marking side-by-side, agree/changes/remark
6. EvidenceVaultBrowser — filter by type/student/date, bulk export
7. DLSAComplianceDashboard — 9 Pearson domain cards with completeness %
8. AuditPackGenerator — course, date range, ZIP export

CRITICAL RULES:
- Student locked until: identity verified + induction + policies accepted
- No submission without authenticity declaration
- Feedback held until IV approval (if sampled)
- Soft deletes only (5yr retention)
- All actions logged to activity_logs
- Files via Supabase Storage signed URLs
- 1hr session timeout
- 2FA for staff

INTEGRATIONS: Zoom, Turnitin/Copyleaks, Stripe, Resend/SendGrid

BUILD ORDER:
1. Auth + role routing
2. Student onboarding
3. Course catalogue + enrolment
4. Assignment submission with declarations
5. Teacher marking
6. Internal verification
7. Admin dashboards + evidence vault
8. DLSA compliance + audit export

Deploy each iteration. No mock data — Supabase from day one.
