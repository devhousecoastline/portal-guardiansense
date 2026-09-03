"use strict";

const PORTAL_URL = "https://guardian-sense.com";
const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.guardiansense.app";
/** Assets públicos no Hosting (web/email/). */
const LOGO_URL = `${PORTAL_URL}/email/logo.png`;
const HEADER_BG_URL = `${PORTAL_URL}/email/header-bg.png`;
/** Proporção do escudo (630×834), igual ao GuardianLogo do portal. */
const LOGO_HEIGHT = 88;
const LOGO_WIDTH = Math.round(LOGO_HEIGHT * (630 / 834));

function escapeHtml(value) {
  return String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function firstName(displayName) {
  const name = String(displayName || "").trim();
  if (!name) return "";
  return name.split(/\s+/)[0];
}

function greetingLine(displayName) {
  const name = firstName(displayName);
  return name ? `Olá, ${name}` : "Olá";
}

function parseFrom(raw) {
  const value = String(raw || "").trim();
  const match = value.match(/^(.*)<([^>]+)>$/);
  if (match) {
    return {
      name: match[1].trim().replace(/^"|"$/g, "") || undefined,
      email: match[2].trim(),
    };
  }
  return { email: value };
}

/**
 * Template de boas-vindas (pt_BR). Um e-mail, só no cadastro.
 * Sem promessa de “impede furto”.
 */
function buildWelcomeEmail({ displayName, email } = {}) {
  const greet = greetingLine(displayName);
  const greetHtml = escapeHtml(greet);
  const mail = String(email || "").trim();
  const mailHtml = escapeHtml(mail);

  // Assunto = saudação (linha principal no Gmail). Preheader sem repetir o Olá.
  const subject = greet;
  const preheader = "Sua conta no Guardian Sense foi criada com sucesso.";
  const preheaderPad = "&#847;&zwnj;&nbsp;".repeat(30);

  const text = [
    `${greet},`,
    "",
    "Sua conta no Guardian Sense foi criada com sucesso.",
    mail
      ? `Este endereço (${mail}) é o login da sua conta. Cada conta fica vinculada a um aparelho.`
      : "Este endereço é o login da sua conta. Cada conta fica vinculada a um aparelho.",
    "",
    "Na Central de Proteção você acompanha o aparelho mesmo quando ele não está com você:",
    PORTAL_URL,
    "",
    "Se ainda não instalou o app no Android:",
    PLAY_STORE_URL,
    "",
    "O Guardian Sense protege seus ativos digitais e ajuda depois de um incidente. Ele não impede o furto do aparelho.",
    "",
    "Equipe Guardian Sense",
    PORTAL_URL,
  ].join("\n");

  const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(subject)}</title>
</head>
<body style="margin:0;padding:0;background:#f4f7fb;font-family:Arial,Helvetica,sans-serif;color:#0f172a;">
  <div style="display:none;font-size:1px;line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;mso-hide:all;">
    ${escapeHtml(preheader)}${preheaderPad}
  </div>
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f7fb;padding:24px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="560" cellspacing="0" cellpadding="0" style="max-width:560px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;border:1px solid #e2e8f0;">
          <tr>
            <td align="center" bgcolor="#0E141B" background="${HEADER_BG_URL}" style="background-color:#0E141B;background-image:url('${HEADER_BG_URL}');background-size:cover;background-position:center;background-repeat:no-repeat;padding:32px 28px 28px;">
              <!--[if gte mso 9]>
              <v:rect xmlns:v="urn:schemas-microsoft-com:vml" fill="true" stroke="false" style="width:560px;height:220px;">
                <v:fill type="frame" src="${HEADER_BG_URL}" color="#0E141B" />
                <v:textbox inset="0,0,0,0">
              <![endif]-->
              <img src="${LOGO_URL}" width="${LOGO_WIDTH}" height="${LOGO_HEIGHT}" alt="" style="display:block;margin:0 auto 12px;border:0;outline:none;text-decoration:none;width:${LOGO_WIDTH}px;height:${LOGO_HEIGHT}px;">
              <p style="margin:0;font-size:13px;letter-spacing:0.08em;text-transform:uppercase;color:#8B98A8;">Guardian Sense</p>
              <h1 style="margin:8px 0 0;font-size:22px;line-height:1.3;color:#F4F7FB;font-weight:bold;">Bem-vindo</h1>
              <!--[if gte mso 9]>
                </v:textbox>
              </v:rect>
              <![endif]-->
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <p style="margin:0 0 16px;font-size:16px;line-height:1.5;">${greetHtml},</p>
              <p style="margin:0 0 16px;font-size:16px;line-height:1.5;">Sua conta no Guardian Sense foi criada com sucesso.</p>
              <p style="margin:0 0 16px;font-size:16px;line-height:1.5;">Este endereço${mailHtml ? ` (<strong>${mailHtml}</strong>)` : ""} é o login da sua conta. Cada conta fica vinculada a um aparelho.</p>
              <p style="margin:0 0 24px;font-size:16px;line-height:1.5;">Na Central de Proteção você acompanha o aparelho mesmo quando ele não está com você.</p>
              <p style="margin:0 0 24px;">
                <a href="${PORTAL_URL}" style="display:inline-block;background:#2563eb;color:#ffffff;text-decoration:none;font-size:16px;font-weight:bold;padding:12px 20px;border-radius:999px;">Abrir a Central de Proteção</a>
              </p>
              <p style="margin:0 0 16px;font-size:14px;line-height:1.5;color:#64748b;">Ainda não instalou o app no Android? <a href="${PLAY_STORE_URL}" style="color:#2563eb;">Baixar na Play Store</a>.</p>
              <p style="margin:0;font-size:13px;line-height:1.5;color:#64748b;">O Guardian Sense protege seus ativos digitais e ajuda depois de um incidente. Ele não impede o furto do aparelho.</p>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px;font-size:12px;line-height:1.5;color:#94a3b8;">
              Equipe Guardian Sense<br>
              <a href="${PORTAL_URL}" style="color:#64748b;">${PORTAL_URL.replace("https://", "")}</a>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return {
    subject,
    text,
    html,
    portalUrl: PORTAL_URL,
    playStoreUrl: PLAY_STORE_URL,
    logoUrl: LOGO_URL,
    headerBgUrl: HEADER_BG_URL,
  };
}

module.exports = {
  PORTAL_URL,
  PLAY_STORE_URL,
  LOGO_URL,
  HEADER_BG_URL,
  LOGO_WIDTH,
  LOGO_HEIGHT,
  escapeHtml,
  firstName,
  greetingLine,
  parseFrom,
  buildWelcomeEmail,
};
