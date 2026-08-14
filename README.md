# Farmora

Farmora is a Flutter MVP connecting **farmers, buyers, and transport providers** in one accessible agricultural marketplace. The current implementation is intentionally local-first so the complete core experience can be demonstrated before connecting production services.

## Completed MVP scope

| Area | Current behavior |
| --- | --- |
| Onboarding and authentication | Role selection for farmer, buyer, or transport provider, demo sign-in, and sign-out. |
| Farmer workflow | Add, view, remove, and manage products; review orders and progress. |
| Buyer workflow | Browse and filter-ready produ| Buyer workflow | Browse il, order placement, and delivery tracking. |
| Transport workflow | Available jobs, route and fee details, and accept-job state. |
| Orders | Status progress from pending through delivered, status update action, and delivery rating dialog. |
| Communication | Profile entry points for language settings and support-ready navigation. |
| Accessibility | Large touch targets, high-contrast status cues, simple copy, and Material 3 components. |

## Run locally

Install Flutter 3.16 or newer, then run:

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

The connected development environment used to prepare this repository does not include the Flutter SDK, so Flutter analysis The connected developmentst be completed on a machine with Flutter installed.

## Production integration checklist

The local-first state layer is ready to be replaced or backed by Firebase Auth, Firestore, Firebase Storage, Firebase Cloud Messaging, Google Maps Flutter, and a localization bundle for English, Sinhala, and Tamil. Before release, add secure authentication, server-side order validation, payment handling, image upload limits, transport location permissions, push-notification topics, and end-to-end tests.

## Structure

```text
lib/main.dart       # Complete local-first MVP shell and workflows
assets/             # Images, icons, and fonts reserved for production assets
test/               # Widget and state tests
pubspec.yaml        # Flutter and Provider dependencies
```

This is an educational project for **SE3050 – User Experience Engineering at SLIIT**, Group ID **Y3S2-NU-WE-02**.
