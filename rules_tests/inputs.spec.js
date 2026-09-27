// Input marketplace (inputs / input_orders), written by
// lib/services/input_market_service.dart.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy,
  writeBatch, serverTimestamp, Timestamp,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

function listing(uid, o = {}) {
  return {
    supplierId: uid, supplierName: uid, name: 'Hybrid maize seed',
    category: 'seeds', listingType: 'sale', priceMinor: 120000, unit: 'kg',
    stock: 10, description: '', district: 'Kandy', imageUrl: null,
    status: 'Active', isDeleted: false,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    createdBy: uid, updatedBy: uid, ...o,
  };
}

function orderData(o = {}) {
  return {
    farmerId: 'farmer1', farmerName: 'farmer1', supplierId: 'sup1', supplierName: 'sup1',
    inputId: 'in1', inputName: 'Hybrid maize seed', listingType: 'sale', unit: 'kg',
    quantity: 2, unitPriceMinor: 120000, totalMinor: 240000,
    deliveryAddress: '12 Main Street, Kandy', paymentMethod: 'cod', status: 'pending',
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  };
}

async function seed() {
  await seedBase(env, async (a) => {
    await setDoc(doc(a, 'users', 'sup1'), { id: 'sup1', role: 'supplier', isVerified: true, isSuspended: false, name: 'sup1' });
    await setDoc(doc(a, 'users', 'supU'), { id: 'supU', role: 'supplier', isVerified: false, isSuspended: false, name: 'supU' });
    await setDoc(doc(a, 'inputs', 'in1'), { ...listing('sup1'), createdAt: new Date(), updatedAt: new Date() });
    await setDoc(doc(a, 'inputs', 'rent1'), {
      ...listing('sup1', { name: 'Tractor', category: 'machinery', listingType: 'rental', unit: 'day', priceMinor: 800000, stock: 1 }),
      createdAt: new Date(), updatedAt: new Date(),
    });
  });
}

describe('input listings', () => {
  beforeEach(seed);

  it('a supplier can sign up; only verified suppliers list, as themselves', async () => {
    await assertSucceeds(setDoc(doc(db('newSup'), 'users', 'newSup'), {
      id: 'newSup', role: 'supplier', isVerified: false, isSuspended: false, name: 'N',
    }));
    await assertFails(setDoc(doc(db('supU'), 'inputs', 'x'), listing('supU')));
    await assertFails(setDoc(doc(db('farmer1'), 'inputs', 'x'), listing('farmer1')));
    await assertFails(setDoc(doc(db('sup1'), 'inputs', 'x'), listing('sup2')));
    await assertFails(setDoc(doc(db('sup1'), 'inputs', 'x'), listing('sup1', { priceMinor: 0 })));
    await assertFails(setDoc(doc(db('sup1'), 'inputs', 'x'), listing('sup1', { category: 'drugs' })));
    await assertSucceeds(setDoc(doc(db('sup1'), 'inputs', 'x'), listing('sup1')));
  });

  it('owners edit and soft-delete; nobody else can', async () => {
    const upd = { priceMinor: 110000, updatedAt: serverTimestamp(), updatedBy: 'sup1' };
    await assertSucceeds(updateDoc(doc(db('sup1'), 'inputs', 'in1'), upd));
    await assertFails(updateDoc(doc(db('farmer1'), 'inputs', 'in1'), { ...upd, updatedBy: 'farmer1' }));
    await assertFails(updateDoc(doc(db('sup1'), 'inputs', 'in1'), { supplierId: 'x', updatedBy: 'sup1' }));
    await assertSucceeds(updateDoc(doc(db('sup1'), 'inputs', 'in1'), {
      isDeleted: true, status: 'Inactive', deletedAt: serverTimestamp(), updatedAt: serverTimestamp(), updatedBy: 'sup1',
    }));
    await assertFails(getDoc(doc(db('farmer1'), 'inputs', 'in1')));
    await assertSucceeds(getDoc(doc(db('sup1'), 'inputs', 'in1')));
  });

  it('catalogue and own-listing queries are allowed', async () => {
    const c = collection(db('farmer1'), 'inputs');
    await assertSucceeds(getDocs(query(c, where('status', '==', 'Active'), where('isDeleted', '==', false), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(query(collection(db('sup1'), 'inputs'), where('supplierId', '==', 'sup1'), where('isDeleted', '==', false))));
    await assertFails(getDocs(query(c, where('isDeleted', '==', false))));
  });
});

describe('input orders', () => {
  beforeEach(seed);

  it('farmers order at the listed price, within stock, with an exact total', async () => {
    const put = (uid, o) => setDoc(doc(db(uid), 'input_orders', 'o1'), orderData(o));
    await assertFails(put('buyer1', { farmerId: 'buyer1' }));
    await assertFails(put('farmer1', { unitPriceMinor: 100000, totalMinor: 200000 }));
    await assertFails(put('farmer1', { totalMinor: 1 }));
    await assertFails(put('farmer1', { quantity: 11, totalMinor: 1320000 }));
    await assertFails(put('farmer1', { status: 'confirmed' }));
    await assertSucceeds(put('farmer1', {}));
  });

  it('rental bookings charge per day', async () => {
    const rental = {
      inputId: 'rent1', inputName: 'Tractor', listingType: 'rental', unit: 'day', quantity: 1,
      unitPriceMinor: 800000, days: 3, startDate: Timestamp.fromDate(new Date(Date.now() + 86400000)),
    };
    await assertFails(setDoc(doc(db('farmer1'), 'input_orders', 'r1'), orderData({ ...rental, totalMinor: 800000 })));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'input_orders', 'r1'), orderData({ ...rental, totalMinor: 2400000 })));
  });

  it('a sale is confirmed only together with its stock; then advances in order', async () => {
    await setDoc(doc(db('farmer1'), 'input_orders', 'o1'), orderData());
    const step = (uid, status) => updateDoc(doc(db(uid), 'input_orders', 'o1'), {
      status, [`${status}At`]: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertFails(step('sup1', 'confirmed'));
    await assertFails(step('farmer1', 'confirmed'));
    const d = db('sup1');
    const b = writeBatch(d);
    b.update(doc(d, 'inputs', 'in1'), { stock: 8, updatedAt: serverTimestamp(), updatedBy: 'sup1' });
    b.update(doc(d, 'input_orders', 'o1'), { status: 'confirmed', confirmedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    await assertSucceeds(b.commit());
    await assertFails(step('farmer1', 'cancelled'));
    await assertFails(step('sup1', 'delivered'));
    await assertSucceeds(step('sup1', 'dispatched'));
    await assertSucceeds(step('sup1', 'delivered'));
  });

  it('farmers cancel only while pending; suppliers reject pending', async () => {
    await setDoc(doc(db('farmer1'), 'input_orders', 'o1'), orderData());
    await setDoc(doc(db('farmer1'), 'input_orders', 'o2'), orderData());
    const set = (uid, id, status) => updateDoc(doc(db(uid), 'input_orders', id), {
      status, [`${status}At`]: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertFails(set('sup1', 'o1', 'cancelled'));
    await assertSucceeds(set('farmer1', 'o1', 'cancelled'));
    await assertFails(set('farmer1', 'o2', 'rejected'));
    await assertSucceeds(set('sup1', 'o2', 'rejected'));
  });

  it('only the two parties read an order', async () => {
    await setDoc(doc(db('farmer1'), 'input_orders', 'o1'), orderData());
    await assertSucceeds(getDoc(doc(db('farmer1'), 'input_orders', 'o1')));
    await assertSucceeds(getDoc(doc(db('sup1'), 'input_orders', 'o1')));
    await assertFails(getDoc(doc(db('farmer2'), 'input_orders', 'o1')));
    await assertSucceeds(getDocs(query(collection(db('sup1'), 'input_orders'), where('supplierId', '==', 'sup1'), orderBy('createdAt', 'desc'))));
  });
});
