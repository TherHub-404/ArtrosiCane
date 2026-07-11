'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useTransition } from 'react';
import type { AdviceVideoRow } from '@/lib/dashboard/videos';
import { deleteVideo, toggleVideoActive } from './actions';

export default function VideosList({
  videos,
  publicBase,
}: {
  videos: AdviceVideoRow[];
  publicBase: string;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  function onToggle(v: AdviceVideoRow) {
    startTransition(async () => {
      await toggleVideoActive(v.id, !v.is_active);
      router.refresh();
    });
  }

  function onDelete(v: AdviceVideoRow) {
    const name = v.title.it || v.storage_path;
    if (!window.confirm(`Eliminare il video "${name}"? L'operazione è definitiva.`)) {
      return;
    }
    startTransition(async () => {
      await deleteVideo(v.id, v.storage_path);
      router.refresh();
    });
  }

  if (videos.length === 0) {
    return (
      <div className="empty-state">
        Nessun video. Premi &quot;Aggiungi video&quot; per crearne uno.
      </div>
    );
  }

  return (
    <table className="table">
      <thead>
        <tr>
          <th style={{ width: 60 }}>#</th>
          <th>Titolo (IT)</th>
          <th>File</th>
          <th>Stato</th>
          <th aria-label="Azioni" />
        </tr>
      </thead>
      <tbody>
        {videos.map((v) => (
          <tr key={v.id}>
            <td>{v.position}</td>
            <td style={{ fontWeight: 600 }}>
              {v.title.it || <span className="muted">— senza titolo —</span>}
            </td>
            <td>
              <a
                href={`${publicBase}/${v.storage_path}`}
                target="_blank"
                rel="noopener"
                className="mono"
                style={{ fontSize: 12, color: 'var(--brand)' }}
              >
                {v.storage_path}
              </a>
            </td>
            <td>
              <button
                type="button"
                className={`badge-pill ${v.is_active ? 'green' : 'gray'}`}
                style={{ border: 'none', cursor: 'pointer' }}
                disabled={pending}
                onClick={() => onToggle(v)}
                title="Clicca per cambiare stato"
              >
                {v.is_active ? 'Attivo' : 'Nascosto'}
              </button>
            </td>
            <td style={{ textAlign: 'right', whiteSpace: 'nowrap' }}>
              <Link href={`/dashboard/videos/${v.id}`} className="btn-link">
                Modifica
              </Link>
              <button
                type="button"
                className="btn-link"
                style={{ color: 'var(--danger)' }}
                disabled={pending}
                onClick={() => onDelete(v)}
              >
                Elimina
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
