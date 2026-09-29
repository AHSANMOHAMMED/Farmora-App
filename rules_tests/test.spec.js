const { assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { getEnv } = require('./helpers');

let testEnv;

before(async () => { testEnv = await getEnv(); });

describe("Farmora Firestore Rules", () => {
  beforeEach(async () => {
    await testEnv.clearFirestore();
    // Setup Mock Users
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("users").doc("farmer1").set({ role: "farmer", isVerified: true });
      await db.collection("users").doc("farmer2").set({ role: "farmer", isVerified: true });
      await db.collection("users").doc("buyer1").set({ role: "buyer", isVerified: true });
      await db.collection("users").doc("admin1").set({ role: "admin", isVerified: true });
      await db.collection("products").doc("prod1").set({
        farmerId: "farmer1",
        name: "Test Product",
        priceMinor: 1000,
        quantityAvailable: 10,
        status: "Active",
      });
      await db.collection("orders").doc("order1").set({
        buyerId: "buyer1",
        farmerId: "farmer1",
        status: "pending",
      });
    });
  });

  it("lets only the owner farmer edit a product (Spark), never re-assigning it", async () => {
    const farmer1Db = testEnv.authenticatedContext('farmer1').firestore();
    const farmer2Db = testEnv.authenticatedContext('farmer2').firestore();

    await assertSucceeds(farmer1Db.collection("products").doc("prod1").update({ name: "Updated" }));
    await assertFails(farmer1Db.collection("products").doc("prod1").update({ farmerId: "farmer2" }));
    await assertFails(farmer1Db.collection("products").doc("prod1").update({ priceMinor: -5 }));

    // Farmer 2 fails to update Farmer 1's product
    await assertFails(farmer2Db.collection("products").doc("prod1").update({ name: "Hacked" }));
  });

  it("should deny orders without validated pricing / stock reservation", async () => {
    const buyer1Db = testEnv.authenticatedContext('buyer1').firestore();

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

  it("allows admin moderation; other users cannot delete orders", async () => {
    const adminDb = testEnv.authenticatedContext('admin1', { admin: true }).firestore();
    const buyer1Db = testEnv.authenticatedContext('buyer1').firestore();

    await assertFails(buyer1Db.collection("orders").doc("order1").delete());
    await assertSucceeds(adminDb.collection("products").doc("prod1").delete());
    await assertSucceeds(adminDb.collection("orders").doc("order1").delete());
  });

  it("scopes transport_jobs reads to participants and denies all client writes", async () => {
    // Seed an assigned job plus an open request, bypassing rules.
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection("transport_jobs").doc("job1").set({
        orderId: "order1",
        farmerId: "farmer1",
        buyerId: "buyer1",
        transporterId: "transporter1",
        status: "accepted",
      });
      await db.collection("transport_jobs").doc("job2").set({
        orderId: "order1",
        farmerId: "farmer1",
        buyerId: "buyer1",
        status: "requested",
      });
    });

    const farmer1Db = testEnv.authenticatedContext('farmer1').firestore();
    const buyer1Db = testEnv.authenticatedContext('buyer1').firestore();
    const transporter1Db = testEnv.authenticatedContext('transporter1').firestore();
    const strangerDb = testEnv.authenticatedContext('stranger').firestore();

    // Participants read their own jobs; the open request is public to
    // verified transporters.
    await assertSucceeds(farmer1Db.collection("transport_jobs").doc("job1").get());
    await assertSucceeds(buyer1Db.collection("transport_jobs").doc("job1").get());
    await assertSucceeds(transporter1Db.collection("transport_jobs").doc("job1").get());
    await assertSucceeds(transporter1Db.collection("transport_jobs").doc("job2").get());
    await assertFails(strangerDb.collection("transport_jobs").doc("job1").get());

    // State changes only via the transitionTransport callable.
    await assertFails(transporter1Db.collection("transport_jobs").doc("job2").update({
      status: "accepted",
      transporterId: "transporter1",
    }));
    await assertFails(farmer1Db.collection("transport_jobs").doc("job2").delete());
  });
});
