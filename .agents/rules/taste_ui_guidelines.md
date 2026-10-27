# Taste Skill UI/UX Integration Guidelines (Leonxlnx/taste-skill)

This document establishes the UI design and aesthetic standards for the InnoMedia Flutter application, based on the **Taste Skill** framework (`Leonxlnx/taste-skill`).

## 1. Core Design Read
- **Product Category**: Next-generation Social Platform & JSON-Driven Form Engine
- **Target Audience**: Discerning tech-forward users, mobile developers, and interview evaluators
- **Core Emotional Tone**: High-polish, editorial, tactile, restrained modern luxury (inspired by Linear, Cosmos, and Threads)
- **Palette Identity**: Deep Obsidian & Graphite base (`#0A0D14`, `#121722`), crisp Slate secondary (`#94A3B8`), Vibrant Electric Crimson & Neon accents (`#FF385C`, `#6366F1`), and Ice-white high-contrast typography (`#F8FAFC`).

## 2. Tunable Dials
- **`DESIGN_VARIANCE: 8/10`**
  - Distinctive asymmetrical layouts and editorial metadata badges.
  - Floating pill navigation with frosted glass backdrop blur.
  - Custom story rings with multi-stop conic gradients and micro-glow.
- **`MOTION_INTENSITY: 7/10`**
  - Tactile button press interactions (scale-down spring response).
  - Double-tap heart burst animation with scale & rotation feedback.
  - Seamless vertical Reel transitions with auto-play/pause lifecycle.
  - Smooth animated expansions for conditional form fields (`visibleIf`).
- **`VISUAL_DENSITY: 4/10`**
  - Generous spatial breathing room (16–24dp content padding).
  - Fine 1px border strokes with subtle alpha (`Colors.white10` / `0x1AFFFFFF`) instead of heavy dropshadows.
  - Clear hierarchy: Headline (Bold 800) > Subheading (SemiBold 600) > Body (Regular 400).

## 3. Strict Anti-Slop Enforcements
- ❌ **No AI Slop Gradients**: Absolutely no generic purple-to-blue linear gradients washed over card backgrounds.
- ❌ **No Default Material-2 Controls**: No default blue square buttons, unstyled dropdown arrows, or default checkbox squares.
- ❌ **No Placeholder Content**: All posts, reels, stories, comments, and form defaults use rich, realistic editorial content.
- ❌ **No Cluttered Card Grids**: Clean vertical flow, distinct sectioning, and hairline card separators.

## 4. Typography Discipline
- Font Family: **Plus Jakarta Sans** (via `google_fonts`)
- Letter Spacing: Tight tracking on titles (`-0.5` to `-0.8`), standard on body (`0.1`), wide tracking on small uppercase tags (`+1.2`).
