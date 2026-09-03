"use strict";

const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const tpl = require("./welcome_email_template");

describe("welcome_email_template", () => {
  it("escapa HTML no nome e no e-mail", () => {
    const mail = tpl.buildWelcomeEmail({
      displayName: `<img src=x onerror=alert(1)>`,
      email: `a&b@example.com`,
    });
    assert.equal(mail.html.includes("onerror=alert"), false);
    assert.equal(mail.html.includes("&lt;img"), true);
    assert.equal(mail.html.includes("a&amp;b@example.com"), true);
    assert.equal(mail.html.includes(`src="${tpl.LOGO_URL}"`), true);
  });

  it("cumpre o copy combinado", () => {
    const mail = tpl.buildWelcomeEmail({
      displayName: "Maria Silva",
      email: "maria@example.com",
    });
    assert.equal(mail.subject, "Olá, Maria");
    assert.match(mail.text, /^Olá, Maria,/);
    const preheaderMatch = mail.html.match(
      /display:none[^>]*>([\s\S]*?)<\/div>/,
    );
    assert.ok(preheaderMatch);
    assert.match(
      preheaderMatch[1],
      /Sua conta no Guardian Sense foi criada com sucesso/,
    );
    assert.equal(preheaderMatch[1].includes("Olá, Maria"), false);
    assert.match(mail.text, /criada com sucesso/);
    assert.match(mail.text, /vinculada a um aparelho/);
    assert.match(mail.text, /não impede o furto/);
    assert.equal(mail.text.includes("impede furto do"), false);
    assert.equal(mail.html.includes(tpl.PORTAL_URL), true);
    assert.equal(mail.html.includes(tpl.PLAY_STORE_URL), true);
    assert.equal(mail.html.includes(tpl.LOGO_URL), true);
    assert.equal(mail.html.includes(tpl.HEADER_BG_URL), true);
    assert.equal(
      mail.html.includes(`width="${tpl.LOGO_WIDTH}" height="${tpl.LOGO_HEIGHT}"`),
      true,
    );
    assert.equal(mail.text.includes(tpl.PORTAL_URL), true);
  });

  it("funciona sem nome de exibição", () => {
    const mail = tpl.buildWelcomeEmail({ email: "x@y.com" });
    assert.equal(mail.subject, "Olá");
    assert.match(mail.text, /^Olá,/);
    assert.equal(mail.text.startsWith("Olá,,"), false);
  });

  it("parseia remetente com nome", () => {
    assert.deepEqual(
      tpl.parseFrom("Guardian Sense <nao-responda@guardian-sense.com>"),
      { name: "Guardian Sense", email: "nao-responda@guardian-sense.com" },
    );
    assert.deepEqual(tpl.parseFrom("contato@guardian-sense.com"), {
      email: "contato@guardian-sense.com",
    });
  });
});
