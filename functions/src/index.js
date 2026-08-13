"use strict";

const { onCall, HttpsError, onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

const mp = require("./mercadopago");
const sub = require("./subscription");
const pairing = require("./device_pairing");

admin.initializeApp();

setGlobalOptions({
  region: "southamerica-east1",
  maxInstances: 20,
});

const mpAccessToken = defineSecret("MERCADOPAGO_ACCESS_TOKEN");
/** Opcional no sandbox; recomendado em produção (painel Webhooks → secret). */
const mpWebhookSecret = defineString("MERCADOPAGO_WEBHOOK_SECRET", {
  default: "",
});

/** R$ 118,80 — alinhado a docs/subscription_trial_7d.md */
const ANNUAL_VALUE_BRL = 118.8;

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
        accessToken: mpAccessToken.value(),
        uid,
        email,
        name,
        amount: ANNUAL_VALUE_BRL,
        description: "Guardian Sense — assinatura anual (12 meses)",
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
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        e.message || "Não foi possível gerar o PIX.",
      );
    }
  },
);

/**
 * Webhook Mercado Pago — só o backend grava status=active (store: pix).
 *
 * Painel Developers → sua aplicação → Webhooks:
 * - URL: …/mercadopagoPixWebhook
 * - Eventos: Pagamentos (payment)
 * - Secret → MERCADOPAGO_WEBHOOK_SECRET
 *
 * Sempre confirma com GET /v1/payments/{id} (não confia só no body).
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

    const secret = mpWebhookSecret.value();
    const xSignature = req.get("x-signature") || "";
    const xRequestId = req.get("x-request-id") || "";
    const dataId = String(req.body?.data?.id || paymentId).toLowerCase();

    if (
      secret &&
      !mp.verifyWebhookSignature({
        secret,
        xSignature,
        xRequestId,
        dataId,
      })
    ) {
      console.warn("Webhook MP assinatura inválida", paymentId);
      res.status(401).send("Unauthorized");
      return;
    }

    try {
      const fresh = await mp.getPayment({
        accessToken: mpAccessToken.value(),
        paymentId,
      });

      const uid =
        fresh.external_reference ||
        fresh.metadata?.uid ||
        null;

      if (!uid) {
        console.warn("Webhook MP sem external_reference", paymentId);
        res.status(200).send("OK");
        return;
      }

      const status = String(fresh.status || "").toLowerCase();

      if (status === "approved") {
        await sub.activateAnnualFromPix({
          uid,
          pixPaymentId: String(fresh.id),
          amount: fresh.transaction_amount,
        });
      } else if (
        ["refunded", "charged_back", "cancelled"].includes(status)
      ) {
        await sub.lapseFromPixRefund({
          uid,
          pixPaymentId: String(fresh.id),
        });
      }

      res.status(200).send("OK");
    } catch (e) {
      console.error("mercadopagoPixWebhook", e);
      res.status(500).send("Error");
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
