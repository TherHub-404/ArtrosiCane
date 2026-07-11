import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getDailyLogs, getDogById } from '@/lib/dashboard/queries';
import {
  formatDate,
  formatDateTime,
  relative,
  riskColor,
  riskLabel,
  semaphoreColor,
  semaphoreLabel,
} from '@/lib/dashboard/format';

export const dynamic = 'force-dynamic';

const CHART_DAYS = 30;

type DayBucket = { day: string; semaphore: string | null; score: number };

function aggregateByDay(logs: Array<{ created_at: string | null; semaphore: string | null; score: number | null }>): DayBucket[] {
  const score = (s: string | null | undefined) => {
    const v = (s ?? '').toLowerCase();
    if (v === 'rosso' || v === 'red') return 3;
    if (v === 'giallo' || v === 'yellow') return 2;
    if (v === 'verde' || v === 'green') return 1;
    return 0;
  };

  const map = new Map<string, DayBucket>();
  for (const log of logs) {
    if (!log.created_at) continue;
    const d = new Date(log.created_at);
    if (Number.isNaN(d.getTime())) continue;
    const key = d.toISOString().slice(0, 10);
    const existing = map.get(key);
    const candidate: DayBucket = {
      day: key,
      semaphore: log.semaphore,
      score: log.score ?? 0,
    };
    if (!existing || score(candidate.semaphore) > score(existing.semaphore) ||
        (score(candidate.semaphore) === score(existing.semaphore) && candidate.score > existing.score)) {
      map.set(key, candidate);
    }
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const out: DayBucket[] = [];
  for (let i = CHART_DAYS - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    out.push(map.get(key) ?? { day: key, semaphore: null, score: 0 });
  }
  return out;
}

export default async function DogDetail({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const dog = await getDogById(id);
  if (!dog) notFound();

  const logs = await getDailyLogs(id, 90);
  const chartData = aggregateByDay(logs);

  const totals = {
    green: logs.filter((l) => semaphoreColor(l.semaphore) === 'green').length,
    yellow: logs.filter((l) => semaphoreColor(l.semaphore) === 'yellow').length,
    red: logs.filter((l) => semaphoreColor(l.semaphore) === 'red').length,
  };

  return (
    <>
      <div style={{ marginBottom: 18 }}>
        {dog.owner_id ? (
          <Link href={`/dashboard/profiles/${dog.owner_id}`} className="btn btn-link">
            ← Profilo proprietario
          </Link>
        ) : (
          <Link href="/dashboard" className="btn btn-link">← Dashboard</Link>
        )}
      </div>

      <div className="card" style={{ marginBottom: 22, overflow: 'hidden' }}>
        <div className="dog-photo dog-photo-large">
          {dog.image_url ? (
            /* eslint-disable-next-line @next/next/no-img-element */
            <img src={dog.image_url} alt={dog.name ?? 'Cane'} />
          ) : (
            <div className="dog-photo-placeholder">
              <span>{(dog.name ?? '?').charAt(0).toUpperCase()}</span>
            </div>
          )}
        </div>
        <div className="card-pad">
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12 }}>
          <h1 className="card-title" style={{ fontSize: 24 }}>{dog.name ?? '—'}</h1>
          <span className={`badge-pill ${riskColor(dog.risk_level)}`}>
            Rischio {riskLabel(dog.risk_level)}
          </span>
        </div>
        <p className="card-subtitle">
          {dog.breed_name_it ?? dog.breed_name ?? 'Razza sconosciuta'}
        </p>

        <dl className="kvp">
          <dt>Età</dt>
          <dd>{dog.age_years != null ? `${dog.age_years} anni` : '—'}</dd>
          <dt>Peso</dt>
          <dd>{dog.weight_kg != null ? `${dog.weight_kg} kg` : '—'}</dd>
          <dt>Taglia</dt>
          <dd>{dog.size ?? '—'}</dd>
          <dt>Fascia età</dt>
          <dd>{dog.age_group ?? '—'}</dd>
          <dt>Diagnosi</dt>
          <dd>{dog.diagnosis_status ?? '—'}</dd>
          <dt>Data diagnosi</dt>
          <dd>{formatDate(dog.diagnosis_date)}</dd>
          <dt>Veterinario</dt>
          <dd>{dog.diagnosis_vet ?? '—'}</dd>
          <dt>Ultimo daily check</dt>
          <dd>
            {dog.last_check_at
              ? `${relative(dog.last_check_at)} (${formatDateTime(dog.last_check_at)})`
              : '—'}
          </dd>
        </dl>
        </div>
      </div>

      <h3 className="section-title">Andamento ultimi {CHART_DAYS} giorni</h3>
      <div className="card card-pad" style={{ marginBottom: 22 }}>
        <div className="stat-grid" style={{ marginBottom: 12 }}>
          <div className="stat">
            <p className="stat-label">Verdi</p>
            <p className="stat-value" style={{ color: 'var(--success)' }}>{totals.green}</p>
          </div>
          <div className="stat">
            <p className="stat-label">Gialli</p>
            <p className="stat-value" style={{ color: 'var(--warn)' }}>{totals.yellow}</p>
          </div>
          <div className="stat">
            <p className="stat-label">Rossi</p>
            <p className="stat-value" style={{ color: 'var(--danger)' }}>{totals.red}</p>
          </div>
          <div className="stat">
            <p className="stat-label">Totali (90gg)</p>
            <p className="stat-value">{logs.length}</p>
          </div>
        </div>
        <div className="chart-shell">
          {chartData.map((b) => {
            const c = semaphoreColor(b.semaphore);
            const heightPct = b.semaphore ? Math.max(20, Math.min(100, (b.score / 8) * 100 + 20)) : 5;
            return (
              <div
                key={b.day}
                className={`chart-bar ${c}`}
                style={{ height: `${heightPct}%` }}
                title={`${b.day} — ${semaphoreLabel(b.semaphore)} (score ${b.score})`}
              />
            );
          })}
        </div>
        <div className="chart-axis">
          {chartData.map((b, i) => (
            <span key={b.day}>
              {i === 0 || i === chartData.length - 1 || i % 7 === 0 ? b.day.slice(5) : ''}
            </span>
          ))}
        </div>
      </div>

      <h3 className="section-title">Ultimi check</h3>
      {logs.length === 0 ? (
        <div className="card empty-state">Nessun daily check registrato.</div>
      ) : (
        <div className="card">
          <table className="table">
            <thead>
              <tr>
                <th>Data</th>
                <th>Stato</th>
                <th>Score</th>
                <th>Raw</th>
                <th>Percorso</th>
              </tr>
            </thead>
            <tbody>
              {logs.slice(0, 30).map((l, idx) => (
                <tr key={`${l.created_at}-${idx}`}>
                  <td>{formatDateTime(l.created_at)}</td>
                  <td>
                    <span className={`badge-pill ${semaphoreColor(l.semaphore)}`}>
                      {semaphoreLabel(l.semaphore)}
                    </span>
                  </td>
                  <td>{l.score ?? '—'}</td>
                  <td className="muted">{l.raw_score ?? '—'}</td>
                  <td className="muted">{l.route_tag ?? '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
