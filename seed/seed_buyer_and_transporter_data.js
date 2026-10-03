const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const {
  getFirestore, doc, setDoc, updateDoc, collection, getDocs, query, where, serverTimestamp, Timestamp
} = require('firebase/firestore');

const app = initializeApp({
  apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg",
  projectId: "farmingapp-24b34"
});
const auth = getAuth(app);
const db = getFirestore(app);

async function seedBuyerAndTransport() {
  console.log("--> Authenticating as Admin...");
  const adminCred = await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  const adminUid = adminCred.user.uid;
  console.log(`[OK] Logged in as Admin (UID: ${adminUid})`);

  // Fetch all active products to link into orders and wishlists
  const prodsSnap = await getDocs(query(collection(db, 'products'), where('status', '==', 'Active')));
  const products = prodsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  console.log(`[OK] Found ${products.length} active products from farmers.`);

  // ─────────────────────────────────────────────────────────────
  // 1. SEED TRANSPORTERS & LOCATION INFRASTRUCTURE
  // ─────────────────────────────────────────────────────────────
  console.log("\n=======================================================");
  console.log("      SEEDING TRANSPORTERS & LOCATION SETTINGS         ");
  console.log("=======================================================");

  const transporterConfigs = [
    {
      uid: 'JFZr8VUY84gRJmNV7dJI2rRwg9f1',
      name: 'Kajal Express Logistics',
      phone: '+94771158043',
      vehicle: 'Refrigerated Reefer Truck (3.5T)',
      plate: 'WP-CAD-8821',
      capacity: 3500,
      lat: 6.9271, // Colombo
      lng: 79.8612,
      locationName: 'Pettah Manning Wholesale Hub, Colombo',
      districts: ['Colombo', 'Gampaha', 'Kandy', 'Matale', 'Nuwara Eliya', 'Jaffna', 'Badulla']
    },
    {
      uid: 'aPtpFJzfobc6X2W2G45qD7c3aNk2',
      name: 'Island-Wide Agro Transport',
      phone: '+94718822334',
      vehicle: 'Heavy Produce Cargo Hauler (5.0T)',
      plate: 'CP-LH-4412',
      capacity: 5000,
      lat: 7.2906, // Kandy
      lng: 80.6337,
      locationName: 'Central Provincial Agri Hub, Kandy',
      districts: ['Kandy', 'Matale', 'Nuwara Eliya', 'Kurunegala', 'Colombo', 'Badulla']
    },
    {
      uid: 'tAnuAuJIuWgnHwjk3FywSaJ5J2E2',
      name: 'Fleet Logistics Lanka',
      phone: '+94773344556',
      vehicle: 'Insulated Cold-Chain Van (2.0T)',
      plate: 'WP-PX-1290',
      capacity: 2000,
      lat: 7.8731, // Dambulla
      lng: 80.6517,
      locationName: 'Dambulla Dedicated Economic Centre, Matale',
      districts: ['Matale', 'Anuradhapura', 'Polonnaruwa', 'Colombo', 'Jaffna']
    }
  ];

  for (const t of transporterConfigs) {
    console.log(`--> Configuring Transporter: ${t.name} (${t.uid})`);

    // A. Update users profile with verified status and live location coordinates
    await setDoc(doc(db, 'users', t.uid), {
      role: 'transporter',
      isVerified: true,
      isSuspended: false,
      verificationStatus: 'verified',
      displayName: t.name,
      phoneNumber: t.phone,
      location: {
        latitude: t.lat,
        longitude: t.lng,
      },
      latitude: t.lat,
      longitude: t.lng,
      locationUpdatedAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    }, { merge: true });

    // B. Set complete transporter_profiles
    await setDoc(doc(db, 'transporter_profiles', t.uid), {
      id: t.uid,
      uid: t.uid,
      displayName: t.name,
      phoneNumber: t.phone,
      isVerified: true,
      isAvailable: true,
      vehicleType: t.vehicle,
      vehicleRegistration: t.plate,
      vehicleCapacity: t.capacity,
      vehicleCapacityUnit: 'kg',
      vehicleDescription: `Specialized transport provider operating ${t.vehicle} with GPS telemetry.`,
      serviceDistricts: t.districts,
      rating: 4.9,
      completedDeliveries: 54,
      location: {
        latitude: t.lat,
        longitude: t.lng,
      },
      latitude: t.lat,
      longitude: t.lng,
      locationUpdatedAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    }, { merge: true });

    // C. Ensure assigned jobs with live location for testing
    // Job 1: In-Transit (Active Delivery with live GPS coordinates!)
    const activeJobRef = doc(collection(db, 'transport_jobs'));
    await setDoc(activeJobRef, {
      title: `Express Consignment: Fresh Vegetables to Colombo`,
      productName: 'Fresh Produce Consignment',
      produceName: 'Fresh Produce Consignment',
      cargoType: 'Vegetables',
      status: 'inTransit',
      transporterId: t.uid,
      logisticsProviderId: t.uid,
      driverId: t.uid,
      driverName: t.name,
      farmerId: '70MmvFXC39SwHa4zWK2KmyppY9h1', // Sureka
      farmerName: 'Sureka Apputhurai',
      farmerPhone: '+94764617927',
      buyerId: 'RNlU1rgy5wPV9EUjUOusERLH9Rf1',
      buyerName: 'Demo Buyer',
      buyerPhone: '+94712345678',
      pickupLocation: 'Thirunelveli Agri Depot, Jaffna',
      pickupAddress: 'Thirunelveli Agri Depot, Jaffna',
      deliveryLocation: 'Manning Wholesale Market, Colombo',
      deliveryAddress: 'Manning Wholesale Market, Colombo',
      cargoWeightKg: 850,
      quantityValue: 850,
      unit: 'kg',
      deliveryFeeMinor: 78000,
      offeredFeeMinor: 78000,
      feeMinor: 78000,
      fee: 'LKR 780.00',
      distanceKm: 395.0,
      courierLat: t.lat,
      courierLng: t.lng,
      locationUpdatedAt: serverTimestamp(),
      coldChain: true,
      tempMinC: 4.0,
      tempMaxC: 12.0,
      accepted: true,
      acceptedAt: serverTimestamp(),
      inTransitAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    // Job 2: Accepted (ready for pickup)
    const acceptedJobRef = doc(collection(db, 'transport_jobs'));
    await setDoc(acceptedJobRef, {
      title: `Highland Potatoes Dispatch to Kandy`,
      productName: 'Welimada Highland Potatoes',
      produceName: 'Welimada Highland Potatoes',
      cargoType: 'Vegetables',
      status: 'accepted',
      transporterId: t.uid,
      logisticsProviderId: t.uid,
      farmerId: 'QuE8rEuS9lTW5mcnPNXh0bWwS3M2', // ahsan
      farmerName: 'ahsan',
      farmerPhone: '+9472556081802',
      buyerId: 'pFUFqDdpl5aDsInA6yFw2JXXQPh2',
      buyerName: 'Suka Su',
      buyerPhone: '+94764617927',
      pickupLocation: 'Welimada Highland Valley, Badulla',
      pickupAddress: 'Welimada Highland Valley, Badulla',
      deliveryLocation: 'Kandy Municipal Market, Kandy',
      deliveryAddress: 'Kandy Municipal Market, Kandy',
      cargoWeightKg: 1200,
      quantityValue: 1200,
      unit: 'kg',
      deliveryFeeMinor: 62000,
      offeredFeeMinor: 62000,
      feeMinor: 62000,
      fee: 'LKR 620.00',
      distanceKm: 98.0,
      accepted: true,
      acceptedAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    // Job 3: Delivered (Historical record)
    const deliveredJobRef = doc(collection(db, 'transport_jobs'));
    await setDoc(deliveredJobRef, {
      title: `Delivered: Jaffna Papaya & Bananas Order ORD-1821`,
      productName: 'Jaffna Tropical Fruits',
      produceName: 'Jaffna Tropical Fruits',
      cargoType: 'Fruits',
      status: 'delivered',
      transporterId: t.uid,
      logisticsProviderId: t.uid,
      farmerId: 'UiFg4RfBu6WPDln3vF7BOHieAUJ2', // kajana
      farmerName: 'kajana',
      farmerPhone: '+94769447392',
      buyerId: 'SjA4etQg5yWVCSBgLi0tgskBSyx2',
      buyerName: 'Grand Hotel Procurement',
      buyerPhone: '+94778899001',
      pickupLocation: 'Chavakachcheri, Jaffna',
      pickupAddress: 'Chavakachcheri, Jaffna',
      deliveryLocation: 'Grand Hotel Colombo, Colombo 03',
      deliveryAddress: 'Grand Hotel Colombo, Colombo 03',
      cargoWeightKg: 650,
      quantityValue: 650,
      unit: 'kg',
      deliveryFeeMinor: 85000,
      offeredFeeMinor: 85000,
      feeMinor: 85000,
      fee: 'LKR 850.00',
      distanceKm: 410.0,
      courierLat: 6.9271,
      courierLng: 79.8612,
      locationUpdatedAt: serverTimestamp(),
      accepted: true,
      deliveredWithCode: true,
      deliveryCode: '741923',
      acceptedAt: serverTimestamp(),
      inTransitAt: serverTimestamp(),
      completedAt: serverTimestamp(),
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    console.log(`  [OK] Jobs populated (inTransit, accepted, delivered) with live GPS (${t.lat}, ${t.lng})`);
  }

  // ─────────────────────────────────────────────────────────────
  // 2. SEED ALL BUYERS (Orders, Wishlist, Reviews)
  // ─────────────────────────────────────────────────────────────
  console.log("\n=======================================================");
  console.log("            SEEDING ALL BUYER ACCOUNTS                 ");
  console.log("=======================================================");

  const buyerConfigs = [
    { uid: 'BJQMn9i3YKZvVgSlA8sCV2v9Ibj1', name: 'akd', district: 'Colombo', phone: '+94769447392' },
    { uid: 'Rhn8WXPV1PPALE2ixhu7', name: 'ahsan msm', district: 'Colombo', phone: '+94725068682' },
    { uid: 'tInvCW8s9XhDxZ64tyPi2den8Dq2', name: 'buyer', district: 'Gampaha', phone: '+94721234567' },
    { uid: 'pFUFqDdpl5aDsInA6yFw2JXXQPh2', name: 'Suka Su', district: 'Kandy', phone: '+94764617927' },
    { uid: 'FBYfCR8aTNJQbSLg7QGl', name: 'Grand Hotel Colombo', district: 'Colombo', phone: '+94778899001' },
    { uid: 'w7bKtDd1HqJm2hILrAxG', name: 'Lanka Fresh Market', district: 'Kurunegala', phone: '+94715566778' },
    { uid: 'YKcxZVJVPETiQp7Zk1J7', name: 'Spice Island Restaurant', district: 'Galle', phone: '+94771122334' },
    { uid: 'RNlU1rgy5wPV9EUjUOusERLH9Rf1', name: 'Demo Buyer', district: 'Colombo', phone: '+94712345678' },
    { uid: 'SjA4etQg5yWVCSBgLi0tgskBSyx2', name: 'Test Buyer', district: 'Colombo', phone: '+94710000002' }
  ];

  let bIndex = 0;
  for (const b of buyerConfigs) {
    bIndex++;
    console.log(`--> [${bIndex}/${buyerConfigs.length}] Configuring Buyer: ${b.name} (${b.uid})`);

    // Ensure user verified and has correct role
    await setDoc(doc(db, 'users', b.uid), {
      role: 'buyer',
      isVerified: true,
      isSuspended: false,
      verificationStatus: 'verified',
      displayName: b.name,
      phoneNumber: b.phone,
      district: b.district,
      location: {
        latitude: b.district === 'Colombo' ? 6.9271 : (b.district === 'Kandy' ? 7.2906 : 6.0535),
        longitude: b.district === 'Colombo' ? 79.8612 : (b.district === 'Kandy' ? 80.6337 : 80.2210),
      },
      updatedAt: serverTimestamp()
    }, { merge: true });

    // A. Check existing orders for this buyer
    const existingOrders = await getDocs(query(collection(db, 'orders'), where('buyerId', '==', b.uid)));
    if (existingOrders.size < 3 && products.length >= 3) {
      const p1 = products[(bIndex * 2) % products.length];
      const p2 = products[(bIndex * 2 + 1) % products.length];
      const p3 = products[(bIndex * 2 + 2) % products.length];

      // 1. Pending order
      const oPending = doc(collection(db, 'orders'));
      const q1 = 30;
      const price1 = p1.priceMinor || 45000;
      await setDoc(oPending, {
        orderNumber: `ORD-${3000 + bIndex * 10 + 1}`,
        buyerId: b.uid,
        buyerName: b.name,
        buyerPhone: b.phone,
        farmerId: p1.farmerId,
        farmerName: p1.farmerName || 'Registered Farmer',
        productId: p1.id,
        productName: p1.name,
        items: [{
          productId: p1.id,
          productName: p1.name,
          quantity: q1,
          unit: p1.unit || 'kg',
          unitPriceMinor: price1,
          totalPriceMinor: q1 * price1
        }],
        totalMinor: q1 * price1,
        total: `LKR ${((q1 * price1) / 100).toFixed(2)}`,
        status: 'pending',
        deliveryAddress: `No. ${25 + bIndex}, Trade Commercial Road, ${b.district}`,
        district: b.district,
        deliveryDate: new Date(Date.now() + 4 * 86400000).toISOString(),
        notes: 'Please pack in rigid cartons for transit protection.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      // 2. In-Transit order (with assigned transporter and live delivery)
      const oTransit = doc(collection(db, 'orders'));
      const q2 = 50;
      const price2 = p2.priceMinor || 38000;
      await setDoc(oTransit, {
        orderNumber: `ORD-${3000 + bIndex * 10 + 2}`,
        buyerId: b.uid,
        buyerName: b.name,
        buyerPhone: b.phone,
        farmerId: p2.farmerId,
        farmerName: p2.farmerName || 'Registered Farmer',
        productId: p2.id,
        productName: p2.name,
        transporterId: transporterConfigs[bIndex % transporterConfigs.length].uid,
        transporterName: transporterConfigs[bIndex % transporterConfigs.length].name,
        items: [{
          productId: p2.id,
          productName: p2.name,
          quantity: q2,
          unit: p2.unit || 'kg',
          unitPriceMinor: price2,
          totalPriceMinor: q2 * price2
        }],
        totalMinor: q2 * price2,
        total: `LKR ${((q2 * price2) / 100).toFixed(2)}`,
        status: 'in_transit',
        deliveryAddress: `Central Distribution Warehouse, ${b.district}`,
        district: b.district,
        deliveryDate: new Date(Date.now() + 1 * 86400000).toISOString(),
        notes: 'Temperature-controlled cargo tracking active.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      // 3. Completed order
      const oCompleted = doc(collection(db, 'orders'));
      const q3 = 75;
      const price3 = p3.priceMinor || 32000;
      await setDoc(oCompleted, {
        orderNumber: `ORD-${3000 + bIndex * 10 + 3}`,
        buyerId: b.uid,
        buyerName: b.name,
        buyerPhone: b.phone,
        farmerId: p3.farmerId,
        farmerName: p3.farmerName || 'Registered Farmer',
        productId: p3.id,
        productName: p3.name,
        transporterId: transporterConfigs[(bIndex + 1) % transporterConfigs.length].uid,
        transporterName: transporterConfigs[(bIndex + 1) % transporterConfigs.length].name,
        items: [{
          productId: p3.id,
          productName: p3.name,
          quantity: q3,
          unit: p3.unit || 'kg',
          unitPriceMinor: price3,
          totalPriceMinor: q3 * price3
        }],
        totalMinor: q3 * price3,
        total: `LKR ${((q3 * price3) / 100).toFixed(2)}`,
        status: 'completed',
        deliveryAddress: `Outlet Storefront, Main Bazaar, ${b.district}`,
        district: b.district,
        deliveryDate: new Date(Date.now() - 2 * 86400000).toISOString(),
        deliveredAt: serverTimestamp(),
        deliveryCode: '619284',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      console.log(`  [Orders Seeded] 3 orders (pending, in_transit, completed) created for ${b.name}`);
    } else {
      console.log(`  [Orders Exist] ${existingOrders.size} orders already exist for ${b.name}`);
    }
    // Wishlist items are written directly by client when user clicks favorite in UI

    // C. Buyer reviews
    const existingReviews = await getDocs(query(collection(db, 'reviews'), where('reviewerId', '==', b.uid)));
    if (existingReviews.size < 2 && products.length >= 2) {
      const pForRev = products[bIndex % products.length];
      const rRef = doc(collection(db, 'reviews'));
      await setDoc(rRef, {
        id: rRef.id,
        orderId: `ORD-${3000 + bIndex * 10 + 3}`,
        orderNumber: `ORD-${3000 + bIndex * 10 + 3}`,
        reviewerId: b.uid,
        reviewerName: b.name,
        subjectId: pForRev.farmerId,
        subjectName: pForRev.farmerName || 'Farmer Partner',
        rating: 5,
        comment: `Excellent quality ${pForRev.name}! Delivered fresh and crisp. Looking forward to our next recurring bulk order.`,
        status: 'approved',
        moderationStatus: 'approved',
        moderationNote: 'Verified platform purchase.',
        createdAt: serverTimestamp(),
        moderatedAt: serverTimestamp()
      });
      console.log(`  [Review Seeded] 5-star review added for ${b.name}`);
    }
  }

  console.log("\n=======================================================");
  console.log("       BUYER & TRANSPORTER SEEDING 100% COMPLETE       ");
  console.log("=======================================================");
  process.exit(0);
}

seedBuyerAndTransport().catch(err => {
  console.error("Seed error:", err);
  process.exit(1);
});
