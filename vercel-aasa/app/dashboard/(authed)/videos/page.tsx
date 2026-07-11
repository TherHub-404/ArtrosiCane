import Link from 'next/link';
import { listAdviceVideos, adviceVideoPublicUrl } from '@/lib/dashboard/videos';
import VideosList from './videos-list';

export const dynamic = 'force-dynamic';

export default async function VideosPage() {
  const videos = await listAdviceVideos();
  const publicBase = adviceVideoPublicUrl('').replace(/\/$/, '');
  const active = videos.filter((v) => v.is_active).length;

  return (
    <>
      <div className="stat-grid">
        <div className="stat">
          <p className="stat-label">Video totali</p>
          <p className="stat-value">{videos.length}</p>
        </div>
        <div className="stat">
          <p className="stat-label">Attivi nell&apos;app</p>
          <p className="stat-value">{active}</p>
        </div>
      </div>

      <div className="card">
        <div
          className="card-pad"
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-start',
            gap: 16,
            paddingBottom: 14,
          }}
        >
          <div>
            <h2 className="card-title">Video passeggiate</h2>
            <p className="card-subtitle" style={{ margin: 0 }}>
              I video mostrati nella tab Passeggiate dell&apos;app, in ordine di posizione.
            </p>
          </div>
          <Link href="/dashboard/videos/new" className="btn btn-primary">
            + Aggiungi video
          </Link>
        </div>
        <VideosList videos={videos} publicBase={publicBase} />
      </div>
    </>
  );
}
