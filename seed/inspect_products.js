const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function inspectProducts() {
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');

  const snap = await getDocs(collection(db, 'products'));
  console.log(`Total products: ${snap.size}`);
  snap.forEach(d => {
    const data = d.data();
    console.log(`- ${d.id}: name="${data.name}", category="${data.category}", imagePath="${data.imagePath}", images=${JSON.stringify(data.images)}, imageUrls=${JSON.stringify(data.imageUrls)}`);
  });
  process.exit(0);
}

inspectProducts().catch(err => {
  console.error(err);
  process.exit(1);
});
