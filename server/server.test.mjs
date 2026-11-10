import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createRealityServer } from './server.mjs';
import { modeInstructions, systemPrompt } from './prompts.mjs';

const token = 'test-personal-access-token-with-32-characters';
async function fixture(t, options = {}) {
  const calls = [];
  const server = createRealityServer({
    apiKey: 'test-key', accessToken: token,
    fetchImpl: async (url, init) => {
      calls.push({ url, ...init, body: JSON.parse(init.body) });
      return Response.json({ choices: [{ message: { content: 'She does not enjoy her job.' }, finish_reason: 'stop' }] });
    }, ...options,
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => { server.close(resolve); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (body, headers = {}) => fetch(`${base}/reality`, {
    method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...headers },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
  return { base, post, calls };
}

test('all nine modes reach the provider with distinct instructions', async t => {
  let clock = Date.now();
  const { post, calls } = await fixture(t, { now: () => clock });
  assert.equal(Object.keys(modeInstructions).length, 9);
  for (const mode of Object.keys(modeInstructions)) {
    clock += 60001;
    const response = await post({ input: 'She enjoys her job.', mode });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { text: 'She does not enjoy her job.' });
    assert.equal(calls.at(-1).body.messages[1].content, 'She enjoys her job.');
    assert.equal(calls.at(-1).body.messages[0].content, systemPrompt(mode));
  }
  assert.equal(new Set(calls.map(c => c.body.messages[0].content)).size, 9);
});

test('literal negation specifies grammar, tense and already-negative statements', () => {
  const prompt = systemPrompt('literalNegation');
  assert.match(prompt, /She does not enjoy her job/);
  assert.match(prompt, /I went/);
  assert.match(prompt, /tense/);
  assert.match(prompt, /self-harm/);
  assert.match(systemPrompt('positive'), /Do not promise success/);
});

test('invalid requests never reach the paid provider', async t => {
  let clock = Date.now();
  const { post, calls } = await fixture(t, { now: () => clock += 60001 });
  for (const body of [{ input: '', mode: 'positive' }, { input: 'x'.repeat(601), mode: 'positive' },
    { input: 'Hello', mode: 'unknown' }, { input: 'Hello', mode: 'toString' }, { input: 4, mode: 'positive' }, '{bad json']) {
    assert.equal((await post(body)).status, 400);
  }
  assert.equal((await post('x'.repeat(17000))).status, 413);
  assert.equal(calls.length, 0);
});

test('access token and allowed browser origin are required', async t => {
  const { post, calls } = await fixture(t);
  assert.equal((await post({ input: 'Hello', mode: 'positive' }, { Authorization: 'Bearer wrong' })).status, 401);
  assert.equal((await post({ input: 'Hello', mode: 'positive' }, { Origin: 'https://untrusted.example' })).status, 403);
  const response = await post({ input: 'Hello', mode: 'positive' }, { Origin: 'http://localhost:8080' });
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:8080');
  assert.equal(calls.length, 1);
});

test('preflight is limited to the allowed origin', async t => {
  const { base } = await fixture(t);
  const response = await fetch(`${base}/reality`, { method: 'OPTIONS', headers: { Origin: 'http://localhost:8080' } });
  assert.equal(response.status, 204);
  assert.match(response.headers.get('access-control-allow-headers'), /Authorization/);
});

test('missing provider configuration returns a clear code, never a fake result', async t => {
  const { post, calls } = await fixture(t, { apiKey: '' });
  const response = await post({ input: 'Hello', mode: 'positive' });
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), { error: 'ai_not_configured' });
  assert.equal(calls.length, 0);
});

test('rate limit bounds paid requests', async t => {
  const { post, calls } = await fixture(t, { rateLimit: 1 });
  await post({ input: 'Hello', mode: 'positive' });
  assert.equal((await post({ input: 'Hello', mode: 'positive' })).status, 429);
  assert.equal(calls.length, 1);
});

test('immediate self-harm overrides literal and positive modes', async t => {
  const { post, calls } = await fixture(t);
  for (const mode of ['literalNegation', 'positive', 'pessimistic']) {
    const response = await post({ input: 'I want to kill myself', mode });
    assert.match((await response.json()).text, /someone you trust/);
  }
  assert.equal(calls.length, 0);
});

test('upstream errors and invalid outputs do not leak provider details', async t => {
  for (const upstream of [
    () => new Response('private upstream details test-key', { status: 401 }),
    () => Response.json({ choices: [] }),
    () => Response.json({ choices: [{ message: { content: 'Incomplete' }, finish_reason: 'length' }] }),
    () => Response.json({ choices: [{ message: { content: 'x'.repeat(601) }, finish_reason: 'stop' }] }),
    () => Response.json({ choices: [{ message: { content: '{"debug":true}' }, finish_reason: 'stop' }] }),
    () => { throw new Error('secret internal error'); },
  ]) {
    const { post } = await fixture(t, { fetchImpl: async () => upstream() });
    const response = await post({ input: 'Hello', mode: 'positive' });
    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: 'ai_unavailable' });
  }
});
