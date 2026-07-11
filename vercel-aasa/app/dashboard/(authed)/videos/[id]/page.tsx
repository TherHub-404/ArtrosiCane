import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getAdviceVideo } from '@/lib/dashboard/videos';
import VideoForm from '../video-form';

export const dynamic = 'force-dynamic';

export default async function EditVideoPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const video = await getAdviceVideo(id);
  if (!video) notFound();

  return (
    <>
      <div style={{ marginBottom: 16 }}>
        <Link href="/dashboard/videos" className="btn btn-link">
          ← Tutti i video
        </Link>
      </div>
      <h1 className="card-title" style={{ fontSize: 24, marginBottom: 18 }}>
        Modifica video
      </h1>
      <VideoForm
        initial={{
          id: video.id,
          title: video.title ?? {},
          description: video.description ?? {},
          storagePath: video.storage_path,
          position: video.position,
          isActive: video.is_active,
        }}
      />
    </>
  );
}
