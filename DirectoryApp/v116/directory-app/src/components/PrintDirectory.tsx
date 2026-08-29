import React, { useState } from 'react';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Company, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName, getPrimary, formatPhoneDisplay } from '../utils';

export interface PrintConfig {
  includePersons: boolean;
  includeCompanies: boolean;
  statusFilter: 'active' | 'all';
  showPhotos: boolean;
  columns: 1 | 2;
}

interface PrintDialogProps {
  entries: DirectoryEntry[];
  households: Household[];
  images: Record<string, string>;
  onClose: () => void;
  onError: (msg: string) => void;
}

export function PrintDialog({ entries, households, images, onClose, onError }: PrintDialogProps) {
  const [config, setConfig] = useState<PrintConfig>({
    includePersons: true,
    includeCompanies: true,
    statusFilter: 'active',
    showPhotos: true,
    columns: 2,
  });
  const [generating, setGenerating] = useState(false);

  const personCount = entries.filter(e => e.type === 'person' && (config.statusFilter === 'all' || (e.status || 'active') === 'active')).length;
  const companyCount = entries.filter(e => e.type === 'company' && (config.statusFilter === 'all' || (e.companyStatus || 'active') === 'active')).length;
  const totalCount = (config.includePersons ? personCount : 0) + (config.includeCompanies ? companyCount : 0);

  const handleGenerate = async () => {
    if (totalCount === 0) { onError('No entries to print with current settings.'); return; }
    setGenerating(true);
    try {
      await generatePrintDirectory({ entries, households, images, config });
      onClose();
    } catch (e: any) {
      if (e?.message && !e.message.includes('declined')) onError(e.message);
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div style={S.overlay} onClick={onClose}>
      <div style={{ ...S.dialog, maxWidth: 440 }} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🖨️ Print Directory</h3>
        <div style={S.dialogBody}>
          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Include</div>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', marginBottom: 6, fontSize: 13 }}>
              <input type="checkbox" checked={config.includePersons}
                onChange={e => setConfig(c => ({ ...c, includePersons: e.target.checked }))} />
              👤 Persons <span style={{ color: colors.textSec, fontSize: 11 }}>({personCount})</span>
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 13 }}>
              <input type="checkbox" checked={config.includeCompanies}
                onChange={e => setConfig(c => ({ ...c, includeCompanies: e.target.checked }))} />
              🏢 Companies <span style={{ color: colors.textSec, fontSize: 11 }}>({companyCount})</span>
            </label>
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Status Filter</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {(['active', 'all'] as const).map(opt => (
                <button key={opt} onClick={() => setConfig(c => ({ ...c, statusFilter: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.statusFilter === opt ? colors.primary : '#fff',
                    color: config.statusFilter === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.statusFilter === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt === 'active' ? '● Active Only' : '○ All Entries'}
                </button>
              ))}
            </div>
            {config.statusFilter === 'all' && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
                Includes deceased persons and closed companies (shown dimmed).
              </div>
            )}
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Profile Photos</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {([true, false] as const).map(opt => (
                <button key={String(opt)} onClick={() => setConfig(c => ({ ...c, showPhotos: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.showPhotos === opt ? colors.primary : '#fff',
                    color: config.showPhotos === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.showPhotos === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt ? '📷 Show Photos' : '🚫 No Photos'}
                </button>
              ))}
            </div>
            {!config.showPhotos && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
                Smaller file size, faster printing.
              </div>
            )}
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Layout</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {([1, 2] as const).map(opt => (
                <button key={opt} onClick={() => setConfig(c => ({ ...c, columns: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.columns === opt ? colors.primary : '#fff',
                    color: config.columns === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.columns === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt === 1 ? '▐ Single Column' : '▐▐ Two Columns'}
                </button>
              ))}
            </div>
            <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
              {config.columns === 1 ? 'Spacious layout — good for large print or wall posters.' : 'Compact layout — fits more entries per page.'}
            </div>
          </div>

          <div style={{ background: colors.accent, borderRadius: 6, padding: '8px 12px', fontSize: 12, color: colors.textSec }}>
            Preview: <strong>{totalCount}</strong> entr{totalCount === 1 ? 'y' : 'ies'} will be included
            {config.showPhotos && Object.keys(images).length > 0 && <> · with photos</>}
            {' · '}{config.columns === 1 ? 'single' : 'two'}-column layout
          </div>
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onClose}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleGenerate} disabled={generating || totalCount === 0}>
            {generating ? 'Generating...' : '🖨️ Download Print File'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── HTML Generation ─────────────────────────────────────────────────

interface GenerateOptions {
  entries: DirectoryEntry[];
  households: Household[];
  images: Record<string, string>;
  config: PrintConfig;
}

async function generatePrintDirectory({ entries, households, images, config }: GenerateOptions): Promise<void> {
  const sorted = [...entries]
    .filter(e => {
      if (e.type === 'person') {
        if (!config.includePersons) return false;
        if (config.statusFilter === 'active') return (e.status || 'active') === 'active';
        return (e.status || 'active') !== 'archived';
      }
      if (!config.includeCompanies) return false;
      if (config.statusFilter === 'active') return (e.companyStatus || 'active') === 'active';
      return (e.companyStatus || 'active') !== 'archived';
    })
    .sort((a, b) => getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase()));

  const persons = sorted.filter((e): e is Person => e.type === 'person');
  const companies = sorted.filter((e): e is Company => e.type === 'company');

  const getPhone = (e: DirectoryEntry) => {
    const p = getPrimary(e.phones);
    return p ? `${p.countryCode || '+1'} ${formatPhoneDisplay(p.number)}` : '';
  };
  const getEmail = (e: DirectoryEntry) => getPrimary(e.emails)?.address || '';
  const getAddr = (e: DirectoryEntry) => {
    const a = getPrimary(e.addresses);
    if (!a) return '';
    return [a.street, a.street2, a.city, a.state, a.zip].filter(Boolean).join(', ');
  };

  const colCount = config.columns;

  const entryCard = (e: DirectoryEntry) => {
    const name = getEntryName(e);
    const phone = getPhone(e);
    const email = getEmail(e);
    const addr = getAddr(e);
    const img = config.showPhotos ? images[e.id] : undefined;
    const isDeceased = e.type === 'person' && e.status === 'deceased';
    const isClosed = e.type === 'company' && e.companyStatus === 'closed';
    const inactive = isDeceased || isClosed;
    const household = e.type === 'person' ? households.find(h => h.memberIds.includes(e.id)) : null;

    return `<div class="entry${inactive ? ' inactive' : ''}">
      <div class="entry-header">
        ${img ? `<img class="avatar" src="${img}" alt="" />` : (config.showPhotos ? `<div class="avatar-placeholder">${e.type === 'person' ? '👤' : '🏢'}</div>` : '')}
        <div class="entry-name">
          <strong>${escHtml(name)}</strong>
          ${inactive ? `<span class="status">${isDeceased ? '✝ Deceased' : '🚫 Closed'}</span>` : ''}
          ${e.type === 'company' && e.industry ? `<span class="industry">${escHtml(e.industry)}</span>` : ''}
          ${household ? `<span class="household">🏠 ${escHtml(household.name)}</span>` : ''}
        </div>
      </div>
      <div class="entry-details">
        ${phone ? `<div class="detail"><span class="icon">📞</span> ${escHtml(phone)}</div>` : ''}
        ${email ? `<div class="detail"><span class="icon">✉️</span> ${escHtml(email)}</div>` : ''}
        ${addr ? `<div class="detail"><span class="icon">📍</span> ${escHtml(addr)}</div>` : ''}
      </div>
    </div>`;
  };

  // Group persons by first letter
  const letterGroups = new Map<string, Person[]>();
  for (const p of persons) {
    const letter = p.lastName.charAt(0).toUpperCase() || '#';
    if (!letterGroups.has(letter)) letterGroups.set(letter, []);
    letterGroups.get(letter)!.push(p);
  }
  const sortedLetters = Array.from(letterGroups.keys()).sort();

  const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Directory — Printed ${today}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: ${colCount === 1 ? '12px' : '11px'}; color: #222; line-height: 1.4; padding: 0.5in; }
  h1 { font-size: ${colCount === 1 ? '24px' : '20px'}; text-align: center; margin-bottom: 4px; }
  .subtitle { text-align: center; color: #666; font-size: 11px; margin-bottom: 20px; }
  .section-title { font-size: ${colCount === 1 ? '16px' : '14px'}; font-weight: 700; color: #1a73e8; border-bottom: 2px solid #1a73e8; padding-bottom: 3px; margin: 16px 0 10px; page-break-after: avoid; }
  .letter-header { font-size: ${colCount === 1 ? '18px' : '16px'}; font-weight: 700; color: #333; background: #f0f4f8; padding: 4px 10px; border-radius: 4px; margin: 14px 0 8px; page-break-after: avoid; }
  .entries { column-count: ${colCount}; column-gap: 24px; }
  .entry { break-inside: avoid; border: 1px solid #e0e0e0; border-radius: 6px; padding: ${colCount === 1 ? '10px 14px' : '8px 10px'}; margin-bottom: ${colCount === 1 ? '10px' : '8px'}; background: #fff; }
  .entry.inactive { opacity: 0.6; border-left: 3px solid #9e9e9e; }
  .entry-header { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
  .avatar { width: ${colCount === 1 ? '36px' : '32px'}; height: ${colCount === 1 ? '36px' : '32px'}; border-radius: 50%; object-fit: cover; flex-shrink: 0; }
  .avatar-placeholder { width: ${colCount === 1 ? '36px' : '32px'}; height: ${colCount === 1 ? '36px' : '32px'}; border-radius: 50%; background: #f0f0f0; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0; }
  .entry-name { display: flex; flex-wrap: wrap; align-items: baseline; gap: 4px; }
  .entry-name strong { font-size: ${colCount === 1 ? '14px' : '12px'}; }
  .status { font-size: 9px; color: #666; background: #eee; padding: 1px 5px; border-radius: 8px; }
  .industry { font-size: 9px; color: #5f6368; }
  .household { font-size: 9px; color: #1a73e8; }
  .entry-details { ${config.showPhotos ? `padding-left: ${colCount === 1 ? '44px' : '40px'};` : ''} }
  .detail { margin-bottom: 2px; color: #444; }
  .icon { display: inline-block; width: 14px; text-align: center; }
  .stats { text-align: center; color: #666; font-size: 10px; margin-top: 16px; padding-top: 10px; border-top: 1px solid #ddd; }
  @media print {
    body { padding: 0.3in; }
    .entry { border-color: #ccc; }
    .no-print { display: none; }
  }
  .print-btn { display: block; margin: 0 auto 20px; padding: 10px 24px; font-size: 14px; font-weight: 600; background: #1a73e8; color: #fff; border: none; border-radius: 6px; cursor: pointer; }
  .print-btn:hover { background: #1558b0; }
</style>
</head>
<body>
<button class="print-btn no-print" onclick="window.print()">🖨️ Print This Directory</button>

<h1>📒 Directory</h1>
<div class="subtitle">Printed on ${escHtml(today)} · ${persons.length} person${persons.length !== 1 ? 's' : ''}${companies.length > 0 ? `, ${companies.length} compan${companies.length !== 1 ? 'ies' : 'y'}` : ''}</div>

${persons.length > 0 ? `
<div class="section-title">👤 Persons</div>
${sortedLetters.map(letter => `
<div class="letter-header">${escHtml(letter)}</div>
<div class="entries">
${letterGroups.get(letter)!.map(p => entryCard(p)).join('\n')}
</div>
`).join('\n')}
` : ''}

${companies.length > 0 ? `
<div class="section-title" style="margin-top: 24px;">🏢 Companies</div>
<div class="entries">
${companies.map(c => entryCard(c)).join('\n')}
</div>
` : ''}

<div class="stats">
  ${persons.length} person${persons.length !== 1 ? 's' : ''}${companies.length > 0 ? ` · ${companies.length} compan${companies.length !== 1 ? 'ies' : 'y'}` : ''} · ${households.length} household${households.length !== 1 ? 's' : ''}
</div>

</body>
</html>`;

  await downloadFile('directory-print.html', new Blob([html], { type: 'text/html' }));
}

function escHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

