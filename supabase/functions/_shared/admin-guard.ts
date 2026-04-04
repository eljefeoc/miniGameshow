import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

export type AdminContext = {
  admin: SupabaseClient;
  user: User;
};

export async function requireAdmin(req: Request): Promise<
  AdminContext | { error: Response }
> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return {
      error: new Response(
        JSON.stringify({
          error: "Server missing Supabase secrets (need SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY)",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return {
      error: new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  // Validate JWT via Auth REST (same as PostgREST). supabase-js getUser() from Edge often returns "Invalid JWT" even when the token is valid.
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
  if (!user) {
    return {
      error: new Response(JSON.stringify({ error: errMsg }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }),
    };
  }

  const admin = createClient(supabaseUrl, serviceKey);

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
