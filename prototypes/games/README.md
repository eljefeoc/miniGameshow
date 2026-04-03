# L3 game modules (arcade layer)

Each file here is a **thin** mini-game bundle loaded by the **L2 host** (see `CURSOR_ROADMAP.md` → *Target architecture — Pattern B*).

The host owns HUD, menus, auth entry, title/post-run overlays, and week context. This folder owns **canvas + loop + game-specific input** only.

## Contract (draft)

Implement as an ES module. Exact names TBD when `play.html` + host loader land.

- **`mount(container)`** — Create canvas (or attach existing), bind listeners, start loop. `container` is the host’s `#game-mount` (or equivalent).
- **`destroy()`** — Remove listeners, stop RAF, detach canvas so another L3 can mount.
- **`onResize?(detail)`** — Optional; host passes `{ width, height }` or scale so the game can match shell layout without duplicating `resizeCanvas` logic long term.

The host (L2) remains responsible for **Supabase session**, **attempts**, and **submitting runs**; the module emits **run end** / score through a callback or event the host registers (shape to be defined with existing `runs` insert code).

## Stage sizing (for every L3)

- The **L2 host** defines the **mount box** (`#game-mount` or equivalent): the pixel area left after HUD, safe areas, and thumb controls.
- Each game defines a **native design resolution or aspect** (e.g. 660×330 for 2:1 landscape, or 9:16 for a vertical title).
- **Scaling:** use a **single uniform scale** — `min(mountW/nativeW, mountH/nativeH)` — then **center** the canvas. Add **letterboxing** (horizontal game in tall viewport) or **pillarboxing** (vertical game in wide viewport) as needed.
- **Do not** stretch width and height independently to fill the mount; that warps art and breaks input mapping.
- **Desktop:** same rule — the game lives in a **framed stage** inside the page, not stretched edge-to-edge.
- A title can be **landscape-primary** (Pengu) or **portrait-primary** (hypothetical stack game); that is a **per-game design choice**, not something the host special-cases beyond reading each module’s native dimensions.

## Slugs

Slug values should match what the admin / `weeks` row stores (e.g. `pengu`, `fish-stack`) so the host can resolve `games/<slug>.js` or a registry map.
