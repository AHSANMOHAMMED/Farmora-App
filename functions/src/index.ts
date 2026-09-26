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

// Maps a notification type to the user-preference category that controls
// its push delivery. The in-app notification doc is always written.
const notificationCategory = (type: string): "messages" | "promos" | "orderUpdates" => {
  if (type === "message") return "messages";
  if (type === "general" || type === "advisory" || type === "promo") return "promos";
  return "orderUpdates";
};

const notifyUser = async (
  userId: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> => {
  const userSnap = await db.collection("users").doc(userId).get();
  const user = userSnap.data() || {};
  if (user.isDeleted === true) return;
  // `notificationPrefs` is the current shape; `notificationPreferences` is legacy.
  const prefs = (user.notificationPrefs || user.notificationPreferences || {}) as
    Record<string, unknown>;
  const category = notificationCategory(String(data.type || ""));
  if (prefs[category] === false) return;
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
  if (!userId) return;
  await db.collection("notifications").add({
    userId,
    title,
    body,
    type,
    ...(referenceId ? { referenceId, orderId: referenceId } : {}),
    ...extra,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  // Always write in-app; FCM honours category prefs and quiet hours in notifyUser.
  try {
    await notifyUser(userId, title, body, {
      type,
      ...(referenceId ? { orderId: referenceId } : {}),
      ...extra,
    });
  } catch (err) {
    functions.logger.warn("Push notification failed", { userId, err });
  }
};

// ─── Audit log ───────────────────────────────────────────────
type AuditSeverity = "info" | "warning" | "critical";

const writeAudit = async (
  actorId: string,
  fields: {
    actionType: string;
    targetEntity: string;
    targetId: string;
    details?: string;
    severity?: AuditSeverity;
  }
): Promise<void> => {
  let actorName = "System";
  let actorRole = "system";
  if (actorId && actorId !== "system") {
    const actor = (await db.collection("users").doc(actorId).get()).data() || {};
    actorName = String(actor.displayName || actor.name || actorId);
    actorRole = String(actor.role || "admin");
  }
  await db.collection("audit_logs").add({
    actorId: actorId || "system",
    actorName,
    actorRole,
    actionType: fields.actionType,
    targetEntity: fields.targetEntity,
    targetId: fields.targetId,
    details: fields.details || "",
    severity: fields.severity || "info",
    timestamp: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
};

// ─── Platform settings / maintenance gate ─────────────────────
const SETTINGS_DEFAULTS = {
  maintenanceMode: false,
  maintenanceNotice: "",
  platformFeeBps: 0,
  sessionTimeoutMinutes: 60,
  defaultDeliveryFeeMinor: 0,
  escrowReleaseHours: 72,
  minAppVersion: "",
};

type PublicSettings = typeof SETTINGS_DEFAULTS;

const loadPlatformSettings = async (): Promise<PublicSettings> => {
  const data = (await db.collection("platform_settings").doc("global").get()).data() || {};
  const intOr = (value: unknown, fallback: number): number => {
    const n = Number(value);
    return Number.isSafeInteger(n) ? n : fallback;
  };
  return {
    maintenanceMode: data.maintenanceMode === true,
    maintenanceNotice: typeof data.maintenanceNotice === "string"
      ? data.maintenanceNotice : SETTINGS_DEFAULTS.maintenanceNotice,
    platformFeeBps: intOr(data.platformFeeBps, SETTINGS_DEFAULTS.platformFeeBps),
    sessionTimeoutMinutes: intOr(data.sessionTimeoutMinutes,
      SETTINGS_DEFAULTS.sessionTimeoutMinutes),
    defaultDeliveryFeeMinor: intOr(data.defaultDeliveryFeeMinor,
      SETTINGS_DEFAULTS.defaultDeliveryFeeMinor),
    escrowReleaseHours: intOr(data.escrowReleaseHours, SETTINGS_DEFAULTS.escrowReleaseHours),
    minAppVersion: typeof data.minAppVersion === "string"
      ? data.minAppVersion : SETTINGS_DEFAULTS.minAppVersion,
  };
};

const isAdminCaller = async (
  context: functions.https.CallableContext
): Promise<boolean> => {
  if (!context.auth) return false;
  if (context.auth.token.admin === true) return true;
  const profile = (await db.collection("users").doc(context.auth.uid).get()).data();
  return profile?.role === "admin" && profile?.isVerified === true
    && profile?.isSuspended !== true && profile?.isDeleted !== true;
};

const assertNotMaintenance = async (
  context: functions.https.CallableContext
): Promise<void> => {
  const settings = (await db.collection("platform_settings").doc("global").get()).data();
  if (settings?.maintenanceMode === true && !(await isAdminCaller(context))) {
    throw new functions.https.HttpsError("unavailable", "Farmora is under maintenance");
  }
};

// ─── Small shared helpers ─────────────────────────────────────
const orderNumberFor = (id: string): string => `FM-${id.slice(0, 8).toUpperCase()}`;

const platformFeeFor = (subtotalMinor: number, feeBps: number): number =>
  Math.round((subtotalMinor * feeBps) / 10000);

const displayNameOf = (user: Record<string, any> | undefined, fallback: string): string =>
  String(user?.displayName || user?.name || fallback);

const sha256Hex = (value: string): string =>
  createHash("sha256").update(value).digest("hex");

const optionalIsoDate = (value: unknown, label: string): string | null => {
  if (value === null || value === "") return null;
  if (typeof value !== "string" || value.length > 40) {
    throw new functions.https.HttpsError("invalid-argument", `Invalid ${label}.`);
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    throw new functions.https.HttpsError("invalid-argument", `Invalid ${label}.`);
  }
  return parsed.toISOString();
};

const requiredString = (value: unknown, label: string, min: number, max: number): string => {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length < min || text.length > max) {
    throw new functions.https.HttpsError("invalid-argument", `Invalid ${label}.`);
  }
  return text;
};

// Validates an optional transporter choice made at checkout / offer accept.
const assertTransporterSelectable = async (transporterId: string): Promise<void> => {
  if (!transporterId) return;
  const transporter = (await db.collection("users").doc(transporterId).get()).data();
  if (!transporter || transporter.role !== "transporter"
    || transporter.isSuspended === true || transporter.isDeleted === true) {
    throw new functions.https.HttpsError(
      "failed-precondition", "Selected transporter is unavailable.");
  }
};

// Reads a farmer's payout account in a transaction and returns the snapshot
// copied onto bank-deposit orders (throws when the farmer has none).
const readBankSnapshot = async (
  transaction: FirebaseFirestore.Transaction,
  farmerId: string
): Promise<Record<string, string>> => {
  const bank = (await transaction.get(
    db.collection("bank_details").doc(farmerId || "-")
  )).data();
  if (!isUsableBank(bank)) {
    throw new functions.https.HttpsError(
      "failed-precondition", "This farmer does not accept bank deposits yet.");
  }
  return {
    bankName: String(bank!.bankName),
    branch: String(bank!.branch),
    accountHolderName: String(bank!.accountHolderName),
    accountNumber: String(bank!.accountNumber),
  };
};

const isUsableBank = (bank: Record<string, any> | undefined): boolean =>
  !!bank && !!bank.bankName && !!bank.branch && !!bank.accountHolderName
  && /^[0-9]{6,18}$/.test(String(bank.accountNumber || ""));

// Public, non-sensitive projection of a transporter profile. Mirrored into
// `transporter_profiles/{uid}` (readable by signed-in users, written only here).
const transporterProjection = (
  uid: string,
  user: Record<string, any>
): Record<string, unknown> => {
  const capacity = Number(user.vehicleCapacity ?? user.capacityKg);
  return {
    id: uid,
    uid,
    displayName: displayNameOf(user, "Transporter"),
    photoUrl: typeof user.photoUrl === "string" ? user.photoUrl : null,
    district: typeof user.district === "string" ? user.district : "",
    vehicleType: typeof user.vehicleType === "string" ? user.vehicleType : "",
    vehicleRegistration: typeof user.vehicleRegistration === "string"
      ? user.vehicleRegistration : "",
    vehicleCapacity: Number.isFinite(capacity) && capacity > 0 ? capacity : null,
    vehicleCapacityUnit: user.vehicleCapacity != null
      ? (user.vehicleCapacityUnit === "tons" ? "tons" : "kg")
      : "kg",
    serviceDistricts: Array.isArray(user.serviceDistricts)
      ? user.serviceDistricts.filter((d: unknown) => typeof d === "string").slice(0, 25)
      : [],
    availabilityStatus: user.availabilityStatus === "unavailable" ? "unavailable" : "available",
    isVerified: user.isVerified === true,
    isSuspended: user.isSuspended === true || user.isDeleted === true,
    rating: Number.isFinite(Number(user.rating)) ? Number(user.rating) : null,
  };
};

// Re-derives transporter_profiles/{uid} from users/{uid}; deletes it when the
// user is no longer an active transporter.
const syncTransporterProfile = async (uid: string): Promise<void> => {
  const user = (await db.collection("users").doc(uid).get()).data();
  const ref = db.collection("transporter_profiles").doc(uid);
  if (!user || user.role !== "transporter" || user.isDeleted === true) {
    await ref.delete();
    return;
  }
  await ref.set({
    ...transporterProjection(uid, user),
    updatedAt: FieldValue.serverTimestamp(),
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
  const unit = String(order.unit || "units");
  const quantityValue = Number(order.items?.[0]?.quantity);
  const qtyLabel = String(order.quantity
    || `${Number.isFinite(quantityValue) ? quantityValue : ""} ${unit}`);
  const requestedTransporterId = typeof order.requestedTransporterId === "string"
    && order.requestedTransporterId ? order.requestedTransporterId : null;
  let farmerName = typeof order.farmerName === "string" ? order.farmerName : "";
  if (!farmerName && order.farmerId) {
    farmerName = displayNameOf(
      (await db.collection("users").doc(String(order.farmerId)).get()).data(), "Farmer");
  }
  const jobRef = db.collection("transport_jobs").doc();
  await jobRef.set({
    orderId,
    orderNumber: String(order.orderNumber || orderNumberFor(orderId)),
    farmerId: order.farmerId,
    buyerId: order.buyerId,
    farmerName: farmerName || "Farmer",
    buyerName: String(order.buyerName || "Buyer"),
    title: `Delivery for ${productName}`,
    route: `${pickup} → ${dropoff}`,
    detail: `${qtyLabel} · Ready for pickup`,
    fee: `LKR ${(fee / 100).toFixed(2)}`,
    offeredFeeMinor: fee,
    deliveryFeeMinor: fee,
    pickupAddress: pickup,
    dropoffAddress: dropoff,
    pickup,
    dropoff,
    productName,
    quantity: qtyLabel,
    quantityValue: Number.isFinite(quantityValue) ? quantityValue : 0,
    unit,
    status: "requested",
    accepted: false,
    transporterId: requestedTransporterId,
    ...(requestedTransporterId ? { requestedTransporterId } : {}),
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

  // A role can only be chosen once. Changing it later is an admin action
  // (adminSetUserRole); this also prevents un-suspending via re-onboarding.
  const userRef = db.collection("users").doc(uid);
  if ((await userRef.get()).exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your profile already exists. Contact support to change your role."
    );
  }

  // Set custom claim
  await auth.setCustomUserClaims(uid, { role });

  await userRef.create({
    id: uid,
    role,
    displayName: typeof displayName === "string" ? displayName.trim().slice(0, 120) : "",
    phone: typeof phone === "string" ? phone.trim().slice(0, 30) : "",
    languageCode: typeof languageCode === "string" ? languageCode.slice(0, 10) : "en",
    isVerified: false,
    isOnboardingComplete: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

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

// Any signed-in user: returns only the public settings fields.
export const getPlatformSettings = functions.https.onCall(async (_data, context) => {
  requireAuth(context);
  return loadPlatformSettings();
});

export const updatePlatformSettings = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const updates: Record<string, unknown> = {};
  if (typeof data.maintenanceMode === "boolean") updates.maintenanceMode = data.maintenanceMode;
  if (data.maintenanceNotice !== undefined) {
    if (typeof data.maintenanceNotice !== "string" || data.maintenanceNotice.length > 300) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid maintenance notice.");
    }
    updates.maintenanceNotice = data.maintenanceNotice.trim();
  }
  if (data.escrowReleaseHours !== undefined) {
    const hours = Number(data.escrowReleaseHours);
    if (!Number.isSafeInteger(hours) || hours < 1 || hours > 720) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid escrow release hours.");
    }
    updates.escrowReleaseHours = hours;
  }
  if (data.minAppVersion !== undefined) {
    if (typeof data.minAppVersion !== "string" || data.minAppVersion.length > 20
      || !/^[0-9A-Za-z.+-]*$/.test(data.minAppVersion)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid minimum app version.");
    }
    updates.minAppVersion = data.minAppVersion.trim();
  }
  if (data.defaultDeliveryFeeMinor !== undefined) {
    const fee = Number(data.defaultDeliveryFeeMinor);
    if (!Number.isSafeInteger(fee) || fee < 0 || fee > 10000000) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid default delivery fee.");
    }
    updates.defaultDeliveryFeeMinor = fee;
  }
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
  const before = await loadPlatformSettings();
  await db.collection("platform_settings").doc("global").set({
    ...updates,
    updatedBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  const maintenanceToggled = typeof updates.maintenanceMode === "boolean"
    && updates.maintenanceMode !== before.maintenanceMode;
  await writeAudit(uid, {
    actionType: maintenanceToggled ? "MAINTENANCE_TOGGLE" : "PLATFORM_SETTINGS_UPDATED",
    targetEntity: "platform_settings",
    targetId: "global",
    details: `Updated ${Object.entries(updates)
      .map(([k, v]) => `${k}=${JSON.stringify(v)}`).join(", ")}`,
    severity: maintenanceToggled || updates.platformFeeBps !== undefined ? "warning" : "info",
  });
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
    const jobId = context.params.jobId as string;

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
      // Only Cloud Functions write transport_jobs (rules deny clients), so an
      // unexpected transition is logged rather than reverted — a revert would
      // itself be an "invalid" transition and re-trigger this function.
      functions.logger.error("Unexpected transport transition", {
        jobId, from: before.status, to: after.status,
      });
      return;
    }

    // Log transition
    await db.collection("transportTransitions").add({
      jobId,
      from: before.status,
      to: after.status,
      actorId: after.transporterId || after.cancelledBy || "system",
      timestamp: FieldValue.serverTimestamp(),
    });

    if (!after.orderId) return;
    const orderRef = db.collection("orders").doc(String(after.orderId));
    const extra = { jobId };

    // A transporter dropped an assigned job: the order goes back to
    // "confirmed" and a fresh open request is created for other transporters.
    const droppedAfterAssignment = after.status === "cancelled"
      && (before.status === "accepted" || before.status === "pickedUp");

    const orderStatusMap: Record<string, string> = {
      accepted: "assigned",
      pickedUp: "pickedUp",
      inTransit: "inTransit",
      delivered: "delivered",
    };
    const orderStatus = orderStatusMap[after.status];
    if (orderStatus) {
      await orderRef.update({
        status: orderStatus,
        ...(after.transporterId ? { transporterId: after.transporterId } : {}),
        updatedAt: FieldValue.serverTimestamp(),
        ...(orderStatus === "delivered"
          ? { deliveredAt: FieldValue.serverTimestamp() }
          : {}),
      });
    } else if (droppedAfterAssignment) {
      await orderRef.update({
        status: "confirmed",
        transporterId: FieldValue.delete(),
        requestedTransporterId: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const orderSnap = await orderRef.get();
    const order = orderSnap.data();
    if (!order) return;

    let reopenedJobId: string | null = null;
    if (droppedAfterAssignment && order.status === "confirmed") {
      // The fresh request is open to every transporter (no target).
      const reopenOrder: Record<string, any> = { ...order };
      delete reopenOrder.requestedTransporterId;
      delete reopenOrder.transporterId;
      reopenedJobId = await createTransportJobForOrder(
        orderSnap.id,
        reopenOrder,
        Number(after.offeredFeeMinor ?? after.deliveryFeeMinor ?? order.deliveryFeeMinor ?? 0)
      );
    }

    const productLabel = order.productName || "your order";
    const body = droppedAfterAssignment
      ? `The transporter cancelled the delivery for ${productLabel}. It has been re-opened for other transporters.`
      : `Delivery for ${productLabel} is now ${after.status}.`;
    const notifyExtra = reopenedJobId ? { jobId: reopenedJobId, previousJobId: jobId } : extra;
    if (order.buyerId) {
      await writeNotification(String(order.buyerId), "Delivery update", body,
        "logistics", String(after.orderId), notifyExtra);
    }
    if (order.farmerId) {
      await writeNotification(String(order.farmerId), "Delivery update", body,
        "logistics", String(after.orderId), notifyExtra);
    }
    if (after.transporterId && (after.status === "accepted" || after.status === "delivered")) {
      await writeNotification(
        String(after.transporterId),
        after.status === "accepted" ? "Job accepted" : "Delivery completed",
        after.status === "accepted"
          ? `You accepted the delivery for ${productLabel}.`
          : `Delivery for ${productLabel} is complete.`,
        "logistics",
        String(after.orderId),
        extra
      );
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
// Optional offerId: when set, uses that offer's negotiated per-unit price/qty
// (buyer must own it). Optional idempotencyKey makes client retries safe.
export const createOrder = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await assertNotMaintenance(context);
  await requireRole(uid, ["buyer"]);
  const productId = typeof data.productId === "string" ? data.productId : "";
  const quantity = Number(data.quantity);
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const transporterId = typeof data.transporterId === "string"
    ? data.transporterId : "";
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  const paymentMethod = data.paymentMethod === "bank_deposit" ? "bank_deposit" : "cod";
  const idempotencyKey = data.idempotencyKey == null ? "" : data.idempotencyKey;
  if (!productId || !Number.isSafeInteger(quantity) || quantity < 1
    || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0
    || deliveryFeeMinor > 10000000) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid order details.");
  }
  if (idempotencyKey !== "" && (typeof idempotencyKey !== "string"
    || idempotencyKey.length < 16 || idempotencyKey.length > 256)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid idempotency key.");
  }
  if (!deliveryAddress || deliveryAddress.length < 5) {
    throw new functions.https.HttpsError("invalid-argument", "Delivery address is required.");
  }
  await assertTransporterSelectable(transporterId);

  const settings = await loadPlatformSettings();
  const productRef = db.collection("products").doc(productId);
  const offerRef = offerId ? db.collection("offers").doc(offerId) : null;
  const buyerSnap = await db.collection("users").doc(uid).get();
  const buyer = buyerSnap.data() || {};
  const idemRef = idempotencyKey
    ? db.collection("idempotency_keys").doc(sha256Hex(`${uid}:${idempotencyKey}`))
    : null;
  const requestHash = sha256Hex(JSON.stringify({
    productId, quantity, deliveryFeeMinor, offerId, transporterId, deliveryAddress, paymentMethod,
  }));

  const orderId = await db.runTransaction(async (transaction) => {
    if (idemRef) {
      const previous = (await transaction.get(idemRef)).data();
      if (previous) {
        if (previous.requestHash === requestHash && typeof previous.orderId === "string") {
          return previous.orderId as string;
        }
        throw new functions.https.HttpsError(
          "already-exists", "This checkout was already submitted with different details.");
      }
    }
    const orderRef = db.collection("orders").doc();
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const available = Number(product?.quantityAvailable);
    let priceMinor = Number(product?.priceMinor);
    let orderQuantity = quantity;
    let finalSubtotal = 0;
    // Reads must precede writes in a transaction, so fetch bank details now.
    const bankDetailsSnapshot = paymentMethod === "bank_deposit"
      ? await readBankSnapshot(transaction, String(product?.farmerId || ""))
      : null;
    const farmer = product?.farmerId
      ? (await transaction.get(db.collection("users").doc(String(product.farmerId)))).data()
      : undefined;

    if (offerRef) {
      const offerSnapshot = await transaction.get(offerRef);
      const offer = offerSnapshot.data();
      if (!offer || offer.buyerId !== uid || offer.productId !== productId
        || offer.status !== "pending") {
        throw new functions.https.HttpsError("failed-precondition", "Offer is not usable.");
      }
      orderQuantity = Number(offer.proposedQuantity);
      priceMinor = Number(offer.proposedPriceMinor); // per unit
      if (!Number.isSafeInteger(orderQuantity) || orderQuantity < 1
        || !Number.isSafeInteger(priceMinor) || priceMinor < 0) {
        throw new functions.https.HttpsError("failed-precondition", "Offer pricing is invalid.");
      }
      finalSubtotal = priceMinor * orderQuantity;
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
      orderNumber: orderNumberFor(orderRef.id),
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
      platformFeeMinor: platformFeeFor(finalSubtotal, settings.platformFeeBps),
      currency: "LKR",
      deliveryAddress,
      pickupAddress: String(product.location || "Farm pickup"),
      location: String(product.location || ""),
      buyerName: displayNameOf(buyer, "Buyer"),
      buyerCompany: String(buyer.district || ""),
      farmerName: displayNameOf(farmer, "Farmer"),
      status: "pending",
      ...(transporterId ? { requestedTransporterId: transporterId } : {}),
      paymentMethod,
      paymentStatus: "payment_required",
      ...(bankDetailsSnapshot ? { bankDetailsSnapshot } : {}),
      escrowStatus: "not_funded",
      ...(offerId ? { offerId } : {}),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (idemRef) {
      transaction.create(idemRef, {
        uid,
        requestHash,
        orderId: orderRef.id,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    return orderRef.id;
  });
  return { orderId };
});

// Buyer creates a price offer; farmerId always taken from the product document.
// proposedPrice / proposedPriceMinor are PER UNIT.
export const createOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await assertNotMaintenance(context);
  const buyer = await requireRole(uid, ["buyer"]);
  const productId = typeof data.productId === "string" ? data.productId : "";
  const proposedQuantity = Number(data.proposedQuantity);
  const proposedPrice = Number(data.proposedPrice);
  if (!productId || !Number.isSafeInteger(proposedQuantity) || proposedQuantity < 1
    || !Number.isFinite(proposedPrice) || proposedPrice <= 0 || proposedPrice > 100000000) {
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
  const farmer = (await db.collection("users").doc(farmerId).get()).data();
  const unit = String(product.unit || "unit");
  const offerRef = db.collection("offers").doc();
  await offerRef.set({
    productId,
    productName: String(product.name || ""),
    unit,
    buyerId: uid,
    buyerName: displayNameOf(buyer, "Buyer"),
    farmerId,
    farmerName: displayNameOf(farmer, "Farmer"),
    proposedQuantity,
    proposedPrice,
    proposedPriceMinor,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeNotification(
    farmerId,
    "New Price Offer",
    `You received an offer of LKR ${proposedPrice.toFixed(2)} per ${unit} for ${proposedQuantity} ${unit}.`,
    "offer",
    offerRef.id,
    { offerId: offerRef.id }
  );
  return { offerId: offerRef.id };
});

// Farmer counters a buyer's pending offer. counterPrice is LKR PER UNIT.
// All price changes and notifications are server-owned so both parties see
// the same negotiated amount.
export const counterOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireVerifiedRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const counterPrice = Number(data.counterPrice);
  if (!offerId || !Number.isFinite(counterPrice) || counterPrice <= 0
    || counterPrice > 100000000) {
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
    originalPriceMinor: Number(offer.proposedPriceMinor || 0),
    proposedPrice: counterPriceMinor / 100,
    proposedPriceMinor: counterPriceMinor,
    counteredAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeNotification(
    String(offer.buyerId),
    "Farmer sent a counter-offer",
    `The farmer countered at LKR ${(counterPriceMinor / 100).toFixed(2)} per ${offer.unit || "unit"}.`,
    "offer",
    offerId,
    { offerId }
  );
  return { success: true };
});

// The farmer accepts the buyer's pending offer, or the buyer accepts the
// farmer's counter. The same transaction creates one order and reserves stock.
export const acceptOffer = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await assertNotMaintenance(context);
  const actor = await requireRole(uid, ["farmer", "buyer"]);
  const actorRole = String(actor.role);
  if (actorRole === "farmer") await requireVerifiedRole(uid, ["farmer"]);
  const offerId = typeof data.offerId === "string" ? data.offerId : "";
  const deliveryFeeMinor = Number(data.deliveryFeeMinor || 0);
  const deliveryAddress = typeof data.deliveryAddress === "string"
    ? data.deliveryAddress.trim().slice(0, 500) : "";
  const paymentMethod = data.paymentMethod === "bank_deposit" ? "bank_deposit" : "cod";
  const transporterId = typeof data.transporterId === "string" ? data.transporterId : "";
  if (!offerId || !Number.isSafeInteger(deliveryFeeMinor) || deliveryFeeMinor < 0
    || deliveryFeeMinor > 10000000
    || (deliveryAddress !== "" && deliveryAddress.length < 5)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid offer accept request.");
  }
  await assertTransporterSelectable(transporterId);
  const settings = await loadPlatformSettings();

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
    const priceMinor = Number(offer.proposedPriceMinor); // per unit
    if (!productId || !Number.isSafeInteger(orderQuantity) || orderQuantity < 1
      || !Number.isSafeInteger(priceMinor) || priceMinor < 0) {
      throw new functions.https.HttpsError("failed-precondition", "Offer pricing is invalid.");
    }
    const finalSubtotal = priceMinor * orderQuantity;
    const farmerId = String(offer.farmerId);
    const productRef = db.collection("products").doc(productId);
    const productSnapshot = await transaction.get(productRef);
    const product = productSnapshot.data();
    const bankDetailsSnapshot = paymentMethod === "bank_deposit"
      ? await readBankSnapshot(transaction, farmerId)
      : null;
    const buyerSnap = await transaction.get(db.collection("users").doc(String(offer.buyerId)));
    const farmerSnap = await transaction.get(db.collection("users").doc(farmerId));
    const available = Number(product?.quantityAvailable);
    if (!product || product.farmerId !== farmerId || product.status !== "Active"
      || !Number.isSafeInteger(available) || available < orderQuantity) {
      throw new functions.https.HttpsError("failed-precondition", "Product is unavailable.");
    }
    const unit = String(product.unit || offer.unit || "unit");
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
      acceptedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(orderRef, {
      orderNumber: orderNumberFor(orderRef.id),
      buyerId: offer.buyerId,
      farmerId,
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
      platformFeeMinor: platformFeeFor(finalSubtotal, settings.platformFeeBps),
      currency: "LKR",
      deliveryAddress: deliveryAddress || String(offer.deliveryAddress || "To be confirmed with buyer"),
      pickupAddress: String(product.location || "Farm pickup"),
      location: String(product.location || ""),
      buyerName: displayNameOf(buyerSnap.data(), String(offer.buyerName || "Buyer")),
      farmerName: displayNameOf(farmerSnap.data(), String(offer.farmerName || "Farmer")),
      status: "pending",
      ...(transporterId ? { requestedTransporterId: transporterId } : {}),
      paymentMethod,
      paymentStatus: "payment_required",
      ...(bankDetailsSnapshot ? { bankDetailsSnapshot } : {}),
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
      orderRef.id,
      { offerId }
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
  await assertNotMaintenance(context);
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
  const availabilityDate = data.availabilityDate === undefined
    ? null : optionalIsoDate(data.availabilityDate, "availability date");
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
    availabilityDate,
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
  const media = Array.isArray(data.media)
    ? data.media.filter((u: unknown) => typeof u === "string"
      && u.startsWith("https://") && u.length < 2048).slice(0, 5)
    : (existing.media || []);
  const availabilityDate = data.availabilityDate === undefined
    ? (typeof existing.availabilityDate === "string" ? existing.availabilityDate : null)
    : optionalIsoDate(data.availabilityDate, "availability date");
  await ref.update({ availabilityDate, name, category, description: typeof data.description === "string" ? data.description.trim().slice(0, 4000) : String(existing.description || ""), unit, location, priceMinor, price: `LKR ${(priceMinor / 100).toFixed(2)} / ${unit}`, pricePerUnit: priceMinor / 100, quantityAvailable, quantity: `${quantityAvailable} ${unit} available`, status: quantityAvailable > 0 ? requestedStatus : "Empty", isOrganic: data.isOrganic == null ? existing.isOrganic === true : data.isOrganic === true, media, updatedAt: FieldValue.serverTimestamp(), listingVersion: Number(existing.listingVersion || 1) + 1 });
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
  await assertNotMaintenance(context);
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
  if (!requestId || !farmerId) throw new functions.https.HttpsError("invalid-argument", "requestId and farmerId are required.");
  const orderRef = db.collection("orders").doc();
  const settings = await loadPlatformSettings();
  await db.runTransaction(async (tx) => {
    const requestSnap = await tx.get(requestRef), quoteSnap = await tx.get(quoteRef);
    const request = requestSnap.data(), quote = quoteSnap.data();
    if (!request || request.buyerId !== uid || request.status !== "open" || !quote || quote.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "Request or quote is no longer available.");
    const productRef = db.collection("products").doc(String(quote.productId));
    const productSnap = await tx.get(productRef), product = productSnap.data();
    const farmerProfile = (await tx.get(db.collection("users").doc(farmerId))).data();
    const available = Number(product?.quantityAvailable), quantity = Number(request.quantity), price = Number(quote.unitPriceMinor);
    if (!product || product.farmerId !== farmerId || product.status !== "Active" || available < quantity
      || !Number.isSafeInteger(price) || price < 1) throw new functions.https.HttpsError("failed-precondition", "Farmer stock or quote is no longer valid.");
    const subtotal = quantity * price, fee = Number(quote.deliveryFeeMinor || 0), unit = String(product.unit || request.unit);
    tx.update(productRef, { quantityAvailable: available - quantity, quantity: `${available - quantity} ${unit} available`, status: available > quantity ? "Active" : "Empty", updatedAt: FieldValue.serverTimestamp() });
    tx.update(quoteRef, { status: "accepted", orderId: orderRef.id, updatedAt: FieldValue.serverTimestamp() });
    tx.update(requestRef, { status: "matched", acceptedFarmerId: farmerId, orderId: orderRef.id, updatedAt: FieldValue.serverTimestamp() });
    tx.create(orderRef, {
      orderNumber: orderNumberFor(orderRef.id),
      farmerName: displayNameOf(farmerProfile, String(quote.farmerName || "Farmer")),
      paymentMethod: "cod",
      platformFeeMinor: platformFeeFor(subtotal, settings.platformFeeBps),
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
  await writeAudit(uid, {
    actionType: decision === "approve" ? "MARKET_PRICE_APPROVED" : "MARKET_PRICE_REJECTED",
    targetEntity: "market_price_reports",
    targetId: reportId,
    details: `${report?.cropName || "Report"} (${report?.district || "-"})`,
  });
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
  const fee = Number.isSafeInteger(deliveryFeeMinor) && deliveryFeeMinor >= 0
    && deliveryFeeMinor <= 10000000
    ? deliveryFeeMinor
    : undefined;
  // An open request already exists: just update its offered fee.
  const openJob = await db.collection("transport_jobs")
    .where("orderId", "==", orderId)
    .where("status", "==", "requested")
    .limit(1)
    .get();
  if (!openJob.empty) {
    const jobRef = openJob.docs[0].ref;
    if (fee !== undefined) {
      await jobRef.update({
        offeredFeeMinor: fee,
        deliveryFeeMinor: fee,
        fee: `LKR ${(fee / 100).toFixed(2)}`,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    return { jobId: jobRef.id };
  }
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
    escrowStatus: "held",
    paymentMethod: typeof order.paymentMethod === "string" ? order.paymentMethod : method,
    paidAt: FieldValue.serverTimestamp(),
    paidBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  // The buyer is notified by the onOrderPaymentStatusChanged trigger.
  return { success: true };
});

export const transitionTransport = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await assertNotMaintenance(context);
  await requireVerifiedRole(uid, ["transporter"]);
  const jobId = typeof data.jobId === "string" ? data.jobId : "";
  const nextStatus = typeof data.status === "string" ? data.status : "";
  const reason = typeof data.reason === "string" ? data.reason.trim().slice(0, 500) : "";
  if (!jobId || !nextStatus) {
    throw new functions.https.HttpsError("invalid-argument", "jobId and status are required.");
  }
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
      case "DECLINED":
      case "DECLINE":
        return "declined";
      default:
        return String(value ?? "");
    }
  };
  const currentStatus = normalizeStatus(job.status);
  const requestedStatus = normalizeStatus(nextStatus);

  // A targeted transporter declines a request: the job stays "requested"
  // but becomes open to every transporter, and the farmer is told.
  if (requestedStatus === "declined") {
    if (currentStatus !== "requested"
      || (job.requestedTransporterId !== uid && job.transporterId !== uid)) {
      throw new functions.https.HttpsError("failed-precondition", "This request cannot be declined.");
    }
    await db.runTransaction(async (transaction) => {
      const current = (await transaction.get(ref)).data();
      if (!current || normalizeStatus(current.status) !== "requested"
        || (current.requestedTransporterId !== uid && current.transporterId !== uid)) {
        throw new functions.https.HttpsError("aborted", "Request changed. Refresh and retry.");
      }
      transaction.update(ref, {
        transporterId: null,
        requestedTransporterId: FieldValue.delete(),
        declinedBy: FieldValue.arrayUnion(uid),
        ...(reason ? { declineReason: reason } : {}),
        declinedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (current.orderId) {
        transaction.update(db.collection("orders").doc(String(current.orderId)), {
          requestedTransporterId: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
    if (job.farmerId) {
      await writeNotification(
        String(job.farmerId),
        "Delivery request declined",
        `The selected transporter declined the delivery for ${job.productName || "your order"}. It is now open to other transporters.`,
        "logistics",
        job.orderId ? String(job.orderId) : undefined,
        { jobId }
      );
    }
    return { success: true };
  }

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

// Full profile update, or availability-only update ({availabilityStatus}).
// Public fields are mirrored to transporter_profiles/{uid}.
export const updateTransporterProfile = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["transporter"]);

  const availabilityStatus = data.availabilityStatus === "available"
    ? "available"
    : data.availabilityStatus === "unavailable"
      ? "unavailable"
      : "";
  const profileKeys = ["displayName", "phone", "vehicleType", "vehicleRegistration",
    "vehicleCapacity", "vehicleCapacityUnit", "vehicleDescription", "serviceDistricts"];
  const isAvailabilityOnly = !profileKeys.some((key) => data[key] !== undefined);

  if (isAvailabilityOnly) {
    if (!availabilityStatus) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid availability status.");
    }
    await db.collection("users").doc(uid).update({
      availabilityStatus,
      updatedAt: FieldValue.serverTimestamp(),
    });
    await syncTransporterProfile(uid);
    return { success: true };
  }

  const displayName = typeof data.displayName === "string" ? data.displayName.trim() : "";
  const phone = typeof data.phone === "string" ? data.phone.trim() : "";
  const vehicleType = typeof data.vehicleType === "string" ? data.vehicleType.trim() : "";
  const vehicleRegistration = typeof data.vehicleRegistration === "string"
    ? data.vehicleRegistration.trim().toUpperCase()
    : "";
  const vehicleCapacity = data.vehicleCapacity == null ? null : Number(data.vehicleCapacity);
  const vehicleCapacityUnit = data.vehicleCapacityUnit === "tons" ? "tons" : "kg";
  const vehicleDescription = typeof data.vehicleDescription === "string"
    ? data.vehicleDescription.trim().slice(0, 500)
    : "";
  let serviceDistricts: string[] | undefined;
  if (data.serviceDistricts !== undefined) {
    if (!Array.isArray(data.serviceDistricts) || data.serviceDistricts.length > 25
      || data.serviceDistricts.some((d: unknown) => typeof d !== "string"
        || d.trim().length === 0 || d.length > 80)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid service districts.");
    }
    serviceDistricts = [...new Set((data.serviceDistricts as string[]).map((d) => d.trim()))];
  }

  if (displayName.length < 2 || displayName.length > 120 || phone.length < 7 || phone.length > 30
    || !vehicleType || vehicleType.length > 60
    || !vehicleRegistration || vehicleRegistration.length > 20 || !availabilityStatus
    || (vehicleCapacity != null && (!Number.isFinite(vehicleCapacity) || vehicleCapacity <= 0
      || vehicleCapacity > 1000000))) {
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
    ...(serviceDistricts ? { serviceDistricts } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await syncTransporterProfile(uid);
  return { success: true };
});

// Signed-in users: verified, non-suspended transporters (public projection).
// Sourced from users (so existing transporters are included) and mirrored
// into transporter_profiles as a lazy backfill.
export const listAvailableTransporters = functions.https.onCall(async (data, context) => {
  requireAuth(context);
  const district = typeof data?.district === "string" ? data.district.trim().toLowerCase() : "";
  if (district.length > 80) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid district.");
  }
  const snap = await db.collection("users")
    .where("role", "==", "transporter")
    .where("isVerified", "==", true)
    .limit(100)
    .get();
  const results: Record<string, unknown>[] = [];
  const backfill: Promise<unknown>[] = [];
  for (const doc of snap.docs) {
    const user = doc.data();
    if (user.isSuspended === true || user.isDeleted === true) continue;
    const projection = transporterProjection(doc.id, user);
    backfill.push(db.collection("transporter_profiles").doc(doc.id).set({
      ...projection,
      updatedAt: FieldValue.serverTimestamp(),
    }));
    if (district) {
      const districts = (projection.serviceDistricts as string[]).map((d) => d.toLowerCase());
      const home = String(projection.district || "").toLowerCase();
      if (home !== district && !districts.includes(district)) continue;
    }
    results.push(projection);
  }
  await Promise.all(backfill);
  return results;
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
  await requireRole(uid, ["farmer", "transporter", "buyer"]);
  const documentType = typeof data.documentType === "string" ? data.documentType.trim() : "";
  const storagePath = typeof data.storagePath === "string" ? data.storagePath : "";
  if (!documentType || documentType.length > 80 || storagePath.length > 1024
    || storagePath.includes("..") || !storagePath.startsWith(`verification/${uid}/`)) {
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

// Chat text is accepted only as ciphertext (plaintext is never persisted).
// Photos reference Storage objects the sender uploaded for this order.
export const sendMessage = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await assertNotMaintenance(context);
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
      orderNumber: String(order.orderNumber || orderNumberFor(orderId)),
      participantIds: participants,
      lastMessage: "",
      lastMessageAt: FieldValue.serverTimestamp(),
      unreadCounts: { [recipientId]: 0, [uid]: 0 },
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  const ref = db.collection("messages").doc();
  await ref.set({
    orderId,
    conversationId,
    participantIds: participants,
    senderId: uid,
    receiverId: recipientId,
    recipientId,
    type: hasImage ? "image" : "text",
    ...(hasText ? { ciphertext } : {}),
    ...(hasImage ? { attachmentUrl, attachmentPath, attachmentKind } : {}),
    createdAt: FieldValue.serverTimestamp(),
  });
  await convoRef.update({
    lastMessage: hasImage
      ? (attachmentKind === "payment_proof" ? "Payment receipt" : "Photo")
      : ciphertext.slice(0, 140),
    lastMessageAt: FieldValue.serverTimestamp(),
    lastSenderId: uid,
    [`unreadCounts.${recipientId}`]: FieldValue.increment(1),
  });
  await writeNotification(
    recipientId,
    hasImage && attachmentKind === "payment_proof" ? "Payment receipt received" : "New message",
    hasImage ? "You received a photo in your order chat." : "You have a new encrypted order message.",
    "message",
    orderId,
    { conversationId, senderId: uid }
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
  await writeAudit(uid, {
    actionType: "ESCROW_RELEASE",
    targetEntity: "orders",
    targetId: orderId,
    details: `Released ${String(order.orderNumber || orderId)} (LKR ${(Number(order.totalMinor || 0) / 100).toFixed(2)})`,
    severity: "warning",
  });
  return { success: true };
});

export const reviewVerification = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const documentId = typeof data.documentId === "string" ? data.documentId : "";
  const status = data.status === "approved" || data.status === "rejected" ? data.status : "";
  const reason = typeof data.reason === "string" ? data.reason.trim() : "";
  if (!documentId || !status || reason.length > 300) throw new functions.https.HttpsError("invalid-argument", "Invalid verification decision.");
  const ref = db.collection("verification_docs").doc(documentId);
  const snapshot = await ref.get();
  const document = snapshot.data();
  if (!document || document.status !== "pending") throw new functions.https.HttpsError("failed-precondition", "Document is not pending.");
  await ref.update({
    status,
    reviewedBy: uid,
    reviewedAt: FieldValue.serverTimestamp(),
    ...(status === "rejected"
      ? { rejectionReason: reason || "Document rejected by admin." }
      : { rejectionReason: FieldValue.delete() }),
  });
  const ownerId = String(document.ownerId || document.farmerId || "");
  if (ownerId) {
    if (status === "approved") {
      await db.collection("users").doc(ownerId).update({ isVerified: true, updatedAt: FieldValue.serverTimestamp() });
      const owner = (await db.collection("users").doc(ownerId).get()).data();
      if (owner?.role === "transporter") await syncTransporterProfile(ownerId);
    }
    const docLabel = String(document.documentType || "verification document");
    await writeNotification(
      ownerId,
      status === "approved" ? "Verification approved" : "Verification rejected",
      status === "approved"
        ? `Your ${docLabel} was approved. Your account is now verified.`
        : `Your ${docLabel} was rejected${reason ? `: ${reason}` : "."} Please upload a new document.`,
      "verification",
      undefined,
      { documentId }
    );
  }
  await writeAudit(uid, {
    actionType: status === "approved" ? "VERIFICATION_APPROVED" : "VERIFICATION_REJECTED",
    targetEntity: "verification_docs",
    targetId: documentId,
    details: `${document.documentType || "Document"} of ${ownerId || "unknown user"}${reason ? ` — ${reason}` : ""}`,
    severity: "info",
  });
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
  const [reviewerSnap, subjectSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("users").doc(String(order.farmerId)).get(),
  ]);
  await reviewRef.create({
    orderId,
    orderNumber: String(order.orderNumber || orderNumberFor(orderId)),
    reviewerId: uid,
    reviewerName: displayNameOf(reviewerSnap.data(), String(order.buyerName || "Buyer")),
    subjectId: order.farmerId,
    subjectName: displayNameOf(subjectSnap.data(), String(order.farmerName || "Farmer")),
    productId: order.productId || null,
    productName: String(order.productName || ""),
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
  const adminUid = await requireAdmin(context);
  const userId = typeof data.userId === "string" ? data.userId.trim() : "";
  const suspended = data.suspended === true;
  if (!userId) {
    throw new functions.https.HttpsError("invalid-argument", "userId is required.");
  }
  if (userId === adminUid) {
    throw new functions.https.HttpsError("failed-precondition", "You cannot suspend your own account.");
  }
  const ref = db.collection("users").doc(userId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }
  if (!suspended && snap.data()?.isDeleted === true) {
    throw new functions.https.HttpsError("failed-precondition", "Deleted accounts cannot be reactivated.");
  }
  await ref.update({
    isSuspended: suspended,
    updatedAt: FieldValue.serverTimestamp(),
  });
  try {
    await auth.updateUser(userId, { disabled: suspended });
    if (suspended) await auth.revokeRefreshTokens(userId);
  } catch (err) {
    functions.logger.warn("Auth disable toggle failed", { userId, err });
  }
  if (snap.data()?.role === "transporter") await syncTransporterProfile(userId);
  await writeAudit(adminUid, {
    actionType: suspended ? "USER_SUSPENDED" : "USER_UNSUSPENDED",
    targetEntity: "users",
    targetId: userId,
    details: `${suspended ? "Suspended" : "Reinstated"} ${displayNameOf(snap.data(), userId)}`,
    severity: suspended ? "warning" : "info",
  });
  return { success: true, userId, isSuspended: suspended };
});

// Deletes every document matched by `query` in batches (bounded).
const deleteQueryInBatches = async (
  query: FirebaseFirestore.Query,
  maxRounds = 25
): Promise<void> => {
  for (let round = 0; round < maxRounds; round++) {
    const snap = await query.limit(400).get();
    if (snap.empty) return;
    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    if (snap.size < 400) return;
  }
};

const deleteStoragePrefix = async (prefix: string): Promise<void> => {
  try {
    await admin.storage().bucket().deleteFiles({ prefix, force: true });
  } catch (err) {
    functions.logger.warn("Storage prefix delete failed", { prefix, err });
  }
};

export const deleteAccount = functions.https.onCall(async (_data, context) => {
  const uid = requireAuth(context);
  const userRef = db.collection("users").doc(uid);

  // Anonymize user document (retain role audit shell)
  await userRef.set({
    displayName: "Deleted User",
    name: "Deleted User",
    phone: "",
    photoUrl: FieldValue.delete(),
    email: FieldValue.delete(),
    address: FieldValue.delete(),
    location: FieldValue.delete(),
    deviceTokens: FieldValue.delete(),
    notificationPreferences: FieldValue.delete(),
    notificationPrefs: FieldValue.delete(),
    chatPublicKey: FieldValue.delete(),
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
      } else if (field === "farmerId") {
        updates.farmerName = "Deleted User";
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

  // Owned ancillary data.
  await Promise.all([
    db.collection("bank_details").doc(uid).delete(),
    db.collection("chat_keys").doc(uid).delete(),
    db.collection("transporter_profiles").doc(uid).delete(),
  ]);
  await deleteQueryInBatches(db.collection("notifications").where("userId", "==", uid));
  await deleteStoragePrefix(`users/${uid}/`);
  await deleteStoragePrefix(`verification/${uid}/`);

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

  const [buyerOffers, farmerOffers, reviewsWritten, reviewsReceived, disputes,
    notifications, bankSnap, messagesSent, settlements] = await Promise.all([
    db.collection("offers").where("buyerId", "==", uid).limit(200).get(),
    db.collection("offers").where("farmerId", "==", uid).limit(200).get(),
    db.collection("reviews").where("reviewerId", "==", uid).limit(200).get(),
    db.collection("reviews").where("subjectId", "==", uid).limit(200).get(),
    db.collection("disputes").where("openedBy", "==", uid).limit(100).get(),
    db.collection("notifications").where("userId", "==", uid).limit(500).get(),
    db.collection("bank_details").doc(uid).get(),
    db.collection("messages").where("senderId", "==", uid).limit(500).get(),
    db.collection("settlements").where("recipientId", "==", uid).limit(200).get(),
  ]);

  // Also collect verification docs keyed by farmerId for older records
  const verificationByFarmer = await db.collection("verification_docs")
    .where("farmerId", "==", uid).limit(100).get();

  const merge = (...snaps: FirebaseFirestore.QuerySnapshot[]): Record<string, unknown>[] => {
    const map = new Map<string, Record<string, unknown>>();
    for (const snap of snaps) {
      for (const doc of snap.docs) map.set(doc.id, { id: doc.id, ...doc.data() });
    }
    return Array.from(map.values());
  };

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
    orders: merge(buyerOrders, farmerOrders, transporterOrders),
    products: products.docs.map((d) => ({ id: d.id, ...d.data() })),
    verificationDocs: merge(verificationDocs, verificationByFarmer),
    offers: merge(buyerOffers, farmerOffers),
    reviews: merge(reviewsWritten, reviewsReceived),
    disputes: merge(disputes),
    notifications: merge(notifications),
    bankDetails: bankSnap.exists ? bankSnap.data() : null,
    messagesSent: merge(messagesSent),
    settlements: merge(settlements),
  });
});

// ─── Admin: disputes ──────────────────────────────────────────
const DISPUTE_REFUND_PERCENT: Record<string, number> = {
  refund_buyer: 100,
  release_farmer: 0,
  split_settlement: 50,
};

export const resolveDispute = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const resolution = typeof data.resolution === "string" ? data.resolution : "";
  const adminNotes = typeof data.adminNotes === "string" ? data.adminNotes.trim() : "";
  const refundPercent = DISPUTE_REFUND_PERCENT[resolution];
  if (!orderId || refundPercent === undefined || !adminNotes || adminNotes.length > 2000) {
    throw new functions.https.HttpsError(
      "invalid-argument", "A valid decision and audit note are required.");
  }
  const orderRef = db.collection("orders").doc(orderId);
  const result = await db.runTransaction(async (transaction) => {
    const order = (await transaction.get(orderRef)).data();
    if (!order || order.paymentStatus !== "disputed") {
      throw new functions.https.HttpsError("failed-precondition", "This order has no open dispute.");
    }
    const disputeId = typeof order.disputeId === "string" ? order.disputeId : "";
    if (!disputeId) {
      throw new functions.https.HttpsError("failed-precondition", "Dispute record is missing.");
    }
    const disputeRef = db.collection("disputes").doc(disputeId);
    const dispute = (await transaction.get(disputeRef)).data();
    if (!dispute || dispute.status !== "open") {
      throw new functions.https.HttpsError("failed-precondition", "This dispute is already closed.");
    }
    const totalMinor = Number(order.totalMinor);
    if (!Number.isSafeInteger(totalMinor) || totalMinor < 0) {
      throw new functions.https.HttpsError("failed-precondition", "Order total is invalid.");
    }
    const refundMinor = Math.round((totalMinor * refundPercent) / 100);
    const settlementMinor = totalMinor - refundMinor;
    const paymentStatus = refundPercent === 100
      ? "refund_pending"
      : refundPercent === 0 ? "settlement_pending" : "split_settlement_pending";
    transaction.update(orderRef, {
      status: resolution === "refund_buyer" ? "cancelled" : "completed",
      disputeStatus: "resolved",
      disputeResolution: resolution,
      disputeAdminNotes: adminNotes,
      disputeResolvedBy: uid,
      disputeResolvedAt: FieldValue.serverTimestamp(),
      refundPercent,
      refundMinor,
      settlementMinor,
      paymentStatus,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(disputeRef, {
      status: "resolved",
      resolution,
      adminNotes,
      resolvedBy: uid,
      resolvedAt: FieldValue.serverTimestamp(),
      refundPercent,
      refundMinor,
      settlementMinor,
    });
    return {
      disputeId,
      refundMinor,
      settlementMinor,
      paymentStatus,
      buyerId: String(order.buyerId || ""),
      farmerId: String(order.farmerId || ""),
      orderNumber: String(order.orderNumber || orderNumberFor(orderId)),
    };
  });

  const label = resolution === "refund_buyer"
    ? "a full refund to the buyer"
    : resolution === "release_farmer" ? "payment released to the farmer" : "a 50/50 split settlement";
  const body = `The dispute on order ${result.orderNumber} was resolved with ${label}.`;
  await writeNotification(result.buyerId, "Dispute resolved", body, "dispute", orderId,
    { disputeId: result.disputeId });
  await writeNotification(result.farmerId, "Dispute resolved", body, "dispute", orderId,
    { disputeId: result.disputeId });
  await writeAudit(uid, {
    actionType: "DISPUTE_RESOLVED",
    targetEntity: "disputes",
    targetId: result.disputeId,
    details: `${result.orderNumber}: ${resolution} (refund ${refundPercent}%). ${adminNotes}`,
    severity: "critical",
  });
  return {
    success: true,
    disputeId: result.disputeId,
    refundPercent,
    refundMinor: result.refundMinor,
    settlementMinor: result.settlementMinor,
    paymentStatus: result.paymentStatus,
  };
});

// ─── Admin: advisories ────────────────────────────────────────
export const broadcastAdvisory = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const title = requiredString(data.title, "title", 1, 120);
  const body = requiredString(data.body, "message", 1, 2000);
  const audience = typeof data.audience === "string" ? data.audience : "";
  if (!["all", "farmer", "buyer", "transporter"].includes(audience)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid audience.");
  }
  const advisoryRef = db.collection("advisories").doc();
  const baseQuery: FirebaseFirestore.Query = audience === "all"
    ? db.collection("users")
    : db.collection("users").where("role", "==", audience);
  const usersSnap = await baseQuery.select("isSuspended", "isDeleted", "role").get();
  const recipients = usersSnap.docs.filter((doc) => {
    const user = doc.data();
    return user.isSuspended !== true && user.isDeleted !== true;
  });
  for (let i = 0; i < recipients.length; i += 400) {
    const batch = db.batch();
    for (const doc of recipients.slice(i, i + 400)) {
      batch.set(db.collection("notifications").doc(), {
        userId: doc.id,
        title,
        body,
        type: "general",
        referenceId: advisoryRef.id,
        advisoryId: advisoryRef.id,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  await advisoryRef.set({
    title,
    body,
    audience,
    recipients: recipients.length,
    createdBy: uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  await writeAudit(uid, {
    actionType: "ADVISORY_BROADCAST",
    targetEntity: "advisories",
    targetId: advisoryRef.id,
    details: `"${title}" sent to ${audience} (${recipients.length} recipients)`,
    severity: "info",
  });
  return { recipients: recipients.length, advisoryId: advisoryRef.id };
});

// ─── Admin: user management ───────────────────────────────────
export const adminSetUserRole = functions.https.onCall(async (data, context) => {
  const adminUid = await requireAdmin(context);
  const targetUid = typeof data.uid === "string" ? data.uid.trim() : "";
  const role = typeof data.role === "string" ? data.role : "";
  if (!targetUid || !["farmer", "buyer", "transporter", "admin"].includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid user or role.");
  }
  if (targetUid === adminUid) {
    throw new functions.https.HttpsError("failed-precondition", "You cannot change your own role.");
  }
  const ref = db.collection("users").doc(targetUid);
  const snap = await ref.get();
  const user = snap.data();
  if (!user || user.isDeleted === true) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }
  const previousRole = String(user.role || "");
  await ref.update({ role, updatedAt: FieldValue.serverTimestamp() });
  try {
    const authUser = await auth.getUser(targetUid);
    await auth.setCustomUserClaims(targetUid, {
      ...(authUser.customClaims || {}),
      role,
      admin: role === "admin",
    });
    await auth.revokeRefreshTokens(targetUid);
  } catch (err) {
    functions.logger.warn("Custom claim update failed", { targetUid, err });
  }
  if (previousRole === "transporter" || role === "transporter") {
    await syncTransporterProfile(targetUid);
  }
  await writeAudit(adminUid, {
    actionType: "USER_ROLE_CHANGED",
    targetEntity: "users",
    targetId: targetUid,
    details: `${displayNameOf(user, targetUid)}: ${previousRole || "none"} → ${role}`,
    severity: role === "admin" || previousRole === "admin" ? "critical" : "warning",
  });
  return { success: true, uid: targetUid, role };
});

export const adminDeleteUser = functions.https.onCall(async (data, context) => {
  const adminUid = await requireAdmin(context);
  const targetUid = typeof data.uid === "string" ? data.uid.trim() : "";
  if (!targetUid) {
    throw new functions.https.HttpsError("invalid-argument", "uid is required.");
  }
  if (targetUid === adminUid) {
    throw new functions.https.HttpsError("failed-precondition", "You cannot delete your own account.");
  }
  const ref = db.collection("users").doc(targetUid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "User not found.");
  }
  await ref.update({
    isDeleted: true,
    isSuspended: true,
    deletedAt: FieldValue.serverTimestamp(),
    deletedBy: adminUid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  try {
    await auth.updateUser(targetUid, { disabled: true });
    await auth.revokeRefreshTokens(targetUid);
  } catch (err) {
    functions.logger.warn("Auth disable failed", { targetUid, err });
  }
  await db.collection("transporter_profiles").doc(targetUid).delete();
  await writeAudit(adminUid, {
    actionType: "USER_DELETED",
    targetEntity: "users",
    targetId: targetUid,
    details: `Soft-deleted ${displayNameOf(snap.data(), targetUid)}`,
    severity: "critical",
  });
  return { success: true, uid: targetUid };
});

// ─── Withdrawals / settlements ────────────────────────────────
const PAYOUT_METHODS = ["CEFT", "SLIP", "Mobile Wallet"];
const EARNING_PAYMENT_STATUSES = ["paid", "released", "settled_split"];

export const requestWithdrawal = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const user = await requireRole(uid, ["farmer", "transporter"]);
  const role = String(user.role);
  const amount = Number(data.amount);
  const amountMinor = Math.round(amount * 100);
  if (!Number.isFinite(amount) || amount <= 0 || amount > 10000000
    || Math.abs(amount * 100 - amountMinor) > 1e-6) {
    throw new functions.https.HttpsError("invalid-argument", "Enter a valid withdrawal amount.");
  }
  const bankName = requiredString(data.bankName, "bank name", 1, 100);
  const accountNumber = requiredString(data.accountNumber, "account number", 4, 40);
  if (!/^[0-9A-Za-z -]+$/.test(accountNumber)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid account number.");
  }
  const payoutMethod = typeof data.payoutMethod === "string" ? data.payoutMethod : "CEFT";
  if (!PAYOUT_METHODS.includes(payoutMethod)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid payout method.");
  }

  const settlementRef = db.collection("settlements").doc();
  await db.runTransaction(async (transaction) => {
    let earnedMinor = 0;
    if (role === "farmer") {
      const orders = await transaction.get(db.collection("orders")
        .where("farmerId", "==", uid)
        .where("paymentStatus", "in", EARNING_PAYMENT_STATUSES));
      for (const doc of orders.docs) {
        const order = doc.data();
        if (String(order.status) === "cancelled") continue;
        const total = Number(order.totalMinor || 0);
        const fee = Number(order.platformFeeMinor || 0);
        // When a transporter carried the order the delivery fee is theirs.
        const delivery = order.transporterId ? Number(order.deliveryFeeMinor || 0) : 0;
        earnedMinor += Math.max(0, total - fee - delivery);
      }
    } else {
      const jobs = await transaction.get(db.collection("transport_jobs")
        .where("transporterId", "==", uid)
        .where("status", "==", "delivered"));
      for (const doc of jobs.docs) {
        const job = doc.data();
        earnedMinor += Math.max(0, Number(job.deliveryFeeMinor ?? job.offeredFeeMinor ?? 0));
      }
    }
    const previous = await transaction.get(db.collection("settlements")
      .where("recipientId", "==", uid));
    let withdrawnMinor = 0;
    for (const doc of previous.docs) {
      const settlement = doc.data();
      if (settlement.status === "rejected") continue;
      withdrawnMinor += Math.round(Number(settlement.netAmount || 0) * 100);
    }
    const availableMinor = earnedMinor - withdrawnMinor;
    if (amountMinor > availableMinor) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Amount exceeds your available balance (LKR ${(Math.max(0, availableMinor) / 100).toFixed(2)}).`
      );
    }
    transaction.create(settlementRef, {
      orderId: "",
      orderNumber: `WD-${settlementRef.id.slice(0, 8).toUpperCase()}`,
      recipientId: uid,
      recipientName: displayNameOf(user, role === "farmer" ? "Farmer" : "Transporter"),
      recipientRole: role,
      grossAmount: amountMinor / 100,
      platformFee: 0,
      netAmount: amountMinor / 100,
      bankName,
      accountNumber,
      payoutMethod,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  await writeAudit(uid, {
    actionType: "WITHDRAWAL_REQUESTED",
    targetEntity: "settlements",
    targetId: settlementRef.id,
    details: `LKR ${(amountMinor / 100).toFixed(2)} via ${payoutMethod} (${bankName})`,
    severity: "info",
  });
  return { settlementId: settlementRef.id };
});

export const updateSettlementStatus = functions.https.onCall(async (data, context) => {
  const uid = await requireAdmin(context);
  const settlementId = typeof data.settlementId === "string" ? data.settlementId : "";
  const status = typeof data.status === "string" ? data.status : "";
  if (!settlementId || !["settled", "on_hold", "processing", "rejected"].includes(status)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid settlement update.");
  }
  const transactionReference = data.transactionReference == null
    || (typeof data.transactionReference === "string" && data.transactionReference.trim() === "")
    ? "" : requiredString(data.transactionReference, "transaction reference", 4, 100);
  if (status === "settled" && !transactionReference) {
    throw new functions.https.HttpsError(
      "invalid-argument", "A transaction reference is required to mark a payout settled.");
  }
  const holdReason = data.holdReason == null
    ? "" : requiredString(data.holdReason, "hold reason", 0, 300);
  const ref = db.collection("settlements").doc(settlementId);
  const settlement = await db.runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    if (!current) {
      throw new functions.https.HttpsError("not-found", "Settlement not found.");
    }
    if (["settled", "rejected"].includes(String(current.status))) {
      throw new functions.https.HttpsError("failed-precondition", "This payout is already closed.");
    }
    transaction.update(ref, {
      status,
      ...(transactionReference ? { transactionReference } : {}),
      ...(status === "on_hold" || status === "rejected"
        ? { holdReason: holdReason || FieldValue.delete() }
        : { holdReason: FieldValue.delete() }),
      ...(status === "settled" ? { settledAt: FieldValue.serverTimestamp() } : {}),
      reviewedBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return current;
  });
  const amountLabel = `LKR ${Number(settlement.netAmount || 0).toFixed(2)}`;
  const messages: Record<string, [string, string]> = {
    settled: ["Payout sent", `Your payout of ${amountLabel} was sent (ref ${transactionReference}).`],
    processing: ["Payout processing", `Your payout of ${amountLabel} is being processed.`],
    on_hold: ["Payout on hold", `Your payout of ${amountLabel} is on hold${holdReason ? `: ${holdReason}` : "."}`],
    rejected: ["Payout rejected", `Your payout of ${amountLabel} was rejected${holdReason ? `: ${holdReason}` : "."}`],
  };
  const [title, body] = messages[status];
  await writeNotification(String(settlement.recipientId || ""), title, body, "payment", undefined,
    { settlementId });
  await writeAudit(uid, {
    actionType: `SETTLEMENT_${status.toUpperCase()}`,
    targetEntity: "settlements",
    targetId: settlementId,
    details: `${settlement.orderNumber || settlementId} ${amountLabel} → ${status}${transactionReference ? ` (ref ${transactionReference})` : ""}${holdReason ? ` — ${holdReason}` : ""}`,
    severity: status === "settled" || status === "rejected" ? "warning" : "info",
  });
  return { success: true, status };
});

// ─── Farmer: product media / QR ───────────────────────────────
const HARVEST_STATUSES = ["growing", "harvested", "packed", "inTransit", "delivered"];

const requireOwnedProduct = async (
  uid: string,
  productId: unknown
): Promise<{ ref: FirebaseFirestore.DocumentReference; product: Record<string, any> }> => {
  const id = typeof productId === "string" ? productId : "";
  if (!id) throw new functions.https.HttpsError("invalid-argument", "productId is required.");
  const ref = db.collection("products").doc(id);
  const product = (await ref.get()).data();
  if (!product || product.farmerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Product not found.");
  }
  return { ref, product };
};

export const setProductMedia = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const { ref, product } = await requireOwnedProduct(uid, data.productId);
  const updates: Record<string, unknown> = {};
  let oldVideoToDelete = "";
  if (data.clearVideo === true) {
    oldVideoToDelete = typeof product.videoPath === "string" ? product.videoPath : "";
    updates.videoPath = FieldValue.delete();
    updates.videoUrl = FieldValue.delete();
  } else {
    if (data.videoPath !== undefined) {
      const videoPath = requiredString(data.videoPath, "video path", 1, 1024);
      if (videoPath.includes("..") || !(videoPath.startsWith(`product_videos/${uid}/`)
        || videoPath.startsWith(`products/${ref.id}/`))) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid video path.");
      }
      if (typeof product.videoPath === "string" && product.videoPath !== videoPath) {
        oldVideoToDelete = product.videoPath;
      }
      updates.videoPath = videoPath;
    }
    if (data.videoUrl !== undefined) {
      const videoUrl = requiredString(data.videoUrl, "video URL", 9, 2048);
      if (!videoUrl.startsWith("https://")) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid video URL.");
      }
      updates.videoUrl = videoUrl;
    }
  }
  if (data.harvestStatus !== undefined) {
    if (typeof data.harvestStatus !== "string" || !HARVEST_STATUSES.includes(data.harvestStatus)) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid harvest status.");
    }
    updates.harvestStatus = data.harvestStatus;
  }
  if (data.harvestDate !== undefined) {
    updates.harvestDate = optionalIsoDate(data.harvestDate, "harvest date");
  }
  if (Object.keys(updates).length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "No media changes supplied.");
  }
  await ref.update({ ...updates, updatedAt: FieldValue.serverTimestamp() });
  if (oldVideoToDelete && (oldVideoToDelete.startsWith(`product_videos/${uid}/`)
    || oldVideoToDelete.startsWith(`products/${ref.id}/`))) {
    try {
      await admin.storage().bucket().file(oldVideoToDelete).delete();
    } catch (err) {
      functions.logger.warn("Old product video delete failed", { productId: ref.id, err });
    }
  }
  return { success: true };
});

export const generateProductQr = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const { ref, product } = await requireOwnedProduct(uid, data.productId);
  const qrCode = `farmora://product/${ref.id}`;
  await ref.update({
    qrCode,
    ...(product.packingDate ? {} : { packingDate: new Date().toISOString() }),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { qrCode };
});

// ─── Farmer: transport + handover ─────────────────────────────
export const cancelTransportRequest = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const jobId = typeof data.jobId === "string" ? data.jobId : "";
  if (!jobId) throw new functions.https.HttpsError("invalid-argument", "jobId is required.");
  const ref = db.collection("transport_jobs").doc(jobId);
  const job = await db.runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    if (!current || current.farmerId !== uid) {
      throw new functions.https.HttpsError("permission-denied", "Transport request not found.");
    }
    if (current.status !== "requested") {
      throw new functions.https.HttpsError(
        "failed-precondition", "Only open transport requests can be cancelled.");
    }
    transaction.update(ref, {
      status: "cancelled",
      cancelledBy: uid,
      cancelledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return current;
  });
  const targeted = String(job.transporterId || job.requestedTransporterId || "");
  if (targeted) {
    await writeNotification(
      targeted,
      "Delivery request cancelled",
      `The farmer cancelled the delivery request for ${job.productName || "an order"}.`,
      "logistics",
      job.orderId ? String(job.orderId) : undefined,
      { jobId }
    );
  }
  return { success: true };
});

export const confirmHandover = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  await requireRole(uid, ["farmer"]);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  if (!orderId) throw new functions.https.HttpsError("invalid-argument", "orderId is required.");
  const ref = db.collection("orders").doc(orderId);
  const order = (await ref.get()).data();
  if (!order || order.farmerId !== uid) {
    throw new functions.https.HttpsError("permission-denied", "Order not found.");
  }
  if (!["assigned", "pickedUp"].includes(String(order.status))) {
    throw new functions.https.HttpsError(
      "failed-precondition", "Handover is available once a transporter is assigned.");
  }
  await ref.update({
    farmerHandedOverAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  if (order.buyerId) {
    await writeNotification(
      String(order.buyerId),
      "Order handed over",
      `The farmer handed over ${order.productName || "your order"} to the transporter.`,
      "order",
      orderId
    );
  }
  return { success: true };
});

// ─── Bank deposit details (buyer-facing) ──────────────────────
// {farmerId} -> {available}; {orderId} (buyer of a bank_deposit order) -> full details.
export const getFarmerBankDetails = functions.https.onCall(async (data, context) => {
  const uid = requireAuth(context);
  const orderId = typeof data.orderId === "string" ? data.orderId : "";
  const farmerId = typeof data.farmerId === "string" ? data.farmerId : "";
  if (orderId) {
    const order = (await db.collection("orders").doc(orderId).get()).data();
    if (!order || (order.buyerId !== uid && order.farmerId !== uid)) {
      throw new functions.https.HttpsError("permission-denied", "Order not found.");
    }
    if (order.paymentMethod !== "bank_deposit") {
      throw new functions.https.HttpsError(
        "failed-precondition", "This order is not paid by bank deposit.");
    }
    const snapshot = order.bankDetailsSnapshot as Record<string, unknown> | undefined;
    const bank = snapshot && snapshot.accountNumber
      ? snapshot
      : (await db.collection("bank_details").doc(String(order.farmerId)).get()).data();
    if (!isUsableBank(bank as Record<string, any> | undefined)) return { available: false };
    return {
      available: true,
      bankName: String(bank!.bankName),
      branch: String(bank!.branch),
      accountHolderName: String(bank!.accountHolderName),
      accountNumber: String(bank!.accountNumber),
    };
  }
  if (!farmerId) {
    throw new functions.https.HttpsError("invalid-argument", "farmerId or orderId is required.");
  }
  const bank = (await db.collection("bank_details").doc(farmerId).get()).data();
  return { available: isUsableBank(bank) };
});

// ─── Payment status notifications ─────────────────────────────
export const onOrderPaymentStatusChanged = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.paymentStatus === after.paymentStatus) return;
    const orderId = context.params.orderId as string;
    const orderNumber = String(after.orderNumber || orderNumberFor(orderId));
    const productLabel = String(after.productName || "your order");
    switch (after.paymentStatus) {
      case "proof_submitted":
        if (after.farmerId) {
          await writeNotification(String(after.farmerId), "Payment proof submitted",
            `The buyer uploaded a bank deposit slip for ${orderNumber} (${productLabel}). Please verify it.`,
            "payment", orderId);
        }
        break;
      case "paid":
        if (after.buyerId) {
          await writeNotification(String(after.buyerId), "Payment confirmed",
            `Your payment for ${orderNumber} (${productLabel}) was confirmed.`,
            "payment", orderId);
        }
        break;
      case "rejected":
        if (after.buyerId) {
          const reason = typeof after.rejectionReason === "string" && after.rejectionReason
            ? `: ${after.rejectionReason}` : ".";
          await writeNotification(String(after.buyerId), "Payment proof rejected",
            `The farmer rejected the deposit slip for ${orderNumber}${reason} Please upload a new slip.`,
            "payment", orderId);
        }
        break;
      default:
        break;
    }
  });
