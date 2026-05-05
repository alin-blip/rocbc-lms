import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const { 
    assignment_id, file_url, video_url, word_count,
    authenticity_declaration, authenticity_text,
    ai_use_declared, ai_tools_used, ai_use_notes
  } = await req.json();
  
  if (!authenticity_declaration) {
    return new Response(
      JSON.stringify({ error: "Authenticity declaration is mandatory" }),
      { status: 400 }
    );
  }
  
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  const authHeader = req.headers.get("Authorization")!;
  const { data: { user } } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
  
  const { data: prev } = await supabase
    .from("submissions")
    .select("attempt_number")
    .eq("assignment_id", assignment_id)
    .eq("student_id", user!.id)
    .order("attempt_number", { ascending: false })
    .limit(1).maybeSingle();
  
  const attempt = (prev?.attempt_number ?? 0) + 1;
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  const ua = req.headers.get("user-agent") ?? "unknown";
  
  const { data: submission, error } = await supabase
    .from("submissions")
    .insert({
      assignment_id,
      student_id: user!.id,
      attempt_number: attempt,
      file_url, video_url, word_count,
      authenticity_declaration: true,
      authenticity_declaration_text: authenticity_text,
      authenticity_declared_at: new Date().toISOString(),
      ai_use_declared, ai_tools_used, ai_use_notes,
      submission_ip: ip,
      submission_user_agent: ua,
      status: "submitted"
    })
    .select().single();
  
  if (error) return new Response(error.message, { status: 500 });
  
  // Trigger async plagiarism scan
  const plagUrl = Deno.env.get("RAILWAY_API");
  if (plagUrl) {
    fetch(`${plagUrl}/plagiarism/scan`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ submission_id: submission.id, file_url })
    }).catch(() => {}); // fire-and-forget
  }
  
  return new Response(JSON.stringify(submission), {
    headers: { "Content-Type": "application/json" }
  });
});