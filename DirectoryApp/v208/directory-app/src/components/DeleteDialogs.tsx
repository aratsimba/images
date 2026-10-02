import React from 'react';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName, selectNewPrimaryContact } from '../utils';

interface DeleteDialogProps {
  target: DirectoryEntry;
  allPersons: Person[];
  entries: DirectoryEntry[];
  households: Household[];
  onCancel: () => void;
  onConfirm: () => void;
}

export function DeleteDialog({ target, allPersons, entries, households, onCancel, onConfirm }: DeleteDialogProps) {
  const effects: { icon: string; text: string }[] = [];
  if (target.type === 'person') {
    if (target.spouseId) {
      const spouse = entries.find(e => e.id === target.spouseId);
      effects.push({ icon: '💍', text: `Unlink spouse ${spouse ? getEntryName(spouse) : 'Unknown'}.` });
    }
    const parents = allPersons.filter(p => p.id !== target.id && p.childIds.includes(target.id));
    if (parents.length > 0) effects.push({ icon: '🧒', text: `Remove as child from ${parents.map(p => getEntryName(p)).join(', ')}.` });
    const linkedCompanies = entries.filter(e => e.type === 'company' && e.contactPersonIds.includes(target.id));
    if (linkedCompanies.length > 0) effects.push({ icon: '🏢', text: `Remove as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}.` });
    if (target.householdId) {
      const hh = households.find(h => h.id === target.householdId);
      if (hh) {
        const remainingIds = hh.memberIds.filter(mid => mid !== target.id);
        if (remainingIds.length < 2) {
          effects.push({ icon: '🏚️', text: `${hh.name} will be dissolved (fewer than 2 members remaining).` });
          if (remainingIds.length === 1) {
            const lastPerson = allPersons.find(p => p.id === remainingIds[0]);
            if (lastPerson) effects.push({ icon: '🏠', text: `${getEntryName(lastPerson)}'s address label will change from "Household" to "Home".` });
          }
        } else {
          effects.push({ icon: '🏠', text: `Remove from ${hh.name} (${remainingIds.length} members will remain).` });
          if (hh.primaryContactId === target.id) {
            const newPrimary = selectNewPrimaryContact(target.id, remainingIds, allPersons);
            const newPrimaryPerson = allPersons.find(p => p.id === newPrimary);
            if (newPrimaryPerson) effects.push({ icon: '★', text: `${hh.name}'s primary contact will change to ${getEntryName(newPrimaryPerson)}.` });
          }
        }
      }
    }
  }
  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={S.dialog} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🗑️ Delete {target.type === 'person' ? 'Person' : 'Company'}</h3>
        <div style={S.dialogBody}>
          <div style={{ marginBottom: effects.length > 0 ? 10 : 0 }}>
            Are you sure you want to delete <strong>{getEntryName(target)}</strong>?
          </div>
          {effects.length > 0 && (
            <div style={{ background: '#fff8e1', border: '1px solid #ffe082', borderRadius: 8, padding: '10px 14px', marginBottom: 10, fontSize: 13, lineHeight: 1.6 }}>
              <div style={{ fontWeight: 600, marginBottom: 4, color: '#e65100' }}>⚠ Pending changes on save:</div>
              {effects.map((e, i) => (
                <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                  <span style={{ flexShrink: 0 }}>{e.icon}</span>
                  <span style={{ color: colors.text }}>{e.text}</span>
                </div>
              ))}
            </div>
          )}
          <div style={{ fontSize: 13 }}>This action cannot be undone.</div>
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnDanger }} onClick={onConfirm}>Delete</button>
        </div>
      </div>
    </div>
  );
}

interface DeleteAllDialogProps {
  entryCount: number;
  householdCount: number;
  onCancel: () => void;
  onConfirm: () => void;
}

export function DeleteAllDialog({ entryCount, householdCount, onCancel, onConfirm }: DeleteAllDialogProps) {
  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={S.dialog} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🗑️ Delete All Entries</h3>
        <div style={S.dialogBody}>
          Are you sure you want to delete <strong>all {entryCount} entr{entryCount === 1 ? 'y' : 'ies'}</strong>
          {householdCount > 0 && <> and <strong>{householdCount} household{householdCount === 1 ? '' : 's'}</strong></>}
          ? This action cannot be undone.
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnDanger }} onClick={onConfirm}>Delete All</button>
        </div>
      </div>
    </div>
  );
}

