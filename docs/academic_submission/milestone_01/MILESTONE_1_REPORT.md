# SLIIT Department of Software Engineering - Faculty of Computing
## Mobile Application Project: Farmora
### Milestone 1: UX Team Formation, User Research & Key Flows (LO1, LO2)

---

## 1. Project Title & Overview
**Project Name:** Farmora – AI-Powered Smart Agricultural Ecosystem & Traceable Supply Chain  
**Domain:** AgriTech / Supply Chain & Digital Marketplaces  
**Target Region:** Sri Lanka (Western, Central, North-Western & Northern Provinces)  
**App Type:** Cross-Platform Mobile & Progressive Web Application (Flutter + Firebase Serverless)  

---

## 2. UX Team Formation & Roles (Lab 01 & Lab 02)
To satisfy the semester lab requirements, team members took ownership of distinct user experiences:

| Member Name | Student ID | Designated UX Role | Focus Modules & Responsibilities |
| :--- | :--- | :--- | :--- |
| **Ahsan Mohammed** | ITXXXXXXX (Lead) | Lead Architect & Admin/Buyer UX | Overall system architecture, Buyer procurement flows, Escrow payments, Barcode tracking, Admin moderation. |
| **Kajana S.** | ITXXXXXXX | Farmer Operations & Agronomy UX | Farmer registration, Harvest listing, AI Disease scanner, Plot IoT monitoring, Crop planning. |
| **Sureka (Suka)** | ITXXXXXXX | Logistics & Transporter UX | Transporter dispatching, Fleet Hub, Cold storage tracking, GPS routing, Proof-of-delivery (POD). |
| **Team Member 4** | ITXXXXXXX | UX Research & QA Lead | Usability benchmarking, Accessibility (WCAG 2.1 AA), Multi-lingual localization (Sinhala/Tamil/English). |

---

## 3. User Groups & Persona Identification (Lab 03)

### Persona 1: Sunimal Perera (Smallholder Farmer - Dambulla)
- **Age:** 48  
- **Context:** Operates a 2-acre vegetable farm; experiences 25-35% post-harvest spoilage and price exploitation by middlemen at economic centres.  
- **Digital Literacy:** Low-to-Medium (WhatsApp, YouTube, voice notes; struggles with complex text menus).  
- **Core Goals:** Fair market pricing without broker cartels; rapid harvest listing; agronomic disease detection without costly consultants.  
- **App Needs:** Simple 1-tap harvest logging, voice search, high-contrast visual cues, Sinhala/Tamil support, QR code traceability stickers.

### Persona 2: Sarah Mendis (Supermarket/Hotel Food Procurement Manager - Colombo)
- **Age:** 34  
- **Context:** Procures 1,500kg of fresh vegetables daily for retail distribution; requires grade-A consistency, timely delivery, and farm-to-shelf traceability.  
- **Digital Literacy:** High (Enterprise ERPs, mobile banking, inventory apps).  
- **Core Goals:** Verified quality grading, transparent cold-chain verification, escrow-protected payments, automated VAT invoicing.  
- **App Needs:** Bulk ordering, real-time dispatch tracking, digital certificates, escrow release on quality verification.

### Persona 3: Ruwan Bandara (Independent Fleet Transporter - Kurunegala)
- **Age:** 41  
- **Context:** Owns 2 refrigerated trucks (Reefers) and 1 light lorry; frequently returns empty on return trips (deadhead miles).  
- **Digital Literacy:** Medium (Google Maps, phone calls, SMS).  
- **Core Goals:** Optimize load capacity, minimize empty backhauls, monitor reefer temperature to prevent cargo rejection.  
- **App Needs:** Real-time cargo matching, clear turn-by-turn routing, instant digital Proof-of-Delivery (photo + signature).

---

## 4. User Research Methodology & Findings (Lab 04)

### Research Methodology:
- **Semi-structured Interviews:** 12 participants (5 Farmers in Dambulla/Nuwara Eliya, 4 Buyers/Wholesalers in Colombo/Pettah, 3 Transporters).
- **Contextual Inquiry:** Observed harvest packing and middleman negotiation at the Dambulla Dedicated Economic Centre.
- **Survey:** Distributed to 35 agricultural cooperative members via mobile forms.

### Key Pain Points Discovered:
1. **Opaque Pricing:** 83% of farmers reported receiving up to 40% less than Colombo retail price due to multi-tiered intermediaries.
2. **Cold-Chain Spoilage:** Over 28% of perishable produce degrades due to lack of temperature logging during transit.
3. **Payment Defaults:** Buyers and farmers experience trust deficits; farmers fear delayed payments, buyers fear substandard rot.
4. **Language Barrier:** Most agricultural apps are English-only, completely alienating local farmers.

---

## 5. Validated Key User Flows (Lab 05)

### Flow 1: Farmer Harvest Onboarding & Video Quality QR Generation
`[Farmer Log In]` ➔ `[Capture Harvest Photos/Video]` ➔ `[Auto-detect Grade & Price Guide]` ➔ `[Publish Batch]` ➔ `[Generate Batch QR Sticker]` ➔ `[Awaiting Buyer Purchase]`

### Flow 2: Buyer Direct Purchase & Escrow Settlement
`[Browse Verified Marketplace]` ➔ `[Inspect Video/Batch Audit]` ➔ `[Add to Cart & Select Delivery Option]` ➔ `[Deposit to PayHere/Escrow]` ➔ `[Real-Time Tracking]` ➔ `[Inspect at Delivery & Scan QR]` ➔ `[Release Escrow Funds to Farmer]`

### Flow 3: Transporter Fleet Allocation & Delivery POD
`[Dispatch Notification Received]` ➔ `[Select Vehicle & Driver]` ➔ `[Accept Route with Cold-Storage Parameters]` ➔ `[GPS Live Tracking]` ➔ `[Upload Delivery Photo & Recipient Signature]` ➔ `[Instant Payout Credited]`

---

## 6. Sketching & Low-Fidelity Wireframes (Lab 06)

Low-fidelity sketches and information hierarchy were designed covering:
1. **Adaptive Role-Based Dashboard:** Tailored navigation for Farmer, Buyer, Transporter, and Agri-Admin.
2. **Accessible Form Layouts:** Large touch targets (min 48dp), clear step progression, and voice input integration.
3. **Marketplace Matrix:** Card-based browse layout displaying grade, harvest timestamp, location, and verified badges.
4. **Fleet Telematics View:** Combined map and cold-storage temperature telemetry widget.
