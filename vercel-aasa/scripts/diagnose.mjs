import { createClient } from '@supabase/supabase-js';
import fs from 'node:fs';
import path from 'node:path';

const envPath = path.resolve('.env.local');
const env = Object.fromEntries(
  fs.readFileSync(envPath, 'utf8')
    .split('\n')
    .filter((l) => l && !l.startsWith('#'))
    .map((l) => {
      const idx = l.indexOf('=');
      return [l.slice(0, idx), l.slice(idx + 1)];
    })
);

const admin = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function listAllAuthUsers() {
  const out = [];
  let page = 1;
  while (true) {
    const { data, error } = await admin.auth.admin.listUsers({ page, perPage: 200 });
    if (error) throw error;
    out.push(...data.users);
    if (data.users.length < 200) break;
    page += 1;
  }
  return out;
}

async function main() {
  console.log('=== auth.users ===');
  const users = await listAllAuthUsers();
  console.log(`total: ${users.length}`);
  for (const u of users) {
    console.log(`- ${u.id}  ${u.email ?? '(no email)'}  created=${u.created_at}  last_sign_in=${u.last_sign_in_at ?? '-'}  providers=${(u.app_metadata?.providers ?? []).join(',') || u.app_metadata?.provider}`);
  }

  console.log('\n=== public.profiles ===');
  const { data: profiles, error: pe } = await admin
    .from('profiles')
    .select('id, email, nickname, auth_user_id, is_deleted, deleted_at, created_at')
    .order('created_at', { ascending: false });
  if (pe) { console.error('profiles error:', pe); process.exit(1); }
  console.log(`total: ${profiles.length}`);
  for (const p of profiles) {
    console.log(`- profile.id=${p.id}  email=${p.email}  auth_user_id=${p.auth_user_id ?? 'NULL'}  nickname=${p.nickname ?? '-'}  deleted=${p.is_deleted ? 'YES' : 'no'}  created=${p.created_at}`);
  }

  console.log('\n=== auth.users WITHOUT matching profile ===');
  const profileEmails = new Set(profiles.map((p) => (p.email || '').toLowerCase()));
  const profileAuthIds = new Set(profiles.map((p) => p.auth_user_id).filter(Boolean));
  for (const u of users) {
    const e = (u.email || '').toLowerCase();
    const matchByAuthId = profileAuthIds.has(u.id);
    const matchByEmail = e && profileEmails.has(e);
    if (!matchByAuthId && !matchByEmail) {
      console.log(`- ORPHAN auth user: id=${u.id}  email=${u.email ?? '(no email)'}  created=${u.created_at}  last_sign_in=${u.last_sign_in_at ?? '-'}`);
    }
  }

  console.log('\n=== profiles WITHOUT matching auth user (pre-populated by website) ===');
  const userIds = new Set(users.map((u) => u.id));
  const userEmails = new Set(users.map((u) => (u.email || '').toLowerCase()).filter(Boolean));
  for (const p of profiles) {
    const e = (p.email || '').toLowerCase();
    const matchByAuthId = p.auth_user_id && userIds.has(p.auth_user_id);
    const matchByEmail = e && userEmails.has(e);
    if (!matchByAuthId && !matchByEmail) {
      console.log(`- UNCLAIMED profile: id=${p.id} email=${p.email}`);
    }
  }

  console.log('\n=== Stefania Cafariello ===');
  const candidates = users.filter((u) => (u.email || '').toLowerCase().includes('stefania') || (u.user_metadata?.full_name || '').toLowerCase().includes('cafariello'));
  for (const u of candidates) {
    console.log(`auth user: ${u.id}  ${u.email}  meta=${JSON.stringify(u.user_metadata)}`);
  }
  const stefProfile = profiles.find((p) => (p.email || '').toLowerCase().includes('stefania') || (p.nickname || '').toLowerCase().includes('cafariello'));
  if (stefProfile) {
    console.log(`profile: ${JSON.stringify(stefProfile)}`);
    const { data: dogs, error: de } = await admin.from('dogs').select('id, name, owner_id, is_deleted, created_at').eq('owner_id', stefProfile.id);
    if (de) console.error('dogs error:', de);
    else console.log(`dogs for stefania: ${JSON.stringify(dogs, null, 2)}`);
  } else {
    console.log('(no profile match by email/nickname)');
  }

  console.log('\n=== app_events recent errors ===');
  const { data: events } = await admin
    .from('app_events')
    .select('created_at, owner_id, event_name, payload')
    .order('created_at', { ascending: false })
    .limit(40);
  if (events) {
    for (const e of events) {
      const payloadStr = typeof e.payload === 'object' ? JSON.stringify(e.payload) : String(e.payload);
      if (/error|fail|dog/i.test(e.event_name) || /error/i.test(payloadStr)) {
        console.log(`- ${e.created_at}  owner=${e.owner_id ?? '-'}  ${e.event_name}  ${payloadStr.slice(0, 200)}`);
      }
    }
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
