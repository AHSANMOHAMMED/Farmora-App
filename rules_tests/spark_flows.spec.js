// Spark-plan (no Cloud Functions) client write flows, mirroring the batches
// lib/services/spark_backend.dart commits.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy,
  writeBatch, serverTimestamp, deleteField, arrayUnion, increment, Timestamp,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();
const admin = () => env.authenticatedContext('admin1').firestore();
const seedDocs = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

function orderData(id, o = {}) {
  const qty = o.requestedQuantity || 2;
  const price = o.price === undefined ? 35000 : o.price;
  const fee = o.deliveryFeeMinor === undefined ? 35000 : o.deliveryFeeMinor;
  const data = {
    orderNumber: 'FM-' + id.slice(0, 8).toUpperCase(),
    buyerId: 'buyer1', farmerId: 'farmer1', productId: 'prod1',
    productName: 'Carrots', title: 'Carrots', quantity: `${qty} kg`, unit: 'kg',
    listingVersion: 1,
    items: [{ productId: 'prod1', quantity: qty, pricePerUnitMinor: price, lineTotalMinor: price * qty }],
    requestedQuantity: qty,
    subtotalMinor: price * qty,
    deliveryFeeMinor: fee,
    totalMinor: price * qty + fee,
    platformFeeMinor: Math.round(price * qty * 250 / 10000),
    currency: 'LKR', deliveryAddress: '12 Galle Road, Colombo',
    pickupAddress: 'Nuwara Eliya', location: 'Nuwara Eliya',
    buyerName: 'buyer1', farmerName: 'farmer1', status: 'pending',
    paymentMethod: 'cod', paymentStatus: 'payment_required',
    escrowStatus: 'not_funded',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  };
  const { price: _p, ...rest } = o;
  return { ...data, ...rest };
}

function stock(id, qty) {
  return {
    quantityAvailable: qty, quantity: `${qty} kg available`,
    status: qty > 0 ? 'Active' : 'Empty', updatedAt: serverTimestamp(), lastOrderId: id,
  };
}

function checkout(uid, id, overrides = {}, stockAfter = 48) {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, 'orders', id), orderData(id, overrides));
  if (stockAfter !== null) batch.update(doc(d, 'products', 'prod1'), stock(id, stockAfter));
  return batch.commit();
}

function jobData(orderId, o = {}) {
  return {
    orderId, orderNumber: 'FM-X', farmerId: 'farmer1', buyerId: 'buyer1',
    farmerName: 'farmer1', buyerName: 'buyer1', title: 'Delivery for Carrots',
    route: 'A → B', detail: '2 kg · Ready for pickup', fee: 'LKR 350.00',
    offeredFeeMinor: 35000, deliveryFeeMinor: 35000, pickupAddress: 'A',
    dropoffAddress: 'B', pickup: 'A', dropoff: 'B', productName: 'Carrots',
    productId: 'prod1', quantity: '2 kg', quantityValue: 2, unit: 'kg',
    district: 'Nuwara Eliya', status: 'requested', accepted: false,
    transporterId: null, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    ...o,
  };
}

/** Seeds an order in [status] (and optionally its job) directly. */
async function seedOrder(id, status, extra = {}, job = null) {
  await seedDocs(async (a) => {
    await setDoc(doc(a, 'orders', id), { ...orderData(id), status,
      createdAt: new Date(), updatedAt: new Date(), ...extra });
    if (job) await setDoc(doc(a, 'transport_jobs', job.id), jobData(id, job.data));
  });
}

describe('Spark: buyer checkout', () => {
  beforeEach(() => seedBase(env));

  it('valid COD order with matching stock reservation succeeds', async () => {
    await assertSucceeds(checkout('buyer1', 'ck_1'));
  });

  it('a tampered unit price is rejected', async () => {
    await assertFails(checkout('buyer1', 'ck_2', { price: 100 }));
  });

  it('an inconsistent total is rejected', async () => {
    await assertFails(checkout('buyer1', 'ck_3', { totalMinor: 1000 }));
  });

  it('the order must reserve exactly its quantity of stock', async () => {
    await assertFails(checkout('buyer1', 'ck_4', {}, null));
    await assertFails(checkout('buyer1', 'ck_5', {}, 40));
  });

  it('buyers cannot touch stock or price outside checkout', async () => {
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), stock('nope', 10)));
    await assertFails(updateDoc(doc(db('buyer1'), 'products', 'prod1'), { priceMinor: 1 }));
  });

  it('money-state fields cannot be preset', async () => {
    await assertFails(checkout('buyer1', 'ck_6', { paymentStatus: 'paid' }));
    await assertFails(checkout('buyer1', 'ck_7', { transporterId: 'trans1' }));
    await assertFails(checkout('buyer1', 'ck_8', { status: 'confirmed' }));
    await assertFails(checkout('buyer2', 'ck_9')); // buyerId is buyer1
  });

  it('bank deposit needs a snapshot matching the farmer account', async () => {
    const snap = { bankName: 'BOC', branch: 'Kandy', accountHolderName: 'F One', accountNumber: '12345678' };
    await assertSucceeds(checkout('buyer1', 'ck_b1', { paymentMethod: 'bank_deposit', bankDetailsSnapshot: snap }));
    await assertFails(checkout('buyer1', 'ck_b2', {
      paymentMethod: 'bank_deposit', bankDetailsSnapshot: { ...snap, accountNumber: '99999999' },
    }, 46));
  });

  it('bank details are readable by signed-in users (deposit instructions)', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'bank_details', 'farmer1')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'bank_details', 'farmer1')));
  });

  it('a requested transporter must be a transporter', async () => {
    await assertSucceeds(checkout('buyer1', 'ck_t1', { requestedTransporterId: 'trans1' }));
    await assertFails(checkout('buyer1', 'ck_t2', { requestedTransporterId: 'buyer2' }, 46));
  });

  it('checkout may probe its idempotent order id', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'orders', 'ck_missing')));
  });

  it('suspended users cannot check out', async () => {
    await assertFails(checkout('suspended1', 'ck_s', { buyerId: 'suspended1' }));
  });
});

describe('Spark: farmer order decisions', () => {
  beforeEach(() => seedBase(env));

  it('farmer confirms a pending order and opens the transport job together', async () => {
    await seedOrder('o1', 'pending');
    const d = db('farmer1');
    const batch = writeBatch(d);
    batch.update(doc(d, 'orders', 'o1'), { status: 'confirmed', confirmedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.set(doc(d, 'transport_jobs', 'j1'), jobData('o1'));
    await assertSucceeds(batch.commit());
  });

  it('another farmer cannot confirm; jobs need a confirmed own order', async () => {
    await seedOrder('o1', 'pending');
    await assertFails(updateDoc(doc(db('farmer2'), 'orders', 'o1'), { status: 'confirmed', updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db('farmer1'), 'transport_jobs', 'j0'), jobData('o1')));
    await seedOrder('o2', 'confirmed', { farmerId: 'farmer2' });
    await assertFails(setDoc(doc(db('farmer1'), 'transport_jobs', 'j2'), jobData('o2')));
  });

  it('targeted job must match the order\'s requested transporter', async () => {
    await seedOrder('o1', 'confirmed', { requestedTransporterId: 'trans1' });
    await assertFails(setDoc(doc(db('farmer1'), 'transport_jobs', 'j1'), jobData('o1')));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'transport_jobs', 'j1'),
      jobData('o1', { transporterId: 'trans1', requestedTransporterId: 'trans1' })));
  });

  it('farmer declines a pending order and restores stock once', async () => {
    await seedOrder('o1', 'pending');
    const d = db('farmer1');
    const batch = writeBatch(d);
    batch.update(doc(d, 'orders', 'o1'), { status: 'rejected', stockRestored: true, rejectedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.update(doc(d, 'products', 'prod1'), stock('o1', 52));
    await assertSucceeds(batch.commit());
    await assertFails(updateDoc(doc(d, 'orders', 'o1'), { status: 'confirmed', updatedAt: serverTimestamp() }));
  });

  it('buyer cancels a pending order with an exact stock restore', async () => {
    await seedOrder('o1', 'pending');
    const d = db('buyer1');
    const ok = writeBatch(d);
    ok.update(doc(d, 'orders', 'o1'), { status: 'cancelled', stockRestored: true, cancelledAt: serverTimestamp(), cancelledBy: 'buyer1', updatedAt: serverTimestamp() });
    ok.update(doc(d, 'products', 'prod1'), stock('o1', 52));
    await assertSucceeds(ok.commit());
  });

  it('buyer cannot inflate stock or cancel a confirmed order', async () => {
    await seedOrder('o1', 'pending');
    const d = db('buyer1');
    const bad = writeBatch(d);
    bad.update(doc(d, 'orders', 'o1'), { status: 'cancelled', stockRestored: true, updatedAt: serverTimestamp() });
    bad.update(doc(d, 'products', 'prod1'), stock('o1', 90));
    await assertFails(bad.commit());
    await seedOrder('o2', 'confirmed');
    await assertFails(updateDoc(doc(d, 'orders', 'o2'), { status: 'cancelled', stockRestored: true, updatedAt: serverTimestamp() }));
  });

  it('money fields are immutable after creation', async () => {
    await seedOrder('o1', 'pending');
    await assertFails(updateDoc(doc(db('buyer1'), 'orders', 'o1'), { totalMinor: 1 }));
    await assertFails(updateDoc(doc(db('farmer1'), 'orders', 'o1'), { deliveryFeeMinor: 0 }));
  });

  it('farmer confirms handover once a transporter is assigned', async () => {
    await seedOrder('o1', 'assigned', { transporterId: 'trans1' });
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'orders', 'o1'), { farmerHandedOverAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await seedOrder('o2', 'pending');
    await assertFails(updateDoc(doc(db('farmer1'), 'orders', 'o2'), { farmerHandedOverAt: serverTimestamp() }));
  });

  it('buyer edits the address only while pending', async () => {
    await seedOrder('o1', 'pending');
    await assertSucceeds(updateDoc(doc(db('buyer1'), 'orders', 'o1'), { deliveryAddress: '44 Kandy Road', updatedAt: serverTimestamp() }));
    await seedOrder('o2', 'confirmed');
    await assertFails(updateDoc(doc(db('buyer1'), 'orders', 'o2'), { deliveryAddress: '44 Kandy Road' }));
  });
});

describe('Spark: transporter job flow', () => {
  beforeEach(() => seedBase(env));

  function accept(uid, jobId = 'j1', orderId = 'o1', withOrder = true) {
    const d = db(uid);
    const batch = writeBatch(d);
    batch.update(doc(d, 'transport_jobs', jobId), { status: 'accepted', transporterId: uid, accepted: true, acceptedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    if (withOrder) {
      batch.update(doc(d, 'orders', orderId), { status: 'assigned', transporterId: uid, transportJobId: jobId, assignedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    }
    return batch.commit();
  }

  function advance(uid, from, to) {
    const d = db(uid);
    const batch = writeBatch(d);
    batch.update(doc(d, 'transport_jobs', 'j1'), { status: to, [`${to}At`]: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.update(doc(d, 'orders', 'o1'), { status: to, [`${to}At`]: serverTimestamp(), updatedAt: serverTimestamp() });
    return batch.commit();
  }

  it('a verified transporter accepts an open job (job + order together)', async () => {
    await seedOrder('o1', 'confirmed', {}, { id: 'j1' });
    await assertFails(accept('transU'));
    await assertFails(accept('trans1', 'j1', 'o1', false));
    await assertSucceeds(accept('trans1'));
    await assertFails(accept('trans2'));
  });

  it('cannot self-assign an order without its job', async () => {
    await seedOrder('o1', 'confirmed', {}, { id: 'j1' });
    await assertFails(updateDoc(doc(db('trans1'), 'orders', 'o1'), {
      status: 'assigned', transporterId: 'trans1', transportJobId: 'nope', updatedAt: serverTimestamp(),
    }));
  });

  it('targeted request: only the chosen transporter accepts; they may decline', async () => {
    await seedOrder('o1', 'confirmed', { requestedTransporterId: 'trans1' },
      { id: 'j1', data: { transporterId: 'trans1', requestedTransporterId: 'trans1' } });
    await assertFails(accept('trans2'));
    await assertSucceeds(getDoc(doc(db('trans1'), 'orders', 'o1')));
    const d = db('trans1');
    const batch = writeBatch(d);
    batch.update(doc(d, 'transport_jobs', 'j1'), {
      transporterId: null, requestedTransporterId: deleteField(), declinedBy: arrayUnion('trans1'),
      declineReason: 'Vehicle in repair', declinedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    batch.update(doc(d, 'orders', 'o1'), { requestedTransporterId: deleteField(), updatedAt: serverTimestamp() });
    await assertSucceeds(batch.commit());
    // Now open to everyone.
    await assertSucceeds(accept('trans2'));
  });

  it('status advances only in order, by the assigned transporter', async () => {
    await seedOrder('o1', 'assigned', { transporterId: 'trans1', transportJobId: 'j1' },
      { id: 'j1', data: { status: 'accepted', transporterId: 'trans1', accepted: true } });
    await assertFails(advance('trans1', 'accepted', 'delivered'));
    await assertFails(advance('trans2', 'accepted', 'pickedUp'));
    await assertSucceeds(advance('trans1', 'accepted', 'pickedUp'));
    await assertSucceeds(advance('trans1', 'pickedUp', 'inTransit'));
    await assertSucceeds(updateDoc(doc(db('trans1'), 'transport_jobs', 'j1'), {
      courierLat: 7.29, courierLng: 80.63, locationUpdatedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(advance('trans1', 'inTransit', 'delivered'));
  });

  it('dropping before pickup reopens the job and the order', async () => {
    await seedOrder('o1', 'assigned', { transporterId: 'trans1', transportJobId: 'j1' },
      { id: 'j1', data: { status: 'accepted', transporterId: 'trans1', accepted: true } });
    const d = db('trans1');
    const batch = writeBatch(d);
    batch.update(doc(d, 'transport_jobs', 'j1'), {
      status: 'requested', transporterId: null, requestedTransporterId: deleteField(),
      accepted: false, acceptedAt: deleteField(), declinedBy: arrayUnion('trans1'),
      cancellationReason: 'Breakdown', droppedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    batch.update(doc(d, 'orders', 'o1'), {
      status: 'confirmed', transporterId: deleteField(), requestedTransporterId: deleteField(),
      transportJobId: deleteField(), updatedAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
    await assertSucceeds(accept('trans2'));
  });

  it('farmer cancels only a requested job', async () => {
    await seedOrder('o1', 'confirmed', {}, { id: 'j1' });
    const cancel = { status: 'cancelled', cancelledBy: 'farmer1', cancelledAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assertFails(updateDoc(doc(db('buyer1'), 'transport_jobs', 'j1'), cancel));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'transport_jobs', 'j1'), cancel));
    await seedOrder('o2', 'assigned', { transporterId: 'trans1' },
      { id: 'j2', data: { status: 'accepted', transporterId: 'trans1' } });
    await assertFails(updateDoc(doc(db('farmer1'), 'transport_jobs', 'j2'), cancel));
  });

  it('job read queries match the rules for every party', async () => {
    await seedOrder('o1', 'confirmed', {}, { id: 'j1' });
    await seedOrder('o2', 'assigned', { transporterId: 'trans1' },
      { id: 'j2', data: { status: 'accepted', transporterId: 'trans1' } });
    const jobs = (uid) => collection(db(uid), 'transport_jobs');
    await assertSucceeds(getDocs(query(jobs('farmer1'), where('farmerId', '==', 'farmer1'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(query(jobs('farmer1'), where('orderId', '==', 'o1'), where('farmerId', '==', 'farmer1'))));
    await assertSucceeds(getDocs(query(jobs('farmer1'), where('orderId', '==', 'o1'), where('farmerId', '==', 'farmer1'),
      where('status', 'in', ['requested', 'accepted', 'pickedUp', 'inTransit']))));
    await assertSucceeds(getDocs(query(jobs('buyer1'), where('orderId', '==', 'o1'), where('buyerId', '==', 'buyer1'))));
    await assertSucceeds(getDocs(query(jobs('trans2'), where('status', '==', 'requested'), where('transporterId', '==', null))));
    await assertSucceeds(getDocs(query(jobs('trans1'), where('transporterId', '==', 'trans1'), orderBy('createdAt', 'desc'))));
    await assertFails(getDocs(query(jobs('stranger'), where('buyerId', '==', 'buyer1'))));
    await assertFails(getDocs(query(jobs('buyer1'), where('orderId', '==', 'o1'))));
    await assertFails(getDocs(query(jobs('buyer1'), where('status', '==', 'requested'), where('transporterId', '==', null))));
  });
});

describe('Spark: order chat', () => {
  const CONVO = 'o_o1_buyer1_farmer1';
  beforeEach(async () => {
    await seedBase(env);
    await seedOrder('o1', 'confirmed');
  });

  function send(uid, peer, { create = true, participantIds = ['buyer1', 'farmer1'], orderId = 'o1', convo = CONVO } = {}) {
    const d = db(uid);
    const batch = writeBatch(d);
    if (create) {
      batch.set(doc(d, 'conversations', convo), {
        orderId, orderNumber: 'FM-O1', participantIds, lastMessage: 'farmora3:abc',
        lastMessageAt: serverTimestamp(), lastSenderId: uid,
        unreadCounts: { [peer]: 1, [uid]: 0 }, createdAt: serverTimestamp(),
      });
    } else {
      batch.update(doc(d, 'conversations', convo), {
        lastMessage: 'farmora3:abc', lastMessageAt: serverTimestamp(), lastSenderId: uid,
        [`unreadCounts.${peer}`]: increment(1),
      });
    }
    batch.set(doc(collection(d, 'messages')), {
      orderId, conversationId: convo, participantIds, senderId: uid,
      receiverId: peer, recipientId: peer, type: 'text',
      ciphertext: 'farmora3:' + 'x'.repeat(40), createdAt: serverTimestamp(),
    });
    return batch.commit();
  }

  it('an order party sends the first message (conversation created)', async () => {
    await assertSucceeds(send('buyer1', 'farmer1'));
    await assertSucceeds(send('farmer1', 'buyer1', { create: false }));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'messages'),
      where('conversationId', '==', CONVO), where('participantIds', 'array-contains', 'farmer1'))));
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'conversations'),
      where('participantIds', 'array-contains', 'buyer1'))));
  });

  it('non-participants cannot create conversations or messages', async () => {
    await assertFails(send('stranger', 'farmer1', {
      participantIds: ['farmer1', 'stranger'], convo: 'o_o1_farmer1_stranger',
    }));
    await assertSucceeds(send('buyer1', 'farmer1'));
    await assertFails(getDoc(doc(db('stranger'), 'conversations', CONVO)));
    await assertFails(getDocs(query(collection(db('stranger'), 'messages'),
      where('conversationId', '==', CONVO))));
  });

  it('messages must match the conversation and the sender', async () => {
    await assertSucceeds(send('buyer1', 'farmer1'));
    const d = db('buyer1');
    await assertFails(setDoc(doc(d, 'messages', 'spoof'), {
      orderId: 'o1', conversationId: CONVO, participantIds: ['buyer1', 'farmer1'],
      senderId: 'farmer1', receiverId: 'buyer1', recipientId: 'buyer1', type: 'text',
      ciphertext: 'farmora3:' + 'x'.repeat(40), createdAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(d, 'messages', 'short'), {
      orderId: 'o1', conversationId: CONVO, participantIds: ['buyer1', 'farmer1'],
      senderId: 'buyer1', receiverId: 'farmer1', recipientId: 'farmer1', type: 'text',
      ciphertext: 'plain', createdAt: serverTimestamp(),
    }));
  });

  it('participants reset only their own unread counter; senders bump the peer by one', async () => {
    await assertSucceeds(send('buyer1', 'farmer1'));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'conversations', CONVO), {
      'unreadCounts.farmer1': 0, 'lastReadAt.farmer1': serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('farmer1'), 'conversations', CONVO), { 'unreadCounts.buyer1': 7 }));
    await assertFails(updateDoc(doc(db('buyer1'), 'conversations', CONVO), {
      lastMessage: 'x', lastSenderId: 'buyer1', 'unreadCounts.farmer1': 50,
    }));
  });

  it('chat public keys: one collection (chat_keys), owner-written', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'chat_keys', 'buyer1'), { publicKey: 'a'.repeat(44), updatedAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(db('farmer1'), 'chat_keys', 'buyer1')));
    await assertFails(setDoc(doc(db('farmer1'), 'chat_keys', 'buyer1'), { publicKey: 'b'.repeat(44) }));
  });
});

describe('Spark: transporter public profiles', () => {
  beforeEach(() => seedBase(env));
  const card = (uid, o = {}) => ({
    id: uid, uid, displayName: uid, photoUrl: null, district: 'Kandy',
    vehicleType: 'Lorry', vehicleRegistration: 'WP-1234', vehicleCapacity: 1000,
    vehicleCapacityUnit: 'kg', serviceDistricts: ['Kandy'], availabilityStatus: 'available',
    isVerified: true, updatedAt: serverTimestamp(), ...o,
  });

  it('the owner writes their card with the true verification state', async () => {
    await assertSucceeds(setDoc(doc(db('trans1'), 'transporter_profiles', 'trans1'), card('trans1')));
    await assertFails(setDoc(doc(db('transU'), 'transporter_profiles', 'transU'), card('transU')));
    await assertSucceeds(setDoc(doc(db('transU'), 'transporter_profiles', 'transU'), card('transU', { isVerified: false })));
  });

  it('no writes to other cards, no self rating, no isSuspended key, not for buyers', async () => {
    await assertFails(setDoc(doc(db('trans1'), 'transporter_profiles', 'trans2'), card('trans2')));
    await assertFails(setDoc(doc(db('trans1'), 'transporter_profiles', 'trans1'), card('trans1', { rating: 5 })));
    await assertFails(setDoc(doc(db('trans1'), 'transporter_profiles', 'trans1'), card('trans1', { isSuspended: false })));
    await assertFails(setDoc(doc(db('buyer1'), 'transporter_profiles', 'buyer1'), card('buyer1', { isVerified: true })));
  });

  it('signed-in users list verified cards; admins refresh any card', async () => {
    await assertSucceeds(setDoc(doc(admin(), 'transporter_profiles', 'trans2'), card('trans2', { rating: 4.5 })));
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'transporter_profiles'), where('isVerified', '==', true))));
  });
});

describe('Spark: settlements / withdrawals', () => {
  beforeEach(() => seedBase(env));
  const wd = (uid, role, o = {}) => ({
    orderId: '', orderNumber: 'WD-ABC', recipientId: uid, recipientName: uid,
    recipientRole: role, grossAmount: 1500, platformFee: 0, netAmount: 1500,
    bankName: 'BOC', accountNumber: '12345678', payoutMethod: 'CEFT', status: 'pending',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  });

  it('a farmer / transporter requests their own bounded pending payout', async () => {
    await assertSucceeds(setDoc(doc(db('farmer1'), 'settlements', 's1'), wd('farmer1', 'farmer')));
    await assertSucceeds(setDoc(doc(db('trans1'), 'settlements', 's2'), wd('trans1', 'transporter')));
  });

  it('inconsistent or oversized requests are rejected', async () => {
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's3'), wd('farmer1', 'farmer', { netAmount: 9999 })));
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's4'), wd('farmer1', 'farmer', { status: 'settled' })));
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's5'), wd('farmer1', 'transporter')));
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's6'), wd('farmer2', 'farmer')));
    await assertFails(setDoc(doc(db('farmer1'), 'settlements', 's7'), wd('farmer1', 'farmer', { grossAmount: 20000000, netAmount: 20000000 })));
    await assertFails(setDoc(doc(db('buyer1'), 'settlements', 's8'), wd('buyer1', 'buyer')));
  });

  it('only admins move a payout; settled needs a reference', async () => {
    await seedDocs((a) => setDoc(doc(a, 'settlements', 's1'), wd('farmer1', 'farmer', { createdAt: new Date(), updatedAt: new Date() })));
    await assertFails(updateDoc(doc(db('farmer1'), 'settlements', 's1'), { status: 'settled', transactionReference: 'REF-1234' }));
    await assertFails(updateDoc(doc(admin(), 'settlements', 's1'), { status: 'settled', reviewedBy: 'admin1', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(admin(), 'settlements', 's1'), {
      status: 'settled', transactionReference: 'REF-1234', settledAt: serverTimestamp(),
      reviewedBy: 'admin1', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(admin(), 'settlements', 's1'), { status: 'processing', updatedAt: serverTimestamp() }));
  });
});

describe('Spark: admin-only writes', () => {
  beforeEach(() => seedBase(env));

  it('platform settings: readable by all signed-in users, admin-written', async () => {
    await assertSucceeds(getDoc(doc(db('buyer1'), 'platform_settings', 'global')));
    await assertFails(setDoc(doc(db('buyer1'), 'platform_settings', 'global'), { maintenanceMode: false }));
    await assertFails(setDoc(doc(db('farmer1'), 'platform_settings', 'global'), { sessionTimeoutMinutes: 0 }));
    await assertSucceeds(setDoc(doc(admin(), 'platform_settings', 'global'), { maintenanceMode: true, updatedBy: 'admin1' }, { merge: true }));
  });

  it('role / verification / suspension changes are admin-only', async () => {
    await assertFails(updateDoc(doc(db('buyer1'), 'users', 'buyer1'), { role: 'admin' }));
    await assertFails(updateDoc(doc(db('farmerU'), 'users', 'farmerU'), { isVerified: true }));
    await assertFails(updateDoc(doc(db('buyer1'), 'users', 'buyer2'), { isSuspended: true }));
    await assertFails(updateDoc(doc(db('suspended1'), 'users', 'suspended1'), { isSuspended: false }));
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'buyer2'), { role: 'farmer', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(admin(), 'users', 'buyer1'), { isSuspended: true, updatedAt: serverTimestamp() }));
  });

  it('an unverified admin profile is not an admin', async () => {
    await seedDocs((a) => setDoc(doc(a, 'users', 'fakeAdmin'), { role: 'admin', isVerified: false }));
    await assertFails(updateDoc(doc(db('fakeAdmin'), 'users', 'buyer2'), { role: 'farmer' }));
  });

  it('audit logs: admin-only, actorId must be the caller, append-only', async () => {
    const log = (actorId) => ({ actorId, actorName: 'A', actorRole: 'admin', actionType: 'USER_ROLE_CHANGED',
      targetEntity: 'users', targetId: 'buyer2', details: '', severity: 'warning', timestamp: serverTimestamp() });
    await assertSucceeds(setDoc(doc(admin(), 'audit_logs', 'a1'), log('admin1')));
    await assertFails(setDoc(doc(admin(), 'audit_logs', 'a2'), log('someone')));
    await assertFails(setDoc(doc(db('buyer1'), 'audit_logs', 'a3'), log('buyer1')));
    await assertFails(updateDoc(doc(admin(), 'audit_logs', 'a1'), { details: 'edited' }));
  });

  it('advisories and dispute resolution are admin-only', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'advisories', 'x'), { title: 'x' }));
    await assertSucceeds(setDoc(doc(admin(), 'advisories', 'x'), { title: 'x', body: 'y', audience: 'all' }));
    await seedDocs((a) => setDoc(doc(a, 'disputes', 'd1'), { orderId: 'o1', openedBy: 'buyer1', status: 'open' }));
    await assertFails(updateDoc(doc(db('buyer1'), 'disputes', 'd1'), { status: 'resolved' }));
    await assertSucceeds(updateDoc(doc(admin(), 'disputes', 'd1'), { status: 'resolved' }));
  });

  it('users may soft-delete (anonymise) only themselves', async () => {
    await assertSucceeds(updateDoc(doc(db('buyer2'), 'users', 'buyer2'), {
      name: 'Deleted User', displayName: 'Deleted User', phone: '',
      isDeleted: true, isSuspended: true, deletedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('buyer1'), 'users', 'buyer1'), { isDeleted: true, isSuspended: true, isVerified: false }));
  });
});

describe('Spark: notifications', () => {
  beforeEach(() => seedBase(env));
  const note = (userId, o = {}) => ({
    userId, title: 'New order', body: 'A buyer ordered Carrots.', type: 'order',
    referenceId: 'o1', orderId: 'o1', read: false, createdAt: serverTimestamp(), ...o,
  });

  it('an active user notifies another user with whitelisted fields', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'notifications', 'n1'), note('farmer1')));
    await assertSucceeds(setDoc(doc(db('trans1'), 'notifications', 'n2'), note('farmer1', { type: 'logistics', jobId: 'j1' })));
  });

  it('rejects self-notes, bad types, extra keys, oversize text and spoofed senders', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n3'), note('buyer1')));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n4'), note('farmer1', { type: 'admin_alert' })));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n5'), note('farmer1', { link: 'https://evil' })));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n6'), note('farmer1', { body: 'x'.repeat(501) })));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n7'), note('farmer1', { read: true })));
    await assertFails(setDoc(doc(db('buyer1'), 'notifications', 'n8'), note('farmer1', { type: 'message', senderId: 'farmer2' })));
    await assertFails(setDoc(doc(db('suspended1'), 'notifications', 'n9'), note('farmer1')));
  });

  it('farm-task reminders are the only self notifications; admins broadcast', async () => {
    const { orderId: _o, ...reminder } = note('farmer1', { type: 'farm_task', referenceId: 't1' });
    await assertSucceeds(setDoc(doc(db('farmer1'), 'notifications', 'n10'), reminder));
    await assertSucceeds(setDoc(doc(admin(), 'notifications', 'n11'), {
      userId: 'buyer1', title: 'Advisory', body: 'Heavy rain', type: 'general',
      referenceId: 'adv1', advisoryId: 'adv1', read: false, createdAt: serverTimestamp(),
    }));
  });

  it('recipients read / mark read only their own', async () => {
    await seedDocs((a) => setDoc(doc(a, 'notifications', 'n1'), { ...note('farmer1'), createdAt: new Date() }));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'notifications', 'n1'), { read: true }));
    await assertFails(updateDoc(doc(db('farmer1'), 'notifications', 'n1'), { title: 'x' }));
    await assertFails(getDoc(doc(db('buyer1'), 'notifications', 'n1')));
  });
});

describe('Spark: offers, produce requests, workspace, reviews, disputes', () => {
  beforeEach(() => seedBase(env));

  const offer = (o = {}) => ({
    productId: 'prod1', productName: 'Carrots', unit: 'kg', buyerId: 'buyer1', buyerName: 'b',
    farmerId: 'farmer1', farmerName: 'f', proposedQuantity: 3, proposedPrice: 300,
    proposedPriceMinor: 30000, status: 'pending', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  });

  it('offer negotiation: buyer offers, farmer counters, buyer accepts with an order', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'offers', 'of1'), offer()));
    await assertFails(setDoc(doc(db('buyer1'), 'offers', 'of2'), offer({ farmerId: 'farmer2' })));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'offers', 'of1'), {
      status: 'countered', originalPriceMinor: 30000, proposedPriceMinor: 32000,
      proposedPrice: 320, counteredAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    const d = db('buyer1');
    const batch = writeBatch(d);
    batch.set(doc(d, 'orders', 'oo1'), orderData('oo1', { requestedQuantity: 3, price: 32000, offerId: 'of1' }));
    batch.update(doc(d, 'products', 'prod1'), stock('oo1', 47));
    batch.update(doc(d, 'offers', 'of1'), { status: 'accepted', orderId: 'oo1', acceptedBy: 'buyer1', updatedAt: serverTimestamp() });
    await assertSucceeds(batch.commit());
  });

  it('farmer accepts a pending offer with an order at the offer price', async () => {
    await seedDocs((a) => setDoc(doc(a, 'offers', 'of1'), { ...offer(), createdAt: new Date(), updatedAt: new Date() }));
    const d = db('farmer1');
    const bad = writeBatch(d);
    bad.set(doc(d, 'orders', 'oo2'), orderData('oo2', { requestedQuantity: 3, price: 99999, offerId: 'of1' }));
    bad.update(doc(d, 'products', 'prod1'), stock('oo2', 47));
    bad.update(doc(d, 'offers', 'of1'), { status: 'accepted', orderId: 'oo2', acceptedBy: 'farmer1', updatedAt: serverTimestamp() });
    await assertFails(bad.commit());
    const ok = writeBatch(d);
    ok.set(doc(d, 'orders', 'oo3'), orderData('oo3', { requestedQuantity: 3, price: 30000, offerId: 'of1' }));
    ok.update(doc(d, 'products', 'prod1'), stock('oo3', 47));
    ok.update(doc(d, 'offers', 'of1'), { status: 'accepted', orderId: 'oo3', acceptedBy: 'farmer1', updatedAt: serverTimestamp() });
    await assertSucceeds(ok.commit());
  });

  it('produce request → farmer quote → buyer accepts with an order', async () => {
    await assertSucceeds(setDoc(doc(db('buyer1'), 'produce_requests', 'r1'), {
      buyerId: 'buyer1', buyerName: 'b', produceName: 'Carrots', category: 'Vegetables',
      quantity: 5, unit: 'kg', maxUnitPriceMinor: 0, district: 'Kandy',
      deliveryAddress: '12 Galle Road', deliveryDate: Timestamp.fromDate(new Date(Date.now() + 86400000)),
      notes: '', status: 'open', quoteCount: 0, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    const f = db('farmer1');
    const quote = writeBatch(f);
    quote.set(doc(f, 'produce_requests', 'r1', 'quotes', 'farmer1'), {
      farmerId: 'farmer1', farmerName: 'f', productId: 'prod1', productName: 'Carrots',
      unitPriceMinor: 30000, deliveryFeeMinor: 20000, message: '', status: 'pending',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    quote.update(doc(f, 'produce_requests', 'r1'), { quoteCount: increment(1), updatedAt: serverTimestamp() });
    await assertSucceeds(quote.commit());
    const d = db('buyer1');
    const accept = writeBatch(d);
    accept.set(doc(d, 'orders', 'rq1'), orderData('rq1', {
      requestedQuantity: 5, price: 30000, deliveryFeeMinor: 20000, sourceRequestId: 'r1',
    }));
    accept.update(doc(d, 'products', 'prod1'), stock('rq1', 45));
    accept.update(doc(d, 'produce_requests', 'r1', 'quotes', 'farmer1'), { status: 'accepted', orderId: 'rq1', updatedAt: serverTimestamp() });
    accept.update(doc(d, 'produce_requests', 'r1'), { status: 'matched', acceptedFarmerId: 'farmer1', orderId: 'rq1', updatedAt: serverTimestamp() });
    await assertSucceeds(accept.commit());
  });

  it('market price reports: reporters create pending, admins review', async () => {
    const report = { reporterId: 'buyer1', reporterRole: 'buyer', cropName: 'Carrot', category: 'Veg',
      district: 'Kandy', marketName: 'Kandy Market', unit: 'kg', priceMinor: 25000, status: 'pending',
      reportedAt: serverTimestamp(), createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('buyer1'), 'market_price_reports', 'm1'), report));
    await assertFails(setDoc(doc(db('buyer1'), 'market_price_reports', 'm2'), { ...report, status: 'approved' }));
    await assertFails(updateDoc(doc(db('buyer1'), 'market_price_reports', 'm1'), { status: 'approved' }));
    await assertSucceeds(updateDoc(doc(admin(), 'market_price_reports', 'm1'), { status: 'approved' }));
  });

  it('farm workspace: verified farmers own their crop plans and tasks', async () => {
    const plan = { farmerId: 'farmer1', cropName: 'Carrot', area: 2, areaUnit: 'acres',
      plantedAt: Timestamp.fromDate(new Date('2026-01-01')), expectedHarvestAt: Timestamp.fromDate(new Date('2026-04-01')),
      expectedYield: 0, yieldUnit: 'kg', status: 'planned', notes: '', createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('farmer1'), 'crop_plans', 'c1'), plan));
    await assertFails(setDoc(doc(db('farmerU'), 'crop_plans', 'c2'), { ...plan, farmerId: 'farmerU' }));
    await assertFails(setDoc(doc(db('buyer1'), 'crop_plans', 'c3'), { ...plan, farmerId: 'buyer1' }));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'crop_plans', 'c1'), { status: 'harvested', harvestedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db('farmer2'), 'crop_plans', 'c1'), { status: 'cancelled' }));
    const task = { farmerId: 'farmer1', title: 'Water', description: '', cropId: 'c1', cropName: 'Carrot',
      dueAt: Timestamp.fromDate(new Date()), priority: 'high', status: 'pending', createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('farmer1'), 'farm_tasks', 't1'), task));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'farm_tasks', 't1'), { reminderDate: '2026-09-26' }));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'farm_tasks'), where('farmerId', '==', 'farmer1'),
      where('status', 'in', ['pending', 'inProgress']))));
  });

  it('reviews only for delivered orders by their buyer', async () => {
    await seedOrder('o1', 'delivered', { transporterId: 'trans1' });
    await seedOrder('o2', 'pending');
    const review = (orderId) => ({ orderId, reviewerId: 'buyer1', subjectId: 'farmer1', rating: 5,
      comment: 'Great', moderationStatus: 'pending', createdAt: serverTimestamp() });
    await assertSucceeds(setDoc(doc(db('buyer1'), 'reviews', 'o1_buyer1'), review('o1')));
    await assertFails(setDoc(doc(db('buyer1'), 'reviews', 'o2_buyer1'), review('o2')));
    await assertFails(setDoc(doc(db('buyer1'), 'reviews', 'o1_x'), review('o1')));
  });

  it('an order party opens a dispute (dispute + order flag in one batch)', async () => {
    await seedOrder('o1', 'delivered', { transporterId: 'trans1' });
    await seedOrder('o2', 'delivered', { transporterId: 'trans1' });
    const open = (uid, id, orderId = 'o1') => {
      const d = db(uid);
      const batch = writeBatch(d);
      batch.set(doc(d, 'disputes', id), { orderId, openedBy: uid, reason: 'Damaged', status: 'open', evidenceImages: [], createdAt: serverTimestamp() });
      batch.update(doc(d, 'orders', orderId), { paymentStatus: 'disputed', disputeId: id, updatedAt: serverTimestamp() });
      return batch.commit();
    };
    await assertFails(open('stranger', 'd0'));
    await assertSucceeds(open('buyer1', 'd1'));
    await assertFails(open('farmer1', 'd2')); // already disputed
    await assertSucceeds(open('trans1', 'd3', 'o2'));
  });
});
