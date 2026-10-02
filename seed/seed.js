const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc, collection, serverTimestamp } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function seed() {
  const adminCred = await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  const adminUid = adminCred.user.uid;
  
  console.log("Creating Admin Doc...");
  await setDoc(doc(db, 'users', adminUid), {
    id: adminUid,
    uid: adminUid,
    role: 'admin',
    phone: '0094725068682',
    isVerified: true,
    isSuspended: false
  }, { merge: true });
  console.log("Admin Doc Created!");

  const usersToCreate = [
    { email: 'farmer@farmora.app', password: 'password123', role: 'farmer', name: 'Demo Farmer', phone: '+94711111111' },
    { email: 'buyer@farmora.app', password: 'password123', role: 'buyer', name: 'Demo Buyer', phone: '+94722222222' },
    { email: 'transporter@farmora.app', password: 'password123', role: 'transporter', name: 'Demo Transporter', phone: '+94733333333' }
  ];

  let uids = {};
  for (let u of usersToCreate) {
    let cred;
    try {
      cred = await createUserWithEmailAndPassword(auth, u.email, u.password);
    } catch(e) {
      if (e.code === 'auth/email-already-in-use') {
        cred = await signInWithEmailAndPassword(auth, u.email, u.password);
      } else throw e;
    }
    uids[u.role] = cred.user.uid;
  }

  // Log in as Admin again
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');

  for (let u of usersToCreate) {
    const uid = uids[u.role];
    await setDoc(doc(db, 'users', uid), {
      id: uid,
      uid: uid,
      email: u.email,
      phone: u.phone,
      name: u.name,
      displayName: u.name,
      role: u.role,
      district: 'Colombo',
      authProvider: 'password',
      isVerified: true,
      isSuspended: false
    });
  }

  const productRef = doc(collection(db, 'products'));
  await setDoc(productRef, {
    farmerId: uids['farmer'],
    farmerName: 'Demo Farmer',
    name: 'Fresh Organic Tomatoes',
    category: 'Vegetables',
    priceMinor: 50000, 
    quantityAvailable: 100,
    unit: 'kg',
    location: 'Colombo',
    district: 'Colombo',
    status: 'Active',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  const orderRef = doc(collection(db, 'orders'));
  await setDoc(orderRef, {
    buyerId: uids['buyer'],
    buyerName: 'Demo Buyer',
    farmerId: uids['farmer'],
    farmerName: 'Demo Farmer',
    productId: productRef.id,
    productName: 'Fresh Organic Tomatoes',
    items: [{
      productId: productRef.id,
      productName: 'Fresh Organic Tomatoes',
      quantity: 10,
      unitPriceMinor: 50000,
      totalPriceMinor: 500000
    }],
    totalMinor: 500000,
    status: 'pending',
    deliveryAddress: '123 Main St, Colombo',
    district: 'Colombo',
    deliveryDate: '2026-10-05',
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  const jobRef = doc(collection(db, 'transport_jobs'));
  await setDoc(jobRef, {
    orderId: orderRef.id,
    farmerId: uids['farmer'],
    buyerId: uids['buyer'],
    pickupLocation: 'Farm A, Colombo',
    dropoffLocation: '123 Main St, Colombo',
    distanceKm: 15.5,
    status: 'requested',
    cargoType: 'Vegetables',
    cargoWeightKg: 10,
    offeredFeeMinor: 150000,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  console.log("Success!");
  process.exit(0);
}
seed();
