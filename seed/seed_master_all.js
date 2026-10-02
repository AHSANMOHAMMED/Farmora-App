const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const {
  getFirestore, doc, setDoc, updateDoc, collection, getDocs, serverTimestamp, Timestamp
} = require('firebase/firestore');

const app = initializeApp({
  apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg",
  projectId: "farmingapp-24b34"
});
const auth = getAuth(app);
const db = getFirestore(app);

async function runMasterSeed() {
  console.log("--> Authenticating as Admin...");
  const adminCred = await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  const adminUid = adminCred.user.uid;
  console.log(`[OK] Logged in as Admin (UID: ${adminUid})`);

  // 1. VERIFY ALL USERS & POPULATE PROFILES
  console.log("\n--> 1. Updating all users in Firestore to isVerified: true, isSuspended: false...");
  const usersSnap = await getDocs(collection(db, 'users'));
  const userMap = {};
  for (const uDoc of usersSnap.docs) {
    const data = uDoc.data();
    userMap[uDoc.id] = { id: uDoc.id, ...data };
    await updateDoc(doc(db, 'users', uDoc.id), {
      isVerified: true,
      isSuspended: false,
      verificationStatus: 'verified',
      updatedAt: serverTimestamp()
    });
  }
  console.log(`[OK] Successfully verified and un-suspended all ${usersSnap.size} user documents.`);

  // Find key UIDs
  const findUid = (predicate) => {
    for (const [id, u] of Object.entries(userMap)) {
      if (predicate(u)) return id;
    }
    return null;
  };

  const demoFarmerId = findUid(u => u.email === 'farmer@farmora.app') || 'AZzuH91AZyZ1tVv449vNcqYALev2';
  const testFarmerId = findUid(u => u.id === 'elQqhnNbqefGexAuZFf0JlRV5B03') || 'elQqhnNbqefGexAuZFf0JlRV5B03';
  const demoBuyerId = findUid(u => u.email === 'buyer@farmora.app') || 'RNlU1rgy5wPV9EUjUOusERLH9Rf1';
  const testBuyerId = findUid(u => u.id === 'SjA4etQg5yWVCSBgLi0tgskBSyx2') || 'SjA4etQg5yWVCSBgLi0tgskBSyx2';
  const demoTransporterId = findUid(u => u.email === 'transporter@farmora.app') || 'aPtpFJzfobc6X2W2G45qD7c3aNk2';
  const kajalTransporterId = findUid(u => u.email === 'kajak4442@gmail.com') || 'JFZr8VUY84gRJmNV7dJI2rRwg9f1';
  const fleetTransporterId = findUid(u => u.id === 'tAnuAuJIuWgnHwjk3FywSaJ5J2E2') || 'tAnuAuJIuWgnHwjk3FywSaJ5J2E2';

  console.log(`Demo Farmer: ${demoFarmerId}`);
  console.log(`Demo Buyer: ${demoBuyerId}`);
  console.log(`Transporters: ${demoTransporterId}, ${kajalTransporterId}, ${fleetTransporterId}`);

  // 2. TRANSPORTER PROFILES
  console.log("\n--> 2. Ensuring Transporter Profiles exist and are verified...");
  const transporters = [demoTransporterId, kajalTransporterId, fleetTransporterId];
  for (const tId of transporters) {
    await setDoc(doc(db, 'transporter_profiles', tId), {
      id: tId,
      uid: tId,
      displayName: tId === kajalTransporterId ? 'Kajal Express Logistics' : 'Island-Wide Agro Transport',
      phoneNumber: '+94771158043',
      isVerified: true,
      isAvailable: true,
      vehicleType: 'Refrigerated Truck (3.5 Ton)',
      vehicleRegistration: 'WP-CAD-8821',
      vehicleCapacity: 3500,
      vehicleCapacityUnit: 'kg',
      vehicleDescription: 'Reliable cold-chain reefer truck for perishable vegetables, fruits, and dairy.',
      serviceDistricts: ['Colombo', 'Gampaha', 'Kandy', 'Matale', 'Nuwara Eliya', 'Kurunegala', 'Jaffna', 'Badulla'],
      rating: 4.9,
      completedDeliveries: 48,
      updatedAt: serverTimestamp()
    }, { merge: true });
  }
  console.log("[OK] Transporter profiles populated.");

  // 3. FIX EXISTING JOBS & SEED NEW OPEN & ASSIGNED TRANSPORT JOBS
  console.log("\n--> 3. Updating existing transport jobs and adding rich open & active jobs...");
  const existingJobsSnap = await getDocs(collection(db, 'transport_jobs'));
  for (const jDoc of existingJobsSnap.docs) {
    const d = jDoc.data();
    const fee = d.deliveryFeeMinor || d.offeredFeeMinor || d.feeMinor || 45000;
    const isAssigned = d.transporterId && d.transporterId.length > 0;
    
    // Normalise status: 'available' -> 'requested'
    let normStatus = d.status;
    if (normStatus === 'available') normStatus = 'requested';
    if (normStatus === 'assigned') normStatus = 'accepted';

    await updateDoc(doc(db, 'transport_jobs', jDoc.id), {
      status: normStatus,
      deliveryFeeMinor: fee,
      offeredFeeMinor: fee,
      feeMinor: fee,
      fee: `LKR ${(fee / 100).toFixed(2)}`,
      pickupLocation: d.pickupAddress || d.pickupLocation || 'Dambulla Economic Centre, Matale',
      pickupAddress: d.pickupAddress || d.pickupLocation || 'Dambulla Economic Centre, Matale',
      deliveryLocation: d.deliveryAddress || d.deliveryLocation || 'Manning Wholesale Market, Pettah, Colombo',
      deliveryAddress: d.deliveryAddress || d.deliveryLocation || 'Manning Wholesale Market, Pettah, Colombo',
      farmerName: d.farmerName || 'Sunil Perera (Nuwara Eliya Farms)',
      buyerName: d.buyerName || 'Lanka Fresh Supermarkets PLC',
      farmerPhone: '+94771234567',
      buyerPhone: '+94712345678',
      quantityValue: d.quantityValue || d.quantity || 150,
      cargoWeightKg: d.cargoWeightKg || d.quantity || 150,
      unit: d.unit || 'kg',
      updatedAt: serverTimestamp()
    });
  }
  console.log(`[OK] Updated ${existingJobsSnap.size} existing transport jobs.`);

  // New Open Jobs (Available to ANY transporter!)
  const openJobSpecs = [
    { title: 'Fresh Organic Carrots Collection', cargo: 'Organic Carrots', weight: 450, fee: 65000, pickup: 'Nuwara Eliya Central Farm, Nuwara Eliya', dropoff: 'Pettah Wholesale Market, Colombo', dist: 165.0 },
    { title: 'Red Onions Bulk Dispatch', cargo: 'Red Onions', weight: 800, fee: 78000, pickup: 'Dambulla Dedicated Economic Centre, Matale', dropoff: 'Kandy Municipal Market, Kandy', dist: 72.5 },
    { title: 'Jaffna Red Chillies & Onions Cargo', cargo: 'Red Chillies', weight: 350, fee: 92000, pickup: 'Thirunelveli Agri Market, Jaffna', dropoff: 'Manning Market, Pettah, Colombo', dist: 395.0 },
    { title: 'Highland Potatoes Shipment', cargo: 'Highland Potatoes', weight: 1200, fee: 88000, pickup: 'Welimada Farm Center, Badulla', dropoff: 'Meegoda Dedicated Economic Centre, Colombo', dist: 195.0 },
    { title: 'Fresh King Coconuts Truckload', cargo: 'King Coconuts', weight: 600, fee: 54000, pickup: 'Kurunegala Coconut Estate, Kurunegala', dropoff: 'Galle Face Hotel, Colombo 03', dist: 98.0 },
    { title: 'Green Beans & Cabbage Delivery', cargo: 'Green Beans', weight: 500, fee: 62000, pickup: 'Keppetipola Economic Centre, Nuwara Eliya', dropoff: 'Negombo Wholesale Produce Market', dist: 178.0 },
    { title: 'Ceylon Spices Consignment', cargo: 'Cardamom & Cloves', weight: 200, fee: 48000, pickup: 'Matale Spice Garden Cooperative, Matale', dropoff: 'Air Cargo Terminal, Katunayake', dist: 135.0 },
    { title: 'Sweet Papaya & Bananas Freight', cargo: 'Papaya & Bananas', weight: 750, fee: 58000, pickup: 'Embilipitiya Fruit Center, Ratnapura', dropoff: 'Cargills Food City Distribution Center, Ja-Ela', dist: 160.0 },
  ];

  for (const spec of openJobSpecs) {
    const r = doc(collection(db, 'transport_jobs'));
    await setDoc(r, {
      title: spec.title,
      productName: spec.cargo,
      produceName: spec.cargo,
      cargoType: spec.cargo,
      status: 'requested',
      transporterId: null,
      requestedTransporterId: null,
      farmerId: demoFarmerId,
      buyerId: demoBuyerId,
      farmerName: 'Sunil Perera',
      buyerName: 'Grand Hotel Procurement',
      farmerPhone: '+94771234567',
      buyerPhone: '+94712345678',
      pickupLocation: spec.pickup,
      pickupAddress: spec.pickup,
      deliveryLocation: spec.dropoff,
      deliveryAddress: spec.dropoff,
      distanceKm: spec.dist,
      cargoWeightKg: spec.weight,
      quantityValue: spec.weight,
      unit: 'kg',
      deliveryFeeMinor: spec.fee,
      offeredFeeMinor: spec.fee,
      feeMinor: spec.fee,
      fee: `LKR ${(spec.fee / 100).toFixed(2)}`,
      detail: `Urgent agricultural produce pickup required. Temperature controlled cold chain preferred.`,
      accepted: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
  }
  console.log(`[OK] Created ${openJobSpecs.length} open jobs with status 'requested' and transporterId: null.`);

  // Assigned Active & Completed Jobs for Transporter accounts
  const assignedSpecs = [
    { tId: demoTransporterId, status: 'accepted', title: 'Accepted: Keells Supermarket Dispatch', cargo: 'Fresh Tomatoes', weight: 400, fee: 52000, pickup: 'Dambulla, Matale', dropoff: 'Keells Colombo Central' },
    { tId: demoTransporterId, status: 'inTransit', title: 'In Transit: Organic Leeks to Colombo', cargo: 'Organic Leeks', weight: 600, fee: 75000, pickup: 'Nuwara Eliya', dropoff: 'Pettah Market, Colombo' },
    { tId: demoTransporterId, status: 'delivered', title: 'Delivered: Fresh Carrots Order ORD-1002', cargo: 'Fresh Carrots', weight: 500, fee: 65000, pickup: 'Nuwara Eliya', dropoff: 'Colombo 07' },
    { tId: kajalTransporterId, status: 'accepted', title: 'Accepted: Nuwara Eliya Cabbage Dispatch', cargo: 'Fresh Cabbage', weight: 350, fee: 48000, pickup: 'Nuwara Eliya', dropoff: 'Kandy Market' },
    { tId: kajalTransporterId, status: 'inTransit', title: 'In Transit: Red Onions Express Consignment', cargo: 'Red Onions', weight: 700, fee: 82000, pickup: 'Dambulla', dropoff: 'Manning Market, Pettah' },
    { tId: kajalTransporterId, status: 'delivered', title: 'Delivered: Highland Potatoes Order ORD-1008', cargo: 'Highland Potatoes', weight: 900, fee: 94000, pickup: 'Badulla', dropoff: 'Colombo 03' },
  ];

  for (const aspec of assignedSpecs) {
    const r = doc(collection(db, 'transport_jobs'));
    await setDoc(r, {
      title: aspec.title,
      productName: aspec.cargo,
      produceName: aspec.cargo,
      cargoType: aspec.cargo,
      status: aspec.status,
      transporterId: aspec.tId,
      logisticsProviderId: aspec.tId,
      farmerId: demoFarmerId,
      buyerId: demoBuyerId,
      farmerName: 'Sunil Perera',
      buyerName: 'Grand Hotel Procurement',
      farmerPhone: '+94771234567',
      buyerPhone: '+94712345678',
      pickupLocation: aspec.pickup,
      pickupAddress: aspec.pickup,
      deliveryLocation: aspec.dropoff,
      deliveryAddress: aspec.dropoff,
      distanceKm: 125.0,
      cargoWeightKg: aspec.weight,
      quantityValue: aspec.weight,
      unit: 'kg',
      deliveryFeeMinor: aspec.fee,
      offeredFeeMinor: aspec.fee,
      feeMinor: aspec.fee,
      fee: `LKR ${(aspec.fee / 100).toFixed(2)}`,
      courierLat: 6.9271,
      courierLng: 79.8612,
      accepted: true,
      deliveredWithCode: aspec.status === 'delivered',
      deliveryCode: '582914',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      acceptedAt: serverTimestamp(),
      inTransitAt: aspec.status === 'inTransit' || aspec.status === 'delivered' ? serverTimestamp() : null,
      completedAt: aspec.status === 'delivered' ? serverTimestamp() : null,
    });
  }
  console.log(`[OK] Created ${assignedSpecs.length} active and delivered jobs for transporter accounts.`);

  // 4. SEED SETTLEMENTS FOR ALL ROLES (Admin Treasury + Farmer & Transporter Earnings)
  console.log("\n--> 4. Seeding settlements across all roles (pending, processing, settled, on_hold, rejected)...");
  const settlementTargets = [
    { uid: demoFarmerId, role: 'farmer', name: 'Demo Farmer' },
    { uid: testFarmerId, role: 'farmer', name: 'Sunil Perera' },
    { uid: demoTransporterId, role: 'transporter', name: 'Island Logistics LK' },
    { uid: kajalTransporterId, role: 'transporter', name: 'Kajal Express Logistics' },
    { uid: fleetTransporterId, role: 'transporter', name: 'Fleet Transporter' },
  ];

  const banks = [
    { bank: 'Bank of Ceylon (BOC)', acc: '7045129841', method: 'SLIP' },
    { bank: 'Commercial Bank of Ceylon', acc: '8102394812', method: 'CEFT' },
    { bank: 'Hatton National Bank (HNB)', acc: '0281923485', method: 'CEFT' },
    { bank: 'Sampath Bank', acc: '1092384756', method: 'CEFT' },
    { bank: "People's Bank", acc: '2981746253', method: 'SLIP' },
  ];

  let setIndex = 100;
  for (const target of settlementTargets) {
    // Create 1 pending, 1 processing, 2 settled, 1 on_hold for each target!
    const statuses = [
      { status: 'pending', gross: 35000, fee: 1750, ref: null, hold: null },
      { status: 'processing', gross: 48000, fee: 2400, ref: null, hold: null },
      { status: 'settled', gross: 65000, fee: 3250, ref: `CEFT-${2026000 + setIndex}`, hold: null },
      { status: 'settled', gross: 82000, fee: 4100, ref: `SLIP-${2026100 + setIndex}`, hold: null },
      { status: 'on_hold', gross: 55000, fee: 2750, ref: null, hold: 'Bank branch verification pending confirmation.' },
    ];

    for (let i = 0; i < statuses.length; i++) {
      setIndex++;
      const s = statuses[i];
      const b = banks[(setIndex) % banks.length];
      const r = doc(collection(db, 'settlements'));
      await setDoc(r, {
        id: r.id,
        orderId: `ORD-${1000 + setIndex}`,
        orderNumber: `ORD-${1000 + setIndex}`,
        recipientId: target.uid,
        recipientName: target.name,
        recipientRole: target.role,
        bankName: b.bank,
        accountNumber: b.acc,
        payoutMethod: b.method,
        grossAmount: s.gross,
        platformFee: s.fee,
        netAmount: s.gross - s.fee,
        status: s.status,
        transactionReference: s.ref,
        holdReason: s.hold,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        settledAt: s.status === 'settled' ? serverTimestamp() : null
      });
    }
  }
  console.log(`[OK] Created comprehensive settlements for all targets across all statuses.`);

  // 5. SEED REVIEWS COVERING ALL MODERATION STATUSES & RATINGS
  console.log("\n--> 5. Seeding reviews (pending, approved, rejected, low rating)...");
  const reviewSpecs = [
    { rating: 5, status: 'pending', comment: 'Exceptional organic produce! Crispy carrots and vibrant fresh tomatoes. Highly recommended farmer.', reviewerName: 'Colombo Fresh Organics' },
    { rating: 4, status: 'pending', comment: 'Fast transport collection and very clean packaging. Arrived within 4 hours.', reviewerName: 'Grand Hotel Procurement' },
    { rating: 5, status: 'approved', comment: 'Consistently top-tier grade A vegetables directly from Nuwara Eliya highland farms.', reviewerName: 'Spice Island Catering' },
    { rating: 4, status: 'approved', comment: 'Reliable transporter with working cold chain monitoring. Goods arrived in pristine shape.', reviewerName: 'Lanka Super Center' },
    { rating: 1, status: 'pending', comment: 'Delivery was delayed by 3 hours and some tomato boxes had crushing damage. Needs investigation.', reviewerName: 'Pettah Retail Mart' },
    { rating: 2, status: 'rejected', comment: 'Driver was rude and refused to wait for offloading. Unacceptable logistics behavior.', reviewerName: 'Negombo Fresh Produce', note: 'Escalated to dispute resolution' },
    { rating: 1, status: 'approved', comment: 'Received lower grade potatoes than agreed in the purchase contract.', reviewerName: 'Kandy Hotel Chain' },
    { rating: 5, status: 'approved', comment: 'Smooth automated escrow release once delivery was verified. Great platform experience!', reviewerName: 'Sunil Perera' },
  ];

  let revIdx = 10;
  for (const rspec of reviewSpecs) {
    revIdx++;
    const r = doc(collection(db, 'reviews'));
    await setDoc(r, {
      id: r.id,
      orderId: `ORD-${1050 + revIdx}`,
      orderNumber: `ORD-${1050 + revIdx}`,
      reviewerId: demoBuyerId,
      reviewerName: rspec.reviewerName,
      subjectId: demoFarmerId,
      subjectName: 'Sunil Perera (Nuwara Eliya Farms)',
      rating: rspec.rating,
      comment: rspec.comment,
      status: rspec.status,
      moderationStatus: rspec.status,
      moderationNote: rspec.note || (rspec.status === 'approved' ? 'Verified genuine customer transaction' : null),
      createdAt: serverTimestamp(),
      moderatedAt: rspec.status !== 'pending' ? serverTimestamp() : null
    });
  }
  console.log(`[OK] Seeded ${reviewSpecs.length} reviews covering all filter states.`);

  // 6. SEED MARKET PRICE REPORTS (For Admin Price Reports Review Tab)
  console.log("\n--> 6. Seeding Market Price Reports for Admin Review tab...");
  const priceReports = [
    { crop: 'Organic Carrots', cat: 'Vegetables', market: 'Nuwara Eliya Dedicated Economic Centre', district: 'Nuwara Eliya', price: 42000, unit: 'kg' },
    { crop: 'Red Onions', cat: 'Vegetables', market: 'Dambulla Dedicated Economic Centre', district: 'Matale', price: 38000, unit: 'kg' },
    { crop: 'Green Chillies', cat: 'Vegetables', market: 'Pettah Wholesale Market', district: 'Colombo', price: 65000, unit: 'kg' },
    { crop: 'Highland Potatoes', cat: 'Vegetables', market: 'Welimada Economic Centre', district: 'Badulla', price: 32000, unit: 'kg' },
    { crop: 'King Coconuts', cat: 'Fruits', market: 'Meegoda Dedicated Economic Centre', district: 'Colombo', price: 9500, unit: 'piece' },
    { crop: 'Samba Rice', cat: 'Grains', market: 'Polonnaruwa Rice Market', district: 'Polonnaruwa', price: 24000, unit: 'kg' },
  ];

  for (const pr of priceReports) {
    const r = doc(collection(db, 'market_price_reports'));
    await setDoc(r, {
      id: r.id,
      cropName: pr.crop,
      category: pr.cat,
      marketName: pr.market,
      district: pr.district,
      priceMinor: pr.price,
      unit: pr.unit,
      status: 'pending',
      reporterRole: 'farmer',
      reporterId: demoFarmerId,
      createdAt: serverTimestamp()
    });
  }
  console.log(`[OK] Seeded ${priceReports.length} pending market price reports.`);

  // 7. VERIFICATION DOCS FOR ADMIN VERIFICATION REVIEW TAB
  console.log("\n--> 7. Seeding Verification Docs for Admin Verification Review tab...");
  const verifDocs = [
    { userId: kajalTransporterId, userName: 'Kajal Express Transporter', role: 'transporter', type: 'Heavy Vehicle Commercial Driving License', status: 'pending' },
    { userId: demoTransporterId, userName: 'Island Logistics LK', role: 'transporter', type: 'Business Registration (BRC)', status: 'pending' },
    { userId: demoFarmerId, userName: 'Sunil Perera (Farmer)', role: 'farmer', type: 'Department of Agriculture Farmer Registration', status: 'pending' },
    { userId: testBuyerId, userName: 'Grand Hotel Colombo', role: 'buyer', type: 'VAT Registration Certificate', status: 'approved' },
  ];

  for (const vd of verifDocs) {
    const r = doc(collection(db, 'verification_docs'));
    await setDoc(r, {
      id: r.id,
      userId: vd.userId,
      userName: vd.userName,
      userRole: vd.role,
      title: vd.type,
      documentType: vd.type,
      description: `Official ${vd.type} document submitted for platform role verification.`,
      status: vd.status,
      storagePath: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600',
      documentUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=600',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
  }
  console.log(`[OK] Seeded ${verifDocs.length} verification docs.`);

  // 8. DISPUTES FOR ADMIN DISPUTES TAB
  console.log("\n--> 8. Seeding Disputes for Admin Disputes tab...");
  const disputes = [
    { orderId: 'ORD-1020', reason: 'Fresh tomatoes package had transit compression damage.', status: 'open', resolution: null },
    { orderId: 'ORD-1025', reason: 'Discrepancy in delivered potato weight (ordered 500kg, received 470kg).', status: 'open', resolution: null },
    { orderId: 'ORD-1015', reason: 'Escrow payment release delayed due to bank holiday.', status: 'resolved', resolution: 'Manual transfer confirmed via CEFT reference BOC-982173.' },
  ];

  for (const disp of disputes) {
    const r = doc(collection(db, 'disputes'));
    await setDoc(r, {
      id: r.id,
      orderId: disp.orderId,
      reason: disp.reason,
      status: disp.status,
      resolution: disp.resolution,
      openedBy: demoBuyerId,
      evidenceImages: ['https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=500'],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
  }
  console.log(`[OK] Seeded ${disputes.length} disputes.`);

  // 9. AUDIT LOGS FOR ADMIN AUDIT TAB
  console.log("\n--> 9. Seeding Audit Logs for Admin Audit Trail tab...");
  const auditEntries = [
    { action: 'USER_LOGIN', actor: 'admin@farmora.app', role: 'admin', details: 'Admin logged into administration console' },
    { action: 'SETTLEMENT_PROCESSED', actor: 'finance@farmora.app', role: 'finance', details: 'Processed CEFT batch payout LKR 65,000 to Sunil Perera' },
    { action: 'JOB_ACCEPTED', actor: 'transporter@farmora.app', role: 'transporter', details: 'Accepted Nuwara Eliya to Colombo bulk delivery' },
    { action: 'ORDER_ESCROW_LOCKED', actor: 'buyer@farmora.app', role: 'buyer', details: 'Buyer deposited LKR 48,000 into escrow holding' },
    { action: 'PRICE_REPORT_SUBMITTED', actor: 'farmer@farmora.app', role: 'farmer', details: 'Farmer reported Dambulla Red Onion price LKR 380/kg' },
    { action: 'SETTINGS_UPDATED', actor: 'admin@farmora.app', role: 'admin', details: 'Updated platform commission rate to 5.0%' },
  ];

  for (const ae of auditEntries) {
    const r = doc(collection(db, 'audit_logs'));
    await setDoc(r, {
      id: r.id,
      action: ae.action,
      actionType: ae.action,
      actorId: adminUid,
      actor: ae.actor,
      actorRole: ae.role,
      details: ae.details,
      timestamp: serverTimestamp(),
      createdAt: serverTimestamp(),
      ipAddress: '127.0.0.1'
    });
  }
  console.log(`[OK] Seeded ${auditEntries.length} audit logs.`);

  // 10. PLATFORM SETTINGS (Global Configuration)
  console.log("\n--> 10. Initializing platform_settings/global...");
  await setDoc(doc(db, 'platform_settings', 'global'), {
    maintenanceMode: false,
    maintenanceNotice: 'Platform scheduled maintenance in progress. Marketplace trades will resume shortly.',
    platformFeeBps: 500,
    commissionRate: 5.0,
    sessionTimeoutMinutes: 60,
    defaultDeliveryFeeMinor: 35000,
    escrowReleaseHours: 48,
    minAppVersion: '1.0.0',
    updatedAt: serverTimestamp(),
    updatedBy: adminUid
  }, { merge: true });
  console.log("[OK] platform_settings/global saved.");

  console.log("\n=======================================================");
  console.log("       MASTER SEEDING COMPLETED WITH 100% SUCCESS       ");
  console.log("=======================================================");
  process.exit(0);
}

runMasterSeed().catch(err => {
  console.error("Master seed error:", err);
  process.exit(1);
});
