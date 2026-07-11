export type Profile = {
  id: string;
  email: string | null;
  nickname: string | null;
  auth_user_id: string | null;
  created_at: string | null;
  is_deleted: boolean | null;
  deleted_at: string | null;
  is_web_migrated: boolean | null;
};

export type ProfileRow = Profile & {
  dog_count: number;
  last_check_at: string | null;
  last_check_semaphore: string | null;
  kind: 'profile' | 'orphan_auth';
  email_confirmed_at: string | null;
  last_sign_in_at: string | null;
};

export type Dog = {
  id: string;
  name: string | null;
  age_years: number | null;
  weight_kg: number | null;
  age_group: string | null;
  size: string | null;
  breed_id: string | null;
  diagnosis_status: string | null;
  diagnosis_date: string | null;
  diagnosis_vet: string | null;
  owner_id: string | null;
  is_deleted: boolean | null;
  deleted_at: string | null;
  created_at: string | null;
};

export type DogWithRisk = Dog & {
  breed_name: string | null;
  breed_name_it: string | null;
  risk_level: string | null;
  risk_score: number | null;
  last_check_at: string | null;
  image_url: string | null;
};

export type DailyLog = {
  created_at: string | null;
  semaphore: string | null;
  score: number | null;
  raw_score: number | null;
  actions: string[] | null;
  avoid: string | null;
  video_label: string | null;
  video_url: string | null;
  route_tag: string | null;
  dog_id: string | null;
};
