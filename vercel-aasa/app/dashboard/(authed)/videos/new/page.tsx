import Link from 'next/link';
import VideoForm from '../video-form';

export const dynamic = 'force-dynamic';

export default function NewVideoPage() {
  return (
    <>
      <div style={{ marginBottom: 16 }}>
        <Link href="/dashboard/videos" className="btn btn-link">
          ← Tutti i video
        </Link>
      </div>
      <h1 className="card-title" style={{ fontSize: 24, marginBottom: 18 }}>
        Nuovo video
      </h1>
      <VideoForm />
    </>
  );
}
