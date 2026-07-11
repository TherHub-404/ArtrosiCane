import Link from 'next/link';

export const dynamic = 'force-dynamic';

export default function ForbiddenPage() {
  return (
    <div className="login-shell">
      <div className="login-card">
        <div className="login-icon" aria-hidden />
        <h1>Accesso non autorizzato</h1>
        <p>
          Questa email non e nella lista dei manutentori autorizzati.
          Se pensi sia un errore, contatta il responsabile dell&apos;app.
        </p>
        <Link href="/dashboard/login" className="btn btn-primary" style={{ width: '100%' }}>
          Riprova con un&apos;altra email
        </Link>
      </div>
    </div>
  );
}
