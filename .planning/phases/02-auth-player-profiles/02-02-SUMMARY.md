---
phase: 02-auth-player-profiles
plan: 02
subsystem: auth
tags: [auth, forgot-password, password-recovery, account-tab, avatar, age-badge]
dependency_graph:
  requires: [02-01]
  provides: [forgot-password flow, PASSWORD_RECOVERY handler, account tab identity block]
  affects: [prototypes/penguin-game.html]
tech_stack:
  added: []
  patterns: [Supabase resetPasswordForEmail, Supabase updateUser, PASSWORD_RECOVERY event, event delegation for dynamic buttons]
key_files:
  created: []
  modified:
    - prototypes/penguin-game.html
decisions:
  - "Auth button listeners refactored to event delegation on #ov-auth — allows buttons replaced via innerHTML to work without re-attaching listeners"
  - "restoreAuthForm() rebuilds .fp-auth-row innerHTML and calls setAuthMode() to unify all form-restore paths"
  - "showPasswordResetForm() defined at module scope so onAuthStateChange PASSWORD_RECOVERY handler can call it before bootSupabaseAuth completes"
  - "Forgot password button shown in signin mode, hidden in signup mode via setAuthMode()"
metrics:
  duration: ~15 minutes
  completed_date: "2026-04-03"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 1
---

# Phase 02 Plan 02: Forgot Password Flow + Account Tab Overhaul Summary

**One-liner:** Wired forgot-password flow (resetPasswordForEmail, PASSWORD_RECOVERY handler, in-place new-password form) and replaced the Account tab with an identity block showing avatar initial, display name, age tier badge, email, and sign out button matching the UI-SPEC color contracts.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Forgot password flow — send reset email + PASSWORD_RECOVERY handler + new password form | a2eb92c | prototypes/penguin-game.html |
| 2 | Overhaul Account tab — display name, avatar, age tier badge, sign out | e5f3613 | prototypes/penguin-game.html |

## What Was Built

### Task 1: Forgot Password Flow

**onAuthStateChange update:**
- Changed `async (_e, session)` to `async (event, session)`
- Added `if(event === 'PASSWORD_RECOVERY'){ showPasswordResetForm(); return; }` BEFORE the `session?.user` check
- `return` prevents fall-through to `onSignedIn`

**showPasswordResetForm() — module scope function:**
- Makes `#ov-auth` visible and sets `data-fp-open="1"`
- Hides email, display name, age label/sub, forgot-pw button
- Shows password field with "New password (8+ characters)" placeholder and `autocomplete="new-password"`
- Sets `#auth-status` to "Set your new password below." in green
- Replaces `.fp-auth-row` with `#auth-set-new-pw` "Save new password" button
- Ensures `#overlay` is visible

**Event delegation refactor:**
- Removed 3 separate direct event listeners (`auth-signin`, `auth-signup`, `auth-forgot-pw` click handlers)
- Single `click` listener on `#ov-auth` dispatches by `e.target.id`
- Handles: `auth-signin`, `auth-signup`, `auth-forgot-pw`, `auth-send-reset`, `auth-back-signin`, `auth-set-new-pw`
- Buttons replaced via `innerHTML` continue to work without re-attaching listeners

**Forgot password UI flow:**
- `auth-forgot-pw` click: hides password/display-name/age/forgot button; changes email placeholder to "Your account email"; replaces `.fp-auth-row` with `#auth-send-reset` + `#auth-back-signin`
- `auth-send-reset` click: validates email, calls `sb.auth.resetPasswordForEmail(email)`, shows "Reset link sent — check your email." on success; hides row + email field
- `auth-back-signin` click: calls `restoreAuthForm('signin')`
- `auth-set-new-pw` click: validates 8+ chars, calls `sb.auth.updateUser({ password })`, shows "Password updated! You are signed in.", restores form after 2 second delay

**restoreAuthForm(mode) helper:**
- Restores email display/placeholder
- Clears password value, restores placeholder/autocomplete
- Clears `#auth-status`
- Rebuilds `.fp-auth-row` with original `auth-signin` + `auth-signup` buttons
- Calls `setAuthMode(mode)` to apply proper field visibility

**setAuthMode() updated:**
- Now also shows/hides `#auth-forgot-pw`: visible in signin mode, hidden in signup mode
- Removes Plan 01's `forgotBtn.style.display = 'none'` placeholder

### Task 2: Account Tab Overhaul

Replaced `refreshGspAccount()` with full identity block:

**Signed-in state:**
- Avatar circle: 34px, `background:#534AB7`, initial letter, `color:#CECBF6`, 11px 500 weight
- Display name row: 13px 500 weight `#1a1a1a` + age tier badge inline
- 18+ badge: `background:#FAEEDA`, `color:#633806`, text "Competitor", border-radius:20px, padding:4px 8px, 11px
- Under-18 badge: `background:rgba(83,74,183,0.12)`, `color:#534AB7`, text "Practice Mode", same sizing
- Email: 11px, `color:#888`, 16px bottom margin
- Sign out button: `border:0.5px solid rgba(255,100,100,0.4)`, `color:#f5a0a0`, 11px, border-radius:8px, padding:8px 12px
- Uses `playerName` and `playerIs18Plus` module-scope vars (set by `onSignedIn()`) — no extra DB fetch
- All user strings escaped via `gspEscapeHtml`

**Not-logged-in state:**
- "Sign in to see your account and compete for prizes." at 13px `#1a1a1a`
- CTA button: `background:#534AB7`, `color:#fff`, 13px, border-radius:8px, padding:12px 16px, min-height:44px

**No Supabase state:**
- Shows config copy instruction only (removed stray Sign in button from no-sb state)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all data paths are wired. The PASSWORD_RECOVERY full round-trip (user receives email, clicks link, lands on site) requires a real Supabase project with email configured. The implementation is complete; the reset email delivery is a Supabase infrastructure concern, not a code stub.

## Self-Check: PASSED

- `prototypes/penguin-game.html` modified and committed (a2eb92c, e5f3613)
- Task 1 automated grep verification: PASS — PASSWORD_RECOVERY, resetPasswordForEmail, auth-set-new-pw, updateUser all present
- Task 2 automated grep verification: PASS — Competitor, Practice Mode, #FAEEDA, #534AB7, gsp-account-signout all present
- All acceptance criteria verified before each commit
