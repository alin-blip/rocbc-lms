import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { 
    feedback_id, agrees_with_assessment, decision, 
    comments, recommended_grade 
  } = await req.json();
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const authHeader = req.headers.get("Authorization")!;
  const { data: { user } } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
  
  const { data: profile } = await supabase
    .from("profiles").select("role").eq("id", user!.id).single();
  
  if (profile?.role !== "internal_verifier" && profile?.role !== "admin") {
    return new Response("Forbidden", { status: 403 });
  }
  
  const { data: fb } = await supabase
    .from("assessment_feedback")
    .select("*, submission:submissions(*) ")
    .eq("id", feedback_id).single();
  
  if (!fb) return new Response("Feedback not found", { status: 404 });
  
  await supabase.from("internal_verifications").insert({
    submission_id: fb.submission_id,
    feedback_id,
    verifier_id: user!.id,
    sampling_method: "targeted",
    agrees_with_assessment,
    decision,
    comments,
    original_grade: fb.decision,
    recommended_grade
  });
  
  let newStatus = "feedback_provided";
  if (decision === "rejected" || decision === "changes_required") {
    newStatus = "under_review"; // back to assessor
  } else if (decision === "remarked") {
    newStatus = "passed";
  } else if (fb.decision === "fail") {
    newStatus = "failed";
  }
  
  await supabase.from("submissions")
    .update({ status: newStatus })
    .eq("id", fb.submission_id);
  
  return new Response(JSON.stringify({ success: true, status: newStatus }), {
    headers: { "Content-Type": "application/json" }
  });
});