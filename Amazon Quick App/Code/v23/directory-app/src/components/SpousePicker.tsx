import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

interface SpousePickerProps {
  allPersons: Person[];
  editId: string | null;
  selectedSpouseId: string;
  childIds: string[];
  onSelect: (id: string) => void;
  onClear: () => void;
}

export function SpousePicker({ allPersons, editId, selectedSpouseId, childIds, onSelect, onClear }: SpousePickerProps) {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (ref.current && !ref.current.contains(ev.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const spouse = allPersons.find(p => p.id === selectedSpouseId);

  // Filter: exclude self, exclude current children, exclude persons already married to someone else
  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (childIds.includes(p.id)) return false;
    if (p.spouseId && p.spouseId !== editId) return false;
    return true;
  });

  const filtered = eligible.filter(p =>
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase())
  );

  if (spouse) {
    return (
      <div style={S.fieldFull}>
        <label style={S.label}>Spouse</label>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={S.chip}>
            {spouse.firstName} {spouse.lastName}
            <button style={S.chipRemove} onClick={onClear}>×</button>
          </span>
        </div>
      </div>
    );
  }

  return (
    <div style={S.fieldFull} ref={ref}>
      <label style={S.label}>Spouse</label>
      <input
        style={S.input}
        placeholder="Search for a spouse..."
        value={q}
        onChange={e => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => setOpen(true)}
      />
      {open && q && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'relative' as const, zIndex: 5 }}>
          {filtered.length === 0 && (
            <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons</div>
          )}
          {filtered.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onSelect(p.id); setQ(''); setOpen(false); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

