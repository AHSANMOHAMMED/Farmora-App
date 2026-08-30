import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { createHash, createHmac, randomUUID, timingSafeEqual } from "crypto";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const barcodeSecret = () => {
  const secret = process.env.BARCODE_SIGNING_SECRET;
  if (!secret || secret.length < 32) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Barcode signing is not configured."
    );
  }
  return secret;
};

const signBarcode = (payload: string): string =>
  createHmac("sha256", barcodeSecret()).update(payload).digest("base64url");

const requireAuth = (context: functions.https.CallableContext): string => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }
  return context.auth.uid;
};

const requireAdmin = (context: functions.https.CallableContext): string => {
  const uid = requireAuth(context);
  if (context.auth?.token.admin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Administrator access required.");
  }
  return uid;
};

const requireRole = async (
  uid: string,
  roles: string[]
): Promise<Record<string, unknown>> => {
  const snapshot = await db.collection("users").doc(uid).get();
  const user = snapshot.data();
  if (!user || !roles.includes(String(user.role)) || user.isSuspended === true) {
    throw new functions.https.HttpsError("permission-denied", "Account is not eligible.");
  }
  return user;
};

const config = (name: string): string => {
  const value = process.env[name];
  if (!value) throw new functions.https.HttpsError("failed-precondition", `${name} is not configured.`);
  return value;
};

const notifyUser = async (
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> => {
  const snapshot = await db.collection("users").doc(userId).collection("device_tokens")
    .where("enabled", "==", true).get();
  const tokens = snapshot.docs.map((doc) => String(doc.data().token)).filter(Boolean);
  if (tokens.length === 0) return;
  const result = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
  });
  const removals = result.responses.map((response, index) =>
    !response.success && response.error?.code === "messaging/registration-token-not-registered"
      ? snapshot.docs[index].ref.delete()
      : Promise.resolve());
  await Promise.all(removals);
};

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

export const registerDeviceToken = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const token = typeof data.token === "string" ? data.token.trim() : "";
  const platform = data.platform === "android" || data.platform === "ios" || data.platform === "web"
    ? data.platform
    : "";
  if (token.length < 20 || token.length > 4096 || !platform) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid notification device token.");
  }
  const tokenId = createHash("sha256").update(token).digest("hex");
  await db.collection("users").doc(uid).collection("device_tokens").doc(tokenId).set({
    token,
    platform,
    enabled: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const unregisterDeviceToken = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const token = typeof data.token === "string" ? data.token.trim() : "";
  if (token.length < 20 || token.length > 4096) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid notification device token.");
  }
  const tokenId = createHash("sha256").update(token).digest("hex");
  await db.collection("users").doc(uid).collection("device_tokens").doc(tokenId).delete();
  return { success: true };
});

export const getPlatformSettings = functions.https.onCall(async (_data, context) => {
  requireAdmin(context);
  const snapshot = await db.collection("platform_settings").doc("global").get();
  return snapshot.exists
    ? snapshot.data()
    : { maintenanceMode: false, platformFeeBps: 0, sessionTimeoutMinutes: 60 };
});

export const updatePlatformSettings = functions.https.onCall(async (data, context) => {
  const uid = requireAdmin(context);
  const updates: Record<string, unknown> = {};
  if (typeof data.maintenanceMode === "boolean") updates.maintenanceMode = data.maintenanceMode;
  if (data.platformFeeBps !== undefined) {
    const fee = Number(data.platformFeeBps);
    if (!Number.isSafeInteger(fee) || fee < 0 || fee > 10000) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid platform fee.");
    }
    updates.platformFeeBps = fee;
  }
  if (data.sessionTimeoutMinutes !== undefined) {
    const timeout = Number(data.sessionTimeoutMinutes);
    if (!Number.isSafeInteger(timeout) || timeout < 5 || timeout > 1440) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid session timeout.");
    }
    updates.sessionTimeoutMinutes = timeout;
  }
  if (Object.keys(updates).length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "No settings supplied.");
  }
  await db.collection("platform_settings").doc("global").set({
    ...updates,
    updatedBy: uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  return { success: true };
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
      await notifyUser(
        farmerId,
        "New order received",
        `You have a new order worth LKR ${calculatedTotal}`,
        { type: "new_order", orderId: context.params.orderId }
      );
    }
  });

// ─── onTransportTransition ────────────────────────────────────
// Validates that transport job status transitions follow the
// allowed state machine and logs every transition.
export const onTransportTransition = functions.firestore
  .document("transport_jobs/{jobId}")
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

// Creates an order from catalog IDs, never from client-supplied prices or totals.
export const createOrder = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const productId = typeof data.productId === "string" ? data.productId : "";
  const quantity = Number(data.quantity);
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  if (!productId || !Number.isSafeInteger(quantity) || quantity < 1
    || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid order details.");
  }

  const productRef = db.collection("products").doc(productId);
  const orderRef = db.collection("orders").doc();
  await db.runTransaction(async (transaction) => {
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const available = Number(product?.quantityAvailable);
    const priceMinor = Number(product?.priceMinor);
    if (!product || product.status !== "Active" || !Number.isSafeInteger(available)
      || !Number.isSafeInteger(priceMinor) || available < quantity) {
      throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
    }
    const subtotalMinor = priceMinor * quantity;
    transaction.update(productRef, {
      quantityAvailable: available - quantity,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.create(orderRef, {
      buyerId: uid,
      farmerId: product.farmerId,
      productId,
      listingVersion: product.listingVersion || 1,
      items: [{ productId, quantity, pricePerUnitMinor: priceMinor }],
      subtotalMinor,
      deliveryFeeMinor,
      totalMinor: subtotalMinor + deliveryFeeMinor,
      currency: "LKR",
      status: "pending",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return { orderId: orderRef.id };
});

export const createProduct = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const user = await requireRole(uid, ["farmer"]);
  if (user.isVerified !== true) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Account verification is required before publishing products."
    );
  }
  const name = typeof data.name === "string" ? data.name.trim() : "";
  const category = typeof data.category === "string" ? data.category.trim() : "";
  const unit = typeof data.unit === "string" ? data.unit.trim() : "";
  const location = typeof data.location === "string" ? data.location.trim() : "";
  const priceMinor = Number(data.priceMinor);
  const quantityAvailable = Number(data.quantityAvailable);
  if (!name || name.length > 120 || !category || !unit || !location
    || !Number.isSafeInteger(priceMinor) || priceMinor < 0
    || !Number.isSafeInteger(quantityAvailable) || quantityAvailable < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid product details.");
  }
  const productRef = db.collection("products").doc();
  await productRef.set({
    farmerId: uid,
    name,
    category,
    description: typeof data.description === "string" ? data.description.trim().slice(0, 4000) : "",
    unit,
    location,
    priceMinor,
    price: `LKR ${(priceMinor / 100).toFixed(2)}`,
    pricePerUnit: priceMinor / 100,
    currency: "LKR",
    quantityAvailable,
    quantity: String(quantityAvailable),
    status: quantityAvailable > 0 ? "Active" : "Empty",
    media: Array.isArray(data.media) ? data.media.slice(0, 5) : [],
    listingVersion: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { productId: productRef.id };
});

export const transitionOrder = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const nextStatus = typeof data.status === "string" ? data.status : "";
  const orderRef = db.collection("orders").doc(orderId);
  const snapshot = await orderRef.get();
  const order = snapshot.data();
  if (!order || !orderId) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }
  const isFarmer = order.farmerId === uid;
  const isBuyer = order.buyerId === uid;
  const transitions: Record<string, string[]> = {
    pending: isFarmer ? ["confirmed", "rejected"] : ["cancelled"],
    confirmed: isFarmer ? ["assigned", "cancelled"] : ["cancelled"],
    assigned: [],
    pickedUp: [],
    inTransit: [],
    delivered: [],
    rejected: [],
    cancelled: [],
  };
  if ((!isFarmer && !isBuyer) || !transitions[order.status]?.includes(nextStatus)) {
    throw new functions.https.HttpsError("failed-precondition", "Invalid order transition.");
  }
  await orderRef.update({
    status: nextStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const transitionTransport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["transporter"]);
  const jobId = typeof data.jobId === "string" ? data.jobId : "";
  const nextStatus = typeof data.status === "string" ? data.status : "";
  const ref = db.collection("transport_jobs").doc(jobId);
  const snapshot = await ref.get();
  const job = snapshot.data();
  if (!job) throw new functions.https.HttpsError("not-found", "Transport job not found.");
  const transitions: Record<string, string[]> = {
    requested: ["accepted"], accepted: ["pickedUp", "cancelled"],
    pickedUp: ["inTransit"], inTransit: ["delivered"], delivered: [], cancelled: [],
  };
  if (job.transporterId && job.transporterId !== uid
    || !transitions[job.status]?.includes(nextStatus)) {
    throw new functions.https.HttpsError("failed-precondition", "Invalid transport transition.");
  }
  await ref.update({
    status: nextStatus,
    transporterId: uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    [`${nextStatus}At`]: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const submitVerification = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer", "transporter"]);
  const documentType = typeof data.documentType === "string" ? data.documentType.trim() : "";
  const storagePath = typeof data.storagePath === "string" ? data.storagePath : "";
  if (!documentType || !storagePath.startsWith(`verification/${uid}/`)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid verification document.");
  }
  const ref = db.collection("verification_docs").doc();
  await ref.set({
    ownerId: uid,
    farmerId: uid,
    documentType,
    storagePath,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { documentId: ref.id };
});

// Only ciphertext is accepted. Plaintext chat is deliberately not persisted.
export const sendMessage = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const recipientId = typeof data.recipientId === "string" ? data.recipientId : "";
  const ciphertext = typeof data.ciphertext === "string" ? data.ciphertext : "";
  if (!orderId || !recipientId || recipientId === uid || ciphertext.length < 16 || ciphertext.length > 20000) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid encrypted message.");
  }
  const order = (await db.collection("orders").doc(orderId).get()).data();
  if (!order || ![order.buyerId, order.farmerId, order.transporterId].includes(uid)
    || ![order.buyerId, order.farmerId, order.transporterId].includes(recipientId)) {
    throw new functions.https.HttpsError("permission-denied", "Conversation is not authorized.");
  }
  const ref = db.collection("messages").doc();
  await ref.set({
    orderId,
    senderId: uid,
    receiverId: recipientId,
    ciphertext,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { messageId: ref.id };
});

// PayHere checkout data is signed server-side. Card details never enter Farmora.
export const createPayHereCheckout = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const snapshot = await db.collection("orders").doc(orderId).get();
  const order = snapshot.data();
  if (!order || order.buyerId !== uid || order.paymentStatus !== "payment_required") {
    throw new functions.https.HttpsError("failed-precondition", "Order is not payable.");
  }
  const merchantId = config("PAYHERE_MERCHANT_ID");
  const currency = String(order.currency || "LKR");
  const amount = (Number(order.totalMinor) / 100).toFixed(2);
  const secretHash = createHash("md5").update(config("PAYHERE_MERCHANT_SECRET")).digest("hex").toUpperCase();
  const hash = createHash("md5").update(`${merchantId}${orderId}${amount}${currency}${secretHash}`).digest("hex").toUpperCase();
  await snapshot.ref.update({
    paymentStatus: "checkout_started",
    paymentProvider: "payhere",
    paymentAttemptId: randomUUID(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { merchantId, orderId, amount, currency, hash, item: order.productId || "Farmora order" };
});

export const payHereWebhook = functions.https.onRequest(async (request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method not allowed");
    return;
  }
  const body = request.body as Record<string, string>;
  const required = ["merchant_id", "order_id", "payhere_amount", "payhere_currency", "status_code", "md5sig"];
  if (required.some((key) => typeof body[key] !== "string")) {
    response.status(400).send("Invalid notification");
    return;
  }
  const secretHash = createHash("md5").update(config("PAYHERE_MERCHANT_SECRET")).digest("hex").toUpperCase();
  const expected = createHash("md5").update(
    `${body.merchant_id}${body.order_id}${body.payhere_amount}${body.payhere_currency}${body.status_code}${secretHash}`
  ).digest("hex").toUpperCase();
  if (expected !== String(body.md5sig).toUpperCase() || body.merchant_id !== config("PAYHERE_MERCHANT_ID")) {
    response.status(401).send("Invalid signature");
    return;
  }
  const orderRef = db.collection("orders").doc(body.order_id);
  const status = body.status_code === "2" ? "paid" : "payment_failed";
  await orderRef.update({
    paymentStatus: status,
    escrowStatus: status === "paid" ? "funded_pending_delivery" : "not_funded",
    paymentProviderReference: body.payment_id || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  response.status(200).send("OK");
});

export const releaseEscrow = functions.https.onCall(async (data, context) => {
  const uid = requireAdmin(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const ref = db.collection("orders").doc(orderId);
  const snapshot = await ref.get();
  const order = snapshot.data();
  if (!order || order.status !== "delivered" || order.paymentStatus !== "paid" || order.disputeId) {
    throw new functions.https.HttpsError("failed-precondition", "Order is not eligible for payout.");
  }
  await ref.update({
    escrowStatus: "released",
    paymentStatus: "released",
    releasedBy: uid,
    releasedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("audit_logs").add({
    action: "escrow_release",
    orderId,
    actorId: uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const reviewVerification = functions.https.onCall(async (data, context) => {
  const uid = requireAdmin(context);
  const documentId = typeof data.documentId === "string" ? data.documentId : "";
  const status = data.status === "approved" || data.status === "rejected" ? data.status : "";
  if (!documentId || !status) throw new functions.https.HttpsError("invalid-argument", "Invalid verification decision.");
  const ref = db.collection("verification_docs").doc(documentId);
  const snapshot = await ref.get();
  const document = snapshot.data();
  if (!document || document.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "Document is not pending.");
  await ref.update({ status, reviewedBy: uid, reviewedAt: admin.firestore.FieldValue.serverTimestamp() });
  if (status === "approved" && document.ownerId) {
    await db.collection("users").doc(document.ownerId).update({ isVerified: true, updatedAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  return { success: true };
});

// Creates a signed, encrypted-by-reference authenticity token for a committed parcel.
// The barcode contains no contact information or payment credentials.
export const issueBarcode = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderSnapshot = await orderRef.get();
  const order = orderSnapshot.data();
  if (!order || order.farmerId !== uid || ["cancelled", "rejected"].includes(order.status)) {
    throw new functions.https.HttpsError("not-found", "Order is not eligible for a barcode.");
  }

  const barcodeId = randomUUID();
  const payload = JSON.stringify({
    barcodeId,
    orderId,
    farmerId: uid,
    productId: order.productId || null,
    listingVersion: order.listingVersion || 1,
    issuedAt: new Date().toISOString(),
  });
  const signature = signBarcode(payload);
  await db.collection("barcodes").doc(barcodeId).set({
    orderId,
    farmerId: uid,
    payload,
    signature,
    status: "issued",
    scanCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { barcodeId, payload, signature };
});

export const verifyBarcode = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const barcodeId = typeof data.barcodeId === "string" ? data.barcodeId : "";
  const suppliedSignature = typeof data.signature === "string" ? data.signature : "";
  const snapshot = await db.collection("barcodes").doc(barcodeId).get();
  const barcode = snapshot.data();
  if (!barcode || !suppliedSignature || typeof barcode.payload !== "string") {
    throw new functions.https.HttpsError("not-found", "Barcode is invalid.");
  }
  const expected = signBarcode(barcode.payload);
  const expectedBytes = Buffer.from(expected);
  const suppliedBytes = Buffer.from(suppliedSignature);
  const validSignature = expectedBytes.length === suppliedBytes.length
    && timingSafeEqual(expectedBytes, suppliedBytes);
  if (!validSignature || barcode.status !== "issued") {
    throw new functions.https.HttpsError("failed-precondition", "Barcode is invalid or revoked.");
  }
  const orderSnapshot = await db.collection("orders").doc(barcode.orderId).get();
  const order = orderSnapshot.data();
  if (!order || order.buyerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Barcode is not assigned to this buyer.");
  }
  await snapshot.ref.update({
    status: "verified",
    verifiedBy: uid,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    scanCount: admin.firestore.FieldValue.increment(1),
  });
  return { valid: true, orderId: barcode.orderId, manifest: JSON.parse(barcode.payload) };
});

export const submitReview = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const rating = Number(data.rating);
  const comment = typeof data.comment === "string" ? data.comment.trim() : "";
  if (!orderId || !Number.isInteger(rating) || rating < 1 || rating > 5 || comment.length > 2000) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid review.");
  }
  const orderSnapshot = await db.collection("orders").doc(orderId).get();
  const order = orderSnapshot.data();
  if (!order || order.buyerId !== uid || order.status !== "delivered") {
    throw new functions.https.HttpsError("failed-precondition", "Only delivered orders can be reviewed.");
  }
  const reviewRef = db.collection("reviews").doc(`${orderId}_${uid}`);
  if ((await reviewRef.get()).exists) {
    throw new functions.https.HttpsError("already-exists", "This order has already been reviewed.");
  }
  await reviewRef.create({
    orderId,
    reviewerId: uid,
    subjectId: order.farmerId,
    rating,
    comment,
    moderationStatus: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const openDispute = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const reason = typeof data.reason === "string" ? data.reason.trim() : "";
  if (!orderId || !reason || reason.length > 2000) {
    throw new functions.https.HttpsError("invalid-argument", "A dispute reason is required.");
  }
  const orderSnapshot = await db.collection("orders").doc(orderId).get();
  const order = orderSnapshot.data();
  if (!order || ![order.buyerId, order.farmerId, order.transporterId].includes(uid)) {
    throw new functions.https.HttpsError("permission-denied", "You cannot dispute this order.");
  }
  const disputeRef = db.collection("disputes").doc();
  await disputeRef.set({
    orderId,
    openedBy: uid,
    reason,
    status: "open",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await orderSnapshot.ref.update({ paymentStatus: "disputed", disputeId: disputeRef.id });
  return { disputeId: disputeRef.id };
});
