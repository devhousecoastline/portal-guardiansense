"use strict";

/**
 * Cliente HTTP mínimo — Mercado Pago Checkout API (PIX).
 * Docs: https://www.mercadopago.com.br/developers/docs
 */

const crypto = require("crypto");

const API_BASE = "https://api.mercadopago.com";

async function mpFetch({ accessToken, method, path, body, idempotencyKey }) {
  const headers = {
    Authorization: `Bearer ${accessToken}`,
    "Content-Type": "application/json",
    "User-Agent": "guardian-portal-functions",
  };
  if (idempotencyKey) {
    headers["X-Idempotency-Key"] = idempotencyKey;
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body == null ? undefined : JSON.stringify(body),
  });

  const text = await res.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch (_) {
    json = { raw: text };
  }

  if (!res.ok) {
    const msg =
      json?.message ||
      json?.cause?.[0]?.description ||
      json?.error ||
      `Mercado Pago HTTP ${res.status}`;
    const err = new Error(msg);
    err.status = res.status;
    err.mercadopago = json;
    throw err;
  }
  return json;
}

/**
 * Cria pagamento PIX. Retorna payment completo (inclui QR em point_of_interaction).
 */
async function createPixPayment({
  accessToken,
  uid,
  email,
  name,
  amount,
  description,
  notificationUrl,
}) {
  const payer = {
    email: email || `uid-${uid.slice(0, 12)}@guardiansense.local`,
  };
  if (name && typeof name === "string") {
    const parts = name.trim().split(/\s+/);
    if (parts[0]) payer.first_name = parts[0];
    if (parts.length > 1) payer.last_name = parts.slice(1).join(" ");
  }

  const body = {
    transaction_amount: amount,
    description,
    payment_method_id: "pix",
    payer,
    external_reference: uid,
    metadata: {
      uid,
      plan: "annual_12m",
      product: "guardian_premium_annual",
    },
  };

  if (notificationUrl) {
    body.notification_url = notificationUrl;
  }

  return mpFetch({
    accessToken,
    method: "POST",
    path: "/v1/payments",
    body,
    idempotencyKey: crypto.randomUUID(),
  });
}

/** URL pública da Function de webhook (Cloud Functions v2). */
function pixWebhookPublicUrl() {
  const project =
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    "guardian-sense-dbdfa";
  return `https://southamerica-east1-${project}.cloudfunctions.net/mercadopagoPixWebhook`;
}

/**
 * Access Token (TEST-/APP_USR-) não é a assinatura secreta do webhook.
 * Se o param estiver com token, o HMAC nunca bate.
 */
function looksLikeAccessToken(value) {
  return /^(TEST-|APP_USR-)/i.test(String(value || "").trim());
}

async function getPayment({ accessToken, paymentId }) {
  return mpFetch({
    accessToken,
    method: "GET",
    path: `/v1/payments/${encodeURIComponent(String(paymentId))}`,
  });
}

function extractPixFromPayment(payment) {
  const tx = payment?.point_of_interaction?.transaction_data || {};
  return {
    paymentId: String(payment.id),
    copyPaste: tx.qr_code || null,
    encodedImage: tx.qr_code_base64 || null,
    expirationDate: payment.date_of_expiration || tx.ticket_url || null,
    status: payment.status || null,
  };
}

/**
 * Valida assinatura de webhook (x-signature) quando o secret está configurado.
 * Manifesto: id e request-id só entram se existirem (docs MP).
 * data.id do HMAC vem do query param, em minúsculas.
 * https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks
 */
function verifyWebhookSignature({
  secret,
  xSignature,
  xRequestId,
  dataId,
}) {
  if (!secret) return true;
  if (looksLikeAccessToken(secret)) return true;
  if (!xSignature) return false;

  const parts = {};
  for (const piece of String(xSignature).split(",")) {
    const trimmed = piece.trim();
    const eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    parts[trimmed.slice(0, eq)] = trimmed.slice(eq + 1);
  }
  const ts = parts.ts;
  const hash = parts.v1;
  if (!ts || !hash) return false;

  const id = dataId ? String(dataId).toLowerCase() : "";
  const requestId = xRequestId ? String(xRequestId) : "";
  const chunks = [];
  if (id) chunks.push(`id:${id}`);
  if (requestId) chunks.push(`request-id:${requestId}`);
  chunks.push(`ts:${ts}`);
  const manifest = `${chunks.join(";")};`;

  const expected = crypto
    .createHmac("sha256", secret)
    .update(manifest)
    .digest("hex");
  const incoming = String(hash).toLowerCase();
  const expectedNorm = expected.toLowerCase();

  try {
    const a = Buffer.from(expectedNorm, "utf8");
    const b = Buffer.from(incoming, "utf8");
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  } catch (_) {
    return expectedNorm === incoming;
  }
}

/** data.id do query (assinatura) — fallback para o body. */
function extractSignatureDataId(req) {
  const fromQuery = req.query?.["data.id"] ?? req.query?.data?.id;
  const fromBody = req.body?.data?.id;
  const raw = fromQuery ?? fromBody;
  return raw == null ? "" : String(raw).toLowerCase();
}

/**
 * Extrai payment id do body (webhook novo) ou query (IPN legado).
 */
function extractPaymentIdFromRequest(req) {
  const fromData = req.body?.data?.id;
  if (fromData != null) return String(fromData);

  const fromQueryData = req.query?.["data.id"];
  if (fromQueryData != null) return String(fromQueryData);

  const topic = req.query?.topic || req.query?.type || req.body?.type;
  const id = req.query?.id;
  if (
    id != null &&
    (topic === "payment" || req.body?.action?.startsWith?.("payment."))
  ) {
    return String(id);
  }

  if (req.body?.action?.startsWith?.("payment.") && req.body?.data?.id) {
    return String(req.body.data.id);
  }

  return null;
}

module.exports = {
  createPixPayment,
  getPayment,
  extractPixFromPayment,
  verifyWebhookSignature,
  extractPaymentIdFromRequest,
  extractSignatureDataId,
  looksLikeAccessToken,
  pixWebhookPublicUrl,
};
