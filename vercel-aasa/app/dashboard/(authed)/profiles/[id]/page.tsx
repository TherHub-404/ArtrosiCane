import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getProfileById, getDogsForOwner } from '@/lib/dashboard/queries';
import {
  formatDate,
  formatDateTime,
  riskColor,
  riskLabel,
} from '@/lib/dashboard/format';

export const dynamic = 'force-dynamic';

export default async function ProfileDetail({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const profile = await getProfileById(id);
  if (!profile) notFound();

  const dogs = await getDogsForOwner(id);

  return (
    <>
      <div style={{ marginBottom: 18 }}>
        <Link href="/dashboard" className="btn btn-link">
          ← Tutti i profili
        </Link>
      </div>

      <div className="card card-pad" style={{ marginBottom: 22 }}>
        <h1 className="card-title" style={{ fontSize: 24 }}>
          {profile.nickname ?? profile.email ?? '—'}
        </h1>
        <p className="card-subtitle">{profile.email ?? '—'}</p>

        <dl className="kvp">
          <dt>ID profilo</dt>
          <dd className="mono">{profile.id}</dd>
          <dt>Auth user ID</dt>
          <dd className="mono">{profile.auth_user_id ?? '—'}</dd>
          <dt>Stato</dt>
          <dd>
            {profile.auth_user_id ? (
              <span className="badge-pill green">Autenticato</span>
            ) : (
              <span className="badge-pill gray">Non autenticato (pre-popolato)</span>
            )}
            {profile.is_deleted && (
              <>
                {' '}
                <span className="badge-pill red">Eliminato</span>
              </>
            )}
          </dd>
          <dt>Registrato il</dt>
          <dd>{formatDateTime(profile.created_at)}</dd>
          {profile.deleted_at && (
            <>
              <dt>Eliminato il</dt>
              <dd>{formatDateTime(profile.deleted_at)}</dd>
            </>
          )}
        </dl>
      </div>

      <h3 className="section-title">Cani ({dogs.length})</h3>
      {dogs.length === 0 ? (
        <div className="card empty-state">Nessun cane associato a questo profilo.</div>
      ) : (
        <div className="dog-grid">
          {dogs.map((d) => {
            const r = riskColor(d.risk_level);
            return (
              <Link
                key={d.id}
                href={`/dashboard/dogs/${d.id}`}
                className="card dog-card"
                prefetch
              >
                <div className="dog-photo">
                  {d.image_url ? (
                    /* eslint-disable-next-line @next/next/no-img-element */
                    <img src={d.image_url} alt={d.name ?? 'Cane'} />
                  ) : (
                    <div className="dog-photo-placeholder">
                      <span>{(d.name ?? '?').charAt(0).toUpperCase()}</span>
                    </div>
                  )}
                </div>
                <div className="card-pad">
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
                    <h4 style={{ margin: 0, fontSize: 17, fontWeight: 800 }}>
                      {d.name ?? '—'}
                    </h4>
                    <span className={`badge-pill ${r}`}>{riskLabel(d.risk_level)}</span>
                  </div>
                  <p className="muted" style={{ fontSize: 13, margin: '4px 0 12px' }}>
                    {d.breed_name_it ?? d.breed_name ?? 'Razza sconosciuta'}
                  </p>
                  <dl className="kvp" style={{ gridTemplateColumns: '110px 1fr', fontSize: 13 }}>
                    <dt>Eta</dt>
                    <dd>{d.age_years != null ? `${d.age_years} anni` : '—'}</dd>
                    <dt>Peso</dt>
                    <dd>{d.weight_kg != null ? `${d.weight_kg} kg` : '—'}</dd>
                    <dt>Diagnosi</dt>
                    <dd>{d.diagnosis_status ?? '—'}</dd>
                    <dt>Diagnosi del</dt>
                    <dd>{formatDate(d.diagnosis_date)}</dd>
                    <dt>Ultimo check</dt>
                    <dd>{formatDateTime(d.last_check_at)}</dd>
                  </dl>
                  <div className="dog-cta">
                    <span>Vedi daily check</span>
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                      <path d="M5 12h14M13 6l6 6-6 6" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </>
  );
}
