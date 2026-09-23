# Farmora App — Preview Run Doc

## Reproduce Uncommitted Artifacts
1. Copy `.env` files from main checkout if any exist (currently none).
2. Run `flutter pub get` to install dependencies.

## Run the Server

### Option A: Release build + static server (used for preview)
```bash
flutter build web --release
python -m http.server 8083 --directory build/web
```

### Option B: Flutter dev server (hot reload)
```bash
flutter run -d web-server --web-port=8081
```

## Access
Open `http://localhost:8083` (release) or `http://localhost:8081` (dev) in a browser.

## Notes
- Firebase is in demo mode (placeholder keys). The app uses mock data.
- The app requires Flutter SDK 3.47.0+ with web support enabled.
