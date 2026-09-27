// Fleet drivers: joining a transporter, job assignment and running a job.
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where,
  writeBatch, serverTimestamp, deleteField,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

async function seed() {
  await seedBase(env, async (a) => {
    await setDoc(doc(a, 'users', 'drv1'), { id: 'drv1', role: 'driver', isVerified: true, isSuspended: false, name: 'drv1' });
    await setDoc(doc(a, 'users', 'drv2'), { id: 'drv2', role: 'driver', isVerified: true, isSuspended: false, name: 'drv2' });
    await setDoc(doc(a, 'orders', 'o1'), {
      buyerId: 'buyer1', farmerId: 'farmer1', status: 'assigned', transporterId: 'trans1',
      transportJobId: 'j1', paymentMethod: 'cod', totalMinor: 100,
    });
    await setDoc(doc(a, 'transport_jobs', 'j1'), {
      orderId: 'o1', farmerId: 'farmer1', buyerId: 'buyer1', status: 'accepted',
      transporterId: 'trans1', accepted: true, createdAt: new Date(),
    });
    await setDoc(doc(a, 'delivery_codes', 'o1'), { orderId: 'o1', buyerId: 'buyer1', code: '482913' });
  });
}

const invite = (t, d) => setDoc(doc(db(t), 'fleet_links', `${t}_${d}`), {
  transporterId: t, transporterName: t, driverId: d, driverName: d, status: 'invited',
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
});
const setLink = (uid, id, status) => updateDoc(doc(db(uid), 'fleet_links', id), { status, updatedAt: serverTimestamp() });
const assign = (uid, driverId) => updateDoc(doc(db(uid), 'transport_jobs', 'j1'), driverId
  ? { driverId, driverName: driverId, updatedAt: serverTimestamp() }
  : { driverId: deleteField(), driverName: deleteField(), updatedAt: serverTimestamp() });
function step(uid, from, to, extra = {}) {
  const d = db(uid);
  const b = writeBatch(d);
  b.update(doc(d, 'transport_jobs', 'j1'), { status: to, [`${to}At`]: serverTimestamp(), updatedAt: serverTimestamp(), ...extra });
  b.update(doc(d, 'orders', 'o1'), { status: to, [`${to}At`]: serverTimestamp(), updatedAt: serverTimestamp() });
  return b.commit();
}

describe('fleet drivers', () => {
  beforeEach(seed);

  it('drivers publish a card; transporters find them by phone', async () => {
    await assertSucceeds(setDoc(doc(db('drv1'), 'driver_profiles', 'drv1'), {
      driverId: 'drv1', name: 'drv1', phoneKey: '771000006', district: 'Kandy', isVerified: true, updatedAt: serverTimestamp(),
    }));
    await assertFails(setDoc(doc(db('drv2'), 'driver_profiles', 'drv2'), {
      driverId: 'drv2', name: 'drv2', phoneKey: '1', district: '', isVerified: false, updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(getDocs(query(collection(db('trans1'), 'driver_profiles'), where('phoneKey', '==', '771000006'))));
    await assertFails(getDocs(query(collection(db('buyer1'), 'driver_profiles'), where('phoneKey', '==', '771000006'))));
  });

  it('transporters invite drivers; drivers accept or leave', async () => {
    await assertFails(invite('trans1', 'buyer1'));
    await assertFails(invite('farmer1', 'drv1'));
    await assertSucceeds(invite('trans1', 'drv1'));
    await assertFails(setLink('trans2', 'trans1_drv1', 'active'));
    await assertFails(setLink('trans1', 'trans1_drv1', 'active'));
    await assertSucceeds(setLink('drv1', 'trans1_drv1', 'active'));
    await assertSucceeds(setLink('drv1', 'trans1_drv1', 'removed'));
    await assertSucceeds(setLink('trans1', 'trans1_drv1', 'invited'));
  });

  it('only active fleet drivers can be assigned, by the job owner', async () => {
    await invite('trans1', 'drv1');
    await assertFails(assign('trans1', 'drv1'));
    await setLink('drv1', 'trans1_drv1', 'active');
    await assertFails(assign('trans2', 'drv1'));
    await assertFails(assign('trans1', 'drv2'));
    await assertSucceeds(assign('trans1', 'drv1'));
    await assertSucceeds(getDoc(doc(db('drv1'), 'transport_jobs', 'j1')));
    await assertFails(getDoc(doc(db('drv2'), 'transport_jobs', 'j1')));
    await assertSucceeds(assign('trans1', null));
  });

  it('the assigned driver runs the job to delivery with the buyer code', async () => {
    await invite('trans1', 'drv1');
    await setLink('drv1', 'trans1_drv1', 'active');
    await assign('trans1', 'drv1');
    await assertFails(step('drv2', 'accepted', 'pickedUp'));
    await assertSucceeds(step('drv1', 'accepted', 'pickedUp'));
    await assertSucceeds(updateDoc(doc(db('drv1'), 'transport_jobs', 'j1'), {
      courierLat: 7.2, courierLng: 80.6, locationUpdatedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(step('drv1', 'pickedUp', 'inTransit'));
    await assertFails(step('drv1', 'inTransit', 'delivered', { deliveryCode: '000000' }));
    await assertSucceeds(step('drv1', 'inTransit', 'delivered', { deliveryCode: '482913' }));
  });

  it('the assigned driver can attach a delivery photo', async () => {
    const { ref, uploadBytes } = require('firebase/storage');
    const jpg = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 0]);
    await env.withSecurityRulesDisabled((c) => updateDoc(doc(c.firestore(), 'orders', 'o1'), { status: 'inTransit' }));
    await invite('trans1', 'drv1');
    await setLink('drv1', 'trans1_drv1', 'active');
    await assign('trans1', 'drv1');
    const st = (uid) => env.authenticatedContext(uid).storage();
    await assertFails(uploadBytes(ref(st('drv2'), 'pod_photos/o1/drv2_a.jpg'), jpg, { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(st('drv1'), 'pod_photos/o1/drv1_a.jpg'), jpg, { contentType: 'image/jpeg' }));
  });

  it('a driver who left the fleet can no longer run the job', async () => {
    await invite('trans1', 'drv1');
    await setLink('drv1', 'trans1_drv1', 'active');
    await assign('trans1', 'drv1');
    await setLink('drv1', 'trans1_drv1', 'removed');
    await assertFails(step('drv1', 'accepted', 'pickedUp'));
  });
});
