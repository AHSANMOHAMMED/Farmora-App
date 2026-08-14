# Farmora — Full Production Build Specification

## Product definition

Farmora is a Flutter mobile marketplace connecting rural farmers, buyers, and transport providers. The production app must make agricultural trade more direct, transparent, and reliable while remaining usable for people with different levels of digital literacy.

> **Primary promise:** farmers can sell their harvest, buyers can source trusted produce, and transport providers can move orders reliably through one simple platform.

## Roles and permissions

| Role | Main workflows | Permissions |
| --- | --- | --- |
| Farmer | List harvest, process orders, request transport, view earnings | Manage own products, own order records, transport requests, and earnings |
| Buyer | Discover produce, place orders, arrange delivery, message, review | Browse available produce, create/pay for own orders, track, message, review |
| Transport provider | Accept delivery work and update delivery status | View eligible jobs, accept assigned jobs, update delivery state, view earnings |
| Administrator | Operate and moderate marketplace | Manage users, products, orders, providers, disputes, notifications, reports |

Every permission must be enforced by the backend. The client is not a security boundary.

## Recommended stack and architecture

Use Flutter for Android and iOS, Riverpod for state management, GoRouter for navigation, Firebase Authentication for identity, Cloud Firestore for application data, Firebase Storage for media, Firebase Cloud Messaging for notifications, and Cloud Functions for trusted workflows. Use Google Maps Flutter only when location consent and API configuration are available.

```text
Flutter app
  Presentation: screens, widgets, localized copy
  State: Riverpod providers and async controllers
  Domain: entities, validation, use cases, state machines
  Data: repositories, Firebase adapters, DTO mapping

Firebase
  Auth · Firestore · Storage · Cloud Functions · FCM · App Check
```

Keep Firebase behind repository interfaces so local fakes can power tests and a future Node.js/PostgreSQL backend can replace the adapters.

## Project structure

```text
lib/
├── app.dart
├── main.dart
├── core/{constants,errors,localization,routing,theme,utils,widgets}
├── features/
│   ├── auth/{data,domain,presentation}
│   ├── farmer/{dashboard,products,orders,earnings}
│   ├── buyer/{home,product_detail,checkout,tracking}
│   ├── transporter/{jobs,active_delivery,earnings}
│   ├── orders/{data,domain,presentation}
│   ├── messaging/{data,domain,presentation}
│   ├── reviews/{data,domain,presentation}
│   └── profile/presentation
├── models/
├── providers/
└── services/{notification,storage,location,analytics}.dart
assets/{images,icons,translations}
test/{unit,widget,integration}
functions/src/index.ts
firestore.rules
storage.rules
firestore.indexes.json
```

## Data model

Use immutable IDs and server timestamps. Store money as integer minor units or validated decimal strings, never floating-point totals.

| Collection | Required fields |
| --- | --- |
| `users` | role, displayName, phone, email, photoUrl, languageCode, address, location, isVerified, isSuspended, timestamps |
| `products` | farmerId, name, category, description, imageUrls, quantityAvailable, unit, priceMinor, currency, location, availability, searchTokens, timestamps |
| `orders` | buyerId, farmerId, transporterId, items, subtotalMinor, deliveryFeeMinor, totalMinor, addresses, status, paymentStatus, deliveryStatus, trackingLocation, timestamps |
| `transportJobs` | orderId, pickup, dropoff, cargoSummary, weight, offeredFeeMinor, status, transporterId, transition timestamps |
| `conversations` | orderId, participantIds, lastMessage, lastMessageAt, unreadCounts |
| `messages` | conversationId, senderId, recipientId, body, attachmentUrl, readAt, createdAt |
| `reviews` | orderId, authorId, subjectId, rating, comment, createdAt, moderation status |

## Authentication and onboarding

Implement email/password and phone authentication first. Add Google and Apple providers only after account linking and privacy flows are complete. An `AuthGate` must route signed-out users to login, incomplete profiles to onboarding, suspended users to support, and active users to the correct role dashboard.

Collect role, display name, phone, preferred language, and location. Transport providers additionally submit vehicle type, registration, capacity, and verification documents. Keep providers pending until administrator approval.

## Farmer requirements

The farmer dashboard must show active listings, pending orders, completed earnings, low-stock warnings, and an obvious add-product action. Product creation must support name, category, description, quantity, unit, price, availability window, location, and up to five compressed images. Allow edit, pause, resume, and delete only for the owner.

Incoming orders must show buyer, item, quantity, total, pickup requirements, and status. Farmers can confirm or reject orders, request transport, message the buyer, and view gross sales, fees, transport deductions, and net earnings.

## Buyer requirements

The buyer home screen must support search by product and location, category filters, price range, availability, sorting, and pagination. Product detail must show farmer identity, location, availability, reviews, price, quantity selector, and delivery estimate.

Checkout must include cart review, delivery address, transport selection, fees, total, and payment status. Use an idempotency key for order creation so repeated taps cannot create duplicate orders. Buyer tracking must show the full timeline and allow contact with the farmer or transporter. After delivery, prompt for a review.

## Transport requirements

Providers should see only jobs eligible for their region, capacity, vehicle, and approval state. Each job shows pickup, dropoff, cargo quantity, route, fee, pickup time, and contact rules.

The delivery state machine is:

```text
Requested → Accepted → PickedUp → InTransit → Delivered
                    └──────────────→ Cancelled
```

Only valid transitions are accepted. Every transition is written through a trusted backend function with actor and timestamp. Location sharing is opt-in, limited to the assigned order, and stopped after delivery.

## Messaging, notifications, reviews

Create an order-scoped conversation between relevant participants. Add pagination, read state, push notifications, offline retry, reporting, and abuse controls. Do not expose phone numbers by default.

Use FCM for order status, transport acceptance, pickup reminders, delivery completion, and new messages. Store notification preferences and quiet hours. Reviews are allowed only after delivery, with one review per order and subject and moderation/reporting support.

## Localization and accessibility

Externalize every user-facing string and ship English, Sinhala, and Tamil resources. Use locale-aware dates, numbers, currencies, and pluralization. Support text scaling, semantic labels, 48dp touch targets, visible focus states, adequate contrast, and loading, empty, and error states for every network screen.

## Security and backend rules

Write Firestore and Storage rules before production data is introduced. Users may access only permitted records; farmers may modify only their products; buyers may modify only their own pre-confirmation orders; providers may modify only assigned jobs. Use Cloud Functions for role claims, payment verification, order totals, state transitions, notifications, provider matching, and audit logs.

Enable App Check, rate limits, server-side validation, structured logs, alerts, backups, and managed secrets. Never commit service keys. Add privacy, terms, consent, deletion, and data-export flows before store release.

## Testing strategy

| Layer | Coverage |
| --- | --- |
| Unit | Validators, totals, order state machine, permissions, localization formatting |
| Widget | Auth gate, onboarding, product form, product detail, checkout, timeline, job acceptance |
| Integration | Sign-in, create listing, buyer order, transport acceptance, delivery completion, review |
| Security | Firestore/Storage allow and deny cases for every role |
| Performance | Pagination, image compression, cold start, offline retry, catalogue queries |

CI should run formatting, analysis, unit/widget tests, rules validation, dependency audit, and release builds on Android and iOS.

## Delivery roadmap

### Phase 1 — Foundation

Replace demo state with repository interfaces, configure development/staging/production Firebase projects, implement AuthGate, onboarding, role claims, localization, error handling, and analytics.

### Phase 2 — Marketplace

Implement production product CRUD, image uploads, search/filter queries, pagination, product details, cart, checkout, payment state, and server-side order totals.

### Phase 3 — Delivery network

Implement provider verification, job matching, valid delivery transitions, maps, location permissions, provider earnings, and buyer tracking.

### Phase 4 — Trust and engagement

Add FCM, messaging, ratings, reviews, reporting, support, farmer earnings, admin moderation, analytics, and localization QA.

### Phase 5 — Hardening and release

Complete rules, privacy and terms, crash reporting, backups, accessibility review, device matrix testing, store metadata, signing, staged rollout, and monitoring.

## Environment configuration

Use separate Firebase projects and bundle identifiers for development, staging, and production. Document Firebase app files, Maps key, notification configuration, storage bucket, payment credentials, analytics IDs, and support contacts in `.env.example` without real values.

## Definition of done

The app is ready for MVP release when a user can select a role, complete onboarding, create or discover a product, place an order, arrange or accept transport, observe valid status updates, receive notifications, message another participant, complete delivery, submit a review, change language, and sign out. Backend permissions, money calculations, and state transitions must be covered by automated tests.

## Current repository handoff

The current repository contains the local-first Flutter demonstration, `pubspec.yaml`, `lib/main.dart`, `test/farmora_test.dart`, and this specification. Use this document as the production backlog and architecture handoff.
