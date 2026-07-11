'use client';

import { useState, useTransition } from 'react';
import { sendMagicLink } from './actions';

export default function LoginForm() {
  const [email, setEmail] = useState('');
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        setError(null);
        startTransition(async () => {
          const result = await sendMagicLink(email);
          if (result?.error) setError(result.error);
        });
      }}
    >
      <div className="field">
        <label htmlFor="email">Email</label>
        <input
          id="email"
          className="search"
          type="email"
          name="email"
          autoComplete="email"
          required
          placeholder="tu@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </div>
      <button type="submit" className="btn btn-primary" disabled={pending} style={{ width: '100%' }}>
        {pending ? 'Invio in corso…' : 'Invia link di accesso'}
      </button>
      {error && <div className="alert alert-error">{error}</div>}
    </form>
  );
}
