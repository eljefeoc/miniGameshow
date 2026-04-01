# Testing Patterns

**Analysis Date:** 2026-04-02

## Test Framework

**Runner:** None

No test framework is installed or configured. There is no `jest.config.*`, `vitest.config.*`,
`mocha`, `playwright`, or any other test runner. The `package.json` defines only a single
`build` script with no `test` script:

```json
{
  "scripts": {
    "build": "node scripts/vercel-write-supabase-config.mjs"
  }
}
```

---

## Test Files

**None found.** There are no `*.test.*`, `*.spec.*`, or `__tests__/` files anywhere in
the repository. The `.gitignore` contains entries for `coverage/` and `.nyc_output` from
a boilerplate template, but no coverage tooling is active.

---

## Coverage

**Requirements:** None enforced

**Current coverage:** 0% — no automated tests exist

---

## Test Types

**Unit tests:** Not present

**Integration tests:** Not present

**E2E tests:** Not present

**Manual testing only.** The project is tested by opening HTML files directly in a browser
or via the Vercel-hosted URL. The `prototypes/` directory name signals that these are
proof-of-concept implementations expected to be tested by hand.

---

## What Exists Instead of Tests

### Defensive Guards in Production Code
The codebase compensates for the absence of tests with runtime guards:

**Safety stubs** — `penguin-game.html` creates a no-op `GameshowHud` stub if `hud.js` has
not loaded, preventing null-reference crashes:
```js
if (!window.GameshowHud || typeof window.GameshowHud.init !== 'function') {
  window.GameshowHud = {
    init:()=>{}, height:()=>56, setPrize:()=>{}, …
  };
}
```
Source: `prototypes/penguin-game.html` (lines 1139–1144)

**Null-check guard clauses** before every DOM operation:
```js
const rankEl = el('ghud-rank');
if (rankEl) rankEl.textContent = rank != null ? `#${rank}` : '—';
```
Source: `prototypes/hud.js`

**try/catch on all async operations** with console labels to aid manual debugging:
```js
}catch(e){ console.error('fetchActiveWeek', e); }
```
Source: `prototypes/penguin-game.html`

### Pre-flight SQL Check
`supabase/pre_flight_check.sql` is a manual SQL script that can be run in the Supabase
dashboard to verify schema readiness before deploying a competition week.
Source: `supabase/pre_flight_check.sql`

### Admin UI as Manual Smoke Test
`prototypes/admin.html` serves as a manual integration harness: it exercises Supabase auth,
`profiles` row inspection, `weeks` CRUD, and the `games` table — all operations that would
be covered by integration tests in a tested codebase.
Source: `prototypes/admin.html`

### Build Script Validation
`scripts/vercel-write-supabase-config.mjs` prints a `console.warn` if environment
variables are missing, acting as a lightweight build-time assertion:
```js
if (!url || !anonKey) {
  console.warn('[vercel-write-supabase-config] SUPABASE_URL or SUPABASE_ANON_KEY missing …');
}
```
Source: `scripts/vercel-write-supabase-config.mjs` (lines 21–26)

---

## Recommendations for Adding Tests

If tests are introduced, the natural first targets are:

1. **`prototypes/hud.js`** — The IIFE module has a clean public API (`init`, `setStats`,
   `setPlayer`, `renderSchedule`) making it the most unit-testable code in the project.
   A jsdom-based environment (Jest or Vitest) could exercise the rendering logic without
   a browser.

2. **`scripts/vercel-write-supabase-config.mjs`** — A pure Node.js script with env-variable
   inputs and a file output. Straightforward to test with mocked `process.env` and a
   temp output path.

3. **Date/formatting helpers** — `fmtNum`, `fmtShowTime`, `fmtEndsShort`, `weekStatus`,
   `fmtDate`, `dt`, `dtToIso`, `suggestWeekCode` are pure functions scattered across
   `hud.js` and `admin.html` that could be extracted and unit-tested trivially.

4. **Supabase DB behavior** — The migration files and RLS policies in `supabase/migrations/`
   would benefit from Supabase's `pgTAP`-based migration tests or a local Supabase instance
   with seeded data.

**Suggested framework:** Vitest — compatible with the project's `"type": "module"` declaration
in `package.json` and requires no build pipeline.

---

*Testing analysis: 2026-04-02*
