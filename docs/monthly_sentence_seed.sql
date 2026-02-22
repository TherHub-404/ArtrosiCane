-- Monthly sentence content for Home carousel
-- Run this in Supabase SQL Editor.

create table if not exists public.monthly_sentence (
  id bigserial primary key,
  month_number smallint not null unique check (month_number between 1 and 12),
  month_name text not null,
  title text not null,
  focus text not null,
  objective text not null,
  areas text[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.monthly_sentence enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'monthly_sentence'
      and policyname = 'monthly_sentence_read_authenticated'
  ) then
    create policy monthly_sentence_read_authenticated
      on public.monthly_sentence
      for select
      to authenticated
      using (true);
  end if;
end $$;

insert into public.monthly_sentence (
  month_number, month_name, title, focus, objective, areas
)
values
  (
    1, 'Gennaio', 'GENNAIO - CONSAPEVOLEZZA E OSSERVAZIONE',
    'Ascolta (A di A.L.L.E.A.T.O.)',
    'Imparare a vedere.',
    array[
      'Segnali precoci',
      'Scale, auto, divano',
      'Rigidità mattutina',
      'Diario semplice',
      'Differenza tra va meglio e è stabile'
    ]
  ),
  (
    2, 'Febbraio', 'FEBBRAIO - PESO E CONTROLLO',
    'Metodo P.E.S.O.',
    'Alleggerire carico articolare.',
    array[
      'Pesare il cibo',
      'Ridurre senza affamare',
      'Porzioni volumetriche',
      'Monitoraggio mensile',
      'Micro-errori quotidiani'
    ]
  ),
  (
    3, 'Marzo', 'MARZO - MOVIMENTO INTELLIGENTE',
    'Rispetta il ritmo (R di A.R.M.O.N.I.A.)',
    'Aumentare senza ricadute.',
    array[
      'Progressione graduale',
      'Terreno regolare vs irregolare',
      'Fine passeggiata buona',
      'Micro-uscite',
      'Consolidamento'
    ]
  ),
  (
    4, 'Aprile', 'APRILE - AMBIENTE E CASA',
    'Esplora (E di A.L.L.E.A.T.O.)',
    'Togliere microtraumi invisibili.',
    array[
      'Pavimenti scivolosi',
      'Rampe',
      'Scale',
      'Zone di riposo',
      'Auto'
    ]
  ),
  (
    5, 'Maggio', 'MAGGIO - MUSCOLO E STABILITÀ',
    'Mantieni il tono',
    'Costruire protezione attiva.',
    array[
      'Lieve salita',
      'Passo controllato',
      'Rinforzo leggero',
      'Stabilità su terreno naturale',
      'Frequenza > intensità'
    ]
  ),
  (
    6, 'Giugno', 'GIUGNO - CALDO E GESTIONE ESTIVA',
    'Adattare il carico',
    'Evitare infiammazioni da sovraccarico estivo.',
    array[
      'Orari corretti',
      'Asfalto caldo',
      'Idratazione',
      'Rigidità serale',
      'Attività in acqua controllata'
    ]
  ),
  (
    7, 'Luglio', 'LUGLIO - VACANZE E SPOSTAMENTI',
    'Continuità fuori casa',
    'Non perdere la stabilità conquistata.',
    array[
      'Auto e salti',
      'Spiaggia',
      'Sabbia profonda',
      'Nuoto dosato',
      'Ritmo alterato'
    ]
  ),
  (
    8, 'Agosto', 'AGOSTO - COSTANZA',
    'Agisci con continuità (A di A.R.M.O.N.I.A.)',
    'Evitare il tutto o niente.',
    array[
      'Mini routine',
      'Diario veloce',
      'Micro-obiettivi',
      'Riduzione eccessi',
      'Stabilizzazione'
    ]
  ),
  (
    9, 'Settembre', 'SETTEMBRE - RICALIBRAZIONE',
    'Tiene traccia (T di A.L.L.E.A.T.O.)',
    'Correggere prima che peggiori.',
    array[
      'Revisione priorità',
      'Tendenza mensile',
      'Segnali nascosti',
      'Aggiustamenti piccoli',
      'Contatto con veterinario curante (se serve)'
    ]
  ),
  (
    10, 'Ottobre', 'OTTOBRE - CLIMA E RIGIDITÀ',
    'Osserva (O di A.L.L.E.A.T.O.)',
    'Prevenire riacutizzazioni.',
    array[
      'Attivazione prima uscita',
      'Riscaldamento lento',
      'Tempo di adattamento',
      'Segnali serali',
      'Terapia regolare'
    ]
  ),
  (
    11, 'Novembre', 'NOVEMBRE - MULTIMODALITÀ',
    'Integra quando serve (I di A.R.M.O.N.I.A.)',
    'Stabilità del dolore.',
    array[
      'Continuità terapeutica',
      'Non sospendere troppo presto',
      'Farmaco non è fallimento',
      'Sinergia movimento + peso + ambiente',
      'Monitoraggio risposta'
    ]
  ),
  (
    12, 'Dicembre', 'DICEMBRE - CONSOLIDAMENTO',
    'Armonia',
    'Trasformare gestione in normalità.',
    array[
      'Cosa ha funzionato',
      'Abitudini stabili',
      'Riduzione ricadute',
      'Relazione cane-proprietario',
      'Pianificazione nuovo anno'
    ]
  )
on conflict (month_number) do update set
  month_name = excluded.month_name,
  title = excluded.title,
  focus = excluded.focus,
  objective = excluded.objective,
  areas = excluded.areas,
  updated_at = now();
