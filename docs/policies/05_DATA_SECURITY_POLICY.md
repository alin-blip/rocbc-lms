# Data & Security Policy — ROCBC

**Version:** 1.0  
**Effective from:** [date]

## 1. Purpose

To protect learner data, ensure GDPR compliance, and maintain secure operation of the distance learning platform.

## 2. Data Controller

ROCBC is the data controller. All data is processed in accordance with GDPR (EU) 2016/679 and UK GDPR.

## 3. Data Collected

- Personal identification (name, DOB, nationality, ID documents)
- Contact details (email, phone, address)
- Academic records (enrolments, attendance, submissions, grades)
- Platform usage logs
- Communication records (support tickets, forum posts)

## 4. Data Storage

- All data stored in Supabase (EU region)
- Files stored in Supabase Storage (encrypted at rest)
- Database encrypted (AES-256)
- Backups: daily automated, retained 30 days
- All transmissions encrypted via TLS 1.3

## 5. Access Control

- Role-based access (student, teacher, IV, admin)
- 2FA required for teacher/IV/admin roles
- Session timeout after 1 hour inactivity
- All access logged in activity_logs table

## 6. Retention

| Data Type | Retention Period |
|-----------|-----------------|
| Active learner records | Duration of enrolment + 5 years |
| Assessment evidence | 5 years (Pearson requirement) |
| ID documents | 5 years after last enrolment |
| Activity logs | 3 years |
| Support tickets | 2 years after closure |

## 7. Data Subject Rights

Learners may:
- Request access to their data (subject access request)
- Request rectification of inaccurate data
- Request erasure (subject to Pearson retention requirements)
- Request portability
- Withdraw consent

## 8. Breach Notification

Any data breach will be reported to the relevant supervisory authority within 72 hours and to affected individuals without undue delay.

## 9. Third-Party Processors

- Supabase (database, storage, auth)
- Railway (hosting)
- Zoom (live sessions)
- Turnitin/Copyleaks (plagiarism detection)
- Resend/SendGrid (email)

All processors have DPA agreements in place.
