'use server';

import { headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { isMaintainer } from '@/lib/auth/maintainers';

export async function sendMagicLink(rawEmail: string) {
  const email = (rawEmail ?? '').trim().toLowerCase();
  if (!email || !email.includes('@')) {
    return { error: 'Inserisci un indirizzo email valido.' };
  }
  if (!isMaintainer(email)) {
    return { error: 'Questa email non e autorizzata ad accedere alla dashboard.' };
  }

  const hdrs = await headers();
  const proto = hdrs.get('x-forwarded-proto') ?? 'https';
  const host = hdrs.get('x-forwarded-host') ?? hdrs.get('host') ?? 'artrosicane.vercel.app';
  const origin = `${proto}://${host}`;

  const supabase = await createSupabaseServerClient();
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${origin}/dashboard/auth/callback`,
      shouldCreateUser: true,
    },
  });

  if (error) {
    return { error: `Impossibile inviare il link: ${error.message}` };
  }

  redirect('/dashboard/login?sent=1');
}
