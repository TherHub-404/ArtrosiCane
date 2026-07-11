export function formatDateTime(iso: string | null | undefined): string {
  if (!iso) return '-';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '-';
  return d.toLocaleString('it-IT', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatDate(iso: string | null | undefined): string {
  if (!iso) return '-';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '-';
  return d.toLocaleDateString('it-IT', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
}

export function relative(iso: string | null | undefined): string {
  if (!iso) return '-';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '-';
  const diffMs = Date.now() - d.getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 1) return 'pochi secondi fa';
  if (minutes < 60) return `${minutes} min fa`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} h fa`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days} g fa`;
  return formatDate(iso);
}

export function semaphoreColor(name: string | null | undefined): 'green' | 'yellow' | 'red' | 'gray' {
  switch ((name ?? '').toLowerCase()) {
    case 'verde':
    case 'green':
      return 'green';
    case 'giallo':
    case 'yellow':
      return 'yellow';
    case 'rosso':
    case 'red':
      return 'red';
    default:
      return 'gray';
  }
}

export function semaphoreLabel(name: string | null | undefined): string {
  switch ((name ?? '').toLowerCase()) {
    case 'verde':
    case 'green':
      return 'Verde';
    case 'giallo':
    case 'yellow':
      return 'Giallo';
    case 'rosso':
    case 'red':
      return 'Rosso';
    default:
      return '-';
  }
}

export function riskColor(level: string | null | undefined): 'green' | 'yellow' | 'red' | 'gray' {
  switch ((level ?? '').toLowerCase()) {
    case 'low':
    case 'basso':
      return 'green';
    case 'medium':
    case 'medio':
      return 'yellow';
    case 'high':
    case 'alto':
      return 'red';
    default:
      return 'gray';
  }
}

export function riskLabel(level: string | null | undefined): string {
  if (!level) return '-';
  const m = level.toLowerCase();
  if (m === 'low' || m === 'basso') return 'Basso';
  if (m === 'medium' || m === 'medio') return 'Medio';
  if (m === 'high' || m === 'alto') return 'Alto';
  return level;
}

export function initials(input: string | null | undefined): string {
  if (!input) return '?';
  const parts = input.replace(/[^a-zA-Z0-9 ]/g, ' ').trim().split(/\s+/);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
