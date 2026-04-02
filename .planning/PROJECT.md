# miniGameshow

## What This Is

A mobile-first web game show where players compete in simple, zen-like arcade games for real prizes — no app install, one link, five attempts per day. An operator-controlled event system drives each competition period (hours to weeks); a live Sunday stream crowns the champion. The games star a growing cast of Arctic characters designed as an original IP, with merch potential long-term.

## Core Value

Anyone who sees a link on social media can tap it and be playing within 10 seconds — zero friction from discovery to first play.

## Requirements

### Validated

- ✓ Penguin Fisher game (canvas, seeded RNG, physics, frenzy/combo system) — existing
- ✓ Supabase backend (7 tables: games, profiles, weeks, runs, leaderboard, daily_attempts, content_events) — existing
- ✓ Daily attempt limiting (5 per day_seed, enforced by DB trigger) — existing
- ✓ Score submission and leaderboard tracking — existing
- ✓ User auth via Supabase email/password — existing
- ✓ HUD overlay (countdown, rank, score, attempt dots, avatar, menu) — existing
- ✓ Admin panel for week management (create/edit/delete weeks, scheduling, HUD preview) — existing
- ✓ Vercel deployment config — existing

### Active

- [ ] Phone-first responsive game shell — full-viewport, touch-optimized, no horizontal scroll
- [ ] Event system — configurable duration (hours/days/week), game selection, prize field (optional), cutoff enforcement server-side
- [ ] Test event mode — events with no prize, flagged as internal, excluded from public winner flow
- [ ] Player profile — display name, age verification gate (18+ to compete for prizes)
- [ ] Under-18 practice mode — full gameplay, own leaderboard, cannot win prizes
- [ ] Admin event controls — create/start/end events, manual "new week live" trigger post-show, auto-publish fallback
- [ ] Winner identification — #1 score at event cutoff surfaced clearly in admin
- [ ] Score card / share mechanic — shareable result card to drive social discovery
- [ ] PWA fundamentals — manifest, icon, home screen installable, no-install-required play
- [ ] Game 02 (Fish Stack) — Supabase integration, event system integration, Babs character
- [ ] Game 03 baseline — third game with backend integration
- [ ] Geo/age restriction framework — structure for local legal compliance (not full legal impl v1)

### Out of Scope

- Multiple simultaneous events — v1 runs one event at a time; multi-event (corporate, etc.) is a future milestone
- In-app prize claiming flow — winner identified in admin, operator contacts winner directly
- Merch store — IP and characters established now, commerce later
- Games 04–10+ — designed and documented in GAME_BIBLE, built after v1 ships
- Full legal compliance implementation — framework built, legal review before public launch
- Payment / purchase flows — free to play always; no monetization in product

## Context

**Existing codebase:** Functional prototype at `prototypes/penguin-game.html` — single-file architecture (3,094 lines), no build pipeline for game logic, Supabase JS loaded from CDN. Admin panel exists at `prototypes/admin.html`. The prototype proves the core loop works; v1 is about making it production-ready and wrapping it in the full game show experience.

**The Sunday show:** The live stream crowning the weekly champion is the product's core marketing moment. Every feature should serve the "one link → play → watch Sunday show → share" loop.

**Character IP:** The Penguin (player character) and Babs the Walrus are designed as original IP with world-building intent. Names TBD pending proper design session. Character design consistency matters now — it compounds.

**Tone:** Pixar warmth in an Arctic world. Playful and light. Makes you smile within 5 seconds. Never stressful, never pay-to-win, never dark.

**Game design constraint:** Games must be instantly legible with zero onboarding. If a first-time player can't figure it out in 10 seconds by looking at it, it's too complicated.

## Constraints

- **Tech Stack**: Vanilla JS + Supabase + Vercel — no framework migration in v1; build on what exists
- **Performance**: Must load and be playable in under 3 seconds on a mid-range phone on LTE
- **No Install**: PWA-style but playable without any install step; native app is out of scope
- **No Payment**: Zero monetization, no purchase flows, ever — legal/trust constraint
- **Age Gating**: Players must verify 18+ to compete for prizes; under-18 can play in practice mode
- **Phone First**: Design starts at 375px width; desktop is a nice-to-have, not the primary target

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Stay vanilla JS (no framework) | Prototype works, no build step = instant deploy, lower complexity | — Pending |
| Supabase for all persistence | Already integrated, handles auth + RLS + triggers, no backend server needed | ✓ Good |
| One event at a time (v1) | Avoid multi-tenancy complexity; validate core loop first | — Pending |
| Manual prize contact (v1) | Claiming flow is complex UX; operator knows their winners; automate later | — Pending |
| Prize field optional | Enables no-prize test events during beta without feature flags or code changes | — Pending |
| 5 attempts/day limit | Anti-addiction design feature, not a restriction — from GAME_BIBLE | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-02 after initialization*
