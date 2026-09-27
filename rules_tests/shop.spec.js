// Direct-to-consumer: wishlist, farm stores and subscription boxes
// (lib/services/shop_service.dart).
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, deleteDoc, collection, query, where,
  serverTimestamp, Timestamp, increment,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const inDays = (d) => Timestamp.fromDate(new Date(Date.now() + d * 86400000));

function box(uid, o = {}) {
  return {
    farmerId: uid, farmerName: uid, title: 'Weekly veg box', contents: 'Carrot, leeks, beans',
    priceMinor: 250000, frequency: 'weekly', status: 'Active', isDeleted: false,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), createdBy: uid, updatedBy: uid, ...o,
  };
}
function sub(o = {}) {
  return {
    boxId: 'b1', boxTitle: 'Weekly veg box', farmerId: 'farmer1', farmerName: 'farmer1',
    buyerId: 'buyer1', buyerName: 'buyer1', priceMinor: 250000, frequency: 'weekly',
    deliveryAddress: '12 Galle Road, Colombo', paymentMethod: 'cod', status: 'active',
    nextDeliveryAt: inDays(2), deliveriesCount: 0,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  };
}

describe('wishlist and farm stores', () => {
  beforeEach(() => seedBase(env));

  it('each user keeps their own wishlist', async () => {
    const w = (uid, owner, pid, o = {}) => setDoc(doc(db(uid), 'users', owner, 'wishlist', pid),
      { productId: pid, addedAt: serverTimestamp(), ...o });
    await assertSucceeds(w('buyer1', 'buyer1', 'prod1'));
    await assertFails(w('buyer2', 'buyer1', 'prod1'));
    await assertFails(w('buyer1', 'buyer1', 'prod1', { productId: 'other' }));
    await assertFails(getDocs(collection(db('buyer2'), 'users', 'buyer1', 'wishlist')));
    await assertSucceeds(deleteDoc(doc(db('buyer1'), 'users', 'buyer1', 'wishlist', 'prod1')));
  });

  it('stores are public; only the farmer writes their own', async () => {
    const store = (o = {}) => ({
      farmerId: 'farmer1', farmName: 'Green Hills', story: 'Since 1990', district: 'Kandy',
      certifications: ['Organic'], coverImageUrl: null, updatedAt: serverTimestamp(), ...o,
    });
    await assertFails(setDoc(doc(db('farmer2'), 'farm_stores', 'farmer1'), store()));
    await assertFails(setDoc(doc(db('buyer1'), 'farm_stores', 'buyer1'), store({ farmerId: 'buyer1' })));
    await assertFails(setDoc(doc(db('farmer1'), 'farm_stores', 'farmer1'), store({ farmName: '' })));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'farm_stores', 'farmer1'), store()));
    await assertSucceeds(getDoc(doc(anon(), 'farm_stores', 'farmer1')));
  });
});

describe('subscription boxes', () => {
  beforeEach(() => seedBase(env, async (a) => {
    await setDoc(doc(a, 'subscription_boxes', 'b1'), { ...box('farmer1'), createdAt: new Date(), updatedAt: new Date() });
  }));

  it('verified farmers publish boxes; others cannot', async () => {
    await assertFails(setDoc(doc(db('farmerU'), 'subscription_boxes', 'x'), box('farmerU')));
    await assertFails(setDoc(doc(db('buyer1'), 'subscription_boxes', 'x'), box('buyer1')));
    await assertFails(setDoc(doc(db('farmer1'), 'subscription_boxes', 'x'), box('farmer1', { frequency: 'daily' })));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'subscription_boxes', 'x'), box('farmer1')));
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'subscription_boxes'),
      where('farmerId', '==', 'farmer1'), where('isDeleted', '==', false), where('status', '==', 'Active'))));
  });

  it('buyers subscribe at the box price and frequency', async () => {
    const put = (o) => setDoc(doc(db('buyer1'), 'box_subscriptions', 's1'), sub(o));
    await assertFails(put({ priceMinor: 100 }));
    await assertFails(put({ frequency: 'monthly' }));
    await assertFails(put({ deliveriesCount: 3 }));
    await assertFails(put({ nextDeliveryAt: inDays(90) }));
    await assertFails(setDoc(doc(db('farmer1'), 'box_subscriptions', 's1'), sub({ buyerId: 'farmer1' })));
    await assertSucceeds(put({}));
  });

  it('buyers pause and cancel; farmers record one delivery at a time', async () => {
    await setDoc(doc(db('buyer1'), 'box_subscriptions', 's1'), sub());
    const deliver = (uid, n, next) => updateDoc(doc(db(uid), 'box_subscriptions', 's1'), {
      deliveriesCount: n, lastDeliveredAt: serverTimestamp(), nextDeliveryAt: next, updatedAt: serverTimestamp(),
    });
    await assertFails(deliver('buyer1', 1, inDays(9)));
    await assertFails(deliver('farmer1', 2, inDays(9)));
    await assertFails(deliver('farmer1', 1, inDays(1)));
    await assertSucceeds(deliver('farmer1', 1, inDays(9)));
    const status = (uid, s) => updateDoc(doc(db(uid), 'box_subscriptions', 's1'), { status: s, updatedAt: serverTimestamp() });
    await assertFails(status('farmer1', 'paused'));
    await assertSucceeds(status('buyer1', 'paused'));
    await assertFails(deliver('farmer1', 2, inDays(16)));
    await assertSucceeds(status('buyer1', 'cancelled'));
    await assertFails(status('buyer1', 'active'));
    await assertFails(getDoc(doc(db('buyer2'), 'box_subscriptions', 's1')));
  });
});
