const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, getDoc } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function test() {
  try {
    const cred = await signInWithEmailAndPassword(auth, 'test_admin_user@example.com', 'testpass123');
    console.log("Logged in:", cred.user.uid);
    const d = await getDoc(doc(db, 'users', cred.user.uid));
    console.log("Doc exists:", d.exists(), d.data());
  } catch (e) {
    console.error("Login failed:", e);
  }
  process.exit(0);
}
test();
