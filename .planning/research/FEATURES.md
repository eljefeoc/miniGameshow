# Features Research

**Project:** miniGameshow — mobile web game show platform
**Researched:** 2026-04-02
**Confidence note:** WebSearch and WebFetch were unavailable during this session. All findings draw on training data (cutoff August 2025). Where recency of a legal or regulatory claim matters, that item is explicitly flagged LOW confidence and marked for legal review before launch.

---

## Table Stakes (must have or users leave)

These are features users expect from any daily-challenge or competition game. Absence of any one creates friction significant enough that users will not return.

### 1. Instant playability — no install, no signup wall
**What:** The game must be fully playable without creating an account. Account creation can be prompted after the first play, never before.
**Why expected:** Wordle's viral explosion in 2021-2022 was driven entirely by the fact that the URL opened directly to a playable game. Any friction before first play kills share-link conversions. NYT Games, Connections, and every successful web game since has preserved this.
**Complexity:** Low — already addressed by PROJECT.md's "zero friction" core value. The existing prototype achieves this.
**Implementation note:** Guest scores can be stored locally (localStorage) and migrated to an account post-signup. Do not discard guest progress as a coercive signup prompt.

### 2. Daily cadence with a hard cutoff
**What:** One "challenge period" per event — players know when it closes. A countdown is always visible. Results are final and published at a defined moment.
**Why expected:** Daily/weekly challenge games have trained users to expect temporal stakes. Without a visible cutoff, the competition has no urgency. Wordle resets at midnight local time. NYT Spelling Bee has a daily new puzzle. The deadline is what makes leaderboard position feel earned.
**Complexity:** Low-Medium — already partially built (weeks table, countdown HUD). Needs reliable server-side cutoff enforcement, not client-side only.
**Critical detail:** Cutoff must be server-enforced. A client that submits a score one second after close, or a user who manipulates their device clock, must be rejected at the API layer.

### 3. Score persistence and visible rank
**What:** After each run, users see their current rank on the leaderboard. Rank updates in near-real-time or on page refresh.
**Why expected:** Competition without visible standing is not a competition. Players need to know whether it's worth using another attempt. "You are #47 of 1,203" is motivating. "You scored 3,400" in isolation is not.
**Complexity:** Low — already built (leaderboard table, rank display in HUD).

### 4. Attempt limiting with transparency
**What:** A clear, visible indicator of how many plays remain today. The 5-attempt limit is explained, not just enforced silently.
**Why expected:** NYT Games (Wordle: 1/day, Connections: 1/day) and Duolingo use attempt or session limits as anti-burnout mechanics. Users accept limits when they understand the reason and see them displayed honestly. Dots, progress bars, or "X of 5 attempts used" patterns all work. Unexplained "you cannot play" is enraging.
**Complexity:** Low — already built (attempt dots in HUD, DB trigger enforcement). Needs clear "come back tomorrow" copy when exhausted.

### 5. Mobile-first, full-viewport game experience
**What:** The game fills the screen on a 375px-wide phone. No pinch-zoom required. Touch targets are at minimum 44x44px. No horizontal scroll.
**Why expected:** Instagram, TikTok, and SMS are the primary discovery channels. Every new user is arriving on a phone. A game that requires landscape rotation, pinch-zoom, or precise small-target tapping will be abandoned immediately.
**Complexity:** Medium — explicitly flagged as Active in PROJECT.md. Canvas games require specific viewport/scaling logic.

### 6. Share result after play
**What:** A tappable "Share" button that produces a score card — either an image (like Wordle's emoji grid) or a pre-populated text+link. On mobile, this invokes the native share sheet.
**Why expected:** Wordle's share mechanic was the single biggest driver of its viral growth. The shareable result became social currency. Without this, the game relies on passive word-of-mouth. Every successful daily challenge game (Wordle, Quordle, Heardle, Connections, Framed) has a share mechanic as a core feature, not an afterthought.
**Complexity:** Medium — Web Share API is well-supported on modern mobile browsers. Image generation (canvas-to-PNG) adds complexity but produces higher-quality shares. Text + emoji fallback is simpler. PROJECT.md has this as Active.

### 7. Account creation with display name
**What:** Players can create an account with a chosen display name that appears on the leaderboard. Email/password is fine for v1; OAuth (Google, Apple) is table stakes for v2.
**Why expected:** Anonymous leaderboards ("Player #4471") have no social pull. Named leaderboards create identity investment — players want to see their name at the top.
**Complexity:** Low — already built (Supabase auth, profiles table).

### 8. Leaderboard (event-scoped, final snapshot)
**What:** A ranked list of all players in the current event, sorted by best score. Visible during and after the event. After cutoff, it is frozen.
**Why expected:** Without a public leaderboard, there is no competition. The leaderboard is the scoreboard — it's the object of the game.
**Complexity:** Low — already built. The key implementation detail is "best score" semantics (not sum, not latest — best single run score should be used unless game design calls for otherwise).

---

## Differentiators (competitive advantage)

These are features that set miniGameshow apart from other web games. Users don't expect them, but they create loyalty, word-of-mouth, and a reason to return.

### 1. The Sunday live stream crowning moment
**What:** A live-streamed event that announces the winner, shows gameplay highlights, and makes the winner feel like a real champion. The stream is the marketing engine — it's what turns a score game into a "game show."
**Why it differentiates:** No daily web challenge game currently anchors to a recurring live event. Wordle, Spelling Bee, and similar games produce engagement through leaderboards and streaks, but there is no communal "watching together" moment. The live show creates a reason to tell your friends, a reason to play this week, and a reason to watch even if you didn't win.
**Complexity:** High — live streaming infrastructure is out of scope for v1 product code, but the product must serve it: score snapshots at cutoff, winner surfacing in admin, and a "watch the show" CTA in the post-game experience.

### 2. Original character IP with consistent world-building
**What:** The Penguin, Babs the Walrus, and the Arctic world are original, expressive, designed-with-intent characters — not generic game art.
**Why it differentiates:** Among-Us, Duolingo's Duo, and Fall Guys each built genuine character affection that became marketing assets. Players rooted for characters, shared art, bought merch. Generic art is forgotten; characters are remembered.
**Complexity:** Low (design effort, not engineering effort). The constraint is consistency — the same character, rendered the same way, every time.

### 3. Under-18 practice mode with its own leaderboard
**What:** Players who do not age-verify (or explicitly identify as under 18) can play all games fully, see their score on a practice-mode leaderboard, but cannot compete for prizes. The experience is not degraded — it is labeled "Practice Mode."
**Why it differentiates:** Most prize competition platforms simply exclude minors. This platform deliberately includes them in a parallel track. It is both legally appropriate and inclusively designed. A 16-year-old who gets good at Penguin Fisher is a future adult player (and current social sharer).
**Complexity:** Medium — requires profile flags, separate leaderboard views, and copy that explains the distinction without making minors feel like second-class players.

### 4. Zero-friction social link ("tap and play in 10 seconds")
**What:** The share link brings a new user directly to the game, not a marketing landing page. First-time users are playing within 10 seconds of tapping the link.
**Why it differentiates:** Most competition apps require app download, account creation, or both before showing the game. This platform's link IS the game. That is architecturally rare and high-value.
**Complexity:** Low (it's a product constraint already validated). The engineering risk is regression — features added later (consent banners, signup gates, loading spinners) must not break the 10-second rule.

### 5. Operator-controlled event system
**What:** An admin can create events of variable duration (hours to weeks), attach a game, set an optional prize, and end the event with a manual or auto-triggered cutoff.
**Why it differentiates:** This flexibility makes the platform usable for different formats — a 4-hour Friday flash competition, a week-long championship, a no-prize beta test. Most daily challenge games are hardcoded to one cadence (daily or weekly).
**Complexity:** Medium — already partially built. Needs reliable cutoff enforcement and clear admin UX.

### 6. Seeded RNG for fair daily seeds
**What:** All players on the same day face the same game parameters (fish spawn patterns, physics seeds, etc.), determined by a daily seed. This ensures leaderboard legitimacy — the #1 score was achieved on the same game as everyone else.
**Why it differentiates:** Many score-attack games allow players to "roll" for better seeds. Seeded daily challenges are perceived as fairer and create shared experience ("I got that big fish on attempt 3 too!").
**Complexity:** Low — already built. Must document the seeding scheme so it can be applied to Game 02 and 03.

---

## Anti-Features (deliberately NOT building in v1)

These are features that seem reasonable but should be explicitly deferred or rejected.

### 1. Real-time live leaderboard (auto-refreshing during play)
**What to avoid:** A leaderboard that refreshes every 5-10 seconds while the event is live, showing rank changes in real time.
**Why to avoid:** This creates two problems: (a) anxiety-driven play — users who are close to losing their rank will spam attempts rather than enjoying the game; (b) infrastructure complexity — polling or WebSocket connections for potentially thousands of concurrent players is a real-time backend problem that is not needed in v1.
**What to do instead:** Snapshot leaderboard on page load, refresh on score submission. Players see their rank after each run. That is sufficient and creates less toxic engagement dynamics.
**Complexity saved:** High. Real-time leaderboards require either polling infrastructure with rate-limit logic or WebSocket connection management.

### 2. In-app prize claiming flow
**What to avoid:** A form, payment integration, or claim workflow where winners submit their prize claim inside the product.
**Why to avoid:** Prize claiming flows involve: identity verification, fraud prevention, payment/shipping data handling, legal documentation (W-9 for US cash prizes over $600), and support workflows for failed claims. This is disproportionately complex for v1 where the operator knows their audience.
**What to do instead:** Admin sees #1 at cutoff; operator contacts winner directly. Add a "winner contact" field to the profile later.

### 3. Notification system (push or email)
**What to avoid:** "You have attempts left today!" or "A new event is live!" push notifications or email campaigns.
**Why to avoid:** Push notification opt-in rates on web are under 15% and declining. Email requires CAN-SPAM compliance, list management, and unsubscribe flows. Neither is worth the complexity in v1 when social share links are the distribution mechanism.
**What to do instead:** The Sunday show and social share cards are the re-engagement mechanism. Build those well before adding notifications.

### 4. Multiple simultaneous events
**What to avoid:** Supporting corporate events, branded events, and the main weekly event running concurrently.
**Why to avoid:** Multi-tenancy means every data query must be scoped to an event. Every leaderboard query, every attempt limit check, every winner lookup becomes more complex. Validate the single-event core loop first.
**Already in PROJECT.md out of scope.** Documented here for reinforcement.

### 5. Social login (Google/Apple OAuth) in v1
**What to avoid:** Treating OAuth integration as table stakes for v1.
**Why to avoid:** OAuth integration requires additional security review, callback URL management, and edge cases (account collision when same email used for both email and OAuth). Email/password is sufficient for v1 with a small beta audience.
**What to do instead:** Add it in v2 when the friction of email signup is validated as a conversion problem.

### 6. Game tutorials / onboarding flows
**What to avoid:** Interactive tutorials, coach marks, or step-by-step onboarding screens.
**Why to avoid:** Games designed to be "instantly legible in 10 seconds" (per GAME_BIBLE constraint) should not need tutorials. Adding a tutorial is a signal the game design has failed, not a solution to bad game design. Tutorial flows also add load time and break the "tap and play" promise.
**What to do instead:** Fix the game design if playtesters cannot figure it out in 10 seconds.

### 7. Streak tracking
**What to avoid:** "You've played 7 days in a row!" streak mechanics.
**Why to avoid:** Streaks are powerful retention tools but they create anxiety and obligation. Duolingo has famously grappled with streak anxiety becoming a source of user burnout. For a competition game where the fun should be winning, not maintaining a counter, streaks are off-brand. They also create guilt when life interrupts a 30-day streak — which is the opposite of the "zen, light, never stressful" tone specified in PROJECT.md.
**What to do instead:** Let returning players take satisfaction from improving their leaderboard rank across events.

---

## Competition / Event Mechanics

### Event window patterns from comparable products

**Wordle (NYT):** One puzzle per day, resets at midnight local time. Infinite attempts but only one puzzle to guess. Score is attempts-to-solve (1-6). Share is that day's score. No prizes.
- **miniGameshow adaptation:** One event per operator-defined window. Score is best single-run score across 5 daily attempts. The event window (not a daily reset) is the competitive period.

**NYT Spelling Bee:** Daily, no attempt limit, but letter set is fixed. Players have a hidden "genius" score target. No prizes.
- **miniGameshow adaptation:** N/A — no relevance to the score-attack model.

**Kahoot (live game shows):** Operator-initiated game session, players join via code, questions are simultaneous. Real-time leaderboard is the mechanic. No async play.
- **miniGameshow adaptation:** The Sunday show is the Kahoot "live moment." The week-long competition is the async buildup. This is a meaningful structural distinction — miniGameshow is primarily async with a live crowning moment, not primarily live.

**HQ Trivia (defunct, but instructive):** Scheduled live events at specific times. Players eliminated in real time. Prize split among winners. Died because: (a) live schedule friction is high; (b) eliminated players had nothing to do; (c) infrastructure cost was unsustainable at scale.
- **miniGameshow lesson:** Do not require live participation to compete. The live show is a bonus, not a gate. A player who can't watch Sunday still experienced the competition.

### Countdown and cutoff UX patterns

**Best practice (observed across Wordle, NYT Games, Lichess daily puzzles):**
- Countdown clock is always visible during active events
- When time expires: the current event closes, scores freeze, a "results" view appears
- New event announcement is shown immediately (or a "next event starts [date]" message)
- Players who submit a run within seconds of cutoff: server timestamp is authoritative, client-side countdown is approximate only

**Implementation requirement:** Server-side score submission must record a `submitted_at` timestamp from the server (not from the client request). Scores with `submitted_at > event.cutoff_at` are rejected, not just ignored. Return a clear error so the UI can show "Event has ended — your score was not counted."

### Attempt exhaustion messaging patterns

**Bad pattern (avoid):** Silent "submit" button that does nothing when attempts are exhausted.
**Good pattern (use):** After the 5th attempt, replace the game UI with a "You're done for today" screen showing:
- Best score achieved today
- Current leaderboard rank
- Time until next attempt reset (if within current event)
- Share button (let them share even if they're done)
- "Come back tomorrow" — exact time, not vague

---

## Age Verification Patterns

**Confidence level: MEDIUM for technical patterns, LOW for legal sufficiency.** Legal sufficiency of any verification method varies by jurisdiction and requires counsel review before public launch.

### What "age verification" means in practice for competition games

There is a spectrum from "honor system" to "hard identity verification." For skill-based competitions with modest prizes, most US operators use methods in the low-to-middle of the spectrum. Full identity verification (government ID scan) is typically reserved for gambling, high-value sweepstakes, or jurisdictions with explicit legal requirements.

### Pattern 1: Self-declaration (honor system)
**How it works:** During account creation or profile completion, a checkbox or date-of-birth field. "I confirm I am 18 or older." No verification of the claim.
**Who uses it:** Most casual web game competitions, Skillz (for lower-value prizes), many sweepstakes.
**Legal sufficiency:** In the US, self-declaration creates a contractual representation. It shifts liability to the user who misrepresented their age. It is not legally sufficient in jurisdictions with strict age verification laws (UK's AV Act, for example), but for casual US skill competitions with modest prizes, it is a common baseline.
**Complexity:** Very Low. A checkbox + terms acceptance at signup.
**Recommendation for miniGameshow v1:** Self-declaration with a clear date-of-birth field (not just a checkbox) is appropriate for v1 with a small, known audience. The DOB field lets the platform automatically determine 18+ vs. under-18 routing rather than requiring the user to manually select a tier.

### Pattern 2: Winner verification (deferred)
**How it works:** Age is not verified at signup. When a winner is identified, the operator requests age verification (ID, etc.) before delivering the prize. This is the most common pattern for skill competitions.
**Who uses it:** Most US sweepstakes and skill contests. Standard language: "Winner may be required to submit proof of eligibility before prize is awarded."
**Complexity:** Very Low (product-side) — add a notes field to the winner admin view. Verification happens off-platform.
**Recommendation for miniGameshow v1:** This is the right pattern for the prize-claiming workflow. Pair it with self-declaration at signup for the dual-track (18+/practice) routing.

### Pattern 3: Credit card verification
**How it works:** Require adding a payment method as an age proxy (credit cards generally require 18+). Only relevant if there's a paid tier.
**Applicability to miniGameshow:** Zero — the platform is explicitly free-to-play, no payment flows.

### Pattern 4: COPPA considerations (under-13)
**What:** The Children's Online Privacy Protection Act (US) prohibits collecting personal information from users under 13 without verifiable parental consent. This is a hard legal requirement, not a best practice.
**Relevance:** miniGameshow's practice mode allows under-18 players, which means under-13 players may create accounts. This triggers COPPA obligations if the platform collects any PII (email address, display name, device ID) from under-13 users.
**Options:**
- (A) Gate at 13+ for account creation (under-13 cannot create accounts, cannot access even practice mode). Simplest.
- (B) Parental consent flow for under-13. Extremely complex to implement correctly.
- (C) Do not collect PII from under-13 accounts. Effectively means no account creation for under-13 — same as option A.
**Recommendation:** For v1, the minimum age for account creation should be 13. Practice mode is available for ages 13-17. Under-13 play is out of scope. This must be stated in Terms of Service.
**Confidence: MEDIUM** — COPPA is well-established US law, but applicability details (what counts as "directed at children") should be reviewed by counsel before public launch.

### Implementation recommendation for miniGameshow

At profile completion (after first play or before entering an event):
1. Date of birth field (required to compete or appear on leaderboard)
2. If calculated age < 13: "You must be at least 13 to create an account. Please ask a parent or guardian."
3. If calculated age 13-17: Route to practice mode. Explain: "You can play all games and see your scores on the practice leaderboard. Prize competitions are open to players 18 and older."
4. If calculated age 18+: Full competition access.
5. Terms of Service acceptance that includes age representation language.

Store the declared date of birth, not just an age flag, so the platform can re-evaluate at the next birthday automatically (a player who turns 18 mid-event should be eligible for the next event).

---

## Virality Mechanics

### The Wordle share card — why it worked and what made it spread

Wordle's share mechanic produced a specific social behavior: people posted their result in group chats and on Twitter before saying what game it was. This created curiosity loops ("What is this grid of emoji?") that drove installs.

**What made it work:**
1. **Spoiler-free:** The grid shows your performance without revealing the answer. People could share without ruining the game for friends who hadn't played.
2. **Social proof:** Seeing "Wordle 423: 4/6" from 5 different friends in one day created FOMO pressure.
3. **One tap:** Tap "Share" → clipboard filled or share sheet opens. Zero friction.
4. **Universally renderable:** Emoji text works in every messenger, every platform, every OS. No image needed.

**What miniGameshow should adapt:**
- The score card should show performance without showing "how to beat it" — share the score and rank, not a guide to achieving it.
- Emoji-based text share is the low-complexity baseline. Canvas-generated image share is higher quality and more visually branded, but emoji text fallback should always exist.
- The share text must include the game link. Every share is an acquisition channel.

### Share card content recommendation

```
[Arctic character emoji or game name]
Event: Week 3 Championship
My score: 4,820 | Rank: #12
I have 2 attempts left — can you beat me?
[link]
```

Key elements:
- Score and rank (social proof + competitive hook)
- Remaining attempts if any (urgency — "they still have tries left")
- Direct link to play (acquisition)
- No spoilers (doesn't explain how to get a high score)

**Complexity:** Medium. Requires: share button component, Web Share API integration, clipboard fallback, score/rank data at time of share. Image generation (canvas-to-PNG) is optional but recommended for visual brand consistency.

### Challenge link pattern

**What:** A link that, when tapped by a new user, shows the sharer's score as a target to beat ("Jeffrey scored 4,820 — can you top it?") before dropping them into the game.
**Who uses it:** Letterboxd challenges, Kahoot challenge links, Duolingo challenges.
**Value:** Higher click-through than generic links because the challenge is personal and specific.
**Complexity:** Medium-High. Requires: URL parameter encoding of challenger's score/name, a challenge landing screen that shows the target, then transitions to the game. Needs to handle expired events gracefully ("This challenge was from a past event. A new one starts [date]").
**Recommendation:** Implement in v2, after share cards are validated as working. Share cards first; challenge links are an amplification of a working share mechanic.

### Open Graph / social preview metadata
**What:** When the game URL is shared in iMessage, Discord, Twitter, or WhatsApp, the link preview card shows the game's visual, title, and description rather than a blank or broken preview.
**Why it matters:** A link with no preview is frequently not tapped. A link with a clear, attractive preview showing the game and an active event has significantly higher CTR.
**Implementation:** `<meta property="og:image">` pointing to a static event-themed image (or dynamically generated), `og:title`, `og:description`. Dynamic OG images (showing current scores or event state) require a server-side image generation function — simpler to start with a static event image per active event.
**Complexity:** Low (static OG) to High (dynamic OG). Start static.

### In-game "tell a friend" prompts
**What:** After a particularly good run (top 10, personal best), show a prompt: "You're in the top 10! Share your rank."
**Why it matters:** Contextual prompts tied to achievement ("you're winning") produce much higher share rates than generic "share this game" buttons.
**Complexity:** Low — requires knowing rank at time of play (already calculated) and a conditional display rule.

---

## Legal Considerations

**Confidence level: LOW for all legal claims.** This section reflects common industry practice and training-data knowledge through August 2025. It is not legal advice. Every claim here requires review by a licensed attorney familiar with promotional law in the jurisdictions where the platform operates before public launch.

### Sweepstakes vs. Skill Contest — the critical distinction

**Sweepstakes:** Winner determined by chance (random drawing). In the US, sweepstakes require:
- No purchase necessary (AMOE — Alternate Method of Entry must exist)
- Official rules
- Disclosure of odds
- Prize descriptions
- Sponsor identification
- Prohibited in some states or subject to state-specific requirements (NY, FL historically require registration/bonding for large prize sweepstakes)

**Skill contest:** Winner determined by skill (highest score, best performance). Does NOT require AMOE because there is no element of chance. The FTC and courts have historically treated skill contests differently from lotteries.

**Why this matters for miniGameshow:** miniGameshow is a skill contest — the highest score wins. This is the most favorable legal category because:
1. No AMOE requirement (no need for "enter by mail")
2. Not considered gambling (no element of chance in determining winner)
3. Lower regulatory burden than sweepstakes in most US states

**The risk to manage:** A court or regulator could argue that the game involves enough luck (physics randomness, fish spawn patterns) that it has a "substantial element of chance." The seeded RNG that gives all players the same game parameters is a critical mitigation — it proves all players face identical conditions. Variance in score is attributable to player skill, not differing game conditions.

### Minimum required legal infrastructure (v1 framework)

These are the elements the platform needs before any public launch with real prizes:

1. **Terms of Service** — must include: age requirements (13+ to create account, 18+ to compete for prizes), eligibility (residency restrictions if any), representation that entries are original, prize description, how winner is determined, right to disqualify for cheating.

2. **Privacy Policy** — required by California (CCPA), GDPR (if any EU users), and general best practice. Must describe what data is collected (email, DOB, scores, IP), how it's used, and how users can request deletion.

3. **Official Contest Rules** — for each event with a prize. Must state: eligibility, entry period (event window), how winner is determined, prize description and approximate retail value (ARV), odds of winning, sponsor name and address, how winner is notified, prize claim procedure, and publicity rights (can you use the winner's name/likeness in marketing?).

4. **Geo-restriction framework** — Some states (Rhode Island, historically) have had sweepstakes registration requirements. Quebec (Canada) has strict promotional contest rules. The platform should be able to block or flag entries from specific jurisdictions. PROJECT.md already includes "geo/age restriction framework" as Active — this is the right call.

**Confidence: LOW** — Promotional law is jurisdictionally complex and changes. The above reflects common US practice through mid-2025, but the legal review milestone should happen before any event with prizes is marketed publicly.

### COPPA (Children's Online Privacy Protection Act)
- Applies to US services that knowingly collect PII from users under 13
- miniGameshow must not allow under-13 account creation without verifiable parental consent
- Minimum account age: 13 (or higher)
- **Confidence: MEDIUM** — COPPA is well-established US federal law. Specific applicability to this platform requires counsel review.

### W-9 / 1099 reporting threshold (US)
- In the US, prizes with a Fair Market Value over $600 to a single recipient in a calendar year must be reported on a 1099-MISC. For cash prizes over $600, a W-9 is required from the winner before delivery.
- This is an operator/accounting obligation, not a product feature in v1. Document it in the winner admin notes so the operator knows to collect a W-9 if the prize exceeds the threshold.
- **Confidence: MEDIUM** — IRS publication thresholds are well-established but subject to annual updates.

### Gambling vs. skill competition
- The platform must not constitute "illegal gambling" — which requires: prize + chance + consideration (something of value paid to enter). miniGameshow: free to play (no consideration), skill-determined winner (no chance). Both elements that would make it gambling are absent.
- The seeded RNG and identical-conditions design are structural protections against a "substantial chance" argument.
- **Confidence: MEDIUM** — The "three elements" test for gambling is standard US legal doctrine. State-level variations exist.

---

## Summary for Roadmap

### Build in v1 (table stakes + legal minimum)
- Instant playability (no-signup-required first play) — already designed
- Hard server-side event cutoff enforcement
- Attempt exhaustion UI with "come back tomorrow" messaging
- Share card (Web Share API + clipboard fallback, text-first, image optional)
- Age gate via date-of-birth field at profile completion
- Under-18 practice mode routing (ages 13-17)
- Under-13 block at account creation
- Open Graph metadata (static per event)
- Legal documents framework (Terms, Privacy Policy, Contest Rules template)

### Build in v2 (differentiators, once core loop is validated)
- Challenge links (personalized "beat my score" links)
- Dynamic OG image generation
- OAuth login (Google/Apple)
- Winner contact info collection in profile
- Geo-restriction admin controls (block specific states/countries)

### Explicitly defer
- Real-time leaderboard polling
- Push notifications / email campaigns
- Streak mechanics
- In-app prize claiming
- Tutorials or onboarding flows
- Multiple simultaneous events

---

## Sources and Confidence Notes

All findings are from training data (knowledge cutoff August 2025). No live web sources were accessible during this research session.

| Area | Confidence | Basis |
|------|------------|-------|
| Daily challenge mechanics (Wordle patterns) | HIGH | Well-documented, widely reported through 2025 |
| Share card patterns | HIGH | Well-documented, stable patterns |
| Web Share API | HIGH | W3C spec, well-established browser support |
| Leaderboard design patterns | HIGH | Standard industry practice |
| US sweepstakes vs. skill contest legal framework | MEDIUM | Well-established doctrine, but jurisdictionally complex; requires legal review |
| COPPA | MEDIUM | Well-established US federal law; specific applicability needs counsel review |
| Age verification sufficiency | LOW | Varies by jurisdiction, evolving regulation (UK AV Act, etc.); requires legal review before launch |
| W-9 / 1099 thresholds | MEDIUM | Well-established IRS rules; subject to annual updates |
| Open Graph best practices | HIGH | Stable web standard |
| Under-13 platform handling | MEDIUM | COPPA doctrine is clear; platform-specific implementation needs review |
