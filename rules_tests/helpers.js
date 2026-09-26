// Shared rules-test environment. Host/ports come from the variables set by
// `firebase emulators:exec` (FIRESTORE_EMULATOR_HOST /
// FIREBASE_STORAGE_EMULATOR_HOST), falling back to firebase.emulators.json.
//
// Run from the repo root:
//   firebase emulators:exec --config firebase.emulators.json \
//     --only firestore,storage --project demo-farmora \
//     "cd rules_tests && npm test"
const path = require('path');
const fs = require('fs');
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

function hostPort(variable, fallbackPort) {
  const value = process.env[variable];
  if (value) {
    const [host, port] = value.split(':');
    return { host, port: Number(port) };
  }
  return { host: '127.0.0.1', port: fallbackPort };
}

let envPromise;
function getEnv() {
  if (!envPromise) {
    envPromise = initializeTestEnvironment({
      // Must match the emulator project so Storage rules' firestore.get()
      // sees the seeded documents.
      projectId: 'demo-farmora',
      firestore: {
        ...hostPort('FIRESTORE_EMULATOR_HOST', 8085),
        rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      },
      storage: {
        ...hostPort('FIREBASE_STORAGE_EMULATOR_HOST', 9199),
        rules: fs.readFileSync(path.join(__dirname, '..', 'storage.rules'), 'utf8'),
      },
    });
  }
  return envPromise;
}

const USERS = [
  ['farmer1', 'farmer', true],
  ['farmer2', 'farmer', true],
  ['farmerU', 'farmer', false],
  ['buyer1', 'buyer', true],
  ['buyer2', 'buyer', true],
  ['stranger', 'buyer', true],
  ['trans1', 'transporter', true],
  ['trans2', 'transporter', true],
  ['transU', 'transporter', false],
  ['admin1', 'admin', true],
];

/** Clears Firestore and seeds users, a product and bank details. */
async function seedBase(env, extra = async () => {}) {
  await env.clearFirestore();
  const { doc, setDoc } = require('firebase/firestore');
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [id, role, isVerified] of USERS) {
      await setDoc(doc(db, 'users', id), {
        id, role, isVerified, isSuspended: false, name: id, displayName: id,
      });
    }
    await setDoc(doc(db, 'users', 'suspended1'), {
      id: 'suspended1', role: 'buyer', isVerified: true, isSuspended: true,
    });
    await setDoc(doc(db, 'products', 'prod1'), {
      farmerId: 'farmer1', farmerName: 'farmer1', name: 'Carrots',
      category: 'Vegetables', priceMinor: 35000, quantityAvailable: 50,
      quantity: '50 kg available', unit: 'kg', location: 'Nuwara Eliya',
      status: 'Active', listingVersion: 1,
    });
    await setDoc(doc(db, 'bank_details', 'farmer1'), {
      farmerId: 'farmer1', bankName: 'BOC', branch: 'Kandy',
      accountHolderName: 'F One', accountNumber: '12345678',
    });
    await extra(db);
  });
}

module.exports = { getEnv, seedBase };
