// Farmora push relay: a free Cloudflare Worker that sends FCM push for
// in-app notifications while the app runs on the Firebase Spark plan (which
// has no Cloud Functions). The app writes a notification document, then
// calls POST /notify {notificationId} with the user's Firebase ID token.
//
// Safety: the caller must hold a valid Firebase ID token for this project;
// only notifications created in the last 2 minutes and not pushed before are
// sent (marked with pushedAt using an update-time precondition, so each is
// pushed at most once); the recipient's preferences and quiet hours apply.
//
// Secrets (npx wrangler secret put ...): SA_CLIENT_EMAIL, SA_PRIVATE_KEY.
// Vars (wrangler.toml): FIREBASE_PROJECT_ID.

const FRESH_MS = 2 * 60 * 1000;
const PER_MINUTE = 60;
const SL_OFFSET_MIN = 330; // Sri Lanka (UTC+05:30) for quiet hours.

let jwksCache = { keys: null, expires: 0 };
let tokenCache = { token: null, expires: 0 };
const rate = new Map();

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};
const json = (status, body) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });

// ── base64url / PEM helpers ─────────────────────────────────
const b64urlToBytes = (s) => {
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/') + '==='.slice((s.length + 3) % 4);
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
};
const bytesToB64url = (bytes) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const strToB64url = (s) => bytesToB64url(new TextEncoder().encode(s));
const pemToDer = (pem) =>
  Uint8Array.from(atob(pem.replace(/-----[^-]+-----/g, '').replace(/\\n|\s/g, '')), (c) => c.charCodeAt(0));

// ── Firebase ID token verification ──────────────────────────
async function googleJwks() {
  if (jwksCache.keys && Date.now() < jwksCache.expires) return jwksCache.keys;
  const res = await fetch('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
  const body = await res.json();
  const maxAge = Number((res.headers.get('cache-control') || '').match(/max-age=(\d+)/)?.[1] || 3600);
  jwksCache = { keys: body.keys, expires: Date.now() + maxAge * 1000 };
  return body.keys;
}

export async function verifyIdToken(token, projectId, now = Date.now() / 1000) {
  const [h, p, sig] = token.split('.');
  if (!h || !p || !sig) throw new Error('malformed token');
  const header = JSON.parse(new TextDecoder().decode(b64urlToBytes(h)));
  const payload = JSON.parse(new TextDecoder().decode(b64urlToBytes(p)));
  if (header.alg !== 'RS256') throw new Error('bad alg');
  const jwk = (await googleJwks()).find((k) => k.kid === header.kid);
  if (!jwk) throw new Error('unknown key');
  const key = await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']);
  const ok = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, b64urlToBytes(sig), new TextEncoder().encode(`${h}.${p}`));
  if (!ok) throw new Error('bad signature');
  if (payload.aud !== projectId) throw new Error('bad audience');
  if (payload.iss !== `https://securetoken.google.com/${projectId}`) throw new Error('bad issuer');
  if (!(payload.exp > now) || !(payload.iat <= now + 60)) throw new Error('expired');
  if (!payload.sub) throw new Error('no subject');
  return payload.sub;
}

// ── Service-account access token (Firestore + FCM) ──────────
async function accessToken(env) {
  if (tokenCache.token && Date.now() < tokenCache.expires) return tokenCache.token;
  const now = Math.floor(Date.now() / 1000);
  const header = strToB64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = strToB64url(JSON.stringify({
    iss: env.SA_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey('pkcs8', pemToDer(env.SA_PRIVATE_KEY),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claims}`));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=${encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')}&assertion=${header}.${claims}.${bytesToB64url(sig)}`,
  });
  const body = await res.json();
  if (!body.access_token) throw new Error('service account auth failed');
  tokenCache = { token: body.access_token, expires: Date.now() + (body.expires_in - 60) * 1000 };
  return body.access_token;
}

// ── Firestore REST ──────────────────────────────────────────
export function fromValue(v) {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('timestampValue' in v) return v.timestampValue;
  if ('nullValue' in v) return null;
  if ('mapValue' in v) return fromFields(v.mapValue.fields || {});
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fromValue);
  return null;
}
const fromFields = (fields) => Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, fromValue(v)]));

const docsUrl = (env) => `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents`;

async function getDoc(env, token, path) {
  const res = await fetch(`${docsUrl(env)}/${path}`, { headers: { Authorization: `Bearer ${token}` } });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`firestore ${res.status}`);
  return res.json();
}

// Mirrors LocalNotifier.categoryOf / the Cloud Functions' notificationCategory.
export function allowedNow(type, prefs, nowMs = Date.now()) {
  const category = type === 'message' ? 'messages'
    : (type === 'general' || type === 'market_price') ? 'promos' : 'orderUpdates';
  if (prefs && prefs[category] === false) return false;
  const start = prefs?.quietHoursStart;
  const end = prefs?.quietHoursEnd;
  if (Number.isInteger(start) && Number.isInteger(end) && start !== end) {
    const h = new Date(nowMs + SL_OFFSET_MIN * 60000).getUTCHours();
    const quiet = start < end ? h >= start && h < end : h >= start || h < end;
    if (quiet) return false;
  }
  return true;
}

async function handleNotify(req, env) {
  const auth = req.headers.get('Authorization') || '';
  let uid;
  try {
    uid = await verifyIdToken(auth.replace(/^Bearer\s+/i, ''), env.FIREBASE_PROJECT_ID);
  } catch (e) {
    return json(401, { error: 'unauthenticated' });
  }
  const minute = Math.floor(Date.now() / 60000);
  const key = `${uid}:${minute}`;
  rate.set(key, (rate.get(key) || 0) + 1);
  if (rate.get(key) > PER_MINUTE) return json(429, { error: 'slow down' });
  if (rate.size > 5000) rate.clear();

  const { notificationId } = await req.json().catch(() => ({}));
  if (typeof notificationId !== 'string' || !/^[A-Za-z0-9]{10,40}$/.test(notificationId)) {
    return json(400, { error: 'notificationId required' });
  }
  const token = await accessToken(env);
  const doc = await getDoc(env, token, `notifications/${notificationId}`);
  if (!doc) return json(404, { error: 'not found' });
  const n = fromFields(doc.fields || {});
  if (n.pushedAt) return json(200, { skipped: 'already pushed' });
  if (!n.createdAt || Date.now() - Date.parse(n.createdAt) > FRESH_MS) {
    return json(200, { skipped: 'stale' });
  }
  if (n.senderId && n.senderId !== uid) return json(403, { error: 'not the sender' });

  // Claim it exactly once (fails if someone else updated it first).
  const claim = await fetch(
    `${docsUrl(env)}/notifications/${notificationId}?updateMask.fieldPaths=pushedAt&currentDocument.updateTime=${encodeURIComponent(doc.updateTime)}`,
    {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ fields: { pushedAt: { timestampValue: new Date().toISOString() } } }),
    },
  );
  if (!claim.ok) return json(200, { skipped: 'claimed elsewhere' });

  const userDoc = await getDoc(env, token, `users/${n.userId}`);
  const user = userDoc ? fromFields(userDoc.fields || {}) : {};
  if (user.isDeleted === true) return json(200, { skipped: 'deleted user' });
  if (!allowedNow(n.type, user.notificationPrefs || user.notificationPreferences || {})) {
    return json(200, { skipped: 'preferences' });
  }
  const list = await getDoc(env, token, `users/${n.userId}/device_tokens?pageSize=20`);
  const tokens = (list?.documents || [])
    .map((d) => ({ name: d.name, ...fromFields(d.fields || {}) }))
    .filter((t) => t.enabled !== false && typeof t.token === 'string' && t.token.length > 20);

  let sent = 0;
  for (const t of tokens) {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          token: t.token,
          notification: { title: String(n.title || 'Farmora').slice(0, 120), body: String(n.body || '').slice(0, 500) },
          data: Object.fromEntries(Object.entries({
            type: n.type, referenceId: n.referenceId, orderId: n.orderId, jobId: n.jobId, notificationId,
          }).filter(([, v]) => typeof v === 'string')),
          android: { priority: 'HIGH', notification: { channel_id: 'farmora_updates' } },
        },
      }),
    });
    if (res.ok) {
      sent += 1;
    } else if (res.status === 404 || res.status === 400) {
      // Unregistered / invalid token: forget it.
      const docPath = t.name.split('/documents/')[1];
      await fetch(`${docsUrl(env)}/${docPath}`, { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } });
    }
  }
  return json(200, { sent });
}

export default {
  async fetch(req, env) {
    if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
    const url = new URL(req.url);
    if (req.method === 'POST' && url.pathname === '/notify') {
      try {
        return await handleNotify(req, env);
      } catch (e) {
        return json(500, { error: 'relay error' });
      }
    }
    return json(404, { error: 'not found' });
  },
};
