begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
do $$ begin
 if (select count(*) from public.sites) <> 1 then raise exception 'single-site isolation failed'; end if;
 if exists(select 1 from public.sites where master_account_id='20000000-0000-0000-0000-000000000002') then raise exception 'cross-tenant isolation failed'; end if;
 if public.has_permission('modules.manage','30000000-0000-0000-0000-000000000001') then raise exception 'custom role permission failed'; end if;
end $$;
rollback;
