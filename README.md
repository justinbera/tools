# MarinaOS

Security-first marina management SaaS. This repository currently implements the Phase 1 foundation: the tenant/site data model, configurable database roles, PostgreSQL RLS, disabled-by-default modules, versioned subscription pricing, support-session auditing, Supabase-aware server authorization, local fixtures, and a responsive account dashboard.

## Start locally

1. Copy `.env.example` to `.env.local` and set values from a local or cloud Supabase project.
2. Run migrations and fixtures with `supabase db reset` (Supabase CLI).
3. Install dependencies with `npm install`, then run `npm run dev`.

Verification: `npm test` runs dependency-free pricing/billing unit tests. `npm run test:db` probes RLS against a seeded database via `DATABASE_URL`.

When package installation is unavailable, `npm run preview` starts a dependency-free browser preview of the account dashboard on `http://localhost:3000`. This preview uses demonstration data and does not replace the authenticated Next.js runtime.

## Public GitHub Pages preview

The Pages workflow publishes the static demonstration in `preview/` whenever it changes on `main` or `work`. In the GitHub repository, open **Settings → Pages**, choose **GitHub Actions** as the source, then run **Deploy browser preview to GitHub Pages** from the Actions tab (or push a preview change). The public address will be `https://<owner>.github.io/<repository>/` and is also shown in the workflow's deployment summary.

GitHub Pages hosts only this frontend demonstration. It cannot run the authenticated Next.js server, protect Supabase secrets, or execute API routes; deploy the full application to Vercel with Supabase for an end-to-end environment.

Read [architecture and security decisions](docs/ARCHITECTURE.md) and the [durable requirements/progress record](docs/REQUIREMENTS.md) before extending the product. All external integrations are sandbox-only until explicitly verified.
