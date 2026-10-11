# SLIIT Department of Software Engineering - Faculty of Computing
## Mobile Application Project: Farmora
### Milestone 6: Individual Contribution Logs & VIVA Preparation (All LOs)

---

## 1. Team Overview & Git Verification
- **Project Repository:** `https://github.com/AHSANMOHAMMED/Farmora-App.git`
- **Primary Branches:** `main`, `dev/swami`, `Kajana`, `suka`, `feature/ahsan-dev`

---

## 2. Individual Contribution Logs

### 2.1 Member 1: Ahsan Mohammed (Team Lead & Full-Stack Architect)
- **Designated Responsibilities:**
  - System architecture, Flutter Clean Architecture setup, Firebase Security Rules design.
  - Escrow payment lifecycle, PayHere integration, and multi-role administrative dispute moderation.
  - Harvest Barcode / QR cryptographic generation, Cloudinary video integration, and automated storage lifecycle.
  - Android release pipeline (Java 21 LTS, Gradle build scripts, ProGuard optimization) and Firebase Web PWA deployment.
- **Milestone-by-Milestone Contributions:**
  - *M1:* Formulated architecture specifications (`FARMORA_FULL_BUILD_SPEC.md`), defined persona requirements for Wholesale Buyers and Admins.
  - *M2:* Built core theming engine (Material 3), multi-role navigation controllers, and responsive layout foundations.
  - *M3:* Conducted secure design audit on Cloud Firestore rules; remediated RBAC vulnerabilities for financial settlements.
  - *M4:* Implemented buyer catalog, escrow locking/unlocking engine, video compression/streaming client, and release APK compilation.
  - *M5:* Designed business pitching deck, financial revenue models, and video pitch storyboards.
  - *M6:* Prepared comprehensive architecture documentation and VIVA defense guides.
- **Evidence / Git Commits:**
  - Commit `4b1395b`: `fix(fleet): add check for empty branches before adding vehicle or driver`
  - Commit `55bafbc`: `fix: address Copilot review — security, rules, timestamps, tracking`
  - Commit `edfa795`: `feat(admin): add Security Audit Trail, Treasury Escrow Settlements`

---

### 2.2 Member 2: Kajana S. (Farmer Operations & Crop Management UX)
- **Designated Responsibilities:**
  - Farmer dashboard, harvest creation forms, and crop health modules.
  - AI plant disease scanner client and agronomic tips integration.
  - Profile customization, localized language strings (Tamil/English), and farm plot management.
- **Milestone-by-Milestone Contributions:**
  - *M1:* Executed contextual inquiries with vegetable farmers; mapped the step-by-step harvest listing flow.
  - *M2:* Designed high-fidelity prototypes for the Farmer Home dashboard and field crop ledger.
  - *M3:* Moderated usability testing sessions with rural participants; gathered feedback on camera/video usability.
  - *M4:* Implemented `add_product_screen.dart`, plot ledger UI, and agricultural advice feed.
  - *M5:* Co-authored the Go-to-Market strategy focusing on agrarian community hubs in Jaffna and Central Province.
  - *M6:* Prepared contribution log and VIVA slides on agricultural UX patterns.
- **Evidence / Git Commits:**
  - Commit `715f288`: `Update profile screen`
  - Branch: `Kajana` / `kajana_task`

---

### 2.3 Member 3: Sureka (Suka) (Logistics & Transporter Fleet UX)
- **Designated Responsibilities:**
  - Transporter portal, dispatch tracking, and cold-chain monitoring.
  - Fleet management bottom sheets (Branch Depots, Vehicles, and Driver registration).
  - Telematics mapping views (Google Maps Flutter integration) and Proof-of-Delivery (POD) captures.
- **Milestone-by-Milestone Contributions:**
  - *M1:* Conducted research on third-party agricultural freight operators; identified deadhead mileage issues.
  - *M2:* Prototyped interactive fleet telematics dashboards and cold-storage alert cards.
  - *M3:* Tested fleet registration flows; identified edge cases where empty branch lists caused unhandled UI exceptions.
  - *M4:* Built `logistics_fleet_hub_screen.dart`, `vehicle_maintenance_sheet.dart`, and GPS location listeners.
  - *M5:* Designed marketing materials targeting freight fleet owners and transport logistics syndicates.
  - *M6:* Prepared VIVA defense documentation regarding Google Maps telematics and cold-chain compliance.
- **Evidence / Git Commits:**
  - Commit `9dc6103`: `transportor ui`
  - Branch: `suka`

---

## 3. Individual Self-Reflection Templates (One-Page Signed Form)

*(Each student will print, review, sign, and hand over to the evaluation panel during VIVA).*

### Template Structure:
```
================================================================================
                    INDIVIDUAL SELF-REFLECTION REPORT
                  Department of Software Engineering, SLIIT
================================================================================
Student Name: ____________________________________   Student ID: _______________
Assigned Role: ___________________________________   Group Name: Farmora
--------------------------------------------------------------------------------

1. Specific Contributions Across Milestones:
   [Detailed breakdown of personal architectural, coding, UI, or testing tasks]

2. Technical & Practical Challenges Faced:
   [How issues such as empty state errors, multi-platform builds, or Firebase rules were solved]

3. New Skills Learned & Applied:
   [Flutter/Dart state management, asynchronous streams, IoT cold-chain concepts, Material 3]

4. What I Would Do Differently in Retrospect:
   [e.g., Implementing end-to-end integration tests earlier, conducting wider field trials]

--------------------------------------------------------------------------------
Student Signature: ____________________________        Date: ___________________
================================================================================
```

---

## 4. Comprehensive VIVA Defense & Q&A Preparation

Be prepared to answer these critical questions during the individual and group evaluation:

### Q1: Why did you choose Flutter over React Native or Native development?
> **Answer:** Flutter compiles directly to native ARM machine code using the Impeller/Skia engine, eliminating the JavaScript bridge bottleneck. This ensures consistent 60+ FPS animations during heavy Google Maps telematics and camera barcode scanning. Crucially, Flutter allowed our team to maintain a single unified codebase that runs seamlessly as an Android APK and a Progressive Web App (PWA) with zero code duplication.

### Q2: How does the system protect farmer funds and prevent buyer fraud?
> **Answer:** We implemented a two-sided Escrow payment engine. When a buyer orders, funds are deposited into a secure escrow account managed via Cloud Firestore security rules. Payment is never released immediately. Only after the transporter delivers the goods, the buyer scans the tamper-evident batch QR code, and photographic Proof-of-Delivery is submitted, the escrow unlocks and credits the farmer within seconds.

### Q3: How do you handle cold-chain perishable failures during transit?
> **Answer:** The Transporter Fleet Hub streams IoT temperature sensor data directly into Firestore. If refrigerated truck temperature breaches safe agricultural thresholds (e.g. rising above 7°C for leafy greens), the system triggers an immediate push notification alert and logs a permanent breach flag on the batch ledger, allowing the buyer to inspect or dispute before escrow settlement.

### Q4: How is data synchronized in rural areas with poor cellular coverage?
> **Answer:** We configured Cloud Firestore with offline persistence enabled. When farmers or drivers enter rural valleys without internet, they can continue recording harvests, logging fleet records, and taking POD photos locally. The Flutter client queues mutations in local cache and automatically syncs to the cloud the moment network connectivity resumes.
