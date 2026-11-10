"use strict";

const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const deletion = require("./account_deletion");

describe("account_deletion", () => {
  it("hash do e-mail ignora caixa e espaços", () => {
    const a = deletion.deletedAccountHash("  Fulano@Example.com ");
    const b = deletion.deletedAccountHash("fulano@example.com");
    assert.equal(a, b);
    assert.match(a, /^[0-9a-f]{64}$/);
    assert.equal(a.includes("fulano"), false);
  });

  it("sem e-mail não gera hash", () => {
    assert.equal(deletion.deletedAccountHash(""), null);
    assert.equal(deletion.deletedAccountHash("   "), null);
    assert.equal(deletion.deletedAccountHash(null), null);
  });

  it("login recente vale por até 300 s", () => {
    const nowMs = 1_800_000_000_000;
    const nowS = nowMs / 1000;
    assert.equal(deletion.isRecentLogin(nowS, nowMs), true);
    assert.equal(deletion.isRecentLogin(nowS - 300, nowMs), true);
    assert.equal(deletion.isRecentLogin(nowS - 301, nowMs), false);
  });

  it("auth_time ausente ou inválido exige login de novo", () => {
    assert.equal(deletion.isRecentLogin(undefined), false);
    assert.equal(deletion.isRecentLogin(null), false);
    assert.equal(deletion.isRecentLogin("abc"), false);
    assert.equal(deletion.isRecentLogin(0), false);
  });

  it("conta recriada nasce com o trial encerrado", () => {
    const now = { marker: "now" };
    const sub = deletion.expiredTrialSubscription(now);
    assert.equal(sub.status, "expired");
    assert.equal(sub.trialEndsAt, now);
    assert.equal(sub.trialStartedAt, now);
    assert.equal(sub.plan, "annual_12m");
  });
});
