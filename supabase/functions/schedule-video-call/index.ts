const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const DEFAULT_OWNER_EMAIL = 'adriano.monino@gmail.com';
const DEFAULT_TIME_ZONE = 'Europe/Rome';

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json',
    },
  });
}

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function parseIsoDate(value: unknown): Date | null {
  if (typeof value !== 'string' || value.trim().length === 0) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function isValidEmail(value: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
}

async function fetchGoogleAccessToken(params: {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
}): Promise<string> {
  const body = new URLSearchParams({
    client_id: params.clientId,
    client_secret: params.clientSecret,
    refresh_token: params.refreshToken,
    grant_type: 'refresh_token',
  });

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });

  const tokenPayload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(
      typeof tokenPayload?.error_description === 'string' &&
              tokenPayload.error_description.trim().length > 0
          ? tokenPayload.error_description
          : 'Google OAuth token request failed.',
    );
  }

  const accessToken = tokenPayload?.access_token;
  if (typeof accessToken !== 'string' || accessToken.trim().length === 0) {
    throw new Error('Google OAuth response did not include access_token.');
  }

  return accessToken;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ ok: false, error: 'Method not allowed.' }, 405);
  }

  try {
    const payload = await req.json().catch(() => ({}));

    const firstName = asTrimmedString(payload?.firstName);
    const lastName = asTrimmedString(payload?.lastName);
    const email = asTrimmedString(payload?.email).toLowerCase();
    const phone = asTrimmedString(payload?.phone);
    const dogName = asTrimmedString(payload?.dogName);
    const timeZone = asTrimmedString(payload?.timeZone) || DEFAULT_TIME_ZONE;

    if (
      firstName.length === 0 ||
      lastName.length === 0 ||
      email.length === 0 ||
      phone.length === 0
    ) {
      return jsonResponse(
        { ok: false, error: 'Nome, cognome, email e telefono sono obbligatori.' },
        400,
      );
    }

    if (!isValidEmail(email)) {
      return jsonResponse({ ok: false, error: 'Email non valida.' }, 400);
    }

    const ownerEmail =
      asTrimmedString(Deno.env.get('VIDEO_CALL_OWNER_EMAIL')) || DEFAULT_OWNER_EMAIL;

    const startAt = parseIsoDate(payload?.startAt) ??
      new Date(Date.now() + 2 * 60 * 60 * 1000);
    const parsedEndAt = parseIsoDate(payload?.endAt);
    const endAt = parsedEndAt && parsedEndAt > startAt
      ? parsedEndAt
      : new Date(startAt.getTime() + 30 * 60 * 1000);

    const googleClientId = asTrimmedString(Deno.env.get('GOOGLE_CALENDAR_CLIENT_ID'));
    const googleClientSecret = asTrimmedString(
      Deno.env.get('GOOGLE_CALENDAR_CLIENT_SECRET'),
    );
    const googleRefreshToken = asTrimmedString(
      Deno.env.get('GOOGLE_CALENDAR_REFRESH_TOKEN'),
    );
    const googleCalendarId =
      asTrimmedString(Deno.env.get('GOOGLE_CALENDAR_ID')) || 'primary';

    if (
      googleClientId.length === 0 ||
      googleClientSecret.length === 0 ||
      googleRefreshToken.length === 0
    ) {
      return jsonResponse(
        {
          ok: false,
          error:
            'Configurazione Google Calendar incompleta lato server. Imposta i secrets richiesti.',
        },
        500,
      );
    }

    const accessToken = await fetchGoogleAccessToken({
      clientId: googleClientId,
      clientSecret: googleClientSecret,
      refreshToken: googleRefreshToken,
    });

    const title = `Video Call Artrosi Cane - ${firstName} ${lastName}`;
    const descriptionLines = [
      'Richiesta videocall creata automaticamente da Artrosi Cane.',
      `Utente: ${firstName} ${lastName}`,
      `Email: ${email}`,
      `Telefono backup: ${phone}`,
      dogName.length === 0 ? 'Cane: non specificato' : `Cane: ${dogName}`,
    ];

    const attendeeMap = new Map<string, { email: string; displayName?: string }>();
    for (const attendee of [
      { email: ownerEmail, displayName: 'Adriano Monino' },
      { email, displayName: `${firstName} ${lastName}`.trim() },
    ]) {
      const normalized = attendee.email.trim().toLowerCase();
      if (normalized.length === 0 || !isValidEmail(normalized)) continue;
      attendeeMap.set(normalized, {
        email: normalized,
        displayName: attendee.displayName,
      });
    }

    const eventPayload = {
      summary: title,
      description: descriptionLines.join('\n'),
      location: 'Google Meet',
      start: {
        dateTime: startAt.toISOString(),
        timeZone,
      },
      end: {
        dateTime: endAt.toISOString(),
        timeZone,
      },
      attendees: Array.from(attendeeMap.values()),
      conferenceData: {
        createRequest: {
          requestId: crypto.randomUUID(),
          conferenceSolutionKey: {
            type: 'hangoutsMeet',
          },
        },
      },
      guestsCanModify: true,
      extendedProperties: {
        private: {
          phoneBackup: phone,
          requesterEmail: email,
          ...(dogName.length === 0 ? {} : { dogName }),
        },
      },
    };

    const googleCalendarEndpoint =
      `https://www.googleapis.com/calendar/v3/calendars/${encodeURIComponent(googleCalendarId)}/events` +
      '?conferenceDataVersion=1&sendUpdates=all';

    const createEventResponse = await fetch(googleCalendarEndpoint, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(eventPayload),
    });

    const createEventBody = await createEventResponse.json().catch(() => ({}));
    if (!createEventResponse.ok) {
      const apiMessage =
        typeof createEventBody?.error?.message === 'string'
          ? createEventBody.error.message
          : 'Google Calendar API error.';
      return jsonResponse(
        {
          ok: false,
          error: `Google Calendar ha rifiutato la prenotazione: ${apiMessage}`,
        },
        502,
      );
    }

    const meetLink =
      typeof createEventBody?.hangoutLink === 'string'
        ? createEventBody.hangoutLink
        : null;

    return jsonResponse({
      ok: true,
      eventId: createEventBody?.id ?? null,
      eventLink: createEventBody?.htmlLink ?? null,
      meetLink,
      calendarId: googleCalendarId,
    });
  } catch (error) {
    console.error('schedule-video-call failed', error);
    return jsonResponse(
      {
        ok: false,
        error: 'Errore interno durante la prenotazione della videocall.',
      },
      500,
    );
  }
});
