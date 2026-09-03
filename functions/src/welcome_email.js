"use strict";

const admin = require("firebase-admin");
const {
  buildWelcomeEmail,
  parseFrom,
} = require("./welcome_email_template");

const DEFAULT_FROM = "Guardian Sense <nao-responda@guardian-sense.com>";
const SENDGRID_URL = "https://api.sendgrid.com/v3/mail/send";

function db() {
  return admin.firestore();
}

function logRef(uid) {
  return db().collection("welcomeEmails").doc(uid);
}

function fromAddress() {
  return String(process.env.WELCOME_MAIL_FROM || DEFAULT_FROM).trim();
}

async function alreadySent(uid) {
  const snap = await logRef(uid).get();
  return snap.exists && snap.data()?.status === "sent";
}

async function markSent(uid, { email, messageId }) {
  await logRef(uid).set(
    {
      email: email || null,
      status: "sent",
      provider: "sendgrid",
      messageId: messageId || null,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function sendWithSendGrid({ apiKey, to, displayName }) {
  const from = parseFrom(fromAddress());
  if (!from.email) {
    throw new Error("WELCOME_MAIL_FROM sem endereço de e-mail.");
  }

  const message = buildWelcomeEmail({ displayName, email: to });
  const res = await fetch(SENDGRID_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: to }] }],
      from: from.name
        ? { email: from.email, name: from.name }
        : { email: from.email },
      subject: message.subject,
      content: [
        { type: "text/plain", value: message.text },
        { type: "text/html", value: message.html },
      ],
      categories: ["welcome"],
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`SendGrid ${res.status}: ${body || res.statusText}`);
  }

  return {
    messageId: res.headers.get("x-message-id") || null,
  };
}

/**
 * Envia boas-vindas para o usuário.
 * `force: true` ignora o log (debug/QA / reenvio).
 */
async function sendWelcomeForUser(user, { apiKey, force = false } = {}) {
  const uid = String(user?.uid || "").trim();
  const email = String(user?.email || "").trim();
  const displayName = user?.displayName || "";

  if (!uid) {
    console.warn("sendWelcomeEmail: usuário sem uid");
    return { sent: false, reason: "no-uid" };
  }

  if (!email) {
    console.warn("sendWelcomeEmail: sem e-mail, uid=", uid);
    return { sent: false, reason: "no-email" };
  }

  if (!force && (await alreadySent(uid))) {
    console.info("sendWelcomeEmail: já enviado, uid=", uid);
    return { sent: false, reason: "already-sent" };
  }

  const key = String(apiKey || process.env.SENDGRID_API_KEY || "").trim();
  if (!key) {
    console.error(
      "sendWelcomeEmail: SENDGRID_API_KEY ausente. Cadastro ok; e-mail não enviado.",
    );
    return { sent: false, reason: "missing-api-key" };
  }

  try {
    const result = await sendWithSendGrid({
      apiKey: key,
      to: email,
      displayName,
    });
    await markSent(uid, { email, messageId: result.messageId });
    console.info("sendWelcomeEmail: enviado, uid=", uid, force ? "(force)" : "");
    return { sent: true, email };
  } catch (e) {
    console.error("sendWelcomeEmail: falha ao enviar", uid, e);
    throw e;
  }
}

/**
 * Dispara no Auth onCreate (app ou portal, e-mail/senha ou Google).
 */
async function handleUserCreated(user, { apiKey } = {}) {
  return sendWelcomeForUser(user, { apiKey, force: false });
}

module.exports = {
  DEFAULT_FROM,
  handleUserCreated,
  sendWelcomeForUser,
  sendWithSendGrid,
  alreadySent,
  markSent,
};
