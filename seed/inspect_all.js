const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function inspect() {
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  console.log("Logged in as Admin.");

  const collections = [
    'users',
    'products',
    'orders',
    'transport_jobs',
    'settlements',
    'reviews',
    'market_prices',
    'market_price_reports',
    'disputes',
    'reports',
    'audit_logs',
    'crop_plans',
    'farm_tasks',
    'verification_docs'
  ];

  for (const c of collections) {
    const snap = await getDocs(collection(db, c));
    console.log(`Collection '${c}': ${snap.size} documents`);
    if (c === 'users') {
      snap.forEach(d => {
        const u = d.data();
        console.log(`  User ${d.id}: role=${u.role}, isVerified=${u.isVerified}, phone=${u.phoneNumber}, email=${u.email}`);
      });
    } else if (c === 'transport_jobs') {
      snap.forEach(d => {
        const j = d.data();
        console.log(`  Job ${d.id}: status=${j.status}, transporterId=${j.transporterId}, cargo=${j.cargoType || j.produceName}`);
      });
    }
  }

  process.exit(0);
}

inspect().catch(err => {
  console.error("Inspect error:", err);
  process.exit(1);
});
