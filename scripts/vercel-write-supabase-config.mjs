/**
 * Vercel build: write prototypes/supabase-config.js from env (never commit keys).
 * Set in Vercel → Project → Settings → Environment Variables:
 *   SUPABASE_URL
 *   SUPABASE_ANON_KEY
 *   MINIGAMESHOW_SITE_URL (optional) — canonical site origin for auth confirmation links, e.g. https://theminigameshow.com
 *     When set, sign-up emails redirect here instead of whatever host the user typed (fixes localhost links from dev).
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(__dirname, '..', 'prototypes', 'supabase-config.js');

const url = String(process.env.SUPABASE_URL || '').trim();
const anonKey = String(process.env.SUPABASE_ANON_KEY || '').trim();
const appOrigin = String(process.env.MINIGAMESHOW_SITE_URL || '').trim().replace(/\/$/, '');

const fields = [`url: ${JSON.stringify(url)}`, `anonKey: ${JSON.stringify(anonKey)}`];
if (appOrigin) fields.push(`appOrigin: ${JSON.stringify(appOrigin)}`);

const body =
  `window.__MINIGAMESHOW_SUPABASE__ = window.__MINIGAMESHOW_SUPABASE__ || { ${fields.join(', ')} };\n`;

fs.writeFileSync(out, body, 'utf8');
if (!url || !anonKey) {
  console.warn(
    '[vercel-write-supabase-config] SUPABASE_URL or SUPABASE_ANON_KEY missing — game will show config reminder until vars are set.'
  );
} else {
  console.log('[vercel-write-supabase-config] Wrote prototypes/supabase-config.js');
}
