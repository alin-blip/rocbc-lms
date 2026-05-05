-- ROCBC Seed Data (development/testing)

-- Sample course
INSERT INTO public.courses (title, pearson_qualification_code, level, description, status)
VALUES ('Business Management Level 3', 'PEA-BUS-L3-001', 'Level 3', 'Foundation in business management principles, organisational behaviour, and strategic planning.', 'active');

-- Sample modules
INSERT INTO public.modules (course_id, title, learning_outcomes, position)
SELECT (SELECT id FROM public.courses LIMIT 1), 'Understanding Business Organisations', '["Explain different types of business organisations", "Analyse organisational structures", "Evaluate business objectives"]'::jsonb, 1;

INSERT INTO public.modules (course_id, title, learning_outcomes, position)
SELECT (SELECT id FROM public.courses LIMIT 1), 'Marketing Principles', '["Define marketing and its role in business", "Explain the marketing mix (7Ps)", "Analyse market segmentation strategies"]'::jsonb, 2;

-- Sample policies
INSERT INTO public.policies (policy_type, version, title, content_html, effective_from, is_active)
VALUES 
  ('assessment', '1.0', 'Assessment Policy', '<h1>Assessment Policy</h1><p>ROCBC ensures all assessments are valid, reliable, and aligned with Pearson standards.</p>', CURRENT_DATE, true),
  ('plagiarism', '1.0', 'Plagiarism & AI Policy', '<h1>Plagiarism & AI Policy</h1><p>All learners must submit original work. AI tools must be declared.</p>', CURRENT_DATE, true),
  ('authenticity', '1.0', 'Authenticity Policy', '<h1>Authenticity Policy</h1><p>Learners must confirm all submitted work is their own.</p>', CURRENT_DATE, true),
  ('data_protection', '1.0', 'Data Protection Policy', '<h1>Data Protection Policy</h1><p>ROCBC is GDPR compliant. All data is securely stored.</p>', CURRENT_DATE, true);

-- Sample assignment
INSERT INTO public.assignments (course_id, title, brief, due_date, max_word_count)
SELECT (SELECT id FROM public.courses LIMIT 1), 'Business Environment Report', 'Write a 2000-word report analysing the external business environment of a chosen organisation, including PESTLE analysis and competitive forces.', CURRENT_DATE + INTERVAL '30 days', 2000;
