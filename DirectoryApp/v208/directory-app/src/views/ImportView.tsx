import React from 'react';
import type { DirectoryEntry, Household } from '../types';
import { S, colors } from '../styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr } from '../utils';

interface Props {
  importPreview: DirectoryEntry[];
  importHouseholdsPreview: Household[];
  importFileName: string;
  importing: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ImportView({ importPreview, importHouseholdsPreview, importFileName, importing, onConfirm, onCancel }: Props) {
  const total = importPreview.length + importHouseholdsPreview.length;
  return (
    <>
      <h2 style={{ marginBottom: 8 }}>📤 Import Preview</h2>
      <p style={{ fontSize: 13, color: colors.textSec, marginBottom: 16 }}>
        File: <strong>{importFileName}</strong> — {importPreview.length} entr{importPreview.length === 1 ? 'y' : 'ies'}
        {importHouseholdsPreview.length > 0 && ` and ${importHouseholdsPreview.length} household${importHouseholdsPreview.length === 1 ? '' : 's'}`} found.
      </p>
      {total === 0 ? <div style={S.emptyState}>No valid records found in the CSV file.</div> : (
        <>
          {importPreview.length > 0 && (
            <div style={{ overflowX: 'auto', marginBottom: 16 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                <thead><tr style={{ background: colors.accent }}>
                  {['#', 'Type', 'Name', 'Primary Email', 'Primary Phone', 'City/State'].map(h => (
                    <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                  ))}
                </tr></thead>
                <tbody>
                  {importPreview.map((e, i) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                      <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                      <td style={{ padding: '8px 12px' }}><span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>{e.type === 'person' ? '👤' : '🏢'}</span></td>
                      <td style={{ padding: '8px 12px', fontWeight: 600 }}>{getEntryName(e)}</td>
                      <td style={{ padding: '8px 12px' }}>{getPrimary(e.emails)?.address || '—'}</td>
                      <td style={{ padding: '8px 12px' }}>{getPrimary(e.phones)?.number ? formatPhoneDisplay(getPrimary(e.phones)!.number) : '—'}</td>
                      <td style={{ padding: '8px 12px' }}>{(() => { const a = getPrimary(e.addresses); return a ? [a.city, a.state].filter(Boolean).join(', ') || '—' : '—'; })()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          {importHouseholdsPreview.length > 0 && (
            <div style={{ overflowX: 'auto', marginBottom: 16 }}>
              <h3 style={{ fontSize: 15, marginBottom: 8 }}>🏠 Households</h3>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                <thead><tr style={{ background: colors.accent }}>
                  {['#', 'Name', 'Address', 'Members'].map(h => (
                    <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                  ))}
                </tr></thead>
                <tbody>
                  {importHouseholdsPreview.map((h, i) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                      <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                      <td style={{ padding: '8px 12px', fontWeight: 600 }}>🏠 {h.name}</td>
                      <td style={{ padding: '8px 12px' }}>{h.address ? formatAddr(h.address) : '—'}</td>
                      <td style={{ padding: '8px 12px' }}>{h.memberIds.length} member{h.memberIds.length === 1 ? '' : 's'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
      <div style={{ ...S.btnRow, marginTop: 8 }}>
        <button style={{ ...S.btn, ...S.btnPrimary }} onClick={onConfirm} disabled={importing || total === 0}>
          {importing ? 'Importing...' : `✅ Import ${total} Record${total === 1 ? '' : 's'}`}
        </button>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel} disabled={importing}>Cancel</button>
      </div>
    </>
  );
}

