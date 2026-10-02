const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, getDoc } = require('firebase/firestore');
const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const db = getFirestore(app);
async function check() {
  const cred = await signInWithEmailAndPassword(getAuth(app), '0094725068682@phone.farmora.app', 'admin123');
  console.log("Auth UID:", cred.user.uid);
  const snap = await getDoc(doc(db, 'users', cred.user.uid));
  console.log("Doc exists?", snap.exists());
  process.exit(0);
}
check();
