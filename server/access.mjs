import { createHash, timingSafeEqual } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync, renameSync } from 'node:fs';

export const tokenHash = token => createHash('sha256').update(token).digest('hex');
export function createAccess({ accessToken = '', inviteTokenHashes = [], perTesterLimit = 30,
  dailyLimit = 300, usageFile, now = Date.now } = {}) {
  const hashes = [...inviteTokenHashes];
  if (accessToken.length >= 32 && !accessToken.startsWith('replace_')) hashes.push(tokenHash(accessToken));
  if (hashes.some(h => !/^[a-f0-9]{64}$/.test(h))) throw new Error('Invitation hashes must be SHA-256 hex strings.');
  if (![perTesterLimit, dailyLimit].every(n => Number.isSafeInteger(n) && n > 0)) throw new Error('Limits must be positive integers.');
  let usage = { day: '', total: 0, testers: {} };
  if (usageFile && existsSync(usageFile)) {
    usage = JSON.parse(readFileSync(usageFile, 'utf8'));
    if (typeof usage.day !== 'string' || !Number.isSafeInteger(usage.total) || usage.total < 0 ||
        !usage.testers || Array.isArray(usage.testers) || typeof usage.testers !== 'object' ||
        Object.entries(usage.testers).some(([h, n]) => !/^[a-f0-9]{64}$/.test(h) || !Number.isSafeInteger(n) || n < 0)) {
      throw new Error('Usage ledger is invalid; restore it before starting.');
    }
  }
  return {
    identify(header) {
      if (typeof header !== 'string' || !header.startsWith('Bearer ') || header.length > 263) return null;
      const candidate = tokenHash(header.slice(7));
      let match = false;
      for (const hash of hashes) match = timingSafeEqual(Buffer.from(candidate, 'hex'), Buffer.from(hash, 'hex')) || match;
      return match ? candidate : null;
    },
    consume(identity) {
      const day = new Date(now()).toISOString().slice(0, 10);
      if (usage.day !== day) usage = { day, total: 0, testers: {} };
      const count = usage.testers[identity] ?? 0;
      if (usage.total >= dailyLimit || count >= perTesterLimit) return false;
      const next = { day, total: usage.total + 1, testers: { ...usage.testers, [identity]: count + 1 } };
      // Persist before the paid call. A failed write fails closed. Deploy one
      // instance with a persistent disk; multiple replicas need a shared store.
      if (usageFile) {
        writeFileSync(`${usageFile}.tmp`, JSON.stringify(next), { mode: 0o600 });
        renameSync(`${usageFile}.tmp`, usageFile);
      }
      usage = next;
      return true;
    },
  };
}
