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
  /** Whether we are in edit mode (editing an existing person) */
  isEditMode?: boolean;
  /** Whether spouse/children + address are present, enabling "create new household" mode */
  canCreateHousehold?: boolean;
  /** Whether spouse/children are assigned (family exists but address may be missing) */
  hasFamily?: boolean;
  /** Names of family members who will be in the new household */
  familyMemberNames?: string[];
  /** New household name (controlled) */
  newHouseholdName?: string;
  onNewHouseholdNameChange?: (name: string) => void;
  /** Whether "create new household" mode is active */
  createMode?: boolean;
  onToggleCreateMode?: (on: boolean) => void;
  /** Validation error for the household name */
  householdNameError?: string;
  /** Selected primary contact ID for new household */
  newHouseholdPrimary?: string;
  onNewHouseholdPrimaryChange?: (id: string) => void;
  /** IDs of family members for primary contact selection */
  familyMemberIds?: string[];
}

export function HouseholdMembership({
  allPersons, households, editId, selectedHouseholdId, onSelectHousehold, onClearHousehold,
  isEditMode, canCreateHousehold, hasFamily, familyMemberNames, newHouseholdName, onNewHouseholdNameChange,
  createMode, onToggleCreateMode, householdNameError, newHouseholdPrimary, onNewHouseholdPrimaryChange, familyMemberIds,
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

      {/* Already assigned to a household */}
      {currentHousehold ? (
        <>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            Assign this person to a household. Their primary address will sync with the household address.
          </span>
          <div style={{ background: colors.accent, borderRadius: 8, padding: 12, marginBottom: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <strong>🏠 {currentHousehold.name}</strong>
              <button style={{ ...S.btn, ...S.btnSec, padding: '4px 10px', fontSize: 12 }} onClick={onClearHousehold}>Leave Household</button>
            </div>
            <div style={{ fontSize: 13, color: colors.textSec, marginTop: 6 }}>
              Members: {memberNames(currentHousehold).join(', ') || 'None'}
            </div>
          </div>
        </>
      ) : createMode && canCreateHousehold ? (
        /* ── Create New Household mode ── */
        <>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            Create a new household with this person and their family members. The person's address will be used as the household address.
          </span>
          <div style={{ background: '#f0f7ff', border: `1px solid ${colors.primary}40`, borderRadius: 8, padding: 14, marginBottom: 10 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
              <strong style={{ color: colors.primary }}>✨ New Household</strong>
              <button style={{ ...S.btn, ...S.btnSec, padding: '4px 10px', fontSize: 12 }}
                onClick={() => onToggleCreateMode?.(false)}>Cancel</button>
            </div>
            <label style={{ ...S.label, marginBottom: 4 }}>Household Name *</label>
            <input
              style={{ ...S.input, ...(householdNameError ? { borderColor: colors.danger } : {}) }}
              placeholder="e.g. Smith Family"
              value={newHouseholdName || ''}
              onChange={e => onNewHouseholdNameChange?.(e.target.value)}
            />
            {householdNameError && (
              <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>{householdNameError}</div>
            )}
            <div style={{ marginTop: 10, fontSize: 13, color: colors.textSec }}>
              <div style={{ fontWeight: 600, marginBottom: 4, color: colors.text }}>Members:</div>
              {familyMemberNames?.map((name, i) => {
                const mid = familyMemberIds?.[i];
                const isPrimary = mid === newHouseholdPrimary;
                return (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '2px 4px', borderRadius: 4, background: isPrimary ? '#c6f0c2' : 'transparent' }}>
                    <span>👤 {name}</span>
                    {isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>★ Primary</span>}
                  </div>
                );
              })}
            </div>
            {familyMemberIds && familyMemberIds.length > 0 && (
              <div style={{ marginTop: 8 }}>
                <label style={{ ...S.label, marginBottom: 4 }}>Primary Contact *</label>
                <select style={S.input} value={newHouseholdPrimary || ''} onChange={e => onNewHouseholdPrimaryChange?.(e.target.value)}>
                  {familyMemberIds.map((mid, i) => (
                    <option key={mid} value={mid}>{familyMemberNames?.[i] || 'Unknown'}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
        </>
      ) : (
        /* ── Not assigned / default mode ── */
        <>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            {canCreateHousehold
              ? 'Create a new household with this person and their family members. The person\'s address will be used as the household address.'
              : 'Assign this person to a household. Their primary address will sync with the household address.'}
          </span>

          {/* Mutually exclusive: show Create button or Search */}
          {canCreateHousehold ? (
            <div
              style={{ border: `2px dashed ${colors.primary}`, borderRadius: 8, padding: 12, marginBottom: 10,
                background: '#f8fbff', cursor: 'pointer', textAlign: 'center' as const }}
              onClick={() => onToggleCreateMode?.(true)}
              onMouseEnter={e => (e.currentTarget.style.background = '#eef4ff')}
              onMouseLeave={e => (e.currentTarget.style.background = '#f8fbff')}>
              <div style={{ color: colors.primary, fontWeight: 600, fontSize: 14 }}>+ Create New Household</div>
              <div style={{ color: colors.textSec, fontSize: 12, marginTop: 2 }}>
                With {familyMemberNames?.length || 0} family member{(familyMemberNames?.length || 0) !== 1 ? 's' : ''} and the current address
              </div>
            </div>
          ) : (
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
        </>
      )}
    </div>
  );
}

