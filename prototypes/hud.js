/* ============================================================
   MiniGameshow — Gameshow HUD
   Shared across all game prototypes.

   Usage in any game HTML:
     <link rel="stylesheet" href="hud.css">
     <div id="gameshow-hud-mount"></div>
     <script src="hud.js"></script>

   Then in the game script:
     GameshowHud.init('#gameshow-hud-mount');
     GameshowHud.setPrize('Weekend in Amsterdam');
     GameshowHud.setShowAt(new Date('2026-03-29T03:00:00Z'));
     GameshowHud.setStats({ rank: 14, best: 8420, attemptsUsed: 2 });
       GameshowHud.setPlayer({ initials: 'JK', name: 'Jeff K.' });
     GameshowHud.setPlayer(null); // signed out / guest
     GameshowHud.onMenuClick(() => { … });
   ============================================================ */

const GameshowHud = (() => {
  // ── state ────────────────────────────────────────────────
  let _showAt         = null;   // Date object for live show
  let _prizeName      = '';
  let _rank           = null;   // null = unknown
  let _best           = null;
  let _attemptsUsed   = 0;
  let _initials       = '';
  let _isGuest        = true;
  let _menuHandler    = null;
  let _avatarHandler  = null;
  let _schedInterval  = null;
  let _endsAt         = null;   // scoring window end from public.weeks.ends_at (admin)

  // ── template ─────────────────────────────────────────────
  const HTML = `
<div id="gameshow-hud">
  <div class="ghud-prize">
    <div class="ghud-brand-row">
      <span class="ghud-show-title" id="ghud-show-title">The Mini-Game Show</span>
    </div>
    <div class="ghud-prize-time" id="ghud-schedule">
      Scoring closes <span class="ghud-accent">Sat midnight</span>
      <span class="ghud-muted"> · Live show Sun ···</span>
    </div>
  </div>

  <div class="ghud-stat ghud-stat-rank">
    <span class="ghud-stat-label">Rank</span>
    <span class="ghud-stat-value" id="ghud-rank">—</span>
  </div>
  <div class="ghud-stat">
    <span class="ghud-stat-label">Score</span>
    <span class="ghud-stat-value" id="ghud-best">—</span>
  </div>
  <div class="ghud-stat ghud-stat-last">
    <span class="ghud-stat-label">Attempts</span>
    <div class="ghud-attempts" id="ghud-attempts"></div>
  </div>

  <div class="ghud-avatar guest" id="ghud-avatar" title="Guest">?</div>

  <div class="ghud-menu" id="ghud-menu" role="button" aria-label="Menu" tabindex="0">
    <div class="ghud-menu-bars">
      <div class="ghud-menu-bar"></div>
      <div class="ghud-menu-bar"></div>
      <div class="ghud-menu-bar"></div>
    </div>
  </div>
</div>`;

  // ── helpers ───────────────────────────────────────────────
  function el(id) { return document.getElementById(id); }

  function fmtNum(n) {
    if (n == null) return '—';
    return Number(n).toLocaleString();
  }

  function fmtShowTime(d) {
    if (!d) return '···';
    try {
      return d.toLocaleTimeString([], {
        hour: 'numeric', minute: '2-digit', timeZoneName: 'short'
      }).replace(':00', '').toLowerCase();
    } catch (_) { return '7pm PT'; }
  }

  function fmtEndsShort(d) {
    if (!d) return '···';
    try {
      return d.toLocaleString([], {
        weekday: 'short', month: 'short', day: 'numeric',
        hour: 'numeric', minute: '2-digit'
      });
    } catch (_) { return '···'; }
  }

  function renderClosedWithShowLine(t) {
    const wrap = el('ghud-schedule');
    if (!wrap) return;
    const now = new Date();
    let showBit = `at ${t}`;
    if (_showAt) {
      const sameDay = now.toDateString() === _showAt.toDateString();
      if (sameDay) showBit = `today at ${t}`;
    }
    wrap.innerHTML =
      `<span class="ghud-muted">Scoring closed</span>` +
      ` <span class="ghud-accent"> · Live show ${showBit}</span>`;
    _clearInterval();
  }

  function renderDots(used) {
    const wrap = el('ghud-attempts');
    if (!wrap) return;
    wrap.innerHTML = '';
    for (let i = 0; i < 5; i++) {
      const d = document.createElement('div');
      d.className = 'ghud-dot ' + (i < used ? 'ghud-dot-used' : 'ghud-dot-avail');
      wrap.appendChild(d);
    }
  }

  // ── schedule: prefer DB ends_at/show_at (admin); else local weekday fallback ──
  function renderSchedule() {
    const wrap = el('ghud-schedule');
    if (!wrap) return;

    const now = new Date();
    const t   = fmtShowTime(_showAt);
    const useDb = _endsAt instanceof Date && !isNaN(_endsAt.getTime());

    if (useDb) {
      const endMs = _endsAt.getTime();
      const pastEnd = now.getTime() > endMs;
      if (pastEnd) {
        renderClosedWithShowLine(t);
        return;
      }
      const secLeft = Math.max(0, Math.floor((endMs - now.getTime()) / 1000));
      if (secLeft <= 172800) {
        const tick = () => {
          const n = new Date();
          const sec = Math.max(0, Math.floor((endMs - n.getTime()) / 1000));
          if (sec <= 0) {
            renderClosedWithShowLine(fmtShowTime(_showAt));
            _clearInterval();
            return;
          }
          const h = Math.floor(sec / 3600);
          const m = Math.floor((sec % 3600) / 60);
          const s = sec % 60;
          const str = h > 48 ? `${Math.floor(h / 24)}d ${h % 24}h left`
            : h > 0 ? `${h}h ${m}m left`
            : m > 0 ? `${m}m ${s}s left`
            : `${s}s left`;
          const w = el('ghud-schedule');
          if (w) {
            w.innerHTML =
              `Scoring closes <span class="ghud-urgent">${str}</span>` +
              ` <span class="ghud-muted"> · Live show ${t}</span>`;
          }
        };
        tick();
        if (!_schedInterval) _schedInterval = setInterval(tick, 1000);
        return;
      }
      _clearInterval();
      wrap.innerHTML =
        `Scoring closes <span class="ghud-accent">${fmtEndsShort(_endsAt)}</span>` +
        ` <span class="ghud-muted"> · Live show ${t}</span>`;
      return;
    }

    const day = now.getDay();

    if (day === 0) {
      renderClosedWithShowLine(t);
    } else if (day === 6) {
      const tick = () => {
        const n   = new Date();
        const end = new Date(n.getFullYear(), n.getMonth(), n.getDate(), 23, 59, 59);
        const sec = Math.max(0, Math.floor((end - n) / 1000));
        const h   = Math.floor(sec / 3600);
        const m   = Math.floor((sec % 3600) / 60);
        const s   = sec % 60;
        const str = h > 0 ? `${h}h ${m}m left`
                  : m > 0 ? `${m}m ${s}s left`
                  : `${s}s left`;
        const w = el('ghud-schedule');
        if (w) w.innerHTML =
          `Scoring closes <span class="ghud-urgent">${str}</span>` +
          ` <span class="ghud-muted"> · Live show tomorrow ${t}</span>`;
      };
      tick();
      if (!_schedInterval) _schedInterval = setInterval(tick, 1000);
    } else {
      wrap.innerHTML =
        `Scoring closes <span class="ghud-accent">Sat midnight</span>` +
        ` <span class="ghud-muted"> · Live show Sun ${t}</span>`;
      _clearInterval();
    }
  }

  function _clearInterval() {
    if (_schedInterval) { clearInterval(_schedInterval); _schedInterval = null; }
  }

  // ── public API ───────────────────────────────────────────
  function init(mountSelector) {
    const mount = typeof mountSelector === 'string'
      ? document.querySelector(mountSelector)
      : mountSelector;
    if (!mount) { console.warn('GameshowHud: mount not found', mountSelector); return; }

    mount.innerHTML = HTML;

    // Wire menu click
    const menuBtn = el('ghud-menu');
    if (menuBtn) {
      menuBtn.addEventListener('click', () => _menuHandler && _menuHandler());
      menuBtn.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') _menuHandler && _menuHandler();
      });
    }

    const avBtn = el('ghud-avatar');
    if (avBtn) {
      avBtn.addEventListener('click', e => {
        e.stopPropagation();
        _avatarHandler && _avatarHandler();
      });
      avBtn.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          _avatarHandler && _avatarHandler();
        }
      });
    }

    // Initial render with current state
    renderDots(_attemptsUsed);
    renderSchedule();
  }

  function setPrize(name) {
    _prizeName = name || '';
    /* Prize name lives in the title / post-run card only — not in the HUD bar. */
  }

  function setShowAt(date) {
    _showAt = date instanceof Date ? date : (date ? new Date(date) : null);
    renderSchedule();
  }

  function setScoringEndsAt(date) {
    _endsAt = date instanceof Date ? date : (date ? new Date(date) : null);
    renderSchedule();
  }

  function setStats({ rank = null, best = null, attemptsUsed = 0 } = {}) {
    _rank = rank; _best = best; _attemptsUsed = attemptsUsed;
    const rankEl = el('ghud-rank');
    const bestEl = el('ghud-best');
    if (rankEl) rankEl.textContent = rank != null ? `#${rank}` : '—';
    if (bestEl) bestEl.textContent = fmtNum(best);
    renderDots(attemptsUsed);
  }

  function setPlayer(player) {
    // player = { initials, name } or null (guest)
    const av = el('ghud-avatar');
    if (!av) return;
    if (player?.initials) {
      _isGuest  = false;
      _initials = player.initials.slice(0, 2).toUpperCase();
      av.textContent = _initials;
      av.className   = 'ghud-avatar';
      av.title       = (player.name || _initials) + ' — tap to sign out';
      av.setAttribute('aria-label', 'Sign out');
    } else {
      _isGuest  = true;
      _initials = '';
      av.textContent = '?';
      av.className   = 'ghud-avatar guest';
      av.title       = 'Guest — tap to sign in';
      av.setAttribute('aria-label', 'Sign in');
    }
  }

  function onMenuClick(handler) {
    _menuHandler = handler;
  }

  function onAvatarClick(handler) {
    _avatarHandler = handler;
  }

  // ── height helper for game resize calculations ───────────
  function height() {
    const h = document.getElementById('gameshow-hud');
    return h ? h.offsetHeight : 56;
  }

  return { init, setPrize, setShowAt, setScoringEndsAt, setStats, setPlayer, onMenuClick, onAvatarClick, height };
})();
// Always on window — inline game scripts and file:// loads rely on this
window.GameshowHud = GameshowHud;
