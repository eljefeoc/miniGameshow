# GAME BIBLE

### [WORLD NAME — TBD] — Working Title

*Last updated: March 29, 2026 | Version 1.6*

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
Monday       — New game drops (after Sunday show). Link live. Social posts go out.
Tue–Saturday — Players get 5 attempts per day. Leaderboard updates live.
Saturday     — HUD countdown turns red. Scoring closes at 23:59:59 player's LOCAL time.
Sunday       — Scoring closed. Top scores reviewed. LIVE EVENT crowns champion.
               New game goes live immediately after show ends.
               Fallback: new game auto-publishes at 20:00 Pacific if not manually triggered.
```

**The live Sunday event is the product.**
The game is the vehicle. The weekly live stream — host, replay of winning run,
champion on camera, prize handoff — is the moment that makes this a show,
not just an app. Every technical and design decision should serve this loop.

**Weekly schedule (all times US Pacific):**

- Scoring deadline: Saturday 23:59:59 player's local time (enforced server-side)
- Live show: Sunday, time TBD (shown in HUD as e.g. "Live show Sun 7pm PT")
- New week publish: manual trigger by host immediately post-show
- Fallback auto-publish: Sunday 20:00 Pacific if manual trigger not fired

**HUD time display states:**

- Mon–Fri: `Scoring closes Sat midnight · Live show Sun 7pm PT`
- Saturday: live red countdown `3h 42m left · Live show tomorrow 7pm PT`
- Sunday pre-show: `Scoring closed · Live show today at 7pm PT`
- Sunday post-show / new week live: resets to new week's game and prize

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

---

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

**Visual implementation (Game 01 — Pengu Fisher, prototype):**

- **Sprite sheet primary:** `prototypes/assets/pengu-sheet.png` (transparent PNG,
  Midjourney-generated poses). Single file load; `drawImage` crop rectangles per
  mood (`happy`, `scared`, `excited`, `nervous`, backpack pose). Tuned crops and
  feet alignment so the character sits on the ice (not floating).
- **Procedural fallback:** If the sheet is not ready or `USE_PENGU_SPRITE` is off,
  vector drawing remains — bluish/cream palette, softer wing blobs, cheek blush,
  two-eye layout (normal / scared X / excited stars), updated beak and feet.
- **Fish backpack:** Persistent bag behind the body; tiny fish appear inside as
  catches stack; strap drawn over the sprite for continuity.

---

### The Walrus — Working name: Babs

**Role:** The elder shopkeeper of the world. Grumpy on the surface, secretly
supportive. Runs the ice trading post, knows everyone's business, has strong
opinions about everything — especially how fish should be stacked.

**Personality:** Permanently furrowed brows. Heavy sigher. Delivers withering
one-liners without breaking eye contact. Reluctantly gives credit when it's
due — but only after a beat, and never warmly. Babs has been at this trading
post since before anyone can remember and considers that to be everyone else's
problem.

**The irreverence is the brand asset.** Babs' voice — dry, grumpy, occasionally
shocked into genuine awe — is what separates this world from generic Arctic
games. Every line she delivers should feel like it came from a specific
character with a specific history, not a generic NPC reaction.

**In-game behavior (Game #1 — Pengu Fisher):**
Breathes (hitbox expands and contracts), giving skilled players a window to
slip past. The breathing is also a personality trait — she sighs heavily
and constantly.

**In-game behavior (Game #2 — Fish Stack):**
Babs is the shopkeeper evaluating your stack in real time. She reacts live
to every row you clear (or fail to clear), with 5 distinct emotional states:

- **Idle** — slow breathing sigh, flat mouth, permanently furrowed brows,
  pupils watching the stack. Occasional unprompted commentary.
- **Happy** — wide eyes, small smile, flippers raise slightly.
  Triggered by clearing 1–2 rows. Reluctant approval.
- **Shocked/Elated** — wide eyes, open mouth, gold speech bubble.
  Triggered by clearing 3–4 rows at once. Genuine awe, which she
  immediately tries to walk back.
- **Angry** — squinted eyes, red brows, frown, body shakes.
  Triggered by sloppy stacking with visible gaps.
- **Game over** — X eyes, frown, locked expression.
  Babs has seen enough. The trading post is closed.

**Babs' voice lines (implemented — Game #2):**

*Idle:*
- "Hmph. Don't waste my shelf space."
- "Stack it right or don't stack it at all."
- "I've been here since the last thaw. Hurry up."
- "*sighs heavily*"
- "Every fish has a place. Know it."
- "Gaps mean lost coin. Remember that."

*On clearing 1 row:*
- "...Not terrible."
- "I suppose that'll do."
- "Fine. You can stay."
- "Keep going. Don't get cocky."
- "Hmm. Maybe you DO know fish."

*On clearing 2 rows:*
- "Good stack."
- "Two rows! Efficient."
- "Keep it up."
- "Maybe you DO know fish."

*On clearing 3 rows:*
- "THREE ROWS?!"
- "Oh. That's... good."
- "Impressive haul."
- "Now THAT'S how you stack!"

*On clearing 4 rows:*
- "FOUR ROWS! UNBELIEVABLE."
- "I've never… wow."
- "THE SHELVES ARE FULL."
- "My trading post has never looked so good!!"

*On sloppy stacking (gaps detected):*
- "Ugh. Gaps. I hate gaps."
- "That gap is going to haunt you."
- "A sloppy stack is a sloppy profit."
- "I've seen seals stack better."
- "Fill the gaps. FILL THEM."

*Game over:*
- "I KNEW you'd stack it wrong."
- "Unsurprising. Deeply unsurprising."
- "Come back when you're serious."
- "The trading post is closed. Indefinitely."
- "Not even close to my standards."

**Design rules:**
Large, round, purple-tinted. Tusks are prominent. The eyes convey reluctant
wisdom — pupils always tracking slightly downward, watching your stack.
She should look like she's been here forever and has strong feelings
about it.

**Voiceover — planned milestone (see Section 13).**

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

**In-game presence (Game 01 — Pengu Fisher):** Not an obstacle — a reward
signal. Seeing the narwhal means something good is about to happen.

**In-game presence (Game 03 — Deep Dive):** The Narwhal is the soul of the
deep world. Appears occasionally below 60m depth, gliding across the screen
with its glowing horn lighting the darkness briefly. Its passage gifts a small
breath refill. It does not speak. It does not help. It simply watches —
and the player feels, briefly, that they are being tolerated in someone
else's world.

**Design rules:** Deep ocean blues and purples. The horn glows with teal
bioluminescence. Should feel slightly otherworldly compared to surface
characters — slower, more deliberate, ancient. Never threatening.

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
- Walrus (Babs) — breathes (hitbox expands/contracts), slip-under window
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

**Status:** Prototype complete. **Score save path live:** Supabase email auth +
client insert into `public.runs`; daily attempt cap enforced in Postgres
(`before_run_insert` on `runs` + `daily_attempts`). Still needs: daily seed
**server-side validation** in gameplay, optional Edge Function for submits,
PWA shell, performance pass for mid-range Android.

**Shell UX (Game 01, implemented):** Dark **HUD** (Zone 1) — prize/show-time
line, attempt dots, best/rank when signed in, **menu** button, **avatar**
(guest `?` or initials). **Avatar tap:** guest → sign-in flow; signed in →
sign out (confirm). **Menu** opens a full-screen **shell** with tabs:
**Leaderboard** (this week), **My scores** (signed-in runs), **Account**
(guest: Sign in → title + auth; signed in: email + Sign out), **Share link**
(Web Share API or clipboard). **Zone 2** title card: first-play expandables
(how to play / how attempts work), **auth block inside overlay** (not a
separate page), **Play now**, **Sign in to save your score** (guests).
**Zone 3** post-run: **Sign in** button when `playMode === guest`; competing
copy shows attempt x/5 or free-play messaging. If Supabase URL/anon key are
missing, status text explains local vs hosted setup and **Sign in / Create
account** are disabled (handlers are not wired without a client).

---

### Game 02: FISH STACK (Prototype Complete)

**Premise:** Stack fish on the shelves of Babs' Arctic Trading Post.
Babs watches your every move and has feelings about it.

**Core mechanic:** Falling-piece stacking — guide fish-shaped pieces
into complete rows to clear them.

**What makes it NOT generic Tetris:**
Pieces are fish silhouettes (salmon, eel, pufferfish, herring, tuna,
cod, mackerel) — each with unique shapes, fins, tails, and eyes.
Babs the Walrus reacts live to your stack with 5 emotional states
and 30+ voiced lines. The game is mechanically familiar but
the world makes it entirely proprietary.

**Piece roster (7 fish):**

- Salmon — chunky S-shape, dorsal fin, forked tail
- Eel — long I-shape (1×4), sinuous wave stripe
- Pufferfish — plus/T-shape, outward spines
- Herring — slim L-shape, scale stripe
- Tuna — reverse-L, powerful build
- Cod — S/Z-shape, classic fish silhouette
- Mackerel — Z-shape, racing stripe

**Scoring:**

- 1 row cleared: 100 pts × level
- 2 rows: 300 pts × level
- 3 rows: 500 pts × level
- 4 rows: 800 pts × level
- Hard drop bonus: +2 pts per cell dropped

**Difficulty ramp:** Speed increases every 8 rows cleared.
Level 1: 800ms drop interval. Max speed: 80ms (level ~11).

**Babs' role:** Persistent shopkeeper in the UI panel above the board.
Animated — breathing, blinking, emotionally reactive. She watches
the board (pupils track downward). Full emotional state system
documented in Section 6.

**Status:** Prototype complete. Known issues: piece physics feel slightly
loose (acceptable for now). Needs: daily seed, score submission,
voiceover integration when audio pipeline is ready (see Section 13).
---

### Game 03: DEEP DIVE (Prototype Complete)

**Premise:** The penguin dives through the ice into the Narwhal's bioluminescent
world below. A place no penguin has been. Wondrous, strange, and unforgiving.

**Core mechanic:** Free-swimming exploration — analog joystick moves the penguin
in all directions through a vertically scrolling deep ocean. Surface before
your breath runs out.

**The tension:** Go deeper for more pearls and a higher score. But breath drains
faster at depth. Getting back to the surface takes time. Every extra metre down
is a calculated risk.

**Hazards:**

- **Jellyfish** — pulsing bioluminescent bells with trailing tentacles. Drift
  slowly across your path in unpredictable patterns. Contact drains breath fast
  and knocks you back.
- **Currents** — invisible water forces that push you sideways and downward,
  hinted at by subtle flowing lines. Stronger versions appear deeper.
- **Darkness** — visibility closes in as a radial vignette as you descend and
  as breath drops. At critical depth+low breath, the world nearly disappears.

**Collectibles:**

- **Pearls** — regular (white glow, 10 pts) and rare gold (50 pts). Collecting
  any restores a small amount of breath. Scattered throughout the dive.
- **Air bubbles** — glowing teal orbs marked with a + icon. Collecting one
  restores roughly a third of your breath. Your main lifeline at depth.

**The Narwhal** — appears occasionally below 60m depth, gliding through with
its glowing horn briefly lighting the path. Its passage gifts a small breath
refill. You are a guest in its world.

**Scoring:**

- Pearls: 10 pts each (regular), 50 pts (rare/gold)
- Hard drop: +2 pts per cell
- Depth bonus: final score shows both pearls collected and max depth reached

**Ending states:**

- **Surfaced** — you chose to come up in time. Narwhal judges your depth.
  Under 20m: "The surface called you back too soon."
  20–40m: "You went deep. Not deep enough."
  Over 40m: "The narwhal approves."
- **Out of air** — breath hit zero. "The deep is unforgiving. The narwhal watches."

**Controls:** Circular analog joystick (left thumb) + SURFACE button (right thumb).
The joystick nub physically tracks thumb position and provides analog speed
scaling — gentle push = slow drift, full deflection = fast swim. Keyboard
arrows work on desktop.

**Visual identity:** Near-black bioluminescent ocean. Everything glows from
within. The penguin wears dive goggles and emits a warm amber light —
the only warmth in a cold alien world. Darkness closes in from the edges
as a radial vignette centered on the penguin.

**Status:** Prototype complete. Needs: daily seed, score submission,
jellyfish pattern variety, narwhal encounter polish.

### Future Games (Concepts — Not Yet Built)

**Arctic Core Series** — characters and setting established, ready to build:

- **Iceberg Surfer** — ride a shrinking iceberg, jump between floes before yours melts
- **Snowball Dodge** — arena survival, incoming snowballs from all sides, patterns get complex
- **Penguin Golf** — one-button power/angle golf on wild Arctic courses
- **Blizzard Run** — screen gradually whiteouts, navigate entirely from memory
- **Hungry Orca** — don't get eaten, collect fish, orca learns your patterns over time
- **Arctic Curling** — flick physics, land closest to center, wind and ice friction vary
- **Penguin Slingshot** — launch yourself between icebergs, collect fish mid-air
- **Freeze! Thaw!** — move when polar bear looks away, freeze when it turns around

**Extended Concepts** — mechanics-first, world can be applied:

- **Rhythm Waddle** — tap in time to a beat, combo multiplier for streaks, tempo increases
- **Snowball Launcher** — Angry Birds style trajectory, knock down seal towers
- **Harpoon Toss** — moving targets at varying distances, wind affects throw arc
- **Tide Timer** — cross a beach in the gaps between waves, timing windows shrink
- **Which Way Waddle** — Simon-says directional memory, pattern length grows
- **Catch the Snowflake** — match the falling pattern, avoid wrong ones, speed increases
- **Crab Claw** — claw machine timing game, grab prizes from a tank, tension builds

**Total pipeline: 15 games beyond current prototypes.**
At one new game per week that's 3.5+ months of content without repeating.
Rotate by mechanic type — never two memory games back to back,
never two survival games in a row.

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
Frontend:       PWA with Service Worker for offline (SW not shipped yet)
Hosting:        Vercel — static output from prototypes/; / → penguin-game.html
Backend/DB:     Supabase (Postgres + Auth + Realtime subscriptions)
API:            Vercel Edge Functions (planned; Game 01 uses direct client insert)
Storage:        Cloudflare R2 (video replays, score card images, audio assets)
Social Sharing: Web Share API (post-run + shell) + Canvas score cards (planned)
Audio:          Web Audio API (sfx) + HTML5 Audio (voiceover — see Section 13)
```

**Vercel + Supabase keys (Game 01):** `npm run build` runs
`scripts/vercel-write-supabase-config.mjs`, which writes
`prototypes/supabase-config.js` from **`SUPABASE_URL`** and
**`SUPABASE_ANON_KEY`** (gitignored; never commit secrets). Local dev: copy
`prototypes/supabase-config.example.js` → `supabase-config.js` and paste keys.
See **`VERCEL.md`** and repo **`vercel.json`**.

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
Run ends → Score card generated (Canvas → PNG)   ← planned; not in prototype yet
         → Web Share API opens native share sheet
         → Pre-populated: image + score + URL + weekly context
```

**Prototype today (Game 01):** post-run and shell use **Web Share API** where
available (fallback: copy URL). **Canvas score card image** not yet generated.

```
URL carries state: domain.com/play?week=22&score=8420&challenge=jake
                   → Friend sees Jake's score before playing
                   → Immediate competitive context
                   → No account needed to play
```

### Sign-up Flow (Frictionless)

**Product intent (unchanged):** play first, verify second — never block the
first run with account creation.

**Current prototype (Game 01):**

1. Land on game — **guest** can **Play now** immediately (random seed; no saves).
2. **Email + password** auth lives **inside the title overlay** (Supabase
   Auth). Profile **username** is read from `profiles` after sign-in for HUD
   copy; display falls back to email prefix.
3. **Sign-in entry points:** title **Sign in to save your score**; **Zone 3**
   post-run **Sign in** (guests); shell **Account** tab **Sign in** (jumps to
   title + auth); **HUD avatar** (guest while playing → Account tab with
   instructions; otherwise → title + auth). **Sign out:** title user bar,
   Account tab, or avatar (confirm).
4. **Phone verify after first real run** — not implemented in prototype;
   required later for prize eligibility.

If `url` / `anon key` are empty, the UI explains **local file** vs **hosted env**
setup and disables auth buttons until configured.

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

- **Game 01 — Pengu Fisher:** Fully playable HTML5 prototype (see **Section 7,
  Game 01** for full mechanic list + **shell UX** summary)
  - **`penguin-game.html`** — canvas game + overlay Zones 2–3 + shell markup
  - **`hud.js` / `hud.css`** — Zone 1 gameshow strip, menu, avatar, stats dots
  - All core mechanics: jump, double-jump, active fishing cast,
    combo multiplier, frenzy mode, 4 distinct obstacle types
  - Mobile-first layout, Web Audio sfx, haptic feedback (Android)
  - **Daily seed** for competition runs; **guest and free-play** use a **new
    random seed every run** so the official daily layout cannot be rehearsed
    offline on a shared device
  - **Play modes (client + DB):**
    - **Guest** — not signed in; random seed each run; scores not saved; overlay
      prompts sign-in to compete
    - **Competing** — signed in, under daily attempt cap; **daily seed**; scores
      submitted to `public.runs`; overlay shows **display name** (profile username
      or email prefix) and **attempt x/5**; **PLAY AGAIN** when attempts remain
    - **Free play** — signed in after **5 attempts used for the day**; random seed
      each run; scores not saved; **FREE PLAY** button; copy states scores are not
      saved
  - Attempt counts are **re-fetched from `daily_attempts`** after each successful
    save so the UI matches server state (not a fragile local-only counter).
    **Gap:** starting a new run does not always re-query the DB first — another
    signed-in device can advance the count while this tab still shows stale x/5
    until the next refresh (server trigger still blocks a 6th insert for the same
    `user_id` + `day_seed`).
  - **Supabase email auth** + **score insert** to `public.runs` in
    `penguin-game.html` when `prototypes/supabase-config.js` is configured — see
    `README.md` steps 2–3, **`VERCEL.md`** for deploy, **`supabase-config.example.js`**
    for local template (requires active `weeks` row, e.g. `seed_week.sql`)
  - **Vercel:** root **`vercel.json`**, **`package.json`** `build` → generated
    `supabase-config.js`; production **/** serves **`penguin-game.html`**

- **Game 02 — Fish Stack:** Fully playable HTML5 prototype
  - 7 fish-shaped falling pieces (not tetrominos — actual silhouettes)
  - Ghost piece, hard drop, wall kicks, level speed scaling
  - Babs the Walrus: animated shopkeeper with 5 emotional states,
    30+ reactive voice lines, live reaction to every row cleared
  - Voiceover architecture ready (single setBabs() call point)

- **Game 03 — Deep Dive:** Fully playable HTML5 prototype
  - Free-swimming vertical scroller, analog joystick controls
  - Bioluminescent visual world: jellyfish, pearls, air bubbles, darkness vignette
  - Narwhal appears as rare deep encounter, gifts breath on passage
  - Dual collectible system: pearls (score) + air bubbles (survival)
  - Three jellyfish types with drift patterns
  - Darkness/visibility system tied to depth and breath level

### Known Issues / Not Yet Built

- [x] **Supabase schema built** — `supabase/schema.sql` + migrations; applied pattern documented in `README.md`
- [x] **Auth + score path (Game 01)** — email auth + insert into `public.runs`; daily attempt cap enforced server-side (`daily_attempts` + triggers)
- [ ] **Score submission via Edge Function** — prototype uses direct client insert; production may move to a server endpoint for validation and keys
- [ ] **Re-fetch `daily_attempts` before each competing run start** — reduces stale x/5 across devices/tabs (DB cap still enforced on insert)
- [ ] No server-side **seed validation** in gameplay (anti-cheat not active; client still drives RNG)
- [ ] Service Worker not implemented — no offline support
- [ ] No PWA manifest — not installable
- [ ] Score card image generation for social sharing — not built
- [ ] Web Share API — **partial** (post-run share + shell “Share link”; not full score-card image flow)
- [ ] Standalone marketing / embeddable **leaderboard page** — not built (in-game shell leaderboard exists)
- [ ] Fish Stack piece physics feel slightly loose (acceptable for now)
- [ ] Fullscreen button non-functional on mobile — remove it (Game 01)
- [ ] Deep Dive jellyfish patterns need more variety
- [ ] Deep Dive narwhal encounter needs more polish
- [ ] Deep Dive needs daily seed integration

### Repository Structure (Actual, as of v1.6)

```
/
├── GAME_BIBLE.md
├── README.md
├── VERCEL.md                 ← deploy env vars + Supabase Auth URL config
├── vercel.json               ← build, outputDirectory prototypes/, / rewrite
├── package.json              ← npm run build → write supabase-config.js
├── scripts/
│   └── vercel-write-supabase-config.mjs
├── prototypes/
│   ├── penguin-game.html     ← Game 01 Pengu Fisher (working prototype)
│   ├── hud.js                ← Zone 1 gameshow HUD
│   ├── hud.css
│   ├── supabase-config.example.js   ← copy → supabase-config.js (local)
│   ├── supabase-config.js    ← gitignored; generated on Vercel from env
│   ├── fish-stack.html       ← Game 02 Fish Stack (working prototype)
│   ├── deep-dive.html        ← Game 03 Deep Dive (working prototype)
│   └── assets/
│       └── pengu-sheet.png   ← transparent sprite sheet (Midjourney, 500×500)
└── supabase/
    ├── schema.sql            ← full DB schema (reference / SQL Editor)
    ├── config.toml           ← Supabase CLI (local dev / link)
    ├── seed_week.sql         ← example active week + game linkage
    ├── pre_flight_check.sql
    └── migrations/           ← apply in order (includes RLS delete-own, week admin,
        runs delete sync, admin RPC lifecycle, drop destructive admin_clear RPC)
```

*Target structure (src/, audio/, pwa/ dirs) to be created when prototype is promoted to production build.*

**Note:** Migration **`20260329230000_drop_admin_clear_all_my_competition_data`**
removes the **`admin_clear_all_my_competition_data`** RPC and related policy;
stress-test admin UI was removed — use normal Table Editor / SQL for data fixes.

### Next Build Priorities (Phase 1)

1. ~~Create Supabase project + apply schema~~ — **done for Game 01 path**; keep migrations in sync for new environments
2. ~~Wire Supabase Auth + prototype score insert~~ — **done** (`README.md` steps 2–3)
3. ~~In-game shell: leaderboard + my scores + account + share~~ — **done** (Game 01); optional **standalone leaderboard** page still open
4. **Refetch attempts (or RPC) before competing run start** — align UI across devices with `daily_attempts`
5. Optional: **Edge Function** (or server route) for score submission + validation instead of client-only insert
6. Remove fullscreen button, finalize mobile layout (Game 01)
7. Proper PWA structure (manifest.json + service worker)
8. Score card image generation + fuller Web Share flow
9. Performance pass for mid-range Android

---

## 12. DECISIONS LOG

*Record every significant decision here with a brief rationale.
Never delete entries — cross them out if reversed and note why.*

| Date     | Decision                                              | Rationale                                                           |
|----------|-------------------------------------------------------|---------------------------------------------------------------------|
| Mar 2026 | PWA not native app                                    | Zero install friction, viral link sharing, Wordle model             |
| Mar 2026 | Vanilla JS + Canvas, no game framework                | Performance budget, no unnecessary dependencies                     |
| Mar 2026 | Supabase + Vercel stack                               | Free at launch scale, grows to 200k MAU without rearchitecting      |
| Mar 2026 | Arctic setting as home base, other settings possible  | Ownable visual identity, flexible for game variety                  |
| Mar 2026 | Character-first IP approach                           | Games are temporary, characters are forever                         |
| Mar 2026 | 5 attempts per day hard limit                         | Healthy gaming philosophy — limits create desire                    |
| Mar 2026 | Live Sunday event is the product                      | Differentiates from every other mobile game, creates community      |
| Mar 2026 | Free to play always, sponsor-funded prizes            | Removes all friction, clean ethics, viable business model           |
| Mar 2026 | Primary audience: everyone — intentionally broad      | No natural excluder, universal entry point, depth reveals over time |
| Mar 2026 | Core feeling: playful and light, pure fun             | Lowest friction emotional hook, works across all four player types  |
| Mar 2026 | World/product name: TBD                               | Name shapes everything downstream, worth doing properly             |
| Mar 2026 | Walrus working name: Babs                             | Strong character voice established in Game 02 prototype             |
| Mar 2026 | Fish Stack uses fish silhouettes not tetrominos       | Breaks generic Tetris association, proprietary feel                 |
| Mar 2026 | Babs reacts live to stack with 5 emotional states     | Character presence > passive backdrop; irreverence is brand asset   |
| Mar 2026 | Voiceover deferred to Phase 2                         | Architecture ready (setBabs() call point); recording needs casting  |
| Mar 2026 | Narwhal fronts Game 03 as world-reveal moment          | It appears as reward signal in Games 01/02 — starring it pays off   |
| Mar 2026 | Deep Dive: analog joystick not D-pad                  | Swimming game needs fluid directional input, not discrete buttons   |
| Mar 2026 | Deep Dive: air bubbles as breath collectible           | Gives player agency over survival, rewards exploration over dive depth |
| Mar 2026 | Supabase schema built before frontend auth             | Schema is the contract — build it first so frontend/API stay aligned |
| Mar 2026 | `runs.seed` consolidated to `runs.day_seed`            | Single column for date-derived PRNG seed; `weeks.seed` separate      |
| Mar 2026 | Pengu sprite: single transparent PNG sheet + crop rects | One network request, fast first-frame, falls back to procedural      |
| Mar 2026 | Midjourney for initial character reference art         | Fast, quality style exploration before committing to character designer |
| Mar 2026 | Fish backpack added to pengu as persistent visual prop | Reinforces fishing identity, gives visible reward feedback per catch  |
| Mar 2026 | Sprite and procedural draw coexist behind `USE_PENGU_SPRITE` flag | Toggle during iteration; remove flag once sprite is final  |
| Mar 2026 | Pengu Fisher graphics pass: palette + eyes + backpack + sprite crops | Midjourney sheet + tuned `drawImage` rects + on-ice alignment; procedural fallback stays in sync |
| Mar 2026 | Three play modes: guest / competing / free play | Guest & free play = random seed every run; competing = daily seed + saves; stops pass-the-phone practice of the official seed |
| Mar 2026 | Attempt UI from DB after each successful `runs` insert | `daily_attempts` is source of truth; overlay shows name + x/5 and PLAY AGAIN vs FREE PLAY |
| Mar 2026 | Scoring closes Saturday 23:59:59 player's local time | Hard local deadline players can reason about; cleaner than a single global cutoff |
| Mar 2026 | Sunday is celebration only — no scoring | Removes Sunday pressure; live show is pure drama not a last-chance scramble |
| Mar 2026 | New week: manual trigger post-show, fallback 20:00 PT | Host controls the moment; fallback prevents game going stale if show runs long |
| Mar 2026 | Live show timezone: US Pacific, shown as PT in HUD | Single source of truth for show time; players in other zones see PT and convert |
| Mar 2026 | Unified game shell: dark HUD bar (Zone 1), dark post-run (Zone 3), light overlay (Zone 2) | Consistent broadcast identity across all games; overlay flips light as "calm data" contrast |
| Mar 2026 | HUD prize section: "Prize:" label + name always prominent | Prize is the main hook — largest element in HUD, always visible |
| Mar 2026 | HUD time line: three states (normal / Saturday urgency / Sunday closed) | Each state has distinct copy and color (amber → red → muted) to signal urgency naturally |
| Mar 2026 | Game 01: auth inside title overlay; guest post-run + Account + avatar sign-in paths | One URL, no separate login page; avatar doubles as quick sign-in / sign-out |
| Mar 2026 | Vercel build writes `prototypes/supabase-config.js` from env | Same HTML locally and in prod without committing keys; documented in `VERCEL.md` |
| Mar 2026 | Remove `admin_clear_all_my_competition_data` RPC + stress admin UI | Destructive helper was dev-only; dropped via migration; RLS delete-own remains for user-owned rows |

---

## 13. VOICEOVER PLAN — BABS (Phase 2 Milestone)

*Added March 2026. Do not build until Phase 1 backend is complete.*

### Why This Matters

Babs' written lines already land. A distinctive voice performance will
make her one of the most memorable characters in casual mobile gaming.
The irreverence, the grumpiness, the reluctant awe — these are
direction-ready. The voice actor should feel like they're playing a
character who has been at this trading post for 40 years and has
strong opinions about fish.

### Technical Architecture (Already Ready)

All Babs lines run through a single function: `setBabs(state, eye, mouth, text)`.
Adding audio requires one change: trigger a sound file from that function.

```javascript
// Current (text only)
function setBabs(state, eye, mouth, text, duration) { ... }

// Phase 2 addition — one line inside setBabs():
playVO(text); // maps text string to audio file, plays via HTML5 Audio
```

Audio files live in Cloudflare R2 (`/audio/babs/`), referenced by line ID.
Fallback to text-only if audio fails or user has sound off.

### Recording Scope

**Priority 1 — Game 02 (Fish Stack):** 30 lines across 6 emotional states.
This is the recording session to do first — Babs has the richest
reactive dialogue here.

**Priority 2 — Game 01 (Pengu Fisher):** Ambient commentary lines for
when Babs appears as an obstacle. Optional grunts/sighs as the
hitbox expands.

**Priority 3 — Global UI lines:** "Welcome back." / "Five attempts.
Don't waste them." / "Your score has been submitted. Hmph."

### Casting Direction

- Gender: open — the character reads as a weary, weathered elder
- Age feel: 55–70, not played for laughs, played for real
- Tone: dry, deliberate, zero warmth in the delivery — but the humor
  comes from how specific and committed she is, not from winking
- Reference feel: Maggie Smith in Downton Abbey crossed with
  a very tired fishmonger who has seen things
- Key test line for auditions: *"I KNEW you'd stack it wrong."*
  Should land like a verdict, not a punchline.

### Decisions to Make Before Recording

- Full sentences voiced vs. grunts/reactions only for obstacle appearances?
- Should Babs ever say the player's username? (Requires dynamic TTS
  or pre-recorded wildcard handling)
- Same voice actor across all character VO eventually,
  or Babs-specific casting?

### Budget Estimate

- 30–40 lines, directed session: $400–$800 (indie VO rate)
- Self-directed remote auditions via Voices.com or similar: $200–$400
- Post-processing (light compression, EQ for Arctic warmth): in-house

---

*End of Game Bible v1.5*
*Next review: after shell HUD + post-run screen implementation in Pengu Fisher*
