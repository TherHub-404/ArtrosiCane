'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { createSupabaseAdmin } from '@/lib/supabase/admin';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { isMaintainer } from '@/lib/auth/maintainers';
import { ADVICE_VIDEOS_BUCKET } from '@/lib/dashboard/videos';

async function assertMaintainer() {
  const supabase = await createSupabaseServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user || !isMaintainer(user.email)) {
    throw new Error('Non autorizzato');
  }
}

/// Returns a signed upload URL so the browser can push the video file
/// straight to Storage (bypassing Vercel's 4.5 MB request body limit).
export async function createVideoUploadUrl(
  originalName: string,
): Promise<{ path: string; token: string }> {
  await assertMaintainer();

  const dot = originalName.lastIndexOf('.');
  const ext = dot >= 0 ? originalName.slice(dot).toLowerCase() : '.mp4';
  const base = (dot >= 0 ? originalName.slice(0, dot) : originalName)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48) || 'video';
  const path = `${Date.now()}-${base}${ext}`;

  const admin = createSupabaseAdmin();
  const { data, error } = await admin.storage
    .from(ADVICE_VIDEOS_BUCKET)
    .createSignedUploadUrl(path);
  if (error || !data) {
    throw new Error(error?.message ?? 'Impossibile creare l\'URL di upload');
  }
  return { path: data.path, token: data.token };
}

export type SaveVideoInput = {
  id?: string;
  title: Record<string, string>;
  description: Record<string, string>;
  storagePath: string;
  position: number;
  isActive: boolean;
};

export async function saveVideo(input: SaveVideoInput): Promise<void> {
  await assertMaintainer();

  const title = Object.fromEntries(
    Object.entries(input.title).map(([k, v]) => [k, (v ?? '').trim()]),
  );
  const description = Object.fromEntries(
    Object.entries(input.description).map(([k, v]) => [k, (v ?? '').trim()]),
  );

  if (!title.it) throw new Error('Il titolo in italiano è obbligatorio.');
  if (!input.storagePath) throw new Error('Il file video è obbligatorio.');

  const admin = createSupabaseAdmin();
  const payload = {
    title,
    description,
    storage_path: input.storagePath,
    position: Number.isFinite(input.position) ? input.position : 0,
    is_active: input.isActive,
  };

  if (input.id) {
    const { error } = await admin
      .from('advice_videos')
      .update(payload)
      .eq('id', input.id);
    if (error) throw new Error(error.message);
  } else {
    const { error } = await admin.from('advice_videos').insert(payload);
    if (error) throw new Error(error.message);
  }

  revalidatePath('/dashboard/videos');
  redirect('/dashboard/videos');
}

export async function toggleVideoActive(
  id: string,
  isActive: boolean,
): Promise<void> {
  await assertMaintainer();
  const admin = createSupabaseAdmin();
  const { error } = await admin
    .from('advice_videos')
    .update({ is_active: isActive })
    .eq('id', id);
  if (error) throw new Error(error.message);
  revalidatePath('/dashboard/videos');
}

export async function deleteVideo(
  id: string,
  storagePath: string,
): Promise<void> {
  await assertMaintainer();
  const admin = createSupabaseAdmin();
  const { error } = await admin.from('advice_videos').delete().eq('id', id);
  if (error) throw new Error(error.message);
  if (storagePath) {
    await admin.storage
      .from(ADVICE_VIDEOS_BUCKET)
      .remove([storagePath])
      .catch(() => {});
  }
  revalidatePath('/dashboard/videos');
}
