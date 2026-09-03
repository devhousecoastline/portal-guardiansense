"use strict";

const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const functionsV1 = require("firebase-functions/v1");
const admin = require("firebase-admin");

const mp = require("./mercadopago");
const sub = require("./subscription");
const pairing = require("./device_pairing");
const welcome = require("./welcome_email");

admin.initializeApp();

setGlobalOptions({
  region: "southamerica-east1",
  maxInstances: 20,
});

const mpAccessToken = defineSecret("MERCADOPAGO_ACCESS_TOKEN");
const sendgridApiKey = defineSecret("SENDGRID_API_KEY");
/** Opcional no sandbox; recomendado em produção (painel Webhooks → secret). */
const mpWebhookSecret = defineString("MERCADOPAGO_WEBHOOK_SECRET", {
  default: "",
});

/** R$ 118,80 — alinhado a docs/subscription_trial_7d.md */
const ANNUAL_VALUE_BRL = 118.8;

function requireMpAccessToken() {
  const token = String(mpAccessToken.value() || "").trim();
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "Access Token do Mercado Pago não configurado. "
        + "Configure MERCADOPAGO_ACCESS_TOKEN no Firebase.",
    );
  }
  return token;
}

function mapMercadoPagoError(e) {
  if (e instanceof HttpsError) return e;
  const status = e.status;
  const code = String(e.mercadopago?.code || "").toLowerCase();
  const msg = String(e.message || "").toLowerCase();
  if (
    status === 401 ||
    code === "unauthorized" ||
    msg.includes("authorization value not present")
  ) {
    throw new HttpsError(
      "failed-precondition",
      "Access Token do Mercado Pago inválido ou vazio. "
        + "Cole de novo o token de produção (APP_USR-...) no secret.",
    );
  }
  throw new HttpsError("internal", e.message || "Não foi possível gerar o PIX.");
}

/**
 * Callable autenticada: gera cobrança PIX anual + QR / copia-cola (Mercado Pago).
 */
exports.createPixAnnualPayment = onCall(
  {
    secrets: [mpAccessToken],
    invoker: "public",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Faça login para assinar.");
    }

    const uid = request.auth.uid;
    const email = request.auth.token.email || null;
    const name =
      request.auth.token.name ||
      (typeof request.data?.name === "string" ? request.data.name : null);

    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    const existing = userSnap.data()?.subscription;
    if (existing?.status === "active") {
      const expiresAt = existing.expiresAt?.toDate?.() || null;
      if (!expiresAt || expiresAt.getTime() > Date.now()) {
        throw new HttpsError(
          "already-exists",
          "Sua assinatura anual já está ativa.",
        );
      }
    }

    try {
      const payment = await mp.createPixPayment({
        accessToken: requireMpAccessToken(),
        uid,
        email,
        name,
        amount: ANNUAL_VALUE_BRL,
        description: "Guardian Sense — assinatura anual (12 meses)",
        notificationUrl: mp.pixWebhookPublicUrl(),
      });

      const pix = mp.extractPixFromPayment(payment);
      if (!pix.copyPaste) {
        throw new Error("Mercado Pago não retornou o código PIX.");
      }

      await sub.markPaymentPending({
        uid,
        pixPaymentId: pix.paymentId,
        amount: ANNUAL_VALUE_BRL,
        provider: "mercadopago",
      });

      return {
        paymentId: pix.paymentId,
        amount: ANNUAL_VALUE_BRL,
        currency: "BRL",
        plan: sub.PLAN,
        encodedImage: pix.encodedImage,
        copyPaste: pix.copyPaste,
        expirationDate: pix.expirationDate,
      };
    } catch (e) {
      console.error("createPixAnnualPayment", e);
      mapMercadoPagoError(e);
    }
  },
);

/**
 * Confirma o pagamento na API do MP e aplica entitlement.
 * Fonte da verdade: GET /v1/payments/{id} com o Access Token (não o body).
 */
async function applyFetchedPayment(fresh) {
  const uid = String(
    fresh.external_reference || fresh.metadata?.uid || "",
  ).trim();
  const status = String(fresh.status || "").toLowerCase();
  const method = String(fresh.payment_method_id || "").toLowerCase();

  if (!uid) {
    return { uid: null, status, applied: false };
  }

  if (method && method !== "pix") {
    console.warn("Pagamento ignorado: método não é PIX", fresh.id, method);
    return { uid, status, applied: false };
  }

  if (status === "approved") {
    await sub.activateAnnualFromPix({
      uid,
      pixPaymentId: String(fresh.id),
      amount: fresh.transaction_amount,
    });
    return { uid, status, applied: true };
  }

  if (["refunded", "charged_back", "cancelled"].includes(status)) {
    await sub.lapseFromPixRefund({
      uid,
      pixPaymentId: String(fresh.id),
    });
    return { uid, status, applied: true };
  }

  return { uid, status, applied: false };
}

/**
 * Webhook Mercado Pago — só o backend grava status=active (store: pix).
 *
 * Painel Developers → sua aplicação → Webhooks:
 * - URL: …/mercadopagoPixWebhook
 * - Eventos: Pagamentos (payment)
 * - Secret → MERCADOPAGO_WEBHOOK_SECRET (assinatura secreta, NÃO o Access Token)
 *
 * Sempre confirma com GET /v1/payments/{id} (não confia só no body).
 * HMAC inválido não bloqueia: o GET autenticado é a prova. 401 impedia a ativação.
 */
exports.mercadopagoPixWebhook = onRequest(
  {
    secrets: [mpAccessToken],
    invoker: "public",
  },
  async (req, res) => {
    if (req.method !== "POST" && req.method !== "GET") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // MP às vezes faz GET de verificação na URL do webhook.
    if (req.method === "GET") {
      res.status(200).send("OK");
      return;
    }

    const paymentId = mp.extractPaymentIdFromRequest(req);
    if (!paymentId) {
      res.status(200).send("OK");
      return;
    }

    const secret = String(mpWebhookSecret.value() || "").trim();
    const xSignature = req.get("x-signature") || "";
    const xRequestId = req.get("x-request-id") || "";
    const dataId =
      mp.extractSignatureDataId(req) || String(paymentId).toLowerCase();

    if (mp.looksLikeAccessToken(secret)) {
      console.warn(
        "MERCADOPAGO_WEBHOOK_SECRET parece Access Token. Use a assinatura secreta do painel Webhooks. HMAC ignorado.",
      );
    } else if (secret) {
      const signed = mp.verifyWebhookSignature({
        secret,
        xSignature,
        xRequestId,
        dataId,
      });
      const signedNoReqId =
        signed ||
        mp.verifyWebhookSignature({
          secret,
          xSignature,
          xRequestId: "",
          dataId,
        });
      if (!signedNoReqId) {
        console.warn(
          "Webhook MP HMAC não conferiu; confirmando via GET /v1/payments",
          paymentId,
        );
      }
    }

    try {
      const fresh = await mp.getPayment({
        accessToken: requireMpAccessToken(),
        paymentId,
      });

      const result = await applyFetchedPayment(fresh);
      if (!result.uid) {
        console.warn("Webhook MP sem external_reference", paymentId);
      }

      res.status(200).send("OK");
    } catch (e) {
      console.error("mercadopagoPixWebhook", e);
      res.status(500).send("Error");
    }
  },
);

/**
 * Callable autenticada: o portal consulta o PIX (botão "Já paguei" / poll).
 * Mesma regra do webhook — só ativa se o MP confirmar approved.
 */
exports.confirmPixPayment = onCall(
  {
    secrets: [mpAccessToken],
    invoker: "public",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Faça login para confirmar.");
    }

    const paymentId = String(request.data?.paymentId || "").trim();
    if (!paymentId) {
      throw new HttpsError("invalid-argument", "Informe o pagamento PIX.");
    }

    try {
      const fresh = await mp.getPayment({
        accessToken: requireMpAccessToken(),
        paymentId,
      });

      const uid = String(
        fresh.external_reference || fresh.metadata?.uid || "",
      ).trim();
      if (!uid || uid !== request.auth.uid) {
        throw new HttpsError(
          "permission-denied",
          "Este PIX não pertence à sua conta.",
        );
      }

      const result = await applyFetchedPayment(fresh);
      return {
        status: result.status || String(fresh.status || "unknown"),
        active: result.status === "approved",
      };
    } catch (e) {
      console.error("confirmPixPayment", e);
      if (e instanceof HttpsError) throw e;
      mapMercadoPagoError(e);
    }
  },
);

/**
 * Portal autenticado: gera QR de verificação de identidade do aparelho.
 */
exports.createDevicePairing = onCall(
  { invoker: "public" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Faça login para vincular.");
    }
    try {
      return await pairing.createDevicePairing(request.auth.uid, {
        refresh: request.data?.refresh === true,
      });
    } catch (e) {
      console.error("createDevicePairing", e);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        e.message || "Não foi possível gerar o QR.",
      );
    }
  },
);

/**
 * App autenticado na mesma conta: confirma o QR e marca o aparelho
 * como ativo e verificado. Sem isso o portal não sincroniza.
 */
exports.confirmDevicePairing = onCall(
  { invoker: "public" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Entre no app com a mesma conta.");
    }
    try {
      return await pairing.confirmDevicePairing(request.auth.uid, request.data);
    } catch (e) {
      console.error("confirmDevicePairing", e);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        e.message || "Não foi possível confirmar o aparelho.",
      );
    }
  },
);

/**
 * Auth onCreate (1ª gen): boas-vindas no cadastro, app ou portal.
 * v2 identity não tem onCreate; Auth 1ª gen só em us-central1.
 */
exports.sendWelcomeEmail = functionsV1
  .region("us-central1")
  .runWith({
    secrets: [sendgridApiKey],
    maxInstances: 20,
    timeoutSeconds: 60,
    memory: "256MB",
  })
  .auth.user()
  .onCreate(async (user) => {
    await welcome.handleUserCreated(user, {
      apiKey: sendgridApiKey.value(),
    });
  });

/**
 * Debug/QA autenticado: remove a verificação para retestar o QR.
 */
exports.resetDeviceVerification = onCall(
  { invoker: "public" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Faça login para resetar.");
    }
    try {
      return await pairing.resetDeviceVerification(request.auth.uid);
    } catch (e) {
      console.error("resetDeviceVerification", e);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        e.message || "Não foi possível resetar a verificação.",
      );
    }
  },
);

/**
 * Debug/QA autenticado: reenvia o e-mail de boas-vindas para a conta logada.
 * Só o portal em kDebugMode chama; force ignora welcomeEmails/{uid}.
 */
exports.sendWelcomeEmailTest = onCall(
  {
    secrets: [sendgridApiKey],
    invoker: "public",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Faça login para testar.");
    }

    const email = String(request.auth.token.email || "").trim();
    if (!email) {
      throw new HttpsError(
        "failed-precondition",
        "Sua conta não tem e-mail para receber o teste.",
      );
    }

    try {
      const result = await welcome.sendWelcomeForUser(
        {
          uid: request.auth.uid,
          email,
          displayName: request.auth.token.name || "",
        },
        {
          apiKey: sendgridApiKey.value(),
          force: true,
        },
      );

      if (!result.sent) {
        throw new HttpsError(
          "failed-precondition",
          result.reason === "missing-api-key"
            ? "SENDGRID_API_KEY não configurada."
            : `Não foi possível enviar (${result.reason || "unknown"}).`,
        );
      }

      return { sent: true, email };
    } catch (e) {
      console.error("sendWelcomeEmailTest", e);
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        e.message || "Não foi possível enviar o e-mail de teste.",
      );
    }
  },
);
