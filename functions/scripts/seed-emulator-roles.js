const { randomBytes } = require('node:crypto');
const admin = require('firebase-admin');

if (!process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error(
    'Refusing to seed accounts unless Auth and Firestore emulator hosts are set.',
  );
}

const projectId = process.env.GCLOUD_PROJECT || 'farmingapp-24b34';
const password =
  process.env.FARMORA_EMULATOR_TEST_PASSWORD || randomBytes(18).toString('base64url');
const testAccounts = [
  { role: 'buyer', phone: '0771000001', name: 'Emulator Buyer' },
  { role: 'farmer', phone: '0771000002', name: 'Emulator Farmer' },
  { role: 'transporter', phone: '0771000003', name: 'Emulator Logistics' },
  { role: 'admin', phone: '0771000004', name: 'Emulator Admin' },
];

admin.initializeApp({ projectId });

function emailForPhone(phone) {
  return `${phone}@phone.farmora.app`;
}

async function findOrCreateUser(email, displayName) {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    return admin.auth().updateUser(existing.uid, { password, displayName });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    return admin.auth().createUser({ email, password, displayName });
  }
}

async function main() {
  const db = admin.firestore();
  for (const account of testAccounts) {
    const email = emailForPhone(account.phone);
    const user = await findOrCreateUser(email, account.name);
    if (account.role === 'admin') {
      await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    }
    await db.collection('users').doc(user.uid).set(
      {
        id: user.uid,
        authUid: user.uid,
        name: account.name,
        displayName: account.name,
        phone: account.phone,
        email,
        role: account.role,
        isVerified: true,
        isSuspended: false,
        isDeleted: false,
      },
      { merge: true },
    );
    console.log(`${account.role}: phone ${account.phone}`);
  }
  console.log(`Shared emulator-only password: ${password}`);
  await admin.app().delete();
}

main().catch(async (error) => {
  console.error(error);
  await admin.app().delete();
  process.exitCode = 1;
});
