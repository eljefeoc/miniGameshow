import { corsHeaders, requireAdmin } from "../_shared/admin-guard.ts";

type Body = { email?: string; password?: string; display_name?: string };

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

  const email = String(body.email ?? "").trim();
  const password = String(body.password ?? "");
  const display_name = String(body.display_name ?? "").trim();

  if (!email || !password) {
    return new Response(JSON.stringify({ error: "email and password required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if (password.length < 6) {
    return new Response(JSON.stringify({ error: "password must be at least 6 characters" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const meta: Record<string, string> = {};
  if (display_name) meta.display_name = display_name;

  const { data, error } = await ctx.admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: Object.keys(meta).length ? meta : undefined,
  });

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({ user: { id: data.user?.id, email: data.user?.email } }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
