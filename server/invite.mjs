// Run locally; this prints a newly generated invitation, never an existing key.
import { randomBytes } from 'node:crypto';
import { tokenHash } from './access.mjs';
const token = randomBytes(32).toString('base64url');
console.log(`Personal invitation (give only to one tester): ${token}`);
console.log(`Append this hash to INVITE_TOKEN_HASHES: ${tokenHash(token)}`);
