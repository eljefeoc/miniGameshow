import { corsHeaders, requireAdmin } from "../_shared/admin-guard.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const ctx = await requireAdmin(req);
  if ("error" in ctx) return ctx.error;

  const { admin } = ctx;
  const allUsers: { id: string; email?: string; created_at?: string }[] = [];
  let page = 1;
  const perPage = 200;
  for (;;) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage });
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    const batch = data.users ?? [];
    allUsers.push(
      ...batch.map((u) => ({
        id: u.id,
        email: u.email,
        created_at: u.created_at,
      })),
    );
    if (batch.length < perPage) break;
    page += 1;
  }

  const ids = allUsers.map((u) => u.id);
  const { data: profs } = await admin
    .from("profiles")
    .select("id, username, display_name, is_admin, is_banned")
    .in("id", ids);

  const pmap = new Map((profs ?? []).map((p) => [p.id, p]));

  const users = allUsers.map((u) => {
    const p = pmap.get(u.id);
    return {
      id: u.id,
      email: u.email ?? "",
      created_at: u.created_at ?? null,
      username: p?.username ?? null,
      display_name: p?.display_name ?? null,
      is_admin: p?.is_admin === true,
      is_banned: p?.is_banned === true,
    };
  });

  return new Response(JSON.stringify({ users }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
