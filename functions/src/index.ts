import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

// ─── setUserRole ──────────────────────────────────────────────
// Sets a custom claim on the user's auth token and creates/updates
// the user document in Firestore.
export const setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated."
    );
  }

  const { role, displayName, phone, languageCode } = data;
  const uid = context.auth.uid;

  const validRoles = ["farmer", "buyer", "transporter"];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Role must be one of: ${validRoles.join(", ")}`
    );
  }

  // Set custom claim
  await auth.setCustomUserClaims(uid, { role });

  // Create/update Firestore document
  await db.collection("users").doc(uid).set(
    {
      role,
      displayName: displayName || "",
      phone: phone || "",
      languageCode: languageCode || "en",
      isVerified: false,
      isSuspended: false,
      isOnboardingComplete: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { success: true, role };
});

// ─── onOrderCreated ───────────────────────────────────────────
// Triggered when a new order is created. Validates and calculates
// server-side totals to prevent client-side manipulation.
export const onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.ref;
    const data = snap.data();

    // Server-side total calculation
    let calculatedSubtotal = 0;
    if (data.items && Array.isArray(data.items)) {
      for (const item of data.items) {
        calculatedSubtotal += item.pricePerUnitMinor * item.quantity;
      }
    }

    const deliveryFee = data.deliveryFeeMinor || 0;
    const calculatedTotal = calculatedSubtotal + deliveryFee;

    // Update with server-calculated values
    await order.update({
      subtotalMinor: calculatedSubtotal,
      totalMinor: calculatedTotal,
      status: "pending",
      paymentStatus: "unpaid",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify farmer
    const farmerId = data.farmerId;
    if (farmerId) {
      await db.collection("notifications").add({
        userId: farmerId,
        type: "new_order",
        title: "New order received",
        body: `You have a new order worth LKR ${calculatedTotal}`,
        orderId: context.params.orderId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });

// ─── onTransportTransition ────────────────────────────────────
// Validates that transport job status transitions follow the
// allowed state machine and logs every transition.
export const onTransportTransition = functions.firestore
  .document("transportJobs/{jobId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return; // No change

    const validTransitions: Record<string, string[]> = {
      requested: ["accepted", "cancelled"],
      accepted: ["pickedUp", "cancelled"],
      pickedUp: ["inTransit", "cancelled"],
      inTransit: ["delivered"],
      delivered: [],
      cancelled: [],
    };

    const allowed = validTransitions[before.status] || [];
    if (!allowed.includes(after.status)) {
      // Revert invalid transition
      await change.after.ref.update({ status: before.status });
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Invalid transition from ${before.status} to ${after.status}`
      );
    }

    // Log transition
    await db.collection("transportTransitions").add({
      jobId: context.params.jobId,
      from: before.status,
      to: after.status,
      actorId: after.transporterId || "system",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update the corresponding order status
    if (after.orderId) {
      const orderStatusMap: Record<string, string> = {
        accepted: "assigned",
        pickedUp: "pickedUp",
        inTransit: "inTransit",
        delivered: "delivered",
      };
      const orderStatus = orderStatusMap[after.status];
      if (orderStatus) {
        await db.collection("orders").doc(after.orderId).update({
          status: orderStatus,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(orderStatus === "delivered"
            ? { deliveredAt: admin.firestore.FieldValue.serverTimestamp() }
            : {}),
        });
      }
    }
  });

// ─── calculateOrderTotal (callable) ──────────────────────────
// Server-side order total calculation callable from the client.
export const calculateOrderTotal = functions.https.onCall(async (data) => {
  const { items, deliveryFee } = data;

  if (!items || !Array.isArray(items)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "items must be an array"
    );
  }

  let subtotal = 0;
  for (const item of items) {
    subtotal += item.pricePerUnitMinor * item.quantity;
  }

  const total = subtotal + (deliveryFee || 0);

  return {
    subtotalMinor: subtotal,
    deliveryFeeMinor: deliveryFee || 0,
    totalMinor: total,
  };
});
