'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useDeferredValue, useMemo, useState } from 'react';
import type { ProfileRow } from '@/lib/dashboard/types';
import { formatDateTime, semaphoreColor, semaphoreLabel } from '@/lib/dashboard/format';

type Classification =
  | 'web_migrated_never_logged_in'
  | 'web_migrated_active'
  | 'self_signup_incomplete'
  | 'self_signup_active'
  | 'pre_populated'
  | 'orphan_auth';

function classify(p: ProfileRow): Classification {
  if (p.kind === 'orphan_auth') return 'orphan_auth';
  if (!p.auth_user_id) return 'pre_populated';
  if (p.is_web_migrated && !p.last_sign_in_at) return 'web_migrated_never_logged_in';
  if (p.is_web_migrated) return 'web_migrated_active';
  if (p.dog_count === 0) return 'self_signup_incomplete';
  return 'self_signup_active';
}

export default function ProfilesTable({ profiles }: { profiles: ProfileRow[] }) {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [hideMigratedNeverLogged, setHideMigratedNeverLogged] = useState(true);
  const deferred = useDeferredValue(query);

  const annotated = useMemo(
    () => profiles.map((p) => ({ ...p, _class: classify(p) })),
    [profiles]
  );

  const migratedNeverLoggedCount = useMemo(
    () => annotated.filter((p) => p._class === 'web_migrated_never_logged_in').length,
    [annotated]
  );

  const filtered = useMemo(() => {
    const q = deferred.trim().toLowerCase();
    return annotated.filter((p) => {
      if (hideMigratedNeverLogged && p._class === 'web_migrated_never_logged_in') {
        return false;
      }
      if (!q) return true;
      const haystack = [p.email, p.nickname]
        .filter((v): v is string => typeof v === 'string')
        .map((v) => v.toLowerCase());
      return haystack.some((h) => h.includes(q));
    });
  }, [deferred, annotated, hideMigratedNeverLogged]);

  return (
    <>
      <div className="card-pad" style={{ paddingBottom: 12 }}>
        <h2 className="card-title">Profili utenti</h2>
        <p className="card-subtitle">
          Profili creati nell&apos;app, utenti migrati dal sito web e utenti
          registrati in Supabase senza riga profilo.
        </p>
        <div style={{ position: 'relative' }}>
          <input
            className="search"
            type="search"
            placeholder="Cerca per email o nickname..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoFocus
            style={{ paddingRight: 80 }}
          />
          <span
            className="muted"
            style={{
              position: 'absolute',
              right: 14,
              top: '50%',
              transform: 'translateY(-50%)',
              fontSize: 12,
              fontWeight: 600,
              pointerEvents: 'none',
            }}
          >
            {filtered.length} / {profiles.length}
          </span>
        </div>
        {migratedNeverLoggedCount > 0 && (
          <label
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 8,
              marginTop: 10,
              fontSize: 13,
              cursor: 'pointer',
              userSelect: 'none',
            }}
          >
            <input
              type="checkbox"
              checked={hideMigratedNeverLogged}
              onChange={(e) => setHideMigratedNeverLogged(e.target.checked)}
            />
            <span>
              Nascondi {migratedNeverLoggedCount} utenti migrati dal sito web mai
              loggati nell&apos;app
            </span>
          </label>
        )}
      </div>

      {filtered.length === 0 ? (
        <div className="empty-state">
          {query
            ? `Nessun profilo trovato per "${query}".`
            : 'Nessun profilo presente al momento.'}
        </div>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Email</th>
              <th>Nickname</th>
              <th>Stato</th>
              <th>Cani</th>
              <th>Ultimo check</th>
              <th>Registrato il</th>
              <th aria-label="Apri" />
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => {
              if (p.kind === 'orphan_auth') {
                return (
                  <tr
                    key={`o-${p.id}`}
                    className="row-orphan"
                    title="Utente registrato in Supabase Auth senza alcuna riga profilo associata."
                  >
                    <td>
                      <span style={{ fontWeight: 600 }}>{p.email ?? '—'}</span>
                    </td>
                    <td>{p.nickname ?? <span className="muted">—</span>}</td>
                    <td>
                      <span className="badge-pill yellow">Senza profilo</span>
                      {!p.email_confirmed_at && (
                        <>
                          {' '}
                          <span className="badge-pill gray">Email non confermata</span>
                        </>
                      )}
                    </td>
                    <td>
                      <span className="muted">—</span>
                    </td>
                    <td>
                      <span className="muted" style={{ fontSize: 12 }}>
                        {p.last_sign_in_at
                          ? `Ultimo login: ${formatDateTime(p.last_sign_in_at)}`
                          : 'Mai loggato in app'}
                      </span>
                    </td>
                    <td>{formatDateTime(p.created_at)}</td>
                    <td />
                  </tr>
                );
              }

              const sem = semaphoreColor(p.last_check_semaphore);
              const href = `/dashboard/profiles/${p.id}`;
              const cls = p._class;
              const stateBadge = (() => {
                if (cls === 'web_migrated_never_logged_in') {
                  return (
                    <span
                      className="badge-pill yellow"
                      title="Profilo importato dal sito web. L'utente non ha ancora effettuato il primo accesso nell'app."
                    >
                      Migrato · mai loggato
                    </span>
                  );
                }
                if (cls === 'web_migrated_active') {
                  return (
                    <span
                      className="badge-pill green"
                      title="Profilo importato dal sito web. L'utente ha già completato il primo accesso e impostato una password."
                    >
                      Migrato · attivo
                    </span>
                  );
                }
                if (cls === 'pre_populated') {
                  return (
                    <span
                      className="badge-pill gray"
                      title="Riga profilo pre-popolata non ancora associata a un account Supabase Auth."
                    >
                      Pre-popolato
                    </span>
                  );
                }
                if (cls === 'self_signup_incomplete') {
                  return (
                    <span
                      className="badge-pill yellow"
                      title="Utente che si è registrato nell'app ma non ha ancora aggiunto un cane."
                    >
                      Onboarding incompleto
                    </span>
                  );
                }
                return (
                  <span
                    className="badge-pill green"
                    title="Utente registrato nell'app con almeno un cane configurato."
                  >
                    Autenticato
                  </span>
                );
              })();
              return (
                <tr
                  key={p.id}
                  className="row-link"
                  onClick={() => router.push(href)}
                  onMouseEnter={() => router.prefetch(href)}
                >
                  <td>
                    <Link href={href} style={{ fontWeight: 600 }} prefetch>
                      {p.email ?? <span className="muted">—</span>}
                    </Link>
                  </td>
                  <td>{p.nickname ?? <span className="muted">—</span>}</td>
                  <td>
                    {stateBadge}
                    {p.is_deleted && (
                      <>
                        {' '}
                        <span className="badge-pill red">Eliminato</span>
                      </>
                    )}
                  </td>
                  <td>
                    <span className="badge-pill gray">
                      {p.dog_count} {p.dog_count === 1 ? 'cane' : 'cani'}
                    </span>
                  </td>
                  <td>
                    {p.last_check_at ? (
                      <>
                        <span className={`badge-pill ${sem}`}>
                          {semaphoreLabel(p.last_check_semaphore)}
                        </span>{' '}
                        <span className="muted" style={{ fontSize: 12 }}>
                          {formatDateTime(p.last_check_at)}
                        </span>
                      </>
                    ) : (
                      <span className="muted">—</span>
                    )}
                  </td>
                  <td>{formatDateTime(p.created_at)}</td>
                  <td style={{ textAlign: 'right' }}>
                    <Link href={href} className="row-cta" prefetch>
                      Apri
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                        <path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" />
                      </svg>
                    </Link>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </>
  );
}
