'use client';

import { useRef, useState, useTransition } from 'react';
import { createSupabaseBrowserClient } from '@/lib/supabase/browser';
import { transcodeToMp4 } from '@/lib/transcode-video';
import { createVideoUploadUrl, saveVideo } from './actions';

const LANGS: { code: string; label: string }[] = [
  { code: 'it', label: 'Italiano' },
  { code: 'en', label: 'English' },
  { code: 'fr', label: 'Français' },
  { code: 'de', label: 'Deutsch' },
];
// Files at or below this size upload as-is; larger files are transcoded
// (and compressed) in the browser before upload.
const TRANSCODE_THRESHOLD_BYTES = 50 * 1024 * 1024;
const BUCKET = 'advice-videos';

// Accepted language keys when pasting a JSON to bulk-fill the fields.
const LANG_ALIASES: Record<string, string> = {
  it: 'it', italiano: 'it', italian: 'it',
  en: 'en', inglese: 'en', english: 'en',
  fr: 'fr', francese: 'fr', francais: 'fr', 'français': 'fr', french: 'fr',
  de: 'de', tedesco: 'de', deutsch: 'de', german: 'de',
};

const JSON_PLACEHOLDER = `{
  "italiano":  { "titolo": "...", "descrizione": "..." },
  "inglese":   { "titolo": "...", "descrizione": "..." },
  "francese":  { "titolo": "...", "descrizione": "..." },
  "tedesco":   { "titolo": "...", "descrizione": "..." }
}`;

function formatMb(bytes: number): string {
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export type VideoFormInitial = {
  id: string;
  title: Record<string, string>;
  description: Record<string, string>;
  storagePath: string;
  position: number;
  isActive: boolean;
};

type Phase = 'idle' | 'transcoding' | 'uploading' | 'saving';

export default function VideoForm({ initial }: { initial?: VideoFormInitial }) {
  const isEdit = !!initial;
  const [title, setTitle] = useState<Record<string, string>>(initial?.title ?? {});
  const [description, setDescription] = useState<Record<string, string>>(
    initial?.description ?? {},
  );
  const [position, setPosition] = useState<number>(initial?.position ?? 1);
  const [isActive, setIsActive] = useState<boolean>(initial?.isActive ?? true);
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>('idle');
  const [progress, setProgress] = useState<number>(0);
  const [jsonInput, setJsonInput] = useState<string>('');
  const [importError, setImportError] = useState<string | null>(null);
  const [importOk, setImportOk] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const busy = pending || phase !== 'idle';
  const willTranscode = !!file && file.size > TRANSCODE_THRESHOLD_BYTES;

  function pickFile(f: File | null) {
    setError(null);
    setFile(f);
  }

  function applyJsonImport() {
    setImportError(null);
    setImportOk(null);

    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonInput);
    } catch {
      setImportError('JSON non valido — controlla la sintassi.');
      return;
    }
    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      setImportError('Il JSON deve essere un oggetto con le lingue.');
      return;
    }

    const nextTitle: Record<string, string> = { ...title };
    const nextDescription: Record<string, string> = { ...description };
    const filled: string[] = [];

    for (const [rawLang, value] of Object.entries(
      parsed as Record<string, unknown>,
    )) {
      const code = LANG_ALIASES[rawLang.trim().toLowerCase()];
      if (!code || typeof value !== 'object' || value === null) continue;
      const entry = value as Record<string, unknown>;
      const t = entry.titolo ?? entry.title;
      const d = entry.descrizione ?? entry.description;
      if (typeof t === 'string') nextTitle[code] = t;
      if (typeof d === 'string') nextDescription[code] = d;
      if (typeof t === 'string' || typeof d === 'string') filled.push(code);
    }

    if (filled.length === 0) {
      setImportError(
        'Nessuna lingua riconosciuta. Usa chiavi italiano/inglese/francese/tedesco.',
      );
      return;
    }

    setTitle(nextTitle);
    setDescription(nextDescription);
    setImportOk(`Campi compilati per: ${filled.join(', ')}.`);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!(title.it ?? '').trim()) {
      setError('Il titolo in italiano è obbligatorio.');
      return;
    }
    if (!isEdit && !file) {
      setError('Seleziona il file video da caricare.');
      return;
    }

    try {
      let storagePath = initial?.storagePath ?? '';

      if (file) {
        let uploadFile = file;

        if (file.size > TRANSCODE_THRESHOLD_BYTES) {
          setPhase('transcoding');
          setProgress(0);
          uploadFile = await transcodeToMp4(file, setProgress);
        }

        setPhase('uploading');
        const { path, token } = await createVideoUploadUrl(uploadFile.name);
        const supabase = createSupabaseBrowserClient();
        const { error: upErr } = await supabase.storage
          .from(BUCKET)
          .uploadToSignedUrl(path, token, uploadFile, {
            contentType: uploadFile.type || 'video/mp4',
          });
        if (upErr) throw new Error(`Upload fallito: ${upErr.message}`);
        storagePath = path;
      }

      setPhase('saving');
      startTransition(async () => {
        try {
          await saveVideo({
            id: initial?.id,
            title,
            description,
            storagePath,
            position,
            isActive,
          });
        } catch (err) {
          setPhase('idle');
          setError(err instanceof Error ? err.message : 'Errore nel salvataggio.');
        }
      });
    } catch (err) {
      setPhase('idle');
      setError(err instanceof Error ? err.message : 'Errore imprevisto.');
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div className="card card-pad" style={{ marginBottom: 18 }}>
        <h3 className="form-section-title">Compilazione rapida da JSON</h3>
        <p className="card-subtitle" style={{ marginBottom: 14 }}>
          Incolla un JSON con le lingue (italiano / inglese / francese / tedesco),
          ognuna con &quot;titolo&quot; e &quot;descrizione&quot;, poi premi
          &quot;Compila i campi&quot; per riempire titoli e descrizioni qui sotto.
        </p>
        <textarea
          className="search"
          rows={7}
          value={jsonInput}
          onChange={(e) => {
            setJsonInput(e.target.value);
            setImportError(null);
            setImportOk(null);
          }}
          placeholder={JSON_PLACEHOLDER}
          style={{ resize: 'vertical', fontFamily: 'monospace', fontSize: 12 }}
        />
        {importError && (
          <div className="alert alert-error" style={{ marginTop: 10 }}>
            {importError}
          </div>
        )}
        {importOk && (
          <p
            className="muted"
            style={{ marginTop: 10, fontSize: 13, fontWeight: 600 }}
          >
            ✓ {importOk}
          </p>
        )}
        <button
          type="button"
          className="btn btn-ghost"
          onClick={applyJsonImport}
          disabled={busy || !jsonInput.trim()}
          style={{ marginTop: 12 }}
        >
          Compila i campi
        </button>
      </div>

      <div className="card card-pad" style={{ marginBottom: 18 }}>
        <h3 className="form-section-title">Titolo</h3>
        <p className="card-subtitle" style={{ marginBottom: 14 }}>
          L&apos;italiano è obbligatorio. Le altre lingue, se vuote, useranno l&apos;italiano.
        </p>
        {LANGS.map((l) => (
          <div className="field" key={`t-${l.code}`}>
            <label>{l.label}{l.code === 'it' ? ' *' : ''}</label>
            <input
              className="search"
              type="text"
              value={title[l.code] ?? ''}
              onChange={(e) => setTitle({ ...title, [l.code]: e.target.value })}
              placeholder={`Titolo (${l.label})`}
            />
          </div>
        ))}
      </div>

      <div className="card card-pad" style={{ marginBottom: 18 }}>
        <h3 className="form-section-title">Descrizione</h3>
        {LANGS.map((l) => (
          <div className="field" key={`d-${l.code}`}>
            <label>{l.label}</label>
            <textarea
              className="search"
              rows={2}
              value={description[l.code] ?? ''}
              onChange={(e) =>
                setDescription({ ...description, [l.code]: e.target.value })
              }
              placeholder={`Descrizione (${l.label})`}
              style={{ resize: 'vertical', fontFamily: 'inherit' }}
            />
          </div>
        ))}
      </div>

      <div className="card card-pad" style={{ marginBottom: 18 }}>
        <h3 className="form-section-title">File video</h3>
        <p className="card-subtitle" style={{ marginBottom: 14 }}>
          Formato verticale 9:16, MP4. I file oltre 50 MB vengono transcodificati
          e compressi automaticamente nel browser prima del caricamento.
          {isEdit && ' Lascia vuoto per mantenere il video attuale.'}
        </p>
        {isEdit && initial?.storagePath && (
          <p className="muted mono" style={{ marginBottom: 10 }}>
            Attuale: {initial.storagePath}
          </p>
        )}
        <input
          ref={fileInputRef}
          type="file"
          accept="video/mp4,video/quicktime"
          onChange={(e) => pickFile(e.target.files?.[0] ?? null)}
        />
        {file && (
          <p className="muted" style={{ marginTop: 8, fontSize: 13 }}>
            {file.name} — {formatMb(file.size)}
            {willTranscode && ' · oltre 50 MB: verrà transcodificato prima dell’upload'}
          </p>
        )}
        {phase === 'transcoding' && (
          <div style={{ marginTop: 12 }}>
            <div
              style={{
                height: 8,
                borderRadius: 999,
                background: 'rgba(0,0,0,0.08)',
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  height: '100%',
                  width: `${Math.round(progress * 100)}%`,
                  background: 'var(--accent, #4B5D9E)',
                  borderRadius: 999,
                  transition: 'width 0.2s ease',
                }}
              />
            </div>
            <p className="muted" style={{ marginTop: 6, fontSize: 12 }}>
              Transcodifica nel browser… {Math.round(progress * 100)}% — può
              richiedere qualche minuto, non chiudere la pagina.
            </p>
          </div>
        )}
      </div>

      <div className="card card-pad" style={{ marginBottom: 18 }}>
        <h3 className="form-section-title">Impostazioni</h3>
        <div className="field">
          <label>Posizione (ordine nella lista)</label>
          <input
            className="search"
            type="number"
            value={position}
            min={0}
            onChange={(e) => setPosition(parseInt(e.target.value, 10) || 0)}
            style={{ maxWidth: 140 }}
          />
        </div>
        <label
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            cursor: 'pointer',
            fontWeight: 600,
            fontSize: 14,
            marginTop: 6,
          }}
        >
          <input
            type="checkbox"
            checked={isActive}
            onChange={(e) => setIsActive(e.target.checked)}
            style={{ width: 18, height: 18 }}
          />
          Video attivo (visibile nell&apos;app)
        </label>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      <div style={{ display: 'flex', gap: 10, marginTop: 18 }}>
        <button type="submit" className="btn btn-primary" disabled={busy}>
          {phase === 'transcoding'
            ? `Transcodifica… ${Math.round(progress * 100)}%`
            : phase === 'uploading'
              ? 'Caricamento video…'
              : phase === 'saving' || pending
                ? 'Salvataggio…'
                : isEdit
                  ? 'Salva modifiche'
                  : 'Crea video'}
        </button>
        <a href="/dashboard/videos" className="btn btn-ghost">
          Annulla
        </a>
      </div>
    </form>
  );
}
