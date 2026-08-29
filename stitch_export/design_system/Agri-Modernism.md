---
name: Agri-Modernism
colors:
  surface: '#f4faff'
  surface-dim: '#cfdce4'
  surface-bright: '#f4faff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#e9f6fd'
  surface-container: '#e3f0f8'
  surface-container-high: '#ddeaf2'
  surface-container-highest: '#d7e4ec'
  on-surface: '#111d23'
  on-surface-variant: '#3f4a3c'
  inverse-surface: '#263238'
  inverse-on-surface: '#e6f3fb'
  outline: '#6f7a6b'
  outline-variant: '#becab9'
  surface-tint: '#006e1c'
  primary: '#006e1c'
  on-primary: '#ffffff'
  primary-container: '#4caf50'
  on-primary-container: '#003c0b'
  inverse-primary: '#78dc77'
  secondary: '#7a5649'
  on-secondary: '#ffffff'
  secondary-container: '#fdcdbc'
  on-secondary-container: '#795548'
  tertiary: '#596055'
  on-tertiary: '#ffffff'
  tertiary-container: '#969d90'
  on-tertiary-container: '#2e352b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#94f990'
  primary-fixed-dim: '#78dc77'
  on-primary-fixed: '#002204'
  on-primary-fixed-variant: '#005313'
  secondary-fixed: '#ffdbcf'
  secondary-fixed-dim: '#ebbcac'
  on-secondary-fixed: '#2e150b'
  on-secondary-fixed-variant: '#603f33'
  tertiary-fixed: '#dee5d6'
  tertiary-fixed-dim: '#c2c9bb'
  on-tertiary-fixed: '#171d14'
  on-tertiary-fixed-variant: '#42493e'
  background: '#f4faff'
  on-background: '#111d23'
  surface-variant: '#d7e4ec'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  button-text:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  touch-target: 48px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style

The design system is built on a foundation of **Modern Minimalism** infused with **Tactile Utility**. It is designed for agricultural professionals who require a high-efficiency tool that feels reliable and calm in a high-stakes environment. 

The aesthetic prioritizes high-contrast legibility and substantial whitespace to reduce cognitive load during field operations. The interface uses subtle environmental cues—such as organic curves and earthy accents—to create a sense of harmony between digital management and physical labor. The emotional goal is to evoke a feeling of "ordered growth": clean, systematic, and fertile.

## Colors

This design system utilizes a palette rooted in agricultural vitality.
- **Primary:** The "Soft Green" serves as the main action color, representing growth and health.
- **Secondary:** Earthy brown is reserved for grounding elements and secondary navigational cues.
- **Tertiary:** A very light mint-white used for large surface areas to provide a softer alternative to pure white, reducing eye strain in outdoor lighting.
- **Neutrals:** Deep blue-greys are used for text and iconography to ensure maximum readability against light backgrounds.
- **Semantic Colors:** High-saturation tones are used for status chips to ensure immediate recognition of operational states (Pending, Accepted, Delivered, etc.).

## Typography

The design system uses **Inter** exclusively to leverage its exceptional legibility and neutral, systematic tone. 

- **Hierarchy:** Strong weight differentiation is used to separate data labels from user-generated values. 
- **Accessibility:** Minimum body size is locked at 14px for general information, with 16px preferred for critical operational data. 
- **Scale:** Headlines on mobile are aggressively capped to prevent text wrapping on smaller devices, ensuring that data tables and dashboards remain scannable.

## Layout & Spacing

The layout follows a **Fluid Grid** model optimized for handheld use in the field. 

- **Rhythm:** An 8px linear scale governs all padding and margins. 
- **Touch Targets:** All interactive elements (buttons, inputs, toggles) must adhere to a minimum height of `48px` to accommodate use with gloves or in outdoor environments.
- **Mobile First:** On mobile, the layout uses a single-column card stack with 16px side margins. On tablet and desktop, the layout transitions to a 12-column grid with content-heavy dashboards utilizing a 24px gutter.

## Elevation & Depth

Depth in this design system is expressed through **Tonal Layering** supplemented by **Ambient Shadows**.

1.  **Level 0 (Base):** The main background uses the Tertiary color (#F1F8E9) to provide a soft, non-glare surface.
2.  **Level 1 (Cards):** Pure white surfaces with a very soft, diffused shadow (Y: 4px, Blur: 12px, 5% opacity black). This creates a "lifted" effect that clearly separates content from the background.
3.  **Level 2 (Interactive):** Elements like active input fields or hovered cards gain a slightly more defined shadow (Y: 8px, Blur: 16px, 8% opacity) to indicate focus.

Avoid heavy borders; use light #E0E0E0 strokes only when cards are placed on white backgrounds.

## Shapes

The design system utilizes **Rounded** geometry to feel modern and accessible.
- **Standard Radius:** 8px (`rounded`) for small components like buttons and input fields.
- **Card Radius:** 16px (`rounded-xl`) for primary content containers to emphasize a friendly, soft aesthetic.
- **Chip Radius:** Always use fully rounded (pill-shaped) ends for status indicators to distinguish them from actionable buttons.

## Components

### Buttons
- **Primary:** Solid #4CAF50 background with white text. High-contrast, 48px height.
- **Secondary:** Transparent background with #4CAF50 border and text.
- **States:** 10% black overlay on press to provide immediate tactile feedback.

### Status Chips
- **Structure:** Pill-shaped, small caps bold text.
- **Colors:** 
  - *Pending:* Light Blue background, Dark Blue text.
  - *Accepted:* Light Green background, Dark Green text.
  - *Out of Stock:* Light Grey background, Dark Grey text.
  - *Error/Urgent:* Light Red background, Dark Red text.

### Cards
- Always use white backgrounds.
- 16px internal padding.
- 16px corner radius.
- Titles should use `headline-md` and be positioned at the top-left.

### Input Fields
- 56px height for "Large" inputs (optimized for mobile).
- 1px border (#E0E0E0) that thickens to 2px Primary Green on focus.
- Floating labels are preferred to maintain context in long forms.

### List Items
- Use 16px vertical padding for list items to ensure clear separation and easy tapping.
- Include a 1px divider between items, inset by 16px from the edges.
