/**
 * Vercel build: write prototypes/supabase-config.js from env (never commit keys).
 * Set in Vercel → Project → Settings → Environment Variables:
 *   SUPABASE_URL
 *   SUPABASE_ANON_KEY
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(__dirname, '..', 'prototypes', 'supabase-config.js');

const url = String(process.env.SUPABASE_URL || '').trim();
const anonKey = String(process.env.SUPABASE_ANON_KEY || '').trim();

const body =
  `window.__MINIGAMESHOW_SUPABASE__ = window.__MINIGAMESHOW_SUPABASE__ || { url: ${JSON.stringify(url)}, anonKey: ${JSON.stringify(anonKey)} };\n`;

fs.writeFileSync(out, body, 'utf8');
if (!url || !anonKey) {
  console.warn(
    '[vercel-write-supabase-config] SUPABASE_URL or SUPABASE_ANON_KEY missing — game will show config reminder until vars are set.'
  );
} else {
  console.log('[vercel-write-supabase-config] Wrote prototypes/supabase-config.js');
}
