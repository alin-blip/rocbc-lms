import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { student_id, decision, rejection_reason, notes } = await req.json();
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const authHeader = req.headers.get("Authorization")!;
  const { data: { user } } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
  
  const { data: verifier } = await supabase
    .from("profiles").select("role").eq("id", user!.id).single();
  
  if (!verifier || !["admin","internal_verifier"].includes(verifier.role)) {
    return new Response("Forbidden", { status: 403 });
  }
  
  const { error: vErr } = await supabase
    .from("student_verifications")
    .update({
      verification_status: decision,
      verified_by: user!.id,
      verified_at: new Date().toISOString(),
      rejection_reason,
      notes
    })
    .eq("student_id", student_id)
    .eq("verification_status", "pending");
  
  if (vErr) return new Response(vErr.message, { status: 500 });
  
  if (decision === "approved") {
    await supabase.from("profiles")
      .update({ identity_verified: true, status: "active" })
      .eq("id", student_id);
  }
  
  await supabase.from("evidence_vault").insert({
    student_id,
    evidence_type: "identity_verification",
    source_table: "student_verifications",
    description: `Identity ${decision} by ${verifier.role}`,
    metadata: { decision, notes, verified_by: user!.id }
  });
  
  await supabase.from("activity_logs").insert({
    user_id: user!.id,
    action: "verify_student_identity",
    entity_type: "student_verification",
    entity_id: student_id,
    metadata: { decision }
  });
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" }
  });
});