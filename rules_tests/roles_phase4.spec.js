// Finance, quality inspection and warehouse rules.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy,
  writeBatch, serverTimestamp, Timestamp,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

async function seed() {
  await seedBase(env, async (a) => {
    const u = (id, role, isVerified = true) => setDoc(doc(a, 'users', id),
      { id, role, isVerified, isSuspended: false, name: id });
    await u('fin1', 'finance');
    await u('finU', 'finance', false);
    await u('qc1', 'inspector');
    await u('qcU', 'inspector', false);
    await u('wh1', 'warehouse');
    await u('wh2', 'warehouse');
    await setDoc(doc(a, 'settlements', 's1'), {
      recipientId: 'farmer1', status: 'pending', netAmount: 1000, grossAmount: 1025, platformFee: 25,
    });
    await setDoc(doc(a, 'orders', 'o1'), { buyerId: 'buyer1', farmerId: 'farmer1', status: 'pending' });
  });
}

describe('finance', () => {
  beforeEach(seed);

  it('cannot self-register as finance', async () => {
    await assertFails(setDoc(doc(db('newFin'), 'users', 'newFin'), {
      id: 'newFin', role: 'finance', isVerified: false, isSuspended: false,
    }));
  });

  it('verified finance staff read and move settlements and read orders', async () => {
    await assertSucceeds(getDoc(doc(db('fin1'), 'settlements', 's1')));
    await assertFails(getDoc(doc(db('finU'), 'settlements', 's1')));
    await assertSucceeds(getDocs(collection(db('fin1'), 'orders')));
    await assertFails(getDocs(collection(db('buyer2'), 'orders')));
    await assertSucceeds(updateDoc(doc(db('fin1'), 'settlements', 's1'), {
      status: 'processing', reviewedBy: 'fin1', updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db('fin1'), 'settlements', 's1'), {
      status: 'settled', reviewedBy: 'fin1', settledAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(setDoc(doc(db('fin1'), 'audit_logs', 'a1'), { actorId: 'fin1', actionType: 'X' }));
  });
});

describe('quality inspection', () => {
  beforeEach(seed);
  const request = (uid, o = {}) => setDoc(doc(db(uid), 'quality_requests', 'prod1'), {
    productId: 'prod1', productName: 'Carrots', farmerId: uid, farmerName: uid, district: 'NE',
    status: 'open', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  });
  const grade = (uid, g = 'A', productGrade = g) => {
    const d = db(uid);
    const b = writeBatch(d);
    b.set(doc(d, 'quality_inspections', 'i1'), {
      productId: 'prod1', productName: 'Carrots', farmerId: 'farmer1', inspectorId: uid,
      inspectorName: uid, grade: g, moisturePct: 12, notes: 'Uniform size', createdAt: serverTimestamp(),
    });
    b.update(doc(d, 'products', 'prod1'), {
      qualityGrade: productGrade, qualityInspectedAt: serverTimestamp(), qualityInspectionId: 'i1',
      qualityInspectorName: uid,
    });
    b.update(doc(d, 'quality_requests', 'prod1'), {
      status: 'done', inspectorId: uid, doneAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    return b.commit();
  };

  it('only the product owner requests an inspection', async () => {
    await assertSucceeds(getDoc(doc(db('farmer1'), 'quality_requests', 'prod1')));
    await assertFails(request('farmer2'));
    await assertSucceeds(request('farmer1'));
  });

  it('farmers cannot grade their own products', async () => {
    await assertFails(updateDoc(doc(db('farmer1'), 'products', 'prod1'), { qualityGrade: 'A' }));
  });

  it('verified inspectors grade with a matching inspection record', async () => {
    await request('farmer1');
    await assertSucceeds(getDocs(query(collection(db('qc1'), 'quality_requests'),
      where('status', '==', 'open'), orderBy('createdAt'))));
    await assertFails(grade('qcU'));
    await assertFails(grade('qc1', 'A', 'B'));
    await assertSucceeds(grade('qc1', 'B'));
    await assertSucceeds(getDoc(doc(db('buyer1'), 'quality_inspections', 'i1')));
  });
});

describe('warehouse lots', () => {
  beforeEach(seed);
  const lot = (uid, o = {}) => ({
    warehouseId: uid, warehouseName: uid, lotCode: 'LOT-1', productName: 'Big onion', ownerName: 'Farmer A',
    quantity: 500, quantityRemaining: 500, unit: 'kg', grade: 'A', storageType: 'cold', district: 'Dambulla',
    notes: '', status: 'in_stock', receivedAt: serverTimestamp(),
    expiresAt: Timestamp.fromDate(new Date(Date.now() + 5 * 86400000)), isDeleted: false,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), createdBy: uid, updatedBy: uid, ...o,
  });
  const receive = (uid, o = {}) => {
    const d = db(uid);
    const b = writeBatch(d);
    b.set(doc(d, 'warehouse_lots', 'L1'), lot(uid, o));
    b.set(doc(d, 'warehouse_lots', 'L1', 'moves', 'm1'), {
      type: 'inward', quantity: 500, note: '', createdAt: serverTimestamp(), createdBy: uid,
    });
    return b.commit();
  };

  it('verified warehouses receive lots with a movement', async () => {
    await assertFails(receive('farmer1'));
    await assertFails(receive('wh1', { quantityRemaining: 400 }));
    await assertFails(receive('wh1', { grade: 'Z' }));
    await assertSucceeds(receive('wh1'));
  });

  it('dispatch reduces remaining within bounds; others cannot touch', async () => {
    await receive('wh1');
    const take = (uid, remaining, o = {}) => updateDoc(doc(db(uid), 'warehouse_lots', 'L1'), {
      quantityRemaining: remaining, updatedAt: serverTimestamp(), updatedBy: uid, ...o,
    });
    await assertFails(take('wh2', 100));
    await assertFails(take('wh1', 600));
    await assertFails(take('wh1', 100, { quantity: 100 }));
    await assertSucceeds(take('wh1', 0, { status: 'dispatched' }));
  });

  it('buyers browse in-stock lots only; moves stay private', async () => {
    await receive('wh1');
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'warehouse_lots'),
      where('status', '==', 'in_stock'), where('isDeleted', '==', false), orderBy('receivedAt', 'desc'))));
    await assertFails(getDocs(collection(db('buyer1'), 'warehouse_lots', 'L1', 'moves')));
    await assertSucceeds(getDocs(collection(db('wh1'), 'warehouse_lots', 'L1', 'moves')));
  });
});
