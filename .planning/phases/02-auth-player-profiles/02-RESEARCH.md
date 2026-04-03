# Phase 2: Auth & Player Profiles — Research

**Researched:** 2026-04-03
**Domain:** Supabase Auth (email/password), PostgreSQL schema migration, vanilla JS state machine
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | User can sign up with email and password (existing — needs polish) | Existing `bootSupabaseAuth()` / `auth-signup` button; requires adding display name + age checkbox to HTML form and updating JS handler to use `signUp({ options: { data: { display_name, is_18_plus } } })` |
| AUTH-02 | User can sign in and session persists across browser refresh | Already implemented via `persistSession:true`, `autoRefreshToken:true`, `detectSessionInUrl:true` on the Supabase client — only needs verification and minor polish |
| AUTH-03 | User can reset password via email link | Not yet implemented; requires `sb.auth.resetPasswordForEmail(email)` call + in-place form swap (no navigation) + `PASSWORD_RECOVERY` event handler in `onAuthStateChange` |
| AUTH-04 | User sets a display name during signup (shown on leaderboard) | Passed as `options.data.display_name` in `signUp`; `handle_new_user` trigger must be updated to read `raw_user_meta_data->>'display_name'` and write to `profiles.display_name` (new column) |
| AUTH-05 | User declares age (18+) during signup; stored on profile; gates prize eligibility | Checkbox → `options.data.is_18_plus` in `signUp`; `handle_new_user` trigger writes `is_18_plus` bool to new `profiles.is_18_plus` column; migration adds the column |
| AUTH-06 | Users under 18 can play but are placed in a separate practice leaderboard, cannot win prizes | `is_18_plus` flag read from `profiles` on sign-in; fed into `playMode` state machine as new `'practice'` value; Practice Mode indicator shown in first-play card per UI-SPEC |
</phase_requirements>

---

## Summary

Phase 2 is a focused extension of existing infrastructure, not a greenfield auth build. The Supabase client is already initialized with session persistence and the `onAuthStateChange` listener. Sign-up and sign-in already work at the HTTP level — what is missing is the UI polish (display name field, age checkbox), the profile schema additions (`display_name`, `is_18_plus` columns), and the age-gated play mode path.

The three plans map cleanly to three separable concerns: (1) extending the signup form and schema, (2) adding the forgot-password flow and account tab, and (3) wiring the `is_18_plus` flag into the play mode state machine. These are independent enough to be executed in order without tight coupling between plans.

The one non-trivial area is the `PASSWORD_RECOVERY` event. Supabase emits both a `SIGNED_IN` and a `PASSWORD_RECOVERY` event when the user follows a reset link back to the same page. The existing `onAuthStateChange` handler must be extended to detect the `PASSWORD_RECOVERY` event and show the "set new password" UI state in-place rather than routing to a new page — consistent with the UI-SPEC's "JS swap, no page navigation" requirement.

**Primary recommendation:** Execute the three plans in strict order. Schema migration (adding `display_name` + `is_18_plus` to `profiles`) must land before plan 1 ships, since the `handle_new_user` trigger is what captures both fields at signup time with zero client-side data loss.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @supabase/supabase-js | 2.101.1 (pinned, confirmed current) | Auth (signUp, signIn, resetPasswordForEmail, onAuthStateChange), Postgres client | Already in use, SECU-03 compliant, version confirmed via `npm view` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Native browser APIs | — | DOM manipulation, `document.getElementById`, `addEventListener` | All UI changes — no framework |
| CSS custom properties | — | Token system already established in `:root` | Reference existing tokens per UI-SPEC; no new tokens needed |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-place JS form swap for forgot-password | Navigate to a separate `/reset-password` URL | Separate URL would require Vercel rewrite and second HTML file; in-place swap matches existing SPA pattern and UI-SPEC requirement |
| Storing `display_name` in `profiles` table | Use `auth.users.raw_user_meta_data` only | `profiles` table is the canonical app data layer; leaderboard joins on `profiles` already; client reads profile not auth metadata |

**Installation:** No new packages. Supabase JS is CDN-loaded. No npm install needed.

**Version verification:** `npm view @supabase/supabase-js version` → `2.101.1` (confirmed 2026-04-03). Pinned CDN URL is already current.

---

## Architecture Patterns

### Recommended Project Structure

No new files needed for Plans 1–2. Plan 3 modifies existing functions only.

```
prototypes/
├── penguin-game.html    # All auth form changes, playMode updates, account tab
supabase/
├── migrations/
│   └── 20260403_add_display_name_is_18_plus.sql   # New — adds columns, updates trigger
├── schema.sql           # Updated to match migration (canonical reference)
```

### Pattern 1: signUp with user metadata

Pass display name and age declaration in `options.data` — these become `raw_user_meta_data` in `auth.users` and are immediately available in the `handle_new_user` trigger via `NEW.raw_user_meta_data`.

```js
// Source: https://supabase.com/docs/guides/auth/managing-user-data (verified)
const { error } = await sb.auth.signUp({
  email,
  password,
  options: {
    data: {
      display_name: displayNameValue,  // stored to profiles.display_name via trigger
      is_18_plus: ageCheckbox.checked  // stored to profiles.is_18_plus via trigger
    }
  }
});
```

### Pattern 2: handle_new_user trigger update

The existing trigger already reads `raw_user_meta_data->>'username'`. It must be updated to also read `display_name` and `is_18_plus`. The migration adds both columns before updating the trigger.

```sql
-- Source: verified against supabase/schema.sql line 144–158
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, is_18_plus)
  VALUES (
    NEW.id,
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    COALESCE((NEW.raw_user_meta_data->>'is_18_plus')::boolean, false)
  );
  RETURN NEW;
END;
$$;
```

Note: the existing trigger uses `username` column. Phase 2 replaces `username` storage with `display_name`. The `username` column can remain for backward compatibility but `display_name` becomes the canonical leaderboard display name going forward.

### Pattern 3: Password reset — in-place form swap

No redirectTo required for this SPA. `detectSessionInUrl: true` on the client handles the recovery token automatically when the user is redirected back to the same origin. The `onAuthStateChange` handler must be extended to catch the `PASSWORD_RECOVERY` event.

```js
// Send reset email (no redirectTo — same-origin SPA)
// Source: https://supabase.com/docs/reference/javascript/auth-resetpasswordforemail (verified)
const { error } = await sb.auth.resetPasswordForEmail(email);

// In onAuthStateChange handler (extend existing):
sb.auth.onAuthStateChange(async (event, session) => {
  if (event === 'PASSWORD_RECOVERY') {
    // Show "enter new password" UI state in place
    showPasswordResetForm();
    return;
  }
  if (session?.user) await onSignedIn(session);
  else onSignedOut();
});
```

After the user enters a new password:
```js
// Source: Supabase docs auth-updateuser (verified pattern)
const { error } = await sb.auth.updateUser({ password: newPassword });
```

### Pattern 4: Reading is_18_plus on sign-in

Extend `onSignedIn()` to fetch `is_18_plus` (and `display_name`) from `profiles` alongside the existing `username` fetch. Store as module-level variable `playerIs18Plus`. Feed into `fetchAttemptsAndSetMode` to set `playMode`.

```js
// Extend existing onSignedIn() fetch — verified against penguin-game.html lines 2597–2601
const { data: prof } = await sb.from('profiles')
  .select('display_name, is_18_plus')
  .eq('id', session.user.id)
  .maybeSingle();
playerName = prof?.display_name || session.user.email?.split('@')[0] || '';
playerIs18Plus = prof?.is_18_plus ?? false;
```

### Pattern 5: play mode state machine — adding 'practice' mode

The existing `playMode` has three values: `'guest'`, `'competing'`, `'freeplay'`. AUTH-06 requires a new path for under-18 signed-in users.

**Updated state transitions:**

```
guest ──sign in (18+)──▶ competing ──5 attempts──▶ freeplay
guest ──sign in (<18)──▶ practice  ──5 attempts──▶ freeplay
  ▲                              │
  └───────────sign out───────────┘
```

Under-18 users in `practice` mode:
- Use the daily seed (same as `competing`) so scores are tracked day-to-day
- Scores ARE saved to Supabase runs table (same as `competing`) but tagged for practice leaderboard separation (handled in Phase 4 LBRD-03)
- Cannot win prizes — `is_18_plus` column on profiles gates this at Phase 4

For Phase 2 scope: `playMode = 'practice'` is set when `playerIs18Plus === false` and user has attempts remaining. The Practice Mode indicator (amber notice block per UI-SPEC) is shown in the first-play card. Scores are saved normally — leaderboard separation is Phase 4 work.

### Anti-Patterns to Avoid
- **alert() for auth errors:** The existing signup handler uses `alert(error.message)`. Phase 2 must replace all `alert()` calls in auth handlers with inline `#auth-status` updates per the UI-SPEC copywriting contract.
- **Storing is_18_plus only in raw_user_meta_data:** Must be written to `profiles.is_18_plus` via the trigger — not read from `auth.users` metadata at runtime (RLS prevents `auth.users` reads from client).
- **Blocking form submit while waiting:** Use the "···" loading state on the CTA button (pointer-events:none + text swap) while Supabase calls are in flight. Do not disable the entire form.
- **Forgetting to guard PASSWORD_RECOVERY:** If the `onAuthStateChange` handler doesn't check for `PASSWORD_RECOVERY` before calling `onSignedIn`, a password-reset click will call `onSignedIn` directly (Supabase emits both `SIGNED_IN` and `PASSWORD_RECOVERY`). The `PASSWORD_RECOVERY` check must come first.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session persistence across refresh | Custom localStorage token management | `persistSession: true` already configured | Already working in the prototype; `sb.auth.getSession()` at boot restores session |
| Password reset token generation and email | Custom email flow | `sb.auth.resetPasswordForEmail(email)` | Supabase handles token generation, email delivery, and token validation |
| Password reset link handling / token extraction | Parse URL hash manually | `detectSessionInUrl: true` already configured | Client auto-processes the `#access_token` or `?code=` fragment on page load |
| Age field encryption / obfuscation | Custom crypto | Plain boolean `is_18_plus` on profiles | The age declaration is a checkbox attestation, not a verified ID; storing a boolean is the correct scope for v1 |

**Key insight:** All token handling and session recovery is already delegated to Supabase JS. The work in Phase 2 is entirely UI plumbing + schema additions — no custom auth infrastructure.

---

## Common Pitfalls

### Pitfall 1: Missing schema migration — display_name and is_18_plus don't exist yet
**What goes wrong:** `handle_new_user` trigger runs fine but silently drops the data because the columns don't exist. Sign-up appears to succeed but the profile has no display_name or is_18_plus.
**Why it happens:** The current `profiles` table schema has only `id`, `username`, `phone`, `phone_verified`, `country`, `is_banned`, `is_admin`, `created_at`, `updated_at`. Neither `display_name` nor `is_18_plus` exist.
**How to avoid:** Migration adding both columns must be written and applied BEFORE any code changes that pass this data via `signUp`. Write migration first, apply via `supabase db push` or SQL Editor, then update trigger, then update JS.
**Warning signs:** Profile row created but `display_name` is null even after signup with a name entered.

### Pitfall 2: alert() calls bypass the UI-SPEC error display
**What goes wrong:** Auth errors show native browser alert dialogs instead of the styled inline `#auth-status` span.
**Why it happens:** The existing `bootSupabaseAuth()` uses `alert(error.message)` for both sign-in and sign-up errors (lines 2669, 2676).
**How to avoid:** Replace all `alert()` in auth handlers with `statusEl.textContent = <copywriting contract message>; statusEl.style.color = '#f5a0a0';`. Map Supabase error codes to the exact copy strings from the UI-SPEC copywriting contract.
**Warning signs:** Any `alert()` call remaining in the auth section after Phase 2.

### Pitfall 3: PASSWORD_RECOVERY event fires alongside SIGNED_IN
**What goes wrong:** User clicks reset link, lands back on the game, and immediately gets signed in as a normal session rather than seeing the "enter new password" UI.
**Why it happens:** Supabase fires both `SIGNED_IN` and `PASSWORD_RECOVERY` events in sequence when following a reset link. If `onAuthStateChange` handles `SIGNED_IN` first, the recovery UI never appears.
**How to avoid:** Add `if (event === 'PASSWORD_RECOVERY') { showPasswordResetForm(); return; }` as the FIRST branch in the `onAuthStateChange` callback before the `session?.user` check.
**Warning signs:** Password reset flow works on desktop but the user is immediately signed in rather than prompted for a new password.

### Pitfall 4: is_18_plus defaulting to false incorrectly
**What goes wrong:** A user checks the "I am 18 or older" checkbox but `profiles.is_18_plus` is false after signup.
**Why it happens:** `raw_user_meta_data->>'is_18_plus'` returns the string `"true"`, not a boolean. Casting with `::boolean` requires the JSONB text value to be exactly `'true'` or `'false'`. If the JS sends `true` (boolean) in the `options.data` object, Supabase serializes it to JSON as `true` — and PostgreSQL's `::boolean` cast from JSONB text works correctly. But if sent as `'true'` (string), the cast also works. Either way, `COALESCE(..., false)` handles the null case.
**How to avoid:** Send `is_18_plus: ageCheckbox.checked` (boolean) in `options.data`. In the trigger, cast with `(NEW.raw_user_meta_data->>'is_18_plus')::boolean` and wrap in `COALESCE(..., false)`. Test with a new signup using an unchecked checkbox.
**Warning signs:** All users show `is_18_plus = false` even when checkbox was checked.

### Pitfall 5: Age checkbox not blocking signup when unchecked (submit disabled state)
**What goes wrong:** Users can submit signup without checking the age declaration.
**Why it happens:** The disabled state on the "Create account" button is visual only (`opacity: 0.4`, `pointer-events: none` per UI-SPEC), but if the event listener fires on Enter key or programmatically it bypasses the visual gate.
**⚠️ AUTH-06 OVERRIDE — DO NOT BLOCK UNDER-18 SIGNUPS:** Under-18 users MUST be allowed to sign up (AUTH-06 — they get `playMode='practice'`). Do NOT add `if (!ageCheckbox.checked) return;` to the signup handler. Pass `is_18_plus: is18Plus` (the boolean variable) so under-18 users are stored with `is_18_plus=false`. See Plan 02-01 Task 2 action for the correct implementation.
**Warning signs:** Under-18 users cannot create accounts at all (they should be allowed in and get practice mode).

### Pitfall 6: display_name vs. username — leaderboard query still references username
**What goes wrong:** After Phase 2, new users have `display_name` populated but `username` is null. The leaderboard query at line 2875 (`profiles(username)`) returns null for new users.
**Why it happens:** The existing leaderboard query selects `profiles.username`. Phase 2 adds `display_name` but does not migrate the leaderboard query.
**How to avoid:** The leaderboard query must be updated to `profiles(display_name)` as part of Phase 2 Plan 1. The `playerName` resolution in `onSignedIn` should read `display_name` first, falling back to `username` for any existing accounts that still have only username.
**Warning signs:** Leaderboard shows blank names or "Player" for all Phase-2-created accounts.

---

## Code Examples

### Signup handler — full replacement

```js
// Source: extending existing bootSupabaseAuth() in penguin-game.html
document.getElementById('auth-signup').addEventListener('click', async () => {
  const email       = document.getElementById('auth-email').value.trim();
  const password    = document.getElementById('auth-pass').value;
  const displayName = document.getElementById('auth-display-name').value.trim();
  const is18Plus    = document.getElementById('auth-age-check').checked;
  const msgEl       = document.getElementById('auth-status');
  const btn         = document.getElementById('auth-signup');

  // AUTH-06: Do NOT block under-18 signups — is18Plus=false → practice mode (Plan 02-03)
  if (password.length < 8) {
    msgEl.textContent = 'Password must be at least 8 characters.';
    msgEl.style.color = '#f5a0a0';
    return;
  }

  btn.textContent = '···';
  btn.style.pointerEvents = 'none';

  const { error } = await sb.auth.signUp({
    email,
    password,
    options: { data: { display_name: displayName, is_18_plus: is18Plus } } // ⚠️ Use variable, NOT hardcoded true
  });

  btn.textContent = 'Create account';
  btn.style.pointerEvents = '';

  if (error) {
    // Map Supabase error codes to UI-SPEC copy
    if (error.message.includes('already registered') || error.code === 'user_already_exists') {
      msgEl.textContent = 'That email is already registered. Try signing in instead.';
    } else {
      msgEl.textContent = 'Something went wrong. Check your connection and try again.';
    }
    msgEl.style.color = '#f5a0a0';
  } else {
    msgEl.textContent = "Account created — you're in!";
    msgEl.style.color = '#7dffb0';
  }
});
```

### Migration file — add display_name and is_18_plus

```sql
-- supabase/migrations/20260403_add_display_name_is_18_plus.sql
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS is_18_plus   boolean NOT NULL DEFAULT false;

-- Update trigger to write both new fields
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, is_18_plus)
  VALUES (
    NEW.id,
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    COALESCE((NEW.raw_user_meta_data->>'is_18_plus')::boolean, false)
  );
  RETURN NEW;
END;
$$;
```

### PASSWORD_RECOVERY handler guard

```js
// Extend existing sb.auth.onAuthStateChange inside bootSupabaseAuth()
sb.auth.onAuthStateChange(async (event, session) => {
  if (event === 'PASSWORD_RECOVERY') {
    // Show in-place new-password form (replaces auth embed fields)
    showPasswordResetForm();  // new function — swaps HTML in ov-auth
    return;
  }
  if (session?.user) await onSignedIn(session);
  else onSignedOut();
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `alert(error.message)` for auth errors | Inline `#auth-status` span with styled copy | Phase 2 | All auth feedback stays in-page; matches UI-SPEC |
| `playMode: 'guest' \| 'competing' \| 'freeplay'` | Add `'practice'` for under-18 signed-in users | Phase 2 | Under-18 users tracked separately; scores saved but gated at leaderboard layer |
| `profiles.username` as display name | `profiles.display_name` (new column) | Phase 2 | `username` column preserved for backward compat; `display_name` is canonical for new accounts |
| No age declaration | `profiles.is_18_plus` boolean via signup checkbox | Phase 2 | Prize eligibility gate established; Phase 4 enforces it in leaderboard separation |

**Deprecated/outdated in Phase 2:**
- `alert()` for auth errors: replaced by inline status messages
- Hardcoded password minimum of 6 characters: raised to 8 per UI-SPEC copywriting contract

---

## Open Questions

1. **Should existing accounts without display_name be prompted to set one?**
   - What we know: Existing accounts (from prototype testing) have `username` set but `display_name` null.
   - What's unclear: Whether the account tab in Phase 2 should prompt existing users to fill in a display name.
   - Recommendation: Out of scope for Phase 2 (display name is read-only in v1 per UI-SPEC). The `onSignedIn` fallback `prof?.display_name || prof?.username || email.split('@')[0]` handles both old and new accounts gracefully.

2. **Does Supabase hosted project need email confirmation disabled for this flow?**
   - What we know: Local config has `enable_confirmations = false`. The existing signup handler already says "If email confirmation is on, check your inbox."
   - What's unclear: Whether the hosted Supabase project has confirmations enabled — this would change the signup success UX (user would not be immediately signed in).
   - Recommendation: Verify in Supabase Dashboard > Auth > Email settings before shipping Plan 1. If confirmations are off (expected for v1), the current "Account created — you're in!" copy is correct.

3. **Password reset redirectTo — same-origin or custom URL?**
   - What we know: `detectSessionInUrl: true` handles the recovery token when the user returns to the same origin. No `redirectTo` is required for a single-file SPA at a single URL.
   - What's unclear: Whether the Supabase hosted project's "Site URL" and "Redirect URLs" allowlist is configured to match the Vercel deployment URL.
   - Recommendation: Verify Supabase Dashboard > Auth > URL Configuration includes the production Vercel URL. For local dev, `http://localhost:8080` must be in the allowlist. No code change needed — configuration only.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| @supabase/supabase-js | All auth ops | ✓ (CDN) | 2.101.1 | — |
| Supabase hosted project | AUTH-01–AUTH-06 | ✓ (assumed — existing prototype uses it) | PostgreSQL 17 | — |
| Supabase CLI | Migration push | ✓ | v2.84.2 | SQL Editor manual apply |
| python3 http.server | Local dev | ✓ (per STACK.md) | any | any static server |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:**
- Supabase CLI: migrations can be applied manually via Supabase Dashboard SQL Editor if CLI unavailable.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — zero automated tests in project (per TESTING.md) |
| Config file | none — see Wave 0 |
| Quick run command | Manual: open `prototypes/penguin-game.html` via `python3 -m http.server 8080` from `prototypes/` |
| Full suite command | Manual browser walkthrough checklist (see Wave 0) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | New user signs up with email, password, display name, age checkbox | manual-only | open game, fill form, submit | ❌ Wave 0 |
| AUTH-02 | Session persists after browser refresh | manual-only | sign in, F5, verify still signed in | ❌ Wave 0 |
| AUTH-03 | Forgot password sends email; reset link updates password | manual-only | click "Forgot password?", check email, follow link | ❌ Wave 0 |
| AUTH-04 | Display name appears on leaderboard after signup | manual-only | sign up, open leaderboard panel | ❌ Wave 0 |
| AUTH-05 | is_18_plus stored on profile; checkbox required | manual-only | check profiles table in Supabase dashboard | ❌ Wave 0 |
| AUTH-06 | Under-18 user sees Practice Mode indicator; competing user does not | manual-only | sign up with unchecked box, verify indicator | ❌ Wave 0 |

**Note:** All tests are manual-only. The project has zero automated test infrastructure. The "automated command" column references the `python3 -m http.server 8080` local dev server. No test files need to be created — the project convention is manual browser verification.

### Sampling Rate
- **Per task commit:** Manual smoke test — sign in successfully with the changed form
- **Per wave merge:** Full AUTH-01–AUTH-06 manual walkthrough against local Supabase
- **Phase gate:** All 5 "Done when" checklist items in ROADMAP.md confirmed green before `/gsd:verify-work`

### Wave 0 Gaps
- No automated tests to create (project convention is manual testing — see TESTING.md)
- Supabase migration must be applied manually before any code changes land

---

## Sources

### Primary (HIGH confidence)
- `prototypes/penguin-game.html` lines 1056–1077, 2557–2687, 2995–3014 — existing auth form HTML and JS, verified by direct code read
- `supabase/schema.sql` lines 27–38, 144–163 — existing `profiles` table and `handle_new_user` trigger, verified by direct read
- `.planning/codebase/ARCHITECTURE.md` — state machine, data flow, overlay system
- `.planning/codebase/INTEGRATIONS.md` — Supabase client config, persistSession, autoRefreshToken
- `.planning/phases/02-auth-player-profiles/02-UI-SPEC.md` — full UI contract verified by direct read
- [Supabase managing-user-data docs](https://supabase.com/docs/guides/auth/managing-user-data) — `signUp options.data` → `raw_user_meta_data` pattern
- `npm view @supabase/supabase-js version` → `2.101.1` (confirmed 2026-04-03)

### Secondary (MEDIUM confidence)
- [Supabase resetPasswordForEmail reference](https://supabase.com/docs/reference/javascript/auth-resetpasswordforemail) — method signature and redirectTo option
- WebSearch: PASSWORD_RECOVERY event fires alongside SIGNED_IN — confirmed by Supabase GitHub discussions and issues

### Tertiary (LOW confidence)
- Known issue: In some Supabase versions, the original browser tab that requested password reset may not receive the PASSWORD_RECOVERY event when the user clicks the link in a different tab. For this SPA the reset link opens the same page in the same browser context, so the known multi-tab issue should not apply — but this was verified only via GitHub discussion threads, not official docs.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — pinned version confirmed, same library already in use
- Architecture: HIGH — read directly from existing source code
- Schema patterns: HIGH — read directly from schema.sql and Supabase official docs
- PASSWORD_RECOVERY flow: MEDIUM — behavior confirmed via multiple sources but known quirks documented
- Pitfalls: HIGH — 5 of 6 pitfalls derived directly from reading existing code and schema

**Research date:** 2026-04-03
**Valid until:** 2026-07-03 (Supabase Auth API is stable; supabase-js version is pinned)
