// Firestore + Storage rules for the Spark-mode flows: checkout (COD / bank
// deposit), deposit-slip submission, farmer confirmation, product images and
// order chat. Run with the emulators:
//   npx firebase emulators:exec --only firestore,storage "npx mocha payments_chat_rules.spec.js"
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const {
  doc, setDoc, updateDoc, getDoc, collection, query, where, getDocs,
  serverTimestamp, deleteField, writeBatch,
} = require('firebase/firestore');
const { ref, uploadBytes, getBytes } = require('firebase/storage');

let env;
const ORDER = 'order1';
const SLIP_URL = 'https://firebasestorage.googleapis.com/v0/b/x/o/slip';
const CONVO = 'o_order1_buyer1_farmer1';

before(async () => {
  env = await initializeTestEnvironment({
    // Must match the emulator project so Storage rules' firestore.get() sees
    // the seeded documents.
    projectId: 'demo-farmora',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync('../firestore.rules', 'utf8'),
    },
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: fs.readFileSync('../storage.rules', 'utf8'),
    },
  });
});

after(async () => env && env.cleanup());

async function seed(orderOverrides = {}) {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [id, role] of [
      ['farmer1', 'farmer'], ['buyer1', 'buyer'], ['buyer2', 'buyer'],
      ['stranger', 'buyer'], ['trans1', 'transporter'],
    ]) {
      await setDoc(doc(db, 'users', id), { role, isVerified: true });
    }
    await setDoc(doc(db, 'products', 'prod1'), {
      farmerId: 'farmer1', name: 'Carrots', category: 'Vegetables',
      priceMinor: 35000, quantityAvailable: 50, unit: 'kg',
      location: 'Nuwara Eliya', status: 'Active',
    });
    await setDoc(doc(db, 'bank_details', 'farmer1'), {
      farmerId: 'farmer1', bankName: 'BOC', branch: 'Kandy',
      accountHolderName: 'F One', accountNumber: '12345678',
    });
    await setDoc(doc(db, 'orders', ORDER), {
      buyerId: 'buyer1', farmerId: 'farmer1', productId: 'prod1',
      status: 'pending', totalMinor: 735000, subtotalMinor: 700000,
      deliveryFeeMinor: 35000, deliveryAddress: '12 Galle Road',
      paymentMethod: 'bank_deposit', paymentStatus: 'pending',
      ...orderOverrides,
    });
  });
}

const db = (uid) => env.authenticatedContext(uid).firestore();
const storage = (uid) => env.authenticatedContext(uid).storage();

function checkoutOrder(extra = {}) {
  return {
    buyerId: 'buyer1', farmerId: 'farmer1', productId: 'prod1',
    status: 'pending', requestedQuantity: 2, subtotalMinor: 70000,
    deliveryFeeMinor: 35000, totalMinor: 105000,
    deliveryAddress: '12 Galle Road, Colombo', paymentMethod: 'cod',
    paymentStatus: 'pending', ...extra,
  };
}

describe('checkout', () => {
  beforeEach(() => seed());

  it('buyer can place a COD order priced from the catalog', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'orders', 'new1'), checkoutOrder()));
  });

  it('buyer can place a bank deposit order with the farmer\'s account', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'orders', 'new2'), checkoutOrder({
      paymentMethod: 'bank_deposit',
      bankDetailsSnapshot: { accountNumber: '12345678' },
    })));
  });

  it('rejects a tampered total', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'orders', 'new3'),
      checkoutOrder({ subtotalMinor: 100, totalMinor: 35100 })));
  });

  it('rejects an order created as already paid', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'orders', 'new4'),
      checkoutOrder({ paymentStatus: 'paid' })));
  });

  it('rejects an unknown payment method', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'orders', 'new5'),
      checkoutOrder({ paymentMethod: 'crypto' })));
  });

  it('checkout can read its not-yet-created idempotency order doc', async () => {
    // SparkBackend.createOrder reads orders/idem_… inside a transaction first.
    await assertSucceeds(getDoc(doc(db('buyer1'), 'orders', 'idem_does_not_exist')));
    // Existing orders stay private to their participants.
    await assertFails(getDoc(doc(db('stranger'), 'orders', ORDER)));
  });

  it('farmer can look up transport jobs for their order (Accept Order)', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'transport_jobs', 'job1'), {
        orderId: ORDER, farmerId: 'farmer1', buyerId: 'buyer1', status: 'requested',
      }));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'transport_jobs'),
      where('orderId', '==', ORDER), where('farmerId', '==', 'farmer1'),
      where('status', 'in', ['requested', 'accepted', 'pickedUp', 'inTransit']))));
    // The unscoped query (the old code) is rejected by the rules.
    await assertFails(getDocs(query(collection(db('farmer1'), 'transport_jobs'),
      where('orderId', '==', ORDER),
      where('status', 'in', ['requested', 'accepted', 'pickedUp', 'inTransit']))));
  });

  it('buyer can only decrease product stock', async () => {
    await assertSucceeds(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { quantityAvailable: 48 }));
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { quantityAvailable: 99 }));
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { priceMinor: 1 }));
  });
});

describe('products', () => {
  beforeEach(() => seed());

  it('farmer can create a product with image URLs', async () => {
    await assertSucceeds(setDoc(doc(db('farmer1'), 'products', 'p2'), {
      farmerId: 'farmer1', name: 'Beans', category: 'Vegetables', priceMinor: 20000,
      quantityAvailable: 10, unit: 'kg', location: 'Kandy',
      media: ['https://firebasestorage.googleapis.com/v0/b/x/o/a'],
    }));
  });

  it('farmer cannot create a product for someone else', async () => {
    await assertFails(setDoc(doc(db('farmer1'), 'products', 'p3'), {
      farmerId: 'farmer2', name: 'Beans', category: 'Vegetables', priceMinor: 1,
      quantityAvailable: 1, unit: 'kg', location: 'Kandy',
    }));
  });

  it('owner can replace images; blank farmerId (old edit bug) is rejected', async () => {
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'products', 'prod1'), {
      media: ['https://x/a'], imageUrls: ['https://x/a'], updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('farmer1'), 'products', 'prod1'), { farmerId: '' }));
  });
});

describe('deposit slip + payment confirmation', () => {
  beforeEach(() => seed());

  const proof = (uid = 'buyer1') => ({
    paymentStatus: 'proof_submitted',
    proofImageUrl: SLIP_URL,
    proofImagePath: `payment_slips/${ORDER}/${uid}_1.jpg`,
    proofSubmittedAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  it('buyer can submit a slip', async () => {
    await assertSucceeds(updateDoc(doc(db('buyer1'), 'orders', ORDER), proof()));
  });

  it('slip path must belong to this order and buyer', async () => {
    await assertFails(updateDoc(doc(db('buyer1'), 'orders', ORDER), {
      ...proof(), proofImagePath: 'payment_slips/other/buyer1_1.jpg',
    }));
  });

  it('buyer cannot mark own order paid', async () => {
    await assertFails(updateDoc(doc(db('buyer1'), 'orders', ORDER), {
      paymentStatus: 'paid', paidAt: serverTimestamp(),
    }));
  });

  it('farmer confirms a submitted slip; cannot confirm before one exists', async () => {
    await assertFails(updateDoc(doc(db('farmer1'), 'orders', ORDER), {
      paymentStatus: 'paid', paidAt: serverTimestamp(), paymentConfirmedBy: 'farmer1',
      updatedAt: serverTimestamp(),
    }));
    await updateDoc(doc(db('buyer1'), 'orders', ORDER), proof());
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'orders', ORDER), {
      paymentStatus: 'paid', paidAt: serverTimestamp(), paymentConfirmedBy: 'farmer1',
      rejectionReason: deleteField(), updatedAt: serverTimestamp(),
    }));
  });

  it('COD: farmer marks cash received only after delivery', async () => {
    await seed({ paymentMethod: 'cod' });
    const cash = {
      paymentStatus: 'paid', paidAt: serverTimestamp(),
      paymentConfirmedBy: 'farmer1', updatedAt: serverTimestamp(),
    };
    await assertFails(updateDoc(doc(db('farmer1'), 'orders', ORDER), cash));
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'orders', ORDER), { status: 'delivered' }));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'orders', ORDER), cash));
  });

  it('non-participants cannot read the order', async () => {
    await assertFails(getDoc(doc(db('stranger'), 'orders', ORDER)));
  });
});

describe('order chat', () => {
  beforeEach(() => seed());

  const convo = () => ({
    orderId: ORDER, participantIds: ['buyer1', 'farmer1'], lastMessage: '',
    lastMessageAt: serverTimestamp(), unreadCounts: {}, createdAt: serverTimestamp(),
  });

  async function openConvo() {
    await setDoc(doc(db('buyer1'), 'conversations', CONVO), convo());
  }

  function message(extra) {
    return {
      orderId: ORDER, conversationId: CONVO, senderId: 'buyer1',
      receiverId: 'farmer1', recipientId: 'farmer1',
      createdAt: serverTimestamp(), ...extra,
    };
  }

  it('buyer can check for and create the deterministic conversation', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'conversations', CONVO)));
    await assertSucceeds(setDoc(doc(db('buyer1'), 'conversations', CONVO), convo()));
  });

  it('outsiders cannot create a conversation on the order', async () => {
    await assertFails(setDoc(doc(db('stranger'), 'conversations', 'o_order1_farmer1_stranger'), {
      ...convo(), participantIds: ['farmer1', 'stranger'],
    }));
  });

  it('conversation id must match its order and participants', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'conversations', 'random'), convo()));
  });

  it('buyer sends encrypted text and a photo; farmer can read', async () => {
    await openConvo();
    const buyerDb = db('buyer1');
    const b = writeBatch(buyerDb);
    b.set(doc(buyerDb, 'messages', 'm1'),
      message({ type: 'text', ciphertext: 'farmora3:' + 'x'.repeat(40) }));
    b.update(doc(buyerDb, 'conversations', CONVO),
      { lastMessage: 'farmora3:xx', lastMessageAt: serverTimestamp() });
    await assertSucceeds(b.commit());
    await assertSucceeds(setDoc(doc(db('buyer1'), 'messages', 'm2'), message({
      type: 'image', attachmentUrl: 'https://firebasestorage.googleapis.com/x',
      attachmentPath: `chat/${ORDER}/buyer1/p.jpg`, attachmentKind: 'photo',
    })));
    await assertSucceeds(getDoc(doc(db('farmer1'), 'messages', 'm2')));
    await assertFails(getDoc(doc(db('stranger'), 'messages', 'm2')));
  });

  it('buyer sends the deposit slip in chat', async () => {
    await openConvo();
    await assertSucceeds(setDoc(doc(db('buyer1'), 'messages', 'm3'), message({
      type: 'image', attachmentUrl: SLIP_URL,
      attachmentPath: `payment_slips/${ORDER}/buyer1_1.jpg`,
      attachmentKind: 'payment_proof',
    })));
  });

  it('rejects plaintext, spoofed senders and foreign attachment paths', async () => {
    await openConvo();
    await assertFails(setDoc(doc(db('buyer1'), 'messages', 'x1'),
      message({ type: 'text', ciphertext: 'hi' })));
    await assertFails(setDoc(doc(db('farmer1'), 'messages', 'x2'),
      message({ type: 'text', ciphertext: 'farmora3:' + 'x'.repeat(40) })));
    await assertFails(setDoc(doc(db('buyer1'), 'messages', 'x3'), message({
      type: 'image', attachmentUrl: 'https://x',
      attachmentPath: `chat/${ORDER}/farmer1/p.jpg`, attachmentKind: 'photo',
    })));
  });

  it('farmer can list messages addressed to them', async () => {
    await openConvo();
    await setDoc(doc(db('buyer1'), 'messages', 'm4'),
      message({ type: 'text', ciphertext: 'farmora3:' + 'x'.repeat(40) }));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'messages'),
      where('conversationId', '==', CONVO), where('orderId', '==', ORDER),
      where('receiverId', '==', 'farmer1'))));
  });
});

describe('storage', () => {
  beforeEach(() => seed());
  const jpg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0]);
  const meta = { contentType: 'image/jpeg' };

  it('buyer uploads a slip; farmer reads it; strangers cannot', async () => {
    const path = `payment_slips/${ORDER}/buyer1_1.jpg`;
    await assertSucceeds(uploadBytes(ref(storage('buyer1'), path), jpg, meta));
    await assertSucceeds(getBytes(ref(storage('farmer1'), path)));
    await assertFails(getBytes(ref(storage('stranger'), path)));
  });

  it('only the order buyer can upload a slip, under their own uid', async () => {
    await assertFails(uploadBytes(ref(storage('farmer1'), `payment_slips/${ORDER}/farmer1_1.jpg`), jpg, meta));
    await assertFails(uploadBytes(ref(storage('buyer1'), `payment_slips/${ORDER}/buyer2_1.jpg`), jpg, meta));
  });

  it('chat photos are limited to order parties and images', async () => {
    await assertSucceeds(uploadBytes(ref(storage('farmer1'), `chat/${ORDER}/farmer1/a.jpg`), jpg, meta));
    await assertFails(uploadBytes(ref(storage('stranger'), `chat/${ORDER}/stranger/a.jpg`), jpg, meta));
    await assertFails(uploadBytes(ref(storage('farmer1'), `chat/${ORDER}/farmer1/a.svg`), jpg,
      { contentType: 'image/svg+xml' }));
  });

  it('farmer uploads product images only to their own folder', async () => {
    await assertSucceeds(uploadBytes(ref(storage('farmer1'), 'product_images/farmer1/a.jpg'), jpg, meta));
    await assertFails(uploadBytes(ref(storage('farmer1'), 'product_images/buyer1/a.jpg'), jpg, meta));
  });
});
