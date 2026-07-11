import 'server-only';
import { createSupabaseAdmin } from '@/lib/supabase/admin';
import type { Profile, ProfileRow, DogWithRisk, DailyLog } from './types';

const DOG_IMAGE_CANDIDATES = [
  'profile_image_url',
  'dog_image_url',
  'photo_url',
  'image_url',
  'avatar_url',
] as const;
const DOG_IMAGE_BUCKETS = ['dog-profile-images', 'dog-diagnosis-files'];

async function resolveDogImage(
  row: Record<string, unknown>,
  breedFallback: string | null
): Promise<string | null> {
  let raw: string | null = null;
  for (const key of DOG_IMAGE_CANDIDATES) {
    const v = row[key];
    if (typeof v === 'string' && v.length > 0) {
      raw = v;
      break;
    }
  }
  const candidate = raw ?? breedFallback;
  if (!candidate) return null;
  if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
    return candidate;
  }

  const admin = createSupabaseAdmin();
  if (candidate.startsWith('storage://')) {
    const without = candidate.slice('storage://'.length);
    const idx = without.indexOf('/');
    if (idx === -1) return null;
    const bucket = without.slice(0, idx);
    const path = without.slice(idx + 1);
    const { data } = await admin.storage.from(bucket).createSignedUrl(path, 3600);
    return data?.signedUrl ?? null;
  }

  for (const bucket of DOG_IMAGE_BUCKETS) {
    const { data, error } = await admin.storage.from(bucket).createSignedUrl(candidate, 3600);
    if (!error && data?.signedUrl) return data.signedUrl;
  }
  return null;
}

export async function listProfiles(): Promise<ProfileRow[]> {
  const admin = createSupabaseAdmin();

  // Fetch ALL profiles in pages. The previous .limit(500) silently dropped
  // ~350 web-migrated rows, which then re-appeared as `orphan_auth` because
  // the email/auth_user_id index couldn't match them.
  const rows: Profile[] = [];
  const pageSize = 1000;
  for (let from = 0; ; from += pageSize) {
    const { data, error } = await admin
      .from('profiles')
      .select(
        'id, email, nickname, auth_user_id, created_at, is_deleted, deleted_at, is_web_migrated'
      )
      .order('created_at', { ascending: false })
      .range(from, from + pageSize - 1);
    if (error) throw new Error(`profiles: ${error.message}`);
    const batch = (data ?? []) as Profile[];
    rows.push(...batch);
    if (batch.length < pageSize) break;
  }

  const ownerIds = rows.map((p) => p.id);
  const [dogsByOwner, lastCheckByOwner, authMetaById] = await Promise.all([
    fetchDogCounts(ownerIds),
    fetchLastCheckByOwner(ownerIds),
    fetchAuthMetadataByUserId(),
  ]);

  const profileRows: ProfileRow[] = rows.map((p) => {
    const auth = p.auth_user_id ? authMetaById.get(p.auth_user_id) : null;
    return {
      ...p,
      dog_count: dogsByOwner.get(p.id) ?? 0,
      last_check_at: lastCheckByOwner.get(p.id)?.created_at ?? null,
      last_check_semaphore: lastCheckByOwner.get(p.id)?.semaphore ?? null,
      kind: 'profile' as const,
      email_confirmed_at: auth?.email_confirmed_at ?? null,
      last_sign_in_at: auth?.last_sign_in_at ?? null,
    };
  });

  const orphans = await listOrphanAuthUsers(profileRows, authMetaById);
  return [...profileRows, ...orphans].sort((a, b) => {
    const ta = a.created_at ? Date.parse(a.created_at) : 0;
    const tb = b.created_at ? Date.parse(b.created_at) : 0;
    return tb - ta;
  });
}

type AuthUserMeta = {
  id: string;
  email: string | null;
  created_at: string | null;
  email_confirmed_at: string | null;
  last_sign_in_at: string | null;
  user_metadata: Record<string, unknown> | null;
};

async function fetchAuthMetadataByUserId(): Promise<Map<string, AuthUserMeta>> {
  const admin = createSupabaseAdmin();
  const out = new Map<string, AuthUserMeta>();
  let page = 1;
  while (true) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) {
      console.warn('[dashboard] auth.admin.listUsers failed:', error.message);
      break;
    }
    for (const u of data.users) {
      out.set(u.id, {
        id: u.id,
        email: u.email ?? null,
        created_at: u.created_at ?? null,
        email_confirmed_at: u.email_confirmed_at ?? null,
        last_sign_in_at: u.last_sign_in_at ?? null,
        user_metadata: (u.user_metadata as Record<string, unknown>) ?? null,
      });
    }
    if (data.users.length < 200) break;
    page += 1;
  }
  return out;
}

async function listOrphanAuthUsers(
  profiles: ProfileRow[],
  authMetaById: Map<string, AuthUserMeta>
): Promise<ProfileRow[]> {
  const profileAuthIds = new Set(profiles.map((p) => p.auth_user_id).filter(Boolean) as string[]);
  const profileEmails = new Set(
    profiles.map((p) => (p.email ?? '').toLowerCase()).filter(Boolean)
  );

  const orphans: ProfileRow[] = [];
  for (const u of authMetaById.values()) {
    const email = (u.email ?? '').toLowerCase();
    if (profileAuthIds.has(u.id)) continue;
    if (email && profileEmails.has(email)) continue;
    orphans.push({
      id: u.id,
      email: u.email,
      nickname: (u.user_metadata?.nickname as string | undefined) ?? null,
      auth_user_id: u.id,
      created_at: u.created_at,
      is_deleted: null,
      deleted_at: null,
      is_web_migrated: null,
      dog_count: 0,
      last_check_at: null,
      last_check_semaphore: null,
      kind: 'orphan_auth',
      email_confirmed_at: u.email_confirmed_at,
      last_sign_in_at: u.last_sign_in_at,
    });
  }
  return orphans;
}

async function fetchDogCounts(ownerIds: string[]) {
  const admin = createSupabaseAdmin();
  const out = new Map<string, number>();
  if (ownerIds.length === 0) return out;
  const { data, error } = await admin
    .from('dogs')
    .select('owner_id, is_deleted')
    .in('owner_id', ownerIds);
  if (error) {
    console.warn('[dashboard] dogs count failed:', error.message);
    return out;
  }
  for (const row of (data ?? []) as Array<{ owner_id: string; is_deleted: boolean | null }>) {
    if (row.is_deleted) continue;
    out.set(row.owner_id, (out.get(row.owner_id) ?? 0) + 1);
  }
  return out;
}

async function fetchLastCheckByOwner(ownerIds: string[]) {
  const admin = createSupabaseAdmin();
  const out = new Map<string, { created_at: string; semaphore: string | null }>();
  if (ownerIds.length === 0) return out;
  const { data, error } = await admin
    .from('daily_logs')
    .select('owner_id, created_at, semaphore')
    .in('owner_id', ownerIds)
    .order('created_at', { ascending: false })
    .limit(2000);
  if (error) {
    console.warn('[dashboard] daily_logs aggregate failed:', error.message);
    return out;
  }
  for (const row of (data ?? []) as Array<{
    owner_id: string;
    created_at: string;
    semaphore: string | null;
  }>) {
    if (!out.has(row.owner_id)) {
      out.set(row.owner_id, { created_at: row.created_at, semaphore: row.semaphore });
    }
  }
  return out;
}

export async function getProfileById(id: string): Promise<Profile | null> {
  const admin = createSupabaseAdmin();
  const { data, error } = await admin
    .from('profiles')
    .select(
      'id, email, nickname, auth_user_id, created_at, is_deleted, deleted_at, is_web_migrated'
    )
    .eq('id', id)
    .maybeSingle();
  if (error) throw new Error(`profile: ${error.message}`);
  return (data as Profile) ?? null;
}

export async function getDogsForOwner(ownerId: string): Promise<DogWithRisk[]> {
  const admin = createSupabaseAdmin();
  const { data: dogs, error } = await admin
    .from('dogs')
    .select('*, breeds(name, name_it, image_url)')
    .eq('owner_id', ownerId)
    .order('created_at', { ascending: true });
  if (error) throw new Error(`dogs: ${error.message}`);
  if (!dogs || dogs.length === 0) return [];

  const dogIds = (dogs as Array<{ id: string }>).map((d) => d.id);
  const [risks, lastChecks] = await Promise.all([
    fetchLatestRiskByDog(dogIds),
    fetchLatestCheckByDog(dogIds),
  ]);

  const out: DogWithRisk[] = [];
  for (const row of dogs as Array<Record<string, unknown>>) {
    const breed = row.breeds as { name?: string; name_it?: string; image_url?: string } | null;
    const imageUrl = await resolveDogImage(row, breed?.image_url ?? null);
    out.push({
      id: row.id as string,
      name: (row.name as string | null) ?? null,
      age_years: (row.age_years as number | null) ?? null,
      weight_kg: (row.weight_kg as number | null) ?? null,
      age_group: (row.age_group as string | null) ?? null,
      size: (row.size as string | null) ?? null,
      breed_id: (row.breed_id as string | null) ?? null,
      diagnosis_status: (row.diagnosis_status as string | null) ?? null,
      diagnosis_date: (row.diagnosis_date as string | null) ?? null,
      diagnosis_vet: (row.diagnosis_vet as string | null) ?? null,
      owner_id: (row.owner_id as string | null) ?? null,
      is_deleted: (row.is_deleted as boolean | null) ?? null,
      deleted_at: (row.deleted_at as string | null) ?? null,
      created_at: (row.created_at as string | null) ?? null,
      breed_name: breed?.name ?? null,
      breed_name_it: breed?.name_it ?? null,
      risk_level: risks.get(row.id as string)?.risk_level ?? null,
      risk_score: risks.get(row.id as string)?.score ?? null,
      last_check_at: lastChecks.get(row.id as string) ?? null,
      image_url: imageUrl,
    });
  }
  return out;
}

async function fetchLatestRiskByDog(dogIds: string[]) {
  const admin = createSupabaseAdmin();
  const out = new Map<string, { risk_level: string | null; score: number | null }>();
  if (dogIds.length === 0) return out;
  const { data, error } = await admin
    .from('quiz_results')
    .select('dog_id, risk_level, score, created_at')
    .in('dog_id', dogIds)
    .order('created_at', { ascending: false });
  if (error) {
    console.warn('[dashboard] quiz_results failed:', error.message);
    return out;
  }
  for (const row of (data ?? []) as Array<{
    dog_id: string | null;
    risk_level: string | null;
    score: number | null;
  }>) {
    if (!row.dog_id) continue;
    if (!out.has(row.dog_id)) {
      out.set(row.dog_id, { risk_level: row.risk_level, score: row.score });
    }
  }
  return out;
}

async function fetchLatestCheckByDog(dogIds: string[]) {
  const admin = createSupabaseAdmin();
  const out = new Map<string, string>();
  if (dogIds.length === 0) return out;
  const { data, error } = await admin
    .from('daily_logs')
    .select('dog_id, created_at')
    .in('dog_id', dogIds)
    .order('created_at', { ascending: false });
  if (error) {
    console.warn('[dashboard] daily_logs by dog failed:', error.message);
    return out;
  }
  for (const row of (data ?? []) as Array<{ dog_id: string | null; created_at: string }>) {
    if (!row.dog_id) continue;
    if (!out.has(row.dog_id)) out.set(row.dog_id, row.created_at);
  }
  return out;
}

export async function getDogById(id: string): Promise<DogWithRisk | null> {
  const admin = createSupabaseAdmin();
  const { data, error } = await admin
    .from('dogs')
    .select('*, breeds(name, name_it, image_url)')
    .eq('id', id)
    .maybeSingle();
  if (error) throw new Error(`dog: ${error.message}`);
  if (!data) return null;
  const [risks, lastChecks] = await Promise.all([
    fetchLatestRiskByDog([id]),
    fetchLatestCheckByDog([id]),
  ]);
  const row = data as Record<string, unknown>;
  const breed = row.breeds as { name?: string; name_it?: string; image_url?: string } | null;
  const imageUrl = await resolveDogImage(row, breed?.image_url ?? null);
  return {
    id: row.id as string,
    name: (row.name as string | null) ?? null,
    age_years: (row.age_years as number | null) ?? null,
    weight_kg: (row.weight_kg as number | null) ?? null,
    age_group: (row.age_group as string | null) ?? null,
    size: (row.size as string | null) ?? null,
    breed_id: (row.breed_id as string | null) ?? null,
    diagnosis_status: (row.diagnosis_status as string | null) ?? null,
    diagnosis_date: (row.diagnosis_date as string | null) ?? null,
    diagnosis_vet: (row.diagnosis_vet as string | null) ?? null,
    owner_id: (row.owner_id as string | null) ?? null,
    is_deleted: (row.is_deleted as boolean | null) ?? null,
    deleted_at: (row.deleted_at as string | null) ?? null,
    created_at: (row.created_at as string | null) ?? null,
    breed_name: breed?.name ?? null,
    breed_name_it: breed?.name_it ?? null,
    risk_level: risks.get(id)?.risk_level ?? null,
    risk_score: risks.get(id)?.score ?? null,
    last_check_at: lastChecks.get(id) ?? null,
    image_url: imageUrl,
  };
}

export async function getDailyLogs(dogId: string, limit = 90): Promise<DailyLog[]> {
  const admin = createSupabaseAdmin();
  const { data, error } = await admin
    .from('daily_logs')
    .select(
      'created_at, semaphore, score, raw_score, actions, avoid, video_label, video_url, route_tag, dog_id'
    )
    .eq('dog_id', dogId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(`daily_logs: ${error.message}`);
  return (data ?? []) as DailyLog[];
}
