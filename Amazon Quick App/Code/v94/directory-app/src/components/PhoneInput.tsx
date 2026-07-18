import React, { useState } from 'react';
import { S, colors } from '../styles';
import { CountryCodeSelect } from './CountryCodeSelect';

// Valid characters: digits, spaces, dashes, parens, dots, plus
const PHONE_CHARS_REGEX = /^[0-9\s\-().+]+$/;

function countDigits(v: string): number {
  return (v.match(/\d/g) || []).length;
}

/**
 * Format a phone number based on the country code.
 * Extracts only digits, then applies a country-specific pattern.
 */
function formatForCountry(raw: string, code: string): string {
  const digits = raw.replace(/[^\d]/g, '');
  if (!digits) return '';

  switch (code) {
    case '+1': {
      // NANP: US/Canada — (XXX) XXX-XXXX
      const d = digits.length === 11 && digits.startsWith('1') ? digits.slice(1) : digits;
      if (d.length === 10) return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
      return raw;
    }
    case '+44': {
      // UK: 0XXXX XXXXXX or XXXXX XXXXXX (10-11 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 4)} ${d.slice(4, 7)} ${d.slice(7)}`;
      if (d.length === 9) return `${d.slice(0, 3)} ${d.slice(3, 6)} ${d.slice(6)}`;
      return raw;
    }
    case '+61': {
      // Australia: XXXX XXX XXX (9 digits without leading 0)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 9) return `${d.slice(0, 4)} ${d.slice(4, 7)} ${d.slice(7)}`;
      return raw;
    }
    case '+49': {
      // Germany: variable length, group as XXXX XXXXXXX
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length >= 10 && d.length <= 11) return `${d.slice(0, 4)} ${d.slice(4)}`;
      return raw;
    }
    case '+33': {
      // France: XX XX XX XX XX (9 digits without leading 0)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 9) return `${d.slice(0, 1)} ${d.slice(1, 3)} ${d.slice(3, 5)} ${d.slice(5, 7)} ${d.slice(7)}`;
      return raw;
    }
    case '+91': {
      // India: XXXXX XXXXX (10 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 5)} ${d.slice(5)}`;
      return raw;
    }
    case '+81': {
      // Japan: XX-XXXX-XXXX (10-11 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 2)}-${d.slice(2, 6)}-${d.slice(6)}`;
      if (d.length === 9) return `${d.slice(0, 1)}-${d.slice(1, 5)}-${d.slice(5)}`;
      return raw;
    }
    case '+86': {
      // China: XXX XXXX XXXX (11 digits)
      if (digits.length === 11) return `${digits.slice(0, 3)} ${digits.slice(3, 7)} ${digits.slice(7)}`;
      return raw;
    }
    case '+55': {
      // Brazil: (XX) XXXXX-XXXX or (XX) XXXX-XXXX
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 11) return `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`;
      if (d.length === 10) return `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`;
      return raw;
    }
    case '+52': {
      // Mexico: XXX XXX XXXX (10 digits)
      if (digits.length === 10) return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
      return raw;
    }
    default: {
      // Generic: group in blocks of 3-4 digits
      if (digits.length >= 7 && digits.length <= 8) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
      if (digits.length >= 9 && digits.length <= 10) return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
      if (digits.length >= 11) return `${digits.slice(0, 3)} ${digits.slice(3, 7)} ${digits.slice(7)}`;
      return raw;
    }
  }
}

export function PhoneInput({ value, countryCode, placeholder, onChange, onCodeChange }: {
  value: string; countryCode: string; placeholder: string;
  onChange: (val: string) => void; onCodeChange: (code: string) => void;
}) {
  const [error, setError] = useState('');

  const handleBlur = () => {
    const trimmed = value.trim();
    if (!trimmed) { setError(''); return; }
    if (!PHONE_CHARS_REGEX.test(trimmed)) {
      setError('Please enter a valid phone number');
      return;
    }
    if (countDigits(trimmed) < 7) {
      setError('Please enter a valid phone number');
      return;
    }
    setError('');
    // Format the valid number
    const formatted = formatForCountry(trimmed, countryCode);
    if (formatted !== value) onChange(formatted);
  };

  return (
    <div>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <CountryCodeSelect value={countryCode} onChange={onCodeChange} />
        <input
          style={{ ...S.input, flex: 1, ...(error ? { borderColor: colors.danger } : {}) }}
          type="tel"
          placeholder={placeholder}
          value={value}
          onChange={e => { onChange(e.target.value); if (error) setError(''); }}
          onBlur={handleBlur}
        />
      </div>
      {error && <div style={{ fontSize: 12, color: colors.danger, marginTop: 2 }}>{error}</div>}
    </div>
  );
}

