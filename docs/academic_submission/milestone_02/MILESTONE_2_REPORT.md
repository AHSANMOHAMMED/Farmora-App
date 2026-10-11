# SLIIT Department of Software Engineering - Faculty of Computing
## Mobile Application Project: Farmora
### Milestone 2: Interactive High-Fidelity Prototyping & Design System (LO3)

---

## 1. Prototype Scope & Objectives
The primary objective of Milestone 2 (Lab 07) is to transform low-fidelity wireframes into an interactive, high-fidelity digital prototype adhering strictly to Material Design 3 (M3) and agricultural usability principles.

---

## 2. Design System & Style Guide

### 2.1 Color Palette
- **Primary Brand (Agri Green):** `#2E7D32` (Represents vitality, nature, harvest prosperity)
- **Primary Container / Accent:** `#E8F5E9` (Soft contrast for card backgrounds)
- **Secondary (Harvest Gold/Orange):** `#F57C00` (Highlights alerts, urgency, pending escrow)
- **Neutral Dark (Text/Headers):** `#1E293B` (High legibility on sunlight screens)
- **Neutral Light (Surface):** `#F8FAFC` (Clean, non-distracting backgrounds)
- **Danger / Temperature Alert:** `#D32F2F` (Cold storage breaches, expired verification)

### 2.2 Typography
- **Primary English/Latin:** Google Inter & Poppins (Weights: 400 Regular, 500 Medium, 600 SemiBold, 700 Bold)
- **Sinhala Localization:** Noto Sans Sinhala (Full Unicode rendering support)
- **Tamil Localization:** Noto Sans Tamil (Full Unicode rendering support)

### 2.3 Micro-interactions & Haptic Feedback
- **Pull-to-refresh:** Custom leaf-sprout animation indicating live market price updates.
- **Haptic Click:** Confirms barcode scanning and camera shutter actions in outdoor farm conditions.
- **Dynamic Chips:** Status indicators for `Order Status` (`Pending`, `In-Transit`, `Delivered`, `Disputed`).

---

## 3. High-Fidelity Screen Architecture & Key Interactions

### 3.1 Onboarding & Multi-Role Authentication
- Seamless phone OTP login alongside biometric (Fingerprint/Face ID).
- Dedicated role switcher: **Farmer**, **Wholesale Buyer**, **Transporter / Fleet Owner**, and **Agri Expert**.
- Role-specific color accents to avoid cognitive confusion when switching roles.

### 3.2 Farmer Hub & Smart Harvest Publishing
- Clean, stepped wizard for listing crops.
- Real-time video recording & Cloudinary video hosting integration.
- Barcode/QR generator rendering unique traceability hash `FARM-BATCH-<ID>`.
- Live farm weather widget with micro-climate rain alerts.

### 3.3 Buyer Direct Marketplace
- Category carousel: *Leafy Greens*, *Root Crops*, *Fruits*, *Spices*, *Export Quality*.
- Product detail sheet featuring interactive video inspection: buyers preview harvest freshness recorded directly in the field before purchase.
- Escrow purchase breakdown: Commodity Price + Logistics Cost + Quality Guarantee Insurance.

### 3.4 Logistics Fleet Hub & Telematics
- Interactive Google Maps view rendering vehicle markers, depot pins, and transit polylines.
- Real-time Cold Storage Temperature Gauge (Target 2°C - 7°C) with automated breach alert.
- Fleet manager bottom sheets to dynamically configure Branch Depots, Vehicles, and Drivers.

---

## 4. Accessibility & Inclusive Design (WCAG 2.1 AA Compliance)
- **Contrast Ratios:** Text-to-background contrast exceeds 4.8:1 across all primary screens for outdoor visibility in Sri Lankan sunlight.
- **Minimum Tap Targets:** All buttons, FABs, and dropdown triggers comply with the 48x48dp minimum physical touch area.
- **Screen Reader Support:** Semantic labels applied to all icon buttons and graphic status indicators.
- **Multi-lingual Switcher:** Instant runtime switching between Sinhala, Tamil, and English with zero app reloads.
