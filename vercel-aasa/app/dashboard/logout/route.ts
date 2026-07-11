import { NextResponse, type NextRequest } from 'next/server';
import { createSupabaseMiddlewareClient } from '@/lib/supabase/middleware-client';

export async function POST(req: NextRequest) {
  const { origin } = new URL(req.url);
  const res = NextResponse.redirect(`${origin}/dashboard/login`, { status: 303 });
  const supabase = createSupabaseMiddlewareClient(req, res);
  await supabase.auth.signOut();
  return res;
}
