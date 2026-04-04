/**
 * Copy this file to supabase-config.js (same folder) and paste your keys.
 *   cp prototypes/supabase-config.example.js prototypes/supabase-config.js
 * supabase-config.js is gitignored — never commit real keys.
 *
 * Keys: Supabase Dashboard → Project Settings → API
 */
window.__MINIGAMESHOW_SUPABASE__ = {
  url: '',
  anonKey: '',
  // Optional: override Edge Functions base (default = url + '/functions/v1'). Use if functions are on another host.
  // functionsUrl: 'https://xxxx.supabase.co/functions/v1',
  // Optional: same host everywhere (Vercel MINIGAMESHOW_SITE_URL, Supabase Site URL, primary domain).
  // Use www OR apex — not both. After load, DevTools console: __MINIGAMESHOW_CONFIRM_REDIRECT__
  // appOrigin: 'https://www.theminigameshow.com',
};
