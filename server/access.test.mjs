import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createAccess, tokenHash } from './access.mjs';
import { createRealityServer, optionsFromEnvironment } from './server.mjs';
const first = 'personal-invitation-for-first-tester-123456';
const second = 'personal-invitation-for-second-tester-12345';

test('individual invitations can be revoked independently', () => {
  const access = createAccess({ inviteTokenHashes: [tokenHash(first), tokenHash(second)] });
  assert.equal(access.identify(`Bearer ${first}`), tokenHash(first));
  assert.equal(access.identify('Bearer invalid'), null);
  assert.equal(createAccess({ inviteTokenHashes: [tokenHash(second)] }).identify(`Bearer ${first}`), null);
});

test('daily quota persists across restart, is independent per tester, and resets next UTC day', t => {
  const dir = mkdtempSync(join(tmpdir(), 'ar-usage-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  let clock = Date.UTC(2026, 10, 10, 8);
  const options = { perTesterLimit: 1, dailyLimit: 2, usageFile: join(dir, 'usage.json'), now: () => clock };
  const access = createAccess(options);
  assert.equal(access.consume(tokenHash(first)), true);
  const restarted = createAccess(options);
  assert.equal(restarted.consume(tokenHash(first)), false);
  assert.equal(restarted.consume(tokenHash(second)), true);
  assert.equal(restarted.consume(tokenHash('third')), false);
  clock += 86400000;
  assert.equal(restarted.consume(tokenHash(first)), true);
});

test('failed ledger writes fail closed', () => {
  const access = createAccess({ usageFile: '/nonexistent-ar-test-dir/usage.json' });
  assert.throws(() => access.consume(tokenHash(first)));
});

test('production rejects shared credentials and requires persistent usage storage', () => {
  assert.throws(() => optionsFromEnvironment({ NODE_ENV: 'production', BACKEND_ACCESS_TOKEN: first }));
  assert.throws(() => optionsFromEnvironment({ NODE_ENV: 'production', INVITE_TOKEN_HASHES: tokenHash(first), OPENAI_API_KEY: 'test-key' }));
  const options = optionsFromEnvironment({ NODE_ENV: 'production', INVITE_TOKEN_HASHES: tokenHash(first), OPENAI_API_KEY: 'test-key', USAGE_FILE: '/data/usage.json' });
  assert.equal(options.accessToken, '');
  assert.deepEqual(options.allowedOrigins, []);
  assert.throws(() => optionsFromEnvironment({ NODE_ENV: 'production', INVITE_TOKEN_HASHES: tokenHash(first), OPENAI_API_KEY: 'test-key', USAGE_FILE: '/data/usage.json', ALLOWED_ORIGINS: 'http://localhost:8080' }));
});

test('health and invitation verification do not invoke paid AI; quota is enforced before provider', async t => {
  let calls = 0;
  const server = createRealityServer({ apiKey: 'test-key', inviteTokenHashes: [tokenHash(first)], perTesterLimit: 1,
    fetchImpl: async () => { calls++; return Response.json({ choices: [{ finish_reason: 'stop', message: { content: 'A different perspective.' } }] }); },
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/healthz`)).status, 200);
  assert.equal((await fetch(`${base}/access`, { method: 'POST', headers: { Authorization: `Bearer ${first}` } })).status, 204);
  assert.equal(calls, 0);
  const init = { method: 'POST', headers: { Authorization: `Bearer ${first}`, 'Content-Type': 'application/json' }, body: JSON.stringify({ input: 'I am ready', mode: 'positive' }) };
  assert.equal((await fetch(`${base}/reality`, init)).status, 200);
  assert.equal((await fetch(`${base}/reality`, init)).status, 429);
  assert.equal(calls, 1);
});
