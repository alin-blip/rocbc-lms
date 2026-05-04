# ROCBC — Pearson Distance Learning Platform

Platformă LMS distance learning pentru **ROCBC** (centru certificat Pearson România).

## Stack
- **Frontend:** Lovable (React + TypeScript + Tailwind)
- **Backend:** Supabase (Postgres + Auth + Storage + Edge Functions)
- **Hosting:** Railway
- **Code:** GitHub
- **Live classes:** Zoom
- **Plagiarism:** Turnitin / Copyleaks
- **Auth:** Supabase Auth (2FA for staff)

## Structură

```
supabase/
  migrations/     → Schema DB completă
  functions/      → Edge Functions (TypeScript)
  storage/        → Bucket RLS policies
docs/
  DLSA_TEMPLATE.md      → Self-assessment template Pearson
  LOVABLE_PROMPT.md      → Prompt pentru generare UI
  AUDIT_PACK_STRUCTURE.md → Structură audit export
  policies/              → 8 politici oficiale complete
src/
  types/database.types.ts → TypeScript types
```

## Roluri (4)
1. **Student** — onboarding, cursuri, live classes, assignments, forum
2. **Teacher (Assessor)** — marking, feedback, plagiarism, oral questioning
3. **Internal Verifier** — QA sampling, audit
4. **Admin** — users, courses, evidence vault, DLSA export

## Deployment

1. Clonează repo-ul
2. Creează un proiect Supabase
3. Rulează `supabase/migrations/001_initial_schema.sql`
4. Deploy Edge Functions
5. Configurează Lovable cu acest repo

---

**License:** MIT