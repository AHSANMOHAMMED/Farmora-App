# Farmora push relay (free, for the Spark plan)

The Spark plan has no Cloud Functions, so nothing can send a push
notification to a phone whose app is closed. This Cloudflare Worker fills
that gap for free (Cloudflare's free plan allows 100,000 requests a day).
Without it the app still shows system notifications whenever it is open or
running in the background.

How it works: after writing an in-app notification, the app calls
`POST /notify {notificationId}` with the user's Firebase ID token. The worker
verifies the token, pushes only notifications created in the last two
minutes that were not pushed before (each is claimed once with `pushedAt`),
respects the recipient's notification preferences and quiet hours, and sends
through FCM HTTP v1 to the recipient's registered devices.

## Set up (once)

1. Firebase console → Project settings → Service accounts → *Generate new
   private key*. Or, in Google Cloud IAM, create a service account with only
   **Cloud Datastore User** and **Firebase Cloud Messaging API Admin**.
2. Install Wrangler and log in: `npx wrangler login`
3. From this folder:
   ```
   npx wrangler secret put SA_CLIENT_EMAIL    # client_email from the key file
   npx wrangler secret put SA_PRIVATE_KEY     # private_key from the key file
   npx wrangler deploy
   ```
4. Build the app with the URL Wrangler prints:
   ```
   flutter build apk --dart-define=PUSH_RELAY_URL=https://farmora-push.<you>.workers.dev
   ```
   (and the same `--dart-define` for web / iOS builds).

Delete the downloaded key file after step 3; keep it out of git.

## Test

`node --test` runs the unit tests in `test/` (token checks, value decoding,
preferences).
