const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "farmora-demo",
    firestore: {
      rules: fs.readFileSync("firestore.rules", "utf8"),
    }
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

describe("Users Collection Rules", () => {
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
