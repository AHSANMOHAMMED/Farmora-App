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

const requireAdmin = async (context: functions.https.CallableContext): Promise<string> => {
  const uid = requireAuth(context);
  if (context.auth?.token.admin !== true) {
    throw new functions.https.HttpsError("permission-denied", "Administrator access required.");
  }
  await requireRole(uid, ["admin"]);
  return uid;
};

const requireRole = async (
  uid: string,
  roles: string[]
): Promise<Record<string, unknown>> => {
  const snapshot = await db.collection("users").doc(uid).get();
  const user = snapshot.data();
  if (!user || !roles.includes(String(user.role))
    || user.isSuspended === true || user.isDeleted === true) {
    throw new functions.https.HttpsError("permission-denied", "Account is not eligible.");
  }
  return user;
};

const isWithinQuietHours = (
  prefs: Record<string, unknown> | undefined
): boolean => {
  if (!prefs) return false;
  const start = Number(prefs.quietHoursStart);
  const end = Number(prefs.quietHoursEnd);
  if (!Number.isInteger(start) || !Number.isInteger(end)
    || start < 0 || start > 23 || end < 0 || end > 23) {
    return false;
  }
  const hour = new Date().getHours();
  if (start === end) return true;
  if (start < end) return hour >= start && hour < end;
  // Overnight window (e.g. 22 → 7)
  return hour >= start || hour < end;
};

const notifyUser = async (
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> => {
  const userSnap = await db.collection("users").doc(userId).get();
  const user = userSnap.data() || {};
  const prefs = (user.notificationPreferences || {}) as Record<string, unknown>;
  if (isWithinQuietHours(prefs)) return;

  const tokenSnap = await db.collection("users").doc(userId).collection("device_tokens")
    .where("enabled", "==", true).get();
  const fromSubcollection = tokenSnap.docs
    .map((doc) => String(doc.data().token)).filter(Boolean);
  const fromUserField = Array.isArray(user.deviceTokens)
    ? user.deviceTokens.map((t: unknown) => String(t)).filter((t) => t.length >= 20)
    : [];
  const tokens = [...new Set([...fromSubcollection, ...fromUserField])];
  if (tokens.length === 0) return;

  const result = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
  });
  const removals = result.responses.map((response, index) => {
    if (response.success
      || response.error?.code !== "messaging/registration-token-not-registered") {
      return Promise.resolve();
    }
    const token = tokens[index];
    const matchingDoc = tokenSnap.docs.find((d) => d.data().token === token);
    return matchingDoc ? matchingDoc.ref.delete() : Promise.resolve();
  });
  await Promise.all(removals);
};

const syncPublicTransporterProfile = async (
  uid: string,
  user: FirebaseFirestore.DocumentData | undefined
): Promise<void> => {
  const publicRef = db.collection("public_profiles").doc(uid);
  if (!user || user.role !== "transporter" || user.isVerified !== true
    || user.isSuspended === true || user.isDeleted === true) {
    await publicRef.delete().catch(() => undefined);
    return;
  }
  await publicRef.set({
    uid,
    role: "transporter",
    isVerified: true,
    displayName: String(user.displayName || user.name || "Transport provider").slice(0, 120),
    photoUrl: typeof user.photoUrl === "string" ? user.photoUrl : "",
    district: typeof user.district === "string" ? user.district : "",
    vehicleType: typeof user.vehicleType === "string" ? user.vehicleType : "",
    vehicleRegistration: typeof user.vehicleRegistration === "string"
      ? user.vehicleRegistration : "",
    vehicleCapacity: Number.isFinite(Number(user.vehicleCapacity))
      ? Number(user.vehicleCapacity) : null,
    vehicleCapacityUnit: user.vehicleCapacityUnit === "tons" ? "tons" : "kg",
    serviceDistricts: Array.isArray(user.serviceDistricts)
      ? user.serviceDistricts.filter((v: unknown) => typeof v === "string").slice(0, 25)
      : [],
    availabilityStatus: user.availabilityStatus === "unavailable" ? "unavailable" : "available",
    location: user.locationSharingEnabled === true && user.location
      ? user.location : admin.firestore.FieldValue.delete(),
    locationUpdatedAt: user.locationSharingEnabled === true && user.location
      ? user.locationUpdatedAt : admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
};

export const syncPublicTransporterProfileOnUserChange = functions.firestore
  .document("users/{userId}").onWrite(async (change, context) => {
    await syncPublicTransporterProfile(context.params.userId, change.after.data());
  });

export const backfillPublicTransporterProfiles = functions.https.onCall(async (_data, context) => {
  await requireAdmin(context);
  const users = await db.collection("users").where("role", "==", "transporter").get();
  for (let offset = 0; offset < users.docs.length; offset += 400) {
    const chunk = users.docs.slice(offset, offset + 400);
    await Promise.all(chunk.map((doc) => syncPublicTransporterProfile(doc.id, doc.data())));
  }
  return { processed: users.size };
});

const writeNotification = async (
  userId: string,
  title: string,
  body: string,
  type: string,
  referenceId?: string,
  extra: Record<string, string> = {}
): Promise<void> => {
  await db.collection("notifications").add({
    userId,
    title,
    body,
    type,
    ...(referenceId ? { referenceId, orderId: referenceId } : {}),
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  // Always write in-app; FCM is skipped during quiet hours inside notifyUser.
  await notifyUser(userId, title, body, {
    type,
    ...(referenceId ? { orderId: referenceId } : {}),
    ...extra,
  });
};

const md5Hex = (value: string): string =>
  createHash("md5").update(value).digest("hex");

const payHereCredentials = (): { merchantId: string; merchantSecret: string; sandbox: boolean } | null => {
  const merchantId = process.env.PAYHERE_MERCHANT_ID || "";
  const merchantSecret = process.env.PAYHERE_MERCHANT_SECRET || "";
  if (!merchantId || !merchantSecret) return null;
  return {
    merchantId,
    merchantSecret,
    sandbox: process.env.PAYHERE_SANDBOX === "true",
  };
};

const createTransportJobForOrder = async (
  orderId: string,
  order: Record<string, any>,
  deliveryFeeMinor?: number
): Promise<string> => {
  const existing = await db.collection("transport_jobs")
    .where("orderId", "==", orderId)
    .where("status", "in", ["requested", "accepted", "pickedUp", "inTransit"])
    .limit(1)
    .get();
  if (!existing.empty) {
    return existing.docs[0].id;
  }
  const fee = Number.isSafeInteger(deliveryFeeMinor)
    ? Number(deliveryFeeMinor)
    : Number(order.deliveryFeeMinor || 0);
  const productName = String(order.productName || order.title || "Produce");
  const dropoff = String(order.deliveryAddress || "Buyer delivery point");
  const pickup = String(order.pickupAddress || order.location || "Farm pickup");
  const qtyLabel = String(order.quantity || `${(order.items?.[0]?.quantity) || ""} units`);
  const jobRef = db.collection("transport_jobs").doc();
  await jobRef.set({
    orderId,
    farmerId: order.farmerId,
    buyerId: order.buyerId,
    title: `Delivery for ${productName}`,
    route: `${pickup} → ${dropoff}`,
    detail: `${qtyLabel} · Ready for pickup`,
    fee: `LKR ${(fee / 100).toFixed(2)}`,
    offeredFeeMinor: fee,
    pickupAddress: pickup,
    dropoffAddress: dropoff,
    productName,
    quantity: qtyLabel,
    status: "requested",
    accepted: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return jobRef.id;
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
  await requireAdmin(context);
  const snapshot = await db.collection("platform_settings").doc("global").get();
  return snapshot.exists
    ? snapshot.data()
    : { maintenanceMode: false, platformFeeBps: 0, sessionTimeoutMinutes: 60 };
});

export const updatePlatformSettings = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
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

    // Update with server-calculated values (do not clobber paymentStatus)
    await order.update({
      subtotalMinor: calculatedSubtotal,
      totalMinor: calculatedTotal,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify farmer
    const farmerId = data.farmerId;
    if (farmerId) {
      await writeNotification(
        farmerId,
        "New order received",
        `You have a new order worth LKR ${(calculatedTotal / 100).toFixed(2)}`,
        "order",
        context.params.orderId
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

    // Update the corresponding order status + notify
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
          ...(after.transporterId ? { transporterId: after.transporterId } : {}),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(orderStatus === "delivered"
            ? { deliveredAt: admin.firestore.FieldValue.serverTimestamp() }
            : {}),
        });
      }
      const orderSnap = await db.collection("orders").doc(after.orderId).get();
      const order = orderSnap.data();
      if (order) {
        const body = `Delivery for ${order.productName || "your order"} is now ${after.status}.`;
        if (order.buyerId) {
          await writeNotification(String(order.buyerId), "Delivery update", body, "logistics", after.orderId);
        }
        if (order.farmerId) {
          await writeNotification(String(order.farmerId), "Delivery update", body, "logistics", after.orderId);
        }
        // Auto-delete harvest video after successful delivery (privacy).
        // Live courier GPS is cleared on delivery AND cancellation so a
        // cancelled job never retains an exposed last position.
        if (after.status === "delivered") {
          await cleanupProductVideoForOrder(order as Record<string, any>);
        }
        if (after.status === "delivered" || after.status === "cancelled") {
          await change.after.ref.update({
            courierLat: admin.firestore.FieldValue.delete(),
            courierLng: admin.firestore.FieldValue.delete(),
            locationUpdatedAt: admin.firestore.FieldValue.delete(),
          });
        }
      }
    }
  });

const cleanupProductVideoForOrder = async (
  order: Record<string, any>
): Promise<void> => {
  const productId = String(
    order.productId ||
    (Array.isArray(order.items) && order.items[0]?.productId) ||
    ""
  );
  if (!productId) return;
  const productRef = db.collection("products").doc(productId);
  const snap = await productRef.get();
  const product = snap.data();
  if (!product) return;
  const videoPath = typeof product.videoPath === "string" ? product.videoPath : "";
  if (videoPath) {
    try {
      await admin.storage().bucket().file(videoPath).delete();
    } catch (err) {
      functions.logger.warn("Harvest video delete failed", { productId, err });
    }
  }
  await productRef.update({
    videoPath: admin.firestore.FieldValue.delete(),
    videoUrl: admin.firestore.FieldValue.delete(),
    harvestStatus: "delivered",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
};

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
// Optional offerId: when set, uses that offer's negotiated total/qty (buyer must own it).
export const createOrder = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const productId = typeof data.productId === "string" ? data.productId : "";
  const quantity = Number(data.quantity);
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  const idempotencyKey = typeof data.idempotencyKey === "string"
    ? data.idempotencyKey : "";
  const paymentMethod = data.paymentMethod === "bank_deposit" ? "bank_deposit" : "cod";
  if (!productId || !Number.isSafeInteger(quantity) || quantity < 1
    || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid order details.");
  }
  if (!deliveryAddress || deliveryAddress.length < 5) {
    throw new functions.https.HttpsError("invalid-argument", "Delivery address is required.");
  }
  if (!/^[A-Za-z0-9_:-]{16,256}$/.test(idempotencyKey)) {
    throw new functions.https.HttpsError("invalid-argument", "A valid idempotency key is required.");
  }

  const productRef = db.collection("products").doc(productId);
  const idempotencyRequestHash = createHash("sha256").update(JSON.stringify({
    productId,
    quantity,
    deliveryFeeMinor,
    offerId,
    deliveryAddress,
    paymentMethod,
  })).digest("hex");
  const idempotencyDocId = createHash("sha256")
    .update(`${uid}:${idempotencyKey}`).digest("hex");
  const orderRef = db.collection("orders").doc(`order_${idempotencyDocId}`);
  const offerRef = offerId ? db.collection("offers").doc(offerId) : null;
  const buyerSnap = await db.collection("users").doc(uid).get();
  const buyer = buyerSnap.data() || {};

  await db.runTransaction(async (transaction) => {
    const existingOrder = await transaction.get(orderRef);
    if (existingOrder.exists) {
      const existing = existingOrder.data()!;
      if (existing.buyerId !== uid
        || existing.idempotencyRequestHash !== idempotencyRequestHash) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Idempotency key was already used for a different order."
        );
      }
      return;
    }
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const available = Number(product?.quantityAvailable);
    let priceMinor = Number(product?.priceMinor);
    let orderQuantity = quantity;
    let finalSubtotal = 0;
    // Reads must precede writes in a transaction, so fetch bank details now.
    let bankDetailsSnapshot: Record<string, string> | null = null;
    if (paymentMethod === "bank_deposit") {
      const bank = (await transaction.get(
        db.collection("bank_details").doc(String(product?.farmerId || "-"))
      )).data();
      if (!bank || !bank.bankName || !bank.branch || !bank.accountHolderName
        || !/^[0-9]{6,18}$/.test(String(bank.accountNumber || ""))) {
        throw new functions.https.HttpsError(
          "failed-precondition", "This farmer does not accept bank deposits yet.");
      }
      bankDetailsSnapshot = {
        bankName: String(bank.bankName),
        branch: String(bank.branch),
        accountHolderName: String(bank.accountHolderName),
        accountNumber: String(bank.accountNumber),
      };
    }

    if (offerRef) {
      const offerSnapshot = await transaction.get(offerRef);
      const offer = offerSnapshot.data();
      if (!offer || offer.buyerId !== uid || offer.productId !== productId
        || offer.status !== "pending") {
        throw new functions.https.HttpsError("failed-precondition", "Offer is not usable.");
      }
      orderQuantity = Number(offer.proposedQuantity);
      finalSubtotal = Number(offer.proposedPriceMinor);
      if (!Number.isSafeInteger(orderQuantity) || orderQuantity < 1
        || !Number.isSafeInteger(finalSubtotal) || finalSubtotal < 0) {
        throw new functions.https.HttpsError("failed-precondition", "Offer pricing is invalid.");
      }
      priceMinor = Math.round(finalSubtotal / orderQuantity);
      transaction.update(offerRef, {
        status: "accepted",
        orderId: orderRef.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      if (!Number.isSafeInteger(priceMinor) || priceMinor < 0) {
        throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
      }
      finalSubtotal = priceMinor * orderQuantity;
    }

    if (!product || product.status !== "Active" || !Number.isSafeInteger(available)
      || available < orderQuantity) {
      throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
    }
    const unit = String(product.unit || "unit");
    const productName = String(product.name || "Produce");
    const quantityLabel = `${orderQuantity} ${unit}`;
    transaction.update(productRef, {
      quantityAvailable: available - orderQuantity,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.create(orderRef, {
      buyerId: uid,
      farmerId: product.farmerId,
      productId,
      productName,
      title: productName,
      quantity: quantityLabel,
      unit,
      listingVersion: product.listingVersion || 1,
      items: [{ productId, quantity: orderQuantity, pricePerUnitMinor: priceMinor }],
      subtotalMinor: finalSubtotal,
      deliveryFeeMinor,
      totalMinor: finalSubtotal + deliveryFeeMinor,
      currency: "LKR",
      deliveryAddress,
      pickupAddress: String(product.location || "Farm pickup"),
      location: String(product.location || ""),
      buyerName: String(buyer.displayName || buyer.name || "Buyer"),
      buyerCompany: String(buyer.district || ""),
      status: "pending",
      paymentMethod,
      paymentStatus: "pending",
      ...(bankDetailsSnapshot ? { bankDetailsSnapshot } : {}),
      escrowStatus: "not_funded",
      requestedQuantity: quantity,
      idempotencyRequestHash,
      ...(offerId ? { offerId } : {}),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  return { orderId: orderRef.id };
});

// Buyer creates a price offer; farmerId always taken from the product document.
export const createOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const productId = typeof data.productId === "string" ? data.productId : "";
  const proposedQuantity = Number(data.proposedQuantity);
  const proposedPrice = Number(data.proposedPrice);
  if (!productId || !Number.isSafeInteger(proposedQuantity) || proposedQuantity < 1
    || !Number.isFinite(proposedPrice) || proposedPrice <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid offer details.");
  }
  const proposedPriceMinor = Math.round(proposedPrice * 100);
  const productSnapshot = await db.collection("products").doc(productId).get();
  const product = productSnapshot.data();
  if (!product || product.status !== "Active") {
    throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
  }
  const available = Number(product.quantityAvailable);
  if (!Number.isSafeInteger(available) || available < proposedQuantity) {
    throw new functions.https.HttpsError("failed-precondition", "Not enough stock for this offer.");
  }
  const farmerId = String(product.farmerId || "");
  if (!farmerId) {
    throw new functions.https.HttpsError("failed-precondition", "Product has no farmer.");
  }
  const offerRef = db.collection("offers").doc();
  await offerRef.set({
    productId,
    productName: String(product.name || ""),
    buyerId: uid,
    farmerId,
    proposedQuantity,
    proposedPrice,
    proposedPriceMinor,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("notifications").add({
    userId: farmerId,
    title: "New Price Offer",
    body: `You received an offer of LKR ${proposedPrice.toFixed(0)} for ${proposedQuantity} units.`,
    type: "offer",
    referenceId: offerRef.id,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { offerId: offerRef.id };
});

// Farmer accepts an offer and creates the buyer order at the negotiated total.
export const acceptOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  if (!offerId || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid offer accept request.");
  }

  const offerRef = db.collection("offers").doc(offerId);
  const orderRef = db.collection("orders").doc();

  await db.runTransaction(async (transaction) => {
    const offerSnapshot = await transaction.get(offerRef);
    const offer = offerSnapshot.data();
    if (!offer || offer.farmerId !== uid || offer.status !== "pending") {
      throw new functions.https.HttpsError("failed-precondition", "Offer cannot be accepted.");
    }
    const productId = String(offer.productId || "");
    const orderQuantity = Number(offer.proposedQuantity);
    const finalSubtotal = Number(offer.proposedPriceMinor);
    if (!productId || !Number.isSafeInteger(orderQuantity) || orderQuantity < 1
      || !Number.isSafeInteger(finalSubtotal) || finalSubtotal < 0) {
      throw new functions.https.HttpsError("failed-precondition", "Offer pricing is invalid.");
    }
    const productRef = db.collection("products").doc(productId);
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const available = Number(product?.quantityAvailable);
    if (!product || product.farmerId !== uid || product.status !== "Active"
      || !Number.isSafeInteger(available) || available < orderQuantity) {
      throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
    }
    const priceMinor = Math.round(finalSubtotal / orderQuantity);
    const unit = String(product.unit || "unit");
    const productName = String(product.name || offer.productName || "Produce");
    const quantityLabel = `${orderQuantity} ${unit}`;
    const deliveryAddress = typeof data.deliveryAddress === "string"
      ? data.deliveryAddress.trim().slice(0, 500)
      : String(offer.deliveryAddress || "");
    transaction.update(productRef, {
      quantityAvailable: available - orderQuantity,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.update(offerRef, {
      status: "accepted",
      orderId: orderRef.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.create(orderRef, {
      buyerId: offer.buyerId,
      farmerId: uid,
      productId,
      productName,
      title: productName,
      quantity: quantityLabel,
      unit,
      listingVersion: product.listingVersion || 1,
      items: [{ productId, quantity: orderQuantity, pricePerUnitMinor: priceMinor }],
      subtotalMinor: finalSubtotal,
      deliveryFeeMinor,
      totalMinor: finalSubtotal + deliveryFeeMinor,
      currency: "LKR",
      deliveryAddress: deliveryAddress || "To be confirmed with buyer",
      pickupAddress: String(product.location || "Farm pickup"),
      location: String(product.location || ""),
      status: "pending",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      offerId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  const accepted = (await offerRef.get()).data();
  if (accepted?.buyerId) {
    await writeNotification(
      String(accepted.buyerId),
      "Offer Accepted",
      "Your offer was accepted and an order was created.",
      "offer",
      offerId
    );
  }
  return { orderId: orderRef.id };
});

export const rejectOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const actor = await requireRole(uid, ["farmer", "buyer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  if (!offerId) {
    throw new functions.https.HttpsError("invalid-argument", "offerId is required.");
  }
  const offerRef = db.collection("offers").doc(offerId);
  const snapshot = await offerRef.get();
  const offer = snapshot.data();
  if (!offer || !["pending", "countered"].includes(String(offer.status))) {
    throw new functions.https.HttpsError("failed-precondition", "Offer cannot be changed.");
  }
  const status = actor.role === "farmer" && offer.farmerId === uid
    ? "rejected"
    : actor.role === "buyer" && offer.buyerId === uid ? "cancelled" : "";
  if (!status) throw new functions.https.HttpsError("permission-denied", "Only an offer participant can cancel or reject it.");
  await offerRef.update({
    status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await writeNotification(
    String(status === "rejected" ? offer.buyerId : offer.farmerId),
    status === "rejected" ? "Offer Rejected" : "Offer Cancelled",
    status === "rejected" ? "Your offer was rejected by the farmer." : "The buyer cancelled the offer.",
    "offer",
    offerId
  );
  return { success: true };
});

export const counterOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const proposedPriceMinor = Number(data.proposedPriceMinor);
  if (!offerId || !Number.isSafeInteger(proposedPriceMinor)
    || proposedPriceMinor < 1 || proposedPriceMinor > 1000000000) {
    throw new functions.https.HttpsError("invalid-argument", "A valid counter price is required.");
  }
  const offerRef = db.collection("offers").doc(offerId);
  let buyerId = "";
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(offerRef);
    const offer = snapshot.data();
    if (!offer || offer.farmerId !== uid || !["pending", "countered"].includes(String(offer.status))) {
      throw new functions.https.HttpsError("failed-precondition", "Offer cannot be countered.");
    }
    buyerId = String(offer.buyerId || "");
    transaction.update(offerRef, {
      status: "countered",
      proposedPriceMinor,
      proposedPrice: proposedPriceMinor / 100,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
  if (buyerId) await writeNotification(buyerId, "Counter offer received", "The farmer proposed a new price.", "offer", offerId);
  return { success: true };
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
    price: `LKR ${(priceMinor / 100).toFixed(2)} / ${unit}`,
    pricePerUnit: priceMinor / 100,
    currency: "LKR",
    quantityAvailable,
    quantity: `${quantityAvailable} ${unit} available`,
    status: quantityAvailable > 0 ? "Active" : "Empty",
    isOrganic: data.isOrganic === true,
    // Only https image URLs (Storage download URLs); drop anything else.
    media: Array.isArray(data.media)
      ? data.media.filter((u: unknown) => typeof u === "string"
        && u.startsWith("https://") && u.length < 2048).slice(0, 5)
      : [],
    harvestStatus: "growing",
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

  let jobId: string | undefined;
  if (nextStatus === "confirmed" && isFarmer) {
    jobId = await createTransportJobForOrder(orderId, order as Record<string, any>);
    await writeNotification(
      String(order.buyerId),
      "Order Confirmed",
      `Your order for ${order.productName || "produce"} was confirmed. Transport is being arranged.`,
      "order",
      orderId
    );
  } else if (nextStatus === "rejected" || nextStatus === "cancelled") {
    await writeNotification(
      String(isFarmer ? order.buyerId : order.farmerId),
      nextStatus === "rejected" ? "Order Declined" : "Order Cancelled",
      `Order for ${order.productName || "produce"} was ${nextStatus}.`,
      "order",
      orderId
    );
  }
  return { success: true, jobId };
});

export const requestTransport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const deliveryFeeMinor = Number(data.deliveryFeeMinor);
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  }
  const orderSnap = await db.collection("orders").doc(orderId).get();
  const order = orderSnap.data();
  if (!order || order.farmerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Order not found.");
  }
  if (!["confirmed", "assigned"].includes(String(order.status))) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Order must be confirmed before requesting transport."
    );
  }
  if (order.status === "confirmed") {
    // already confirmed — ensure job exists
  } else if (order.status === "pending") {
    throw new functions.https.HttpsError("failed-precondition", "Confirm the order first.");
  }
  const fee = Number.isSafeInteger(deliveryFeeMinor) && deliveryFeeMinor >= 0
    ? deliveryFeeMinor
    : undefined;
  const jobId = await createTransportJobForOrder(orderId, order as Record<string, any>, fee);
  return { jobId };
});

export const updateOrderAddress = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  if (!orderId || deliveryAddress.length < 5) {
    throw new functions.https.HttpsError("invalid-argument", "Valid address required.");
  }
  const ref = db.collection("orders").doc(orderId);
  const snap = await ref.get();
  const order = snap.data();
  if (!order || order.buyerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Order not found.");
  }
  if (order.status !== "pending") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Address can only change while the order is pending."
    );
  }
  await ref.update({
    deliveryAddress,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

export const markPaymentReceived = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const method = typeof data.method === "string" ? data.method : "cod";
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  }
  const ref = db.collection("orders").doc(orderId);
  const snap = await ref.get();
  const order = snap.data();
  if (!order) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }
  // Only the farmer who received the money confirms it (COD after delivery).
  const isFarmer = order.farmerId === uid;
  const isAdmin = context.auth?.token.admin === true;
  if (!isFarmer && !isAdmin) {
    throw new functions.https.HttpsError("permission-denied", "Not allowed.");
  }
  const delivered = ["delivered", "completed"].includes(String(order.status).toLowerCase());
  if (!delivered && !isAdmin) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Payment can be confirmed after delivery."
    );
  }
  await ref.update({
    paymentStatus: "paid",
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
    paymentConfirmedBy: uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (order.buyerId) {
    await writeNotification(
      String(order.buyerId),
      "Payment received",
      `The farmer confirmed your ${method === "bank_deposit" ? "bank deposit" : "cash"} payment.`,
      "order",
      orderId
    );
  }
  return { success: true };
});

export const transitionTransport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["transporter"]);
  const jobId = typeof data.jobId === "string" ? data.jobId : "";
  const nextStatus = typeof data.status === "string" ? data.status : "";
  const reason = typeof data.reason === "string" ? data.reason.trim() : "";
  const ref = db.collection("transport_jobs").doc(jobId);
  const snapshot = await ref.get();
  const job = snapshot.data();
  if (!job) throw new functions.https.HttpsError("not-found", "Transport job not found.");
  const normalizeStatus = (value: unknown): string => {
    switch (String(value ?? "").trim().toUpperCase().replace(/[\s-]/g, "_")) {
      case "OPEN":
      case "REQUESTED":
      case "PENDING":
        return "requested";
      case "ACCEPTED":
        return "accepted";
      case "COLLECTED":
      case "PICKEDUP":
      case "PICKED_UP":
        return "pickedUp";
      case "IN_TRANSIT":
      case "INTRANSIT":
        return "inTransit";
      case "COMPLETED":
      case "DELIVERED":
        return "delivered";
      case "CANCELLED":
        return "cancelled";
      default:
        return String(value ?? "");
    }
  };
  const currentStatus = normalizeStatus(job.status);
  const requestedStatus = normalizeStatus(nextStatus);
  const transitions: Record<string, string[]> = {
    requested: ["accepted"], accepted: ["pickedUp", "cancelled"],
    pickedUp: ["inTransit"], inTransit: ["delivered"], delivered: [], cancelled: [],
  };
  if (job.transporterId && job.transporterId !== uid
    || !transitions[currentStatus]?.includes(requestedStatus)) {
    throw new functions.https.HttpsError("failed-precondition", "Invalid transport transition.");
  }
  await db.runTransaction(async (transaction) => {
    transaction.update(ref, {
      status: requestedStatus,
      transporterId: uid,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      [`${requestedStatus}At`]: admin.firestore.FieldValue.serverTimestamp(),
      ...(requestedStatus === "cancelled" && reason ? { cancellationReason: reason } : {}),
    });

    if (requestedStatus === "delivered" && job.deliveryFeeMinor) {
      const transporterRef = db.collection("users").doc(uid);
      const amount = job.deliveryFeeMinor / 100.0;
      transaction.update(transporterRef, {
        availableBalance: admin.firestore.FieldValue.increment(amount)
      });
    }
  });
  return { success: true };
});

export const updateTransporterProfile = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["transporter"]);

  const displayName = typeof data.displayName === "string" ? data.displayName.trim() : "";
  const phone = typeof data.phone === "string" ? data.phone.trim() : "";
  const vehicleType = typeof data.vehicleType === "string" ? data.vehicleType.trim() : "";
  const vehicleRegistration = typeof data.vehicleRegistration === "string"
    ? data.vehicleRegistration.trim().toUpperCase()
    : "";
  const vehicleCapacity = data.vehicleCapacity == null ? null : Number(data.vehicleCapacity);
  const vehicleCapacityUnit = data.vehicleCapacityUnit === "tons" ? "tons" : "kg";
  const vehicleDescription = typeof data.vehicleDescription === "string"
    ? data.vehicleDescription.trim()
    : "";
  const availabilityStatus = data.availabilityStatus === "available"
    ? "available"
    : data.availabilityStatus === "unavailable"
      ? "unavailable"
      : "";

  if (displayName.length < 2 || phone.length < 7 || !vehicleType
    || !vehicleRegistration || !availabilityStatus
    || (vehicleCapacity != null && (!Number.isFinite(vehicleCapacity) || vehicleCapacity <= 0))) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Name, phone, vehicle details, and availability are required."
    );
  }

  await db.collection("users").doc(uid).update({
    displayName,
    phone,
    vehicleType,
    vehicleRegistration,
    vehicleCapacity,
    vehicleCapacityUnit,
    vehicleDescription,
    availabilityStatus,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true };
});

/** Live courier coordinates while a job is active. Cleared after delivered. */
export const updateTransportLocation = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["transporter"]);
  const jobId = typeof data.jobId === "string" ? data.jobId : "";
  const lat = Number(data.lat);
  const lng = Number(data.lng);
  if (!jobId || !Number.isFinite(lat) || !Number.isFinite(lng)) {
    throw new functions.https.HttpsError("invalid-argument", "jobId, lat, lng required.");
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid coordinates.");
  }
  const ref = db.collection("transport_jobs").doc(jobId);
  const snap = await ref.get();
  const job = snap.data();
  if (!job || job.transporterId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Not your job.");
  }
  if (!["accepted", "pickedUp", "inTransit"].includes(String(job.status))) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Location sharing only while delivery is active."
    );
  }
  await ref.update({
    courierLat: lat,
    courierLng: lng,
    locationUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
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

// Chat text is accepted only as ciphertext (plaintext is never persisted).
// Photos reference Storage objects the sender uploaded for this order.
export const sendMessage = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const recipientId = typeof data.recipientId === "string" ? data.recipientId : "";
  const ciphertext = typeof data.ciphertext === "string" ? data.ciphertext : "";
  const attachmentUrl = typeof data.attachmentUrl === "string" ? data.attachmentUrl : "";
  const attachmentPath = typeof data.attachmentPath === "string" ? data.attachmentPath : "";
  const attachmentKind = data.attachmentKind === "payment_proof" ? "payment_proof" : "photo";
  const hasText = ciphertext.length > 0;
  const hasImage = attachmentUrl.length > 0;
  if (!orderId || !recipientId || recipientId === uid || (!hasText && !hasImage)
    || (hasText && (ciphertext.length < 16 || ciphertext.length > 20000))) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid message.");
  }
  const order = (await db.collection("orders").doc(orderId).get()).data();
  if (!order || ![order.buyerId, order.farmerId, order.transporterId].includes(uid)
    || ![order.buyerId, order.farmerId, order.transporterId].includes(recipientId)) {
    throw new functions.https.HttpsError("permission-denied", "Conversation is not authorized.");
  }
  if (hasImage) {
    const expectedPrefix = attachmentKind === "payment_proof"
      ? `payment_slips/${orderId}/${uid}_`
      : `chat/${orderId}/${uid}/`;
    if (!attachmentUrl.startsWith("https://") || attachmentUrl.length > 2048
      || !attachmentPath.startsWith(expectedPrefix)
      || (attachmentKind === "payment_proof" && order.buyerId !== uid)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid attachment.");
    }
  }
  // Same deterministic id the client uses (o_{orderId}_{uidA}_{uidB}).
  const participants = [uid, recipientId].sort();
  const conversationId = `o_${orderId}_${participants[0]}_${participants[1]}`;
  const convoRef = db.collection("conversations").doc(conversationId);
  if (!(await convoRef.get()).exists) {
    await convoRef.set({
      orderId,
      participantIds: participants,
      lastMessage: "",
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      unreadCounts: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  const ref = db.collection("messages").doc();
  await ref.set({
    orderId,
    conversationId,
    senderId: uid,
    receiverId: recipientId,
    recipientId,
    type: hasImage ? "image" : "text",
    ...(hasText ? { ciphertext } : {}),
    ...(hasImage ? { attachmentUrl, attachmentPath, attachmentKind } : {}),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await convoRef.update({
    lastMessage: hasImage
      ? (attachmentKind === "payment_proof" ? "Payment receipt" : "Photo")
      : ciphertext.slice(0, 140),
    lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await writeNotification(
    recipientId,
    hasImage && attachmentKind === "payment_proof" ? "Payment receipt received" : "New message",
    hasImage ? "You received a photo in your order chat." : "You have a new encrypted order message.",
    "message",
    orderId
  );
  return { messageId: ref.id, conversationId };
});

export const createPayHereCheckout = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const creds = payHereCredentials();
  if (!creds) {
    return { enabled: false, useCod: true };
  }

  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  }
  const orderSnap = await db.collection("orders").doc(orderId).get();
  const order = orderSnap.data();
  if (!order || order.buyerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Order not found.");
  }
  if (order.paymentStatus === "paid" || order.paymentStatus === "released") {
    throw new functions.https.HttpsError("failed-precondition", "Order is already paid.");
  }

  const amountMajor = (Number(order.totalMinor || 0) / 100).toFixed(2);
  const currency = String(order.currency || "LKR");
  const hash = md5Hex(
    `${creds.merchantId}${orderId}${amountMajor}${currency}${creds.merchantSecret}`
  ).toUpperCase();

  const checkoutUrl = creds.sandbox
    ? "https://sandbox.payhere.lk/pay/checkout"
    : "https://www.payhere.lk/pay/checkout";

  await orderSnap.ref.update({
    paymentMethod: "payhere",
    payhereCheckoutAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    enabled: true,
    useCod: false,
    sandbox: creds.sandbox,
    checkoutUrl,
    merchant_id: creds.merchantId,
    order_id: orderId,
    amount: amountMajor,
    currency,
    items: String(order.productName || order.title || "Farmora order"),
    hash,
  };
});

export const payHereWebhook = functions.https.onRequest(async (request, response) => {
  const creds = payHereCredentials();
  if (!creds) {
    response.status(503).send("PayHere is not configured.");
    return;
  }

  try {
    const body = request.method === "POST" ? request.body : request.query;
    const merchantId = String(body.merchant_id || "");
    const orderId = String(body.order_id || "");
    const payhereAmount = String(body.payhere_amount || "");
    const payhereCurrency = String(body.payhere_currency || "");
    const statusCode = String(body.status_code || "");
    const md5sig = String(body.md5sig || "").toUpperCase();

    if (!merchantId || !orderId || !payhereAmount || !payhereCurrency || !statusCode || !md5sig) {
      response.status(400).send("Missing webhook fields.");
      return;
    }
    if (merchantId !== creds.merchantId) {
      response.status(403).send("Merchant mismatch.");
      return;
    }

    const localSig = md5Hex(
      `${merchantId}${orderId}${payhereAmount}${payhereCurrency}${statusCode}${md5Hex(creds.merchantSecret).toUpperCase()}`
    ).toUpperCase();

    const a = Buffer.from(localSig);
    const b = Buffer.from(md5sig);
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      response.status(403).send("Invalid signature.");
      return;
    }

    // Status 2 = success (paid)
    if (statusCode === "2") {
      const orderRef = db.collection("orders").doc(orderId);
      let alreadyPaid = false;
      let orderData: any = null;

      await db.runTransaction(async (transaction) => {
        const orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) return;
        
        orderData = orderSnap.data();
        if (orderData?.paymentStatus === "paid") {
          alreadyPaid = true;
          return; // Idempotency check: already processed
        }

        transaction.update(orderRef, {
          paymentStatus: "paid",
          escrowStatus: "held",
          paymentMethod: "payhere",
          payhereStatusCode: statusCode,
          payherePaymentId: String(body.payment_id || ""),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      if (!alreadyPaid && orderData?.farmerId) {
        await writeNotification(
          String(orderData.farmerId),
          "Payment received",
          `PayHere payment confirmed for ${orderData.productName || "an order"}.`,
          "order",
          orderId
        );
      }
    }

    response.status(200).send("OK");
  } catch (err) {
    functions.logger.error("payHereWebhook error", err);
    response.status(500).send("Webhook processing failed.");
  }
});

export const releaseEscrow = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const orderRef = db.collection("orders").doc(orderId);

  await db.runTransaction(async (transaction) => {
    const orderSnap = await transaction.get(orderRef);
    const order = orderSnap.data();
    if (!order || order.status !== "delivered" || order.paymentStatus !== "paid" || order.disputeId) {
      throw new functions.https.HttpsError("failed-precondition", "Order is not eligible for payout.");
    }
    const farmerId = order.farmerId;
    if (!farmerId) throw new functions.https.HttpsError("internal", "Order has no farmerId.");
    
    const settlementMinor = typeof order.settlementMinor === "number" ? order.settlementMinor : Number(order.totalMinor || 0);
    const settlementMajor = settlementMinor / 100;

    const farmerRef = db.collection("users").doc(farmerId);
    const auditRef = db.collection("audit_logs").doc();

    transaction.update(orderRef, {
      escrowStatus: "released",
      paymentStatus: "released",
      releasedBy: uid,
      releasedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.set(farmerRef, {
      availableBalance: admin.firestore.FieldValue.increment(settlementMajor),
      totalEarnings: admin.firestore.FieldValue.increment(settlementMajor)
    }, { merge: true });

    transaction.create(auditRef, {
      action: "escrow_release",
      orderId,
      farmerId,
      amount: settlementMajor,
      actorId: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

export const requestWithdrawal = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const amount = Number(data.amount);
  const bankName = typeof data.bankName === "string" ? data.bankName : "";
  const accountNumber = typeof data.accountNumber === "string" ? data.accountNumber : "";
  const payoutMethod = typeof data.payoutMethod === "string" ? data.payoutMethod : "CEFT";

  if (!amount || amount <= 0 || !bankName || !accountNumber) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid withdrawal parameters.");
  }

  const farmerRef = db.collection("users").doc(uid);
  const settlementRef = db.collection("settlements").doc();

  await db.runTransaction(async (transaction) => {
    const farmerSnap = await transaction.get(farmerRef);
    const farmer = farmerSnap.data();
    if (!farmer) throw new functions.https.HttpsError("not-found", "User not found.");

    const availableBalance = typeof farmer.availableBalance === "number" ? farmer.availableBalance : 0;
    if (availableBalance < amount) {
      throw new functions.https.HttpsError("failed-precondition", "Insufficient balance.");
    }

    const fee = amount * 0.05; // 5% commission as defined in client
    const netAmount = amount - fee;

    transaction.update(farmerRef, {
      availableBalance: admin.firestore.FieldValue.increment(-amount)
    });

    const role = farmer.role || "farmer";
    transaction.create(settlementRef, {
      orderId: "WITHDRAWAL-" + Date.now(),
      orderNumber: "WD-" + String(Date.now()).slice(7),
      recipientId: uid,
      recipientName: farmer.displayName || farmer.businessName || farmer.name || "User",
      recipientRole: role,
      bankName,
      accountNumber,
      grossAmount: amount,
      platformFee: fee,
      netAmount,
      payoutMethod,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });

  return { success: true, settlementId: settlementRef.id };
});

export const reviewVerification = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
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
  const evidenceUrls = Array.isArray(data.evidenceUrls)
    ? data.evidenceUrls.filter((u: unknown) => typeof u === "string" && (u as string).length <= 2000).slice(0, 5)
    : [];
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
    evidenceImages: evidenceUrls,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await orderSnapshot.ref.update({ paymentStatus: "disputed", disputeId: disputeRef.id });
  return { disputeId: disputeRef.id };
});

export const resolveDispute = functions.https.onCall(async (data, context) => {
  const adminId = await requireAdmin(context);
  const orderId = typeof data.orderId === "string" ? data.orderId.trim() : "";
  const resolution = typeof data.resolution === "string" ? data.resolution : "";
  const adminNotes = typeof data.adminNotes === "string"
    ? data.adminNotes.trim().slice(0, 2000) : "";
  const refundPercent = resolution === "refund_buyer" ? 100
    : resolution === "release_farmer" ? 0
      : resolution === "split_settlement" ? 50 : -1;
  if (!orderId || refundPercent < 0 || !adminNotes) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Order, valid outcome, and audit notes are required."
    );
  }

  const orderRef = db.collection("orders").doc(orderId);
  await db.runTransaction(async (transaction) => {
    const orderSnapshot = await transaction.get(orderRef);
    const order = orderSnapshot.data();
    if (!order) {
      throw new functions.https.HttpsError("not-found", "Order not found.");
    }
    if (order.paymentStatus !== "disputed" || !order.disputeId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Order has no open payment dispute."
      );
    }
    const disputeRef = db.collection("disputes").doc(String(order.disputeId));
    const disputeSnapshot = await transaction.get(disputeRef);
    const dispute = disputeSnapshot.data();
    if (!dispute || dispute.orderId !== orderId || dispute.status !== "open") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "The linked dispute is already closed or invalid."
      );
    }

    const totalMinor = Number(order.totalMinor);
    if (!Number.isSafeInteger(totalMinor) || totalMinor < 0) {
      throw new functions.https.HttpsError("failed-precondition", "Order total is invalid.");
    }
    const refundMinor = Math.round(totalMinor * refundPercent / 100);
    const settlementMinor = totalMinor - refundMinor;
    const paymentStatus = refundPercent === 100 ? "refund_pending"
      : refundPercent === 0 ? "settlement_pending" : "split_settlement_pending";
    const resolvedAt = admin.firestore.FieldValue.serverTimestamp();

    transaction.update(orderRef, {
      status: resolution === "refund_buyer" ? "cancelled" : "completed",
      disputeStatus: "resolved",
      disputeResolution: resolution,
      disputeAdminNotes: adminNotes,
      disputeResolvedBy: adminId,
      disputeResolvedAt: resolvedAt,
      refundPercent,
      refundMinor,
      settlementMinor,
      paymentStatus,
      updatedAt: resolvedAt,
    });
    transaction.update(disputeRef, {
      status: "resolved",
      resolution,
      adminNotes,
      resolvedBy: adminId,
      resolvedAt,
      refundPercent,
      refundMinor,
      settlementMinor,
    });
    transaction.create(db.collection("audit_logs").doc(), {
      action: "dispute_resolved",
      orderId,
      disputeId: order.disputeId,
      resolution,
      refundPercent,
      actorId: adminId,
      createdAt: resolvedAt,
    });
  });

  return { success: true, orderId, resolution, refundPercent };
});

// ─── Admin: seed Sri Lankan marketplace data (Admin SDK only) ──────
// Attaches products/orders/jobs to REAL users by role (or explicit IDs).
export const seedDatabase = functions.https.onCall(async (data, context) => {
  await requireAdmin(context);
  const now = admin.firestore.FieldValue.serverTimestamp();

  const findUidByRole = async (role: string): Promise<string | null> => {
    const snap = await db.collection("users").where("role", "==", role).limit(10).get();
    const docs = snap.docs.filter((d) => {
      const u = d.data();
      return u.isSuspended !== true && u.isDeleted !== true;
    });
    const verified = docs.find((d) => d.data().isVerified === true);
    return (verified || docs[0])?.id || null;
  };

  let farmerId = (typeof data?.farmerId === "string" && data.farmerId) || await findUidByRole("farmer");
  let buyerId = (typeof data?.buyerId === "string" && data.buyerId) || await findUidByRole("buyer");
  let transporterId = (typeof data?.transporterId === "string" && data.transporterId) || await findUidByRole("transporter");

  if (!farmerId) {
    farmerId = "farmer_demo_1";
    await db.collection("users").doc(farmerId).set({
      id: farmerId, authUid: farmerId, role: "farmer", name: "Demo Farmer", displayName: "Demo Farmer", phone: "0770000001", isVerified: true, isSuspended: false, district: "Nuwara Eliya", createdAt: now, updatedAt: now
    }, { merge: true });
  }
  
  if (!buyerId) {
    buyerId = "buyer_demo_1";
    await db.collection("users").doc(buyerId).set({
      id: buyerId, authUid: buyerId, role: "buyer", name: "Demo Buyer", displayName: "Demo Buyer", phone: "0770000002", isVerified: true, isSuspended: false, district: "Colombo", createdAt: now, updatedAt: now
    }, { merge: true });
  }
  
  if (!transporterId) {
    transporterId = "transporter_demo_1";
    await db.collection("users").doc(transporterId).set({
      id: transporterId, authUid: transporterId, role: "transporter", name: "Demo Transporter", displayName: "Demo Transporter", phone: "0770000003", isVerified: true, isSuspended: false, district: "Gampaha", vehicleType: "Truck", vehicleCapacity: 5000, vehicleCapacityUnit: "kg", isApprovedTransporter: true, createdAt: now, updatedAt: now
    }, { merge: true });
  }

  const farmerSnap = await db.collection("users").doc(farmerId).get();
  const buyerSnap = await db.collection("users").doc(buyerId).get();
  const farmerName = String(farmerSnap.data()?.name || farmerSnap.data()?.displayName || "Farmer");
  const buyerName = String(buyerSnap.data()?.name || buyerSnap.data()?.displayName || "Buyer");
  const farmerDistrict = String(farmerSnap.data()?.district || "Nuwara Eliya");
  const buyerDistrict = String(buyerSnap.data()?.district || "Colombo");

  const productSpecs = [
    {
      name: "Nuwara Eliya Carrots",
      category: "Vegetables",
      location: "Nuwara Eliya",
      unit: "kg",
      priceMinor: 35000,
      quantityAvailable: 80,
      description: "Crisp hill-country carrots from Nuwara Eliya farms.",
      isOrganic: true,
    },
    {
      name: "Dambulla Tomatoes",
      category: "Vegetables",
      location: "Matale",
      unit: "kg",
      priceMinor: 28000,
      quantityAvailable: 120,
      description: "Fresh tomatoes from the Dambulla economic centre supply belt.",
      isOrganic: false,
    },
    {
      name: "Jaffna Red Onions",
      category: "Vegetables",
      location: "Jaffna",
      unit: "kg",
      priceMinor: 42000,
      quantityAvailable: 60,
      description: "Pungent Jaffna red onions prized across Sri Lanka.",
      isOrganic: false,
    },
    {
      name: "Ceylon Cinnamon (Kurundu)",
      category: "Spices",
      location: "Kandy",
      unit: "kg",
      priceMinor: 450000,
      quantityAvailable: 15,
      description: "True Ceylon cinnamon quills, Grade 1 Alba.",
      isOrganic: true,
    },
    {
      name: "King Coconut (Thambili)",
      category: "Fruits",
      location: "Kurunegala",
      unit: "pcs",
      priceMinor: 12000,
      quantityAvailable: 200,
      description: "Sweet Thambili king coconuts, electrolyte-rich.",
      isOrganic: true,
    },
    {
      name: "Kolikuttu Banana",
      category: "Fruits",
      location: "Hambantota",
      unit: "kg",
      priceMinor: 25000,
      quantityAvailable: 90,
      description: "Ripe Kolikuttu bananas from the southern plains.",
      isOrganic: false,
    },
    {
      name: "Keeri Samba Rice",
      category: "Grains",
      location: "Polonnaruwa",
      unit: "kg",
      priceMinor: 32000,
      quantityAvailable: 500,
      description: "Premium Keeri Samba rice from Polonnaruwa paddies.",
      isOrganic: false,
    },
    {
      name: "Low-grown Ceylon Tea",
      category: "Spices",
      location: "Ratnapura",
      unit: "kg",
      priceMinor: 180000,
      quantityAvailable: 40,
      description: "Orthodox low-grown black tea from Ratnapura estates.",
      isOrganic: true,
    },
    {
      name: "Gotukola Bundle",
      category: "Herbs",
      location: "Gampaha",
      unit: "pcs",
      priceMinor: 8000,
      quantityAvailable: 150,
      description: "Fresh Gotukola greens for mallung and juice.",
      isOrganic: true,
    },
    {
      name: "Ambul Banana",
      category: "Fruits",
      location: "Monaragala",
      unit: "kg",
      priceMinor: 18000,
      quantityAvailable: 70,
      description: "Cooking Ambul bananas popular in village kitchens.",
      isOrganic: false,
    },
  ];

  const batch = db.batch();
  const productIds: string[] = [];
  for (const spec of productSpecs) {
    const ref = db.collection("products").doc();
    productIds.push(ref.id);
    batch.set(ref, {
      farmerId,
      farmerName,
      name: spec.name,
      category: spec.category,
      description: spec.description,
      unit: spec.unit,
      location: spec.location,
      priceMinor: spec.priceMinor,
      price: `LKR ${(spec.priceMinor / 100).toFixed(2)} / ${spec.unit}`,
      pricePerUnit: spec.priceMinor / 100,
      currency: "LKR",
      quantityAvailable: spec.quantityAvailable,
      quantity: `${spec.quantityAvailable} ${spec.unit} available`,
      status: "Active",
      isOrganic: spec.isOrganic,
      media: [],
      imageUrls: [],
      harvestStatus: "harvested",
      listingVersion: 1,
      isSeedData: true,
      createdAt: now,
      updatedAt: now,
    });
  }

  // Orders covering the acceptance status chain (LKR, SL addresses).
  const orderSpecs: Array<Record<string, unknown>> = [
    {
      productIdx: 0,
      qty: 20,
      status: "pending",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      deliveryAddress: `No. 12, Galle Road, ${buyerDistrict === "Colombo" ? "Colombo 03" : buyerDistrict}`,
      pickupAddress: "Nuwara Eliya",
    },
    {
      productIdx: 3,
      qty: 5,
      status: "confirmed",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      deliveryAddress: "45 Peradeniya Road, Kandy",
      pickupAddress: "Kandy",
    },
    {
      productIdx: 4,
      qty: 50,
      status: "inTransit",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      deliveryAddress: "88 Baseline Road, Colombo 09",
      pickupAddress: "Kurunegala",
      transporterId: transporterId || null,
    },
    {
      productIdx: 6,
      qty: 25,
      status: "delivered",
      paymentStatus: "paid",
      escrowStatus: "held",
      deliveryAddress: "22 Marine Drive, Dehiwala",
      pickupAddress: "Polonnaruwa",
      transporterId: transporterId || null,
    },
  ];

  const orderRefs: Array<FirebaseFirestore.DocumentReference> = [];
  for (const spec of orderSpecs) {
    const idx = Number(spec.productIdx);
    const p = productSpecs[idx];
    const qty = Number(spec.qty);
    const subtotal = p.priceMinor * qty;
    const deliveryFeeMinor = 35000;
    const ref = db.collection("orders").doc();
    orderRefs.push(ref);
    batch.set(ref, {
      buyerId,
      farmerId,
      farmerName,
      buyerName,
      productId: productIds[idx],
      productName: p.name,
      title: `${qty} ${p.unit} ${p.name}`,
      quantity: `${qty} ${p.unit}`,
      unit: p.unit,
      items: [{ productId: productIds[idx], quantity: qty, pricePerUnitMinor: p.priceMinor }],
      subtotalMinor: subtotal,
      deliveryFeeMinor,
      totalMinor: subtotal + deliveryFeeMinor,
      currency: "LKR",
      deliveryAddress: spec.deliveryAddress,
      pickupAddress: spec.pickupAddress,
      location: p.location,
      status: spec.status,
      paymentStatus: spec.paymentStatus,
      escrowStatus: spec.escrowStatus,
      ...(spec.transporterId ? { transporterId: spec.transporterId } : {}),
      isSeedData: true,
      createdAt: now,
      updatedAt: now,
    });
  }

  // Transport jobs with districts for matching.
  const jobSpecs = [
    {
      orderRef: orderRefs[1],
      productIdx: 3,
      status: "requested",
      route: "Kandy → Peradeniya",
      pickup: "Kandy",
      dropoff: "Peradeniya",
      district: "Kandy",
      feeMinor: 220000,
      qty: "5 kg",
      transporterId: null as string | null,
    },
    {
      orderRef: orderRefs[2],
      productIdx: 4,
      status: "inTransit",
      route: "Kurunegala → Colombo",
      pickup: "Kurunegala",
      dropoff: "Colombo 09",
      district: "Kurunegala",
      feeMinor: 450000,
      qty: "50 pcs",
      transporterId: transporterId || null,
    },
    {
      orderRef: orderRefs[3],
      productIdx: 6,
      status: "delivered",
      route: "Polonnaruwa → Dehiwala",
      pickup: "Polonnaruwa",
      dropoff: "Dehiwala",
      district: "Polonnaruwa",
      feeMinor: 550000,
      qty: "25 kg",
      transporterId: transporterId || null,
    },
    {
      orderRef: orderRefs[0],
      productIdx: 0,
      status: "requested",
      route: `${farmerDistrict} → ${buyerDistrict}`,
      pickup: String(orderSpecs[0].pickupAddress),
      dropoff: buyerDistrict,
      district: "Nuwara Eliya",
      feeMinor: 350000,
      qty: "20 kg",
      transporterId: null as string | null,
    },
  ];

  for (const j of jobSpecs) {
    const p = productSpecs[j.productIdx];
    const ref = db.collection("transport_jobs").doc();
    batch.set(ref, {
      orderId: j.orderRef.id,
      farmerId,
      buyerId,
      ...(j.transporterId ? { transporterId: j.transporterId } : {}),
      title: `Delivery: ${p.name}`,
      route: j.route,
      detail: `${j.qty} · ${p.name}`,
      fee: `LKR ${(j.feeMinor / 100).toLocaleString("en-LK")}`,
      offeredFeeMinor: j.feeMinor,
      pickupAddress: j.pickup,
      dropoffAddress: j.dropoff,
      pickup: j.pickup,
      dropoff: j.dropoff,
      productName: p.name,
      quantity: j.qty,
      district: j.district,
      capacityKg: 500,
      weightKg: parseInt(j.qty, 10) || 20,
      status: j.status,
      accepted: j.status !== "requested",
      isSeedData: true,
      createdAt: now,
      updatedAt: now,
    });
  }

  // Platform settings defaults (LKR delivery fee suggestion).
  batch.set(db.collection("settings").doc("platform"), {
    currency: "LKR",
    defaultDeliveryFeeMinor: 35000,
    platformFeeBps: 250,
    sessionTimeoutMinutes: 60,
    country: "Sri Lanka",
    updatedAt: now,
  }, { merge: true });

  await batch.commit();
  return {
    success: true,
    farmerId,
    buyerId,
    transporterId: transporterId || null,
    products: productIds.length,
    orders: orderRefs.length,
    jobs: jobSpecs.length,
    message: "Seeded Sri Lankan marketplace data onto registered role accounts.",
  };
});

export const setUserSuspended = functions.https.onCall(async (data, context) => {
  await requireAdmin(context);
  const userId = typeof data.userId === "string" ? data.userId.trim() : "";
  const suspended = data.suspended === true;
  if (!userId) {
    throw new functions.https.HttpsError("invalid-argument", "userId is required.");
  }
  const ref = db.collection("users").doc(userId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }
  await ref.update({
    isSuspended: suspended,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  await db.collection("audit_logs").add({
    action: suspended ? "user_suspended" : "user_unsuspended",
    targetUserId: userId,
    actorId: context.auth!.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { success: true, userId, isSuspended: suspended };
});

export const deleteAccount = functions.runWith({ timeoutSeconds: 540, memory: "1GB" }).https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  const userRef = db.collection("users").doc(uid);

  // Anonymize user document (retain role audit shell)
  await userRef.set({
    displayName: "Deleted User",
    phone: "",
    photoUrl: admin.firestore.FieldValue.delete(),
    email: admin.firestore.FieldValue.delete(),
    address: admin.firestore.FieldValue.delete(),
    district: admin.firestore.FieldValue.delete(),
    country: admin.firestore.FieldValue.delete(),
    location: admin.firestore.FieldValue.delete(),
    latitude: admin.firestore.FieldValue.delete(),
    longitude: admin.firestore.FieldValue.delete(),
    locationSharingEnabled: false,
    vehicleRegistration: admin.firestore.FieldValue.delete(),
    chatPublicKey: admin.firestore.FieldValue.delete(),
    deviceTokens: admin.firestore.FieldValue.delete(),
    notificationPreferences: admin.firestore.FieldValue.delete(),
    isSuspended: true,
    isDeleted: true,
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const processOwnedRecords = async (
    collectionName: string,
    field: string,
    action: (batch: FirebaseFirestore.WriteBatch, doc: FirebaseFirestore.QueryDocumentSnapshot) => void,
    arrayContains = false
  ): Promise<void> => {
    let cursor: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    while (true) {
      let query: FirebaseFirestore.Query = db.collection(collectionName);
      query = arrayContains
        ? query.where(field, "array-contains", uid)
        : query.where(field, "==", uid);
      query = query.limit(400);
      if (cursor) query = query.startAfter(cursor);
      const page = await query.get();
      if (page.empty) return;
      const batch = db.batch();
      for (const doc of page.docs) action(batch, doc);
      await batch.commit();
      cursor = page.docs[page.docs.length - 1];
    }
  };

  const tokenDocs = await userRef.collection("device_tokens").get();
  for (let offset = 0; offset < tokenDocs.docs.length; offset += 400) {
    const batch = db.batch();
    for (const doc of tokenDocs.docs.slice(offset, offset + 400)) batch.delete(doc.ref);
    await batch.commit();
  }

  // Keep financial order records, but remove direct contact details.
  await processOwnedRecords("orders", "buyerId", (batch, doc) => batch.update(doc.ref, {
    buyerId: "deleted-user",
    buyerName: "Deleted User",
    buyerCompany: "",
    buyerAvatar: admin.firestore.FieldValue.delete(),
    buyerPhone: admin.firestore.FieldValue.delete(),
    deliveryAddress: "[redacted]",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  await processOwnedRecords("orders", "farmerId", (batch, doc) => batch.update(doc.ref, {
    farmerId: "deleted-user",
    farmerName: "Deleted User",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  await processOwnedRecords("orders", "transporterId", (batch, doc) => batch.update(doc.ref, {
    transporterId: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));

  const productIds: string[] = [];
  await processOwnedRecords("products", "farmerId", (batch, doc) => {
    productIds.push(doc.id);
    batch.update(doc.ref, {
    status: "Deleted",
    farmerId: "deleted-user",
    name: "[deleted]",
    description: "",
    location: "",
    imagePath: admin.firestore.FieldValue.delete(),
    media: [],
    imageUrls: [],
    images: [],
    videoPath: admin.firestore.FieldValue.delete(),
    videoUrl: admin.firestore.FieldValue.delete(),
    qrCode: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  // Remove personal content and account-scoped records. Keep financial and
  // dispute records only where needed for audit, with identifying text scrubbed.
  for (const field of ["ownerId", "farmerId"]) {
    await processOwnedRecords("verification_docs", field, (batch, doc) => batch.delete(doc.ref));
  }
  for (const field of ["buyerId", "farmerId"]) {
    await processOwnedRecords("offers", field, (batch, doc) => batch.delete(doc.ref));
  }
  for (const field of ["senderId", "recipientId", "receiverId"]) {
    await processOwnedRecords("messages", field, (batch, doc) => batch.delete(doc.ref));
  }
  await processOwnedRecords("notifications", "userId", (batch, doc) => batch.delete(doc.ref));
  await processOwnedRecords("reviews", "reviewerId", (batch, doc) => batch.delete(doc.ref));
  await processOwnedRecords("reviews", "subjectId", (batch, doc) => batch.update(doc.ref, {
    subjectId: "deleted-user",
    subjectName: "Deleted User",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  await processOwnedRecords("disputes", "openedBy", (batch, doc) => batch.update(doc.ref, {
    openedBy: "deleted-user",
    reason: "[redacted]",
    evidenceImages: [],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  await processOwnedRecords("conversations", "participantIds", (batch, doc) => batch.update(doc.ref, {
    participantIds: admin.firestore.FieldValue.arrayRemove(uid),
    unreadCounts: admin.firestore.FieldValue.delete(),
    lastMessage: "",
    lastMessageAt: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }), true);
  await processOwnedRecords("transport_jobs", "transporterId", (batch, doc) => batch.update(doc.ref, {
    transporterId: admin.firestore.FieldValue.delete(),
    courierLat: admin.firestore.FieldValue.delete(),
    courierLng: admin.firestore.FieldValue.delete(),
    locationUpdatedAt: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));
  for (const field of ["createdBy", "farmerId", "buyerId"]) {
    await processOwnedRecords("transport_jobs", field, (batch, doc) => batch.update(doc.ref, {
      farmerId: admin.firestore.FieldValue.delete(),
      buyerId: admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }));
  }
  await processOwnedRecords("settlements", "recipientId", (batch, doc) => batch.update(doc.ref, {
    bankName: admin.firestore.FieldValue.delete(),
    accountNumber: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }));

  await Promise.all([
    db.collection("public_profiles").doc(uid).delete().catch(() => undefined),
    db.collection("chat_public_keys").doc(uid).delete().catch(() => undefined),
  ]);

  // Remove account-owned uploads, including profile, listing and KYC media.
  const bucket = admin.storage().bucket();
  for (const prefix of [
    `users/${uid}/`,
    `product_images/${uid}/`,
    `product_videos/${uid}/`,
    `verification/${uid}/`,
    `disputes/${uid}/`,
  ]) {
    const [files] = await bucket.getFiles({ prefix });
    for (let offset = 0; offset < files.length; offset += 100) {
      await Promise.all(files.slice(offset, offset + 100)
        .map((file) => file.delete({ ignoreNotFound: true })));
    }
  }
  for (const productId of productIds) {
    const [files] = await bucket.getFiles({ prefix: `products/${productId}/` });
    for (let offset = 0; offset < files.length; offset += 100) {
      await Promise.all(files.slice(offset, offset + 100)
        .map((file) => file.delete({ ignoreNotFound: true })));
    }
  }

  await auth.deleteUser(uid);
  return { success: true };
});

export const exportUserData = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);

  const [
    userSnap,
    buyerOrders,
    farmerOrders,
    transporterOrders,
    products,
    verificationDocs,
    buyerOffers,
    farmerOffers,
    openedDisputes,
    sentMessages,
    receivedMessages,
    legacyReceivedMessages,
    notifications,
    authoredReviews,
    receivedReviews,
    conversations,
    transporterJobs,
    createdJobs,
    settlements,
  ] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("orders").where("buyerId", "==", uid).limit(200).get(),
      db.collection("orders").where("farmerId", "==", uid).limit(200).get(),
      db.collection("orders").where("transporterId", "==", uid).limit(200).get(),
      db.collection("products").where("farmerId", "==", uid).limit(200).get(),
      db.collection("verification_docs").where("ownerId", "==", uid).limit(100).get(),
      db.collection("offers").where("buyerId", "==", uid).limit(200).get(),
      db.collection("offers").where("farmerId", "==", uid).limit(200).get(),
      db.collection("disputes").where("openedBy", "==", uid).limit(100).get(),
      db.collection("messages").where("senderId", "==", uid).limit(500).get(),
      db.collection("messages").where("recipientId", "==", uid).limit(500).get(),
      db.collection("messages").where("receiverId", "==", uid).limit(500).get(),
      db.collection("notifications").where("userId", "==", uid).limit(500).get(),
      db.collection("reviews").where("reviewerId", "==", uid).limit(200).get(),
      db.collection("reviews").where("subjectId", "==", uid).limit(200).get(),
      db.collection("conversations").where("participantIds", "array-contains", uid)
        .limit(200).get(),
      db.collection("transport_jobs").where("transporterId", "==", uid).limit(200).get(),
      db.collection("transport_jobs").where("createdBy", "==", uid).limit(200).get(),
      db.collection("settlements").where("recipientId", "==", uid).limit(200).get(),
    ]);

  // Also collect verification docs keyed by farmerId for older records
  const verificationByFarmer = await db.collection("verification_docs")
    .where("farmerId", "==", uid).limit(100).get();

  const orderMap = new Map<string, Record<string, unknown>>();
  for (const snap of [buyerOrders, farmerOrders, transporterOrders]) {
    for (const doc of snap.docs) {
      orderMap.set(doc.id, { id: doc.id, ...doc.data() });
    }
  }

  const verificationMap = new Map<string, Record<string, unknown>>();
  for (const snap of [verificationDocs, verificationByFarmer]) {
    for (const doc of snap.docs) {
      verificationMap.set(doc.id, { id: doc.id, ...doc.data() });
    }
  }

  const asRecords = (snapshots: FirebaseFirestore.QuerySnapshot[]) => {
    const records = new Map<string, Record<string, unknown>>();
    for (const snapshot of snapshots) {
      for (const doc of snapshot.docs) {
        records.set(doc.id, { id: doc.id, ...doc.data() });
      }
    }
    return Array.from(records.values());
  };

  const serialize = (value: unknown): unknown => {
    if (value === null || value === undefined) return value;
    if (value instanceof admin.firestore.Timestamp) return value.toDate().toISOString();
    if (Array.isArray(value)) return value.map(serialize);
    if (typeof value === "object") {
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        out[k] = serialize(v);
      }
      return out;
    }
    return value;
  };

  return serialize({
    exportedAt: new Date().toISOString(),
    userId: uid,
    profile: userSnap.exists ? { id: userSnap.id, ...userSnap.data() } : null,
    orders: Array.from(orderMap.values()),
    products: products.docs.map((d) => ({ id: d.id, ...d.data() })),
    verificationDocs: Array.from(verificationMap.values()),
    offers: asRecords([buyerOffers, farmerOffers]),
    disputes: asRecords([openedDisputes]),
    messages: asRecords([sentMessages, receivedMessages, legacyReceivedMessages]),
    notifications: asRecords([notifications]),
    authoredReviews: asRecords([authoredReviews]),
    reviewsAboutUser: asRecords([receivedReviews]),
    conversations: asRecords([conversations]),
    transportJobs: asRecords([transporterJobs, createdJobs]),
    settlements: asRecords([settlements]),
  });
});
