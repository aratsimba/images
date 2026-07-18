import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';

import type {
  DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address,
  View, SortField, SortDir, TypeFilter,
} from './types';
import { EMPTY_ADDR, EMPTY_PHONE, EMPTY_EMAIL, EMAIL_LABELS, PHONE_LABELS } from './types';
import { S, colors } from './styles';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, getEntryName, formatAddr } from './utils';
import { saveEntry, loadEntry, loadAll, removeEntry, exportCsv, parseCsvFile } from './storage';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { RelationshipPicker } from './components/RelationshipPicker';
import { findDuplicates, DuplicateWarningBanner } from './components/DuplicateWarning';
import { Toolbar } from './components/Toolbar';

import appSource from './App.tsx?raw';

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
  const [pEmails, setPEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [pPhones, setPPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [pAddrs, setPAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [pSpouseId, setPSpouseId] = useState('');
  const [pChildIds, setPChildIds] = useState<string[]>([]);
  const [pHouseholdId, setPHouseholdId] = useState('');
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
    setPFirst(''); setPLast('');
    setPEmails([{ ...EMPTY_EMAIL }]); setPPhones([{ ...EMPTY_PHONE }]); setPAddrs([{ ...EMPTY_ADDR }]);
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(uuidv4()); setPNotes(''); setEditId(null);
  };

  const resetCompanyForm = () => {
    setCName(''); setCIndustry('');
    setCEmails([{ ...EMPTY_EMAIL }]); setCPhones([{ ...EMPTY_PHONE }]); setCAddrs([{ ...EMPTY_ADDR }]);
    setCContactIds([]); setCNotes(''); setEditId(null);
  };

  const fillPersonForm = (p: Person) => {
    setPFirst(p.firstName); setPLast(p.lastName);
    setPEmails(p.emails.length ? [...p.emails] : [{ ...EMPTY_EMAIL }]);
    setPPhones(p.phones.length ? [...p.phones] : [{ ...EMPTY_PHONE }]);
    setPAddrs(p.addresses.length ? [...p.addresses] : [{ ...EMPTY_ADDR }]);
    setPSpouseId(p.spouseId); setPChildIds([...p.childIds]);
    setPHouseholdId(p.householdId); setPNotes(p.notes); setEditId(p.id);
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
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId, notes: pNotes.trim(),
    };
    try {
      await saveEntry(person);
      const primaryAddr = getPrimary(finalAddrs);
      if (primaryAddr) {
        const householdMembers = allPersons.filter(p => p.id !== id && p.householdId === person.householdId);
        for (const m of householdMembers) {
          const mAddrs = [...m.addresses];
          const pIdx = mAddrs.findIndex(a => a.isPrimary);
          if (pIdx >= 0) mAddrs[pIdx] = { ...primaryAddr, label: mAddrs[pIdx].label };
          else mAddrs.unshift({ ...primaryAddr });
          await saveEntry({ ...m, addresses: mAddrs });
        }
      }
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person' && spouse.spouseId !== id)
          await saveEntry({ ...spouse, spouseId: id, householdId: person.householdId });
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
  const handleDelete = async (id: string) => {
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person' && entry.spouseId) {
        const spouse = await loadEntry(entry.spouseId);
        if (spouse && spouse.type === 'person') await saveEntry({ ...spouse, spouseId: '' });
      }
      await removeEntry(id); await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
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
    try { await downloadFile('App.tsx', new Blob([appSource], { type: 'text/plain' })); }
    catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  const handleDownloadMarkdown = async () => {
    const md = `# 📒 Directory Application — Conversation Log\n\nThis file documents the features and history of this directory app.\nSee the source code for full implementation details.\n`;
    try { await downloadFile('directory-app-conversation.md', new Blob([md], { type: 'text/markdown' })); }
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
                        <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>{e.type}</span>
                        <strong>{getEntryName(e)}</strong>
                        {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                      </div>
                      <span style={{ fontSize: 13, color: colors.textSec }}>{getPrimaryEmail(e)}</span>
                    </div>
                    <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>{getPrimaryAddr(e)}</div>
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

            <MultiItemField<EmailEntry> title="Email Addresses" items={pEmails} onChange={setPEmails} labels={EMAIL_LABELS} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Personal' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="email@example.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={pPhones} onChange={setPPhones} labels={PHONE_LABELS} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Mobile' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={pAddrs} onChange={setPAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Relationships</div></div>
              <div style={S.fieldFull}>
                <label style={S.label}>Spouse</label>
                <select style={{ ...S.input, background: '#fff' }} value={pSpouseId} onChange={e => {
                  const sid = e.target.value; setPSpouseId(sid);
                  if (sid) { const spouse = allPersons.find(p => p.id === sid); if (spouse) setPHouseholdId(spouse.householdId || pHouseholdId); }
                }}>
                  <option value="">— None —</option>
                  {allPersons.filter(p => p.id !== editId).map(p => <option key={p.id} value={p.id}>{p.firstName} {p.lastName}</option>)}
                </select>
              </div>
              <RelationshipPicker label="Children" entries={allPersons.filter(p => p.id !== editId)}
                selectedIds={pChildIds} onToggle={id => setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <div style={S.fieldFull}>
                <label style={S.label}>Household ID</label>
                <input style={{ ...S.input, background: '#f8f9fa' }} value={pHouseholdId} readOnly />
                <span style={{ fontSize: 11, color: colors.textSec }}>Members of the same household share the primary address.</span>
              </div>
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

            <MultiItemField<EmailEntry> title="Email Addresses" items={cEmails} onChange={setCEmails} labels={EMAIL_LABELS} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Work' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="contact@company.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={cPhones} onChange={setCPhones} labels={PHONE_LABELS} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Work' })}
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
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => handleDelete(selectedEntry.id)}>Delete</button>
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
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Children</span>
                    <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.childIds.length === 0 ? '—' : selectedEntry.childIds.map(cid => (
                        <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>
                      ))}
                    </span>
                  </div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Household</span>
                    <span style={{ fontSize: 12, color: colors.textSec }}>{selectedEntry.householdId}</span>
                  </div>
                  {(() => {
                    const housemates = allPersons.filter(p => p.householdId === selectedEntry.householdId && p.id !== selectedEntry.id);
                    if (housemates.length === 0) return null;
                    return (
                      <>
                        <div style={S.section}>Household Members (shared primary address)</div>
                        <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                          {housemates.map(p => (
                            <span key={p.id} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(p.id)}>{p.firstName} {p.lastName}</span>
                          ))}
                        </div>
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
    </div>
  );
};

export default App;
