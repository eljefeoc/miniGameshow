# Stack Research

**Project:** miniGameshow
**Researched:** 2026-04-02
**Existing codebase audited:** Yes — prototypes/penguin-game.html (3094 lines), admin.html, vercel.json, package.json

---

## Existing Stack (Confirmed)

| Layer | Technology | How It's Used |
|---|---|---|
| Game runtime | Vanilla JS, HTML5 Canvas | Single-file game, no framework, no transpiler |
| Backend | Supabase JS v2 (CDN ESM import) | Auth, DB queries, session management |
| Hosting | Vercel | Static output from `prototypes/` directory |
| Build step | `node scripts/vercel-write-supabase-config.mjs` | Injects Supabase URL/key into config file at deploy time |
| Fonts | Google Fonts (Press Start 2P, Titan One, Bubblegum Sans) | Preconnect + stylesheet link |
| CSS | Inline styles + `hud.css` | No preprocessor |
| Auth | Supabase email/password | `persistSession: true`, session stored in localStorage |

**Important architectural note:** `vercel.json` sets `outputDirectory: "prototypes"` — all HTML files in that directory are deployable artifacts. There is no bundler. Supabase JS is loaded via dynamic `import()` from `cdn.jsdelivr.net`. This is the constraint that shapes every decision below.

---

## Phone-First Shell

### What Exists
The prototype already has a solid foundation:
- `max-scale=1.0, user-scalable=no` on viewport meta — correct for game
- `touch-action: manipulation` globally — prevents 300ms tap delay
- `touch-action: none` on canvas — prevents scroll interference
- `env(safe-area-inset-bottom)` on the controls bar — notch-aware
- `clamp()` for font sizes — fluid type
- `-webkit-tap-highlight-color: transparent` — removes iOS tap flash
- `apple-mobile-web-app-capable` and `apple-mobile-web-app-status-bar-style` meta tags — iOS fullscreen mode

### What's Missing / Needs to Change

**1. Overlay/shell screens not yet 375px-first**
The game canvas shell is solid but the GSP panel (leaderboard/menu drawer), auth flow, and post-run overlay need audit. The admin panel uses `max-width: 1000px` centered layout — fine for operators on desktop, not needed for player-facing UI.

**2. No `viewport-fit=cover` on the viewport meta**
Required for true edge-to-edge on iPhone X+ notched devices. Current meta uses `width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no` but lacks `viewport-fit=cover`. Add it.

**3. Canvas resize logic needs `window.visualViewport`**
On mobile, the software keyboard causes `window.innerHeight` to shrink when an input is focused (e.g., auth form). If the canvas resize is tied to `window.innerHeight`, it will jump. Use `window.visualViewport.height` for canvas sizing, with fallback to `window.innerHeight`.

**Recommendation: No new library needed.** The existing CSS patterns are correct. The work is surgical additions:
- Add `viewport-fit=cover` to the viewport meta
- Switch canvas resize to `visualViewport` API
- Apply `env(safe-area-inset-*)` padding on any full-width UI elements (score cards, overlays)
- Ensure all tap targets meet 44×44px minimum (Apple HIG / WCAG 2.5.5)

**Confidence: HIGH** — these are native browser APIs, no library risk.

---

## PWA Fundamentals

### Installability Requirements (Confirmed via MDN)

A PWA is installable on Chromium-based browsers when:
1. Manifest file linked from every page via `<link rel="manifest" href="/manifest.json">`
2. Manifest contains: `name` or `short_name`, `icons` (192px and 512px minimum), `start_url`, `display: "standalone"` or `"fullscreen"`
3. Served over HTTPS (Vercel satisfies this automatically)
4. `prefer_related_applications` must be `false` or omitted

**Service workers are NOT required for basic installability.** The browser install prompt fires without one (confirmed MDN). For this project, a minimal service worker is recommended solely for the offline fallback screen — not for complex caching strategies.

### What to Build

**manifest.json** — static file in `prototypes/`:
```json
{
  "name": "MiniGameshow",
  "short_name": "MiniGameshow",
  "description": "Arctic arcade games. One link, instant play.",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait",
  "background_color": "#110822",
  "theme_color": "#110822",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512-maskable.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

**Service worker (sw.js)** — minimal, static file in `prototypes/`:
- Cache the offline fallback HTML only (do NOT cache game assets aggressively — you want players to always get the latest game version on first load)
- Use a network-first strategy for all game HTML
- Cache-bust on each deploy by embedding a version string

**Registration in game HTML:**
```js
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}
```

### What NOT to Do
- Do not use Workbox for this project. Workbox requires either a build step (Workbox CLI/webpack plugin) or a CDN import that adds ~80KB to the service worker. For a minimal offline fallback, hand-write 20 lines of vanilla service worker code.
- Do not implement aggressive pre-caching. The game must always load the latest version. Pre-caching game logic breaks fast iteration.
- Do not add a "prompt to install" banner on first visit. The game's core value is "tap and play without installing" — a pushy install prompt undermines that. Let the browser handle the ambient install prompt in its own time.

**Apple specifics:** iOS Safari does not use the manifest for install prompts. iOS install is always manual (Share → Add to Home Screen). The `apple-mobile-web-app-capable` and `apple-touch-icon` meta tags (already present) handle iOS. Add `<link rel="apple-touch-icon" href="/icons/icon-180.png">` for proper iOS home screen icon.

**Confidence: HIGH** — PWA manifest spec is stable and well-documented.

---

## Admin UI Approach

### What Exists
`prototypes/admin.html` is a standalone HTML file with:
- Supabase auth gate (same email/password pattern as game)
- Week CRUD (create/edit/delete weeks)
- HUD preview
- Dark UI with system-ui font, purple/amber color scheme
- Responsive grid that collapses to single column at 600px

### What's Needed
The PROJECT.md requirements add:
- Event management (configurable duration hours/days/week, game selection, prize field)
- Test event mode flag
- "New week live" manual trigger + auto-publish fallback
- Winner identification surface (#1 at event cutoff)

### Approach: Extend the existing admin.html pattern
The admin is operator-facing, not public. Desktop-primary is acceptable (operators likely use laptop/desktop). The existing pattern — vanilla JS + Supabase direct queries + inline CSS — is the right approach. Do not add a UI component library.

**Why no UI library (Alpine.js, Petite Vue, etc.):**
- Admin HTML is already ~800 lines and the pattern is clear
- Adding a CDN-loaded reactive framework for a single-operator tool creates a CDN dependency that can fail
- Supabase real-time is available for live winner display — use it directly

**For the winner surface specifically:** Query the `leaderboard` view filtered by the active event's `week_id`, ordered by rank, limited to 1. Display clearly with a distinct visual treatment. No special library needed.

**Admin auth security pattern:** The existing approach (Supabase email/password with RLS) is correct for v1. The admin panel gates behind Supabase auth, and RLS policies restrict write access to admin-role users. This is sufficient for a single-operator setup.

**Recommendation:** Extend admin.html as needed. Keep it one file. Consider splitting into `admin.html` (read-only event view) and `admin-manage.html` (write operations) only if the file exceeds ~1500 lines.

**Confidence: HIGH** — no new technology, extending proven pattern.

---

## Age Verification

### Requirements
- 18+ required to compete for prizes
- Under-18 can play in "practice mode" (own leaderboard, cannot win prizes)
- Must be stored in user profile (Supabase `profiles` table)
- Geo/age restriction framework for legal compliance (not full legal impl in v1)

### Approach: Client-side gate + server-side enforcement

**Step 1 — Profile completion gate**
After sign-up, before first scored run is recorded, show a one-time age verification prompt:
- "Are you 18 or older?" — Yes / No / Prefer not to say
- Store result in `profiles.age_verified` (boolean) and `profiles.age_gate_passed_at` (timestamp)
- If "No" or "Prefer not to say" → set `profiles.practice_mode = true`

**Why not a date-of-birth field?** Date-of-birth fields create data storage obligations depending on jurisdiction. A boolean acknowledgment is simpler and adequate for v1. Legal review before public launch (already in PROJECT.md Out of Scope) will determine if more is needed.

**Step 2 — Server-side enforcement**
Add a Supabase database check in the `runs` insert trigger or RLS policy:
```sql
-- Pseudocode for run insert policy
CREATE POLICY "only_eligible_players_can_submit_runs" ON runs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND (age_verified = true OR practice_mode = true)
    )
  );
```

Runs submitted by practice_mode users are flagged and excluded from the prize-eligible `leaderboard` view. Create a separate `practice_leaderboard` view filtered by `practice_mode = true`.

**No external age verification library.** Third-party age verification services (AgeID, Yoti, etc.) are expensive, require native app integrations, or add GDPR complexity. For v1, a self-declared checkbox with RLS enforcement is correct. Legal review will determine if a harder gate is needed.

**UI implementation:** A modal overlay in the game shell, shown on first scored play attempt after auth. Pure vanilla JS + inline CSS. The modal blocks play until the user makes a selection.

**Confidence: HIGH** for the implementation approach. MEDIUM for legal sufficiency — this is explicitly deferred to legal review.

---

## Social Share Cards

### Approach: Vercel OG image generation (`@vercel/og`)

**Confirmed from official Vercel docs:**
- `@vercel/og` generates PNG images from JSX/HTML+CSS using Satori (HTML→SVG) + Resvg (SVG→PNG)
- Deployed as a Vercel Function at `api/og.js` (or `.tsx`)
- Supports flexbox layout, custom fonts (ttf/otf/woff), and nested images
- Automatically adds CDN cache headers — generated once, cached
- Recommended OG image size: 1200×630px
- Maximum bundle size: 500KB
- Node.js runtime (not Edge) — confirmed supported

**How it fits the no-build-pipeline constraint:**
The `api/` directory is handled by Vercel Functions automatically — no build step, no bundler. You write `api/og.js`, Vercel deploys it as a serverless function. The `prototypes/` output directory is for static files; `api/` is separate and works in parallel.

**Score card design:**
```
api/og.js?score=12400&rank=3&name=IceFisher99&event=Week+12
```
Returns a 1200×630 PNG with:
- Arctic/game art background (embedded as base64 or fetched from static URL)
- Score and rank prominently displayed
- Player display name
- "Play at theminigameshow.com" CTA
- Arctic character art

**In-game share flow:**
```js
// After run completion, build share URL
const shareUrl = `https://theminigameshow.com/api/og?score=${score}&rank=${rank}&name=${displayName}`;
// Use Web Share API if available (iOS Safari, Android Chrome)
if (navigator.share) {
  navigator.share({
    title: `I scored ${score} in Pengu Fisher!`,
    text: `Rank #${rank} this week. Can you beat me?`,
    url: 'https://theminigameshow.com',
  });
} else {
  // Fallback: copy link to clipboard + show toast
}
```

**Web Share API support (2026):** Available in all modern mobile browsers (iOS Safari 12.4+, Chrome for Android 61+). Desktop support is improving but inconsistent. Always provide the clipboard fallback.

**What NOT to do:**
- Do not use `html2canvas` or `dom-to-image` for client-side image generation. These libraries are ~150KB, slow on mobile, and produce inconsistent results across browsers.
- Do not use Puppeteer/headless Chrome. Too heavy, too expensive for a serverless function, cold start latency is unacceptable.
- Do not generate static score card images at run submission time (pre-generating). You don't know which scores players will want to share. Generate on-demand with CDN caching.

**`@vercel/og` requires `package.json`** — it must be listed in `dependencies`. The project already has a `package.json`. Add: `"@vercel/og": "^0.6.3"` (latest stable as of knowledge cutoff). The `npm install` step happens on Vercel's build infrastructure, not locally.

**Confidence: HIGH** for Vercel OG approach. The API is stable and the project's Vercel setup makes this a natural fit.

---

## Real-time Leaderboard

### What Exists
The current leaderboard is **pull-based**: `refreshGspLeaderboard()` runs an explicit Supabase query each time the user opens the leaderboard tab. There is no polling or push mechanism. This is correct for the current prototype but insufficient for a live game show context where real-time rank changes matter.

### Supabase Realtime: Postgres Changes

Supabase JS v2 (already loaded) includes the Realtime client. The channel API:

```js
const sb = window._miniGameshowSb; // already initialized

const channel = sb.channel('leaderboard-updates')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'runs',          // or 'leaderboard' if it's a materialized view
      filter: `week_id=eq.${weekId}`,
    },
    (payload) => {
      // A new run was submitted — refresh the leaderboard display
      refreshGspLeaderboard();
    }
  )
  .subscribe();

// Cleanup when panel closes
channel.unsubscribe();
```

**Important: Subscribe to `runs` inserts, not the `leaderboard` view.** Supabase Realtime requires `REPLICA IDENTITY FULL` set on the source table. Views are not directly subscribable in postgres_changes. Subscribe to `runs` inserts → on each insert, re-query the `leaderboard` view.

**Why not subscribe to the leaderboard view directly?** Leaderboard ranks are computed values. Even with materialized views, postgres_changes fires on the underlying tables. Re-querying is the correct pattern.

**Throttling:** On an active event, many `runs` inserts could fire in quick succession. Add a debounce (500ms) before refreshing the leaderboard to avoid hammering the DB:
```js
let lbRefreshTimer;
const debouncedRefresh = () => {
  clearTimeout(lbRefreshTimer);
  lbRefreshTimer = setTimeout(refreshGspLeaderboard, 500);
};
```

**When to activate:** Subscribe only when the leaderboard panel is open. Unsubscribe when it closes. This avoids holding WebSocket connections open on players who never view the leaderboard.

**Connection limits (Supabase free/pro tier):** Free tier allows 200 concurrent realtime connections. For a game show with hundreds of simultaneous players, the Pro plan (500 concurrent) is needed. Connection is shared per client session — each player uses 1 connection regardless of how many channels they subscribe to.

**Alternative: 30-second polling.** If Supabase Realtime causes complexity (RLS on the channel, REPLICA IDENTITY setup requirements), a 30-second `setInterval` refresh when the panel is open is perfectly adequate for a game show leaderboard. Players are not watching their rank update second-by-second during active play.

**Recommendation:** Implement polling first (simpler, already works), add Realtime subscribe in the same milestone only if real-time rank updates are required for the Sunday show experience. The polling pattern already exists and can be made interval-based with 3 lines of code.

**Confidence: HIGH** for the Supabase Realtime API pattern. MEDIUM for operational complexity (requires confirming REPLICA IDENTITY and RLS channel policies are configured in the DB).

---

## Recommendations Summary

| Feature | Approach | Library/Tool | Confidence |
|---|---|---|---|
| Phone-first shell | Add `viewport-fit=cover`; switch canvas resize to `visualViewport` API; audit tap targets | None — native browser APIs | HIGH |
| Safe area insets | `env(safe-area-inset-*)` in CSS | None | HIGH |
| PWA manifest | `manifest.json` static file; `<link rel="manifest">` on all pages | None | HIGH |
| Service worker | Hand-write minimal offline fallback (~20 lines); network-first strategy | None — do NOT use Workbox | HIGH |
| iOS home screen | `apple-touch-icon` + `apple-mobile-web-app-capable` meta (already partially present) | None | HIGH |
| Admin event UI | Extend `admin.html` with new event fields; same vanilla JS + Supabase pattern | None | HIGH |
| Age verification gate | Client-side modal on first play; boolean stored in `profiles` table; RLS enforcement on `runs` inserts | None — no third-party age-verification service | HIGH |
| Practice mode leaderboard | Separate `practice_leaderboard` DB view filtered by `practice_mode = true` | None | HIGH |
| Social share card (OG image) | Vercel Function at `api/og.js` using `@vercel/og` | `@vercel/og` ^0.6.x | HIGH |
| Share trigger (in-game) | Web Share API with clipboard fallback | None | HIGH |
| Real-time leaderboard | Polling (30s interval when panel open) as first pass; Supabase Realtime `postgres_changes` as enhancement | Supabase JS v2 (already loaded) | HIGH |

---

## What NOT to Add

| Library | Why Not |
|---|---|
| Alpine.js / Petite Vue | Adds CDN dependency and mental model overhead to a codebase that already works without reactivity |
| Workbox | Requires build step or heavy CDN import; overkill for a minimal offline fallback |
| html2canvas / dom-to-image | Slow, inconsistent, ~150KB; `@vercel/og` is the right tool |
| Tailwind CSS (CDN) | Play CDN adds 300KB+ of CSS classes; inline CSS is already working well |
| Lit / Web Components | No benefit over inline JS for single-file game architecture |
| Any date-of-birth / age-ID service | Adds PII storage obligation, external dependency, cost; inappropriate for v1 |
| Socket.io | Supabase Realtime provides WebSocket-based real-time; Socket.io is redundant |

---

## Sources

- MDN PWA installability requirements: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable (fetched 2026-04-02, confidence HIGH)
- Vercel OG image generation docs: https://vercel.com/docs/functions/og-image-generation (fetched 2026-04-02, confidence HIGH)
- MDN Web App Manifest: https://developer.mozilla.org/en-US/docs/Web/Manifest (fetched 2026-04-02, confidence HIGH)
- Supabase Realtime API: Training data + codebase patterns (Supabase JS v2 CDN pattern confirmed in penguin-game.html); confidence MEDIUM — verify channel filter syntax and REPLICA IDENTITY requirements in DB before implementation
- Web Share API: Training data (MDN); confidence MEDIUM for exact browser support table — verify current Safari/Chrome versions before shipping
- `@vercel/og` version: Training data cutoff August 2025; run `npm show @vercel/og version` to confirm latest before adding to package.json
