import { redirect } from 'next/navigation';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { isMaintainer } from '@/lib/auth/maintainers';
import LoginForm from './login-form';

export const dynamic = 'force-dynamic';

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ sent?: string; error?: string }>;
}) {
  const { sent, error } = await searchParams;
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (user && isMaintainer(user.email)) redirect('/dashboard');

  return (
    <div className="login-shell">
      <div className="login-card">
        <div className="login-icon" aria-hidden />
        <h1>Dashboard ZampaSiCura</h1>
        <p>
          Inserisci la tua email e ti invieremo un link sicuro per accedere.
          Solo gli account autorizzati possono entrare.
        </p>
        <LoginForm />
        {sent && (
          <div className="alert alert-success">
            Link inviato! Controlla la posta in arrivo (anche lo spam) e clicca per accedere.
          </div>
        )}
        {error && (
          <div className="alert alert-error">
            {decodeURIComponent(error)}
          </div>
        )}
      </div>
    </div>
  );
}
