// Community feed and expert consultations (lib/services/community_service.dart).
const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, setDoc, updateDoc, getDoc, getDocs, collection, query, where, orderBy,
  writeBatch, serverTimestamp, increment,
} = require('firebase/firestore');
const { getEnv, seedBase } = require('./helpers');

let env;
before(async () => { env = await getEnv(); });

const db = (uid) => env.authenticatedContext(uid).firestore();
const post = (uid, role, o = {}) => ({
  authorId: uid, authorName: uid, authorRole: role, text: 'Neem spray worked on aphids',
  imageUrl: null, likeCount: 0, commentCount: 0, isDeleted: false,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
});

async function seed() {
  await seedBase(env, async (a) => {
    await setDoc(doc(a, 'users', 'exp1'), { id: 'exp1', role: 'expert', isVerified: true, isSuspended: false, name: 'exp1' });
    await setDoc(doc(a, 'users', 'expU'), { id: 'expU', role: 'expert', isVerified: false, isSuspended: false, name: 'expU' });
    await setDoc(doc(a, 'community_posts', 'p1'), { ...post('farmer1', 'farmer'), createdAt: new Date(), updatedAt: new Date() });
  });
}

describe('community feed', () => {
  beforeEach(seed);

  it('farmers and experts post as themselves; buyers cannot post', async () => {
    await assertSucceeds(setDoc(doc(db('farmer1'), 'community_posts', 'a'), post('farmer1', 'farmer')));
    await assertSucceeds(setDoc(doc(db('exp1'), 'community_posts', 'b'), post('exp1', 'expert')));
    await assertFails(setDoc(doc(db('buyer1'), 'community_posts', 'c'), post('buyer1', 'buyer')));
    await assertFails(setDoc(doc(db('farmer1'), 'community_posts', 'd'), post('farmer1', 'expert')));
    await assertFails(setDoc(doc(db('farmer1'), 'community_posts', 'e'), post('farmer1', 'farmer', { likeCount: 50 })));
    await assertSucceeds(getDocs(query(collection(db('buyer1'), 'community_posts'),
      where('isDeleted', '==', false), orderBy('createdAt', 'desc'))));
  });

  it('likes move the counter by exactly one with the like doc', async () => {
    const like = (uid, delta, withDoc = true) => {
      const d = db(uid);
      const b = writeBatch(d);
      if (withDoc) {
        const ref = doc(d, 'community_posts', 'p1', 'likes', uid);
        if (delta > 0) b.set(ref, { createdAt: serverTimestamp() }); else b.delete(ref);
      }
      b.update(doc(d, 'community_posts', 'p1'), { likeCount: increment(delta) });
      return b.commit();
    };
    await assertFails(like('buyer1', 1, false));
    await assertFails(like('buyer1', 2));
    await assertSucceeds(like('buyer1', 1));
    await assertFails(like('buyer1', 1));
    await assertSucceeds(like('buyer1', -1));
  });

  it('comments bump the count once; authors or admins delete posts', async () => {
    const d = db('buyer1');
    const b = writeBatch(d);
    b.set(doc(d, 'community_posts', 'p1', 'comments', 'c1'), {
      authorId: 'buyer1', authorName: 'buyer1', text: 'Thanks!', createdAt: serverTimestamp(),
    });
    b.update(doc(d, 'community_posts', 'p1'), { commentCount: increment(1) });
    await assertSucceeds(b.commit());
    await assertFails(setDoc(doc(db('buyer2'), 'community_posts', 'p1', 'comments', 'c2'), {
      authorId: 'buyer2', authorName: 'b', text: 'no counter', createdAt: serverTimestamp(),
    }));
    const hide = (uid) => updateDoc(doc(db(uid), 'community_posts', 'p1'), {
      isDeleted: true, deletedBy: uid, updatedAt: serverTimestamp(),
    });
    await assertFails(hide('farmer2'));
    await assertSucceeds(hide('admin1'));
  });
});

describe('consultations', () => {
  beforeEach(seed);
  const ask = (uid, o = {}) => setDoc(doc(db(uid), 'consultations', 'q1'), {
    farmerId: uid, farmerName: uid, topic: 'pest', question: 'Yellow spots on tomato leaves',
    imageUrl: null, status: 'open', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...o,
  });

  it('farmers ask; verified experts claim, answer; farmers rate', async () => {
    await assertFails(ask('buyer1'));
    await assertFails(ask('farmer1', { question: 'short' }));
    await assertSucceeds(ask('farmer1'));
    await assertSucceeds(getDocs(query(collection(db('exp1'), 'consultations'),
      where('status', '==', 'open'), orderBy('createdAt', 'desc'))));
    await assertFails(getDoc(doc(db('farmer2'), 'consultations', 'q1')));
    const claim = (uid) => updateDoc(doc(db(uid), 'consultations', 'q1'), {
      status: 'claimed', expertId: uid, expertName: uid, claimedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertFails(claim('expU'));
    await assertFails(claim('farmer2'));
    await assertSucceeds(claim('exp1'));
    await assertFails(getDoc(doc(db('expU'), 'consultations', 'q1')));
    const answer = (uid) => updateDoc(doc(db(uid), 'consultations', 'q1'), {
      status: 'answered', answer: 'Early blight: remove leaves, spray mancozeb.', answeredAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertFails(answer('farmer1'));
    await assertSucceeds(answer('exp1'));
    const rate = (uid, rating) => updateDoc(doc(db(uid), 'consultations', 'q1'), {
      status: 'closed', rating, closedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await assertFails(rate('exp1', 5));
    await assertFails(rate('farmer1', 9));
    await assertSucceeds(rate('farmer1', 5));
  });

  it('farmers cancel only open questions', async () => {
    await ask('farmer1');
    await assertSucceeds(updateDoc(doc(db('farmer1'), 'consultations', 'q1'), { status: 'cancelled', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db('exp1'), 'consultations', 'q1'), {
      status: 'claimed', expertId: 'exp1', expertName: 'e', claimedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }));
  });

  it('experts can sign up', async () => {
    await assertSucceeds(setDoc(doc(db('newExp'), 'users', 'newExp'), {
      id: 'newExp', role: 'expert', isVerified: false, isSuspended: false, name: 'N',
    }));
  });
});
