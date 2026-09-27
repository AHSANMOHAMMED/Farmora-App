import { test } from 'node:test';
import assert from 'node:assert/strict';
import { verifyIdToken, fromValue, allowedNow } from '../src/index.js';

const enc = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');

async function signedToken(claims, kid = 'k1') {
  const { privateKey, publicKey } = await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true, ['sign', 'verify']);
  const head = enc({ alg: 'RS256', kid });
  const body = enc(claims);
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey, new TextEncoder().encode(`${head}.${body}`));
  const jwk = { ...(await crypto.subtle.exportKey('jwk', publicKey)), kid };
  return { token: `${head}.${body}.${Buffer.from(sig).toString('base64url')}`, jwk };
}

const now = Math.floor(Date.now() / 1000);
const good = { aud: 'farmora-1da5a', iss: 'https://securetoken.google.com/farmora-1da5a', sub: 'u1', iat: now - 10, exp: now + 3600 };

test('verifyIdToken accepts a valid Firebase token and rejects bad ones', async () => {
  const { token, jwk } = await signedToken(good);
  globalThis.fetch = async () => new Response(JSON.stringify({ keys: [jwk] }), { headers: { 'cache-control': 'max-age=60' } });
  assert.equal(await verifyIdToken(token, 'farmora-1da5a'), 'u1');
  await assert.rejects(verifyIdToken(token, 'other-project'));
  const tampered = token.replace(/\.[^.]+\./, `.${enc({ ...good, sub: 'attacker' })}.`);
  await assert.rejects(verifyIdToken(tampered, 'farmora-1da5a'));
});

test('verifyIdToken rejects expired tokens', async () => {
  const { token, jwk } = await signedToken({ ...good, exp: now - 5 }, 'k2');
  globalThis.fetch = async () => new Response(JSON.stringify({ keys: [jwk] }));
  await assert.rejects(verifyIdToken(token, 'farmora-1da5a', now + 1e6));
});

test('Firestore values decode', () => {
  assert.equal(fromValue({ integerValue: '42' }), 42);
  assert.deepEqual(fromValue({ mapValue: { fields: { a: { booleanValue: false } } } }), { a: false });
  assert.deepEqual(fromValue({ arrayValue: { values: [{ stringValue: 'x' }] } }), ['x']);
});

test('preferences and Sri Lanka quiet hours', () => {
  assert.equal(allowedNow('order', {}), true);
  assert.equal(allowedNow('message', { messages: false }), false);
  // 22:00–06:00 quiet; 18:00 UTC is 23:30 in Sri Lanka.
  const at = Date.UTC(2026, 8, 27, 18, 0);
  assert.equal(allowedNow('order', { quietHoursStart: 22, quietHoursEnd: 6 }, at), false);
  assert.equal(allowedNow('order', { quietHoursStart: 22, quietHoursEnd: 6 }, Date.UTC(2026, 8, 27, 6, 0)), true);
});
