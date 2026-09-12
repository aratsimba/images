import React from 'react';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName } from '../utils';

interface DeleteDialogProps {
  target: DirectoryEntry;
  allPersons: Person[];
  entries: DirectoryEntry[];
  onCancel: () => void;
  onConfirm: () => void;
}

export function DeleteDialog({ target, allPersons, entries, onCancel, onConfirm }: DeleteDialogProps) {
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };
  const cascadeEffects: string[] = [];
  if (target.type === 'person') {
    if (target.spouseId) cascadeEffects.push(`Unlink spouse ${resolveName(target.spouseId)}`);
    const parents = allPersons.filter(p => p.id !== target.id && p.childIds.includes(target.id));
    if (parents.length > 0) cascadeEffects.push(`Remove as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
    const linkedCompanies = entries.filter(e => e.type === 'company' && e.contactPersonIds.includes(target.id));
    if (linkedCompanies.length > 0) cascadeEffects.push(`Remove as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
  }
  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={S.dialog} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🗑️ Delete {target.type === 'person' ? 'Person' : 'Company'}</h3>
        <div style={S.dialogBody}>
          Are you sure you want to delete <strong>{getEntryName(target)}</strong>?
          {cascadeEffects.length > 0 && <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>{cascadeEffects.map((eff, i) => <li key={i}>{eff}</li>)}</ul>}
          {' '}This action cannot be undone.
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

