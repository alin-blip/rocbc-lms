# Pearson Audit Pack — Structură Export

```
ROCBC_Audit_Pack_[YYYY-MM-DD]/
├── 00_COVER_SHEET.pdf
│   ├── Centru: ROCBC (Romanian Online Centre)
│   ├── Pearson code: [codul oficial]
│   ├── Perioada: [date_from] — [date_to]
│   └── Statistici: studenți, submissions, pass rate
│
├── 01_GOVERNANCE/
│   ├── organigram.pdf
│   ├── centre_policies/ (toate 8 versionate)
│   └── staff_list.csv
│
├── 02_TECHNOLOGY/
│   ├── platform_architecture.md
│   ├── security_audit_logs.csv
│   └── backup_records.csv
│
├── 03_STAFF/
│   ├── staff_training_records.csv
│   ├── certifications/ (PDF-uri)
│   └── cpd_logs.csv
│
├── 04_LEARNER_SUPPORT/
│   ├── identity_verifications.csv
│   ├── induction_records.csv
│   ├── support_tickets.csv
│   └── policy_acceptances.csv
│
├── 05_COURSE_DESIGN/
│   ├── course_specs/ (per curs)
│   ├── module_breakdowns/
│   └── assessment_plans/
│
├── 06_PROGRAMME_STRUCTURE/
│   └── learner_handbook.pdf
│
├── 07_TEACHING_LEARNING/
│   ├── live_sessions.csv
│   ├── recordings_index.csv
│   └── communication_logs.csv
│
├── 08_ENGAGEMENT/
│   ├── attendance.csv
│   ├── forum_activity.csv
│   └── activity_logs.csv
│
├── 09_ASSESSMENT/
│   ├── submissions/[student_id]/[assignment]/
│   │   ├── submission_file
│   │   ├── authenticity_declaration.pdf
│   │   ├── feedback.pdf
│   │   ├── plagiarism_report.pdf
│   │   └── iv_record.pdf
│   └── assessment_summary.csv
│
└── 10_EVIDENCE_INDEX.csv
    └── Master index: tip evidență → locație → criteriu DLSA
```

## Generare

Via Edge Function `export-audit-pack` (automatizat) sau manual din Admin → Evidence Vault → Export audit pack.
