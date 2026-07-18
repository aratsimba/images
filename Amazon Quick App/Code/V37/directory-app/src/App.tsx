import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';

import type {
  DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address,
  View, SortField, SortDir, TypeFilter,
} from './types';
import { EMPTY_ADDR, EMPTY_PHONE, EMPTY_EMAIL, EMAIL_LABELS_PERSON, EMAIL_LABELS_COMPANY, PHONE_LABELS_PERSON, PHONE_LABELS_COMPANY, GENDER_OPTIONS } from './types';
import { S, colors } from './styles';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, getEntryName, formatAddr, calculateAge, getAncestorIds, getDescendantIds } from './utils';
import { saveEntry, loadEntry, loadAll, removeEntry, exportCsv, parseCsvFile } from './storage';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { RelationshipPicker } from './components/RelationshipPicker';
import { SpousePicker } from './components/SpousePicker';
import { HouseholdPicker } from './components/HouseholdPicker';
import { findDuplicates, DuplicateWarningBanner } from './components/DuplicateWarning';
import { Toolbar } from './components/Toolbar';

import appSource from './App.tsx?raw';
import devLog from './DEVLOG.md?raw';
import typesSource from './types.ts?raw';
import stylesSource from './styles.ts?raw';
import utilsSource from './utils.ts?raw';
import storageSource from './storage.ts?raw';
import addressFieldsSource from './components/AddressFields.tsx?raw';
import multiItemFieldSource from './components/MultiItemField.tsx?raw';
import relationshipPickerSource from './components/RelationshipPicker.tsx?raw';
import spousePickerSource from './components/SpousePicker.tsx?raw';
import householdPickerSource from './components/HouseholdPicker.tsx?raw';
import duplicateWarningSource from './components/DuplicateWarning.tsx?raw';
import toolbarSource from './components/Toolbar.tsx?raw';

// ─── Main App ────────────────────────────────────────────────────────

export const App = () => {
  const [view, setView] = useState<View>('list');
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [editId, setEditId] = useState<string | null>(null);

  // Search
  const [searchQ, setSearchQ] = useState('');
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  // Sort & Filter
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all');
  const [industryFilter, setIndustryFilter] = useState('');

  // Person form state
  const [pFirst, setPFirst] = useState('');
  const [pLast, setPLast] = useState('');
  const [pGender, setPGender] = useState('');
  const [pBirthday, setPBirthday] = useState('');
  const [pAnniversary, setPAnniversary] = useState('');
  const [pEmails, setPEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [pPhones, setPPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [pAddrs, setPAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [pSpouseId, setPSpouseId] = useState('');
  const [pChildIds, setPChildIds] = useState<string[]>([]);
  const [pHouseholdId, setPHouseholdId] = useState('');
  const [pHouseholdExtraIds, setPHouseholdExtraIds] = useState<string[]>([]);
  const [pHouseholdExcludedIds, setPHouseholdExcludedIds] = useState<string[]>([]);
  const [pNotes, setPNotes] = useState('');

  // Company form state
  const [cName, setCName] = useState('');
  const [cIndustry, setCIndustry] = useState('');
  const [cEmails, setCEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [cPhones, setCPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [cAddrs, setCAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [cContactIds, setCContactIds] = useState<string[]>([]);
  const [cNotes, setCNotes] = useState('');

  // Import state
  const [importPreview, setImportPreview] = useState<DirectoryEntry[]>([]);
  const [importFileName, setImportFileName] = useState('');
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Delete confirmation
  const [deleteTarget, setDeleteTarget] = useState<DirectoryEntry | null>(null);
  const [showDeleteAll, setShowDeleteAll] = useState(false);
  const [deletingAll, setDeletingAll] = useState(false);

  const allPersons = entries.filter((e): e is Person => e.type === 'person');

  // Duplicate detection
  const personDuplicates = useMemo(() =>
    findDuplicates(entries, editId, `${pFirst} ${pLast}`, getPrimary(pEmails)?.address || '', getPrimary(pPhones)?.number || ''),
    [entries, editId, pFirst, pLast, pEmails, pPhones]
  );
  const companyDuplicates = useMemo(() =>
    findDuplicates(entries, editId, cName, getPrimary(cEmails)?.address || '', getPrimary(cPhones)?.number || ''),
    [entries, editId, cName, cEmails, cPhones]
  );

  const viewDuplicate = (id: string) => { setSelectedId(id); setView('detail'); };

  // Load
  const reload = useCallback(async () => {
    try { setLoading(true); setEntries(await loadAll()); }
    catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { reload(); }, [reload]);

  // Search
  const sq = searchQ.toLowerCase();
  const searchResults = entries.filter(e =>
    e.type === 'person'
      ? `${e.firstName} ${e.lastName} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
      : `${e.name} ${e.industry} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
  );

  const allIndustries = useMemo(() => {
    const set = new Set<string>();
    entries.forEach(e => { if (e.type === 'company' && e.industry.trim()) set.add(e.industry.trim()); });
    return Array.from(set).sort();
  }, [entries]);

  const filteredEntries = useMemo(() => {
    let list = searchQ ? searchResults : entries;
    if (typeFilter !== 'all') list = list.filter(e => e.type === typeFilter);
    if (industryFilter) list = list.filter(e => e.type === 'company' && e.industry.trim().toLowerCase() === industryFilter.toLowerCase());
    list = [...list].sort((a, b) => {
      let cmp = 0;
      if (sortField === 'name') cmp = getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else if (sortField === 'type') cmp = a.type.localeCompare(b.type) || getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else cmp = a.id.localeCompare(b.id);
      return sortDir === 'desc' ? -cmp : cmp;
    });
    return list;
  }, [entries, searchQ, searchResults, typeFilter, industryFilter, sortField, sortDir]);

  // Close search dropdown on outside click
  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(ev.target as Node)) setShowSearchDropdown(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  // ── Form helpers ──

  const resetPersonForm = () => {
    setPFirst(''); setPLast(''); setPGender(''); setPBirthday(''); setPAnniversary('');
    setPEmails([{ ...EMPTY_EMAIL }]); setPPhones([{ ...EMPTY_PHONE }]); setPAddrs([{ ...EMPTY_ADDR }]);
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(uuidv4()); setPHouseholdExtraIds([]); setPHouseholdExcludedIds([]); setPNotes(''); setEditId(null);
  };

  const resetCompanyForm = () => {
    setCName(''); setCIndustry('');
    setCEmails([{ ...EMPTY_EMAIL }]); setCPhones([{ ...EMPTY_PHONE }]); setCAddrs([{ ...EMPTY_ADDR }]);
    setCContactIds([]); setCNotes(''); setEditId(null);
  };

  const fillPersonForm = (p: Person) => {
    setPFirst(p.firstName); setPLast(p.lastName);
    setPGender(p.gender || ''); setPBirthday(p.birthday || ''); setPAnniversary(p.weddingAnniversary || '');
    setPEmails(p.emails.length ? [...p.emails] : [{ ...EMPTY_EMAIL }]);
    setPPhones(p.phones.length ? [...p.phones] : [{ ...EMPTY_PHONE }]);
    setPAddrs(p.addresses.length ? [...p.addresses] : [{ ...EMPTY_ADDR }]);
    setPSpouseId(p.spouseId);
    // Merge children with spouse's children to ensure sync
    let mergedChildIds = [...p.childIds];
    if (p.spouseId) {
      const spouse = entries.find(e => e.id === p.spouseId);
      if (spouse && spouse.type === 'person') {
        mergedChildIds = Array.from(new Set([...p.childIds, ...spouse.childIds]));
      }
    }
    setPChildIds(mergedChildIds);
    setPHouseholdId(p.householdId);
    // Compute extra household members: same householdId but not self, spouse, or children
    const autoIds = new Set([...(p.spouseId ? [p.spouseId] : []), ...mergedChildIds]);
    const extras = allPersons
      .filter(m => m.id !== p.id && m.householdId === p.householdId && !autoIds.has(m.id))
      .map(m => m.id);
    setPHouseholdExtraIds(extras);
    // Compute excluded auto-members: spouse/children with a different householdId
    const excluded = [...autoIds].filter(id => {
      const m = allPersons.find(x => x.id === id);
      return m && m.householdId !== p.householdId;
    });
    setPHouseholdExcludedIds(excluded);
    setPNotes(p.notes); setEditId(p.id);
  };

  const fillCompanyForm = (c: Company) => {
    setCName(c.name); setCIndustry(c.industry);
    setCEmails(c.emails.length ? [...c.emails] : [{ ...EMPTY_EMAIL }]);
    setCPhones(c.phones.length ? [...c.phones] : [{ ...EMPTY_PHONE }]);
    setCAddrs(c.addresses.length ? [...c.addresses] : [{ ...EMPTY_ADDR }]);
    setCContactIds([...c.contactPersonIds]); setCNotes(c.notes); setEditId(c.id);
  };

  // ── Save person ──
  const savePerson = async () => {
    if (!pFirst.trim() || !pLast.trim()) { setError('First and last name are required.'); return; }
    if (!pGender) { setError('Gender is required.'); return; }
    setError('');
    const id = editId || uuidv4();
    const cleanPhones = pPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = pEmails.filter(e => e.address.trim());
    const cleanAddrs = pAddrs.filter(a => a.street.trim() || a.city.trim());
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];

    const person: Person = {
      id, type: 'person', firstName: pFirst.trim(), lastName: pLast.trim(),
      gender: pGender, birthday: pBirthday, weddingAnniversary: pAnniversary,
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId, notes: pNotes.trim(),
    };

    // Collect all household member IDs (spouse + children + extras), excluding those removed from household
    const householdMemberIds = [...new Set([
      ...(pSpouseId && !pHouseholdExcludedIds.includes(pSpouseId) ? [pSpouseId] : []),
      ...pChildIds.filter(id => !pHouseholdExcludedIds.includes(id)),
      ...pHouseholdExtraIds,
    ])];

    try {
      // If editing and spouse changed, clear old spouse's link and anniversary on both sides
      // but preserve the full shared children set on the old spouse
      if (editId) {
        const oldPerson = allPersons.find(p => p.id === editId);
        if (oldPerson && oldPerson.spouseId && oldPerson.spouseId !== pSpouseId) {
          const oldSpouse = await loadEntry(oldPerson.spouseId);
          if (oldSpouse && oldSpouse.type === 'person') {
            // Merge children: old spouse keeps union of their children and the current person's children
            const mergedChildren = Array.from(new Set([...oldSpouse.childIds, ...pChildIds]));
            await saveEntry({ ...oldSpouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
          // Clear anniversary on the current person as well
          person.weddingAnniversary = '';
        }
      }

      await saveEntry(person);

      // Sync spouse's childIds and householdId (only if spouse is in household)
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const spouseInHousehold = !pHouseholdExcludedIds.includes(pSpouseId);
          const newHouseholdId = spouseInHousehold ? pHouseholdId : spouse.householdId;
          const needsUpdate = spouse.spouseId !== id ||
            spouse.householdId !== newHouseholdId ||
            spouse.weddingAnniversary !== pAnniversary ||
            JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate)
            await saveEntry({ ...spouse, spouseId: id, householdId: newHouseholdId, childIds: pChildIds, weddingAnniversary: pAnniversary });
        }
      }

      // Sync householdId and primary address for all household members
      const primaryAddr = getPrimary(finalAddrs);
      for (const memberId of householdMemberIds) {
        if (memberId === pSpouseId) {
          // Spouse already handled above for childIds/spouseId; just sync address if needed
          if (primaryAddr) {
            const spouse = await loadEntry(memberId);
            if (spouse && spouse.type === 'person') {
              const mAddrs = [...spouse.addresses];
              const pIdx = mAddrs.findIndex(a => a.isPrimary);
              if (pIdx >= 0) mAddrs[pIdx] = { ...primaryAddr };
              else if (mAddrs.length > 0) { mAddrs[0] = { ...primaryAddr, isPrimary: true }; }
              else mAddrs.push({ ...primaryAddr });
              await saveEntry({ ...spouse, householdId: pHouseholdId, addresses: mAddrs });
            }
          }
          continue;
        }
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const updates: Partial<Person> = { householdId: pHouseholdId };
          if (primaryAddr) {
            const mAddrs = [...member.addresses];
            const pIdx = mAddrs.findIndex(a => a.isPrimary);
            if (pIdx >= 0) mAddrs[pIdx] = { ...primaryAddr };
            else if (mAddrs.length > 0) { mAddrs[0] = { ...primaryAddr, isPrimary: true }; }
            else mAddrs.push({ ...primaryAddr });
            updates.addresses = mAddrs;
          }
          await saveEntry({ ...member, ...updates });
        }
      }

      await reload(); resetPersonForm(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Save company ──
  const saveCompany = async () => {
    if (!cName.trim()) { setError('Company name is required.'); return; }
    setError('');
    const id = editId || uuidv4();
    const cleanPhones = cPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = cEmails.filter(e => e.address.trim());
    const cleanAddrs = cAddrs.filter(a => a.street.trim() || a.city.trim());
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];

    const company: Company = {
      id, type: 'company', name: cName.trim(), industry: cIndustry.trim(),
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      contactPersonIds: cContactIds, notes: cNotes.trim(),
    };
    try {
      await saveEntry(company); await reload(); resetCompanyForm(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Delete ──
  const requestDelete = (entry: DirectoryEntry) => setDeleteTarget(entry);
  const cancelDelete = () => setDeleteTarget(null);
  const confirmDelete = async () => {
    if (!deleteTarget) return;
    const id = deleteTarget.id;
    setDeleteTarget(null);
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person') {
        // Unlink spouse, clear their wedding anniversary, and transfer full children set
        if (entry.spouseId) {
          const spouse = await loadEntry(entry.spouseId);
          if (spouse && spouse.type === 'person') {
            // Surviving spouse inherits the full merged children set (minus the deleted person if they were a child)
            const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => cid !== id);
            await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
        }
        // Remove from all parents' childIds
        for (const p of allPersons) {
          if (p.id !== id && p.childIds.includes(id)) {
            await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
          }
        }
        // Remove from all companies' contactPersonIds
        for (const e of entries) {
          if (e.type === 'company' && e.contactPersonIds.includes(id)) {
            await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
          }
        }
      }
      await removeEntry(id); await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Delete All ──
  const handleDeleteAll = async () => {
    setShowDeleteAll(false);
    setDeletingAll(true);
    try {
      for (const entry of entries) await removeEntry(entry.id);
      await reload();
      setSelectedId(null);
      setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
    finally { setDeletingAll(false); }
  };

  // ── Helpers ──
  const resolveName = (id: string) => {
    const e = entries.find(x => x.id === id);
    return e ? getEntryName(e) : 'Unknown';
  };
  const getPrimaryEmail = (e: DirectoryEntry) => getPrimary(e.emails)?.address || '';
  const getPrimaryAddr = (e: DirectoryEntry) => { const a = getPrimary(e.addresses); return a ? formatAddr(a) : '—'; };

  const selectedEntry = entries.find(e => e.id === selectedId);

  // ── Downloads ──
  const handleDownloadCode = async () => {
    const files: [string, string][] = [
      ['src/types.ts', typesSource],
      ['src/styles.ts', stylesSource],
      ['src/utils.ts', utilsSource],
      ['src/storage.ts', storageSource],
      ['src/components/AddressFields.tsx', addressFieldsSource],
      ['src/components/MultiItemField.tsx', multiItemFieldSource],
      ['src/components/RelationshipPicker.tsx', relationshipPickerSource],
      ['src/components/SpousePicker.tsx', spousePickerSource],
      ['src/components/HouseholdPicker.tsx', householdPickerSource],
      ['src/components/DuplicateWarning.tsx', duplicateWarningSource],
      ['src/components/Toolbar.tsx', toolbarSource],
      ['src/App.tsx', appSource],
      ['DEVLOG.md', devLog],
    ];

    // Build a self-extracting shell script using heredocs
    const lines: string[] = [
      '#!/usr/bin/env bash',
      '# Directory App — Self-Extracting Source Code',
      '# Run: bash directory-app.sh',
      '# This will create a "directory-app/" folder with the full project structure.',
      '',
      'set -e',
      'ROOT="directory-app"',
      'mkdir -p "$ROOT/src/components"',
      'echo "Extracting files into $ROOT/ ..."',
      '',
    ];

    for (const [path, content] of files) {
      // Use a unique heredoc delimiter per file to avoid collisions
      const delim = `__EOF_${path.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}__`;
      lines.push(`cat > "$ROOT/${path}" << '${delim}'`);
      lines.push(content);
      lines.push(delim);
      lines.push('');
    }

    lines.push('echo "✅ Done! Extracted ' + files.length + ' files into $ROOT/"');
    lines.push('echo ""');
    lines.push('echo "Project structure:"');
    lines.push('if command -v tree &> /dev/null; then tree "$ROOT"; else find "$ROOT" -type f | sort; fi');

    const script = lines.join('\n');
    try { await downloadFile('directory-app.sh', new Blob([script], { type: 'text/x-shellscript' })); }
    catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  const handleDownloadMarkdown = async () => {
    try { await downloadFile('directory-app-conversation.md', new Blob([devLog], { type: 'text/markdown' })); }
    catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  // ── CSV ──
  const handleExportCsv = async () => {
    if (entries.length === 0) { setError('No entries to export.'); return; }
    try { await downloadFile('directory-export.csv', new Blob([exportCsv(entries)], { type: 'text/csv' })); }
    catch (e: any) { setError(e?.message || 'Export failed'); }
  };

  const handleFileSelect = async (file: File) => {
    setError(''); setImportFileName(file.name);
    const { entries: parsed, errors } = await parseCsvFile(file);
    if (errors.length > 0) setError(errors.slice(0, 5).join('. ') + (errors.length > 5 ? ` ...and ${errors.length - 5} more.` : ''));
    setImportPreview(parsed); setView('import');
  };

  const handleImportConfirm = async () => {
    if (importPreview.length === 0) return;
    setImporting(true); setError('');
    try {
      let saved = 0;
      for (const entry of importPreview) { await saveEntry(entry); saved++; }
      await reload(); setImportPreview([]); setImportFileName(''); setView('list');
      setError(`✅ Successfully imported ${saved} entr${saved === 1 ? 'y' : 'ies'}.`);
      setTimeout(() => setError(prev => prev.startsWith('✅') ? '' : prev), 3000);
    } catch (e) { if (e instanceof PageStorageError) setError(e.message); }
    finally { setImporting(false); }
  };

  const handleImportCancel = () => { setImportPreview([]); setImportFileName(''); setView('list'); };

  // ── Render ──
  return (
    <div style={S.app}>
      {/* Header */}
      <div style={S.header}>
        <h1 style={S.headerTitle} onClick={() => { setView('list'); setSelectedId(null); setSearchQ(''); }}>📒 Directory</h1>
        <div style={S.searchWrap} ref={searchRef}>
          <input style={S.searchInput} placeholder="Search persons & companies..."
            value={searchQ} onChange={e => { setSearchQ(e.target.value); setShowSearchDropdown(true); }}
            onFocus={() => setShowSearchDropdown(true)} />
          {showSearchDropdown && searchQ && (
            <div style={S.dropdown}>
              {searchResults.length === 0 && <div style={{ padding: 14, color: colors.textSec }}>No results</div>}
              {searchResults.slice(0, 10).map(e => (
                <div key={e.id} style={S.dropdownItem}
                  onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)}
                  onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')}
                  onClick={() => { setSearchQ(getEntryName(e)); setShowSearchDropdown(false); setSelectedId(e.id); setView('detail'); }}>
                  <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                    {e.type === 'person' ? '👤' : '🏢'}
                  </span>
                  {getEntryName(e)}
                  {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({e.industry})</span>}
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', gap: 8, marginLeft: 12 }}>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }} onClick={handleDownloadCode} title="Download source code">💾 Export Code</button>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }} onClick={handleDownloadMarkdown} title="Download conversation log">📄 Export Log</button>
        </div>
      </div>

      <div style={S.body}>
        {error && <div style={S.error}>{error}</div>}

        {/* ── LIST VIEW ── */}
        {view === 'list' && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { resetPersonForm(); setView('personForm'); }}>+ Add Person</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { resetCompanyForm(); setView('companyForm'); }}>+ Add Company</button>
              <div style={{ flex: 1 }} />
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleExportCsv}>📥 Export CSV</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => fileInputRef.current?.click()}>📤 Import CSV</button>
              <input ref={fileInputRef} type="file" accept=".csv" style={{ display: 'none' }}
                onChange={e => { const f = e.target.files?.[0]; if (f) handleFileSelect(f); e.target.value = ''; }} />
              {entries.length > 0 && (
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => setShowDeleteAll(true)} disabled={deletingAll}>
                  {deletingAll ? '🗑️ Deleting...' : '🗑️ Delete All'}
                </button>
              )}
            </div>

            <Toolbar sortField={sortField} setSortField={setSortField} sortDir={sortDir} setSortDir={setSortDir}
              typeFilter={typeFilter} setTypeFilter={setTypeFilter} industryFilter={industryFilter}
              setIndustryFilter={setIndustryFilter} allIndustries={allIndustries} />

            {loading ? <div style={S.emptyState}>Loading...</div> :
              filteredEntries.length === 0 ? <div style={S.emptyState}>{searchQ ? 'No matching entries.' : 'No entries yet. Add a person or company to get started.'}</div> :
                filteredEntries.map(e => (
                  <div key={e.id} style={S.card}
                    onMouseEnter={ev => (ev.currentTarget.style.boxShadow = '0 3px 10px rgba(0,0,0,.12)')}
                    onMouseLeave={ev => (ev.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,.08)')}
                    onClick={() => { setSelectedId(e.id); setView('detail'); }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                          {e.type === 'person' ? '👤' : '🏢'}
                        </span>
                        <strong>{getEntryName(e)}</strong>
                        {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: colors.textSec, marginTop: 6 }}>
                      {getPrimaryEmail(e) && <span>✉️ {getPrimaryEmail(e)}</span>}
                      {getPrimary(e.phones)?.number && <span>📞 {formatPhoneDisplay(getPrimary(e.phones)!.number)}</span>}
                      {getPrimary(e.addresses) && <span>📍 {formatAddr(getPrimary(e.addresses)!)}</span>}
                    </div>
                  </div>
                ))
            }
          </>
        )}

        {/* ── PERSON FORM ── */}
        {view === 'personForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{editId ? 'Edit Person' : 'Add Person'}</h2>
            <DuplicateWarningBanner duplicates={personDuplicates} onViewEntry={viewDuplicate} />
            <div style={S.formGrid}>
              <div><label style={S.label}>First Name *</label><input style={S.input} value={pFirst} onChange={e => setPFirst(e.target.value)} /></div>
              <div><label style={S.label}>Last Name *</label><input style={S.input} value={pLast} onChange={e => setPLast(e.target.value)} /></div>
            </div>

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Personal Information</div></div>
              <div>
                <label style={S.label}>Gender *</label>
                <select style={S.input} value={pGender} onChange={e => setPGender(e.target.value)}>
                  {GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}
                </select>
              </div>
              <div>
                <label style={S.label}>Birthday</label>
                <input style={S.input} type="date" value={pBirthday} onChange={e => setPBirthday(e.target.value)} />
              </div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={pEmails} onChange={setPEmails} labels={EMAIL_LABELS_PERSON} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Personal' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="email@example.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={pPhones} onChange={setPPhones} labels={PHONE_LABELS_PERSON} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Mobile' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={pAddrs} onChange={setPAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Relationships</div></div>
              <SpousePicker
                allPersons={allPersons}
                editId={editId}
                selectedSpouseId={pSpouseId}
                childIds={pChildIds}
                onSelect={sid => {
                  setPSpouseId(sid);
                  const spouse = allPersons.find(p => p.id === sid);
                  if (spouse) {
                    setPHouseholdId(spouse.householdId || pHouseholdId);
                    // Merge children from both persons
                    setPChildIds(prev => Array.from(new Set([...prev, ...spouse.childIds])));
                  }
                }}
                onClear={() => { setPSpouseId(''); setPAnniversary(''); }}
              />
              <div>
                <label style={S.label}>Wedding Anniversary</label>
                <input style={S.input} type="date" value={pAnniversary} onChange={e => setPAnniversary(e.target.value)} disabled={!pSpouseId} />
              </div>
              <RelationshipPicker label="Children" entries={allPersons.filter(p => {
                if (p.id === editId || p.id === pSpouseId) return false;
                // Already selected as a child of this person — always show so it can be removed
                if (pChildIds.includes(p.id)) return true;
                // Prevent cycles: cannot add an ancestor as a child
                const currentId = editId || '__new__';
                const ancestors = getAncestorIds(currentId, allPersons);
                if (ancestors.has(p.id)) return false;
                // Cannot add someone who is a descendant's ancestor through another path
                // (i.e., if adding p as child would create a cycle because p has currentId as descendant)
                const pDescendants = getDescendantIds(p.id, allPersons);
                if (pDescendants.has(currentId)) return false;
                // Count how many other parents already claim this person (excluding current editor & their spouse)
                const parentCount = allPersons.filter(
                  other => other.id !== editId && other.id !== pSpouseId && other.childIds.includes(p.id)
                ).length;
                return parentCount < 2;
              })}
                selectedIds={pChildIds} onToggle={id => setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <HouseholdPicker
                allPersons={allPersons}
                editId={editId}
                spouseId={pHouseholdExcludedIds.includes(pSpouseId) ? '' : pSpouseId}
                childIds={pChildIds.filter(id => !pHouseholdExcludedIds.includes(id))}
                extraMemberIds={pHouseholdExtraIds}
                onAddMember={id => { setPHouseholdExtraIds(prev => [...prev, id]); setPHouseholdExcludedIds(prev => prev.filter(x => x !== id)); }}
                onRemoveMember={id => setPHouseholdExtraIds(prev => prev.filter(x => x !== id))}
                onRemoveFromHousehold={id => setPHouseholdExcludedIds(prev => [...prev, id])}
              />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={pNotes} onChange={e => setPNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={savePerson}>Save Person</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { resetPersonForm(); setView('list'); }}>Cancel</button>
            </div>
          </>
        )}

        {/* ── COMPANY FORM ── */}
        {view === 'companyForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{editId ? 'Edit Company' : 'Add Company'}</h2>
            <DuplicateWarningBanner duplicates={companyDuplicates} onViewEntry={viewDuplicate} />
            <div style={S.formGrid}>
              <div><label style={S.label}>Company Name *</label><input style={S.input} value={cName} onChange={e => setCName(e.target.value)} /></div>
              <div><label style={S.label}>Industry</label><input style={S.input} value={cIndustry} onChange={e => setCIndustry(e.target.value)} /></div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={cEmails} onChange={setCEmails} labels={EMAIL_LABELS_COMPANY} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Main' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="contact@company.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={cPhones} onChange={setCPhones} labels={PHONE_LABELS_COMPANY} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Main' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={cAddrs} onChange={setCAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Contact Persons</div></div>
              <RelationshipPicker label="Contact Persons" entries={allPersons}
                selectedIds={cContactIds} onToggle={id => setCContactIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={cNotes} onChange={e => setCNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={saveCompany}>Save Company</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { resetCompanyForm(); setView('list'); }}>Cancel</button>
            </div>
          </>
        )}

        {/* ── DETAIL VIEW ── */}
        {view === 'detail' && selectedEntry && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('list'); setSelectedId(null); }}>← Back</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                if (selectedEntry.type === 'person') { fillPersonForm(selectedEntry); setView('personForm'); }
                else { fillCompanyForm(selectedEntry); setView('companyForm'); }
              }}>Edit</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => requestDelete(selectedEntry)}>Delete</button>
            </div>

            <div style={{ ...S.card, cursor: 'default' }}>
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
                <span style={{ fontSize: 36, marginRight: 14 }}>{selectedEntry.type === 'person' ? '👤' : '🏢'}</span>
                <div>
                  <h2 style={{ margin: 0 }}>{getEntryName(selectedEntry)}</h2>
                  <span style={{ ...S.badge, marginTop: 4, background: selectedEntry.type === 'person' ? '#e8f0fe' : '#fce8e6', color: selectedEntry.type === 'person' ? colors.primary : colors.danger }}>
                    {selectedEntry.type}
                  </span>
                  {selectedEntry.type === 'company' && selectedEntry.industry && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{selectedEntry.industry}</span>}
                </div>
              </div>

              {selectedEntry.type === 'person' && (selectedEntry.gender || selectedEntry.birthday) && (
                <>
                  <div style={S.section}>Personal Information</div>
                  {selectedEntry.gender && <div style={S.detailRow}><span style={S.detailLabel}>Gender</span><span>{selectedEntry.gender}</span></div>}
                  {selectedEntry.birthday && <div style={S.detailRow}><span style={S.detailLabel}>Birthday</span><span>{selectedEntry.birthday}{calculateAge(selectedEntry.birthday) !== null && ` (Age ${calculateAge(selectedEntry.birthday)})`}</span></div>}
                </>
              )}

              <div style={S.section}>Email Addresses</div>
              {selectedEntry.emails.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.emails.map((em, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{em.label}</span>
                    <span>{em.address}</span>
                    {em.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))}

              <div style={S.section}>Phone Numbers</div>
              {selectedEntry.phones.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.phones.map((ph, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{ph.label}</span>
                    <span>{formatPhoneDisplay(ph.number)}</span>
                    {ph.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))}

              <div style={S.section}>Addresses</div>
              {selectedEntry.addresses.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.addresses.map((addr, i) => (
                  <div key={i} style={{ padding: '8px 12px', marginBottom: 6, borderRadius: 6, border: `1px solid ${colors.border}`, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                      <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{addr.label}</span>
                      {addr.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                    </div>
                    <div style={{ fontSize: 14 }}>{formatAddr(addr)}</div>
                  </div>
                ))}

              {selectedEntry.type === 'person' && (
                <>
                  <div style={S.section}>Relationships</div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Spouse</span>
                    <span>{selectedEntry.spouseId ? (
                      <span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(selectedEntry.spouseId)}>{resolveName(selectedEntry.spouseId)}</span>
                    ) : '—'}</span>
                  </div>
                  {selectedEntry.weddingAnniversary && (
                    <div style={S.detailRow}>
                      <span style={S.detailLabel}>Anniversary</span>
                      <span>💍 {selectedEntry.weddingAnniversary}</span>
                    </div>
                  )}
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Children</span>
                    <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.childIds.length === 0 ? '—' : selectedEntry.childIds.map(cid => (
                        <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>
                      ))}
                    </span>
                  </div>
                  {(() => {
                    const housemates = allPersons.filter(p => p.householdId === selectedEntry.householdId && p.id !== selectedEntry.id);
                    return (
                      <>
                        <div style={S.section}>Household Members</div>
                        <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>Members share the same primary address.</span>
                        {housemates.length === 0
                          ? <div style={{ fontSize: 14, color: colors.textSec }}>No other household members.</div>
                          : <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                              {housemates.map(p => {
                                const isSpouse = p.id === selectedEntry.spouseId;
                                const isChild = selectedEntry.childIds.includes(p.id);
                                const role = isSpouse ? 'spouse' : isChild ? 'child' : '';
                                return (
                                  <span key={p.id} style={{ ...S.chip, cursor: 'pointer', background: (isSpouse || isChild) ? '#e8f5e9' : colors.accent }} onClick={() => setSelectedId(p.id)}>
                                    {p.firstName} {p.lastName}
                                    {role && <span style={{ fontSize: 10, color: colors.textSec, marginLeft: 2 }}>({role})</span>}
                                  </span>
                                );
                              })}
                            </div>
                        }
                      </>
                    );
                  })()}
                </>
              )}

              {selectedEntry.type === 'company' && (
                <>
                  <div style={S.section}>Contact Persons</div>
                  {selectedEntry.contactPersonIds.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                    <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.contactPersonIds.map(pid => (
                        <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>{resolveName(pid)}</span>
                      ))}
                    </div>}
                </>
              )}

              {selectedEntry.notes && (
                <>
                  <div style={S.section}>Notes</div>
                  <div style={{ fontSize: 14, whiteSpace: 'pre-wrap' }}>{selectedEntry.notes}</div>
                </>
              )}
            </div>
          </>
        )}

        {/* ── IMPORT PREVIEW ── */}
        {view === 'import' && (
          <>
            <h2 style={{ marginBottom: 8 }}>📤 Import Preview</h2>
            <p style={{ fontSize: 13, color: colors.textSec, marginBottom: 16 }}>
              File: <strong>{importFileName}</strong> — {importPreview.length} entr{importPreview.length === 1 ? 'y' : 'ies'} found.
            </p>
            {importPreview.length === 0 ? <div style={S.emptyState}>No valid entries found in the CSV file.</div> : (
              <div style={{ overflowX: 'auto', marginBottom: 16 }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                  <thead>
                    <tr style={{ background: colors.accent }}>
                      {['#', 'Type', 'Name', 'Primary Email', 'Primary Phone', 'City/State'].map(h => (
                        <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {importPreview.map((e, i) => (
                      <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                        <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                        <td style={{ padding: '8px 12px' }}>
                          <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                            {e.type === 'person' ? '👤' : '🏢'}
                          </span>
                        </td>
                        <td style={{ padding: '8px 12px', fontWeight: 600 }}>{getEntryName(e)}</td>
                        <td style={{ padding: '8px 12px' }}>{getPrimary(e.emails)?.address || '—'}</td>
                        <td style={{ padding: '8px 12px' }}>{getPrimary(e.phones)?.number ? formatPhoneDisplay(getPrimary(e.phones)!.number) : '—'}</td>
                        <td style={{ padding: '8px 12px' }}>
                          {(() => { const a = getPrimary(e.addresses); return a ? [a.city, a.state].filter(Boolean).join(', ') || '—' : '—'; })()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            <div style={{ ...S.btnRow, marginTop: 8 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleImportConfirm} disabled={importing || importPreview.length === 0}>
                {importing ? 'Importing...' : `✅ Import ${importPreview.length} Entr${importPreview.length === 1 ? 'y' : 'ies'}`}
              </button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleImportCancel} disabled={importing}>Cancel</button>
            </div>
          </>
        )}
      </div>

      {/* ── DELETE CONFIRMATION ── */}
      {deleteTarget && (() => {
        const cascadeEffects: string[] = [];
        if (deleteTarget.type === 'person') {
          if (deleteTarget.spouseId) cascadeEffects.push(`Unlink spouse ${resolveName(deleteTarget.spouseId)}`);
          const parents = allPersons.filter(p => p.id !== deleteTarget.id && p.childIds.includes(deleteTarget.id));
          if (parents.length > 0) cascadeEffects.push(`Remove as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
          const linkedCompanies = entries.filter(e => e.type === 'company' && e.contactPersonIds.includes(deleteTarget.id));
          if (linkedCompanies.length > 0) cascadeEffects.push(`Remove as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
        }
        return (
          <div style={S.overlay} onClick={cancelDelete}>
            <div style={S.dialog} onClick={e => e.stopPropagation()}>
              <h3 style={S.dialogTitle}>🗑️ Delete {deleteTarget.type === 'person' ? 'Person' : 'Company'}</h3>
              <div style={S.dialogBody}>
                Are you sure you want to delete <strong>{getEntryName(deleteTarget)}</strong>?
                {cascadeEffects.length > 0 && (
                  <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>
                    {cascadeEffects.map((eff, i) => <li key={i}>{eff}</li>)}
                  </ul>
                )}
                {' '}This action cannot be undone.
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={cancelDelete}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmDelete}>Delete</button>
              </div>
            </div>
          </div>
        );
      })()}
      {/* ── DELETE ALL CONFIRMATION ── */}
      {showDeleteAll && (
        <div style={S.overlay} onClick={() => setShowDeleteAll(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete All Entries</h3>
            <div style={S.dialogBody}>
              Are you sure you want to delete <strong>all {entries.length} entr{entries.length === 1 ? 'y' : 'ies'}</strong>? This action cannot be undone.
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowDeleteAll(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={handleDeleteAll}>Delete All</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default App;

