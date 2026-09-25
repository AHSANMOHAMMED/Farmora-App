const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "farmora-demo",
    firestore: {
      host: "127.0.0.1",
      port: 8085,
      rules: fs.readFileSync("../firestore.rules", "utf8"),
    }
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("Users Collection Rules", () => {
  it("allows normal role signup and denies self-assigned admin role", async () => {
    const farmerDb = testEnv.authenticatedContext('farmer').firestore();
    const adminDb = testEnv.authenticatedContext('attacker').firestore();

    await assertSucceeds(farmerDb.collection('users').doc('farmer').set({
      id: 'farmer',
      role: 'farmer',
      isVerified: false
    }));
    await assertFails(adminDb.collection('users').doc('attacker').set({
      id: 'attacker',
      role: 'admin',
      isVerified: false
    }));
  });

  it("should deny user from updating their availableBalance", async () => {
    const unauthedDb = testEnv.unauthenticatedContext().firestore();
    const aliceDb = testEnv.authenticatedContext('alice', { email: 'alice@example.com' }).firestore();

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        authUid: 'alice',
        role: 'farmer',
        isVerified: true,
        isSuspended: false,
        name: 'Alice',
        displayName: 'Alice',
        phone: '12345',
        availableBalance: 100,
        createdAt: new Date(),
        updatedAt: new Date()
      });
    });

    // Try to update balance
    await assertFails(aliceDb.collection('users').doc('alice').update({
      availableBalance: 1000
    }));
  });

  it("should allow user to update their displayName", async () => {
    const aliceDb = testEnv.authenticatedContext('alice', { email: 'alice@example.com' }).firestore();

    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('users').doc('alice').set({
        id: 'alice',
        authUid: 'alice',
        role: 'farmer',
        isVerified: true,
        isSuspended: false,
        name: 'Alice',
        displayName: 'Alice',
        phone: '12345',
        availableBalance: 100,
        createdAt: new Date(),
        updatedAt: new Date()
      });
    });

    await assertSucceeds(aliceDb.collection('users').doc('alice').update({
      displayName: 'Alice New'
    }));
  });
});
