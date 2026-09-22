"use server";
import { redirect } from "next/navigation";
import { serverSupabase } from "@/lib/auth/authorization";
export async function signIn(formData: FormData) { const supabase=await serverSupabase(); const email=String(formData.get("email")??""); const password=String(formData.get("password")??""); const {error}=await supabase.auth.signInWithPassword({email,password}); if(error) redirect(`/login?error=${encodeURIComponent("Invalid email or password")}`); redirect("/"); }
