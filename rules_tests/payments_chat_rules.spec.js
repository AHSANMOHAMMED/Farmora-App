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
  serverTimestamp, deleteField, deleteDoc,
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

// Orders, offers and products are created by Cloud Functions (createOrder,
// acceptOffer, createProduct …); clients can no longer write them directly.
describe('checkout (server-owned)', () => {
  beforeEach(() => seed());

  it('buyer cannot create an order directly', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'orders', 'new1'), {
      buyerId: 'buyer1', farmerId: 'farmer1', productId: 'prod1', status: 'pending',
      totalMinor: 105000, paymentMethod: 'cod', paymentStatus: 'payment_required',
    }));
  });

  it('idempotency records are server-only', async () => {
    await assertFails(getDoc(doc(db('buyer1'), 'idempotency_keys', 'k1')));
    await assertFails(setDoc(doc(db('buyer1'), 'idempotency_keys', 'k1'), { orderId: 'x' }));
  });

  it('existing orders stay private to their participants', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'orders', ORDER)));
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
    // The unscoped query is rejected by the rules.
    await assertFails(getDocs(query(collection(db('farmer1'), 'transport_jobs'),
      where('orderId', '==', ORDER),
      where('status', 'in', ['requested', 'accepted', 'pickedUp', 'inTransit']))));
  });

  it('buyers cannot touch product stock or pricing', async () => {
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { quantityAvailable: 48 }));
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { priceMinor: 1 }));
  });
});

describe('bank details', () => {
  beforeEach(() => seed());

  it('only the owner (or an admin) can read payout details', async () => {
    await assertSucceeds(getDoc(doc(db('farmer1'), 'bank_details', 'farmer1')));
    await assertFails(getDoc(doc(db('buyer1'), 'bank_details', 'farmer1')));
  });

  it('farmer can save their own payout account', async () => {
    await assertSucceeds(setDoc(doc(db('farmer1'), 'bank_details', 'farmer1'), {
      farmerId: 'farmer1', bankName: 'HNB', branch: 'Galle',
      accountHolderName: 'F One', accountNumber: '87654321', updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(db('buyer1'), 'bank_details', 'buyer1'), {
      farmerId: 'buyer1', bankName: 'HNB', branch: 'Galle',
      accountHolderName: 'B One', accountNumber: '87654321',
    }));
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

  async function seedConvo() {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(doc(adminDb, 'conversations', CONVO), {
        orderId: ORDER, participantIds: ['buyer1', 'farmer1'], lastMessage: '',
        unreadCounts: { buyer1: 0, farmer1: 3 }, lastReadAt: {},
      });
      await setDoc(doc(adminDb, 'messages', 'm1'), {
        orderId: ORDER, conversationId: CONVO, participantIds: ['buyer1', 'farmer1'],
        senderId: 'buyer1', receiverId: 'farmer1', recipientId: 'farmer1',
        type: 'text', ciphertext: 'farmora3:' + 'x'.repeat(40),
      });
      // Legacy message written before participantIds existed.
      await setDoc(doc(adminDb, 'messages', 'legacy'), {
        orderId: ORDER, conversationId: CONVO, senderId: 'buyer1',
        receiverId: 'farmer1', type: 'text', ciphertext: 'farmora3:' + 'y'.repeat(40),
      });
    });
  }

  it('a missing conversation can be checked but not created by clients', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'conversations', CONVO)));
    await assertFails(setDoc(doc(db('buyer1'), 'conversations', CONVO), {
      orderId: ORDER, participantIds: ['buyer1', 'farmer1'],
    }));
  });

  it('only participants can read a conversation', async () => {
    await seedConvo();
    await assertSucceeds(getDoc(doc(db('farmer1'), 'conversations', CONVO)));
    await assertFails(getDoc(doc(db('stranger'), 'conversations', CONVO)));
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'conversations'),
      where('participantIds', 'array-contains', 'buyer1'))));
  });

  it('a participant may reset only their own unread counter', async () => {
    await seedConvo();
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'conversations', CONVO), {
      'unreadCounts.farmer1': 0, 'lastReadAt.farmer1': serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('farmer1'), 'conversations', CONVO), {
      'unreadCounts.buyer1': 0,
    }));
    await assertFails(updateDoc(doc(db('farmer1'), 'conversations', CONVO), {
      lastMessage: 'spoofed',
    }));
  });

  it('messages are written only by the sendMessage function', async () => {
    await seedConvo();
    await assertFails(setDoc(doc(db('buyer1'), 'messages', 'x1'), {
      orderId: ORDER, conversationId: CONVO, senderId: 'buyer1',
      participantIds: ['buyer1', 'farmer1'], ciphertext: 'farmora3:' + 'x'.repeat(40),
    }));
  });

  it('participants read messages; strangers cannot', async () => {
    await seedConvo();
    await assertSucceeds(getDoc(doc(db('farmer1'), 'messages', 'm1')));
    await assertSucceeds(getDoc(doc(db('farmer1'), 'messages', 'legacy')));
    await assertFails(getDoc(doc(db('stranger'), 'messages', 'm1')));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'messages'),
      where('conversationId', '==', CONVO),
      where('participantIds', 'array-contains', 'farmer1'))));
  });

  it('chat public keys: anyone signed in reads, only the owner writes', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'chat_keys', 'buyer1'), {
      publicKey: 'a'.repeat(44), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(getDoc(doc(db('farmer1'), 'chat_keys', 'buyer1')));
    await assertFails(setDoc(doc(db('farmer1'), 'chat_keys', 'buyer1'), {
      publicKey: 'b'.repeat(44),
    }));
    await assertFails(setDoc(doc(db('buyer1'), 'chat_keys', 'buyer1'), {
      publicKey: 'a'.repeat(44), extra: true,
    }));
  });
});

describe('server-owned collections', () => {
  beforeEach(() => seed());

  it('transporter profiles are readable but never client-written', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'transporter_profiles', 'trans1')));
    await assertFails(setDoc(doc(db('trans1'), 'transporter_profiles', 'trans1'), {
      isVerified: true,
    }));
  });

  it('reviews, disputes, settlements and notifications cannot be forged', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'reviews', 'r1'), {
      reviewerId: 'buyer1', rating: 5,
    }));
    await assertFails(setDoc(doc(db('buyer1'), 'disputes', 'd1'), {
      openedBy: 'buyer1', reason: 'x',
    }));
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's1'), {
      recipientId: 'farmer1', recipientRole: 'farmer', status: 'pending',
      grossAmount: 100, platformFee: 1, netAmount: 99, bankName: 'BOC',
      accountNumber: '12345678', payoutMethod: 'CEFT',
    }));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n1'), {
      userId: 'farmer1', title: 'Fake', body: 'Fake', read: false,
    }));
  });

  it('users cannot delete their own profile document', async () => {
    await assertFails(deleteDoc(doc(db('buyer1'), 'users', 'buyer1')));
  });

  it('platform settings and advisories are readable by signed-in users', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'platform_settings', 'global')));
    await assertFails(setDoc(doc(db('buyer1'), 'platform_settings', 'global'), {
      maintenanceMode: true,
    }));
    await assertSucceeds(getDoc(doc(db('buyer1'), 'advisories', 'a1')));
    await assertFails(setDoc(doc(db('buyer1'), 'advisories', 'a1'), { title: 'x' }));
  });
});

describe('transporter ratings and issues', () => {
  beforeEach(() => seed());

  it('transporter reports issues via add() and edits only rating fields', async () => {
    await assertSucceeds(setDoc(doc(db('trans1'), 'transport_job_issues', 'auto1'), {
      logisticsProviderId: 'trans1', jobId: 'job1', note: 'Flat tyre',
    }));
    await assertSucceeds(getDoc(doc(db('trans1'), 'transport_job_ratings', 'missing')));
    await assertSucceeds(setDoc(doc(db('trans1'), 'transport_job_ratings', 'job1'), {
      logisticsProviderId: 'trans1', stars: 4, comment: 'ok',
    }));
    await assertSucceeds(updateDoc(doc(db('trans1'), 'transport_job_ratings', 'job1'), {
      stars: 5, updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('trans1'), 'transport_job_ratings', 'job1'), {
      logisticsProviderId: 'someone-else',
    }));
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
