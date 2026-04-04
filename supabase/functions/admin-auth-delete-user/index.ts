import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { corsHeaders, requireAdmin } from "../_shared/admin-guard.ts";

type Body = { user_id?: string };

/** Delete competition rows before GoTrue removes auth.users (avoids FK / trigger ordering issues). */
async function purgeUserCompetitionData(admin: SupabaseClient, targetUserId: string): Promise<{ error: string | null }> {
  const { data: lbRows, error: lbErr } = await admin.from("leaderboard").select("week_id").eq("user_id", targetUserId);
  if (lbErr) return { error: lbErr.message };
  const { data: runRows, error: runErr } = await admin.from("runs").select("week_id").eq("user_id", targetUserId);
  if (runErr) return { error: runErr.message };
  const weeks = new Set<string>();
  for (const r of lbRows ?? []) {
    if (r.week_id) weeks.add(String(r.week_id));
  }
  for (const r of runRows ?? []) {
    if (r.week_id) weeks.add(String(r.week_id));
  }

  const { error: e1 } = await admin.from("leaderboard").delete().eq("user_id", targetUserId);
  if (e1) return { error: e1.message };
  const { error: e2 } = await admin.from("runs").delete().eq("user_id", targetUserId);
  if (e2) return { error: e2.message };
  const { error: e3 } = await admin.from("daily_attempts").delete().eq("user_id", targetUserId);
  if (e3) return { error: e3.message };

  for (const w of weeks) {
    const { error: re } = await admin.rpc("refresh_leaderboard_ranks", { p_week_id: w });
    if (re) console.warn("refresh_leaderboard_ranks failed:", w, re.message);
  }
  return { error: null };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const ctx = await requireAdmin(req);
  if ("error" in ctx) return ctx.error;

  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const user_id = String(body.user_id ?? "").trim();
  if (!user_id) {
    return new Response(JSON.stringify({ error: "user_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (user_id === ctx.user.id) {
    return new Response(JSON.stringify({ error: "cannot delete your own account" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { error: purgeErr } = await purgeUserCompetitionData(ctx.admin, user_id);
  if (purgeErr) {
    return new Response(JSON.stringify({ error: `pre-delete purge: ${purgeErr}` }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { error } = await ctx.admin.auth.admin.deleteUser(user_id);
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
