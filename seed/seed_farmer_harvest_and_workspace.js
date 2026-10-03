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

// High-quality Unsplash image directory by produce
const IMAGES = {
  red_onion: 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=800&auto=format&fit=crop',
  cassava: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=800&auto=format&fit=crop',
  drumstick: 'https://images.unsplash.com/photo-1551893478-d726eaf0442c?w=800&auto=format&fit=crop',
  green_chili: 'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?w=800&auto=format&fit=crop',
  red_chili: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&auto=format&fit=crop',
  potato: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=800&auto=format&fit=crop',
  carrot: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=800&auto=format&fit=crop',
  capsicum: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=800&auto=format&fit=crop',
  ginger: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop',
  corn: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=800&auto=format&fit=crop',
  papaya: 'https://images.unsplash.com/photo-1617112848923-cc2234396a8d?w=800&auto=format&fit=crop',
  banana: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=800&auto=format&fit=crop',
  guava: 'https://images.unsplash.com/photo-1536511132770-e5058c7e8c46?w=800&auto=format&fit=crop',
  passion_fruit: 'https://images.unsplash.com/photo-1589135233689-d655f0134f59?w=800&auto=format&fit=crop',
  cinnamon: 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?w=800&auto=format&fit=crop',
  black_pepper: 'https://images.unsplash.com/photo-1599940824399-b87987ceb72a?w=800&auto=format&fit=crop',
  cardamom: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop',
  turmeric: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop',
  beetroot: 'https://images.unsplash.com/photo-1593105544559-ecb03bf76f82?w=800&auto=format&fit=crop',
  radish: 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=800&auto=format&fit=crop',
  leeks: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=800&auto=format&fit=crop',
  cauliflower: 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=800&auto=format&fit=crop',
  cabbage: 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=800&auto=format&fit=crop',
  strawberry: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=800&auto=format&fit=crop',
  tomato: 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&auto=format&fit=crop',
  cherry_tomato: 'https://images.unsplash.com/photo-1546470427-e26264be0b11?w=800&auto=format&fit=crop',
  curry_leaves: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop',
  king_coconut: 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=800&auto=format&fit=crop',
  okra: 'https://images.unsplash.com/photo-1627916607164-7b20241db935?w=800&auto=format&fit=crop',
  bitter_gourd: 'https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?w=800&auto=format&fit=crop',
  pumpkin: 'https://images.unsplash.com/photo-1506917728037-b6af01a7d403?w=800&auto=format&fit=crop',
  brinjal: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop',
  beans: 'https://images.unsplash.com/photo-1551893478-d726eaf0442c?w=800&auto=format&fit=crop',
  rice: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&auto=format&fit=crop',
};

// Farmer harvest item configurations
const FARMER_CATALOG = {
  // 1. Sureka Apputhurai
  '70MmvFXC39SwHa4zWK2KmyppY9h1': {
    name: 'Sureka Apputhurai',
    district: 'Jaffna',
    location: 'Thirunelveli, Jaffna',
    products: [
      { name: 'Fresh Jaffna Red Onions', cat: 'Vegetables', priceMinor: 48000, qty: 250, unit: 'kg', img: IMAGES.red_onion, organic: true, desc: 'Grade-A pungent red shallots organically grown in sandy Jaffna loam.' },
      { name: 'Jaffna Sweet Cassava', cat: 'Vegetables', priceMinor: 22000, qty: 180, unit: 'kg', img: IMAGES.cassava, organic: true, desc: 'Freshly harvested fibrous and buttery Jaffna sweet manioc roots.' },
      { name: 'Jaffna Drumsticks (Murunga)', cat: 'Vegetables', priceMinor: 38000, qty: 85, unit: 'kg', img: IMAGES.drumstick, organic: false, desc: 'Tender fresh green drumsticks rich in minerals and iron.' },
      { name: 'Northern Green Chilies', cat: 'Vegetables', priceMinor: 62000, qty: 65, unit: 'kg', img: IMAGES.green_chili, organic: true, desc: 'Spicy, firm Jaffna green chillies directly picked from sun-drenched plots.' },
      { name: 'Jaffna Sun-Dried Red Chilies', cat: 'Spices', priceMinor: 85000, qty: 40, unit: 'kg', img: IMAGES.red_chili, organic: true, desc: 'Traditional wood-rack sun-dried red chilies with intense aroma.' }
    ]
  },

  // 2. ahsan
  'QuE8rEuS9lTW5mcnPNXh0bWwS3M2': {
    name: 'ahsan',
    district: 'Badulla',
    location: 'Welimada Highland Valley, Badulla',
    products: [
      { name: 'Welimada Highland Potatoes', cat: 'Vegetables', priceMinor: 36000, qty: 450, unit: 'kg', img: IMAGES.potato, organic: false, desc: 'Premium golden highland potatoes with thin skin and fluffy texture.' },
      { name: 'Fresh Upcountry Carrots', cat: 'Vegetables', priceMinor: 42000, qty: 320, unit: 'kg', img: IMAGES.carrot, organic: true, desc: 'Crunchy sweet orange carrots harvested from cool mist-covered terraces.' },
      { name: 'Crisp Bell Peppers (Capsicum)', cat: 'Vegetables', priceMinor: 54000, qty: 140, unit: 'kg', img: IMAGES.capsicum, organic: true, desc: 'Vibrant green and yellow bell peppers with thick juicy walls.' },
      { name: 'Highland Fresh Ginger', cat: 'Spices', priceMinor: 85000, qty: 90, unit: 'kg', img: IMAGES.ginger, organic: true, desc: 'Potent and fragrant organic ginger rhizomes with strong medicinal value.' },
      { name: 'Sweet Golden Highland Corn', cat: 'Grains', priceMinor: 28000, qty: 220, unit: 'kg', img: IMAGES.corn, organic: false, desc: 'Sweet, tender yellow sweetcorn cobs ready for roasting or boiling.' }
    ]
  },

  // 3. kajana
  'UiFg4RfBu6WPDln3vF7BOHieAUJ2': {
    name: 'kajana',
    district: 'Jaffna',
    location: 'Chavakachcheri, Jaffna',
    products: [
      { name: 'Jaffna Red Lady Papaya', cat: 'Fruits', priceMinor: 26000, qty: 240, unit: 'kg', img: IMAGES.papaya, organic: true, desc: 'Rich reddish-orange flesh with high sugar brix and fragrant honey aroma.' },
      { name: 'Cavendish Sweet Bananas', cat: 'Fruits', priceMinor: 29000, qty: 190, unit: 'kg', img: IMAGES.banana, organic: true, desc: 'Naturally ripened, blemish-free dessert bananas from sheltered groves.' },
      { name: 'Sweet Apple Guava', cat: 'Fruits', priceMinor: 34000, qty: 150, unit: 'kg', img: IMAGES.guava, organic: false, desc: 'Crunchy white-fleshed guavas loaded with natural Vitamin C.' },
      { name: 'Fresh Purple Passion Fruit', cat: 'Fruits', priceMinor: 52000, qty: 95, unit: 'kg', img: IMAGES.passion_fruit, organic: true, desc: 'Deep purple wrinkled skins indicating ultra-sweet tropical pulpy juice.' }
    ]
  },

  // 4. KAJANA
  'kgJE3Sw9Z0Vgq2MEtNBRfYCo0t03': {
    name: 'KAJANA',
    district: 'Matale',
    location: 'Spice Hills Estate, Matale',
    products: [
      { name: 'Pure Ceylon Alba Cinnamon Quills', cat: 'Spices', priceMinor: 280000, qty: 45, unit: 'kg', img: IMAGES.cinnamon, organic: true, desc: 'Highest Alba grade hand-rolled thin quills of authentic Ceylon cinnamon.' },
      { name: 'Malabar Bold Black Pepper', cat: 'Spices', priceMinor: 195000, qty: 70, unit: 'kg', img: IMAGES.black_pepper, organic: true, desc: 'High piperine black peppercorns from Matale hillside shade plantations.' },
      { name: 'Ceylon Green Cardamom Pods', cat: 'Spices', priceMinor: 450000, qty: 25, unit: 'kg', img: IMAGES.cardamom, organic: true, desc: 'Intensely fragrant green pods carefully sorted for uniform size and aroma.' },
      { name: 'Fresh Raw Turmeric Roots', cat: 'Spices', priceMinor: 42000, qty: 160, unit: 'kg', img: IMAGES.turmeric, organic: true, desc: 'High-curcumin raw organic turmeric fingers freshly harvested from dark soil.' }
    ]
  },

  // 5. Sunil Fernando
  'A3q9tJM51ky1GbSpj4fi': {
    name: 'Sunil Fernando',
    district: 'Matale',
    location: 'Dambulla Outskirts, Matale',
    products: [
      { name: 'Matale Green Beans', cat: 'Vegetables', priceMinor: 45000, qty: 120, unit: 'kg', img: IMAGES.beans, organic: false, desc: 'Snap beans grown under controlled drip irrigation in sunny Dambulla.' }
    ],
    updatePrices: {
      'Fresh Carrots': 40000,
      'Potato': 35000,
      'Beetroot': 32000,
      'Radish': 24000
    }
  },

  // 6. Ravi Jayawardena
  'IOwcgTqSV0UwTeSEEeXf': {
    name: 'Ravi Jayawardena',
    district: 'Nuwara Eliya',
    location: 'Kandapola Highlands, Nuwara Eliya',
    products: [
      { name: 'Nuwara Eliya Fresh Strawberries', cat: 'Fruits', priceMinor: 120000, qty: 60, unit: 'kg', img: IMAGES.strawberry, organic: true, desc: 'Hand-picked ruby red strawberries grown in cool mountain mist.' }
    ],
    updatePrices: {
      'Fresh Leeks': 36000,
      'Cauliflower': 48000,
      'Cabbage': 28000,
      'Spring Onions': 38000
    }
  },

  // 7. Kamal Perera
  'KNNSOZHCj6YBx3A9rHFD': {
    name: 'Kamal Perera',
    district: 'Kandy',
    location: 'Peradeniya Valley, Kandy',
    products: [
      { name: 'Organic Bitter Gourd (Karawila)', cat: 'Vegetables', priceMinor: 39000, qty: 90, unit: 'kg', img: IMAGES.bitter_gourd, organic: true, desc: 'Dark green, knobby bitter gourd with renowned natural health benefits.' }
    ],
    updatePrices: {
      'Fresh Tomatoes': 38000,
      'Banana (Ambul)': 24000,
      'Cherry Tomatoes': 65000
    }
  },

  // 8. Nimal Silva
  'MrwhaGjrO9B28XxSdpuy': {
    name: 'Nimal Silva',
    district: 'Gampaha',
    location: 'Mirigama Gardens, Gampaha',
    products: [
      { name: 'Fresh King Coconuts (Thambili)', cat: 'Fruits', priceMinor: 12000, qty: 250, unit: 'pieces', img: IMAGES.king_coconut, organic: true, desc: 'Sweet electrolyte-rich natural king coconuts fresh from the palm.' }
    ],
    updatePrices: {
      'Green Chilli': 58000,
      'Red Chilli': 72000,
      'Curry Leaves': 15000,
      'Capsicum Mix': 52000
    }
  },

  // 9. Dinesh Kumara
  'ZHKU7jZo8idcvVIbzFPo': {
    name: 'Dinesh Kumara',
    district: 'Badulla',
    location: 'Mahiyanganaya Flats, Badulla',
    products: [
      { name: 'Traditional Suwandel Rice', cat: 'Grains', priceMinor: 36000, qty: 500, unit: 'kg', img: IMAGES.rice, organic: true, desc: 'Aromatic traditional Sri Lankan white heirloom rice with low glycemic index.' }
    ],
    updatePrices: {
      'Ladies Finger (Okra)': 31000,
      'Bitter Gourd': 36000,
      'Pumpkin': 22000,
      'Brinjal': 34000,
      'Long Beans': 39000
    }
  },

  // 10. Test Farmer
  'elQqhnNbqefGexAuZFf0JlRV5B03': {
    name: 'Test Farmer',
    district: 'Colombo',
    location: 'Kaduwela Demonstration Farm, Colombo',
    products: []
  }
};

async function seedFarmers() {
  console.log("--> Authenticating as Admin...");
  const adminCred = await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  const adminUid = adminCred.user.uid;
  console.log(`[OK] Logged in as Admin (UID: ${adminUid})`);

  // Buyers for generating realistic orders
  const buyerList = [
    { id: 'RNlU1rgy5wPV9EUjUOusERLH9Rf1', name: 'Demo Buyer', district: 'Colombo', phone: '+94712345678' },
    { id: 'SjA4etQg5yWVCSBgLi0tgskBSyx2', name: 'Grand Hotel Procurement', district: 'Colombo', phone: '+94778899001' },
    { id: 'pFUFqDdpl5aDsInA6yFw2JXXQPh2', name: 'Lanka Fresh Supermarkets', district: 'Kandy', phone: '+94723344556' }
  ];

  let farmerIndex = 0;
  for (const [farmerId, cfg] of Object.entries(FARMER_CATALOG)) {
    farmerIndex++;
    console.log(`\n======================================================`);
    console.log(`[${farmerIndex}/10] Processing Farmer: ${cfg.name} (${farmerId})`);
    console.log(`======================================================`);

    // 1. UPDATE EXISTING ZERO-PRICED PRODUCTS (if any)
    if (cfg.updatePrices) {
      const existingProds = await getDocs(query(collection(db, 'products'), where('farmerId', '==', farmerId)));
      for (const pDoc of existingProds.docs) {
        const pd = pDoc.data();
        for (const [nameKey, newPrice] of Object.entries(cfg.updatePrices)) {
          if (pd.name.toLowerCase().includes(nameKey.toLowerCase())) {
            await updateDoc(doc(db, 'products', pDoc.id), {
              priceMinor: newPrice,
              pricePerUnit: newPrice / 100.0,
              price: `LKR ${(newPrice / 100).toFixed(0)}/${pd.unit || 'kg'}`,
              location: cfg.location,
              district: cfg.district,
              status: 'Active',
              updatedAt: serverTimestamp()
            });
            console.log(`  [Price Fixed] ${pd.name} -> Rs. ${newPrice / 100} / ${pd.unit}`);
          }
        }
      }
    }

    // 2. SEED NEW DISTINCT PRODUCTS
    const createdProductIds = [];
    for (const p of cfg.products) {
      // Check if product with this exact name already exists for this farmer
      const existSnap = await getDocs(query(
        collection(db, 'products'),
        where('farmerId', '==', farmerId),
        where('name', '==', p.name)
      ));

      if (existSnap.empty) {
        const pRef = doc(collection(db, 'products'));
        const pData = {
          farmerId: farmerId,
          farmerName: cfg.name,
          name: p.name,
          category: p.cat,
          priceMinor: p.priceMinor,
          pricePerUnit: p.priceMinor / 100.0,
          price: `LKR ${(p.priceMinor / 100).toFixed(0)}/${p.unit}`,
          quantityAvailable: p.qty,
          quantity: `${p.qty} ${p.unit}`,
          unit: p.unit,
          location: cfg.location,
          district: cfg.district,
          status: 'Active',
          isOrganic: p.organic,
          trustLevel: 'Verified',
          description: p.desc,
          imagePath: p.img,
          images: [p.img],
          imageUrls: [p.img],
          media: [p.img],
          harvestStatus: 'harvested',
          harvestDate: new Date().toISOString(),
          availabilityDate: new Date().toISOString(),
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        };
        await setDoc(pRef, pData);
        createdProductIds.push({ id: pRef.id, ...pData });
        console.log(`  [Product Created] ${p.name} (Rs. ${p.priceMinor / 100}/${p.unit}, Qty: ${p.qty})`);
      } else {
        const existingId = existSnap.docs[0].id;
        createdProductIds.push({ id: existingId, ...existSnap.docs[0].data() });
        console.log(`  [Product Exists] ${p.name} (id: ${existingId})`);
      }
    }

    // Also get all products of this farmer for order generation
    const allFarmerProds = await getDocs(query(collection(db, 'products'), where('farmerId', '==', farmerId)));
    const farmerProdList = allFarmerProds.docs.map(d => ({ id: d.id, ...d.data() }));

    // 3. SEED FARM PLOTS (2 plots)
    const existingPlots = await getDocs(query(collection(db, 'farm_plots'), where('farmerId', '==', farmerId)));
    let plot1Id = null, plot2Id = null;
    if (existingPlots.size < 2) {
      const plot1Ref = doc(collection(db, 'farm_plots'));
      plot1Id = plot1Ref.id;
      await setDoc(plot1Ref, {
        farmerId: farmerId,
        name: `${cfg.district} North Valley Plot A`,
        area: 2.5,
        areaUnit: 'acres',
        soilType: cfg.district === 'Jaffna' ? 'Sandy Red Latosol' : (cfg.district === 'Badulla' || cfg.district === 'Nuwara Eliya' ? 'Highland Clay Loam' : 'Alluvial Fertile Loam'),
        irrigation: 'Drip Irrigation System',
        notes: 'High yield fertile plot equipped with solar-powered drip emitters.',
        isDeleted: false,
        createdBy: farmerId,
        updatedBy: farmerId,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      const plot2Ref = doc(collection(db, 'farm_plots'));
      plot2Id = plot2Ref.id;
      await setDoc(plot2Ref, {
        farmerId: farmerId,
        name: `${cfg.district} Hillside Terraces B`,
        area: 1.8,
        areaUnit: 'acres',
        soilType: 'Organic Mulched Topsoil',
        irrigation: 'Rainwater Harvesting & Micro-Sprinklers',
        notes: 'Dedicated nursery and organic rotation field with natural windbreaks.',
        isDeleted: false,
        createdBy: farmerId,
        updatedBy: farmerId,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
      console.log(`  [Plots Created] 2 farm plots seeded for ${cfg.name}`);
    } else {
      plot1Id = existingPlots.docs[0].id;
      plot2Id = existingPlots.docs[1].id;
      console.log(`  [Plots Exist] 2+ farm plots already exist for ${cfg.name}`);
    }

    // 4. SEED CROP PLANS (2 crop plans)
    const existingCrops = await getDocs(query(collection(db, 'crop_plans'), where('farmerId', '==', farmerId)));
    let crop1Id = null;
    if (existingCrops.size < 2) {
      const now = new Date();
      const harvestDate1 = new Date(now.getTime() + 45 * 24 * 60 * 60 * 1000);
      const harvestDate2 = new Date(now.getTime() + 75 * 24 * 60 * 60 * 1000);

      const primaryCrop = cfg.products[0]?.name || 'Seasonal Highland Harvest';
      const secondaryCrop = cfg.products[1]?.name || 'Organic Rotation Crop';

      const crop1Ref = doc(collection(db, 'crop_plans'));
      crop1Id = crop1Ref.id;
      await setDoc(crop1Ref, {
        farmerId: farmerId,
        cropName: primaryCrop,
        area: 1.5,
        areaUnit: 'acres',
        plotId: plot1Id,
        plotName: `${cfg.district} North Valley Plot A`,
        plantedAt: Timestamp.fromDate(now),
        expectedHarvestAt: Timestamp.fromDate(harvestDate1),
        expectedYield: 1800,
        yieldUnit: 'kg',
        status: 'growing',
        notes: 'Targeting commercial grade quality; organic compost applied at vegetative stage.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      const crop2Ref = doc(collection(db, 'crop_plans'));
      await setDoc(crop2Ref, {
        farmerId: farmerId,
        cropName: secondaryCrop,
        area: 1.0,
        areaUnit: 'acres',
        plotId: plot2Id,
        plotName: `${cfg.district} Hillside Terraces B`,
        plantedAt: Timestamp.fromDate(now),
        expectedHarvestAt: Timestamp.fromDate(harvestDate2),
        expectedYield: 1200,
        yieldUnit: 'kg',
        status: 'planted',
        notes: 'Intercropped with legumes for natural nitrogen fixation.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
      console.log(`  [Crop Plans Created] 2 crop plans seeded for ${cfg.name}`);
    } else {
      crop1Id = existingCrops.docs[0].id;
      console.log(`  [Crop Plans Exist] Crop plans already present for ${cfg.name}`);
    }

    // 5. SEED FARM TASKS (3 farm tasks)
    const existingTasks = await getDocs(query(collection(db, 'farm_tasks'), where('farmerId', '==', farmerId)));
    if (existingTasks.size < 3) {
      const now = new Date();
      const due1 = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);
      const due2 = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
      const due3 = new Date(now.getTime() + 9 * 24 * 60 * 60 * 1000);

      const tasksToSeed = [
        { title: 'Apply organic neem extract bio-spray', priority: 'high', due: due1, desc: 'Preventative aphid and pest control across young foliage.' },
        { title: 'Inspect and flush drip emitters', priority: 'medium', due: due2, desc: 'Clean inline mesh filters and verify uniform flow rates.' },
        { title: 'Manual weeding and straw mulch top-up', priority: 'low', due: due3, desc: 'Retain soil moisture and prevent weed competition around stems.' }
      ];

      for (const t of tasksToSeed) {
        const tRef = doc(collection(db, 'farm_tasks'));
        await setDoc(tRef, {
          farmerId: farmerId,
          title: t.title,
          description: t.desc,
          cropId: crop1Id || '',
          cropName: cfg.products[0]?.name || 'Seasonal Produce',
          dueAt: Timestamp.fromDate(t.due),
          priority: t.priority,
          status: 'pending',
          completed: false,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        });
      }
      console.log(`  [Farm Tasks Created] 3 farm tasks seeded for ${cfg.name}`);
    } else {
      console.log(`  [Farm Tasks Exist] Tasks already present for ${cfg.name}`);
    }

    // 6. SEED FARM LEDGER ENTRIES (4 ledger entries: 1 income, 3 expenses)
    const existingLedger = await getDocs(query(collection(db, 'farm_ledger'), where('farmerId', '==', farmerId)));
    if (existingLedger.size < 4) {
      const ledgerEntries = [
        { type: 'income', category: 'produce_sale', amountMinor: 7500000, note: 'Wholesale harvest sale to Manning Market distributors.' },
        { type: 'expense', category: 'seed', amountMinor: 950000, note: 'Certified non-GMO hybrid seed purchase from Agri Dept.' },
        { type: 'expense', category: 'fertilizer', amountMinor: 1400000, note: 'Bulk organic cattle compost and bone meal delivery.' },
        { type: 'expense', category: 'labour', amountMinor: 1800000, note: 'Casual harvesting and packing labour wages (4 days).' }
      ];

      for (const le of ledgerEntries) {
        const lRef = doc(collection(db, 'farm_ledger'));
        await setDoc(lRef, {
          farmerId: farmerId,
          type: le.type,
          category: le.category,
          amountMinor: le.amountMinor,
          date: serverTimestamp(),
          cropId: crop1Id || '',
          cropName: cfg.products[0]?.name || 'Highland Crops',
          note: le.note,
          sourceId: '',
          isDeleted: false,
          createdBy: farmerId,
          updatedBy: farmerId,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp()
        });
      }
      console.log(`  [Ledger Created] 4 financial ledger records seeded for ${cfg.name}`);
    } else {
      console.log(`  [Ledger Exists] Farm ledger records already present for ${cfg.name}`);
    }

    // 7. SEED ORDERS FOR CRUD TESTING IN FARMER ORDERS SCREEN (2 orders: 1 pending, 1 accepted/completed)
    const existingOrders = await getDocs(query(collection(db, 'orders'), where('farmerId', '==', farmerId)));
    if (existingOrders.size < 2 && farmerProdList.length > 0) {
      const sampleProd1 = farmerProdList[0];
      const sampleProd2 = farmerProdList.length > 1 ? farmerProdList[1] : farmerProdList[0];
      const buyer1 = buyerList[(farmerIndex - 1) % buyerList.length];
      const buyer2 = buyerList[(farmerIndex) % buyerList.length];

      // Order 1: Pending (allows farmer to test "Accept / Process" CRUD in Farmer Orders tab!)
      const o1Ref = doc(collection(db, 'orders'));
      const qty1 = 25;
      const unitPrice1 = sampleProd1.priceMinor || 45000;
      const total1 = qty1 * unitPrice1;
      await setDoc(o1Ref, {
        orderNumber: `ORD-${2000 + farmerIndex * 10 + 1}`,
        farmerId: farmerId,
        farmerName: cfg.name,
        buyerId: buyer1.id,
        buyerName: buyer1.name,
        buyerPhone: buyer1.phone,
        productId: sampleProd1.id,
        productName: sampleProd1.name,
        items: [{
          productId: sampleProd1.id,
          productName: sampleProd1.name,
          quantity: qty1,
          unit: sampleProd1.unit || 'kg',
          unitPriceMinor: unitPrice1,
          totalPriceMinor: total1
        }],
        totalMinor: total1,
        total: `LKR ${(total1 / 100).toFixed(2)}`,
        status: 'pending',
        deliveryAddress: `No. ${12 + farmerIndex}, Commercial High Street, ${buyer1.district}`,
        district: buyer1.district,
        deliveryDate: new Date(Date.now() + 3 * 86400000).toISOString(),
        notes: 'Please pack in ventilated crates for express road transport.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      // Order 2: Accepted / In-progress (allows farmer to test "Ready for Dispatch / Mark Completed")
      const o2Ref = doc(collection(db, 'orders'));
      const qty2 = 40;
      const unitPrice2 = sampleProd2.priceMinor || 38000;
      const total2 = qty2 * unitPrice2;
      await setDoc(o2Ref, {
        orderNumber: `ORD-${2000 + farmerIndex * 10 + 2}`,
        farmerId: farmerId,
        farmerName: cfg.name,
        buyerId: buyer2.id,
        buyerName: buyer2.name,
        buyerPhone: buyer2.phone,
        productId: sampleProd2.id,
        productName: sampleProd2.name,
        items: [{
          productId: sampleProd2.id,
          productName: sampleProd2.name,
          quantity: qty2,
          unit: sampleProd2.unit || 'kg',
          unitPriceMinor: unitPrice2,
          totalPriceMinor: total2
        }],
        totalMinor: total2,
        total: `LKR ${(total2 / 100).toFixed(2)}`,
        status: 'accepted',
        deliveryAddress: `Harbour Central Logistics Hub, ${buyer2.district}`,
        district: buyer2.district,
        deliveryDate: new Date(Date.now() + 2 * 86400000).toISOString(),
        notes: 'Quality checked and confirmed for cold storage transport.',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      console.log(`  [Orders Created] 2 orders (1 pending, 1 accepted) seeded for ${cfg.name}`);
    } else {
      console.log(`  [Orders Exist] Orders already present for ${cfg.name}`);
    }
  }

  console.log(`\n======================================================`);
  console.log(`       ALL 10 FARMERS SEEDED AND VERIFIED!            `);
  console.log(`======================================================`);
  process.exit(0);
}

seedFarmers().catch(err => {
  console.error("Farmer seed error:", err);
  process.exit(1);
});
