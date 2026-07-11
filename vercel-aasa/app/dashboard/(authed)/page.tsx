import { listProfiles } from '@/lib/dashboard/queries';
import ProfilesTable from './profiles-table';

export const dynamic = 'force-dynamic';

export default async function DashboardHome() {
  const profiles = await listProfiles();
  const totalDogs = profiles.reduce((sum, p) => sum + (p.dog_count ?? 0), 0);
  const realProfiles = profiles.filter((p) => p.kind === 'profile');
  const orphans = profiles.filter((p) => p.kind === 'orphan_auth');
  const migrated = realProfiles.filter((p) => p.is_web_migrated === true);
  // "Onboarding incompleto" is now strictly users who tried to sign up in the
  // app but did not add a dog yet, plus auth users without any profile row.
  // Web-migrated users are NOT counted here — they have a complete profile
  // pre-populated from the website and are tracked separately.
  const incompleteOnboarding =
    realProfiles.filter(
      (p) => !p.is_web_migrated && p.auth_user_id && (p.dog_count ?? 0) === 0
    ).length + orphans.length;

  return (
    <>
      <div className="stat-grid">
        <div className="stat">
          <p className="stat-label">Profili attivi</p>
          <p className="stat-value">{realProfiles.length}</p>
        </div>
        <div className="stat" title="Profili importati dal sito web (tutti, già loggati e non).">
          <p className="stat-label">Migrati dal sito web</p>
          <p className="stat-value">{migrated.length}</p>
        </div>
        <div className="stat" title="Utenti che si sono registrati nell'app ma non hanno completato l'onboarding (nessun cane / nessun profilo).">
          <p className="stat-label">Onboarding incompleto</p>
          <p
            className="stat-value"
            style={{ color: incompleteOnboarding > 0 ? 'var(--warn)' : undefined }}
          >
            {incompleteOnboarding}
          </p>
        </div>
        <div className="stat">
          <p className="stat-label">Cani registrati</p>
          <p className="stat-value">{totalDogs}</p>
        </div>
      </div>

      <div className="card">
        <ProfilesTable profiles={profiles} />
      </div>
    </>
  );
}
