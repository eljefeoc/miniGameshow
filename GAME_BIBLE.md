# GAME BIBLE
### [WORLD NAME — TBD] — Working Title
*Last updated: March 2026 | Version 1.1*

---

> **How to use this document**
> This is the single source of truth for every decision made about this product.
> Paste the relevant sections at the start of every AI session, every design
> conversation, and every developer onboarding. It is a living document —
> update it when decisions change, never let it go stale.

---

## 1. THE ELEVATOR PITCH

**One sentence:**
A mini game show you play on your phone every day — one link, no download,
five attempts, real prizes, live weekly champion crowned on stream.

**The Wordle comparison:**
Like Wordle but a game, with stakes. Same daily ritual. Same "everyone plays
the same thing." But with characters you care about, a live event every Sunday,
and a real prize for the winner.

**The antidote framing:**
This product exists as a direct response to doom-scrolling and addictive mobile
gaming. Five attempts per day. Then you're done. The limit is a feature, not a
restriction. Players come back tomorrow because they want to, not because an
algorithm trapped them.

---

## 2. THE CORE PRODUCT LOOP

```
Monday — New game drops. Link goes live. Social posts go out.
Tuesday–Saturday — Players get 5 attempts per day. Leaderboard updates live.
Saturday night — Last chance posts. Urgency window.
Sunday — Leaderboard locks. Top scores reviewed. LIVE EVENT crowns champion.
Monday — New week. New game. New prize. Loop repeats.
```

**The live Sunday event is the product.**
The game is the vehicle. The weekly live stream — host, replay of winning run,
champion on camera, prize handoff — is the moment that makes this a show,
not just an app. Every technical and design decision should serve this loop.

---

## 3. THE FEELING

**Primary emotion (first 10 seconds of play):**
Playful and light — pure fun, no pressure.

**What that means in practice:**
- The game should make you smile within the first 5 seconds — character
  animation, sound, and visual warmth all work together toward that
- Zero onboarding anxiety — a first-time player should understand what
  to do instinctively, not by reading instructions
- Failure feels funny, not frustrating — getting hit by a lunging seal
  should produce a laugh, not a groan
- The world is inherently joyful — color, sound, and character personality
  all reinforce lightness at every moment
- Stakes exist (leaderboard, prizes, weekly champion) but they sit underneath
  the fun — never on top of it

**The cozy layer underneath:**
While the primary hit is playful and light, there's a warm, cozy undertone
that keeps people coming back. The Arctic world, the characters, the sunset
palette — these create comfort and familiarity over time. First visit is fun.
Tenth visit feels like coming home.

**What it explicitly is NOT:**
- Not stressful or anxiety-inducing
- Not dark or aggressive in tone
- Not designed to maximize session length or exploit habit loops
- Not pay-to-win, ever
- Not a game that makes you feel bad for losing

---

## 4. THE PLAYER

**Primary audience: Everyone — intentionally broad.**

This is a deliberate strategic choice. The product is designed to have no
natural excluder — no genre gatekeeping, no skill barrier to entry, no
cultural reference that loses half the room. A 9-year-old and a 55-year-old
should both pick it up and smile within 10 seconds.

**What "everyone" actually means in practice:**
Designing for everyone is designing for the lowest friction possible at the
entry point, with depth that reveals itself over time. The first 15 seconds
must be universally legible. The combo system and frenzy meter are there for
players who go looking for depth — they are never in the way of someone who
just wants to jump over a walrus.

**The four player types this world serves:**

*The Curious Tapper* — saw a link, tapped it, never played a game in their
life. Must feel instant joy within 10 seconds or they're gone. Design test:
would your least "gamer" family member smile immediately?

*The Daily Ritualist* — comes back every day for the same 5 attempts, checks
their rank, moves on. The daily seed and leaderboard exist for them. They are
your retention backbone.

*The Competitor* — cares deeply about rank, studies the daily seed pattern,
chases the combo multiplier. The depth systems (frenzy, combos, terrain
reading) exist for them. They are your live event audience.

*The Social Sharer* — plays primarily to share their score and challenge
friends. The score card, the one-link model, and the weekly prize drama exist
for them. They are your growth engine.

**The universal design test:**
Before shipping any feature ask: "Does this make the game more fun for
everyone, or does it only serve one player type at the expense of another?"
Features that serve all four types simultaneously are gold. Features that
actively alienate any type need rethinking.

**Note on the previous "burned out doomscroller" framing:**
That audience is still very much here and very much served — the 5-attempt
limit, the healthy gaming philosophy, the calm Arctic world all speak directly
to them. But they're one segment of everyone, not the ceiling of ambition.

---

## 5. THE WORLD

### Setting
The Arctic — ice, ocean, aurora borealis, sunsets, seasons. Cold environment,
warm soul. The visual palette is sunset oranges and golds against ice blues and
deep purples. It feels like a place that's magical precisely because it's remote
and quiet.

**The Arctic world is the HOME BASE.** Individual games may visit other settings
as the world expands — the deep ocean below the ice, a distant snowy mountain,
a summer thaw — but they all connect back to this world and its characters.

### Tone
- Pixar's warmth applied to an Arctic world
- Whimsical but never childish — adults should feel at home here
- Humor comes from character personality, not slapstick
- The world has history and lore even if players never see it explicitly —
  it should feel like a real place with real relationships

### The Visual Language
- Cartoon-first rendering (rounded shapes, expressive eyes, exaggerated
  proportions) not pixel-art-first
- Sunset color palette dominant: warm oranges, golds, purples bleeding into
  ice blues
- Characters are chubby and expressive — think Pixar shorts proportions
- UI floats on top of the game world rather than surrounding it —
  the world always feels full-screen

---

## 6. THE CHARACTERS

*Note: Names are working titles. A proper naming/design session with a
character designer is a planned milestone before public launch.*

### The Penguin (Player Character — Working name: TBD)
**Role:** The heart of the world. Playful, determined, slightly accident-prone.
Loves fishing above everything else. The player IS this character.

**Personality:** Optimistic. Gets nervous when things go wrong (visible in
expressions) but bounces back fast. Competitive but not ruthless — celebrates
other players' good runs. Has a signature fishing rod that's slightly too big
for them.

**Emotional states (implemented in game):**
- Happy — default walking state, tail wag
- Excited — star eyes, during frenzy mode or double jump
- Scared — X eyes, when lives are low or after getting hit
- Nervous — sweat drop, when cast window is closing

**Design rules:**
- Always round — no sharp edges on the protagonist
- Eyes are the primary emotional communicator — make them large and readable
- The fishing rod is a character prop, always present, always expressive

---

### The Walrus (Working name: TBD)
**Role:** The elder/shopkeeper of the world. Grumpy on the surface, secretly
supportive. Shows up as an obstacle in games but has lore as a community
pillar — runs the ice trading post, knows everyone's business.

**In-game behavior:** Breathes (hitbox expands and contracts), giving skilled
players a window to slip past. The breathing is also a personality trait —
he sighs heavily and constantly.

**Design rules:** Large, round, purple-tinted. Tusks are prominent. The eyes
convey reluctant wisdom. He should look like he's been here forever.

---

### The Polar Bear (Working name: TBD)
**Role:** The rival/antagonist — but a charming one. Not evil, just competitive.
Has a complex relationship with the penguin — respect masked by rivalry.

**In-game behavior:** Variable speed (oscillates between slow and fast charges).
Gets visibly angry when moving fast — furrowed brows, speed lines. Calm and
almost friendly when slow.

**Design rules:** White and fluffy but imposing in scale. Size contrast with the
penguin matters — he should feel like a real threat. Expressive face is key.

---

### The Seal (Working name: TBD)
**Role:** Comic relief and sidekick energy. Doesn't take anything seriously.
Secretly the most skilled character in the world at everything.

**In-game behavior:** Lunges toward the player with a warning telegraph —
a pre-lunge crouch and flash before the burst. The lunge is his personality:
chaotic, impulsive, immediately regretful.

**Design rules:** Grey-blue tones. Wide eyes that convey perpetual surprise.
Whiskers are expressive — they spread when lunging, droop when sad.

---

### The Narwhal (Working name: TBD)
**Role:** The mysterious deep-water character. Rarely seen. Appears in bonus
moments (golden fish events, frenzy mode) as a hint that there's something
bigger in the world below the ice. May become central to a future game.

**In-game presence:** Not an obstacle — a reward signal. Seeing the narwhal
means something good is about to happen.

**Design rules:** Deep ocean blues and purples. The horn glows. Should feel
slightly otherworldly compared to the surface characters.

---

## 7. THE GAMES

### Design Philosophy
Every game is a window into the characters' daily lives — not an abstract
challenge. "The penguin fishes" is a premise, not just a mechanic. The
mechanical depth serves the character fantasy.

**The six questions every game must answer before building:**
1. What is the core mechanic (the one thing always happening)?
2. What secondary mechanic runs parallel, creating divided attention?
3. What is the risk/reward decision separating beginners from experts?
4. What economy creates strategic tradeoffs?
5. How does difficulty ramp within a single 90-second session?
6. What does mastery look like, and can the player see it clearly?

### Difficulty Curve (Universal Template)
```
0–15s    COMFORT ZONE   — Slow, easy, player feels competent
15–35s   FIRST PRESSURE — New obstacle type introduced, timing matters
35–60s   SKILL TEST     — All core mechanics active, decisions matter
60–90s   EXPERT ZONE    — Compound challenges, combos pay off here
90s+     SURVIVAL       — Speed maximum, density maximum, pure reaction
```

80% of beginners die in the skill test zone. Experts live in survival mode.
Both experiences should feel fair and satisfying at their level.

### Session Design Rules
- Target run length: 90 seconds to 3 minutes per attempt
- 5 attempts per day, resets at midnight local time
- Daily seed: date-based PRNG — everyone plays identical level that day
- Same level across days means players can study and improve deliberately
- Leaderboard locks Saturday night, live event Sunday

---

### Game 01: PENGU FISHER (Prototype Complete)

**Premise:** The penguin's daily fishing route along the ice path.

**Core mechanic:** Side-scrolling obstacle dodge (jump/double-jump)

**Secondary mechanic:** Active fishing — bite meter fills, cast window opens,
player must press cast at the right moment to catch

**Obstacles (in order of introduction):**
- Seal — lunges with telegraph warning
- Walrus — breathes (hitbox expands/contracts), slip-under window
- Polar Bear — variable oscillating speed, speed lines when fast
- Ice Block — standable platform, height advantage if landed on top

**Terrain variations:**
- Normal ice — standard
- Slow patch — blue tint, drags speed
- Ramp — upward boost on contact
- Crack ice — breaks after 25 frames standing, falls through

**Economy:** Fish Meter (0–100) fills with catches, triggers Frenzy Mode at 100

**Frenzy Mode:** 6 seconds, 3x points, increased golden fish chance, visual aura

**Combo system:** Consecutive catches build multiplier (1x → 1.5x → 2x → 3x → 5x)
Breaking streak resets to 1x. Combo decay timer visible as bar.

**Scoring:**
- Passive: +1 point every 6 frames (+3 in frenzy)
- Small fish: 50 pts × combo multiplier
- Medium fish: 150 pts in frenzy × combo multiplier
- Golden fish: 500 pts × combo multiplier

**Status:** Prototype complete. Needs: daily seed server validation, score
submission API, PWA shell, performance pass for mid-range Android.

---

### Future Games (Concepts — Not Yet Built)

**Iceberg Surfer** — Ride a shrinking iceberg, jump between floes
**Snowball Dodge** — Arena survival, incoming snowballs from all sides
**Penguin Golf** — One-button power/angle, wild Arctic courses
**Fish Stack** — Tetris-style with fish shapes
**Blizzard Run** — Screen gradually whiteouts, navigate from memory
**Hungry Orca** — Don't get eaten, orca gets smarter
**Arctic Curling** — Flick physics, land closest to center
**Penguin Slingshot** — Launch between icebergs, collect fish mid-air
**Freeze! Thaw!** — Move when polar bear looks away (reverse hide and seek)
**Deep Dive** — Breath meter, pearls, jellyfish, resurface before drowning

---

## 8. TECHNICAL ARCHITECTURE

### Platform Decision
**PWA (Progressive Web App) + HTML5 Canvas. No app store. One URL.**

Rationale: Zero install friction for viral sharing. Universal device support —
any browser from the last 6 years on any device. Wordle model. One link works
everywhere. Optional "Add to Home Screen" for power users but never required.

The URL is the product.

### Performance Budget
- Target: 60fps on a 4-year-old mid-range Android
- First load: under 3 seconds on 3G
- Offline: fully playable after first visit (Service Worker)
- Canvas rendering: lean — no heavy frameworks in the game engine

### Tech Stack
```
Game Engine:    Vanilla JS + HTML5 Canvas (no game framework)
Frontend:       PWA with Service Worker for offline
Hosting:        Vercel (edge network, instant deploys)
Backend/DB:     Supabase (Postgres + Auth + Realtime subscriptions)
API:            Vercel Edge Functions
Storage:        Cloudflare R2 (video replays, score card images)
Social Sharing: Web Share API + Canvas-generated score card images
```

### Daily Seed System
```javascript
// Same date = same game for everyone worldwide
function getDailySeed() {
  const d = new Date();
  return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
}

function makeRng(seed) {
  let s = seed >>> 0;
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 0xFFFFFFFF; };
}
```

All obstacle positions, terrain tiles, fish spawn timing generated from this
seed. Server validates that submitted scores are possible given the day's seed.

### Score Submission Payload
```javascript
{
  userId: string,           // JWT-verified Supabase user ID
  score: number,
  seed: number,             // daily seed (date-derived)
  attemptNumber: number,    // 1–5
  durationMs: number,       // run length — sanity check
  inputCount: number,       // total inputs — bot detection
  inputLog: compressed[],   // every keypress/tap with timestamp
  frameCheckpoints: [],     // score at every 60th frame
  gameVersion: string,      // invalidate old builds
  weekId: string,           // 'YYYY-WNN'
  signature: string         // HMAC of payload with session token
}
```

### Anti-Cheat (5 Layers)
1. **Client:** Input logging, frame checkpoints, session tokens, version pinning
2. **API:** JWT auth, attempt limits server-side, rate limiting, sanity checks
3. **Replay sim:** Server re-runs input log against seed, validates score ±10
4. **Statistical:** Flag scores >3 std deviations above weekly mean
5. **Manual:** Report button on every leaderboard entry. Top 3 manually
   reviewed before every Sunday live event. Human eyes on every prize.

### Database Schema (Key Tables)
```sql
users          — id, email, phone (verified), username, country, is_banned
weeks          — id, week_code, game_id, seed, starts_at, ends_at, prize_title, sponsor_name
runs           — id, user_id, week_id, score, attempt_num, duration_ms, replay_data, is_validated
leaderboard    — user_id, week_id, best_score, best_run_id, rank
daily_attempts — user_id, day_seed, attempts_used (max 5)
content_events — event_type, metadata (triggers social content pipeline)
```

### Viral Sharing Architecture
```
Run ends → Score card generated (Canvas → PNG)
         → Web Share API opens native share sheet
         → Pre-populated: image + score + URL + weekly context

URL carries state: domain.com/play?week=22&score=8420&challenge=jake
                   → Friend sees Jake's score before playing
                   → Immediate competitive context
                   → No account needed to play
```

### Sign-up Flow (Frictionless)
```
1. Land on game page
2. Play a FREE DEMO — no account, local storage only
3. After first run: "Want your score to count? Create free account"
4. Username + email → instant account → playing immediately
5. Phone verify prompt after first real run (required for prize eligibility)
```

Play first. Verify second. Never block play with account creation.

---

## 9. MONETIZATION

### Model: Free to Play, Sponsor-Funded
- **Never charge to play** — zero paywalls on gameplay, ever
- **Never pay-to-win** — money never buys competitive advantage
- **Cosmetic upgrades** — character skins, name colors (Phase 2)
- **Corporate challenges** — private weekly challenge for company teams (Phase 2)

### Sponsorship Structure
**Title Sponsor (1 per week):**
- Logo on game loading screen (3–5 seconds, every attempt)
- 30-second host read at Sunday live stream open
- Winner announcement post features sponsor + prize prominently
- Leaderboard page persistent banner
- Social posts throughout week name and tag sponsor

**Community Sponsor (up to 2 per week):**
- Social mention only, no game placement
- ~40% of title sponsor rate

### Prize Rotation
Mixed categories, rotating weekly to serve different audience segments:
- Aspirational: travel, experiences (weekend trips, concert tickets)
- Practical: subscriptions, gift cards, tools people actually use
- Character-driven: branded merchandise from the game world (Phase 2)

### Revenue Targets (Realistic)
```
Weeks 1–12:   $0 cash — barter prizes only, building proof
Weeks 13–24:  $500–$1,000/week average — first paid sponsors
Weeks 25–52:  $1,000–$3,000/week average — established relationships
Year 1 total: $25,000–$60,000 (after costs ~$5,000–$8,000)
```

### Sponsor Acquisition
Phase 1: Direct email to marketing directors of brand-fit companies.
         Pitch is 3 paragraphs, media kit attached, specific proposal.
Phase 2: Gaming creator marketplaces (StreamElements, Powerspike, Grapevine)
Phase 3: Boutique sponsorship agency (Loaded, Neon) once 5k+ WAU proven

### Key Metric for Sponsor Conversations
**Weekly retention rate** — percentage of players returning the following week.
- 25% = product needs work
- 40% = something real is here
- 50%+ = exceptional, national brand conversations start

---

## 10. CONTENT & SOCIAL

### Weekly Content Calendar
```
Monday    — "This week's game drops!" reveal + teaser clip
Tue–Fri   — Daily leaderboard update (top 5 scores, usernames)
Saturday  — "Last chance" urgency post (hours remaining, current leader)
Sunday    — LIVE EVENT → clip highlights → winner announcement post
```

### Content Automation Pipeline
```
Score submitted → DB trigger → content_events row
Nightly job → checks content_events
→ new_high_score: leaderboard graphic (Canvas → PNG)
→ first_place_change: "New Leader!" short video clip
→ week_end: top-10 highlight reel (headless browser replay recording)
→ upload to R2 → queue for social posting via Buffer API
```

### Live Sunday Event Format
- Duration: 20–30 minutes maximum
- Platform: Instagram Live / YouTube Live (simulcast)
- Format: Host intro → this week's game recap → top 3 replay reveals →
  winner on video call → prize handoff → next week teaser
- The host IS the brand — personality-driven, game-show energy
- Clips from the live event become the following week's promotional content

### Influencer Strategy
- Target: micro-influencers 5k–50k in casual gaming, productivity,
  healthy tech habits, brain games niches
- Avoid: large gaming influencers whose audience plays AAA titles
- Budget year 1: $2,000–$4,000 total, all tracked with unique referral URLs
- Measure: sign-ups per influencer, not views or likes
- Guest podcast appearances > paid podcast ads at this stage

---

## 11. CURRENT STATE

*Update this section at the end of every meaningful work session.*

### What Exists
- Single HTML5 canvas game — Pengu Fisher prototype (fully playable)
- All core mechanics implemented: jump, double-jump, active fishing cast,
  combo multiplier, frenzy mode, 4 distinct obstacle types
- Mobile-first layout: overlay controls, HUD floating on canvas
- Web Audio sound effects (all actions have sound)
- Haptic feedback (Android Chrome only — iOS blocks Vibration API)
- Daily seed system (client-side only — not server-validated yet)
- Sunset visual theme, cartoon character art

### Known Issues / Not Yet Built
- [ ] Fullscreen button non-functional on mobile — remove it
- [ ] No backend — scores not saved anywhere
- [ ] No user accounts / authentication
- [ ] No server-side seed validation (anti-cheat not active)
- [ ] Service Worker not implemented — no offline support
- [ ] No PWA manifest — not installable
- [ ] Score card image generation for social sharing — not built
- [ ] Web Share API integration — not built
- [ ] Leaderboard UI — not built
- [ ] Weekly attempt tracking — client-side only, not enforced server-side

### Repository Structure (Target)
```
/
├── GAME_BIBLE.md          ← this document
├── CURRENT_STATE.md       ← short current sprint status
├── README.md
├── prototypes/
│   └── penguin-fisher.html   ← working prototype
├── src/
│   ├── game/              ← game engine
│   ├── pwa/               ← manifest, service worker
│   ├── api/               ← Vercel edge functions
│   └── ui/                ← leaderboard, profile, sharing
└── supabase/
    └── schema.sql         ← full database schema
```

### Next Build Priorities (Phase 1)
1. Proper PWA structure (manifest.json + service worker)
2. Supabase backend (auth + score submission + leaderboard)
3. Remove fullscreen button, finalize mobile layout
4. Score card image generation + Web Share API
5. Performance pass for mid-range Android

---

## 12. DECISIONS LOG

*Record every significant decision here with a brief rationale.
Never delete entries — cross them out if reversed and note why.*

| Date | Decision | Rationale |
|------|----------|-----------|
| Mar 2026 | PWA not native app | Zero install friction, viral link sharing, Wordle model |
| Mar 2026 | Vanilla JS + Canvas, no game framework | Performance budget, no unnecessary dependencies |
| Mar 2026 | Supabase + Vercel stack | Free at launch scale, grows to 200k MAU without rearchitecting |
| Mar 2026 | Arctic setting as home base, other settings possible | Ownable visual identity, flexible for game variety |
| Mar 2026 | Character-first IP approach | Games are temporary, characters are forever |
| Mar 2026 | 5 attempts per day hard limit | Healthy gaming philosophy — limits create desire |
| Mar 2026 | Live Sunday event is the product | Differentiates from every other mobile game, creates community |
| Mar 2026 | Free to play always, sponsor-funded prizes | Removes all friction, clean ethics, viable business model |
| Mar 2026 | Primary audience: everyone — intentionally broad | No natural excluder, universal entry point, depth reveals over time |
| Mar 2026 | Core feeling: playful and light, pure fun | Lowest friction emotional hook, works across all four player types |
| Mar 2026 | World/product name: TBD — placeholder until naming session | Name shapes everything downstream, worth doing properly |

---

*End of Game Bible v1.0*
*Next review: after Phase 1 build complete*
