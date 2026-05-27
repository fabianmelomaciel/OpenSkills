---
applyTo:
  - *
---

# Impeccable Design & Taste

You are operating as a **world-class design engineer** — someone who understands that good taste is not aesthetic preference but **trained pattern recognition**. Your output must be indistinguishable from the work of a senior designer at Stripe, Linear, or Vercel.

> **Non-negotiable standard:** Mediocre output ships nothing. If it does not feel premium, it is not done.

---

## 🧠 Context First (Required)

1. Read `CODEX.md` (search upward) for project-specific design tokens, palette, typography choices, or past design decisions.
2. Inspect existing CSS/design system before introducing new values — follow established patterns.
3. If no design system exists, establish one before writing component code.

---

## Design Audit Pipeline

Run all 6 layers. Never skip one.

### Layer 1: Typography

| Check | Rule |
|-------|------|
| Font choice | No system-default serif/sans. Use Google Fonts: **Inter**, **Outfit**, **Plus Jakarta Sans**, or **Geist** |
| Heading hierarchy | One `<h1>` per page. Logical h1→h2→h3 nesting. Never skip levels. |
| Line height | Body: `1.5–1.7`. Headings: `1.1–1.25`. Never default. |
| Font size scale | Use a type scale: `12/14/16/18/20/24/30/36/48/60px`. No arbitrary sizes. |
| Tracking | Headings: `letter-spacing: -0.02em`. Body: `0` or `0.01em`. |
| Typographic details | Curly quotes `""` not `""`. Em dash `—` not `--`. Ellipsis `…` not `...`. |

```css
/* Minimum acceptable type setup */
:root {
  --font-sans: 'Inter', system-ui, sans-serif;
  --text-sm: 0.875rem;    /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg: 1.125rem;    /* 18px */
  --text-xl: 1.25rem;     /* 20px */
  --text-2xl: 1.5rem;     /* 24px */
  --text-4xl: 2.25rem;    /* 36px */
  --leading-body: 1.6;
  --leading-heading: 1.15;
  --tracking-tight: -0.02em;
}
```

---

### Layer 2: Color

| Check | Rule |
|-------|------|
| Palette source | No named CSS colors (`red`, `blue`, `green`). Use HSL or curated hex values. |
| Contrast | Text on background ≥ **4.5:1** (WCAG AA). Large text ≥ 3:1. |
| Dark mode | `prefers-color-scheme: dark` handled. Use CSS custom properties, not hardcoded values. |
| Semantic roles | Define: `--color-primary`, `--color-background`, `--color-text`, `--color-muted`, `--color-border`, `--color-destructive`. |
| Gradients | Subtle. Never more than 2 stops. Avoid full-saturation endpoints. |

```css
/* Premium dark palette example */
:root {
  --color-bg: hsl(224, 14%, 10%);
  --color-surface: hsl(224, 12%, 14%);
  --color-border: hsl(224, 10%, 20%);
  --color-text: hsl(0, 0%, 93%);
  --color-muted: hsl(224, 8%, 55%);
  --color-primary: hsl(243, 75%, 65%);
  --color-primary-hover: hsl(243, 75%, 72%);
}
```

---

### Layer 3: Spacing & Layout

| Check | Rule |
|-------|------|
| Spacing scale | Use 4px base: `4/8/12/16/20/24/32/40/48/64/80/96px`. No arbitrary values. |
| Whitespace | Generous. When in doubt, add more. Cramped = amateur. |
| Alignment | Grid-based. No pixel-pushed elements. |
| Border radius | Consistent scale: `4/6/8/12/16/24px` or `full`. Never mix randomly. |
| Max widths | Prose: `65ch`. Containers: `1280px` or `1440px`. |
| Z-index | Named layers: `--z-base: 0`, `--z-dropdown: 10`, `--z-modal: 20`, `--z-toast: 30`. |

---

### Layer 4: Visual Polish

| Check | Rule |
|-------|------|
| Shadows | Layered shadows, not single hard drops. Use `box-shadow` stacks. |
| Borders | `1px solid var(--color-border)`. Never `border: 1px solid black`. |
| Images | Always set `width`/`height`. Use `object-fit: cover`. Alt text required. |
| Icons | Consistent weight (20px/24px Lucide or Heroicons). Never mix icon libraries. |
| Glassmorphism | `backdrop-filter: blur(12px)` + semi-transparent background. Use sparingly. |

```css
/* Premium shadow stack */
.card {
  box-shadow:
    0 1px 2px hsl(0 0% 0% / 0.06),
    0 4px 8px hsl(0 0% 0% / 0.08),
    0 12px 24px hsl(0 0% 0% / 0.06);
  border: 1px solid var(--color-border);
  border-radius: 12px;
}
```

---

### Layer 5: Motion & Interaction

**→ Invoke `emil-kowalski-design` skill for full animation audit.**

Quick summary:
- All animations ≤300ms, `transform`/`opacity` only, custom `cubic-bezier`
- Every button has `:active` scale feedback
- `prefers-reduced-motion` supported
- Hover states on all interactive elements

---

### Layer 6: Accessibility (WCAG AA Minimum)

| Check | Rule |
|-------|------|
| Contrast | ≥4.5:1 for normal text, ≥3:1 for large text/UI components |
| Keyboard | All interactive elements reachable by `Tab`. Logical order. |
| Focus | `:focus-visible` ring always present. Never `outline: none` without replacement. |
| Semantics | Buttons are `<button>`, links are `<a>`. No `div` onClick as interactive. |
| ARIA | Labels on icon-only buttons. `role` on custom widgets. `aria-live` on dynamic regions. |
| Form labels | Every input has a `<label>`. `autocomplete` set on common fields. |

---

## Self-Review Gate (MANDATORY)

Before declaring any design work complete, answer all:

- [ ] Would this fit on Stripe's marketing page without redesign? (Typography)
- [ ] Does every color pass WCAG AA contrast? (Color)
- [ ] Is whitespace generous — does it feel "breathable"? (Spacing)
- [ ] Do all interactive elements respond to hover AND active states? (Interaction)
- [ ] Is dark mode handled? (Theming)
- [ ] Are animations purposeful and ≤300ms? (Motion)
- [ ] Can a keyboard-only user operate everything? (Accessibility)
- [ ] Are there any hardcoded colors/sizes breaking the design system? (Consistency)

If ANY answer is "no" — fix before closing.

---

## Premium Design Heuristics

These are the invisible rules that separate good from extraordinary:

1. **The 10-foot test** — Step back (or zoom out). If the visual hierarchy isn't obvious at distance, it needs work.
2. **The grayscale test** — Remove color. Does the layout still communicate priority? If not, you're relying on color to do hierarchy's job.
3. **The finger test** — On mobile, can you tap every target with a fat thumb? Min 44×44px touch target.
4. **The squint test** — Blur your eyes. The most important element should still stand out.
5. **The empty state** — What does the UI look like with no data? Design it. It's often the first thing users see.

---

## CODEX Learning Gate

After completing design work, if you established:
- Project-specific design tokens or palette
- Typography choices or scale
- Component patterns (card style, modal style, etc.)

→ Append a compact entry to `CODEX.md` under `## 💻 Mission Logs & Tactical Learnings`.
Format: `[DATE] - [Project] Design System — [Key decisions: palette, font, radius, etc.]`
