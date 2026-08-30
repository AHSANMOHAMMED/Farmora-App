# Farmora

> **Farmora** is a role-based agricultural marketplace for farmers, buyers, transport providers, and administrators.

Farmora connects the complete produce journey:

`Farmer lists produce -> Buyer orders -> Transport provider delivers -> Buyer verifies and reviews`

The application is built with Flutter and Firebase. The visual experience follows the Stitch **Agri-Modernism** design system, while authentication, authorization, inventory, orders, verification, notifications, and delivery transitions are enforced by Firebase services.

## Demo At A Glance

| Icon | Role | What the user can do |
| --- | --- | --- |
| 🌾 | Farmer | Create produce listings, manage stock, accept orders, upload verification documents, and view earnings. |
| 🛒 | Buyer | Browse produce, search by category, add items to a cart, place orders, track delivery, scan barcodes, review purchases, and open disputes. |
| 🚚 | Transport provider | View available jobs, accept eligible deliveries, update pickup and transit status, and review delivery history. |
| 🛡️ | Administrator | Review users and verification documents, inspect logistics, manage platform settings, and seed development data. |

### Demo Flow

1. Launch the app and complete the splash/onboarding screens.
2. Select **Farmer**, **Buyer**, or **Transport provider**.
3. Register with a phone number and password, or use the configured Google/Phone OTP provider.
4. Sign in again with the same credentials.
5. The app loads the user profile from Firestore and opens only that user’s role dashboard.
6. Complete the role workflow shown above.

**Important:** A signed-in user cannot switch to another role. The role belongs to the Firebase user profile and is used for both navigation and backend authorization. Administrator accounts must be provisioned by an authorized operator; they are not available through public registration.

## Feature Map

### Authentication and accounts

- Firebase email/password authentication using a normalized phone-based account identifier.
- Firebase Phone OTP login and registration.
- Google sign-in where the platform provider is enabled.
- UID-based Firestore profiles.
- Role-specific routing after the profile is loaded.
- Profile photo upload and language preference persistence.
- Sign-out clears active listeners and push-token subscriptions.

### Farmer experience 🌾

- Stitch-designed farmer dashboard.
- Product creation with name, category, description, quantity, unit, price, availability, location, and media.
- Server-side validation for verified farmers.
- Firestore-backed stock pause/resume and product deletion.
- Incoming order management and valid order transitions.
- Verification document upload to Firebase Storage.
- Earnings and completed-order views.

### Buyer experience 🛒

- Public produce catalogue with category filtering and search.
- Product details and cart.
- Server-side order creation and inventory reservation.
- Order detail and delivery timeline.
- Barcode verification after delivery.
- Review submission for delivered orders.
- Order-scoped dispute creation.

### Transport experience 🚚

- Available delivery jobs.
- Job detail view.
- Trusted acceptance and delivery state transitions.
- Active delivery and history screens.
- Buyer/farmer order status synchronization.

### Administrator experience 🛡️

- User management view.
- Verification review workflow.
- Logistics overview.
- Backend-controlled maintenance mode.
- Backend-controlled platform fee and session timeout settings.
- Development database seeding.

### Notifications 🔔

- Firestore notification records.
- Notification list with read/unread state.
- FCM device-token registration and refresh handling.
- Server-side push notification for new orders.
- Invalid device tokens are removed automatically.

### PayHere 💳

PayHere is intentionally **skipped for now** because merchant credentials are not available. Existing checkout/webhook code is scaffolded but must not be treated as production payment functionality until credentials, webhook validation, idempotency, refunds, reconciliation, and legal escrow decisions are supplied.

## Architecture

```mermaid
flowchart TD
    A[Flutter App] --> B[Firebase Auth]
    A --> C[FarmoraState]
    C --> D[FirestoreService]
    D --> E[Cloud Functions]
    D --> F[(Firestore)]
    D --> G[(Firebase Storage)]
    E --> F
    E --> H[Firebase Cloud Messaging]
    H --> A
    E --> I[Trusted state validation]

    J[Farmer] --> A
    K[Buyer] --> A
    L[Transport provider] --> A
    M[Administrator] --> A
```

### Client layers

| Layer | Location | Responsibility |
| --- | --- | --- |
| App shell | `lib/app.dart`, `lib/main.dart` | Firebase initialization, theme, splash, and auth gate. |
| Role state | `lib/providers/farmora_state.dart` | Profile loading, role routing, scoped listeners, cart, and UI state. |
| Auth | `lib/core/services/firebase_auth_service.dart` | Password, Google, Phone OTP, profile creation, and profile loading. |
| Firebase adapter | `lib/services/firebase_service.dart` | Firestore streams, Storage uploads, callable Functions, notifications, and settings. |
| Feature screens | `lib/features/` | Stitch-aligned farmer, buyer, transporter, admin, profile, onboarding, and notification flows. |
| Shared UI | `lib/core/` | Colors, theme, logo, cards, status chips, and reusable widgets. |

### Backend layers

| Layer | Location | Responsibility |
| --- | --- | --- |
| Callable Functions | `functions/src/index.ts` | Validate identity, roles, money, stock, state transitions, reviews, disputes, settings, and device tokens. |
| Firestore rules | `firestore.rules` | Enforce private reads, ownership, participant access, immutable trusted writes, and admin access. |
| Storage rules | `storage.rules` | Restrict uploads by owner, path, size, and content type. |
| Indexes | `firestore.indexes.json` | Support scoped product, order, transport, and notification queries. |
| Hosting | `firebase.json`, `web/` | Flutter Web hosting, caching, robots, sitemap, and SEO metadata. |

## Role and Security Model

1. Firebase Authentication identifies the user.
2. The app loads `users/{authUid}` before displaying a dashboard.
3. The profile’s `role` selects exactly one role navigation tree.
4. Local role changes are ignored after authentication.
5. Cloud Functions re-check authentication, role, suspension, ownership, and workflow state.
6. Firestore rules deny direct writes for orders, messages, reviews, disputes, barcodes, audit logs, and trusted admin workflows.
7. Money uses integer minor units such as `priceMinor` and `totalMinor`.
8. Order creation reserves inventory inside a Firestore transaction.

### Supported role states

```text
Public registration: farmer | buyer | transporter
Admin: operator-provisioned only
```

### Order and delivery states

```text
Order: pending -> confirmed -> assigned -> pickedUp -> inTransit -> delivered
                         \-> rejected
                         \-> cancelled

Transport: requested -> accepted -> pickedUp -> inTransit -> delivered
                         \-> cancelled
```

## Backend Functions

| Function | Purpose |
| --- | --- |
| `setUserRole` | Provision a supported role and profile fields. |
| `createProduct` | Validate a verified farmer listing. |
| `createOrder` | Validate a buyer order, calculate totals, and reserve stock atomically. |
| `transitionOrder` | Apply authorized order transitions. |
| `transitionTransport` | Apply authorized delivery transitions. |
| `submitVerification` | Create a verification document submission. |
| `reviewVerification` | Approve or reject verification as an administrator. |
| `sendMessage` | Store order-scoped ciphertext only. |
| `registerDeviceToken` / `unregisterDeviceToken` | Manage FCM device tokens securely. |
| `getPlatformSettings` / `updatePlatformSettings` | Read and update admin settings. |
| `issueBarcode` / `verifyBarcode` | Issue and verify delivery authenticity codes. |
| `submitReview` | Accept a review only for an eligible delivered order. |
| `openDispute` | Open an authorized order dispute. |
| `releaseEscrow` | Release an eligible payment record after delivery review. |
| `createPayHereCheckout` / `payHereWebhook` | PayHere scaffold, disabled until credentials are available. |

## Project Structure

```text
lib/
  app.dart                         App shell and theme
  main.dart                        Firebase initialization
  core/                            Auth, theme, colors, shared widgets
  features/auth/                   Welcome, role selection, login, registration, OTP
  features/farmer/                 Products, orders, verification, earnings
  features/buyer/                  Catalogue, cart, orders, tracking, barcode
  features/transporter/            Jobs, active delivery, history
  features/admin/                  Users, logistics, settings, dashboard
  features/notifications/          Firestore-backed notification UI
  features/profile/                Profile, language, fixed account role
  models/                          Product, order, role, transport, verification
  providers/                       FarmoraState and scoped listeners
  services/firebase_service.dart   Firestore, Storage, Functions, FCM adapter

functions/src/index.ts             Trusted Cloud Functions
firestore.rules                    Firestore authorization
storage.rules                      Storage authorization
firestore.indexes.json             Query indexes
firebase.json                      Firebase deployment configuration
stitch_export/                     Stitch HTML references, assets, and design system
android/                            Android build and signing configuration
web/                                Web metadata, sitemap, and robots policy
test/                               Flutter widget and UI tests
```

## Requirements

- Flutter stable `3.35.0` or compatible.
- Dart `3.9.x` or compatible with the project SDK constraint.
- Android SDK API 36.
- Java 17 for CI and Android builds.
- Node.js 18 for Cloud Functions.
- Firebase CLI for deployment and emulator work.
- A configured Firebase project for live mode.

## Run Locally

From the repository root:

```bash
flutter pub get
flutter run
```

Run the standard checks:

```bash
dart format lib test
flutter analyze
flutter test
git diff --check
```

Build Cloud Functions:

```bash
cd functions
npm ci
npm run build
cd ..
```

Build an Android release locally:

```bash
cd android
./gradlew assembleRelease
```

If Firebase is unavailable, the app can show local/demo state. Demo state is for UI demonstration only and is not a production data or security mode.

## Firebase Setup

The configured project alias is `farmora-1da5` in `.firebaserc`.

```bash
firebase login
firebase use farmora-1da5
```

Enable these Firebase services before live testing:

1. Authentication: Email/Password, Phone, and Google as required.
2. Firestore Database.
3. Cloud Storage.
4. Cloud Functions.
5. Cloud Messaging.

Deploy Functions, rules, and indexes:

```bash
cd functions
npm ci
npm run build
cd ..
firebase deploy --only functions,firestore
```

Deploy Flutter Web hosting:

```bash
flutter build web
firebase deploy --only hosting
```

### FCM platform setup

- Android: register the app, add SHA-1/SHA-256 fingerprints, and enable notification permission on Android 13+.
- iOS: upload an APNs key/certificate and enable Push Notifications capability.
- Web: configure a Firebase Web Push VAPID key and pass it to the messaging web setup.

### Firebase IAM blocker

Deployment requires the operator account to have `serviceusage.services.use` and the required Firebase project roles. If deployment fails with a permission error, ask the project owner to grant the required IAM role rather than weakening rules or committing credentials.

## Tests And CI

GitHub Actions runs on `main`, `suka`, and `dev/swami`, and on pull requests targeting `main`.

The workflow validates:

1. Flutter dependency installation.
2. Static analysis.
3. Flutter tests.
4. Cloud Functions TypeScript compilation.
5. Temporary CI Android signing.
6. Release APK compilation.

Latest verified main-branch CI: [33318125543](https://github.com/AHSANMOHAMMED/Farmora-App/actions/runs/33318125543).

## Production Checklist

### Can be completed without PayHere

- Configure App Check, managed secrets, structured logs, alerts, backups, crash reporting, and performance monitoring.
- Add Firebase Emulator tests for every allow/deny rule path.
- Add cursor pagination and listener lifecycle tests.
- Replace map placeholders with Google Maps, permissions, consent, route display, and live location.
- Complete English, Sinhala, and Tamil string externalization and QA.
- Complete client-side Signal-compatible key generation, storage, rotation, verification, and message exchange.
- Add offline retry, loading, empty, and error states to every network screen.
- Add KYC, consent, privacy, terms, account deletion, and data export flows.
- Add transport matching, capacity rules, provider earnings, moderation, reporting, and audit UI.
- Validate all role paths on physical Android and iOS devices.

### PayHere intentionally deferred

- Merchant credentials.
- Production webhook secret and provider verification.
- Idempotent payment attempts.
- Refund and reconciliation workflows.
- Escrow/legal approval.

### Never commit

- `android/key.properties`.
- Release keystores.
- Firebase service-account JSON files.
- PayHere credentials or webhook secrets.
- Private encryption keys.

## Design References

The Stitch source material is preserved in `stitch_export/`:

- `stitch_export/design_system/Agri-Modernism.md` contains the visual language.
- `stitch_export/html/` contains the original screen references.
- `stitch_export/images/` contains the design assets used by the Flutter UI.

The Flutter implementation is the source of truth for behavior. Stitch references guide layout, typography, color, imagery, and interaction intent; Firebase Functions and security rules are the source of truth for authorization and business logic.

## Academic Context

Farmora is an educational project for **SE3050 - User Experience Engineering at SLIIT**, Group ID **Y3S2-NU-WE-02**.

Use `FARMORA_FULL_BUILD_SPEC.md` for the original long-term product specification. This README describes the current merged `main` branch and its remaining production work.
