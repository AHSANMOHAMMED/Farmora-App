# SLIIT Department of Software Engineering - Faculty of Computing
## Mobile Application Project: Farmora
### Milestone 4: Tech Stack Justification & Mobile App Implementation (LO1, LO4)

---

## Part 1: Tech Stack Justification

### 1. Architectural Options Comparison

| Evaluation Criteria | Option A: Flutter (Selected) | Option B: React Native | Option C: Native (Kotlin + Swift) |
| :--- | :--- | :--- | :--- |
| **Rendering Performance** | **High** (Skia/Impeller direct canvas rendering; rock-solid 60/120fps) | **Medium** (JavaScript bridge overhead; slower during complex canvas/map renders) | **Highest** (Native platform thread) |
| **Multi-Platform Support** | **Unified Codebase** (Android, iOS, Web PWA from a single codebase) | **High** (Mobile only; Web requires React Native for Web with high divergence) | **None** (Requires 2 entirely separate codebases and double team size) |
| **Team Skillset & Velocity** | **Rapid** (Hot reload, typed Dart, comprehensive widget library) | **Moderate** (Requires reconciling native bridge differences) | **Slow** (Split team between Swift & Kotlin, duplicate bug fixes) |
| **Accessibility (a11y)** | **Built-in** (Rich `Semantics` tree, native screen reader bindings) | **Good** (Requires third-party wrappers for advanced tags) | **High** (Native a11y APIs) |
| **Hardware & Camera APIs** | **Robust** (Direct Camera, QR scanner, GPS telematics plugins) | **Moderate** (Bridge lag can cause frame drops in barcode stream) | **High** (Full native access) |
| **Development Cost** | **Lowest** (1 codebase, 1 build pipeline, 1 QA cycle) | **Moderate** (Bridge debugging increases overhead) | **Highest** (Requires distinct Android and iOS specialists) |

### 2. Tech Stack Justification Rationale:
Flutter was selected because AgriTech users in Sri Lanka use diverse Android devices (from budget entry-level smartphones to modern flagships), alongside wholesale enterprise buyers accessing via desktop/tablet web browsers. Flutter provides:
1. **Identical Pixel-Perfect UI:** Zero layout discrepancies across different screen densities and aspect ratios.
2. **Offline-Ready Client Architecture:** Integrates seamlessly with Cloud Firestore offline caches and local SQLite/secure storage.
3. **High Productivity:** Hot Reload enabled the team to iterate rapidly during user testing in Milestone 3.

---

## Part 2: Implementation & Folder Architecture

### 1. Folder Structure (Clean Architecture Pattern)
```
lib/
├── core/
│   ├── constants/       # AppColors, ApiEndpoints, Strings
│   ├── network/         # Http & Cloudinary API clients
│   ├── services/        # FirebaseAuthService, GeolocationService
│   ├── theme/           # Material 3 light & dark themes
│   └── utils/           # Formatters, barcode helpers, image compression
├── features/
│   ├── admin/           # Escrow dispute management, user approvals
│   ├── auth/            # OTP verification, role switcher, onboarding
│   ├── buyer/           # Catalog, video inspection, checkout, escrow
│   ├── farmer/          # Harvest listing, disease detection, QR generator
│   └── transporter/     # Fleet Hub, depot manager, GPS tracking, POD
└── main.dart            # Multi-provider initialization, route registry
```

### 2. Version Control & Git Strategy
- **Repository:** Hosted on GitHub (`AHSANMOHAMMED/Farmora-App`).
- **Branching Model:** Feature-branch workflow with automated PR verification and strict branch protection on `main` and `dev/swami`.
- **Release Automation:** Continuous integration building automated Android APKs (`app-release.apk`) and continuous deployment to Firebase Web Hosting (`farmingapp-24b34.web.app`).

### 3. Requirements Traceability Matrix (RTM)

| Req ID | Requirement / User Story | Implementation Screen / Widget | Data Model / Backend Endpoint | Status |
| :--- | :--- | :--- | :--- | :--- |
| **REQ-01** | Multi-role user registration and role gating | `welcome_screen.dart`, `role_selection_screen.dart` | `users/{uid}` (role, isVerified) | **Verified** |
| **REQ-02** | Farmers can record video & upload harvests | `add_product_screen.dart` | `crops/{cropId}` + Cloudinary video API | **Verified** |
| **REQ-03** | Generate unique batch QR for harvest tracking | `batch_qr_dialog.dart`, `qr_flutter` | `qrCodeHash`, `storagePath` | **Verified** |
| **REQ-04** | Buyers inspect video and deposit to escrow | `product_detail_screen.dart`, `checkout_screen.dart` | `orders/{orderId}` (escrowStatus) | **Verified** |
| **REQ-05** | Transporters manage branch depots, vehicles, and drivers | `logistics_fleet_hub_screen.dart` | `transporters/{tid}/vehicles`, `branches` | **Verified** |
| **REQ-06** | Real-time Cold Storage telemetry & map tracking | `logistics_fleet_map_view.dart` | `cold_storage_logs`, `currentLat/currentLng` | **Verified** |
| **REQ-07** | Proof-of-delivery (photo + signature) on delivery | `order_dispatch_screen.dart` | `orders/{orderId}/podPhotoPath` | **Verified** |

### 4. Build Deliverables
- **Mobile Build:** Android Release APK located at `build/app/outputs/flutter-apk/app-release.apk` (Size: 99.3MB, compileSdk: 36, Java 21 LTS).
- **Web App URL:** [https://farmingapp-24b34.web.app](https://farmingapp-24b34.web.app)
- **Git Repository:** [https://github.com/AHSANMOHAMMED/Farmora-App.git](https://github.com/AHSANMOHAMMED/Farmora-App.git)
