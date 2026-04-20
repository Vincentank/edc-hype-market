# EDC LV 2026 · Hype Market

Live prediction market where friends vote their top 5 + top 10 anticipated DJ sets for EDC Las Vegas 2026 (May 15–17).

- **Frontend:** single-file HTML, no build step.
- **Backend:** Supabase (anonymous auth + realtime + Postgres RLS).
- **Hosting:** Vercel (static).

## Configure

Edit `index.html`, find `SUPABASE_CONFIG`, paste your Supabase project URL + anon key:

```js
const SUPABASE_CONFIG = {
  url:     "https://YOUR-PROJECT.supabase.co",
  anonKey: "YOUR-PUBLIC-ANON-KEY"
};
```

Then run the schema in `supabase-schema.sql` (bundled in the parent folder) in the Supabase SQL editor, and turn on Anonymous Sign-Ins under Auth → Providers.

## Develop locally

Just open `index.html` in a browser — no server needed.
