---
phase: 2
slug: auth-player-profiles
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual / Browser DevTools (no automated test framework in project) |
| **Config file** | none |
| **Quick run command** | Open app in browser, check auth flow |
| **Full suite command** | Full auth regression: signup → login → reset → age-gate |
| **Estimated runtime** | ~5 minutes manual |

---

## Sampling Rate

- **After every task commit:** Load app in browser, verify no JS errors in console
- **After every plan wave:** Run the full auth regression flow
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 minutes

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | AUTH-01 | manual | open app, complete signup with display_name + 18+ checkbox | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | AUTH-02 | manual | sign in, refresh browser, session persists | ✅ | ⬜ pending |
| 02-01-03 | 01 | 1 | AUTH-03 | manual | check #auth-status shows error text on bad password | ✅ | ⬜ pending |
| 02-02-01 | 02 | 2 | AUTH-04 | manual | click "Forgot password", check email, reset link works | ✅ | ⬜ pending |
| 02-02-02 | 02 | 2 | AUTH-05 | manual | open account tab, verify display name + age tier shown | ✅ | ⬜ pending |
| 02-03-01 | 03 | 3 | AUTH-06 | manual | sign up as under-18, see Practice Mode indicator | ✅ | ⬜ pending |
| 02-03-02 | 03 | 3 | AUTH-06 | manual | sign up as 18+, compete on main leaderboard | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- None — no automated test framework. All verification is manual browser testing.

*Existing infrastructure: browser + Supabase dashboard covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Signup creates profiles row with display_name and is_18_plus | AUTH-01 | No test framework; DB state requires Supabase dashboard | Sign up → check Table Editor in Supabase dashboard for new row |
| Password reset email arrives and link resolves | AUTH-04 | Email delivery and URL redirect require live environment | Click "Forgot password" → check email → follow link → set new password |
| Under-18 user sees Practice Mode indicator in HUD | AUTH-06 | Visual/UI state; no DOM assertion framework | Sign up with age < 18 → start game → verify "Practice Mode" visible |
| 18+ user's scores go to competitive leaderboard | AUTH-06 | Leaderboard full wiring is Phase 4; flag set correctly here | Sign up as 18+ → verify `is_18_plus = true` in profiles table |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
