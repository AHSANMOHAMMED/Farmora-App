// Farm plots, the income / expense ledger and crop harvest records,
// written by lib/services/farm_records_service.dart and SparkBackend.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy,
  serverTimestamp, Timestamp,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();
const audit = (uid) => ({
  farmerId: uid, isDeleted: false, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
  createdBy: uid, updatedBy: uid,
});
const plot = (uid, o = {}) => ({
  name: 'North field', area: 2.5, areaUnit: 'acres', soilType: 'Loam', irrigation: 'Well',
  notes: '', ...audit(uid), ...o,
});
const entry = (uid, o = {}) => ({
  type: 'expense', category: 'fertilizer', amountMinor: 450000,
  date: Timestamp.fromDate(new Date()), cropId: '', cropName: '', note: 'Urea', sourceId: '',
  ...audit(uid), ...o,
});

describe('farm plots and ledger', () => {
  beforeEach(() => seedBase(env, async (a) => {
    await setDoc(doc(a, 'input_orders', 'io1'), { farmerId: 'farmer1', supplierId: 'sup1', status: 'delivered' });
    await setDoc(doc(a, 'crop_plans', 'c1'), {
      farmerId: 'farmer1', cropName: 'Carrot', area: 1, areaUnit: 'acres', status: 'growing',
      notes: '', createdAt: new Date(), updatedAt: new Date(),
    });
  }));

  it('farmers keep their own plots with audit fields and soft delete', async () => {
    await assertFails(setDoc(doc(db('buyer1'), 'farm_plots', 'p'), plot('buyer1')));
    await assertFails(setDoc(doc(db('farmer1'), 'farm_plots', 'p'), plot('farmer2')));
    await assertFails(setDoc(doc(db('farmer1'), 'farm_plots', 'p'), plot('farmer1', { area: 0 })));
    await assertFails(setDoc(doc(db('farmer1'), 'farm_plots', 'p'), plot('farmer1', { createdBy: 'x' })));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'farm_plots', 'p'), plot('farmer1')));
    await assertFails(getDoc(doc(db('farmer2'), 'farm_plots', 'p')));
    await assertFails(updateDoc(doc(db('farmer2'), 'farm_plots', 'p'), { name: 'x', updatedBy: 'farmer2' }));
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'farm_plots', 'p'), {
      isDeleted: true, updatedAt: serverTimestamp(), updatedBy: 'farmer1',
    }));
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'farm_plots'),
      where('farmerId', '==', 'farmer1'), where('isDeleted', '==', false), orderBy('createdAt'))));
  });

  it('ledger entries are validated by type and category', async () => {
    const put = (id, o) => setDoc(doc(db('farmer1'), 'farm_ledger', id), entry('farmer1', o));
    await assertFails(put('e1', { category: 'produce_sale' }));
    await assertFails(put('e1', { type: 'income', category: 'labour' }));
    await assertFails(put('e1', { amountMinor: 0 }));
    await assertSucceeds(put('e1', {}));
    await assertSucceeds(put('e2', { type: 'income', category: 'subsidy' }));
    await assertFails(getDoc(doc(db('farmer2'), 'farm_ledger', 'e1')));
    await assertSucceeds(getDoc(doc(db('farmer1'), 'farm_ledger', 'missing')));
  });

  it('input-order expenses use a fixed id and the farmer\'s own order', async () => {
    await assertFails(setDoc(doc(db('farmer1'), 'farm_ledger', 'random'), entry('farmer1', { sourceId: 'io1' })));
    await assertFails(setDoc(doc(db('farmer2'), 'farm_ledger', 'io_io1'), entry('farmer2', { sourceId: 'io1' })));
    await assertSucceeds(setDoc(doc(db('farmer1'), 'farm_ledger', 'io_io1'), entry('farmer1', { sourceId: 'io1' })));
    await assertFails(updateDoc(doc(db('farmer1'), 'farm_ledger', 'io_io1'), {
      sourceId: 'other', updatedAt: serverTimestamp(), updatedBy: 'farmer1',
    }));
  });

  it('crop plans record the actual harvest', async () => {
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'crop_plans', 'c1'), {
      status: 'harvested', actualYield: 850, yieldUnit: 'kg', harvestedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('farmer1'), 'crop_plans', 'c1'), { actualYield: -1, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db('farmer2'), 'crop_plans', 'c1'), { actualYield: 5, updatedAt: serverTimestamp() }));
  });
});
