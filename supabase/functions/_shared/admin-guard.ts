import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-user-jwt",
};

export type AdminContext = {
  admin: SupabaseClient;
  user: User;
};

export async function requireAdmin(req: Request): Promise<
  AdminContext | { error: Response }
> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  // Use the same anon key the browser sends (admin.html sets `apikey`). Edge-injected SUPABASE_ANON_KEY can drift from local/Vercel config and cause "Invalid JWT" on auth/v1/user while PostgREST still works.
  const anonKey =
    req.headers.get("apikey")?.trim() ||
    Deno.env.get("SUPABASE_ANON_KEY") ||
    "";
  if (!supabaseUrl || !serviceKey) {
    return {
      error: new Response(
        JSON.stringify({
          error: "Server missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }
  if (!anonKey) {
    return {
      error: new Response(
        JSON.stringify({
          error: "Missing apikey header (anon key) or SUPABASE_ANON_KEY secret",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const authVal =
    req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "")?.trim() || "";
  const xJwt = req.headers.get("x-user-jwt")?.trim() || "";
  // Prefer X-User-JWT; else Authorization. Never treat anon key as user session (happens if custom header is stripped).
  let bearerToken = xJwt || authVal;
  if (!bearerToken) {
    return {
      error: new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }
  if (bearerToken === anonKey) {
    return {
      error: new Response(
        JSON.stringify({
          error:
            "No user session on this request (only anon key). Hard-refresh admin, sign out/in, or check adblock stripping the X-User-JWT header.",
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const authHeader = `Bearer ${bearerToken}`;
  const admin = createClient(supabaseUrl, serviceKey);

  // 1) Auth REST
  const base = supabaseUrl.replace(/\/$/, "");
  const userRes = await fetch(`${base}/auth/v1/user`, {
    headers: {
      Authorization: authHeader,
      apikey: anonKey,
    },
  });
  const raw = await userRes.text();
  let user: User | null = null;
  let errMsg = "Invalid session";
  try {
    const body = JSON.parse(raw) as { user?: User; msg?: string; error_description?: string; error?: string };
    if (userRes.ok && body.user) user = body.user;
    else {
      errMsg = body.msg || body.error_description || body.error || errMsg;
    }
  } catch {
    if (!userRes.ok && raw) errMsg = raw.slice(0, 200);
  }

  // 2) Service-role getUser (works when REST path is picky in Edge)
  if (!user) {
    const { data: gu, error: ge } = await admin.auth.getUser(bearerToken);
    if (!ge && gu.user) user = gu.user;
    else if (ge?.message) errMsg = `${errMsg} / ${ge.message}`;
  }

  if (!user) {
    return {
      error: new Response(JSON.stringify({ error: errMsg }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  const { data: prof, error: perr } = await admin
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .maybeSingle();

  if (perr || !prof?.is_admin) {
    return {
      error: new Response(JSON.stringify({ error: "Forbidden" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  return { admin, user };
}
