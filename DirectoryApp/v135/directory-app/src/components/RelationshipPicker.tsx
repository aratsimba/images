import React, { useState } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

export function RelationshipPicker({ label, entries, selectedIds, pendingIds, onToggle, onEditPending }: {
  label: string; entries: Person[]; selectedIds: string[]; pendingIds?: Set<string>; onToggle: (id: string) => void; onEditPending?: (id: string) => void;
}) {
  const [q, setQ] = useState('');
  const filtered = entries.filter(p => !selectedIds.includes(p.id) &&
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase()));
  const selected = entries.filter(p => selectedIds.includes(p.id));
  return (
    <div style={S.fieldFull}>
      <label style={S.label}>{label}</label>
      <div style={{ display: 'flex', flexWrap: 'wrap', marginBottom: 6 }}>
        {selected.map(p => {
          const isPending = pendingIds?.has(p.id);
          return (
            <span key={p.id} style={{ ...S.chip, ...(isPending ? { background: '#fff8e1', border: '1px solid #ffc107', cursor: 'pointer' } : {}) }}
              onClick={isPending && onEditPending ? () => onEditPending(p.id) : undefined}
              title={isPending ? 'Click to edit' : undefined}>
              {isPending && <span style={{ fontSize: 11, fontWeight: 700, color: '#f57f17' }}>✨ new</span>}
              {p.firstName} {p.lastName}
              <button style={S.chipRemove} onClick={e => { e.stopPropagation(); onToggle(p.id); }}>×</button>
            </span>
          );
        })}
      </div>
      <input style={S.input} placeholder={`Search persons to add as ${label.toLowerCase()}...`}
        value={q} onChange={e => setQ(e.target.value)} />
      {q && filtered.length > 0 && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 150, overflowY: 'auto', marginTop: 4 }}>
          {filtered.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onToggle(p.id); setQ(''); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

