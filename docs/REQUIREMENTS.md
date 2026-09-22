# MarinaOS delivery record

This file is the durable handoff for the product specification.

## Phase status

| Phase | Status | Delivered / next |
|---|---|---|
| 1 Security and commercial foundation | In progress | Schema, tenant/site RLS, database roles, module gates, versioned pricing, invoice records, support sessions/audit, fixtures, centralized server checks, and responsive account shell are present. Authentication uses Supabase sessions. Next: role editor forms, pricing/invoice job UI, login flow, complete platform console, E2E coverage. |
| 2 Core marina operations | Not started | Customer/boat sharing, reservations, contracts, portal, reports. |
| 3 Operational payments | Not started | Sandbox adapter, site receivables and reconciliation. |
| 4 Financials | Not started | Per-site general ledgers and statements. |
| 5 Additional operations | Not started | POS, fuel simulator, dry-stack, repairs. |
| 6 Integrations/hardening | Not started | Verified QBO sandbox, recovery, accessibility/performance/deployment. |

## Assumptions and decisions

* U.S.-only initially: USD integer cents, U.S. postal addresses as structured JSON, IANA site time zones.
* Monthly subscriptions bill in arrears with no Phase 1 proration.
* Modules are operationally disabled by default but priced from the catalog; only enabled modules produce charge lines.
* Platform support needs an explicit active session and reason. Customer approval is not required, but every view/export/change must be recorded.
* The service-role credential is reserved for migrations and bounded background/platform procedures.
* Payment, mail, fuel, and accounting providers remain sandbox adapters until verified credentials are supplied.

## Acceptance evidence map

The local seed contains two unrelated master accounts, three sites, a master-scoped user, and a site-scoped user. The SQL integration test impersonates the site user and probes RLS directly. Unit tests prove explicit-zero price precedence and site-attributed invoice arithmetic. Later-phase acceptance criteria remain open and must not be inferred as complete from the dashboard shell.
