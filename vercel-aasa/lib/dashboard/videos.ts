import 'server-only';
import { createSupabaseAdmin } from '@/lib/supabase/admin';

export const ADVICE_VIDEOS_BUCKET = 'advice-videos';
export const LANGUAGES = ['it', 'en', 'fr', 'de'] as const;
export type Language = (typeof LANGUAGES)[number];
export const LANGUAGE_LABELS: Record<Language, string> = {
  it: 'Italiano',
  en: 'English',
  fr: 'Français',
  de: 'Deutsch',
};

export type AdviceVideoRow = {
  id: string;
  title: Record<string, string>;
  description: Record<string, string>;
  storage_path: string;
  position: number;
  is_active: boolean;
  created_at: string;
};

export function adviceVideoPublicUrl(storagePath: string): string {
  const base = process.env.NEXT_PUBLIC_SUPABASE_URL ?? '';
  return `${base}/storage/v1/object/public/${ADVICE_VIDEOS_BUCKET}/${storagePath}`;
}

export async function listAdviceVideos(): Promise<AdviceVideoRow[]> {
  const admin = createSupabaseAdmin();
  const { data, error } = await admin
    .from('advice_videos')
    .select('id, title, description, storage_path, position, is_active, created_at')
    .order('position', { ascending: true });
  if (error) throw new Error(`advice_videos: ${error.message}`);
  return (data ?? []) as AdviceVideoRow[];
}

export async function getAdviceVideo(id: string): Promise<AdviceVideoRow | null> {
  const admin = createSupabaseAdmin();
  const { data, error } = await admin
    .from('advice_videos')
    .select('id, title, description, storage_path, position, is_active, created_at')
    .eq('id', id)
    .maybeSingle();
  if (error) throw new Error(`advice_video: ${error.message}`);
  return (data as AdviceVideoRow) ?? null;
}
