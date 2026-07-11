import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs';
import path from 'node:path';

const envPath = path.resolve('.env.local');
const env = Object.fromEntries(
  fs.readFileSync(envPath, 'utf8')
    .split('\n')
    .filter((l) => l && !l.startsWith('#'))
    .map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1)];
    })
);

const admin = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const BUCKET = 'advice-videos';
const SOURCE_DIR = path.resolve('../video-to-upload/_transcoded');

const FILES = [
  'consigli-camminata-cane.mp4',
  'consigli-camminata-in-acqua.mp4',
  'consigli-camminata-in-spiaggia.mp4',
];

async function ensureBucket() {
  const { data: list, error } = await admin.storage.listBuckets();
  if (error) throw error;
  const exists = (list ?? []).some((b) => b.name === BUCKET);
  if (!exists) {
    console.log(`creating bucket ${BUCKET}…`);
    const { error: ce } = await admin.storage.createBucket(BUCKET, {
      public: true,
      fileSizeLimit: '512MB',
    });
    if (ce) throw ce;
  } else {
    console.log(`bucket ${BUCKET} already exists`);
  }
}

async function upload(file) {
  const full = path.join(SOURCE_DIR, file);
  const stat = fs.statSync(full);
  const buf = fs.readFileSync(full);
  console.log(`uploading ${file} (${(stat.size / 1024 / 1024).toFixed(1)} MB)…`);
  const { error } = await admin.storage
    .from(BUCKET)
    .upload(file, buf, {
      contentType: 'video/mp4',
      upsert: true,
    });
  if (error) {
    console.error(`  FAILED: ${error.message}`);
    return false;
  }
  const { data } = admin.storage.from(BUCKET).getPublicUrl(file);
  console.log(`  ok → ${data.publicUrl}`);
  return true;
}

async function main() {
  await ensureBucket();
  for (const f of FILES) {
    await upload(f);
  }

  const { data: listing } = await admin.storage.from(BUCKET).list('', { limit: 100, sortBy: { column: 'name', order: 'asc' } });
  console.log('\nfinal bucket contents:');
  for (const it of listing ?? []) {
    console.log(`  - ${it.name}  (${(it.metadata?.size ?? 0)} bytes)`);
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
