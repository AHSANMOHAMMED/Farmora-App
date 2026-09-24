const { assertFails, assertSucceeds, initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const fs = require('fs');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "farmora-test",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: fs.readFileSync("../firestore.rules", "utf8"),
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  if (testEnv) await testEnv.clearFirestore();
  // Setup Mock Users
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.collection("users").doc("farmer1").set({
      role: "farmer",
      isVerified: true
    });
    await db.collection("users").doc("buyer1").set({
      role: "buyer",
      isVerified: true
    });
    await db.collection("users").doc("admin1").set({
      role: "admin",
      isVerified: true
    });
    await db.collection("products").doc("prod1").set({
      farmerId: "farmer1",
      name: "Test Product",
      priceMinor: 1000
    });
    await db.collection("orders").doc("order1").set({
      buyerId: "buyer1",
      farmerId: "farmer1",
      status: "pending"
    });
  });
});

describe("Farmora Firestore Rules", () => {
  it("should allow a farmer to update their own product but not another farmer's", async () => {
    const farmer1Db = testEnv.authenticatedContext('farmer1').firestore();
    const farmer2Db = testEnv.authenticatedContext('farmer2').firestore();
    
    // Farmer 1 updates their product
    await assertSucceeds(farmer1Db.collection("products").doc("prod1").update({ name: "Updated" }));
    
    // Farmer 2 fails to update Farmer 1's product
    await assertFails(farmer2Db.collection("products").doc("prod1").update({ name: "Hacked" }));
  });

  it("should deny clients from creating orders directly", async () => {
    const buyer1Db = testEnv.authenticatedContext('buyer1').firestore();
    
    // Buyer creating an order directly fails (must use callable functions)
    await assertFails(buyer1Db.collection("orders").doc("neworder").set({
      buyerId: "buyer1",
      farmerId: "farmer1"
    }));
  });

  it("should allow participants to read their orders", async () => {
    const farmer1Db = testEnv.authenticatedContext('farmer1').firestore();
    const buyer1Db = testEnv.authenticatedContext('buyer1').firestore();
    const strangerDb = testEnv.authenticatedContext('stranger').firestore();

    await assertSucceeds(farmer1Db.collection("orders").doc("order1").get());
    await assertSucceeds(buyer1Db.collection("orders").doc("order1").get());
    await assertFails(strangerDb.collection("orders").doc("order1").get());
  });

  it("should allow admins to do anything", async () => {
    const adminDb = testEnv.authenticatedContext('admin1', { admin: true }).firestore();
    
    await assertSucceeds(adminDb.collection("products").doc("prod1").delete());
    await assertSucceeds(adminDb.collection("orders").doc("order1").delete());
  });
});
