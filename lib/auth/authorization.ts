import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function serverSupabase() {
  const jar = await cookies();
  return createServerClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { cookies: { getAll: () => jar.getAll(), setAll: (items) => items.forEach(({ name, value, options }) => jar.set(name, value, options)) } });
}

/** Central authorization gate. RLS remains the final enforcement boundary. */
export async function requireCapability(permission: string, siteId?: string) {
  const supabase = await serverSupabase();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new AuthorizationError("Authentication required", 401);
  const { data, error } = await supabase.rpc("has_permission", { requested_permission: permission, requested_site_id: siteId ?? null });
  if (error || !data) throw new AuthorizationError("You do not have permission for this operation", 403);
  return { supabase, user };
}

export async function requireModule(siteId: string, moduleKey: string) {
  const { supabase, user } = await requireCapability(`${moduleKey}.use`, siteId);
  const { data } = await supabase.from("site_modules").select("enabled").eq("site_id", siteId).eq("module_key", moduleKey).maybeSingle();
  if (!data?.enabled) throw new AuthorizationError("This module is disabled for the selected site", 409);
  return { supabase, user };
}

export class AuthorizationError extends Error { constructor(message: string, readonly status: number) { super(message); } }
