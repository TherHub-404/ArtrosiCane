const FALLBACK_MAINTAINERS = [
  'matteo.carlone99@gmail.com',
  'matteomaragliano99@gmail.com',
  'adriano.monino@gmail.com',
];

export function maintainerEmails(): string[] {
  const raw = process.env.MAINTAINER_EMAILS;
  const list = raw && raw.trim().length > 0
    ? raw.split(',').map((e) => e.trim()).filter(Boolean)
    : FALLBACK_MAINTAINERS;
  return list.map((e) => e.toLowerCase());
}

export function isMaintainer(email: string | null | undefined): boolean {
  if (!email) return false;
  return maintainerEmails().includes(email.toLowerCase());
}
