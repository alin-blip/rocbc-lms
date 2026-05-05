-- ROCBC Storage Bucket Policies
-- Create these 8 buckets in Supabase Dashboard > Storage:
-- 1. identity-documents (PRIVATE)
-- 2. assignment-submissions (PRIVATE)
-- 3. video-presentations (PRIVATE)
-- 4. course-materials (PUBLIC)
-- 5. plagiarism-reports (PRIVATE)
-- 6. certificates (PRIVATE)
-- 7. evidence-archive (PRIVATE)
-- 8. policies (PUBLIC)

-- ===================== IDENTITY DOCUMENTS =====================
CREATE POLICY "Students upload own ID" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'identity-documents' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Read ID" ON storage.objects FOR SELECT
USING (bucket_id = 'identity-documents' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role() IN ('admin','internal_verifier')));

-- ===================== ASSIGNMENT SUBMISSIONS =====================
CREATE POLICY "Students upload submissions" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'assignment-submissions' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Read submissions" ON storage.objects FOR SELECT
USING (bucket_id = 'assignment-submissions' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role() IN ('teacher','internal_verifier','admin')));

-- ===================== VIDEO PRESENTATIONS =====================
CREATE POLICY "Students upload videos" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'video-presentations' AND auth.role() = 'authenticated' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "Read videos" ON storage.objects FOR SELECT
USING (bucket_id = 'video-presentations' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role() IN ('teacher','internal_verifier','admin')));

-- ===================== PLAGIARISM REPORTS =====================
CREATE POLICY "Staff manage plagiarism" ON storage.objects FOR ALL
USING (bucket_id = 'plagiarism-reports' AND public.get_user_role() IN ('teacher','internal_verifier','admin'));

-- ===================== CERTIFICATES =====================
CREATE POLICY "Students view own certs" ON storage.objects FOR SELECT
USING (bucket_id = 'certificates' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role() = 'admin'));
CREATE POLICY "Admin upload certs" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'certificates' AND public.get_user_role() = 'admin');

-- ===================== EVIDENCE ARCHIVE =====================
CREATE POLICY "Admin/IV manage evidence" ON storage.objects FOR ALL
USING (bucket_id = 'evidence-archive' AND public.get_user_role() IN ('internal_verifier','admin'));

-- ===================== COURSE MATERIALS =====================
CREATE POLICY "Staff upload materials" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'course-materials' AND public.get_user_role() IN ('teacher','admin'));
CREATE POLICY "Enrolled read materials" ON storage.objects FOR SELECT
USING (bucket_id = 'course-materials' AND auth.role() = 'authenticated');

-- ===================== POLICIES =====================
CREATE POLICY "Anyone read policies" ON storage.objects FOR SELECT
USING (bucket_id = 'policies');
CREATE POLICY "Admin upload policies" ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'policies' AND public.get_user_role() = 'admin');
