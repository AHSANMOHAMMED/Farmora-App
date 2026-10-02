const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc, getDoc, collection, getDocs, updateDoc, query, where, serverTimestamp } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function runTests() {
  console.log("=== Starting Role CRUD Tests ===\n");
  let sharedProductId = null;

  try {
    // 1. Test FARMER Role
    console.log("--> Testing FARMER role (farmer@farmora.app)");
    const farmerCred = await signInWithEmailAndPassword(auth, 'farmer@farmora.app', 'password123');
    const farmerUid = farmerCred.user.uid;
    console.log("    [OK] Logged in");

    const productRef = doc(collection(db, 'products'));
    sharedProductId = productRef.id;
    await setDoc(productRef, {
      farmerId: farmerUid,
      farmerName: 'Demo Farmer',
      name: 'Test Potatoes',
      category: 'Vegetables',
      priceMinor: 20000, 
      quantityAvailable: 50,
      unit: 'kg',
      location: 'Colombo',
      district: 'Colombo',
      status: 'Active',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    console.log("    [OK] Created a product (CRUD: Create)");

    const pQ = query(collection(db, 'products'), where('farmerId', '==', farmerUid));
    const pSnaps = await getDocs(pQ);
    console.log(`    [OK] Read ${pSnaps.size} own products (CRUD: Read)`);
    console.log("    [SUCCESS] Farmer flow\n");

    // 2. Test BUYER Role
    console.log("--> Testing BUYER role (buyer@farmora.app)");
    const buyerCred = await signInWithEmailAndPassword(auth, 'buyer@farmora.app', 'password123');
    const buyerUid = buyerCred.user.uid;
    console.log("    [OK] Logged in");

    const allProds = await getDocs(collection(db, 'products'));
    console.log(`    [OK] Read ${allProds.size} products from marketplace (CRUD: Read)`);

    const wishlistRef = doc(db, 'users', buyerUid, 'wishlist', sharedProductId);
    await setDoc(wishlistRef, {
      productId: sharedProductId,
      addedAt: serverTimestamp()
    });
    console.log("    [OK] Created a wishlist item (CRUD: Create)");
    console.log("    [SUCCESS] Buyer flow\n");

    // 3. Test TRANSPORTER Role
    console.log("--> Testing TRANSPORTER role (transporter@farmora.app)");
    const transporterCred = await signInWithEmailAndPassword(auth, 'transporter@farmora.app', 'password123');
    const transporterUid = transporterCred.user.uid;
    console.log("    [OK] Logged in");

    const jobsQ = query(collection(db, 'transport_jobs'), 
      where('status', '==', 'requested'), 
      where('transporterId', '==', null)
    );
    const jobs = await getDocs(jobsQ);
    console.log(`    [OK] Read ${jobs.size} open transport jobs on the board (CRUD: Read)`);

    const profileRef = doc(db, 'transporter_profiles', transporterUid);
    await setDoc(profileRef, {
      id: transporterUid,
      uid: transporterUid,
      displayName: 'Demo Transporter',
      isVerified: true,
      vehicleCapacity: 500
    });
    console.log("    [OK] Updated own transporter profile (CRUD: Create/Update)");
    console.log("    [SUCCESS] Transporter flow\n");

    // 4. Test ADMIN Role
    console.log("--> Testing ADMIN role (0094725068682@phone.farmora.app)");
    await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
    console.log("    [OK] Logged in");

    const allUsers = await getDocs(collection(db, 'users'));
    console.log(`    [OK] Read all ${allUsers.size} users across platform (CRUD: Read)`);
    
    await updateDoc(doc(db, 'products', sharedProductId), {
      status: 'Inactive'
    });
    console.log("    [OK] Updated product status directly (Admin CRUD: Update)");

    console.log("    [SUCCESS] Admin flow\n");
    console.log("=== ALL ROLE TESTS PASSED PERFECTLY ===");
    process.exit(0);

  } catch (err) {
    console.error("\n[ERROR] Test failed:", err);
    process.exit(1);
  }
}
runTests();
