import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { 
    submission_id, marks_awarded, overall_feedback, 
    strengths, improvements, decision, oral_questioning_notes 
  } = await req.json();
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const authHeader = req.headers.get("Authorization")!;
  const { data: { user } } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
  
  const { data: profile } = await supabase
    .from("profiles").select("role").eq("id", user!.id).single();
  if (profile?.role !== "teacher") return new Response("Forbidden", { status: 403 });
  
  // Get submission for context
  const { data: submission } = await supabase
    .from("submissions")
    .select("id, student_id, assignment_id, attempt_number")
    .eq("id", submission_id).single();
  
  // Create feedback
  const { data: feedback, error: fbErr } = await supabase
    .from("assessment_feedback")
    .insert({
      submission_id,
      assessor_id: user!.id,
      marks_awarded,
      overall_feedback,
      strengths,
      improvements,
      decision,
      oral_questioning_notes
    })
    .select().single();
  
  if (fbErr) return new Response(fbErr.message, { status: 500 });
  
  // Check if IV sampling is required
  const { count: assessorCount } = await supabase
    .from("assessment_feedback")
    .select("*", { count: "exact", head: true })
    .eq("assessor_id", user!.id);
  
  const requiresIV = (
    (assessorCount ?? 0) <= 3 ||
    ['fail','refer','resubmit'].includes(decision) ||
    decision === 'distinction'
  );
  
  await supabase.from("submissions")
    .update({ status: requiresIV ? "under_review" : (
      decision === 'fail' || decision === 'refer' ? "feedback_provided" : "passed"
    )})
    .eq("id", submission_id);
  
  return new Response(JSON.stringify({ 
    feedback, 
    requires_iv: requiresIV 
  }), {
    headers: { "Content-Type": "application/json" }
  });
});