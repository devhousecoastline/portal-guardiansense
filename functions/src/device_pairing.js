"use strict";

const crypto = require("crypto");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

/** Mesmo alfabeto do portal (`DevicePairing.codeAlphabet`). */
const ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 6;
const TTL_MS = 5 * 60 * 1000;
const PAIR_ORIGIN = "https://guardian-sense.com";
const MAX_CREATES_PER_HOUR = 20;

function db() {
  return admin.firestore();
}

function randomCode() {
  const bytes = crypto.randomBytes(CODE_LENGTH);
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return code;
}

function normalizeCode(raw) {
  return String(raw || "")
    .trim()
    .toUpperCase()
    .replace(/[^A-Z2-9]/g, "");
}

function pairingUrl(code) {
  return `${PAIR_ORIGIN}/pair?c=${code}`;
}

function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return 0;
}

function serializePairing(id, data) {
  const code = normalizeCode(data.code);
  return {
    pairingId: id,
    code,
    expiresAtMs: toMillis(data.expiresAt),
    pairingUrl: pairingUrl(code),
  };
}

/**
 * Gera (ou reusa) um desafio QR para a sessão logada no portal.
 * Só o dono da conta cria; o app confirma com `confirmDevicePairing`.
 */
async function createDevicePairing(uid, { refresh = false } = {}) {
  const userRef = db().collection("users").doc(uid);
  const col = userRef.collection("devicePairings");
  const now = Date.now();

  const open = await col.where("used", "==", false).limit(8).get();
  const active = open.docs.find((doc) => toMillis(doc.data().expiresAt) > now);

  if (active && !refresh) {
    return serializePairing(active.id, active.data());
  }

  const recent = await col
    .where(
      "createdAt",
      ">",
      admin.firestore.Timestamp.fromMillis(now - 60 * 60 * 1000),
    )
    .get();
  if (recent.size >= MAX_CREATES_PER_HOUR) {
    throw new HttpsError(
      "resource-exhausted",
      "Muitas tentativas. Aguarde um pouco para gerar outro QR.",
    );
  }

  const batch = db().batch();
  for (const doc of open.docs) {
    batch.update(doc.ref, {
      used: true,
      usedAt: admin.firestore.FieldValue.serverTimestamp(),
      invalidated: true,
    });
  }

  const code = randomCode();
  const expiresAt = admin.firestore.Timestamp.fromMillis(now + TTL_MS);
  const createdAt = admin.firestore.Timestamp.fromMillis(now);
  const pairingRef = col.doc();
  batch.set(pairingRef, {
    code,
    createdAt,
    expiresAt,
    used: false,
    deviceId: null,
  });
  await batch.commit();

  return serializePairing(pairingRef.id, {
    code,
    expiresAt,
  });
}

function assertDeviceId(raw) {
  const deviceId = String(raw || "").trim();
  if (!deviceId || deviceId.length > 128) {
    throw new HttpsError(
      "invalid-argument",
      "Identificador do aparelho inválido.",
    );
  }
  return deviceId;
}

function optionalString(raw, max) {
  if (raw == null) return null;
  const value = String(raw).trim();
  if (!value) return null;
  return value.slice(0, max);
}

/**
 * App autenticado na mesma conta: consome o código do QR e marca o aparelho
 * como ativo e verificado. Só esta Function pode gravar `verified` / `verifiedAt`.
 *
 * Payload: { code, deviceId, modelLabel?, platform?, appVersion?, fingerprint? }
 */
async function confirmDevicePairing(uid, data = {}) {
  const code = normalizeCode(data.code);
  if (code.length !== CODE_LENGTH) {
    throw new HttpsError("invalid-argument", "Código inválido.");
  }

  const deviceId = assertDeviceId(data.deviceId);
  const userRef = db().collection("users").doc(uid);
  const col = userRef.collection("devicePairings");
  const nowMs = Date.now();

  const matches = await col.where("code", "==", code).limit(5).get();
  const pairingDoc = matches.docs.find((doc) => {
    const row = doc.data();
    return row.used !== true && toMillis(row.expiresAt) > nowMs;
  });

  if (!pairingDoc) {
    const any = matches.docs[0];
    if (any?.data()?.used === true) {
      throw new HttpsError(
        "already-exists",
        "Este código já foi usado. Gere outro QR no portal.",
      );
    }
    throw new HttpsError(
      "not-found",
      "Código inválido ou expirado. Gere outro QR no portal.",
    );
  }

  const now = admin.firestore.Timestamp.fromMillis(nowMs);
  const deviceRef = userRef.collection("devices").doc(deviceId);
  const modelLabel = optionalString(data.modelLabel, 80);
  const platform = optionalString(data.platform, 16);
  const appVersion = optionalString(data.appVersion, 32);
  const fingerprint = optionalString(data.fingerprint, 128);

  const devicePatch = {
    status: "active",
    verified: true,
    verifiedAt: now,
    verifiedVia: "qr",
    lastSeen: now,
  };
  if (modelLabel) devicePatch.modelLabel = modelLabel;
  if (platform) devicePatch.platform = platform;
  if (appVersion) devicePatch.appVersion = appVersion;
  if (fingerprint) devicePatch.fingerprint = fingerprint;

  await db().runTransaction(async (tx) => {
    const fresh = await tx.get(pairingDoc.ref);
    const row = fresh.data() || {};
    if (row.used === true || toMillis(row.expiresAt) <= Date.now()) {
      throw new HttpsError(
        "already-exists",
        "Este código já foi usado. Gere outro QR no portal.",
      );
    }

    tx.update(pairingDoc.ref, {
      used: true,
      usedAt: now,
      deviceId,
      invalidated: false,
    });
    tx.set(deviceRef, devicePatch, { merge: true });
    tx.set(userRef, { boundDeviceId: deviceId }, { merge: true });
  });

  return {
    deviceId,
    verified: true,
    verifiedVia: "qr",
  };
}

/**
 * QA / debug: tira a verificação dos aparelhos ativos da conta.
 * O portal volta ao QR; o app deve mostrar Confirmar identidade de novo.
 */
async function resetDeviceVerification(uid) {
  const userRef = db().collection("users").doc(uid);
  const snap = await userRef.collection("devices").limit(40).get();
  const batch = db().batch();
  let reset = 0;

  for (const doc of snap.docs) {
    const status = String(doc.data()?.status || "active").toLowerCase();
    if (status === "released") continue;
    batch.set(
      doc.ref,
      {
        verified: false,
        verifiedAt: admin.firestore.FieldValue.delete(),
        verifiedVia: admin.firestore.FieldValue.delete(),
      },
      { merge: true },
    );
    reset += 1;
  }

  batch.set(
    userRef,
    { boundDeviceId: admin.firestore.FieldValue.delete() },
    { merge: true },
  );
  await batch.commit();
  return { reset };
}

module.exports = {
  createDevicePairing,
  confirmDevicePairing,
  resetDeviceVerification,
  normalizeCode,
  pairingUrl,
};
