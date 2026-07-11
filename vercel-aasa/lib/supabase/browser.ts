'use client';

import { createClient } from '@supabase/supabase-js';

/// Lightweight browser Supabase client used only for direct Storage uploads
/// via signed upload URLs (the token authorizes the upload — no session
/// needed). Never used for privileged reads/writes.
export function createSupabaseBrowserClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anon) {
    throw new Error('Missing NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY');
  }
  return createClient(url, anon, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
