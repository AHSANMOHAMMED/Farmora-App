# Farmora

Farmora is a Flutter agricultural marketplace connecting farmers, buyers, and transport providers. The app combines marketplace discovery, trusted order workflows, transport coordination, verification, and administrative oversight.

This repository is an MVP and production handoff. The main Flutter experience, Firebase data access, trusted Cloud Functions, security rules, tests, Android release configuration, and CI pipeline are present. Several integrations still require credentials, Firebase deployment permissions, or production hardening; those items are listed explicitly below.

## Branch and Handoff Status

The active branch is `dev/swami`. At the current handoff, `origin/main` is an ancestor of this branch and `dev/swami` is 30 commits ahead; there is no pending main-to-`dev/swami` merge required. The graph view can still show the historical `origin/main` label beside older commits because Git labels commits by ancestry, not by the current tip alone.

## Product Promise

- Farmers can list harvest, process orders, coordinate delivery, and view earnings.
- Buyers can discover produce, place orders, track delivery, review purchases, and raise disputes.
- Transport providers can view eligible delivery work, accept jobs, and update delivery state.
- Administrators can review users, verification, logistics, system settings, and marketplace activity.

## Current Status

| Area | Status | Current implementation |
| --- | --- | --- |
| Onboarding and authentication | Implemented | Splash, onboarding, role selection, email/password login and registration, sign-out, profile and language entry points. |
| Role-based experience | Implemented | Farmer, buyer, transporter, and administrator dashboards and screens. |
| Farmer marketplace | Implemented | Product creation, editing, deletion, availability, quantity, pricing, categories, orders, verification upload, and earnings UI. |
| Buyer marketplace | Implemented | Product browsing, product details, cart, order placement, order history, tracking timeline, barcode scanning, reviews, and complaints. |
| Transport workflow | Implemented | Available jobs, job details, acceptance, active delivery, delivery history, and valid delivery transitions. |
| Firebase client data | Implemented baseline | Firebase Auth, Firestore, Storage, and callable Functions adapters in `lib/services/firebase_service.dart`; primary list reads are now role-scoped and bounded. |
| Trusted backend | Implemented | Callable Functions validate product/order data, calculate totals, reserve inventory, transition orders and transport, issue/verify barcodes, accept reviews/disputes, and process verification decisions. |
| Security rules | Implemented baseline | `firestore.rules` and `storage.rules` restrict private records, ownership, uploads, messages, orders, disputes, reviews, and admin operations. Rules still need emulator test coverage and a production rules review. |
| Payments | Scaffolded | PayHere checkout and webhook endpoints exist. Merchant credentials, signature verification, payment state integration, and production testing remain. |
| Messaging | Partial | Order-scoped ciphertext submission exists. Client key management, real Signal protocol integration, conversation UI, pagination, read state, attachments, and abuse controls remain. |
| Notifications | Partial | Notification records can be created by backend workflows. FCM delivery, device tokens, preferences, and notification UI remain. |
| Maps and live tracking | Placeholder | Tracking and active-delivery screens contain map placeholders. Google Maps, location consent, live location, and provider matching remain. |
| Localization | Partial | Language selection UI exists, but all copy is not yet externalized into English, Sinhala, and Tamil resource files. |
| Release automation | Implemented baseline | GitHub Actions runs dependency installation, analysis, tests, Functions build, CI signing, and release APK build. |

## Traffic and Smooth-Operation Baseline

The app is designed to avoid the most dangerous early traffic pattern: every user receiving every collection in real time. Current protections include:

- Product, order, and transport streams use bounded queries with a default limit of 50 records.
- Farmer products are filtered by `farmerId`; farmer orders by `farmerId`; buyer orders by `buyerId`; transporter orders by `transporterId`.
- Transport providers receive only requested jobs and jobs already assigned to them; administrators can inspect the broader job list.
- User records are subscribed only by administrators and are bounded to 100 records.
- Order creation and inventory reservation use a Firestore transaction and server-side totals.
- Firestore composite indexes are defined for scoped product, order, and transport queries.
- Storage uploads enforce ownership, content type, and size limits.
- CI validates dependency resolution, static analysis, widget tests, Functions compilation, and release APK compilation.

This is a safe MVP baseline, not a traffic capacity guarantee. Firestore listeners, Cloud Functions concurrency, payment webhooks, image delivery, and Firebase quotas still need load testing with realistic traffic.

### Required scale work

- Replace fixed limits with cursor pagination and explicit `startAfterDocument` queries.
- Use a public catalogue query model with category/location/status filters and search indexing instead of downloading a broad catalogue.
- Remove unnecessary real-time listeners from screens that only need one-time reads; subscribe only while a screen is visible.
- Split admin dashboards into aggregate counters and paginated tables rather than loading whole collections.
- Add listener lifecycle tests, retry/backoff, offline cache policy, and cancellation on logout/navigation.
- Add idempotency keys to order creation and payment attempts; the current cart loop can issue multiple callable orders and does not yet provide an atomic multi-item checkout.
- Add Cloud Functions load tests, Firestore query-cost monitoring, quota alerts, cold-start measurement, and performance budgets.
- Compress/resize product media, use CDN-friendly URLs, lazy-load images, and configure image cache limits.
- Add FCM fan-out controls and notification deduplication before large-scale status events.
- Configure App Check, rate limits, managed secrets, backups, structured logging, and crash/performance monitoring.

## End-to-End Workflow

### 1. Registration and onboarding

1. The user opens Farmora and completes the splash and onboarding screens.
2. The user selects `Farmer`, `Buyer`, or `Transport Provider`.
3. The user registers or signs in with email and password.
4. The app routes the user to the role-specific dashboard.
5. A provider or farmer can submit identity documents from Account Verification.
6. An administrator reviews verification before restricted marketplace actions are treated as production-ready.

### 2. Farmer sells produce

1. A verified farmer creates a product with name, category, description, quantity, unit, price, availability, and location.
2. The product is visible in the buyer catalogue.
3. The farmer edits, pauses, resumes, or deletes only their own listing.
4. The farmer receives incoming orders and views item, buyer, amount, and status information.
5. The farmer confirms or rejects the order and coordinates transport.
6. Completed orders contribute to the farmer earnings view.

### 3. Buyer purchases produce

1. The buyer browses products and opens product details.
2. The buyer selects quantity and adds items to the cart.
3. Checkout calculates subtotal, delivery fee, and total through a trusted backend function.
4. The buyer creates an order through `createOrder`; inventory reservation and total validation are server-side.
5. The buyer follows order and delivery status from the order detail and tracking screens.
6. After delivery, the buyer can scan the delivery barcode, submit a review, or open a complaint/dispute.

### 4. Transport provider delivers

1. A provider views available delivery jobs.
2. The provider opens a job to inspect pickup, drop-off, cargo, route, and offered fee details.
3. The provider accepts an eligible job.
4. Delivery moves through the trusted state machine:

```text
Requested -> Accepted -> PickedUp -> InTransit -> Delivered
                         |
                         +----------------------> Cancelled
```

5. Each transition is validated by Cloud Functions and records actor/timestamp data.
6. The buyer and farmer can observe the order timeline.
7. Delivery completion enables review and future escrow release workflows.

### 5. Administrator operations

1. An administrator opens the admin dashboard.
2. User management supports oversight of accounts and roles.
3. Verification review supports approve/reject decisions.
4. Logistics management shows active delivery and order activity.
5. System settings provide the administrative configuration surface.
6. Production administration must additionally cover moderation, reports, disputes, audit logs, payments, support, and notification operations.

## Trusted Backend Workflows

Cloud Functions are in `functions/src/index.ts`. The client is not a security boundary; order money, inventory, permissions, and state transitions must be enforced here.

| Function | Responsibility |
| --- | --- |
| `setUserRole` | Set a user role through a trusted callable workflow. |
| `calculateOrderTotal` | Validate items and calculate server-side totals. |
| `createOrder` | Validate the buyer/order, reserve inventory, and create an order. |
| `createProduct` | Validate and create a farmer product. |
| `transitionOrder` | Apply valid order state changes. |
| `transitionTransport` | Apply valid transport state changes. |
| `submitVerification` | Submit identity verification metadata. |
| `reviewVerification` | Allow an administrator to approve or reject verification. |
| `sendMessage` | Store order-scoped ciphertext without persisting plaintext. |
| `createPayHereCheckout` | Create signed PayHere checkout data. |
| `payHereWebhook` | Receive payment provider notifications. |
| `releaseEscrow` | Release eligible funds after delivery/payment conditions. |
| `issueBarcode` / `verifyBarcode` | Issue and validate delivery completion codes. |
| `submitReview` | Accept a review only for an eligible completed order. |
| `openDispute` | Open a buyer/order dispute. |

## Firebase Data and Security

Configured Firebase project alias: `farmora-1da5a` in `.firebaserc`.

Main Firestore collections include:

- `users`
- `products`
- `orders`
- `transport_jobs`
- `transportJobs` for legacy/alternate job records
- `verification_docs`
- `reviews`
- `disputes`
- `barcodes`
- `messages`
- `conversations`
- `market_prices`
- `notifications`
- `audit_logs`

Security files:

- `firestore.rules`: private user/order data, participant access, farmer ownership, admin-only records, immutable trusted workflows, and message restrictions.
- `storage.rules`: user, product, and verification uploads with ownership, content-type, and size limits.
- `firebase.json`: Functions source, Firestore rules/indexes, and Firebase Hosting configuration.

Before production data is introduced, test both allowed and denied access for every role using the Firebase Emulator Suite. Firebase deployment currently requires the operator account to have the required project permissions, including `serviceusage.services.use`.

## Project Structure

```text
lib/
  app.dart                         Application shell and routing
  main.dart                        Firebase initialization and demo fallback
  models/                          Product, order, role, verification, and UI models
  providers/                       Farmora state and local fallback state
  services/firebase_service.dart   Firestore, Storage, and Functions adapter
  core/                            Theme, colors, widgets, auth services
  features/auth/                   Welcome, role selection, login, registration
  features/farmer/                 Products, orders, verification, earnings
  features/buyer/                  Catalogue, cart, orders, barcode, reviews
  features/transporter/            Jobs, active delivery, history
  features/admin/                  Users, logistics, settings, dashboard
  features/profile/                Profile, language, role controls

functions/src/index.ts             Trusted Firebase Cloud Functions
firestore.rules                    Firestore authorization rules
storage.rules                      Firebase Storage authorization rules
firestore.indexes.json             Firestore indexes
firebase.json                      Firebase project deployment configuration
android/                            Android Gradle and release signing setup
test/                               Flutter widget and UI tests
.github/workflows/flutter-ci.yml   CI and release APK validation
FARMORA_FULL_BUILD_SPEC.md         Original production specification/backlog
```

## Requirements

- Flutter stable `3.35.0` or compatible.
- Dart `3.9.x` or newer within the project SDK constraint.
- Android SDK API 36.
- Java 17 for CI and Android builds. Java 21 also works locally with the current Gradle setup.
- Node.js 18 for Cloud Functions. Newer Node versions may show an engine warning.
- Firebase CLI for deployment and emulator work.
- A configured Firebase project for non-demo operation.

## Local Development

From the repository root:

```bash
flutter pub get
flutter run
```

Recommended validation commands:

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
```

Run the Functions emulator:

```bash
cd functions
npm run serve
```

Build a local Android release APK:

```bash
cd android
./gradlew assembleRelease
```

The app can fall back to local/demo state when Firebase is not available. Demo fallback is useful for UI demonstrations only; it is not a production data or security mode.

## Firebase Deployment

Authenticate and select the configured project:

```bash
firebase login
firebase use farmora-1da5a
```

Deploy Functions:

```bash
cd functions
npm ci
npm run build
cd ..
firebase deploy --only functions
```

Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore
```

Deploy Hosting after generating the web build:

```bash
flutter build web
firebase deploy --only hosting
```

Do not deploy to production until provider credentials, rules tests, payment webhooks, App Check, backups, monitoring, and privacy/legal documents are ready.

## Web SEO

SEO metadata is defined in `web/index.html` and is included in Firebase Hosting builds:

- English document language, title, description, keywords, author, viewport, theme color, and crawler directives.
- Sinhala (`si`) and Tamil (`ta`) descriptions, keyword sets, Open Graph locale alternates, and crawler-readable fallback copy.
- `hreflang` alternates for English, Sinhala, Tamil, and the default locale.
- Canonical URL for the current Firebase Hosting address.
- Open Graph and Twitter/X sharing metadata.
- `WebApplication` JSON-LD structured data for Farmora, supported platforms, languages, and marketplace description.
- `web/robots.txt` allowing public crawling and linking the sitemap.
- `web/sitemap.xml` containing the public application entry point.
- Firebase Hosting content types and short cache policies for crawler files.

Before launch, replace `farmora-1da5a.web.app` in `web/index.html`, `web/robots.txt`, and `web/sitemap.xml` with the final verified custom domain. Then:

1. Deploy with `flutter build web` and `firebase deploy --only hosting`.
2. Verify `/`, `/robots.txt`, and `/sitemap.xml` return HTTP 200 responses.
3. Register the final domain in Google Search Console and Bing Webmaster Tools.
4. Submit the sitemap and inspect the canonical URL and structured data.
5. Add a real social preview image sized for sharing instead of the current favicon fallback.

The mobile Android/iOS application itself is not indexed like a normal website. App Store and Play Store listing metadata, screenshots, localized keywords, privacy links, and deep links are separate release tasks. The current Flutter Web shell advertises English, Sinhala, and Tamil through metadata and `?lang=` alternate hints, but these URLs are not yet separate server-rendered documents. For strong multilingual indexing, create distinct localized public pages such as `/en/`, `/si/`, and `/ta/` with translated visible content, self-canonical URLs, and matching sitemap entries. Flutter Web is a client-rendered SPA, so indexable product/category pages require prerendering or a server-rendered public marketing/catalogue surface.

## Android Signing

Production signing uses a local, ignored `android/key.properties` file. Start from the template:

```bash
cp android/key.properties.example android/key.properties
```

Replace the placeholders with the release keystore values. Never commit:

- `android/key.properties`
- `android/*.jks`
- Firebase service-account JSON files
- PayHere credentials or webhook secrets
- API keys or private encryption keys

The CI workflow creates a short-lived CI-only key so that release APK compilation can be validated without exposing the production keystore.

## CI

`.github/workflows/flutter-ci.yml` runs on pushes to `main`, `suka`, and `dev/swami`, and pull requests targeting `main`.

The workflow performs:

1. Checkout.
2. Java 17 setup.
3. Flutter 3.35.0 setup.
4. `flutter pub get`.
5. `flutter analyze`.
6. `flutter test`.
7. `npm ci` and `npm run build` in `functions/`.
8. Temporary CI signing key creation.
9. `flutter build apk --release`.

Latest verified result at the time of this handoff: CI run [33307080663](https://github.com/AHSANMOHAMMED/Farmora-App/actions/runs/33307080663) passed all steps.

## What Remains Before Production

### Required integrations

- Configure separate development, staging, and production Firebase projects.
- Resolve Firebase deployment IAM permissions and deploy rules/functions through a controlled account.
- Add PayHere merchant credentials, webhook signature verification, idempotency, refund handling, and payment reconciliation.
- Configure Google Maps keys, maps SDKs, location permissions, route display, and opt-in live tracking.
- Configure FCM device tokens, notification topics, notification preferences, quiet hours, and delivery events.
- Replace placeholder map panels with real map/tracking components.
- Load test catalogue reads, listeners, callable Functions, uploads, notifications, and payment webhooks against expected peak traffic.

### Security and trust

- Implement real client-side Signal-compatible key generation, key storage, rotation, verification, and encrypted message exchange. The current backend accepts ciphertext but does not itself provide complete E2EE.
- Enable Firebase App Check, rate limits, managed secrets, structured logs, alerts, backups, and crash reporting.
- Add rules tests for every allow/deny path in `firestore.rules` and `storage.rules`.
- Add audit log writes and administrator moderation/reporting workflows.
- Complete KYC policy, consent, privacy, terms, account deletion, and data export flows.
- Confirm escrow, refunds, disputes, and legal responsibilities with the payment/operations owner.

### Product completeness

- Add production search, location filtering, pagination, and catalogue indexing.
- Add cursor pagination and screen-scoped listener lifecycle management; current streams are bounded but not paginated.
- Complete provider eligibility and regional/capacity job matching.
- Add transport earnings and full farmer net-earnings calculations.
- Complete order-scoped messaging UI, attachments, read state, offline retry, reporting, and abuse controls.
- Externalize all user-facing strings and complete English, Sinhala, and Tamil localization QA.
- Add loading, empty, retry, offline, and error states for every network screen.
- Replace sample/placeholder data and validate all role paths on physical Android and iOS devices.

### Testing and release

- Add unit tests for validators, money calculations, permissions, and order/transport state machines.
- Add Firebase Emulator integration tests for authentication, product creation, checkout, inventory, delivery, reviews, disputes, and rules.
- Add Android and iOS integration tests, accessibility checks, and performance tests.
- Add Firebase Emulator and rules tests for role-scoped queries, including requested/assigned transport jobs.
- Add performance tests for startup, scrolling, image loading, listener counts, checkout latency, and offline recovery.
- Run dependency/security audits and resolve or review reported vulnerabilities.
- Configure production application IDs, bundle identifiers, release keystore handling, store metadata, staged rollout, and monitoring.

## Definition of Done

Farmora is ready for an MVP production release when a real user can:

1. Select a role and complete onboarding.
2. Register securely and pass required verification.
3. Create or discover a product.
4. Place and pay for an order without duplicate or client-controlled totals.
5. Arrange or accept transport.
6. Observe valid order and delivery transitions.
7. Receive notifications and message authorized participants securely.
8. Complete delivery and barcode verification.
9. Submit a review or open a dispute.
10. Change language, manage profile, and sign out.

Each step must be protected by backend authorization and covered by automated tests.

## Academic Context

Farmora is an educational project for **SE3050 - User Experience Engineering at SLIIT**, Group ID **Y3S2-NU-WE-02**.

Use `FARMORA_FULL_BUILD_SPEC.md` for the original product specification and longer-term architecture requirements. This README is the current implementation and handoff status.
