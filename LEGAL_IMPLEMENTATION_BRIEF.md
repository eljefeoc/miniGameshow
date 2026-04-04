# LEGAL IMPLEMENTATION BRIEF

### For Cursor / AI-assisted coding sessions

**Entry points:** [`CURSOR_ROADMAP.md`](CURSOR_ROADMAP.md) → *Start here next session (legal compliance)*, and [`GAME_BIBLE.md`](GAME_BIBLE.md) Section 8 → *Legal, consent & sweepstakes*.

*Paste this at the top of any session where you are building auth, sign-up, competition entry, or any user-facing legal flow — or point the session at this file.*

---

## WHAT THIS IS

This product is a free-to-play browser-based game show with real weekly prizes.
It runs on Vanilla JS + Canvas, Supabase (auth + DB), and Vercel.
There are two play modes: **Arcade** (everyone, unlimited, no prize) and **Competition** (18+, shared daily seed, prize-eligible).

Legal compliance is split across two tiers:

- **Tier 1 — General site use:** Applies to ALL visitors, including guests and under-18 players.
- **Tier 2 — Competition entry:** Applies ONLY to users who opt into Competition mode. Requires age verification and separate agreement acceptance.

---

## DOCUMENTS THAT NEED TO EXIST (build links/pages for all of these)

| Slug / filename            | What it is                                  | Tier     |
|---------------------------|---------------------------------------------|----------|
| `/legal/tos`              | General Terms of Service                    | Tier 1   |
| `/legal/privacy`          | Privacy Policy                              | Tier 1   |
| `/legal/cookies`          | Cookie & Tracking Notice                    | Tier 1   |
| `/legal/acceptable-use`   | Acceptable Use Policy (anti-cheat language) | Tier 1   |
| `/legal/dmca`             | DMCA / IP Notice                            | Tier 1   |
| `/legal/competition-rules`| Official Sweepstakes / Competition Rules    | Tier 2   |

All documents must be:

- Publicly accessible without login
- Linkable (canonical URLs, no auth wall)
- Versioned (store `effective_date` and `version` string in the document itself)

**Planned repo layout:** Static site root is [`prototypes/`](prototypes/); add
`prototypes/legal/*.html` when building. Optional [`vercel.json`](vercel.json)
rewrites can map `/legal/tos` → `/legal/tos.html`, etc. **Not created yet** — only
this brief + the migration file exist until the legal build starts.

---

## DATABASE — CONSENT LOGGING (REQUIRED)

Supabase table: `user_legal_consent`

Migration (in repo, **do not apply** until counsel approves starting this work):
[`supabase/migrations/20260405120000_legal_consent_and_audit_tables.sql`](supabase/migrations/20260405120000_legal_consent_and_audit_tables.sql).
Apply via Supabase CLI or SQL editor when the legal build begins.

**Every consent event must write a row here.** This is the audit trail for prize
disputes, regulatory inquiries, and winner verification. Do not skip this even
during development — seed it with test data so the pattern is established.

`ip_address` / `user_agent` should be populated from a trusted path (e.g. Edge Function) when possible; the table allows nulls until that wiring exists.

---

## SIGN-UP / ACCOUNT CREATION FLOW

When a user creates an account (email + password via Supabase Auth):

1. Show TOS and Privacy Policy links — plainly visible, not buried.
2. Require a checkbox: `"I agree to the Terms of Service and Privacy Policy"`
   - Do NOT pre-check this box.
   - Do NOT allow form submission if unchecked.
3. On successful account creation, write a `user_legal_consent` row:
   - `consent_type: 'tos_general'`
   - `document_version: '[current version string]'`
4. If the user is in an EU/UK jurisdiction (detect by IP or ask), surface the
   Cookie Notice separately before any non-essential cookies are set.

**Do not bundle competition consent into the sign-up flow.**
These are two separate agreements and must be accepted at separate moments.

---

## COMPETITION ENTRY FLOW — AGE GATE + COMPETITION RULES

This gate fires when a signed-in user attempts to activate Competition mode
(not on general sign-up — only at the moment they try to enter the competition).

### UI requirements

1. **Date of birth field** (not just a checkbox) — collect `YYYY-MM-DD`.
   Calculate age server-side. If age < 18, block entry silently and route to Arcade.
   Do NOT display a message that says "you are too young" — per the game bible,
   under-18 players should land on Arcade naturally, framed as equally desirable.

2. **Show the full Competition Rules** or a clearly labeled link to `/legal/competition-rules`
   that opens in a readable modal or new tab. The link must be visible before the
   user accepts.

3. **Eligibility declaration checkbox** (unchecked by default):
   ```
   "I confirm I am 18 or older, a legal resident of an eligible location,
   and I agree to the Official Competition Rules."
   ```

4. **Void states warning** — display this line near the checkbox:
   ```
   "Competition void in AZ, MD, ND, and VT. Additional restrictions
   apply in FL and NY. See Official Rules for details."
   ```

5. On acceptance, write TWO rows to `user_legal_consent`:
   - `consent_type: 'age_declaration'`, `document_version: '[current]'`
   - `consent_type: 'competition_rules'`, `document_version: '[current]'`

6. Store `dob` on the user profile (Supabase `profiles` table or `auth.users` metadata).
   Never re-ask for DOB once stored — re-verify from DB on each competition week entry.

### Server-side enforcement (Supabase RLS / Edge Function)

- The `runs` insert for `mode = 'competition'` must verify:
  - User is authenticated (not guest)
  - User has a valid `age_declaration` consent row
  - User's calculated age from stored DOB is >= 18
  - User's stored location is not in a void state
- Reject the insert and return a clear error code if any check fails.
- **Never trust client-side age checks alone.** The client UI is a UX layer only.

---

## COOKIE / TRACKING NOTICE

- Fire this for ALL users on first visit, before any analytics or non-essential
  cookies are set.
- A simple banner is sufficient for US-only launch. For EU/UK, you need a proper
  consent management pattern (accept / reject / manage preferences).
- Supabase Auth uses essential cookies — these do not require consent.
- Any analytics tool (Plausible, PostHog, GA, etc.) = non-essential. Gate it.

Recommended implementation: check `localStorage` for `cookie_consent_v1`.
If absent, show banner. On accept, set the key and initialize analytics.
On reject, do not initialize analytics. Do not use a cookie to store this
preference (ironic, but correct for pre-consent state).

---

## "NO PURCHASE NECESSARY" — REQUIRED COPY PLACEMENT

US sweepstakes law requires this phrase (or equivalent) to appear:

- On the homepage / L1 landing page near any prize mention
- In the HUD wherever the prize is displayed
- At the top of the Official Competition Rules

Suggested HUD addition (small text below prize name):

```
Free to play · No purchase necessary · Void where prohibited
```

---

## PRIZE & TAX HANDLING (backend checklist, not UI)

- [ ] Track cumulative prize value per `user_id` per calendar year in a `prize_awards` table
- [ ] If value >= $600 in a year, flag for 1099 issuance — collect winner SSN/TIN before releasing prize
- [ ] Winner notification must go out within the timeframe stated in the Official Rules
- [ ] Store winner's full name, mailing address, and consent to use name/likeness for the live show
- [ ] For Canada winners: generate and present a skill-testing question before awarding the prize

`prize_awards` defined in migration file — create table + wire logic when prizes go live.

---

## FLAGGED RUNS & DISQUALIFICATION

Per the game bible, the admin panel has a flagged runs review flow pre-Sunday.
Any disqualification must:

- Be logged with reason code in a `disqualifications` table
- Reference the `runs.id` that triggered it
- Not reveal disqualification criteria to players (to avoid gaming the detection)
- Be reviewed by a human before the prize is awarded — never auto-disqualify

`disqualifications` defined in migration file — admin UI wiring TBD.

---

## JURISDICTION QUICK REFERENCE

| Region        | Include at launch? | Key requirement                                      |
|---------------|--------------------|------------------------------------------------------|
| 50 US states  | Yes (with voids)   | Void AZ, MD, ND, VT. Special handling FL + NY >$5k. |
| Canada        | Yes                | Skill-testing question required for ON, QC, MB       |
| UK            | Yes (confirm)      | Document skill element clearly; low gambling risk     |
| EU            | Optional           | GDPR separate consent layer required                 |
| Mexico        | No — Phase 2       | SEGOB permit required, ~60 day lead time              |
| Australia     | No — Phase 2       | State-level permits required (NSW, VIC, SA)          |

---

## FILES IN THE PROJECT (today vs to build)

**In repo now (documentation + SQL only):**

- [`LEGAL_IMPLEMENTATION_BRIEF.md`](LEGAL_IMPLEMENTATION_BRIEF.md) — this document
- [`supabase/migrations/20260405120000_legal_consent_and_audit_tables.sql`](supabase/migrations/20260405120000_legal_consent_and_audit_tables.sql) — **unapplied** until legal build
- Pointers in [`GAME_BIBLE.md`](GAME_BIBLE.md) §8 and [`CURSOR_ROADMAP.md`](CURSOR_ROADMAP.md) (“Start here next session (legal compliance)”)

**To build when starting legal work:**

```
prototypes/legal/
  tos.html, privacy.html, cookies.html, acceptable-use.html, dmca.html, competition-rules.html

prototypes/components/   (or equivalent — vanilla modules)
  LegalConsentModal.js   ← sign-up TOS/Privacy
  AgeGate.js             ← Competition entry DOB + rules
  CookieBanner.js        ← first visit; localStorage cookie_consent_v1
```

**Also:** L1 + HUD copy (“no purchase necessary”), sign-up checkbox + consent row,
Competition gate + server enforcement, admin disqualification UI → `disqualifications`.

---

*This document is a developer implementation brief, not legal advice.
Have a licensed attorney review all final legal documents before launch,
especially the Official Competition Rules.*
