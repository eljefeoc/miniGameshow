---
phase: 02-auth-player-profiles
plan: 01
subsystem: auth
tags: [auth, profiles, schema, leaderboard, forms]
dependency_graph:
  requires: []
  provides: [display_name in profiles, is_18_plus in profiles, inline auth errors, leaderboard display names]
  affects: [prototypes/penguin-game.html, supabase/schema.sql, supabase/migrations]
tech_stack:
  added: []
  patterns: [Supabase signUp options.data, inline error UX, touch-target inputs, CSS focus ring]
key_files:
  created:
    - supabase/migrations/20260403_add_display_name_is_18_plus.sql
  modified:
    - supabase/schema.sql
    - prototypes/penguin-game.html
decisions:
  - "Signup handler passes is_18_plus as the checkbox boolean value — under-18 users are never blocked (AUTH-06 compatible)"
  - "setAuthMode() helper controls signup-only field visibility (display name, age) to avoid cluttering signin UX"
  - "Forgot password button added but hidden (display:none) — enabled in Plan 02"
  - "Password minimum raised from 6 to 8 characters per AUTH-01 requirement"
metrics:
  duration: ~20 minutes
  completed_date: "2026-04-03"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 02 Plan 01: Schema Migration + Extended Signup Form Summary

**One-liner:** Added display_name and is_18_plus columns via migration, extended signup form with display name + age checkbox, replaced all alert() auth errors with inline #auth-status messages, and wired leaderboard to show display names.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Schema migration — add display_name and is_18_plus columns, update trigger | f33fe9a | supabase/migrations/20260403_add_display_name_is_18_plus.sql, supabase/schema.sql |
| 2 | Extend signup form HTML, update JS handlers, fix leaderboard query | 7a7c0dc | prototypes/penguin-game.html |

## What Was Built

### Task 1: Schema Migration

Created `supabase/migrations/20260403_add_display_name_is_18_plus.sql` which:
- Adds `display_name text` column to `public.profiles` with `ADD COLUMN IF NOT EXISTS`
- Adds `is_18_plus boolean NOT NULL DEFAULT false` column to `public.profiles`
- Replaces `handle_new_user()` trigger to read `display_name` and `is_18_plus` from `raw_user_meta_data` instead of `username`

Updated `supabase/schema.sql` canonical schema to match:
- Profiles table now includes `display_name text` and `is_18_plus boolean NOT NULL DEFAULT false`
- `handle_new_user()` function body updated to INSERT display_name and is_18_plus

Migration is ready to apply via Supabase Dashboard SQL Editor (Supabase CLI not linked to remote project).

### Task 2: Extended Signup Form

**HTML changes to `#ov-auth`:**
- Added `auth-display-name` text input (font-size:16px, min-height:44px)
- Added `auth-email` and `auth-pass` inputs styled with 16px font / 44px touch targets
- Added `auth-age-label` + `auth-age-check` checkbox (min-height:44px, display:flex)
- Added `auth-age-sub` sub-copy for under-18 messaging
- Added `auth-forgot-pw` button (hidden by default, enabled in Plan 02)
- Added `aria-live="polite"` to `#auth-status`
- Added `data-auth-mode="signup"` attribute to track form mode

**CSS additions:**
- Focus ring: `outline: 2px solid #534AB7` for auth text/email/password inputs

**JavaScript changes:**
- `let playerIs18Plus = false` module-scope variable added
- `onSignedIn()` now fetches `display_name, is_18_plus, username` from profiles; sets `playerIs18Plus`; resolves `playerName` with `display_name || username || email-prefix` fallback
- Signin listener: replaced `alert(error.message)` with inline `#auth-status` message with loading state (`...`)
- Signup listener: reads displayName and is18Plus from new fields, passes to `signUp({ options: { data: { display_name, is_18_plus } } })`; password minimum raised to 8 chars; inline errors for all cases
- Under-18 users are NOT blocked — `is_18_plus: is18Plus` stores the actual checkbox value
- `setAuthMode(mode)` helper: hides display name + age fields in signin mode, shows in signup mode
- `auth-forgot-pw` click placeholder added (hidden)
- Leaderboard query updated to `.select('rank,best_score,user_id,profiles(display_name,username)')`
- Leaderboard name resolution: `row.profiles?.display_name || row.profiles?.username || 'Player'`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data paths are wired. The forgot password button is intentionally hidden (`display:none`) with a code comment noting it's enabled in Plan 02. This is not a stub that prevents Plan 01's goals from being achieved.

## Self-Check: PASSED

- `supabase/migrations/20260403_add_display_name_is_18_plus.sql` — created and committed (f33fe9a)
- `supabase/schema.sql` — updated and committed (f33fe9a)
- `prototypes/penguin-game.html` — updated and committed (7a7c0dc)
- All acceptance criteria verified via automated grep checks before committing
