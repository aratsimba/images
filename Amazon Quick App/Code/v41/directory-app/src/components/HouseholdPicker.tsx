import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

interface HouseholdPickerProps {
  allPersons: Person[];
  editId: string | null;
  spouseId: string;
  childIds: string[];
  /** Manually-added household member IDs (beyond spouse/children) */
  extraMemberIds: string[];
  onAddMember: (id: string) => void;
  onRemoveMember: (id: string) => void;
  onRemoveFromHousehold: (id: string) => void;
}

export function HouseholdPicker({
  allPersons, editId, spouseId, childIds, extraMemberIds, onAddMember, onRemoveMember,
  onRemoveFromHousehold,
}: HouseholdPickerProps) {
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

  const autoIds = [...new Set([...(spouseId ? [spouseId] : []), ...childIds])];
  const allMemberIds = [...new Set([...autoIds, ...extraMemberIds])];

  const resolve = (id: string) => allPersons.find(p => p.id === id);

  const roleLabel = (id: string): string => {
    if (id === spouseId) return 'spouse';
    if (childIds.includes(id)) return 'child';
    return '';
  };

  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (allMemberIds.includes(p.id)) return false;
    return `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase());
  });

  return (
    <div style={S.fieldFull} ref={ref}>
      <div style={S.section}>Household Members</div>
      <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
        Members share the same primary address. Spouse and children are automatically included. Removing from household does not affect relationships.
      </span>

      {allMemberIds.length === 0 ? (
        <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>No household members yet.</div>
      ) : (
        <div style={{ display: 'flex', flexWrap: 'wrap', marginBottom: 8 }}>
          {allMemberIds.map(id => {
            const p = resolve(id);
            if (!p) return null;
            const isAuto = autoIds.includes(id);
            const role = roleLabel(id);
            return (
              <span key={id} style={{ ...S.chip, background: isAuto ? '#e8f5e9' : colors.accent }}>
                {p.firstName} {p.lastName}
                {role && <span style={{ fontSize: 10, color: colors.textSec, marginLeft: 2 }}>({role})</span>}
                {isAuto ? (
                  <button style={S.chipRemove} title={`Remove ${p.firstName} from household (keeps relationship)`}
                    onClick={() => onRemoveFromHousehold(id)}>×</button>
                ) : (
                  <button style={S.chipRemove} onClick={() => onRemoveMember(id)}>×</button>
                )}
              </span>
            );
          })}
        </div>
      )}

      <input
        style={S.input}
        placeholder="Search for a person to add to household..."
        value={q}
        onChange={e => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => { if (q) setOpen(true); }}
      />
      {open && q && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4 }}>
          {eligible.length === 0 && (
            <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons</div>
          )}
          {eligible.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onAddMember(p.id); setQ(''); setOpen(false); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

