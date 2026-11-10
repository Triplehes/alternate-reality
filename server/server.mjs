import http from 'node:http';
import { createAccess } from './access.mjs';
import { pathToFileURL } from 'node:url';
import { modeInstructions, systemPrompt, needsImmediateSupport, supportiveResponse } from './prompts.mjs';

export function createRealityServer({
  apiKey = '', model = 'gpt-4.1-mini', accessToken = '', inviteTokenHashes = [],
  perTesterLimit = 30, dailyLimit = 300, usageFile,
  allowedOrigins = ['http://localhost:8080', 'http://127.0.0.1:8080'],
  fetchImpl = fetch, rateLimit = 20, now = Date.now, requestTimeoutMs = 25000,
} = {}) {
  const access = createAccess({ accessToken, inviteTokenHashes, perTesterLimit, dailyLimit, usageFile, now });
  const testerWindows = new Map();
  let windowStart = now();
  let count = 0;
  let active = 0;
  const server = http.createServer(async (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Vary', 'Origin');
    const reply = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(body == null ? undefined : JSON.stringify(body));
    };
    req.setTimeout(10000, () => req.destroy());
    const origin = req.headers.origin;
    if (origin && !allowedOrigins.includes(origin)) return reply(403, { error: 'origin_not_allowed' });
    if (origin) res.setHeader('Access-Control-Allow-Origin', origin);
    if (req.method === 'GET' && req.url === '/healthz') return reply(200, { status: 'ok' });
    if (!['/reality', '/access'].includes(req.url)) return reply(404, { error: 'not_found' });
    if (req.method === 'OPTIONS') {
      res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      return reply(204, null);
    }
    if (req.method !== 'POST') return reply(405, { error: 'method_not_allowed' });
    const identity = access.identify(req.headers.authorization);
    if (!identity) return reply(401, { error: 'unauthorized' });
    if (req.url === '/access') return reply(204, null);
    if (!req.headers['content-type']?.toLowerCase().startsWith('application/json')) {
      return reply(415, { error: 'json_required' });
    }
    if (!apiKey || apiKey.startsWith('replace_')) return reply(503, { error: 'ai_not_configured' });
    if (now() - windowStart >= 60000) { windowStart = now(); count = 0; }
    let testerWindow = testerWindows.get(identity);
    if (!testerWindow || now() - testerWindow.start >= 60000) { testerWindow = { start: now(), count: 0 }; testerWindows.set(identity, testerWindow); }
    if (count >= rateLimit || active >= 3 || testerWindow.count >= 5) {
      res.setHeader('Retry-After', '60');
      return reply(429, { error: 'rate_limited' });
    }
    count++;
    testerWindow.count++;
    active++;
    try {
      const chunks = [];
      let bytes = 0;
      for await (const chunk of req) {
        bytes += chunk.length;
        if (bytes > 16384) return reply(413, { error: 'input_too_large' });
        chunks.push(chunk);
      }
      req.setTimeout(0);
      let body;
      try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
      catch { return reply(400, { error: 'invalid_input' }); }
      const input = typeof body?.input === 'string' ? body.input.trim() : '';
      if (!input || input.length > 600 || typeof body?.mode !== 'string' || !Object.hasOwn(modeInstructions, body.mode)) {
        return reply(400, { error: 'invalid_input' });
      }
      if (needsImmediateSupport(input)) return reply(200, { text: supportiveResponse });
      if (!access.consume(identity)) {
        res.setHeader('Retry-After', String(Math.ceil((86400000 - now() % 86400000) / 1000)));
        return reply(429, { error: 'daily_limit' });
      }
      const upstream = await fetchImpl('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model, store: false, max_completion_tokens: 512,
          messages: [{ role: 'system', content: systemPrompt(body.mode) }, { role: 'user', content: input }],
        }),
        signal: AbortSignal.timeout(requestTimeoutMs),
      });
      if (!upstream.ok) return reply(502, { error: 'ai_unavailable' });
      const data = await upstream.json();
      const choice = data?.choices?.[0];
      const result = choice?.message?.content;
      if (choice?.finish_reason !== 'stop' || typeof result !== 'string' || !result.trim() ||
          result.trim().length > 600 || /^[{\[]|^```/.test(result.trim())) {
        return reply(502, { error: 'ai_unavailable' });
      }
      return reply(200, { text: result.trim() });
    } catch (error) {
      const timedOut = error?.name === 'TimeoutError' || error?.name === 'AbortError';
      if (!res.headersSent) reply(timedOut ? 504 : 502, { error: timedOut ? 'ai_timeout' : 'ai_unavailable' });
    } finally { active--; }
  });
  server.maxHeadersCount = 50;
  server.keepAliveTimeout = 5000;
  server.requestTimeout = 30000;
  server.headersTimeout = 10000;
  return server;
}

export function optionsFromEnvironment(env) {
  const production = env.NODE_ENV === 'production';
  const accessToken = production ? '' : env.BACKEND_ACCESS_TOKEN ?? '';
  const inviteTokenHashes = (env.INVITE_TOKEN_HASHES ?? '').split(',').map(s => s.trim()).filter(Boolean);
  const allowedOrigins = (env.ALLOWED_ORIGINS ?? (production ? '' : 'http://localhost:8080,http://127.0.0.1:8080'))
    .split(',').map(s => s.trim()).filter(Boolean);
  if (!inviteTokenHashes.length && (accessToken.length < 32 || accessToken.startsWith('replace_'))) throw new Error('Configure personal invitation hashes (or a local development access token).');
  if (production && (!env.OPENAI_API_KEY || env.OPENAI_API_KEY.startsWith('replace_') || !env.USAGE_FILE)) throw new Error('Production requires an API key and persistent USAGE_FILE.');
  for (const origin of allowedOrigins) {
    const url = new URL(origin);
    if (url.origin !== origin || (production && url.protocol !== 'https:')) throw new Error('Allowed origins must be exact HTTPS origins in production.');
  }
  return {
    apiKey: env.OPENAI_API_KEY, model: env.OPENAI_MODEL || 'gpt-4.1-mini', accessToken,
    inviteTokenHashes, allowedOrigins, usageFile: env.USAGE_FILE,
    perTesterLimit: Number(env.PER_TESTER_DAILY_LIMIT ?? 30),
    dailyLimit: Number(env.GLOBAL_DAILY_LIMIT ?? 300),
    rateLimit: Number(env.REQUESTS_PER_MINUTE ?? 20),
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const options = optionsFromEnvironment(process.env);
    if (!Number.isSafeInteger(options.rateLimit) || options.rateLimit < 1) throw new Error('REQUESTS_PER_MINUTE must be a positive integer.');
    const host = process.env.HOST ?? '127.0.0.1';
    const port = Number(process.env.PORT ?? 8787);
    if (!Number.isSafeInteger(port) || port < 1 || port > 65535) throw new Error('PORT must be between 1 and 65535.');
    const server = createRealityServer(options);
    server.listen(port, host, () => console.log('Alternate Reality backend ready.'));
    const stop = () => {
      server.close(() => process.exit(0));
      setTimeout(() => { server.closeAllConnections(); process.exit(0); }, 30000).unref();
    };
    process.on('SIGTERM', stop);
    process.on('SIGINT', stop);
    server.on('error', () => { console.error('Backend could not start. Check the port and host.'); process.exitCode = 1; });
  } catch (_) {
    console.error('Backend configuration or usage storage is invalid. See docs/RELEASE.md. No secrets were logged.');
    process.exitCode = 1;
  }
}
