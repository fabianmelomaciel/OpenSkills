---
applyTo:
  - *
---

# Emil Kowalski Design Engineering

You are applying the design philosophy of Emil Kowalski — the idea that **taste is a trained instinct**, not a gift. In a world where functionality is commoditized, **invisible details** are the primary differentiator.

> **Core doctrine:** The best animation is the one that goes unnoticed. The best interaction is the one that feels inevitable.

---

## 🧠 Before You Start

1. Read `CODEX.md` (search upward) to load any project-specific UI patterns or past lessons.
2. Inspect existing animation/transition code in the project before proposing new approaches.
3. Ask yourself: **"Does this change serve a function, or is it decoration?"** Decoration without purpose ships last or not at all.

---

## Animation Rules (Non-Negotiable)

| Rule | Requirement |
|------|-------------|
| **Duration** | UI transitions: **100–300ms max**. Anything slower feels sluggish. |
| **Easing** | Always use custom `cubic-bezier`. Never use `ease`, `ease-in`, `ease-out` defaults. |
| **GPU acceleration** | Only animate `transform` and `opacity`. Never animate `width`, `height`, `top`, `left`. |
| **Origin-aware** | Popovers, dropdowns, tooltips must animate from their trigger point (`transform-origin`). |
| **Purposeful** | Every animation must answer: "what spatial relationship does this communicate?" |
| **Reduced motion** | `@media (prefers-reduced-motion: reduce)` MUST disable or minimize all animations. |

### Standard Easing Values

```css
/* Snappy entry — for menus, dropdowns, toasts */
cubic-bezier(0.16, 1, 0.3, 1)

/* Natural exit — for closing, dismissing */
cubic-bezier(0.4, 0, 0.2, 1)

/* Bouncy — use sparingly, only for delight moments */
cubic-bezier(0.34, 1.56, 0.64, 1)
```

### Animation Template

```css
/* ✅ Correct — GPU-friendly, purposeful, origin-aware */
.popover {
  transform-origin: var(--radix-popover-content-transform-origin);
  animation: popover-in 150ms cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes popover-in {
  from { opacity: 0; transform: scale(0.95); }
  to   { opacity: 1; transform: scale(1); }
}

@media (prefers-reduced-motion: reduce) {
  .popover { animation: none; }
}

/* ❌ Wrong — animating layout properties, bad easing */
.popover {
  transition: height 400ms ease, width 400ms ease;
}
```

---

## Micro-Interaction Rules

| Interaction | Implementation |
|-------------|----------------|
| **Button press** | `transform: scale(0.97)` on `:active` — instant (0ms), release 100ms |
| **Hover lift** | `transform: translateY(-1px)` + subtle `box-shadow` increase |
| **Loading states** | Show spinner after 300ms delay (avoid flash for fast responses) |
| **Optimistic UI** | Update UI immediately, revert on error — never make users wait |
| **Focus ring** | Always visible, never removed. Use `:focus-visible` not `:focus`. |

### Press Feedback Template

```css
/* Immediate press, smooth release */
.button {
  transition: transform 100ms cubic-bezier(0.4, 0, 0.2, 1),
              box-shadow 100ms cubic-bezier(0.4, 0, 0.2, 1);
}
.button:active {
  transform: scale(0.97);
}

/* For touch devices */
@media (hover: none) {
  .button:active {
    transform: scale(0.95);
  }
}
```

---

## Perceived Performance Rules

- **Skeleton screens** over spinners for content that takes >500ms
- **Optimistic updates** for mutations (like, bookmark, delete) — revert on failure
- **Prefetch on hover** (`router.prefetch()` on link hover for page transitions)
- **Instant feedback** — every click must produce a visual response within one frame (16ms)
- **Stagger children** — when revealing lists, stagger by 30–50ms per item, not all at once

```css
/* Staggered list reveal */
.item:nth-child(1) { animation-delay: 0ms; }
.item:nth-child(2) { animation-delay: 40ms; }
.item:nth-child(3) { animation-delay: 80ms; }
/* Cap at ~5 items — beyond that, stagger loses meaning */
```

---

## Design Audit Checklist

Run this on any UI component before marking work done:

- [ ] All animations use `transform`/`opacity` only (no layout properties)
- [ ] All durations are ≤300ms
- [ ] Custom `cubic-bezier` used (no CSS defaults)
- [ ] Origin-aware: dropdowns/popovers animate from trigger point
- [ ] `@media (prefers-reduced-motion: reduce)` disables animations
- [ ] Buttons have `:active` scale feedback
- [ ] Focus states visible with `:focus-visible`
- [ ] No animation exists purely for decoration without spatial meaning
- [ ] Loading states appear only after 300ms delay
- [ ] Touch devices have appropriate `touch-action` set

---

## Taste Development Protocol

When reviewing your own work, ask:

1. **Does this feel fast?** Interactions should feel instantaneous. If it feels slow, it is slow.
2. **Is the animation communicating something?** Fade = appears. Scale from origin = grows from source. Slide = spatial context.
3. **What happens on mobile/touch?** Hover effects must degrade gracefully.
4. **Would this embarrass Stripe, Linear, or Vercel?** These are the taste benchmarks.

---

## CODEX Learning Gate

After completing UI work, if you discovered:
- A project-specific animation pattern or design token
- A browser/OS quirk affecting animations
- A performance constraint unique to this stack

→ Append a log entry to `CODEX.md` under `## 💻 Mission Logs & Tactical Learnings`.
