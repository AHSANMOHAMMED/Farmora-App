// Reverse-auction transport bids (lib/services/bidding_service.dart).
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDocs, deleteDoc, collection, query, orderBy,
  serverTimestamp, writeBatch,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

async function seed() {
  await seedBase(env, async (a) => {
    await setDoc(doc(a, 'orders', 'o1'), {
      buyerId: 'buyer1', farmerId: 'farmer1', status: 'confirmed', paymentMethod: 'cod', totalMinor: 100,
    });
    await setDoc(doc(a, 'transport_jobs', 'j1'), {
      orderId: 'o1', farmerId: 'farmer1', buyerId: 'buyer1', status: 'requested',
      transporterId: null, accepted: false, offeredFeeMinor: 50000, deliveryFeeMinor: 50000,
      fee: 'LKR 500.00', createdAt: new Date(),
    });
  });
}

const bid = (uid, amount, o = {}) => setDoc(doc(db(uid), 'transport_jobs', 'j1', 'bids', uid), {
  transporterId: uid, transporterName: uid, vehicleType: 'Lorry', amountMinor: amount, etaHours: 12,
  note: '', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
});
const award = (uid, bidder, amount) => updateDoc(doc(db(uid), 'transport_jobs', 'j1'), {
  transporterId: bidder, requestedTransporterId: bidder, offeredFeeMinor: amount, deliveryFeeMinor: amount,
  fee: 'LKR x', awardedBidAt: serverTimestamp(), updatedAt: serverTimestamp(),
});

describe('transport bids', () => {
  beforeEach(seed);

  it('verified transporters bid up to the offered fee', async () => {
    await assertFails(bid('transU', 40000));
    await assertFails(bid('buyer1', 40000));
    await assertFails(bid('trans1', 60000));
    await assertFails(bid('trans2', 40000, { transporterId: 'trans1' }));
    await assertSucceeds(bid('trans1', 45000));
    await assertSucceeds(bid('trans2', 42000));
    await assertSucceeds(bid('trans1', 41000));
  });

  it('only the farmer and each bidder see bids', async () => {
    await bid('trans1', 45000);
    await assertSucceeds(getDocs(query(collection(db('farmer1'), 'transport_jobs', 'j1', 'bids'), orderBy('amountMinor'))));
    await assertFails(getDocs(collection(db('trans2'), 'transport_jobs', 'j1', 'bids')));
    await assertFails(getDocs(collection(db('farmer2'), 'transport_jobs', 'j1', 'bids')));
  });

  it('the farmer awards an existing bid at its exact amount; then the winner accepts', async () => {
    await bid('trans1', 45000);
    await assertFails(award('farmer1', 'trans2', 45000));
    await assertFails(award('farmer1', 'trans1', 30000));
    await assertFails(award('farmer2', 'trans1', 45000));
    await assertSucceeds(award('farmer1', 'trans1', 45000));
    // Closed for new bids once awarded.
    await assertFails(bid('trans2', 40000));
    const d = db('trans1');
    const b = writeBatch(d);
    b.update(doc(d, 'transport_jobs', 'j1'), { status: 'accepted', transporterId: 'trans1', accepted: true, acceptedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    b.update(doc(d, 'orders', 'o1'), { status: 'assigned', transporterId: 'trans1', transportJobId: 'j1', assignedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    await assertSucceeds(b.commit());
  });

  it('bidders withdraw while the job is open', async () => {
    await bid('trans1', 45000);
    await assertFails(deleteDoc(doc(db('trans2'), 'transport_jobs', 'j1', 'bids', 'trans1')));
    await assertSucceeds(deleteDoc(doc(db('trans1'), 'transport_jobs', 'j1', 'bids', 'trans1')));
  });
});
