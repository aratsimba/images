import React from 'react';
import { S, colors } from '../styles';
import { COUNTRY_CODES } from '../countryCodes';

export function CountryCodeSelect({ value, onChange }: { value: string; onChange: (code: string) => void }) {
  return (
    <select
      style={{ ...S.input, width: 'auto', minWidth: 160, padding: '4px 8px', fontSize: 12, flex: '0 0 auto' }}
      value={value || '+1'}
      onChange={e => onChange(e.target.value)}
    >
      {COUNTRY_CODES.map((c, i) => (
        <option key={`${c.code}-${i}`} value={c.code}>
          {c.flag} {c.name} ({c.code})
        </option>
      ))}
    </select>
  );
}

