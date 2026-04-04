import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

/** Decode JWT payload `iss` without verifying (debug + host fix only). */
function jwtIss(token: string): string | null {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const pad = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const json = JSON.parse(atob(pad)) as { iss?: string };
    return typeof json.iss === "string" ? json.iss : null;
  } catch {
    return null;
  }
}

/**
 * Edge `SUPABASE_URL` is sometimes an internal host (e.g. kong). GoTrue must be called on the
 * public `*.supabase.co` origin or `/auth/v1/user` returns "Invalid JWT" for valid access tokens.
 */
function resolveAuthApiOrigin(base: string, bearerToken: string): string {
  const trimmed = base.replace(/\/$/, "");
  try {
    const host = new URL(trimmed).hostname;
    if (host.endsWith("supabase.co") || host === "127.0.0.1" || host === "localhost") {
      return trimmed;
    }
  } catch {
    return trimmed;
  }
  const iss = jwtIss(bearerToken);
  if (!iss) return trimmed;
  try {
    const u = new URL(iss);
    if (u.hostname.endsWith(".supabase.co")) return u.origin;
  } catch {
    /* ignore */
  }
  return trimmed;
}

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
      error: new Response(
        JSON.stringify({
          error: "Unauthorized",
          debug: { branch: "no_bearer", hypothesisId: "H5", hasXJwt: Boolean(xJwt), authValLen: authVal.length },
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }
  if (bearerToken === anonKey) {
    return {
      error: new Response(
        JSON.stringify({
          error:
            "No user session on this request (only anon key). Hard-refresh admin, sign out/in, or check adblock stripping the X-User-JWT header.",
          debug: { branch: "bearer_is_anon", hypothesisId: "H5" },
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const authHeader = `Bearer ${bearerToken}`;
  const base = supabaseUrl.replace(/\/$/, "");
  const apiOrigin = resolveAuthApiOrigin(base, bearerToken);
  const admin = createClient(apiOrigin, serviceKey);

  // 1) Auth REST (must hit public GoTrue origin when env URL is internal)
  const userRes = await fetch(`${apiOrigin}/auth/v1/user`, {
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
  let getUserErr: string | null = null;
  if (!user) {
    const { data: gu, error: ge } = await admin.auth.getUser(bearerToken);
    if (!ge && gu.user) user = gu.user;
    else if (ge?.message) {
      getUserErr = ge.message;
      errMsg = `${errMsg} / ${ge.message}`;
    }
  }

  if (!user) {
    let baseHost = "";
    let apiHost = "";
    try {
      baseHost = new URL(base).hostname;
    } catch {
      baseHost = "invalid_supabase_url";
    }
    try {
      apiHost = new URL(apiOrigin).hostname;
    } catch {
      apiHost = "invalid_api_origin";
    }
    return {
      error: new Response(
        JSON.stringify({
          error: errMsg,
          debug: {
            hypothesisId: "H1-H3",
            userResStatus: userRes.status,
            restErrSnippet: raw.slice(0, 120),
            getUserErr,
            baseHost,
            apiHost,
            accessTokenIssHost: (() => {
              const iss = jwtIss(bearerToken);
              if (!iss) return null;
              try {
                return new URL(iss).hostname;
              } catch {
                return null;
              }
            })(),
            bearerLen: bearerToken.length,
            anonLen: anonKey.length,
            hadXJwt: Boolean(xJwt),
          },
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
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
