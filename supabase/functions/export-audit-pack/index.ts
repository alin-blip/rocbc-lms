import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { course_id, student_id, date_from, date_to } = await req.json();
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const [
    { data: courses },
    { data: students },
    { data: identityRecords },
    { data: inductions },
    { data: attendance },
    { data: submissions },
    { data: feedback },
    { data: plagiarism },
    { data: ivRecords },
    { data: activityLogs },
    { data: policies },
    { data: evidence }
  ] = await Promise.all([
    supabase.from("courses").select("*")
      .when(course_id, (q) => q.eq("id", course_id)),
    supabase.from("profiles").select("*").eq("role", "student")
      .when(student_id, (q) => q.eq("id", student_id)),
    supabase.from("student_verifications").select("*"),
    supabase.from("inductions").select("*"),
    supabase.from("attendance").select("*, session:live_sessions(*)"),
    supabase.from("submissions").select("*, assignment:assignments(*)"),
    supabase.from("assessment_feedback").select("*"),
    supabase.from("plagiarism_reports").select("*"),
    supabase.from("internal_verifications").select("*"),
    supabase.from("activity_logs").select("*"),
    supabase.from("policies").select("*"),
    supabase.from("evidence_vault").select("*")
  ]);
  
  // Build export payload for Railway ZIP generator
  const exportPayload = {
    centre: "ROCBC",
    generated_at: new Date().toISOString(),
    course_id, student_id, date_from, date_to,
    statistics: {
      total_students: students?.length ?? 0,
      total_submissions: submissions?.length ?? 0,
      total_feedback: feedback?.length ?? 0,
      total_iv_records: ivRecords?.length ?? 0,
      pass_rates: {}
    },
    data: {
      courses, students, identityRecords, inductions,
      attendance, submissions, feedback, plagiarism,
      ivRecords, activityLogs, policies, evidence
    }
  };
  
  // Call Railway service to generate ZIP
  let zip_url = "";
  const railApi = Deno.env.get("RAILWAY_API");
  if (railApi) {
    const resp = await fetch(`${railApi}/generate-audit-zip`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(exportPayload)
    });
    const result = await resp.json();
    zip_url = result.zip_url ?? "";
  }
  
  // Log the export
  if (zip_url) {
    await supabase.from("evidence_vault").insert({
      student_id: student_id ?? null,
      course_id,
      evidence_type: "grade_record",
      file_url: zip_url,
      description: `Pearson Audit Pack — ${new Date().toISOString().split("T")[0]}`,
      retention_until: new Date(Date.now() + 5*365*24*60*60*1000).toISOString().split("T")[0]
    });
  }
  
  return new Response(JSON.stringify({ zip_url, export_summary: exportPayload.statistics }), {
    headers: { "Content-Type": "application/json" }
  });
});