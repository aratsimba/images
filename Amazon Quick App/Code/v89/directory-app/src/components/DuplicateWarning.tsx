import React from 'react';
import type { DirectoryEntry, DuplicateMatch } from '../types';
import { S, colors } from '../styles';
import { getPrimary, toE164 } from '../utils';

export function findDuplicates(
  entries: DirectoryEntry[],
  editId: string | null,
  name: string,
  primaryEmail: string,
  primaryPhone: string,
): DuplicateMatch[] {
  const normName = name.trim().toLowerCase();
  const normEmail = primaryEmail.trim().toLowerCase();
  const normPhone = primaryPhone ? toE164(primaryPhone).replace(/[^\d]/g, '') : '';
  if (!normName && !normEmail && !normPhone) return [];

  const matches: DuplicateMatch[] = [];
  for (const e of entries) {
    if (e.id === editId) continue;
    const reasons: string[] = [];
    const eName = e.type === 'person' ? `${e.firstName} ${e.lastName}`.toLowerCase() : e.name.toLowerCase();
    if (normName && eName && normName === eName) reasons.push('Same name');
    const ePrimEmail = getPrimary(e.emails)?.address?.trim().toLowerCase() || '';
    if (normEmail && ePrimEmail && normEmail === ePrimEmail) reasons.push('Same primary email');
    const ePrimPhone = getPrimary(e.phones)?.number ? toE164(getPrimary(e.phones)!.number).replace(/[^\d]/g, '') : '';
    if (normPhone && ePrimPhone && normPhone === ePrimPhone) reasons.push('Same primary phone');
    if (reasons.length > 0) matches.push({ entry: e, reasons });
  }
  return matches;
}

export function DuplicateWarningBanner({ duplicates, onViewEntry }: {
  duplicates: DuplicateMatch[];
  onViewEntry: (id: string) => void;
}) {
  if (duplicates.length === 0) return null;
  return (
    <div style={{ background: '#fef7e0', border: '1px solid #f9c642', borderRadius: 8, padding: '12px 16px', marginBottom: 16 }}>
      <div style={{ fontWeight: 700, fontSize: 14, color: '#7a5c00', marginBottom: 8 }}>
        ⚠️ Potential duplicate{duplicates.length > 1 ? 's' : ''} found
      </div>
      {duplicates.map(d => (
        <div key={d.entry.id} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6, fontSize: 13 }}>
          <span style={{
            ...S.badge,
            background: d.entry.type === 'person' ? '#e8f0fe' : '#fce8e6',
            color: d.entry.type === 'person' ? colors.primary : colors.danger,
          }}>
            {d.entry.type === 'person' ? '👤' : '🏢'}
          </span>
          <span style={{ fontWeight: 600 }}>
            {d.entry.type === 'person' ? `${d.entry.firstName} ${d.entry.lastName}` : d.entry.name}
          </span>
          <span style={{ color: '#7a5c00' }}>— {d.reasons.join(', ')}</span>
          <button style={{ ...S.btn, padding: '2px 10px', fontSize: 12, ...S.btnSec, marginLeft: 'auto' }}
            onClick={() => onViewEntry(d.entry.id)}>View</button>
        </div>
      ))}
      <div style={{ fontSize: 12, color: '#7a5c00', marginTop: 6 }}>
        Review the entries above before saving to avoid duplicates.
      </div>
    </div>
  );
}

