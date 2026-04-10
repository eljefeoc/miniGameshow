# Admin UI Redesign — Cursor Task Brief
*Generated: April 8, 2026*

## Visual reference
`prototypes/admin-mockup.html` is the approved design. Open it in a browser before starting. All visual decisions (colors, spacing, layout, animations) should match it exactly.

---

## Scope & rules

**This is a visual + structural update to `prototypes/admin.html` only.**

- Do NOT touch `prototypes/penguin-game.html`, `prototypes/hud.js`, `prototypes/hud.css`, or any game files
- Do NOT change any Supabase queries, RPC calls, Edge Function calls, or auth logic
- Do NOT change any existing JS function names or their internal logic
- All existing element IDs that JS depends on must be preserved exactly (list below)
- Make changes in small, logical steps — do not rewrite the whole file in one pass
- Test: after changes, the page must still load, authenticate, and show the live dashboard with real data

---

## IDs and attributes that must be preserved exactly

These are wired to JS — rename or remove any of them and the page breaks:

```
#auth-gate
#admin-shell
#sidebar (nav element)
#sidebar-avatar
#sidebar-email
#btn-admin-logout
#content
#not-admin-note
#section-live
#section-new
#section-users
data-section="live" | "new" | "users"   (on nav buttons)
#event-hub-card
#event-hub-wrap
#event-hub-empty
#event-hub-sub
#event-etabs
#event-hub-panel
.etab-btn + data-etab="active|upcoming|past"
#etab-n-active, #etab-n-upcoming, #etab-n-past
#event-winner-banner
#sv-players, #ss-players
#sv-runs, #ss-runs
#sv-flagged, #ss-flagged
#sv-time, #sv-time-label, #ss-time
All leaderboard render targets in section-live
All flagged/banned table targets in section-users
All form fields and buttons in section-new
```

---

## Change 1 — CSS variables (add to `:root`)

Add these new variables to the existing `:root` block. Do not remove any existing variables.

```css
--sidebar-bg:     #1a1826;
--sidebar-hover:  #252236;
--sidebar-active: #2e2a45;
--sidebar-text:   rgba(255,255,255,0.55);
--sidebar-head:   rgba(255,255,255,0.25);
--gold:           #F5A623;
--gold-bg:        rgba(245,166,35,0.10);
--gold-border:    rgba(245,166,35,0.30);
--live-green:     #22c55e;
```

---

## Change 2 — Sidebar CSS

Replace the entire sidebar CSS block (everything that targets `#sidebar`, `.sidebar-brand`, `.sidebar-nav`, `.nav-item`, `.sidebar-footer`, `.sidebar-avatar`, `.sidebar-email`) with the following. Copy exactly from `admin-mockup.html` — the relevant classes are:

```
#sidebar
.sidebar-brand
.brand-icon
.brand-name
.brand-sub
.rail-section
.rail-label
.event-item
.event-item:hover
.event-item.active
.event-dot
.event-dot.live  (includes pulse-dot keyframe animation)
.event-dot.upcoming
.event-dot.past
.event-info
.event-name
.event-meta
.live-badge
.past-toggle
.toggle-arrow
.past-list
.past-list.open
.past-item
.past-name
.past-meta
.past-winner
.sidebar-spacer
.sidebar-footer-nav
.footer-nav-item
.footer-nav-item .icon
.sidebar-user
.user-avatar
.user-email
.user-role
.live-dot-sm  (small pulsing dot, reused in hero)
```

Also add the `@keyframes pulse-dot` animation.

---

## Change 3 — Sidebar HTML

Replace the existing `<nav id="sidebar">` block (lines ~409–426 in the current file) with this new structure. **Preserve all JS-wired IDs and data attributes.**

```html
<nav id="sidebar">

  <!-- Brand -->
  <div class="sidebar-brand">
    <div class="brand-icon">🎮</div>
    <div>
      <div class="brand-name">MiniGameshow</div>
      <div class="brand-sub">Admin</div>
    </div>
  </div>

  <!-- Live event rail — populated by renderSidebarRail() -->
  <div class="rail-section">
    <div class="rail-label">Live Now</div>
    <div id="sidebar-rail-live">
      <!-- JS populates this -->
    </div>
  </div>

  <div class="rail-section">
    <div class="rail-label">Upcoming</div>
    <div id="sidebar-rail-upcoming">
      <!-- JS populates this -->
    </div>
  </div>

  <div class="rail-section">
    <div class="rail-label">Past Events</div>
    <div class="past-toggle" id="past-toggle-btn">
      <span class="toggle-arrow" id="past-arrow">▶</span>
      Show past events
    </div>
    <div class="past-list" id="past-list">
      <div id="sidebar-rail-past">
        <!-- JS populates this -->
      </div>
    </div>
  </div>

  <!-- Hidden nav buttons — keep for JS section switching compatibility -->
  <div style="display:none">
    <button class="nav-item active" data-section="live">Live competition</button>
    <button class="nav-item" data-section="new">New competition</button>
    <button class="nav-item" data-section="users">User admin</button>
  </div>

  <div class="sidebar-spacer"></div>

  <!-- Footer nav -->
  <div class="sidebar-footer-nav">
    <div class="footer-nav-item" onclick="navigateTo('users')">
      <span class="icon">👤</span>
      User Admin
    </div>
    <div class="footer-nav-item" onclick="navigateTo('new')">
      <span class="icon">＋</span>
      New Event
    </div>
  </div>

  <!-- User identity (preserved IDs) -->
  <div class="sidebar-user">
    <div class="user-avatar" id="sidebar-avatar">?</div>
    <div style="min-width:0">
      <div class="user-role">Admin</div>
      <div class="user-email" id="sidebar-email"></div>
    </div>
  </div>

</nav>
```

**Note:** The hidden nav buttons preserve the `data-section` attributes that `navigateTo()` queries. The visible footer items call `navigateTo()` directly. Do not remove the hidden block.

---

## Change 4 — New JS function: renderSidebarRail()

Add this function near the top of the JS section (after existing utility functions, before `loadEventHub`). It reads the already-fetched events array and populates the three sidebar rail containers.

```javascript
function renderSidebarRail(events) {
  // events: array of event objects from Supabase (same shape loadEventHub uses)
  const now = new Date();

  const live     = events.filter(e => new Date(e.starts_at) <= now && new Date(e.ends_at) >= now);
  const upcoming = events.filter(e => new Date(e.starts_at) > now);
  const past     = events.filter(e => new Date(e.ends_at) < now).sort((a,b) => new Date(b.ends_at) - new Date(a.ends_at));

  function eventLabel(e) {
    return e.prize_title ? `${e.prize_title}` : (e.game_id || 'Event');
  }

  // Live
  const liveEl = document.getElementById('sidebar-rail-live');
  if (liveEl) {
    liveEl.innerHTML = live.length === 0
      ? `<div style="padding:6px 10px;font-size:12px;color:var(--sidebar-text)">No live event</div>`
      : live.map(e => `
        <div class="event-item active" data-event-id="${e.id}" onclick="sidebarSelectEvent(this, '${e.id}')">
          <div class="event-dot live"></div>
          <div class="event-info">
            <div class="event-name">${eventLabel(e)}</div>
            <div class="live-badge">● Live</div>
            <div class="event-meta">Ends ${new Date(e.ends_at).toLocaleDateString('en-US',{month:'short',day:'numeric'})} · ${e.prize_amount ? '$'+e.prize_amount : ''}</div>
          </div>
        </div>`).join('');
  }

  // Upcoming
  const upEl = document.getElementById('sidebar-rail-upcoming');
  if (upEl) {
    upEl.innerHTML = upcoming.length === 0
      ? `<div style="padding:6px 10px;font-size:12px;color:var(--sidebar-text)">None scheduled</div>`
      : upcoming.slice(0,3).map(e => `
        <div class="event-item" data-event-id="${e.id}" onclick="sidebarSelectEvent(this, '${e.id}')">
          <div class="event-dot upcoming"></div>
          <div class="event-info">
            <div class="event-name">${eventLabel(e)}</div>
            <div class="event-meta">Starts ${new Date(e.starts_at).toLocaleDateString('en-US',{month:'short',day:'numeric'})}</div>
          </div>
        </div>`).join('');
  }

  // Past
  const pastEl = document.getElementById('sidebar-rail-past');
  if (pastEl) {
    pastEl.innerHTML = past.length === 0
      ? `<div style="padding:6px 10px;font-size:12px;color:var(--sidebar-text)">No past events</div>`
      : past.slice(0,8).map(e => `
        <div class="past-item" data-event-id="${e.id}" onclick="sidebarSelectEvent(this, '${e.id}')">
          <div class="past-name">${eventLabel(e)}</div>
          <div class="past-meta">Ended ${new Date(e.ends_at).toLocaleDateString('en-US',{month:'short',day:'numeric'})}${e.prize_amount ? ' · $'+e.prize_amount : ''}</div>
        </div>`).join('');
  }

  // Wire past toggle
  const toggleBtn = document.getElementById('past-toggle-btn');
  if (toggleBtn) {
    toggleBtn.onclick = () => {
      const list = document.getElementById('past-list');
      const arrow = document.getElementById('past-arrow');
      list.classList.toggle('open');
      if (arrow) arrow.textContent = list.classList.contains('open') ? '▼' : '▶';
    };
  }
}

function sidebarSelectEvent(el, eventId) {
  // Highlight the clicked item
  document.querySelectorAll('#sidebar .event-item, #sidebar .past-item').forEach(e => e.classList.remove('active'));
  el.classList.add('active');
  // Navigate to live section (event detail is shown in main content)
  navigateTo('live');
  // If the event hub already loaded, switch to the matching etab
  // (active/upcoming/past tabs in the main content will still work normally)
}
```

---

## Change 5 — Call renderSidebarRail() from loadEventHub()

In the existing `loadEventHub()` function, after the events array is fetched and before it renders the etabs, add one line:

```javascript
renderSidebarRail(events);
```

This ensures the sidebar populates whenever the main event hub loads. Do not change anything else in `loadEventHub()`.

---

## Change 6 — Dark gradient header for section-live

In `#section-live`, replace:

```html
<div class="page-title">Live competition</div>
```

with a dynamic hero header. Add this immediately after `<section id="section-live" class="admin-section active">`:

```html
<div id="live-hero" style="
  background: linear-gradient(135deg, #1e1b2e 0%, #2a2550 50%, #1e2d40 100%);
  border-bottom: 1px solid rgba(255,255,255,0.06);
  padding: 14px 24px;
  display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
  margin: -24px -24px 24px;
  position: relative; overflow: hidden;
">
  <div style="position:absolute;inset:0;background:radial-gradient(ellipse at 80% 50%,rgba(127,119,221,0.12) 0%,transparent 70%);pointer-events:none"></div>
  <div id="live-hero-chip" style="
    display:inline-flex;align-items:center;gap:5px;
    background:rgba(34,197,94,0.15);border:1px solid rgba(34,197,94,0.3);
    border-radius:100px;padding:3px 10px;font-size:10.5px;font-weight:700;
    color:#22c55e;letter-spacing:0.05em;text-transform:uppercase;
    flex-shrink:0;position:relative;
  ">
    <div style="width:6px;height:6px;border-radius:50%;background:#22c55e;animation:pulse-dot 2s infinite"></div>
    Live
  </div>
  <div id="live-hero-title" style="font-size:16px;font-weight:700;color:#fff;flex-shrink:0;position:relative;">
    Live competition
  </div>
  <div style="width:1px;height:20px;background:rgba(255,255,255,0.12);flex-shrink:0;position:relative"></div>
  <div id="live-hero-meta" style="font-size:12px;color:rgba(255,255,255,0.45);position:relative"></div>
  <div id="live-hero-countdown" style="font-size:13px;font-weight:700;color:#22c55e;margin-left:auto;font-variant-numeric:tabular-nums;position:relative"></div>
</div>
```

**Note on margin:** `margin: -24px -24px 24px` bleeds the header to the content area edges (content has `padding: 24px`). Adjust if content padding differs.

---

## Change 7 — Populate the hero header from JS

Find where the existing live event data is rendered (in `loadLiveSection()` or wherever `sv-players`, `sv-time` etc. are set). After that data is available, add:

```javascript
// Populate live hero header
const heroTitle    = document.getElementById('live-hero-title');
const heroMeta     = document.getElementById('live-hero-meta');
const heroCountdown = document.getElementById('live-hero-countdown');
const heroChip     = document.getElementById('live-hero-chip');

if (activeEvent && heroTitle) {
  const prizePart = activeEvent.prize_amount ? ` · $${activeEvent.prize_amount}` : '';
  heroTitle.textContent = activeEvent.prize_title || 'Live competition';
  if (heroMeta) heroMeta.innerHTML = `Prize: <span style="font-weight:600;color:rgba(255,255,255,0.85)">${activeEvent.prize_amount ? '$'+activeEvent.prize_amount : '—'}</span>`;
}

// Countdown tick (updates every second)
if (activeEvent && heroCountdown) {
  function tickHero() {
    const now  = new Date();
    const end  = new Date(activeEvent.ends_at);
    const diff = end - now;
    if (diff <= 0) { heroCountdown.textContent = 'Scoring closed'; return; }
    const d = Math.floor(diff / 86400000);
    const h = Math.floor((diff % 86400000) / 3600000);
    const m = Math.floor((diff % 3600000)  / 60000);
    const s = Math.floor((diff % 60000)    / 1000);
    heroCountdown.textContent = `${d}d ${h}h ${m}m ${s}s left`;
  }
  tickHero();
  setInterval(tickHero, 1000);
}
```

If no active event exists, hide the chip and show a neutral header:

```javascript
if (!activeEvent && heroChip) {
  heroChip.style.display = 'none';
  if (heroTitle) heroTitle.textContent = 'No live event';
}
```

---

## Change 8 — Leaderboard row styling

The existing leaderboard renders rows via JS (search for where `tr` or leaderboard rows are built in `loadLeaderboard` or similar). Update the row rendering to match the mockup style:

- Rank 1 row: add gold background (`var(--gold-bg)`), gold border (`var(--gold-border)`), gold score text
- Rank 2 row: silver rank number (`#94a3b8`)
- Rank 3 row: bronze rank number (`#b45309`)
- All rows: flex layout with avatar circle (initials), username, attempts sub-label, score right-aligned
- Add rank change indicator column (`▲N` green / `▼N` red / `—` muted) — track previous rank in a `Map` keyed by `user_id`, compare on each reload

Copy the `.lb-row`, `.lb-rank`, `.lb-avatar`, `.lb-info`, `.lb-username`, `.lb-attempts`, `.lb-score`, `.lb-change`, `.flash-up`, `.flash-down` CSS from `admin-mockup.html` into the `<style>` block.

Add `@keyframes flash-up` and `@keyframes flash-down` from the mockup.

Wrap the leaderboard table in a container that matches `.lb-card` styling from the mockup (rounded card, header with Competition/Arcade tabs, footer with "Updating live" indicator).

---

## Change 9 — Leaderboard realtime subscription

After the existing leaderboard load call, add a Supabase realtime subscription so scores update live without a manual refresh:

```javascript
// Realtime leaderboard updates
const lbChannel = supabase
  .channel('leaderboard-admin')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'runs'
  }, payload => {
    // A new run was submitted — reload the leaderboard
    loadLeaderboard();  // replace with actual leaderboard load function name
  })
  .subscribe();
```

Use the actual leaderboard reload function name — search the file for where leaderboard rows are built and call that function.

---

## Verification checklist

After all changes, verify:

- [ ] Page loads and shows auth gate for unauthenticated users
- [ ] Signing in shows the dark sidebar with event rail populated from Supabase
- [ ] Live event appears in "Live Now" section with pulsing dot
- [ ] Upcoming and past events appear in their sections
- [ ] Past events toggle opens/closes
- [ ] Clicking an event in the sidebar calls `navigateTo('live')`
- [ ] "User Admin" footer button switches to `#section-users`
- [ ] "New Event" footer button switches to `#section-new`
- [ ] Live hero header shows event name, prize, and live countdown
- [ ] Leaderboard shows gold/silver/bronze styling on top 3
- [ ] Leaderboard rank change indicators show on reload
- [ ] Realtime subscription fires when a new run is inserted
- [ ] Sign out still works (logout button in sidebar-user area)
- [ ] No console errors on load
