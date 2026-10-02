const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, doc, setDoc, collection, serverTimestamp, writeBatch, getDocs, query, where } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

async function runRichSeed() {
  console.log("Authenticating as Admin...");
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');

  console.log("Fetching users...");
  const usersSnap = await getDocs(collection(db, 'users'));
  let fId, bId, tId;
  usersSnap.forEach(snap => {
    const d = snap.data();
    if (d.email === 'farmer@farmora.app') fId = snap.id;
    if (d.email === 'buyer@farmora.app') bId = snap.id;
    if (d.email === 'transporter@farmora.app') tId = snap.id;
  });

  if (!fId || !bId || !tId) {
    console.error("Missing one or more demo users!");
    process.exit(1);
  }

  console.log(`Farmer: ${fId}, Buyer: ${bId}, Transporter: ${tId}`);

  // Create Products
  const products = [
    { name: 'Organic Carrots', cat: 'Vegetables', price: 45000, qty: 250, unit: 'kg' },
    { name: 'Red Onions', cat: 'Vegetables', price: 15000, qty: 500, unit: 'kg' },
    { name: 'Basmati Rice', cat: 'Grains', price: 32000, qty: 1000, unit: 'kg' },
    { name: 'King Coconut', cat: 'Fruits', price: 8000, qty: 150, unit: 'pieces' },
    { name: 'Green Chilies', cat: 'Vegetables', price: 65000, qty: 50, unit: 'kg' }
  ];

  let prodRefs = [];
  for (let p of products) {
    const r = doc(collection(db, 'products'));
    await setDoc(r, {
      farmerId: fId,
      farmerName: 'Demo Farmer',
      name: p.name,
      category: p.cat,
      priceMinor: p.price, 
      quantityAvailable: p.qty,
      unit: p.unit,
      location: 'Nuwara Eliya',
      district: 'Nuwara Eliya',
      status: 'Active',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    prodRefs.push(r.id);
  }
  console.log("Created 5 new products for Farmer.");

  // Create Orders
  const orders = [
    { pId: prodRefs[0], name: 'Organic Carrots', status: 'completed', price: 45000 },
    { pId: prodRefs[1], name: 'Red Onions', status: 'processing', price: 15000 },
    { pId: prodRefs[2], name: 'Basmati Rice', status: 'pending', price: 32000 },
  ];

  let orderRefs = [];
  for (let o of orders) {
    const r = doc(collection(db, 'orders'));
    await setDoc(r, {
      buyerId: bId,
      buyerName: 'Demo Buyer',
      farmerId: fId,
      farmerName: 'Demo Farmer',
      productId: o.pId,
      productName: o.name,
      items: [{
        productId: o.pId,
        productName: o.name,
        quantity: 20,
        unitPriceMinor: o.price,
        totalPriceMinor: o.price * 20
      }],
      totalMinor: o.price * 20,
      status: o.status,
      deliveryAddress: '456 Buyer Lane, Colombo',
      district: 'Colombo',
      deliveryDate: '2026-10-10',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    orderRefs.push(r.id);
  }
  console.log("Created 3 orders between Buyer and Farmer.");

  // Create Transport Jobs
  const jobs = [
    { oId: orderRefs[0], status: 'completed', tId: tId, fee: 350000, cargo: 'Vegetables' },
    { oId: orderRefs[1], status: 'in_transit', tId: tId, fee: 200000, cargo: 'Vegetables' },
    { oId: orderRefs[2], status: 'requested', tId: null, fee: 180000, cargo: 'Grains' },
  ];

  for (let j of jobs) {
    const r = doc(collection(db, 'transport_jobs'));
    await setDoc(r, {
      orderId: j.oId,
      farmerId: fId,
      buyerId: bId,
      transporterId: j.tId,
      pickupLocation: 'Nuwara Eliya Farm',
      dropoffLocation: '456 Buyer Lane, Colombo',
      distanceKm: 165.5,
      status: j.status,
      cargoType: j.cargo,
      cargoWeightKg: 20,
      offeredFeeMinor: j.fee,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  }
  console.log("Created 3 transport jobs (1 requested, 1 in_transit, 1 completed).");

  console.log("Rich seeding completed successfully!");
  process.exit(0);
}

runRichSeed().catch(console.error);
