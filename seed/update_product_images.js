const { initializeApp } = require('firebase/app');
const { getAuth, signInWithEmailAndPassword } = require('firebase/auth');
const { getFirestore, collection, getDocs, doc, updateDoc } = require('firebase/firestore');

const app = initializeApp({ apiKey: "AIzaSyBbyW98LURPAlM5jcT_bdETj-3Xq2Yw5Kg", projectId: "farmingapp-24b34" });
const auth = getAuth(app);
const db = getFirestore(app);

function getProduceImage(name, category) {
  const n = (name || '').toLowerCase();
  const c = (category || '').toLowerCase();

  if (n.includes('cherry tomato')) {
    return 'https://images.unsplash.com/photo-1546470427-e26264be0b11?w=800&auto=format&fit=crop';
  }
  if (n.includes('tomato')) {
    return 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=800&auto=format&fit=crop';
  }
  if (n.includes('carrot')) {
    return 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=800&auto=format&fit=crop';
  }
  if (n.includes('potato')) {
    return 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=800&auto=format&fit=crop';
  }
  if (n.includes('spring onion') || n.includes('leek')) {
    return 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=800&auto=format&fit=crop';
  }
  if (n.includes('red onion')) {
    return 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=800&auto=format&fit=crop';
  }
  if (n.includes('onion')) {
    return 'https://images.unsplash.com/photo-1508747703725-719777637510?w=800&auto=format&fit=crop';
  }
  if (n.includes('cabbage')) {
    return 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=800&auto=format&fit=crop';
  }
  if (n.includes('cauliflower')) {
    return 'https://images.unsplash.com/photo-1568584711075-3d021a7c3ca3?w=800&auto=format&fit=crop';
  }
  if (n.includes('brinjal') || n.includes('eggplant')) {
    return 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop';
  }
  if (n.includes('green chil') || n.includes('green chilli')) {
    return 'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?w=800&auto=format&fit=crop';
  }
  if (n.includes('red chil') || n.includes('red chilli')) {
    return 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=800&auto=format&fit=crop';
  }
  if (n.includes('chili') || n.includes('chilli')) {
    return 'https://images.unsplash.com/photo-1588252303782-cb80119abd6d?w=800&auto=format&fit=crop';
  }
  if (n.includes('capsicum') || n.includes('bell pepper')) {
    return 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=800&auto=format&fit=crop';
  }
  if (n.includes('beetroot')) {
    return 'https://images.unsplash.com/photo-1593105544559-ecb03bf76f82?w=800&auto=format&fit=crop';
  }
  if (n.includes('pumpkin')) {
    return 'https://images.unsplash.com/photo-1506917728037-b6af01a7d403?w=800&auto=format&fit=crop';
  }
  if (n.includes('long bean') || n.includes('bean')) {
    return 'https://images.unsplash.com/photo-1551893478-d726eaf0442c?w=800&auto=format&fit=crop';
  }
  if (n.includes('okra') || n.includes('ladies finger')) {
    return 'https://images.unsplash.com/photo-1627916607164-7b20241db935?w=800&auto=format&fit=crop';
  }
  if (n.includes('bitter gourd')) {
    return 'https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?w=800&auto=format&fit=crop';
  }
  if (n.includes('radish')) {
    return 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=800&auto=format&fit=crop';
  }
  if (n.includes('curry leaves')) {
    return 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=800&auto=format&fit=crop';
  }
  if (n.includes('coconut')) {
    return 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?w=800&auto=format&fit=crop';
  }
  if (n.includes('banana')) {
    return 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=800&auto=format&fit=crop';
  }
  if (n.includes('rice') || c.includes('grain')) {
    return 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=800&auto=format&fit=crop';
  }
  if (c.includes('fruit')) {
    return 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800&auto=format&fit=crop';
  }
  return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&auto=format&fit=crop';
}

async function updateAllProductImages() {
  await signInWithEmailAndPassword(auth, '0094725068682@phone.farmora.app', 'admin123');
  console.log('Signed in as Admin');

  const snap = await getDocs(collection(db, 'products'));
  console.log(`Found ${snap.size} products to update`);

  let updatedCount = 0;
  for (const docSnap of snap.docs) {
    const data = docSnap.data();
    const realImg = getProduceImage(data.name, data.category);

    await updateDoc(doc(db, 'products', docSnap.id), {
      imagePath: realImg,
      images: [realImg],
      imageUrls: [realImg],
      media: [realImg],
    });
    updatedCount++;
    console.log(`[${updatedCount}/${snap.size}] Updated ${docSnap.id} (${data.name}) -> ${realImg.substring(0, 50)}...`);
  }

  console.log(`Successfully updated ${updatedCount} products with realistic photos!`);
  process.exit(0);
}

updateAllProductImages().catch(err => {
  console.error('Failed to update product images:', err);
  process.exit(1);
});
