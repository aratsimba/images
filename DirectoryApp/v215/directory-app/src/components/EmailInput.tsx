import React, { useState } from 'react';
import { S, colors } from '../styles';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function EmailInput({ value, placeholder, onChange }: {
  value: string; placeholder: string; onChange: (val: string) => void;
}) {
  const [error, setError] = useState('');

  const validate = (v: string) => {
    if (v.trim() && !EMAIL_REGEX.test(v.trim())) {
      setError('Please enter a valid email address');
    } else {
      setError('');
    }
  };

  return (
    <div>
      <input
        style={{ ...S.input, ...(error ? { borderColor: colors.danger } : {}) }}
        type="email"
        placeholder={placeholder}
        value={value}
        onChange={e => { onChange(e.target.value); if (error) setError(''); }}
        onBlur={() => validate(value)}
      />
      {error && <div style={{ fontSize: 12, color: colors.danger, marginTop: 2 }}>{error}</div>}
    </div>
  );
}

