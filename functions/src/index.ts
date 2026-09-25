import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
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

const requireAdmin = async (
  context: functions.https.CallableContext
): Promise<string> => {
  const uid = requireAuth(context);
  const profile = (await db.collection("users").doc(uid).get()).data();
  if (
    (context.auth?.token.admin !== true &&
      (profile?.role !== "admin" || profile?.isVerified !== true))
    || profile?.isSuspended === true
    || profile?.isDeleted === true
  ) {
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
  if (!user || !roles.includes(String(user.role)) || user.isSuspended === true
    || user.isDeleted === true) {
    throw new functions.https.HttpsError("permission-denied", "Account is not eligible.");
  }
  return user;
};

const requireVerifiedRole = async (
  uid: string,
  roles: string[]
): Promise<Record<string, unknown>> => {
  const user = await requireRole(uid, roles);
  if (user.isVerified !== true) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Account verification is required for this action."
    );
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
    createdAt: FieldValue.serverTimestamp(),
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
    transporterId: order.requestedTransporterId || null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
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
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
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
    updatedAt: FieldValue.serverTimestamp(),
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
    updatedAt: FieldValue.serverTimestamp(),
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
        calculatedSubtotal += Number.isSafeInteger(item.lineTotalMinor)
          ? item.lineTotalMinor
          : item.pricePerUnitMinor * item.quantity;
      }
    }

    const deliveryFee = data.deliveryFeeMinor || 0;
    const calculatedTotal = calculatedSubtotal + deliveryFee;

    // Update with server-calculated values (do not clobber paymentStatus)
    await order.update({
      subtotalMinor: calculatedSubtotal,
      totalMinor: calculatedTotal,
      updatedAt: FieldValue.serverTimestamp(),
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
      timestamp: FieldValue.serverTimestamp(),
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
          updatedAt: FieldValue.serverTimestamp(),
          ...(orderStatus === "delivered"
            ? { deliveredAt: FieldValue.serverTimestamp() }
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
            courierLat: FieldValue.delete(),
            courierLng: FieldValue.delete(),
            locationUpdatedAt: FieldValue.delete(),
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
    videoPath: FieldValue.delete(),
    videoUrl: FieldValue.delete(),
    harvestStatus: "delivered",
    updatedAt: FieldValue.serverTimestamp(),
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
  const transporterId = typeof data.transporterId === "string"
    ? data.transporterId : "";
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  if (!productId || !Number.isSafeInteger(quantity) || quantity < 1
    || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid order details.");
  }
  if (!deliveryAddress || deliveryAddress.length < 5) {
    throw new functions.https.HttpsError("invalid-argument", "Delivery address is required.");
  }
  if (transporterId) {
    const transporterSnap = await db.collection("users").doc(transporterId).get();
    const transporter = transporterSnap.data();
    if (!transporter || transporter.role !== "transporter"
      || transporter.isSuspended === true) {
      throw new functions.https.HttpsError(
        "failed-precondition", "Selected transporter is unavailable.");
    }
  }

  const productRef = db.collection("products").doc(productId);
  const orderRef = db.collection("orders").doc();
  const offerRef = offerId ? db.collection("offers").doc(offerId) : null;
  const buyerSnap = await db.collection("users").doc(uid).get();
  const buyer = buyerSnap.data() || {};

  await db.runTransaction(async (transaction) => {
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const available = Number(product?.quantityAvailable);
    let priceMinor = Number(product?.priceMinor);
    let orderQuantity = quantity;
    let finalSubtotal = 0;

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
        updatedAt: FieldValue.serverTimestamp(),
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
      quantity: `${available - orderQuantity} ${unit} available`,
      status: available - orderQuantity > 0 ? "Active" : "Empty",
      updatedAt: FieldValue.serverTimestamp(),
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
      items: [{ productId, quantity: orderQuantity, pricePerUnitMinor: priceMinor, lineTotalMinor: finalSubtotal }],
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
      ...(transporterId ? { requestedTransporterId: transporterId } : {}),
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      ...(offerId ? { offerId } : {}),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
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
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection("notifications").add({
    userId: farmerId,
    title: "New Price Offer",
    body: `You received an offer of LKR ${proposedPrice.toFixed(0)} for ${proposedQuantity} units.`,
    type: "offer",
    referenceId: offerRef.id,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { offerId: offerRef.id };
});

// Farmer counters a buyer's pending offer. All price changes and notifications
// are server-owned so both parties see the same negotiated amount.
export const counterOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const counterPrice = Number(data.counterPrice);
  if (!offerId || !Number.isFinite(counterPrice) || counterPrice <= 0) {
    throw new functions.https.HttpsError("invalid-argument", "Valid offer and counter price are required.");
  }
  const ref = db.collection("offers").doc(offerId);
  const snapshot = await ref.get();
  const offer = snapshot.data();
  if (!offer || offer.farmerId !== uid || offer.status !== "pending") {
    throw new functions.https.HttpsError("failed-precondition", "Offer cannot be countered.");
  }
  const counterPriceMinor = Math.round(counterPrice * 100);
  await ref.update({
    status: "countered",
    proposedPrice: counterPriceMinor / 100,
    proposedPriceMinor: counterPriceMinor,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeNotification(
    String(offer.buyerId),
    "Farmer sent a counter-offer",
    `The farmer countered at LKR ${(counterPriceMinor / 100).toFixed(2)} per unit.`,
    "offer",
    offerId
  );
  return { success: true };
});

// The farmer accepts the buyer's offer, or the buyer accepts the farmer's
// counter. The same transaction creates one order and reserves the stock.
export const acceptOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const actor = await requireRole(uid, ["farmer", "buyer"]);
  const actorRole = String(actor.role);
  if (actorRole === "farmer") await requireVerifiedRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  if (!offerId || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid offer accept request.");
  }

  const offerRef = db.collection("offers").doc(offerId);
  const orderRef = db.collection("orders").doc();

  await db.runTransaction(async (transaction) => {
    const offerSnapshot = await transaction.get(offerRef);
    const offer = offerSnapshot.data();
    const isFarmerAccepting = actorRole === "farmer"
      && offer?.farmerId === uid && offer?.status === "pending";
    const isBuyerAcceptingCounter = actorRole === "buyer"
      && offer?.buyerId === uid && offer?.status === "countered";
    if (!offer || (!isFarmerAccepting && !isBuyerAcceptingCounter)) {
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
    if (!product || product.farmerId !== offer.farmerId || product.status !== "Active"
      || !Number.isSafeInteger(available) || available < orderQuantity) {
      throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
    }
    const priceMinor = Math.round(finalSubtotal / orderQuantity);
    const unit = String(product.unit || "unit");
    const productName = String(product.name || offer.productName || "Produce");
    const quantityLabel = `${orderQuantity} ${unit}`;
    transaction.update(productRef, {
      quantityAvailable: available - orderQuantity,
      quantity: `${available - orderQuantity} ${unit} available`,
      status: available - orderQuantity > 0 ? "Active" : "Empty",
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(offerRef, {
      status: "accepted",
      orderId: orderRef.id,
      updatedAt: FieldValue.serverTimestamp(),
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
      items: [{ productId, quantity: orderQuantity, pricePerUnitMinor: priceMinor, lineTotalMinor: finalSubtotal }],
      subtotalMinor: finalSubtotal,
      deliveryFeeMinor,
      totalMinor: finalSubtotal + deliveryFeeMinor,
      currency: "LKR",
      deliveryAddress: deliveryAddress || String(offer.deliveryAddress || "To be confirmed with buyer"),
      pickupAddress: String(product.location || "Farm pickup"),
      location: String(product.location || ""),
      status: "pending",
      paymentStatus: "payment_required",
      escrowStatus: "not_funded",
      offerId,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  const accepted = (await offerRef.get()).data();
  const notifyId = actorRole === "farmer" ? accepted?.buyerId : accepted?.farmerId;
  if (notifyId) {
    await writeNotification(
      String(notifyId),
      actorRole === "farmer" ? "Offer Accepted" : "Counter-offer Accepted",
      actorRole === "farmer"
        ? "Your offer was accepted and an order was created."
        : "The buyer accepted your counter-offer and an order was created.",
      "offer",
      offerId
    );
  }
  return { orderId: orderRef.id };
});

export const rejectOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const actor = await requireRole(uid, ["farmer", "buyer"]);
  const actorRole = String(actor.role);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  if (!offerId) {
    throw new functions.https.HttpsError("invalid-argument", "offerId is required.");
  }
  const offerRef = db.collection("offers").doc(offerId);
  const snapshot = await offerRef.get();
  const offer = snapshot.data();
  const canFarmerReject = actorRole === "farmer" && offer?.farmerId === uid
    && ["pending", "countered"].includes(String(offer?.status));
  const canBuyerWithdraw = actorRole === "buyer" && offer?.buyerId === uid
    && ["pending", "countered"].includes(String(offer?.status));
  if (!offer || (!canFarmerReject && !canBuyerWithdraw)) {
    throw new functions.https.HttpsError("failed-precondition", "Offer cannot be rejected.");
  }
  await offerRef.update({
    status: actorRole === "buyer" ? "cancelled" : "rejected",
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeNotification(
    String(actorRole === "buyer" ? offer.farmerId : offer.buyerId),
    actorRole === "buyer" ? "Offer Withdrawn" : "Offer Rejected",
    actorRole === "buyer" ? "The buyer withdrew their offer." : "Your offer was rejected by the farmer.",
    "offer",
    offerId
  );
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
    media: Array.isArray(data.media) ? data.media.slice(0, 5) : [],
    harvestStatus: "growing",
    listingVersion: 1,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { productId: productRef.id };
});

export const updateProduct = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const user = await requireRole(uid, ["farmer"]);
  if (user.isVerified !== true) throw new functions.https.HttpsError("failed-precondition", "Account verification is required.");
  const productId = typeof data.productId === "string" ? data.productId : "";
  const ref = db.collection("products").doc(productId);
  const snapshot = await ref.get();
  const existing = snapshot.data();
  if (!existing || existing.farmerId !== uid) throw new functions.https.HttpsError("permission-denied", "Product not found.");
  const name = typeof data.name === "string" ? data.name.trim() : String(existing.name || "");
  const category = typeof data.category === "string" ? data.category.trim() : String(existing.category || "");
  const unit = typeof data.unit === "string" ? data.unit.trim() : String(existing.unit || "unit");
  const location = typeof data.location === "string" ? data.location.trim() : String(existing.location || "");
  const priceMinor = data.priceMinor == null ? Number(existing.priceMinor) : Number(data.priceMinor);
  const quantityAvailable = data.quantityAvailable == null ? Number(existing.quantityAvailable) : Number(data.quantityAvailable);
  const requestedStatus = data.status === "Empty" ? "Empty" : "Active";
  if (!productId || !name || name.length > 120 || !category || !unit || !location
    || !Number.isSafeInteger(priceMinor) || priceMinor < 0
    || !Number.isSafeInteger(quantityAvailable) || quantityAvailable < 0) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid product details.");
  }
  const media = Array.isArray(data.media) ? data.media.slice(0, 5) : (existing.media || []);
  await ref.update({ name, category, description: typeof data.description === "string" ? data.description.trim().slice(0, 4000) : String(existing.description || ""), unit, location, priceMinor, price: `LKR ${(priceMinor / 100).toFixed(2)} / ${unit}`, pricePerUnit: priceMinor / 100, quantityAvailable, quantity: `${quantityAvailable} ${unit} available`, status: quantityAvailable > 0 ? requestedStatus : "Empty", isOrganic: data.isOrganic == null ? existing.isOrganic === true : data.isOrganic === true, media, updatedAt: FieldValue.serverTimestamp(), listingVersion: Number(existing.listingVersion || 1) + 1 });
  return { success: true };
});

export const deleteProduct = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const user = await requireRole(uid, ["farmer"]);
  if (user.isVerified !== true) throw new functions.https.HttpsError("failed-precondition", "Account verification is required.");
  const productId = typeof data.productId === "string" ? data.productId : "";
  const ref = db.collection("products").doc(productId);
  const snapshot = await ref.get();
  if (!snapshot.exists || snapshot.data()?.farmerId !== uid) throw new functions.https.HttpsError("permission-denied", "Product not found.");
  const activeOrders = await db.collection("orders").where("productId", "==", productId).where("status", "in", ["pending", "confirmed", "assigned", "pickedUp", "inTransit"]).limit(1).get();
  if (!activeOrders.empty) throw new functions.https.HttpsError("failed-precondition", "Product has active orders and cannot be removed.");
  await ref.delete();
  return { success: true };
});

// ── Farmer farm management ────────────────────────────────────
const cropStatuses = ["planned", "planted", "growing", "harvested", "cancelled"];
const taskStatuses = ["pending", "inProgress", "completed", "cancelled"];

export const createCropPlan = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const cropName = typeof data.cropName === "string" ? data.cropName.trim().slice(0, 100) : "";
  const area = Number(data.area);
  const areaUnit = typeof data.areaUnit === "string" ? data.areaUnit : "acres";
  const plantedAt = new Date(String(data.plantedAt || ""));
  const expectedHarvestAt = new Date(String(data.expectedHarvestAt || ""));
  if (!cropName || !Number.isFinite(area) || area <= 0 || area > 100000
    || !["acres", "hectares", "perches"].includes(areaUnit)
    || Number.isNaN(plantedAt.getTime()) || Number.isNaN(expectedHarvestAt.getTime())
    || expectedHarvestAt <= plantedAt) {
    throw new functions.https.HttpsError("invalid-argument", "Enter a crop, valid farm area, planting date, and later harvest date.");
  }
  const ref = db.collection("crop_plans").doc();
  await ref.set({
    farmerId: uid, cropName, area, areaUnit,
    plantedAt: Timestamp.fromDate(plantedAt),
    expectedHarvestAt: Timestamp.fromDate(expectedHarvestAt),
    expectedYield: Math.max(0, Number(data.expectedYield || 0)),
    yieldUnit: String(data.yieldUnit || "kg").slice(0, 20),
    status: "planned", notes: String(data.notes || "").trim().slice(0, 1000),
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { cropId: ref.id };
});

export const updateCropPlan = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const cropId = String(data.cropId || "");
  const ref = db.collection("crop_plans").doc(cropId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.farmerId !== uid) throw new functions.https.HttpsError("permission-denied", "Crop plan not found.");
  const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (typeof data.status === "string") {
    if (!cropStatuses.includes(data.status)) throw new functions.https.HttpsError("invalid-argument", "Invalid crop status.");
    updates.status = data.status;
    if (data.status === "harvested") updates.harvestedAt = FieldValue.serverTimestamp();
  }
  if (typeof data.notes === "string") updates.notes = data.notes.trim().slice(0, 1000);
  if (typeof data.expectedYield === "number" && Number.isFinite(data.expectedYield) && data.expectedYield >= 0) updates.expectedYield = data.expectedYield;
  await ref.update(updates);
  return { success: true };
});

export const createFarmTask = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const title = typeof data.title === "string" ? data.title.trim().slice(0, 120) : "";
  const dueAt = new Date(String(data.dueAt || ""));
  if (!title || Number.isNaN(dueAt.getTime())) throw new functions.https.HttpsError("invalid-argument", "Task title and due date are required.");
  const ref = db.collection("farm_tasks").doc();
  await ref.set({
    farmerId: uid, title, description: String(data.description || "").trim().slice(0, 1000),
    cropId: String(data.cropId || ""), cropName: String(data.cropName || "").slice(0, 100),
    dueAt: Timestamp.fromDate(dueAt), priority: ["low", "normal", "high"].includes(data.priority) ? data.priority : "normal",
    status: "pending", createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { taskId: ref.id };
});

export const updateFarmTask = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const taskId = String(data.taskId || "");
  const ref = db.collection("farm_tasks").doc(taskId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.farmerId !== uid) throw new functions.https.HttpsError("permission-denied", "Farm task not found.");
  const updates: Record<string, unknown> = { updatedAt: FieldValue.serverTimestamp() };
  if (typeof data.status === "string") {
    if (!taskStatuses.includes(data.status)) throw new functions.https.HttpsError("invalid-argument", "Invalid task status.");
    updates.status = data.status;
    if (data.status === "completed") updates.completedAt = FieldValue.serverTimestamp();
  }
  if (typeof data.title === "string" && data.title.trim()) updates.title = data.title.trim().slice(0, 120);
  if (typeof data.dueAt === "string") {
    const dueAt = new Date(data.dueAt);
    if (Number.isNaN(dueAt.getTime())) throw new functions.https.HttpsError("invalid-argument", "Invalid due date.");
    updates.dueAt = Timestamp.fromDate(dueAt);
    updates.reminderDate = FieldValue.delete();
  }
  await ref.update(updates);
  return { success: true };
});

export const checkFarmTaskReminders = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const today = new Date().toISOString().slice(0, 10);
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const tasks = await db.collection("farm_tasks").where("farmerId", "==", uid)
    .where("status", "in", ["pending", "inProgress"]).limit(100).get();
  let reminders = 0;
  for (const taskDoc of tasks.docs) {
    const task = taskDoc.data();
    const dueAt = task.dueAt instanceof Timestamp ? task.dueAt.toDate() : null;
    if (!dueAt || dueAt > tomorrow || task.reminderDate === today) continue;
    await db.runTransaction(async (tx) => {
      const current = await tx.get(taskDoc.ref);
      if (current.data()?.reminderDate === today || !["pending", "inProgress"].includes(String(current.data()?.status))) return;
      tx.update(taskDoc.ref, { reminderDate: today });
      const notificationRef = db.collection("notifications").doc();
      tx.create(notificationRef, {
        userId: uid, title: dueAt < new Date() ? "Farm task overdue" : "Farm task due soon",
        body: `${task.title} is due ${dueAt < new Date() ? "now" : "within 24 hours"}.`,
        type: "farm_task", referenceId: taskDoc.id, read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    reminders++;
  }
  return { reminders };
});

export const createProduceRequest = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const buyer = await requireRole(uid, ["buyer"]);
  const produceName = typeof data.produceName === "string" ? data.produceName.trim().slice(0, 100) : "";
  const quantity = Number(data.quantity);
  const unit = typeof data.unit === "string" ? data.unit.trim().toLowerCase() : "";
  const units = ["kg", "g", "ton", "piece", "pcs", "box", "crate", "bunch", "bag", "liter"];
  const deliveryAddress = typeof data.deliveryAddress === "string" ? data.deliveryAddress.trim().slice(0, 500) : "";
  const deliveryDate = new Date(String(data.deliveryDate || ""));
  if (!produceName || !Number.isSafeInteger(quantity) || quantity < 1 || !units.includes(unit)
    || deliveryAddress.length < 5 || Number.isNaN(deliveryDate.getTime())) {
    throw new functions.https.HttpsError("invalid-argument", "Produce, whole quantity/unit, delivery address, and required date are needed.");
  }
  const ref = db.collection("produce_requests").doc();
  await ref.set({
    buyerId: uid, buyerName: String(buyer.displayName || buyer.name || "Buyer"),
    produceName, category: String(data.category || "Other").slice(0, 50), quantity, unit,
    maxUnitPriceMinor: Math.max(0, Number(data.maxUnitPriceMinor || 0)),
    district: String(data.district || "").trim().slice(0, 80),
    deliveryAddress, deliveryDate: Timestamp.fromDate(deliveryDate),
    notes: String(data.notes || "").trim().slice(0, 1000), status: "open", quoteCount: 0,
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { requestId: ref.id };
});

export const cancelProduceRequest = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const requestId = String(data.requestId || "");
  const ref = db.collection("produce_requests").doc(requestId);
  const snap = await ref.get();
  if (!snap.exists || snap.data()?.buyerId !== uid || snap.data()?.status !== "open") {
    throw new functions.https.HttpsError("failed-precondition", "Only your open requests can be cancelled.");
  }
  await ref.update({ status: "cancelled", updatedAt: FieldValue.serverTimestamp() });
  return { success: true };
});

export const submitProduceRequestQuote = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const requestId = String(data.requestId || ""), productId = String(data.productId || "");
  const unitPriceMinor = Number(data.unitPriceMinor), deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  if (!requestId || !productId || !Number.isSafeInteger(unitPriceMinor) || unitPriceMinor < 1
    || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0) throw new functions.https.HttpsError("invalid-argument", "Invalid quote.");
  const requestRef = db.collection("produce_requests").doc(requestId);
  const productRef = db.collection("products").doc(productId);
  const [requestSnap, productSnap, farmerSnap] = await Promise.all([
    requestRef.get(), productRef.get(), db.collection("users").doc(uid).get(),
  ]);
  const request = requestSnap.data(), product = productSnap.data(), farmer = farmerSnap.data();
  if (!request || request.status !== "open" || !product || product.farmerId !== uid
    || product.status !== "Active" || Number(product.quantityAvailable) < Number(request.quantity)
    || String(product.unit).toLowerCase() !== String(request.unit).toLowerCase()) {
    throw new functions.https.HttpsError("failed-precondition", "Your active listing must match the requested unit and have enough stock.");
  }
  const quoteRef = requestRef.collection("quotes").doc(uid);
  await db.runTransaction(async (tx) => {
    const latest = await tx.get(requestRef);
    if (latest.data()?.status !== "open") throw new functions.https.HttpsError("failed-precondition", "This request is no longer open.");
    tx.set(quoteRef, {
      farmerId: uid, farmerName: String(farmer?.displayName || farmer?.name || "Farmer"),
      productId, productName: String(product.name || request.produceName),
      unitPriceMinor, deliveryFeeMinor, message: String(data.message || "").trim().slice(0, 500),
      status: "pending", createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    });
    tx.update(requestRef, { quoteCount: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() });
  });
  await writeNotification(String(request.buyerId), "New produce quote", `${farmer?.displayName || "A farmer"} sent a quote for ${request.produceName}.`, "produce_request", requestId);
  return { success: true };
});

export const acceptProduceRequestQuote = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["buyer"]);
  const requestId = String(data.requestId || ""), farmerId = String(data.farmerId || "");
  const requestRef = db.collection("produce_requests").doc(requestId);
  const quoteRef = requestRef.collection("quotes").doc(farmerId);
  const orderRef = db.collection("orders").doc();
  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef), quoteSnap = await tx.get(quoteRef);
    const request = requestSnap.data(), quote = quoteSnap.data();
    if (!request || request.buyerId !== uid || request.status !== "open" || !quote || quote.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "Request or quote is no longer available.");
    const productRef = db.collection("products").doc(String(quote.productId));
    const productSnap = await tx.get(productRef), product = productSnap.data();
    const available = Number(product?.quantityAvailable), quantity = Number(request.quantity), price = Number(quote.unitPriceMinor);
    if (!product || product.farmerId !== farmerId || product.status !== "Active" || available < quantity
      || !Number.isSafeInteger(price) || price < 1) throw new functions.https.HttpsError("failed-precondition", "Farmer stock or quote is no longer valid.");
    const subtotal = quantity * price, fee = Number(quote.deliveryFeeMinor || 0), unit = String(product.unit || request.unit);
    tx.update(productRef, { quantityAvailable: available - quantity, quantity: `${available - quantity} ${unit} available`, status: available > quantity ? "Active" : "Empty", updatedAt: FieldValue.serverTimestamp() });
    tx.update(quoteRef, { status: "accepted", orderId: orderRef.id, updatedAt: FieldValue.serverTimestamp() });
    tx.update(requestRef, { status: "matched", acceptedFarmerId: farmerId, orderId: orderRef.id, updatedAt: FieldValue.serverTimestamp() });
    tx.create(orderRef, {
      buyerId: uid, farmerId, productId: quote.productId,
      productName: product.name || request.produceName, title: product.name || request.produceName,
      quantity: `${quantity} ${unit}`, unit, items: [{ productId: quote.productId, quantity, pricePerUnitMinor: price, lineTotalMinor: subtotal }],
      subtotalMinor: subtotal, deliveryFeeMinor: fee, totalMinor: subtotal + fee, currency: "LKR",
      buyerName: String(request.buyerName || "Buyer"), deliveryAddress: request.deliveryAddress,
      pickupAddress: String(product.location || "Farm pickup"), location: String(product.location || ""),
      status: "pending", paymentStatus: "payment_required", escrowStatus: "not_funded",
      sourceRequestId: requestId, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { orderId: orderRef.id };
});

export const submitMarketPriceReport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const user = await requireRole(uid, ["buyer", "farmer"]);
  const cropName = typeof data.cropName === "string" ? data.cropName.trim().slice(0, 100) : "";
  const district = typeof data.district === "string" ? data.district.trim().slice(0, 80) : "";
  const marketName = typeof data.marketName === "string" ? data.marketName.trim().slice(0, 100) : "";
  const unit = typeof data.unit === "string" ? data.unit.trim().toLowerCase() : "";
  const priceMinor = Number(data.priceMinor);
  if (!cropName || !district || !marketName || !["kg", "g", "ton", "piece", "pcs", "box", "crate", "bunch", "bag", "liter"].includes(unit)
    || !Number.isSafeInteger(priceMinor) || priceMinor < 1 || priceMinor > 100000000) throw new functions.https.HttpsError("invalid-argument", "Enter valid produce, market, location, unit, and price.");
  const ref = db.collection("market_price_reports").doc();
  await ref.set({ reporterId: uid, reporterRole: String(user.role), cropName, category: String(data.category || "Other").slice(0, 50), district, marketName, unit, priceMinor, status: "pending", reportedAt: FieldValue.serverTimestamp(), createdAt: FieldValue.serverTimestamp() });
  return { reportId: ref.id };
});

export const reviewMarketPriceReport = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const reportId = String(data.reportId || ""), decision = String(data.decision || "");
  if (!reportId || !["approve", "reject"].includes(decision)) throw new functions.https.HttpsError("invalid-argument", "Invalid price report review.");
  const reportRef = db.collection("market_price_reports").doc(reportId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(reportRef), report = snap.data();
    if (!report || report.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "Price report already reviewed.");
    let benchmark: Record<string, unknown> | null = null;
    if (decision === "approve") {
      const key = `${String(report.cropName).toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${String(report.district).toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${report.unit}`;
      const priceRef = db.collection("market_prices").doc(key);
      const existingSnap = await tx.get(priceRef);
      const existing = existingSnap.data();
      const oldCount = Number(existing?.reportCount || 0), oldAvg = Number(existing?.averagePricePerKg || 0), price = Number(report.priceMinor) / 100;
      const count = oldCount + 1, average = (oldAvg * oldCount + price) / count;
      benchmark = {
        cropName: report.cropName, category: report.category, district: report.district, marketName: report.marketName,
        unit: report.unit, minPricePerKg: existing ? Math.min(Number(existing.minPricePerKg), price) : price,
        maxPricePerKg: existing ? Math.max(Number(existing.maxPricePerKg), price) : price,
        averagePricePerKg: average, trend: existing ? (price > oldAvg ? "up" : price < oldAvg ? "down" : "stable") : "stable",
        reportCount: count, updatedAt: FieldValue.serverTimestamp(),
      };
      (benchmark as Record<string, unknown>).__ref = priceRef;
    }
    tx.update(reportRef, { status: decision === "approve" ? "approved" : "rejected", reviewedBy: uid, reviewedAt: FieldValue.serverTimestamp() });
    if (benchmark) {
      const priceRef = benchmark.__ref as FirebaseFirestore.DocumentReference;
      delete benchmark.__ref;
      tx.set(priceRef, benchmark, { merge: true });
    }
  });
  const report = (await reportRef.get()).data();
  if (report?.reporterId) await writeNotification(String(report.reporterId), `Market price report ${decision === "approve" ? "approved" : "reviewed"}`, decision === "approve" ? "Your market price report is now included in the benchmark." : "Your market price report was not approved.", "market_price", reportId);
  return { success: true };
});

export const transitionOrder = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const actor = await requireRole(uid, ["farmer", "buyer"]);
  if (actor.role === "farmer") await requireVerifiedRole(uid, ["farmer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const nextStatus = typeof data.status === "string" ? data.status : "";
  const orderRef = db.collection("orders").doc(orderId);
  const snapshot = await orderRef.get();
  const order = snapshot.data();
  if (!order || !orderId) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }
  const isFarmer = actor.role === "farmer" && order.farmerId === uid;
  const isBuyer = actor.role === "buyer" && order.buyerId === uid;
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
  await db.runTransaction(async (transaction) => {
    const currentSnapshot = await transaction.get(orderRef);
    const current = currentSnapshot.data();
    if (!current || current.status !== order.status) {
      throw new functions.https.HttpsError("aborted", "Order changed. Refresh and retry.");
    }
    if ((nextStatus === "rejected" || nextStatus === "cancelled")
      && current.stockRestored !== true) {
      const productId = String(current.productId || current.items?.[0]?.productId || "");
      const quantity = Number(current.items?.[0]?.quantity || 0);
      if (productId && Number.isSafeInteger(quantity) && quantity > 0) {
        const productRef = db.collection("products").doc(productId);
        const productSnapshot = await transaction.get(productRef);
        const product = productSnapshot.data();
        if (product) {
          const available = Number(product.quantityAvailable || 0) + quantity;
          const unit = String(product.unit || "unit");
          transaction.update(productRef, {
            quantityAvailable: available,
            quantity: `${available} ${unit} available`,
            status: available > 0 ? "Active" : "Empty",
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      }
    }
    transaction.update(orderRef, {
      status: nextStatus,
      ...(nextStatus === "rejected" || nextStatus === "cancelled"
        ? { stockRestored: true }
        : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  let jobId: string | undefined;
  if (nextStatus === "confirmed" && isFarmer) {
    jobId = await createTransportJobForOrder(orderId, order as Record<string, any>);
    const selectedTransporter = String(order.requestedTransporterId || "");
    if (selectedTransporter) {
      await writeNotification(
        selectedTransporter,
        "Delivery request",
        `A confirmed order for ${order.productName || "produce"} is ready for delivery.`,
        "logistics",
        orderId
      );
    }
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
  await requireVerifiedRole(uid, ["farmer"]);
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
    updatedAt: FieldValue.serverTimestamp(),
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
  const isBuyer = order.buyerId === uid;
  const isAdmin = context.auth?.token.admin === true;
  if (!isBuyer && !isAdmin) {
    throw new functions.https.HttpsError("permission-denied", "Not allowed.");
  }
  if (order.status !== "delivered" && !isAdmin) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Payment can be confirmed after delivery."
    );
  }
  await ref.update({
    paymentStatus: "paid",
    escrowStatus: "held",
    paymentMethod: method,
    paidAt: FieldValue.serverTimestamp(),
    paidBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (order.farmerId) {
    await writeNotification(
      String(order.farmerId),
      "Payment received",
      `COD/payment marked paid for ${order.productName || "an order"}.`,
      "order",
      orderId
    );
  }
  return { success: true };
});

export const transitionTransport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["transporter"]);
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
  if (requestedStatus === "accepted" && job.orderId) {
    const orderSnapshot = await db.collection("orders").doc(String(job.orderId)).get();
    const linkedOrder = orderSnapshot.data();
    if (!linkedOrder || linkedOrder.status !== "confirmed"
      || (linkedOrder.requestedTransporterId && linkedOrder.requestedTransporterId !== uid)) {
      throw new functions.https.HttpsError("failed-precondition", "Order is not ready for this transporter.");
    }
  }
  await db.runTransaction(async (transaction) => {
    const currentSnap = await transaction.get(ref);
    const currentJob = currentSnap.data();
    if (!currentJob || normalizeStatus(currentJob.status) !== currentStatus
      || (currentJob.transporterId && currentJob.transporterId !== uid)) {
      throw new functions.https.HttpsError("aborted", "Delivery was claimed or updated. Refresh and retry.");
    }
    if (requestedStatus === "accepted" && currentJob.orderId) {
      const orderRef = db.collection("orders").doc(String(currentJob.orderId));
      const orderSnap = await transaction.get(orderRef);
      const linkedOrder = orderSnap.data();
      if (!linkedOrder || linkedOrder.status !== "confirmed"
        || (linkedOrder.requestedTransporterId && linkedOrder.requestedTransporterId !== uid)) {
        throw new functions.https.HttpsError("failed-precondition", "Order is not ready for this transporter.");
      }
    }
    transaction.update(ref, {
      status: requestedStatus,
      transporterId: uid,
      updatedAt: FieldValue.serverTimestamp(),
      [`${requestedStatus}At`]: FieldValue.serverTimestamp(),
      ...(requestedStatus === "cancelled" && reason ? { cancellationReason: reason } : {}),
    });
  });
  if (requestedStatus === "accepted" && job.orderId && job.requestedTransporterId === uid) {
    // The order confirmation remains owned by the farmer. Acceptance only
    // assigns the already-confirmed order through the onTransportTransition trigger.
  }
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
    updatedAt: FieldValue.serverTimestamp(),
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
    locationUpdatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
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
    createdAt: FieldValue.serverTimestamp(),
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
  // Ensure the order-scoped conversation exists (created only by backend).
  const participants = [uid, recipientId].sort();
  const convoQuery = await db.collection("conversations")
    .where("orderId", "==", orderId).get();
  let conversationId = "";
  for (const doc of convoQuery.docs) {
    const ids = [...((doc.data().participantIds as string[]) || [])].sort();
    if (ids.length === participants.length && ids.every((v, i) => v === participants[i])) {
      conversationId = doc.id;
      break;
    }
  }
  if (!conversationId) {
    const convoRef = db.collection("conversations").doc();
    await convoRef.set({
      orderId,
      participantIds: participants,
      lastMessage: "",
      lastMessageAt: FieldValue.serverTimestamp(),
      unreadCounts: { [recipientId]: 0 },
      createdAt: FieldValue.serverTimestamp(),
    });
    conversationId = convoRef.id;
  }
  const ref = db.collection("messages").doc();
  await ref.set({
    orderId,
    conversationId,
    senderId: uid,
    receiverId: recipientId,
    recipientId,
    ciphertext,
    createdAt: FieldValue.serverTimestamp(),
  });
  await db.collection("conversations").doc(conversationId).update({
    lastMessage: ciphertext.slice(0, 140),
    lastMessageAt: FieldValue.serverTimestamp(),
  });
  await writeNotification(
    recipientId,
    "New message",
    "You have a new encrypted order message.",
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
    payhereCheckoutAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
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
      const orderSnap = await orderRef.get();
      if (orderSnap.exists) {
        await orderRef.update({
          paymentStatus: "paid",
          escrowStatus: "held",
          paymentMethod: "payhere",
          payhereStatusCode: statusCode,
          payherePaymentId: String(body.payment_id || ""),
          paidAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        const order = orderSnap.data();
        if (order?.farmerId) {
          await writeNotification(
            String(order.farmerId),
            "Payment received",
            `PayHere payment confirmed for ${order.productName || "an order"}.`,
            "order",
            orderId
          );
        }
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
    releasedAt: FieldValue.serverTimestamp(),
  });
  await db.collection("audit_logs").add({
    action: "escrow_release",
    orderId,
    actorId: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true };
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
  await ref.update({ status, reviewedBy: uid, reviewedAt: FieldValue.serverTimestamp() });
  if (status === "approved" && document.ownerId) {
    await db.collection("users").doc(document.ownerId).update({ isVerified: true, updatedAt: FieldValue.serverTimestamp() });
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
    createdAt: FieldValue.serverTimestamp(),
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
    verifiedAt: FieldValue.serverTimestamp(),
    scanCount: FieldValue.increment(1),
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
    createdAt: FieldValue.serverTimestamp(),
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
    createdAt: FieldValue.serverTimestamp(),
  });
  await orderSnapshot.ref.update({ paymentStatus: "disputed", disputeId: disputeRef.id });
  return { disputeId: disputeRef.id };
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
    updatedAt: FieldValue.serverTimestamp(),
  });
  await db.collection("audit_logs").add({
    action: suspended ? "user_suspended" : "user_unsuspended",
    targetUserId: userId,
    actorId: context.auth!.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { success: true, userId, isSuspended: suspended };
});

export const deleteAccount = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  const userRef = db.collection("users").doc(uid);

  // Anonymize user document (retain role audit shell)
  await userRef.set({
    displayName: "Deleted User",
    phone: "",
    photoUrl: FieldValue.delete(),
    email: FieldValue.delete(),
    address: FieldValue.delete(),
    deviceTokens: FieldValue.delete(),
    notificationPreferences: FieldValue.delete(),
    isSuspended: true,
    isDeleted: true,
    deletedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  // Remove device tokens subcollection
  const tokens = await userRef.collection("device_tokens").get();
  await Promise.all(tokens.docs.map((d) => d.ref.delete()));

  // Scrub PII from orders where user is buyer/farmer/transporter
  const roles = ["buyerId", "farmerId", "transporterId"] as const;
  for (const field of roles) {
    const snap = await db.collection("orders").where(field, "==", uid).limit(100).get();
    await Promise.all(snap.docs.map((doc) => {
      const updates: Record<string, unknown> = {
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (field === "buyerId") {
        updates.buyerName = "Deleted User";
        updates.buyerCompany = "";
        updates.deliveryAddress = "[redacted]";
      }
      return doc.ref.update(updates);
    }));
  }

  // Soft-delete owned products
  const products = await db.collection("products").where("farmerId", "==", uid).limit(100).get();
  await Promise.all(products.docs.map((doc) => doc.ref.update({
    status: "Deleted",
    name: "[deleted]",
    description: "",
    media: [],
    updatedAt: FieldValue.serverTimestamp(),
  })));

  await auth.deleteUser(uid);
  return { success: true };
});

export const exportUserData = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);

  const [userSnap, buyerOrders, farmerOrders, transporterOrders, products, verificationDocs] =
    await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("orders").where("buyerId", "==", uid).limit(200).get(),
      db.collection("orders").where("farmerId", "==", uid).limit(200).get(),
      db.collection("orders").where("transporterId", "==", uid).limit(200).get(),
      db.collection("products").where("farmerId", "==", uid).limit(200).get(),
      db.collection("verification_docs").where("ownerId", "==", uid).limit(100).get(),
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

  const serialize = (value: unknown): unknown => {
    if (value === null || value === undefined) return value;
    if (value instanceof Timestamp) return value.toDate().toISOString();
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
  });
});
