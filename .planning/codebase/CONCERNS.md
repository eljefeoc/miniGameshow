# Codebase Concerns

**Analysis Date:** 2026-04-02

## Tech Debt

**Monolithic HTML game files:**
- Issue: All game logic, markup, styles, and scripts are co-located in single HTML files exceeding 3,000 lines each
- Files: `game01/index.html`, `game02/index.html`, `game03/index.html`
- Impact: Extremely difficult to navigate, refactor, or test individual subsystems; changes in one area risk breaking unrelated functionality; no separation of concerns between UI, game logic, and data layers
- Fix approach: Extract JS into separate modules (e.g., `game-logic.js`, `ui.js`, `scores.js`), extract CSS into stylesheets, adopt a component or module bundler pattern

**Games 02 and 03 have zero Supabase integration:**
- Issue: `game02/index.html` and `game03/index.html` contain no Supabase client initialization, no score submission, and no leaderboard reads
- Files: `game02/index.html`, `game03/index.html`
- Impact: Scores from these games are never persisted; multi-game leaderboard comparisons are impossible; player progress is lost on page reload
- Fix approach: Port the score submission and leaderboard fetch pattern from `game01/index.html` into each game, extracting the shared Supabase logic into a shared module first

**Supabase JS loaded from CDN without a version pin:**
- Issue: `<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js">` (or equivalent unpinned CDN URL) is used in game HTML files
- Files: `game01/index.html`
- Impact: A CDN update to a new major version can silently break API calls; no reproducible build; no integrity check (SRI hash absent)
- Fix approach: Pin to an explicit version (e.g., `@supabase/supabase-js@2.x.x`), add a `integrity="sha384-..."` SRI attribute, or bundle via npm/package.json

## Known Bugs

**`is_banned` and `is_validated` columns are never read or written:**
- Symptoms: Banned players can submit scores freely; unvalidated accounts are treated as validated
- Files: `game01/index.html`, Supabase `players` table schema
- Trigger: Any score submission by any player regardless of account standing
- Workaround: None currently in place

## Security Considerations

**Real Supabase credentials present in a gitignored prototype file:**
- Risk: `prototypes/supabase-config.js` contains the live project URL and anon key in plaintext; if `.gitignore` is misconfigured or the file is accidentally staged, credentials become public in git history
- Files: `prototypes/supabase-config.js`
- Current mitigation: File is listed in `.gitignore`
- Recommendations: Rotate credentials immediately if any prior commit history is suspect; move credentials to a `.env` file (also gitignored); serve anon key only via environment variables injected at build time; audit git history with `git log --all -- prototypes/supabase-config.js` to confirm it was never committed

**No server-side score validation (anti-cheat not implemented):**
- Risk: Any client can POST an arbitrary score to the Supabase `scores` table; leaderboard rankings can be trivially manipulated via the browser console or direct API calls
- Files: `game01/index.html`, Supabase `scores` table, `refresh_leaderboard_ranks()` database function
- Current mitigation: None
- Recommendations: Implement a Supabase Edge Function or Row Level Security policy that validates score plausibility (e.g., max score per session, rate limiting per player, timestamp cross-checks); at minimum enable RLS on the `scores` table so anonymous writes are blocked and only authenticated inserts are accepted

**Supabase anon key embedded in client-side HTML:**
- Risk: The anon key is visible to any user who views page source; combined with absent RLS this allows unrestricted table access
- Files: `game01/index.html`
- Current mitigation: Anon key has limited permissions by default in Supabase, but RLS must be enforced to contain the risk
- Recommendations: Audit and enforce RLS on all tables; confirm the anon key cannot perform admin operations

## Performance Bottlenecks

**`refresh_leaderboard_ranks()` performs a full-table UPDATE on every score submission:**
- Problem: The stored procedure issues an `UPDATE scores SET rank = ...` (or equivalent) that touches every row in the table on each new score insert
- Files: Supabase database function `refresh_leaderboard_ranks()`, invoked from `game01/index.html`
- Cause: Recomputing dense ranks requires a window function pass over the entire dataset; as the `scores` table grows this becomes O(n) per submission
- Improvement path: Replace with a `RANK()` or `DENSE_RANK()` window function in the leaderboard SELECT query so ranks are computed at read time, not written on every insert; alternatively maintain a separate materialized view refreshed on a schedule rather than per-insert

**`content_events` table grows unboundedly:**
- Problem: Every game event (clicks, answers, state transitions) is appended to `content_events` with no archival, TTL, or pruning strategy
- Files: `game01/index.html` (event emission), Supabase `content_events` table
- Cause: Insert-only append log with no deletion or partitioning policy
- Improvement path: Add a `created_at` index and a scheduled Supabase function or pg_cron job to delete rows older than a retention window (e.g., 90 days); consider partitioning the table by month if analytics retention is required

## Fragile Areas

**Score submission and leaderboard fetch tightly coupled inside game HTML:**
- Files: `game01/index.html`
- Why fragile: Supabase client initialization, table names, column names, and UI rendering are interleaved in the same inline `<script>` block; a schema rename or API change requires editing deep inside a 3,000-line file
- Safe modification: Search for all Supabase `.from(` calls before changing any table or column name; test leaderboard display end-to-end after any schema migration
- Test coverage: Zero automated tests; all verification is manual

**No PWA manifest, no Service Worker, no offline support:**
- Files: All `index.html` files; no `manifest.json` or `sw.js` present anywhere in the project
- Why fragile: The app is entirely dependent on network availability; a dropped connection mid-game loses all state; mobile users cannot install the app or play offline
- Safe modification: Adding a Service Worker retroactively requires careful cache-busting strategy to avoid serving stale game assets
- Test coverage: None

## Scaling Limits

**Leaderboard rank refresh:**
- Current capacity: Functional at low row counts (hundreds of rows)
- Limit: Full-table UPDATE becomes visibly slow (multi-second latency) at tens of thousands of rows; at hundreds of thousands it will cause lock contention and timeout errors on score submission
- Scaling path: Migrate to read-time rank computation via window functions; remove the `refresh_leaderboard_ranks()` trigger

**`content_events` table:**
- Current capacity: No enforced limit
- Limit: Query performance degrades without pruning; storage costs increase linearly; unindexed columns will cause slow scans as volume grows
- Scaling path: Introduce retention policy and index on `created_at`; evaluate whether all event types need persistence or only aggregates

## Dependencies at Risk

**Unpinned Supabase JS from CDN:**
- Risk: No integrity guarantee; subject to supply-chain attack via CDN compromise or accidental breaking release
- Impact: All Supabase operations in `game01/index.html` would break silently
- Migration plan: Add to `package.json`, bundle with a build tool, or pin CDN URL to a specific version with SRI hash

## Missing Critical Features

**No authentication enforcement on score writes:**
- Problem: RLS is absent or permissive; the `is_validated` flag on the `players` table is never set or checked
- Blocks: Cannot trust leaderboard integrity; cannot enforce per-player score uniqueness or rate limits

**No automated tests of any kind:**
- Problem: Zero unit, integration, or end-to-end tests exist in the repository
- Blocks: Any refactoring (e.g., extracting modules from monolithic HTML) carries full regression risk with no safety net; the score submission path, rank refresh logic, and leaderboard rendering are entirely unverified by automation

**`is_banned` enforcement absent:**
- Problem: The `players.is_banned` column exists in the schema but is never queried before accepting a score submission
- Blocks: Moderation actions have no effect on gameplay

## Test Coverage Gaps

**Score submission flow:**
- What's not tested: Supabase insert succeeds, rank is updated correctly, UI reflects new rank
- Files: `game01/index.html`
- Risk: Silent failures in score persistence go unnoticed until a player reports a missing score
- Priority: High

**Leaderboard rendering:**
- What's not tested: Correct rank ordering, tie-breaking, display of top-N players
- Files: `game01/index.html`
- Risk: A schema change or query modification could silently corrupt displayed rankings
- Priority: High

**Game logic (all games):**
- What's not tested: Scoring rules, answer validation, timer behavior, state transitions
- Files: `game01/index.html`, `game02/index.html`, `game03/index.html`
- Risk: Regressions in core gameplay go undetected until manual playtesting
- Priority: Medium

**Access control / RLS policies:**
- What's not tested: Whether anonymous users can write arbitrary scores, whether banned players are blocked
- Files: Supabase database policies
- Risk: Security assumptions are unverified; a misconfigured policy silently opens write access
- Priority: High

---

*Concerns audit: 2026-04-02*
