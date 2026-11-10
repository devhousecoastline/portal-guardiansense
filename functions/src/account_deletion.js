"use strict";

const crypto = require("node:crypto");
const admin = require("firebase-admin");

/** Contrato do app: `auth_time` com mais de 5 min pede login de novo. */
const RECENT_LOGIN_MAX_AGE_S = 300;
const BATCH_LIMIT = 400;

function db() {
  return admin.firestore();
}

/** Chave de `deletedAccounts` — nunca guardar o e-mail em claro. */
function deletedAccountHash(email) {
  const normalized = String(email || "").trim().toLowerCase();
  if (!normalized) return null;
  return crypto.createHash("sha256").update(normalized).digest("hex");
}

function isRecentLogin(authTimeSeconds, nowMs = Date.now()) {
  const authTime = Number(authTimeSeconds);
  if (!Number.isFinite(authTime) || authTime <= 0) return false;
  return Math.floor(nowMs / 1000) - authTime <= RECENT_LOGIN_MAX_AGE_S;
}

async function markTrialUsed(email) {
  const hash = deletedAccountHash(email);
  if (!hash) return false;
  await db().collection("deletedAccounts").doc(hash).set(
    {
      trialUsed: true,
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return true;
}

/** Mantém a cobrança (fiscal / estorno), sem vínculo com a conta. */
async function anonymizePixPayments(uid) {
  const snap = await db()
    .collection("pixPayments")
    .where("uid", "==", uid)
    .get();

  for (let i = 0; i < snap.docs.length; i += BATCH_LIMIT) {
    const batch = db().batch();
    for (const doc of snap.docs.slice(i, i + BATCH_LIMIT)) {
      batch.update(doc.ref, {
        uid: admin.firestore.FieldValue.delete(),
        anonymizedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  return snap.size;
}

async function deleteAuthUser(uid) {
  try {
    await admin.auth().deleteUser(uid);
    return true;
  } catch (e) {
    if (e?.code === "auth/user-not-found") return false;
    throw e;
  }
}

/**
 * Apaga a conta e os dados na nuvem. O Auth vai por último: se algo falhar
 * no meio, o usuário ainda consegue entrar e repetir.
 */
async function deleteAccount({ uid, email }) {
  const trialMarked = await markTrialUsed(email);
  const pixAnonymized = await anonymizePixPayments(uid);
  await db().collection("welcomeEmails").doc(uid).delete();
  await db().recursiveDelete(db().collection("users").doc(uid));
  const authDeleted = await deleteAuthUser(uid);

  console.info("deleteAccount: ok", {
    trialMarked,
    pixAnonymized,
    authDeleted,
  });
}

function expiredTrialSubscription(now) {
  return {
    status: "expired",
    trialStartedAt: now,
    trialEndsAt: now,
    plan: "annual_12m",
    updatedAt: now,
  };
}

/**
 * Auth onCreate: e-mail de conta já excluída não ganha trial de novo.
 * Sobrescreve o trial que o cliente cria no 1º login.
 */
async function applyDeletedAccountTrial(user) {
  const uid = String(user?.uid || "").trim();
  const hash = deletedAccountHash(user?.email);
  if (!uid || !hash) return false;

  const marker = await db().collection("deletedAccounts").doc(hash).get();
  if (!marker.exists || marker.data()?.trialUsed !== true) return false;

  const now = admin.firestore.Timestamp.now();
  await db().collection("users").doc(uid).set(
    { subscription: expiredTrialSubscription(now) },
    { merge: true },
  );
  console.info("applyDeletedAccountTrial: trial encerrado (conta recriada)");
  return true;
}

module.exports = {
  RECENT_LOGIN_MAX_AGE_S,
  deletedAccountHash,
  isRecentLogin,
  expiredTrialSubscription,
  deleteAccount,
  applyDeletedAccountTrial,
};
