import Link from 'next/link';
import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { isMaintainer } from '@/lib/auth/maintainers';
import { initials } from '@/lib/dashboard/format';

export default async function AuthedLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/dashboard/login');
  if (!isMaintainer(user.email)) redirect('/dashboard/auth/forbidden');

  const email = user.email ?? '';

  return (
    <div className="dash-container">
      <header className="dash-header">
        <Link href="/dashboard" className="brand">
          <span className="brand-icon" aria-hidden />
          <span>ZampaSiCura · Dashboard</span>
        </Link>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <span className="user-chip">
            <span className="avatar">{initials(email)}</span>
            <span>{email}</span>
          </span>
          <form action="/dashboard/logout" method="post">
            <button type="submit" className="btn btn-ghost">Esci</button>
          </form>
        </div>
      </header>
      <nav className="dash-nav">
        <Link href="/dashboard">Profili</Link>
        <Link href="/dashboard/videos">Video</Link>
      </nav>
      {children}
    </div>
  );
}
