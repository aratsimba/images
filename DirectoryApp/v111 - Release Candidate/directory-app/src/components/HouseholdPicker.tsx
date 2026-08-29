import React, { useState, useRef, useEffect } from 'react';
import type { Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName } from '../utils';

interface HouseholdMembershipProps {
  allPersons: Person[];
  households: Household[];
  editId: string | null;
  selectedHouseholdId: string;
  onSelectHousehold: (householdId: string) => void;
  onClearHousehold: () => void;
}

export function HouseholdMembership({
  allPersons, households, editId, selectedHouseholdId, onSelectHousehold, onClearHousehold,
}: HouseholdMembershipProps) {
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

  const currentHousehold = households.find(h => h.id === selectedHouseholdId);

  // Filter households for search: exclude households that already have this person
  // (they can still see their current household)
  const eligible = households.filter(h => {
    if (h.id === selectedHouseholdId) return false;
    return h.name.toLowerCase().includes(q.toLowerCase());
  });

  const memberNames = (h: Household) =>
    h.memberIds.map(mid => {
      const p = allPersons.find(x => x.id === mid);
      return p ? getEntryName(p) : 'Unknown';
    });

  return (
    <div style={S.fieldFull} ref={ref}>
      <div style={S.section}>Household Membership</div>
      <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
        Assign this person to a household. Their primary address will sync with the household address.
      </span>

      {currentHousehold ? (
        <div style={{ background: colors.accent, borderRadius: 8, padding: 12, marginBottom: 10 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <strong>🏠 {currentHousehold.name}</strong>
            <button style={{ ...S.btn, ...S.btnSec, padding: '4px 10px', fontSize: 12 }} onClick={onClearHousehold}>Leave Household</button>
          </div>
          <div style={{ fontSize: 13, color: colors.textSec, marginTop: 6 }}>
            Members: {memberNames(currentHousehold).join(', ') || 'None'}
          </div>
        </div>
      ) : (
        <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>Not assigned to any household.</div>
      )}

      {!currentHousehold && (
        <>
          <input
            style={S.input}
            placeholder="Search for a household to join..."
            value={q}
            onChange={e => { setQ(e.target.value); setOpen(true); }}
            onFocus={() => { if (q) setOpen(true); }}
          />
          {open && q && (
            <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4 }}>
              {eligible.length === 0 && (
                <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching households</div>
              )}
              {eligible.slice(0, 8).map(h => (
                <div key={h.id} style={S.dropdownItem}
                  onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                  onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                  onClick={() => { onSelectHousehold(h.id); setQ(''); setOpen(false); }}>
                  🏠 {h.name}
                  <span style={{ fontSize: 12, color: colors.textSec, marginLeft: 8 }}>
                    ({h.memberIds.length} members)
                  </span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}

