const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, collection, getDocs, limit, query } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function check() {
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');

  const ordersSnap = await getDocs(query(collection(db, 'orders'), limit(3)));
  console.log("=== ORDERS SAMPLE ===");
  ordersSnap.forEach(d => console.log(d.id, JSON.stringify(d.data())));

  const jobsSnap = await getDocs(query(collection(db, 'transport_jobs'), limit(5)));
  console.log("=== JOBS SAMPLE ===");
  jobsSnap.forEach(d => console.log(d.id, JSON.stringify(d.data())));

  process.exit(0);
}

check().catch(console.error);
