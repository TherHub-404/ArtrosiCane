import { NextResponse, type NextRequest } from 'next/server';
import { createSupabaseMiddlewareClient } from '@/lib/supabase/middleware-client';
import { isMaintainer } from '@/lib/auth/maintainers';

export async function GET(req: NextRequest) {
  const { searchParams, origin } = new URL(req.url);
  const code = searchParams.get('code');
  const errorParam = searchParams.get('error_description') ?? searchParams.get('error');

  if (errorParam) {
    return NextResponse.redirect(
      `${origin}/dashboard/login?error=${encodeURIComponent(errorParam)}`
    );
  }

  if (!code) {
    return NextResponse.redirect(
      `${origin}/dashboard/login?error=${encodeURIComponent('Link non valido o scaduto.')}`
    );
  }

  const res = NextResponse.redirect(`${origin}/dashboard`);
  const supabase = createSupabaseMiddlewareClient(req, res);
  const { data, error } = await supabase.auth.exchangeCodeForSession(code);
  if (error || !data?.user) {
    return NextResponse.redirect(
      `${origin}/dashboard/login?error=${encodeURIComponent(
        error?.message ?? 'Sessione non creata.'
      )}`
    );
  }

  if (!isMaintainer(data.user.email)) {
    await supabase.auth.signOut();
    return NextResponse.redirect(`${origin}/dashboard/auth/forbidden`);
  }

  return res;
}
