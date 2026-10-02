const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc, serverTimestamp } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function run() {
  try {
    const cred = await createUserWithEmailAndPassword(auth, '0094779998888@phone.farmora.app', 'driver123');
    const uid = cred.user.uid;
    console.log("Created Auth user:", uid);
    
    await setDoc(doc(db, 'users', uid), {
      id: uid,
      authUid: uid,
      uid: uid,
      name: 'Demo Driver',
      displayName: 'Demo Driver',
      phone: '0779998888',
      email: null,
      role: 'driver',
      district: 'Colombo',
      isVerified: true,
      isSuspended: false,
      isDeleted: false,
      createdByAdmin: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    console.log("Created Firestore document.");
  } catch(e) {
    console.error(e);
  }
  process.exit(0);
}
run();
