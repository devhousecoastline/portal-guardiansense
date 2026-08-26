"use strict";

const admin = require("firebase-admin");

const PLAN = "annual_12m";
const ANNUAL_MS = 365 * 24 * 60 * 60 * 1000;

/**
 * Grava entitlement ativo (só Admin SDK). Idempotente por pixPaymentId.
 */
async function activateAnnualFromPix({ uid, pixPaymentId, amount }) {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const payRef = db.collection("pixPayments").doc(pixPaymentId);

  await db.runTransaction(async (tx) => {
    const paySnap = await tx.get(payRef);
    const pay = paySnap.data() || {};

    if (pay.status === "applied" && pay.uid === uid) {
      return;
    }

    const userSnap = await tx.get(userRef);
    const existing = userSnap.data()?.subscription || {};
    const now = admin.firestore.Timestamp.now();
    const expires = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + ANNUAL_MS,
    );

    const subscription = {
      status: "active",
      trialStartedAt: existing.trialStartedAt || now,
      trialEndsAt: existing.trialEndsAt || now,
      plan: PLAN,
      startedAt: now,
      expiresAt: expires,
      store: "pix",
      productId: PLAN,
      purchaseTokenFingerprint: null,
      pixPaymentId,
      updatedAt: now,
    };

    tx.set(
      userRef,
      {
        subscription,
        plan: "premium",
        deviceLimit: 1,
      },
      { merge: true },
    );
    tx.set(
      payRef,
      {
        uid,
        status: "applied",
        plan: PLAN,
        amount: amount ?? pay.amount ?? null,
        store: "pix",
        appliedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
  });
}

/**
 * Estorno / chargeback → lapsed se o paymentId for o da assinatura atual.
 */
async function lapseFromPixRefund({ uid, pixPaymentId }) {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const payRef = db.collection("pixPayments").doc(pixPaymentId);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const sub = userSnap.data()?.subscription || {};
    const now = admin.firestore.Timestamp.now();

    if (sub.pixPaymentId === pixPaymentId && sub.status === "active") {
      tx.set(
        userRef,
        {
          subscription: {
            ...sub,
            status: "lapsed",
            updatedAt: now,
          },
          plan: "free",
        },
        { merge: true },
      );
    }

    tx.set(
      payRef,
      {
        uid,
        status: "refunded",
        updatedAt: now,
        refundedAt: now,
      },
      { merge: true },
    );
  });
}

async function markPaymentPending({
  uid,
  pixPaymentId,
  amount,
  provider,
}) {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  await db.collection("pixPayments").doc(String(pixPaymentId)).set(
    {
      uid,
      status: "pending",
      plan: PLAN,
      amount,
      store: "pix",
      provider: provider || "mercadopago",
      createdAt: now,
      updatedAt: now,
    },
    { merge: true },
  );
}

module.exports = {
  PLAN,
  activateAnnualFromPix,
  lapseFromPixRefund,
  markPaymentPending,
};
