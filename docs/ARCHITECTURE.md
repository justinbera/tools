# MarinaOS architecture and security model

## System shape

MarinaOS is a Next.js application hosted on Vercel. Supabase Cloud supplies PostgreSQL, Auth, and private Storage. Browser requests use the authenticated user's short-lived token and the public anon key; ordinary request paths never receive the service-role key. Route handlers centralize capability checks, while PostgreSQL row-level security (RLS) is the authoritative boundary. Scheduled work will use narrowly scoped database functions and idempotency keys rather than bypassing policies wholesale.

The hierarchy is **platform → master account (tenant) → site**. Every site-owned relationship carries both `master_account_id` and `site_id`, backed by a composite foreign key. This intentionally duplicates the tenant key: PostgreSQL can then reject a site from another tenant without relying on application code.

## Permission model

Permissions are stable capabilities, roles and role-permission links are data, and assignments have either master or site scope. `has_permission` evaluates the current Supabase identity and the requested site. Master assignments reach all sites in that tenant; site assignments reach only their named site. Neither APIs nor RLS make decisions from role names. Assignment and role-permission triggers reject grants the actor does not already hold.

Module availability is a second gate. A request must pass both its capability check and its module check. New site/module rows default disabled; disabling a module does not delete data. Dependencies are declared in `module_catalog` and invalid enablement is rejected by the database.

Platform support identities are separate from tenant roles. Access requires an active, reason-bearing support session. Support activity is linked to that session in append-only audit events. Future platform routes must require platform privileges and must write view/export/change events.

## Commercial model

All money is integer cents in USD. Dated global price versions are immutable invoice inputs. Nullable tenant and site override rows implement global → master → site precedence; `NULL` means no override while `0` is a real price. Issued subscription invoices snapshot the billing address and retain their price-version-backed, site-attributed lines. The first global version is $399/site/month and every module begins at $0.

Billing cadence is calendar-month, in arrears, with no proration in Phase 1. Later proration requires an explicit policy/version rather than silently changing old invoices. Subscription billing is a platform concern and remains separate from boater receivables.

## Private files and integrations

Storage buckets will be private. Object paths will begin with tenant and site UUIDs and downloads will be short-lived after the same centralized authorization check. Provider credentials belong in encrypted server-side storage, never audit metadata. All Phase 1 external behavior is sandbox/simulated; no live processor, email, or equipment operation is represented.

## Deployment

Apply `supabase/migrations` in order, configure the public Supabase URL and anon key in Vercel, and keep database/service credentials in server-only secret stores. Run `supabase/seed.sql` only locally. Production needs a Supabase project and Vercel project; none are required for unit tests.
