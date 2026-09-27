// Cold-chain range and temperature readings on delivery jobs.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDocs, collection, writeBatch, serverTimestamp, increment,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

async function seed() {
  await seedBase(env, async (a) => {
    await setDoc(doc(a, 'transport_jobs', 'j1'), {
      orderId: 'o1', farmerId: 'farmer1', buyerId: 'buyer1', status: 'inTransit',
      transporterId: 'trans1', accepted: true, createdAt: new Date(),
    });
  });
}

const reading = (uid, c, o = {}) => {
  const d = db(uid);
  const b = writeBatch(d);
  b.set(doc(d, 'transport_jobs', 'j1', 'temps', `r${Math.random().toString(36).slice(2, 8)}`), {
    celsius: c, source: 'manual', recordedBy: uid, recordedAt: serverTimestamp(), ...o,
  });
  b.update(doc(d, 'transport_jobs', 'j1'), {
    lastTempC: c, lastTempAt: serverTimestamp(), tempBreachCount: increment(c > 8 ? 1 : 0),
    updatedAt: serverTimestamp(),
  });
  return b.commit();
};

describe('cold chain', () => {
  beforeEach(seed);

  it('the farmer sets a sane range; others cannot', async () => {
    const set = (uid, o) => updateDoc(doc(db(uid), 'transport_jobs', 'j1'), { ...o, updatedAt: serverTimestamp() });
    await assertFails(set('buyer1', { coldChain: true, tempMinC: 2, tempMaxC: 8 }));
    await assertFails(set('farmer1', { coldChain: true, tempMinC: 9, tempMaxC: 8 }));
    await assertSucceeds(set('farmer1', { coldChain: true, tempMinC: 2, tempMaxC: 8 }));
    await assertSucceeds(set('farmer1', { coldChain: false }));
  });

  it('only the carrier logs readings; job parties read them', async () => {
    await assertFails(reading('buyer1', 5));
    await assertFails(reading('trans2', 5));
    await assertFails(reading('trans1', 99));
    await assertSucceeds(reading('trans1', 5));
    await assertSucceeds(reading('trans1', 12));
    await assertSucceeds(getDocs(collection(db('buyer1'), 'transport_jobs', 'j1', 'temps')));
    await assertSucceeds(getDocs(collection(db('farmer1'), 'transport_jobs', 'j1', 'temps')));
    await assertFails(getDocs(collection(db('buyer2'), 'transport_jobs', 'j1', 'temps')));
  });

  it('breach counter moves by at most one per reading', async () => {
    await assertFails(updateDoc(doc(db('trans1'), 'transport_jobs', 'j1'), {
      lastTempC: 5, lastTempAt: serverTimestamp(), tempBreachCount: 5, updatedAt: serverTimestamp(),
    }));
  });
});

describe('carbon', () => {
  beforeEach(seed);
  const audit = (uid) => ({ farmerId: uid, isDeleted: false, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), createdBy: uid, updatedBy: uid });
  const practice = (uid, o = {}) => setDoc(doc(db(uid), 'carbon_practices', 'p1'), {
    practice: 'agroforestry_trees', quantity: 100, unit: 'trees', tonnesPerYear: 2,
    startedAt: serverTimestamp(), notes: '', ...audit(uid), ...o,
  });

  it('farmers log their own carbon practices', async () => {
    await assertFails(practice('buyer1'));
    await assertFails(practice('farmer1', { practice: 'magic' }));
    await assertFails(practice('farmer1', { quantity: -1 }));
    await assertSucceeds(practice('farmer1'));
    await assertFails(getDocs(collection(db('farmer2'), 'carbon_practices')));
  });

  it('delivery carbon estimate is bounded', async () => {
    const deliver = (co2Kg) => {
      const d = db('trans1');
      const b = writeBatch(d);
      b.update(doc(d, 'transport_jobs', 'j1'), { status: 'delivered', deliveredAt: serverTimestamp(), updatedAt: serverTimestamp(), distanceKm: 150, co2Kg });
      return b.commit();
    };
    await assertFails(deliver(99999));
  });
});
