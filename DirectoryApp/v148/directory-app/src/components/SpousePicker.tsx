import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';
import { getAncestorIds, getDescendantIds } from '../utils';

interface SpousePickerProps {
  allPersons: Person[];
  pendingIds?: Set<string>;
  editId: string | null;
  selectedSpouseId: string;
  childIds: string[];
  currentGender: string;
  onSelect: (id: string) => void;
  onClear: () => void;
  onEditPending?: (id: string) => void;
  onQuickAdd?: () => void;
}

export function SpousePicker({ allPersons, pendingIds, editId, selectedSpouseId, childIds, currentGender, onSelect, onClear, onEditPending, onQuickAdd }: SpousePickerProps) {
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

  // Filter: exclude self, exclude current children, exclude persons already married to someone else,
  // exclude ancestors and descendants (to prevent cycles)
  const currentId = editId || '__new__';
  const ancestors = getAncestorIds(currentId, allPersons);
  const descendants = getDescendantIds(currentId, allPersons);
  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (childIds.includes(p.id)) return false;
    if (p.spouseId && p.spouseId !== editId) return false;
    if (ancestors.has(p.id)) return false;
    if (descendants.has(p.id)) return false;
    // Only show persons of the opposite gender
    if (currentGender && p.gender) {
      if (currentGender === p.gender) return false;
    }
    return true;
  });

  const filtered = eligible.filter(p =>
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase())
  );

  if (spouse) {
    const isPending = pendingIds?.has(spouse.id);
    return (
      <div style={S.fieldFull}>
        <label style={S.label}>Spouse</label>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ ...S.chip, ...(isPending ? { background: '#fff8e1', border: '1px solid #ffc107', cursor: 'pointer' } : {}) }}
            onClick={isPending && onEditPending ? () => onEditPending(spouse.id) : undefined}
            title={isPending ? 'Click to edit' : undefined}>
            {isPending && <span style={{ fontSize: 11, fontWeight: 700, color: '#f57f17' }}>✨ new</span>}
            {spouse.firstName} {spouse.lastName}
            <button style={S.chipRemove} onClick={e => { e.stopPropagation(); onClear(); }}>×</button>
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
        placeholder="Search or create a spouse..."
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
          {onQuickAdd && (
            <>
              <div style={{ borderTop: `1px solid ${colors.border}` }} />
              <div style={{ ...S.dropdownItem, color: colors.primary, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}
                onMouseEnter={e => (e.currentTarget.style.background = '#f0f7ff')}
                onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                onClick={() => { setQ(''); setOpen(false); onQuickAdd(); }}>
                ✨ Create new spouse…
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}

