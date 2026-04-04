import { createClient, type SupabaseClient, type User } from "https://esm.sh/@supabase/supabase-js@2.49.1";

/** Decode JWT payload (no verify) for `iss`, `ref`, `role`. */
function jwtPayloadJson(token: string): Record<string, unknown> | null {
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    let b64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const rem = b64.length % 4;
    if (rem) b64 += "=".repeat(4 - rem);
    return JSON.parse(atob(b64)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function jwtIss(token: string): string | null {
  const json = jwtPayloadJson(token);
  const iss = json?.iss;
  return typeof iss === "string" ? iss : null;
}

/**
 * Pick the GoTrue/PostgREST origin:
 * - Internal `SUPABASE_URL` → JWT `iss` host (`*.supabase.co`) when it differs from base.
 * - Wrong project ref in env → prefer `iss` when hostname differs from base.
 */
function resolveAuthApiOrigin(base: string, bearerToken: string): string {
  const trimmed = base.replace(/\/$/, "");
  let buHost = "";
  try {
    buHost = new URL(trimmed).hostname;
  } catch {
    return trimmed;
  }

  const iss = jwtIss(bearerToken);
  if (iss) {
    try {
      const iu = new URL(iss);
      if (
        iu.protocol === "https:" &&
        iu.hostname.endsWith(".supabase.co") &&
        iu.hostname !== buHost
      ) {
        return iu.origin;
      }
    } catch {
      /* ignore */
    }
  }

  if (buHost.endsWith("supabase.co") || buHost === "127.0.0.1" || buHost === "localhost") {
    return trimmed;
  }

  if (iss) {
    try {
      const u = new URL(iss);
      if (u.protocol === "https:" && u.hostname.endsWith(".supabase.co")) return u.origin;
    } catch {
      /* ignore */
    }
  }
  return trimmed;
}

/** Supabase API keys are JWTs; payload includes `ref` (project id) for hosted projects. */
function jwtPayloadRef(supabaseKey: string): string | null {
  const json = jwtPayloadJson(supabaseKey);
  const ref = typeof json?.ref === "string" ? json.ref.trim() : "";
  if (!ref || !/^[a-z0-9]{15,40}$/.test(ref)) return null;
  return ref;
}

/** `xyz.supabase.co` → lowercase project ref; null for bare `supabase.co`, pooler-style hosts, etc. */
function projectRefFromSupabaseCoHost(host: string): string | null {
  const m = /^([a-z0-9]{15,40})\.supabase\.co$/i.exec(host.trim());
  return m ? m[1].toLowerCase() : null;
}

/**
 * Public PostgREST/GoTrue origin for this function:
 * - Local dev (`127.0.0.1` / `localhost`): use `SUPABASE_URL` as-is.
 * - Already `*.supabase.co`: use iss-based resolver (wrong subdomain vs token).
 * - Internal/other host (kong, docker): `https://<ref>.supabase.co` from service JWT (matches injected keys).
 */
function pickApiOrigin(
  base: string,
  serviceKey: string,
  bearerToken: string,
): { origin: string; source: string } {
  const trimmed = base.replace(/\/$/, "");
  let buHost = "";
  try {
    buHost = new URL(trimmed).hostname;
  } catch {
    return { origin: resolveAuthApiOrigin(trimmed, bearerToken), source: "resolve_iss_invalid_base" };
  }
  if (buHost === "127.0.0.1" || buHost === "localhost") {
    return { origin: trimmed, source: "local_base" };
  }
  if (buHost.endsWith(".supabase.co")) {
    return { origin: resolveAuthApiOrigin(trimmed, bearerToken), source: "resolve_iss_public_base" };
  }
  const ref = jwtPayloadRef(serviceKey);
  if (ref) {
    return { origin: `https://${ref}.supabase.co`, source: "service_jwt_ref" };
  }
  return { origin: resolveAuthApiOrigin(trimmed, bearerToken), source: "resolve_iss_fallback" };
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
        JSON.stringify({ error: "Unauthorized" }),
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
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const sessionPayload = jwtPayloadJson(bearerToken);
  const sessionRole = typeof sessionPayload?.role === "string" ? sessionPayload.role : null;
  if (sessionRole === "service_role") {
    return {
      error: new Response(
        JSON.stringify({
          error:
            "Authorization carried a service key instead of a user access token. Ensure X-User-JWT is sent and not stripped by a proxy.",
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const svcRef = jwtPayloadRef(serviceKey);
  const iss = jwtIss(bearerToken);
  let tokenIssHost: string | null = null;
  if (iss) {
    try {
      tokenIssHost = new URL(iss).hostname;
    } catch {
      tokenIssHost = null;
    }
  }
  const refFromToken = tokenIssHost ? projectRefFromSupabaseCoHost(tokenIssHost) : null;
  if (svcRef && refFromToken && refFromToken !== svcRef.toLowerCase()) {
    const expectedHost = `${svcRef}.supabase.co`;
    return {
      error: new Response(
        JSON.stringify({
          error:
            "User session is for a different Supabase project than this function. Align `url` and `functionsUrl` in admin config with the same project.",
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      ),
    };
  }

  const authHeader = `Bearer ${bearerToken}`;
  const base = supabaseUrl.replace(/\/$/, "");
  const { origin: apiOrigin } = pickApiOrigin(base, serviceKey, bearerToken);
  const admin = createClient(apiOrigin, serviceKey);

  // 1) Auth REST (anon apikey first; retry with service role apikey if GoTrue rejects — anon/env drift)
  async function fetchAuthUser(apikey: string): Promise<{ res: Response; raw: string }> {
    const res = await fetch(`${apiOrigin}/auth/v1/user`, {
      headers: {
        Authorization: authHeader,
        apikey,
      },
    });
    const raw = await res.text();
    return { res, raw };
  }

  let { res: userRes, raw } = await fetchAuthUser(anonKey);
  let user: User | null = null;
  let errMsg = "Invalid session";

  function parseUserResponse(res: Response, text: string): User | null {
    try {
      const body = JSON.parse(text) as { user?: User; msg?: string; error_description?: string; error?: string };
      if (res.ok && body.user) return body.user;
      errMsg = body.msg || body.error_description || body.error || errMsg;
    } catch {
      if (!res.ok && text) errMsg = text.slice(0, 200);
    }
    return null;
  }

  user = parseUserResponse(userRes, raw);
  if (!user && userRes.status === 401) {
    const second = await fetchAuthUser(serviceKey);
    userRes = second.res;
    raw = second.raw;
    errMsg = "Invalid session";
    user = parseUserResponse(userRes, raw);
  }

  // 2) Service-role getUser (works when REST path is picky in Edge)
  if (!user) {
    const { data: gu, error: ge } = await admin.auth.getUser(bearerToken);
    if (!ge && gu.user) user = gu.user;
    else if (ge?.message) errMsg = `${errMsg} / ${ge.message}`;
  }

  if (!user) {
    return {
      error: new Response(
        JSON.stringify({ error: errMsg }),
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
      error: new Response(
        JSON.stringify({ error: "Forbidden" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      ),
    };
  }

  return { admin, user };
}
