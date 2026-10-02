const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, collection, getDocs, limit, query } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function inspectDocSamples() {
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');

  const collections = ['settlements', 'reviews', 'market_price_reports', 'disputes', 'transport_jobs'];
  for (const c of collections) {
    const q = query(collection(db, c), limit(2));
    const snap = await getDocs(q);
    console.log(`\n=== SAMPLE FROM ${c} ===`);
    snap.forEach(d => {
      console.log(d.id, "=>", JSON.stringify(d.data()));
    });
  }
  process.exit(0);
}

inspectDocSamples().catch(console.error);
