---
version: "1.0.0"
name: inno-media-design-system
description: High-polish, editorial, and tactile design system for InnoMedia. Anchors on an Obsidian canvas with elevated Slate surfaces, Electric Crimson primary CTAs, Cyber Neon secondary highlights, and tight Plus Jakarta Sans typography. Eliminates AI slop tropes (purple gradients, nested cards, unstyled inputs) in favor of restrained modern luxury and tactile micro-interactions.

colors:
  # Canvases & Surfaces
  canvas: "#090C10"
  surface: "#131822"
  surface-elevated: "#1C2333"
  surface-overlay: "#CC0D111A"
  
  # Borders & Dividers
  hairline: "#263044"
  hairline-soft: "#1AFFFFFF"
  border-focus: "#6366F1"
  
  # Brand Accents
  primary: "#FF3366"
  primary-active: "#E02856"
  primary-light: "#FF6B8B"
  secondary: "#6366F1"
  secondary-light: "#818CF8"
  accent-cyan: "#06B6D4"
  
  # Typography Inks (Never pure untinted gray)
  ink-primary: "#F8FAFC"
  ink-secondary: "#94A3B8"
  ink-muted: "#64748B"
  on-primary: "#FFFFFF"
  
  # Status
  success: "#10B981"
  warning: "#F59E0B"
  error: "#EF4444"

typography:
  display-xl:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 32px
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: -1.0px
  display-lg:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 26px
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: -0.8px
  headline-lg:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 22px
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: -0.5px
  headline-md:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.35
    letterSpacing: -0.3px
  title-lg:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: -0.2px
  body-lg:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0.1px
  body-md:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0.1px
  body-sm:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0.2px
  label-lg:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: 0.3px
  caption-uppercase:
    fontFamily: "Plus Jakarta Sans, sans-serif"
    fontSize: 11px
    fontWeight: 700
    lineHeight: 1.4
    letterSpacing: 1.2px

rounded:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  pill: 9999px
  full: 9999px

spacing:
  xxs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  xxl: 32px
  section: 48px

components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.lg}"
    height: 52px
    shadow: "0 4px 16px rgba(255, 51, 102, 0.35)"
  button-secondary:
    backgroundColor: "{colors.surface-elevated}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.lg}"
    border: "0.8px solid {colors.hairline}"
    height: 48px
  card-feed:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-primary}"
    rounded: "{rounded.xl}"
    border: "0.8px solid {colors.hairline}"
    padding: "{spacing.md}"
  text-input:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-primary}"
    typography: "{typography.body-lg}"
    rounded: "{rounded.lg}"
    border: "1.0px solid {colors.hairline}"
    borderFocus: "1.5px solid {colors.border-focus}"
    borderError: "1.2px solid {colors.error}"
    padding: "16px 18px"
  story-ring:
    gradient: "sweep-gradient(#FF3366, #FF8A00, #E040FB, #6366F1)"
    size: 68px
    avatarSize: 58px
    separator: "2.0px solid {colors.canvas}"
  reels-action-bar:
    textColor: "#FFFFFF"
    iconSize: 28px
    discSize: 44px
    spacing: 20px
  bottom-nav:
    backgroundColor: "{colors.surface}"
    borderTop: "0.8px solid {colors.hairline}"
    activeColor: "{colors.primary}"
    inactiveColor: "{colors.ink-muted}"
    height: 60px
---

# InnoMedia Design System Specification

## 1. Atmosphere & Visual Ethos
InnoMedia's visual identity balances **editorial precision** and **tactile mobile responsiveness**. The design language draws direct inspiration from modern high-taste engineering tools (Linear, Raycast, Cosmos) rather than standard template apps.

### Core Tenets:
1. **Obsidian Foundation**: Deep `#090C10` background establishes maximum contrast without eye strain.
2. **Restrained Color Voltage**: Electric Crimson (`#FF3366`) is reserved strictly for primary actions, liked states, and active focal points. It is never diluted into random gradient backdrops.
3. **Tinted Grays Only**: We never use pure untinted gray (`#808080`) or pure harsh black (`#000000`). All secondary and muted inks are tinted with slate and blue-gray undertones (`#94A3B8`, `#64748B`).
4. **Hairline Precision**: Card boundaries and dividers use crisp `0.8px` hairline strokes (`#263044`) instead of heavy, muddy drop shadows.

## 2. Motion & Micro-Interactions
- **Tap Physics**: Every button and touch target uses physics-based spring scaling (`0.95 -> 1.0`) with light haptic feedback (`TactileBounce`).
- **Heart Bursts**: Double-tapping post images or reel videos triggers a 3-stage animated heart explosion with rotation and glow (`CurveTween(curve: Curves.easeOutBack)`).
- **Reel Vinyl Disc**: Continuous subtle 360° rotation simulating an analog audio record.
- **Dynamic Field Disclosures**: Conditional form fields (`visibleIf`) animate into view using `AnimatedSize(curve: Curves.easeInOut)`.

## 3. Strict Anti-Patterns
- ❌ **No AI Slop Gradients**: No purple-to-blue linear gradients washed across screen backgrounds.
- ❌ **No Unstyled Form Inputs**: No default underline inputs or gray boxes without focus states.
- ❌ **No Nested Cards**: Do not nest cards inside cards. Use clean spacing and dividers.
- ❌ **No Unhandled Overflow**: Every label, caption, username, and filename must have explicit truncation with ellipsis.
