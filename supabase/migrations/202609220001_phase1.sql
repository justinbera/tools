begin;
create extension if not exists pgcrypto;

create type public.assignment_scope as enum ('master','site');
create type public.invoice_status as enum ('draft','issued','paid','void');
create type public.support_session_status as enum ('active','ended');

create table public.master_accounts (id uuid primary key default gen_random_uuid(), name text not null, billing_email text not null, billing_address jsonb not null default '{}'::jsonb, default_timezone text not null default 'America/New_York', created_at timestamptz not null default now());
create table public.sites (id uuid primary key default gen_random_uuid(), master_account_id uuid not null references public.master_accounts(id), name text not null, timezone text not null default 'America/New_York', status text not null default 'setup' check(status in('setup','active','suspended')), created_at timestamptz not null default now(), unique(master_account_id,id));
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, display_name text not null, created_at timestamptz not null default now());
create table public.permissions (key text primary key, description text not null);
create table public.roles (id uuid primary key default gen_random_uuid(), master_account_id uuid not null references public.master_accounts(id), name text not null, created_at timestamptz not null default now(), unique(master_account_id,name), unique(master_account_id,id));
create table public.role_permissions (master_account_id uuid not null, role_id uuid not null, permission_key text not null references public.permissions(key), primary key(role_id,permission_key), foreign key(master_account_id,role_id) references public.roles(master_account_id,id) on delete cascade);
create table public.role_assignments (id uuid primary key default gen_random_uuid(), master_account_id uuid not null references public.master_accounts(id), user_id uuid not null references auth.users(id), role_id uuid not null, scope assignment_scope not null, site_id uuid, granted_by uuid references auth.users(id), created_at timestamptz not null default now(), foreign key(master_account_id,role_id) references public.roles(master_account_id,id), foreign key(master_account_id,site_id) references public.sites(master_account_id,id), check((scope='master' and site_id is null) or (scope='site' and site_id is not null)));

create table public.module_catalog (key text primary key, name text not null, dependency_keys text[] not null default '{}');
create table public.site_modules (master_account_id uuid not null, site_id uuid not null, module_key text not null references public.module_catalog(key), enabled boolean not null default false, updated_at timestamptz not null default now(), primary key(site_id,module_key), foreign key(master_account_id,site_id) references public.sites(master_account_id,id));

create table public.price_versions (id uuid primary key default gen_random_uuid(), item_key text not null, amount_cents bigint not null check(amount_cents>=0), currency text not null default 'USD' check(currency='USD'), effective_from timestamptz not null, effective_to timestamptz, created_at timestamptz not null default now(), check(effective_to is null or effective_to>effective_from));
create unique index one_current_global_price on public.price_versions(item_key) where effective_to is null;
create table public.price_overrides (id uuid primary key default gen_random_uuid(), price_version_id uuid not null references public.price_versions(id), master_account_id uuid not null references public.master_accounts(id), site_id uuid, amount_cents bigint not null check(amount_cents>=0), effective_from timestamptz not null, effective_to timestamptz, foreign key(master_account_id,site_id) references public.sites(master_account_id,id), check(effective_to is null or effective_to>effective_from));
create table public.subscription_invoices (id uuid primary key default gen_random_uuid(), master_account_id uuid not null references public.master_accounts(id), period_start date not null, period_end date not null, status invoice_status not null default 'draft', billing_snapshot jsonb not null, total_cents bigint not null default 0, issued_at timestamptz, unique(master_account_id,period_start,period_end));
create table public.subscription_invoice_lines (id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.subscription_invoices(id), master_account_id uuid not null, site_id uuid not null, price_version_id uuid references public.price_versions(id), kind text not null, description text not null, amount_cents bigint not null, foreign key(master_account_id,site_id) references public.sites(master_account_id,id));

create table public.platform_users (user_id uuid primary key references auth.users(id), can_support boolean not null default false, can_manage_pricing boolean not null default false);
create table public.support_sessions (id uuid primary key default gen_random_uuid(), support_user_id uuid not null references auth.users(id), master_account_id uuid not null references public.master_accounts(id), site_id uuid, reason text not null check(length(reason)>=10), status support_session_status not null default 'active', started_at timestamptz not null default now(), ended_at timestamptz, foreign key(master_account_id,site_id) references public.sites(master_account_id,id));
create table public.audit_events (id bigint generated always as identity primary key, master_account_id uuid references public.master_accounts(id), site_id uuid, actor_user_id uuid references auth.users(id), support_session_id uuid references public.support_sessions(id), action text not null, target_type text not null, target_id text, metadata jsonb not null default '{}', occurred_at timestamptz not null default now(), foreign key(master_account_id,site_id) references public.sites(master_account_id,id));

insert into public.permissions(key,description) values ('sites.view','View assigned sites'),('sites.manage','Manage sites'),('roles.manage','Manage roles without escalation'),('modules.manage','Enable site modules'),('subscription.view','View subscription invoices'),('audit.view','View customer audit records');
insert into public.module_catalog(key,name,dependency_keys) values ('reservations','Reservations & slips','{}'),('contracts','Contracts & recurring billing','{}'),('pos','Retail POS & inventory','{}'),('fuel','Fuel sales & management','{}'),('dry_stack','Dry-stack operations','{}'),('maintenance','Maintenance & repair','{}'),('financials','Financials','{}'),('accounting','Accounting integrations','{financials}');
insert into public.price_versions(item_key,amount_cents,effective_from) values ('base',39900,'2026-01-01');
insert into public.price_versions(item_key,amount_cents,effective_from) select 'module:'||key,0,'2026-01-01' from public.module_catalog;

create or replace function public.has_permission(requested_permission text, requested_site_id uuid default null) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from role_assignments a join role_permissions rp on rp.role_id=a.role_id and rp.master_account_id=a.master_account_id where a.user_id=auth.uid() and rp.permission_key=requested_permission and (requested_site_id is null or a.scope='master' or a.site_id=requested_site_id))
 or exists(select 1 from platform_users p where p.user_id=auth.uid() and p.can_support and exists(select 1 from support_sessions ss where ss.support_user_id=auth.uid() and ss.status='active' and (requested_site_id is null or ss.site_id is null or ss.site_id=requested_site_id)));
$$;
revoke all on function public.has_permission(text,uuid) from public; grant execute on function public.has_permission(text,uuid) to authenticated;
create or replace function public.has_master_permission(requested_permission text, requested_master_id uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from role_assignments a join role_permissions rp on rp.role_id=a.role_id and rp.master_account_id=a.master_account_id where a.user_id=auth.uid() and a.master_account_id=requested_master_id and a.scope='master' and rp.permission_key=requested_permission);
$$;
revoke all on function public.has_master_permission(text,uuid) from public; grant execute on function public.has_master_permission(text,uuid) to authenticated;

create or replace function public.prevent_privilege_escalation() returns trigger language plpgsql security definer set search_path=public as $$ begin
 if auth.uid() is null then return new; end if;
 if not has_permission('roles.manage',new.site_id) then raise exception 'permission denied'; end if;
 if exists(select 1 from role_permissions target where target.role_id=new.role_id and not has_permission(target.permission_key,new.site_id)) then raise exception 'cannot grant permissions beyond own authority'; end if;
 return new; end $$;
create trigger role_assignment_authority before insert or update on public.role_assignments for each row execute function public.prevent_privilege_escalation();
create or replace function public.prevent_role_permission_escalation() returns trigger language plpgsql security definer set search_path=public as $$ begin
 if auth.uid() is null then return new; end if;
 if not has_master_permission('roles.manage',new.master_account_id) or not has_master_permission(new.permission_key,new.master_account_id) then raise exception 'cannot grant permissions beyond own authority'; end if;
 return new; end $$;
create trigger role_permission_authority before insert or update on public.role_permissions for each row execute function public.prevent_role_permission_escalation();

create or replace function public.validate_module_dependencies() returns trigger language plpgsql as $$ begin if new.enabled and exists(select 1 from unnest((select dependency_keys from module_catalog where key=new.module_key)) as deps(dep) where not exists(select 1 from site_modules sm where sm.site_id=new.site_id and sm.module_key=deps.dep and sm.enabled)) then raise exception 'required module dependency is disabled'; end if; return new; end $$;
create trigger module_dependencies before insert or update on public.site_modules for each row execute function public.validate_module_dependencies();

create or replace function public.reject_audit_mutation() returns trigger language plpgsql as $$ begin raise exception 'audit events are append-only'; end $$;
create trigger audit_immutable before update or delete on public.audit_events for each row execute function public.reject_audit_mutation();

alter table public.master_accounts enable row level security; alter table public.sites enable row level security; alter table public.roles enable row level security; alter table public.role_permissions enable row level security; alter table public.role_assignments enable row level security; alter table public.site_modules enable row level security; alter table public.subscription_invoices enable row level security; alter table public.subscription_invoice_lines enable row level security; alter table public.audit_events enable row level security;
create policy sites_read on public.sites for select to authenticated using(has_permission('sites.view',id));
create policy sites_manage on public.sites for all to authenticated using(has_permission('sites.manage',id)) with check(has_permission('sites.manage',id));
create policy account_read on public.master_accounts for select to authenticated using(exists(select 1 from role_assignments a where a.user_id=auth.uid() and a.master_account_id=id));
create policy roles_read on public.roles for select to authenticated using(exists(select 1 from role_assignments a where a.user_id=auth.uid() and a.master_account_id=roles.master_account_id));
create policy roles_manage on public.roles for all to authenticated using(has_master_permission('roles.manage',master_account_id)) with check(has_master_permission('roles.manage',master_account_id));
create policy role_permissions_read on public.role_permissions for select to authenticated using(exists(select 1 from role_assignments a where a.user_id=auth.uid() and a.master_account_id=role_permissions.master_account_id));
create policy role_permissions_manage on public.role_permissions for all to authenticated using(has_master_permission('roles.manage',master_account_id)) with check(has_master_permission('roles.manage',master_account_id));
create policy assignments_read on public.role_assignments for select to authenticated using(user_id=auth.uid() or exists(select 1 from role_assignments own where own.user_id=auth.uid() and own.master_account_id=role_assignments.master_account_id));
create policy assignments_manage on public.role_assignments for insert to authenticated with check(has_permission('roles.manage',site_id));
create policy modules_read on public.site_modules for select to authenticated using(has_permission('sites.view',site_id));
create policy modules_manage on public.site_modules for all to authenticated using(has_permission('modules.manage',site_id)) with check(has_permission('modules.manage',site_id));
create policy invoices_read on public.subscription_invoices for select to authenticated using(has_master_permission('subscription.view',master_account_id));
create policy lines_read on public.subscription_invoice_lines for select to authenticated using(has_permission('subscription.view',site_id));
create policy audits_read on public.audit_events for select to authenticated using(has_permission('audit.view',site_id));

grant select on public.master_accounts,public.sites,public.permissions,public.roles,public.role_permissions,public.role_assignments,public.module_catalog,public.site_modules,public.subscription_invoices,public.subscription_invoice_lines,public.audit_events to authenticated;
grant insert,update on public.site_modules,public.roles,public.role_permissions,public.role_assignments to authenticated;
commit;
