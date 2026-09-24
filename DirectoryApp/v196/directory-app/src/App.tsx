import React, { useState, useEffect, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';

import type { DirectoryEntry, Person, Company, View, SortField, SortDir, TypeFilter, Household, StatusFilter } from './types';
import { EMAIL_LABELS_PERSON, EMAIL_LABELS_COMPANY, PHONE_LABELS_PERSON, PHONE_LABELS_COMPANY, GENDER_OPTIONS } from './types';
import { S, colors } from './styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr, getAncestorIds, getDescendantIds, capitalizeName } from './utils';
import { exportFullCsv, parseCsvFile, saveEntry, saveHousehold, saveImage } from './storage';

import { useDirectoryData, useFilteredEntries } from './hooks/useDirectoryData';
import { useDirectoryActions } from './hooks/useDirectoryActions';
import { usePersonForm } from './hooks/usePersonForm';
import { useCompanyForm } from './hooks/useCompanyForm';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { RelationshipPicker } from './components/RelationshipPicker';
import { SpousePicker } from './components/SpousePicker';
import { HouseholdMembership } from './components/HouseholdPicker';
import { HouseholdView } from './components/HouseholdView';
import { DuplicateWarningBanner } from './components/DuplicateWarning';
import { FilterBar } from './components/FilterBar';
import { EmailInput } from './components/EmailInput';
import { PhoneInput } from './components/PhoneInput';
import { ProfileImage } from './components/ProfileImage';
import { useCollapsedSections } from './components/CollapsibleSection';
import { BulkActionsBar } from './components/BulkActions';
import { PrintDialog } from './components/PrintDirectory';
import { DeleteDialog, DeleteAllDialog } from './components/DeleteDialogs';
import { DetailView } from './views/DetailView';
import { ImportView } from './views/ImportView';
import { ToastProvider, useToast } from './components/Toast';
import { QuickAddRelativeDialog } from './components/QuickAddRelative';
import { QuickAddCompanyDialog } from './components/QuickAddCompany';
import { ContactPersonSearch } from './components/ContactPersonSearch';
import { AffiliationEditor } from './components/AffiliationEditor';

import appSource from './App.tsx?raw';
import devLog from './DEVLOG.md?raw';
import typesSource from './types.ts?raw';
import stylesSource from './styles.ts?raw';
import utilsSource from './utils.ts?raw';
import storageSource from './storage.ts?raw';
import countryCodesSource from './countryCodes.ts?raw';
import mainSource from './main.tsx?raw';
import viteEnvSource from './vite-env.d.ts?raw';
import addressFieldsSource from './components/AddressFields.tsx?raw';
import multiItemFieldSource from './components/MultiItemField.tsx?raw';
import countryCodeSelectSource from './components/CountryCodeSelect.tsx?raw';
import relationshipPickerSource from './components/RelationshipPicker.tsx?raw';
import spousePickerSource from './components/SpousePicker.tsx?raw';
import householdPickerSource from './components/HouseholdPicker.tsx?raw';
import householdViewSource from './components/HouseholdView.tsx?raw';
import duplicateWarningSource from './components/DuplicateWarning.tsx?raw';
import filterBarSource from './components/FilterBar.tsx?raw';
import phoneInputSource from './components/PhoneInput.tsx?raw';
import profileImageSource from './components/ProfileImage.tsx?raw';
import imageCropperSource from './components/ImageCropper.tsx?raw';
import familyTreeSource from './components/FamilyTree.tsx?raw';
import collapsibleSectionSource from './components/CollapsibleSection.tsx?raw';
import vcardExportSource from './components/VCardExport.tsx?raw';
import bulkActionsSource from './components/BulkActions.tsx?raw';
import printDirectorySource from './components/PrintDirectory.tsx?raw';
import deleteDialogsSource from './components/DeleteDialogs.tsx?raw';
import detailViewSource from './views/DetailView.tsx?raw';
import importViewSource from './views/ImportView.tsx?raw';
import useDirectoryDataSource from './hooks/useDirectoryData.ts?raw';
import useDirectoryActionsSource from './hooks/useDirectoryActions.ts?raw';
import usePersonFormSource from './hooks/usePersonForm.ts?raw';
import useCompanyFormSource from './hooks/useCompanyForm.ts?raw';
import emailInputSource from './components/EmailInput.tsx?raw';
import toastSource from './components/Toast.tsx?raw';
import quickAddRelativeSource from './components/QuickAddRelative.tsx?raw';
import companyPickerSource from './components/CompanyPicker.tsx?raw';
import quickAddCompanySource from './components/QuickAddCompany.tsx?raw';

// ─── Main App ────────────────────────────────────────────────────────

const AppInner = () => {
  const { addToast } = useToast();
  const [view, setView] = useState<View>('list');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [searchQ, setSearchQ] = useState('');
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all');
  const [industryFilter, setIndustryFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('active');
  const [missionaryFilter, setMissionaryFilter] = useState(false);
  const [companyFilter, setCompanyFilter] = useState('');
  const [pageSize, setPageSize] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [deleteTarget, setDeleteTarget] = useState<DirectoryEntry | null>(null);
  const [showDeleteAll, setShowDeleteAll] = useState(false);
  const [deletingAll, setDeletingAll] = useState(false);
  const [showPrintDialog, setShowPrintDialog] = useState(false);
  const [quickAddMode, setQuickAddMode] = useState<'spouse' | 'child' | null>(null);
  const [quickAddInitialName, setQuickAddInitialName] = useState('');
  const [editingPendingId, setEditingPendingId] = useState<string | null>(null);
  const [quickAddCompanyOpen, setQuickAddCompanyOpen] = useState(false);
  const [quickAddCompanyInitName, setQuickAddCompanyInitName] = useState('');
  const [editingPendingCompanyId, setEditingPendingCompanyId] = useState<string | null>(null);
  const [importPreview, setImportPreview] = useState<DirectoryEntry[]>([]);
  const [importHouseholdsPreview, setImportHouseholdsPreview] = useState<Household[]>([]);
  const [importImageIdMap, setImportImageIdMap] = useState<Record<string, string>>({});
  const [importFileName, setImportFileName] = useState('');
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);

  const data = useDirectoryData();
  const { entries, households, images, loading, error, setError, reload, allPersons, allIndustries, allAffiliatedCompanies } = data;
  const allCompanies = useMemo(() => entries.filter((e): e is Company => e.type === 'company'), [entries]);
  const { collapsed: collapsedSections, toggle: toggleSection } = useCollapsedSections();
  const { searchResults, filteredEntries } = useFilteredEntries(entries, searchQ, typeFilter, industryFilter, statusFilter, sortField, sortDir, missionaryFilter, companyFilter);

  const actions = useDirectoryActions({
    entries, allPersons, households, images, reload, setError,
    selectedId, setSelectedId, setView, setSelectMode, setSelectedIds,
    setDeletingAll, setShowDeleteAll, setDeleteTarget, deleteTarget,
  });

  const personForm = usePersonForm({ entries, allPersons, households, images, reload, setError, setView });
  const companyForm = useCompanyForm({ entries, allPersons, images, reload, setError, setView });

  useEffect(() => { setCurrentPage(1); }, [searchQ, typeFilter, industryFilter, statusFilter, sortField, sortDir, missionaryFilter, companyFilter]);
  useEffect(() => {
    const h = (ev: MouseEvent) => { if (searchRef.current && !searchRef.current.contains(ev.target as Node)) setShowSearchDropdown(false); };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const totalEntries = filteredEntries.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStart = (safeCurrentPage - 1) * pageSize;
  const pageEnd = Math.min(pageStart + pageSize, totalEntries);
  const paginatedEntries = filteredEntries.slice(pageStart, pageEnd);

  const selectedEntry = entries.find(e => e.id === selectedId);
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };

  // ── CSV / Import ──
  const handleExportCsv = async () => {
    if (entries.length === 0 && households.length === 0) { setError('No entries to export.'); return; }
    try {
      await downloadFile('directory-export.csv', new Blob([exportFullCsv(entries, households, images)], { type: 'text/csv' }));
      if (Object.keys(images).length > 0) await downloadFile('directory-images.json', new Blob([JSON.stringify(images, null, 2)], { type: 'application/json' }));
      addToast('📥 CSV exported successfully');
    } catch (e: any) { setError(e?.message || 'Export failed'); }
  };

  const handleFileSelect = async (file: File) => {
    setError(''); setImportFileName(file.name);
    if (file.name.endsWith('.json')) {
      try {
        const parsed = JSON.parse(await file.text()) as Record<string, string>;
        const count = Object.keys(parsed).length;
        if (count === 0) { setError('No images found in the JSON file.'); return; }
        for (const [id, dataUrl] of Object.entries(parsed)) { if (typeof dataUrl === 'string' && dataUrl.startsWith('data:image/')) await saveImage(id, dataUrl); }
        await reload();
        addToast(`✅ Successfully imported ${count} profile image${count === 1 ? '' : 's'}`);
      } catch (e) { if (e instanceof PageStorageError) setError(e.message); else setError('Failed to parse images JSON file.'); }
      return;
    }
    const { entries: parsed, households: parsedHH, imageIdMap, errors } = await parseCsvFile(file);
    if (errors.length > 0) setError(errors.slice(0, 5).join('. ') + (errors.length > 5 ? ` ...and ${errors.length - 5} more.` : ''));
    setImportPreview(parsed); setImportHouseholdsPreview(parsedHH); setImportImageIdMap(imageIdMap); setView('import');
  };

  const handleImportConfirm = async () => {
    if (importPreview.length === 0 && importHouseholdsPreview.length === 0) return;
    setImporting(true); setError('');
    try {
      let saved = 0;
      for (const entry of importPreview) { await saveEntry(entry); const oid = importImageIdMap[entry.id]; if (oid && images[oid] && oid !== entry.id) await saveImage(entry.id, images[oid]); saved++; }
      for (const hh of importHouseholdsPreview) { await saveHousehold(hh); const oid = importImageIdMap[hh.id]; if (oid && images[oid] && oid !== hh.id) await saveImage(hh.id, images[oid]); saved++; }
      await reload(); setImportPreview([]); setImportHouseholdsPreview([]); setImportImageIdMap({}); setImportFileName(''); setView('list');
      addToast(`✅ Successfully imported ${saved} record${saved === 1 ? '' : 's'}`);
    } catch (e) { if (e instanceof PageStorageError) setError(e.message); }
    finally { setImporting(false); }
  };
  const handleImportCancel = () => { setImportPreview([]); setImportHouseholdsPreview([]); setImportImageIdMap({}); setImportFileName(''); setView('list'); };

  // ── Code / Log export ──
  const handleDownloadMarkdown = async () => { try { await downloadFile('directory-app-conversation.md', new Blob([devLog], { type: 'text/markdown' })); addToast('📄 Conversation log exported'); } catch (e: any) { setError(e?.message || 'Download failed'); } };
  const handleDownloadCode = async () => {
    const pkgJson = JSON.stringify({ name: "directory-app", version: "0.1.0", private: true, type: "module", dependencies: { "papaparse": "^5.5.3", "react": "^18.2.0", "react-dom": "^18.2.0", "uuid": "^11.1.0" }, devDependencies: { "@types/papaparse": "^5.3.15", "@types/react": "^18.2.0", "@types/react-dom": "^18.2.25", "@types/uuid": "^10.0.0", "@vitejs/plugin-react": "^4.3.4", "typescript": "^5.1.6", "vite": "^6.4.1", "vite-tsconfig-paths": "^4.2.0" }, scripts: { dev: "vite", build: "tsc && vite build", preview: "vite preview" } }, null, 2);
    const tsJson = JSON.stringify({ compilerOptions: { target: "esnext", useDefineForClassFields: true, lib: ["DOM", "DOM.Iterable", "ESNext"], allowJs: false, skipLibCheck: true, esModuleInterop: false, allowSyntheticDefaultImports: true, strict: false, forceConsistentCasingInFileNames: true, module: "ESNext", moduleResolution: "Node", resolveJsonModule: true, isolatedModules: true, strictNullChecks: true, noEmit: true, jsx: "react-jsx", paths: { "@root/*": ["./src/*"] } }, include: ["src"] }, null, 2);
    const viteCfg = `import react from '@vitejs/plugin-react';\nimport { defineConfig } from 'vite';\nimport tsconfigPaths from 'vite-tsconfig-paths';\n\nexport default defineConfig({ plugins: [react(), tsconfigPaths()] });\n`;
    const indexHtml = `<!DOCTYPE html>\n<html lang="en"><head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Directory App</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>\n`;
    const readme = `# Directory App\n\nA personal/church directory application built with React + TypeScript + Vite.\n\n## Getting Started\n\n\`\`\`bash\nnpm install\nnpm run dev\n\`\`\`\n\n## Notes\n\n- This export is a standalone version. Replace \`@amzn/quick-pages-runtime-lib\` storage calls with your own backend.\n`;
    const files: [string, string][] = [
      ['package.json', pkgJson], ['tsconfig.json', tsJson], ['vite.config.ts', viteCfg], ['index.html', indexHtml], ['README.md', readme],
      ['src/main.tsx', mainSource], ['src/vite-env.d.ts', viteEnvSource], ['src/types.ts', typesSource], ['src/styles.ts', stylesSource], ['src/utils.ts', utilsSource], ['src/storage.ts', storageSource], ['src/countryCodes.ts', countryCodesSource], ['src/App.tsx', appSource],
      ['src/hooks/useDirectoryData.ts', useDirectoryDataSource], ['src/hooks/useDirectoryActions.ts', useDirectoryActionsSource], ['src/hooks/usePersonForm.ts', usePersonFormSource], ['src/hooks/useCompanyForm.ts', useCompanyFormSource],
      ['src/views/DetailView.tsx', detailViewSource], ['src/views/ImportView.tsx', importViewSource],
      ['src/components/AddressFields.tsx', addressFieldsSource], ['src/components/MultiItemField.tsx', multiItemFieldSource], ['src/components/CountryCodeSelect.tsx', countryCodeSelectSource], ['src/components/RelationshipPicker.tsx', relationshipPickerSource], ['src/components/SpousePicker.tsx', spousePickerSource], ['src/components/HouseholdPicker.tsx', householdPickerSource], ['src/components/HouseholdView.tsx', householdViewSource], ['src/components/DuplicateWarning.tsx', duplicateWarningSource], ['src/components/FilterBar.tsx', filterBarSource], ['src/components/EmailInput.tsx', emailInputSource], ['src/components/PhoneInput.tsx', phoneInputSource], ['src/components/ProfileImage.tsx', profileImageSource], ['src/components/ImageCropper.tsx', imageCropperSource], ['src/components/FamilyTree.tsx', familyTreeSource], ['src/components/CollapsibleSection.tsx', collapsibleSectionSource], ['src/components/VCardExport.tsx', vcardExportSource], ['src/components/BulkActions.tsx', bulkActionsSource], ['src/components/PrintDirectory.tsx', printDirectorySource], ['src/components/DeleteDialogs.tsx', deleteDialogsSource], ['src/components/Toast.tsx', toastSource], ['src/components/QuickAddRelative.tsx', quickAddRelativeSource], ['src/components/CompanyPicker.tsx', companyPickerSource], ['src/components/QuickAddCompany.tsx', quickAddCompanySource],
      ['DEVLOG.md', devLog],
    ];
    const lines = ['#!/usr/bin/env bash', '# Directory App — Self-Extracting Source Code', 'set -e', 'ROOT="directory-app"', 'mkdir -p "$ROOT/src/components" "$ROOT/src/hooks" "$ROOT/src/views"', 'echo "Extracting files into $ROOT/ ..."', ''];
    for (const [path, content] of files) { const d = `__EOF_${path.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}__`; lines.push(`cat > "$ROOT/${path}" << '${d}'`, content, d, ''); }
    lines.push(`echo "✅ Done! Extracted ${files.length} files into $ROOT/"`, 'echo "To get started: cd $ROOT && npm install && npm run dev"');
    try { await downloadFile('directory-app.sh', new Blob([lines.join('\n')], { type: 'text/x-shellscript' })); addToast('💾 Source code exported'); } catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  // ── Render ──
  return (
    <div style={S.app}>
      {/* Header */}
      <div style={S.header}>
        <h1 style={S.headerTitle} onClick={() => { setView('list'); setSelectedId(null); setSearchQ(''); }}>📒 Directory</h1>
        <div style={S.searchWrap} ref={searchRef}>
          <input style={{ ...S.searchInput, paddingRight: searchQ ? 32 : 12 }} placeholder="Search persons & companies..." value={searchQ} onChange={e => { setSearchQ(e.target.value); setShowSearchDropdown(true); }} onFocus={() => setShowSearchDropdown(true)} />
          {searchQ && (
            <button onClick={() => { setSearchQ(''); setShowSearchDropdown(false); }} title="Clear search" style={{ position: 'absolute', right: 6, top: '50%', transform: 'translateY(-50%)', border: 'none', background: 'rgba(0,0,0,0.15)', color: '#fff', borderRadius: '50%', width: 20, height: 20, fontSize: 13, lineHeight: 1, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0 }}>×</button>
          )}
          {showSearchDropdown && searchQ && (
            <div style={S.dropdown}>
              {searchResults.length === 0 && <div style={{ padding: 14, color: colors.textSec }}>No results</div>}
              {searchResults.slice(0, 10).map(e => (
                <div key={e.id} style={{ ...S.dropdownItem, display: 'flex', alignItems: 'center', gap: 8 }} onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)} onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')} onClick={() => { setSearchQ(getEntryName(e)); setShowSearchDropdown(false); setSelectedId(e.id); setView('detail'); }}>
                  <ProfileImage imageUrl={images[e.id] || null} size={24} fallback={e.type === 'person' ? '👤' : '🏢'} />
                  {getEntryName(e)}{e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({e.industry})</span>}
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
        {error && <div ref={errorRef} style={S.error}>{error}</div>}

        {/* ── LIST VIEW ── */}
        {view === 'list' && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { personForm.reset(); setView('personForm'); }}>+ Add Person</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { companyForm.reset(); setView('companyForm'); }}>+ Add Company</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('households'); }}>🏠 Households</button>
              <button style={{ ...S.btn, ...(selectMode ? { background: colors.primary, color: '#fff' } : S.btnSec) }} onClick={() => { setSelectMode(!selectMode); if (selectMode) setSelectedIds(new Set()); }}>{selectMode ? '✓ Selecting' : '☐ Select'}</button>
              <div style={{ flex: 1 }} />
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleExportCsv}>📥 Export CSV</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowPrintDialog(true)}>🖨️ Print</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => fileInputRef.current?.click()}>📤 Import CSV</button>
              <input ref={fileInputRef} type="file" accept=".csv,.json" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) handleFileSelect(f); e.target.value = ''; }} />
              {entries.length > 0 && <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => setShowDeleteAll(true)} disabled={deletingAll}>{deletingAll ? '🗑️ Deleting...' : '🗑️ Delete All'}</button>}
            </div>
            <FilterBar sortField={sortField} setSortField={setSortField} sortDir={sortDir} setSortDir={setSortDir} typeFilter={typeFilter} setTypeFilter={setTypeFilter} industryFilter={industryFilter} setIndustryFilter={setIndustryFilter} allIndustries={allIndustries} statusFilter={statusFilter} setStatusFilter={setStatusFilter} missionaryFilter={missionaryFilter} setMissionaryFilter={setMissionaryFilter} companyFilter={companyFilter} setCompanyFilter={setCompanyFilter} allAffiliatedCompanies={allAffiliatedCompanies} totalCount={filteredEntries.length} />
            {loading ? <div style={S.emptyState}>Loading...</div> : filteredEntries.length === 0 ? <div style={S.emptyState}>{searchQ ? 'No matching entries.' : 'No entries yet. Add a person or company to get started.'}</div> : (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, fontSize: 13, color: colors.textSec }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    {selectMode && <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><button onClick={() => setSelectedIds(new Set(filteredEntries.map(e => e.id)))} style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }}>All</button><button onClick={() => setSelectedIds(new Set())} style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }}>None</button></div>}
                    <span>Showing {pageStart + 1}–{pageEnd} of {totalEntries} entr{totalEntries === 1 ? 'y' : 'ies'}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span>Per page:</span>{[25, 50, 100].map(size => <button key={size} onClick={() => { setPageSize(size); setCurrentPage(1); }} style={{ ...S.btn, padding: '3px 10px', fontSize: 12, background: pageSize === size ? colors.primary : 'transparent', color: pageSize === size ? '#fff' : colors.text, border: `1px solid ${pageSize === size ? colors.primary : colors.border}`, borderRadius: 4 }}>{size}</button>)}</div>
                </div>
                {paginatedEntries.map(e => {
                  const isInactive = e.type === 'person' ? e.status === 'deceased' : e.companyStatus === 'closed';
                  const isSelected = selectedIds.has(e.id);
                  return (
                    <div key={e.id} style={{ ...S.card, ...(isInactive ? { opacity: 0.7, borderLeft: '4px solid #9e9e9e' } : {}), ...(isSelected ? { border: `2px solid ${colors.primary}`, background: '#f0f7ff' } : {}) }} onMouseEnter={ev => (ev.currentTarget.style.boxShadow = '0 3px 10px rgba(0,0,0,.12)')} onMouseLeave={ev => (ev.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,.08)')} onClick={() => { if (selectMode) { setSelectedIds(prev => { const n = new Set(prev); if (n.has(e.id)) n.delete(e.id); else n.add(e.id); return n; }); } else { setSelectedId(e.id); setView('detail'); } }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          {selectMode && <div style={{ width: 20, height: 20, borderRadius: 4, border: `2px solid ${isSelected ? colors.primary : colors.border}`, background: isSelected ? colors.primary : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{isSelected && <span style={{ color: '#fff', fontSize: 13, fontWeight: 700, lineHeight: 1 }}>✓</span>}</div>}
                          <ProfileImage imageUrl={images[e.id] || null} size={36} fallback={e.type === 'person' ? '👤' : '🏢'} />
                          <strong style={isInactive ? { color: colors.textSec } : {}}>{getEntryName(e)}</strong>
                          {isInactive && <span style={{ ...S.badge, background: '#e0e0e0', color: '#616161', fontSize: 10 }}>{e.type === 'person' ? '✝ DECEASED' : '🚫 CLOSED'}</span>}
                          {e.type === 'person' && e.isMissionary && <span style={{ ...S.badge, background: '#f3e5f5', color: '#7b1fa2', fontSize: 10 }}>✝ MISSIONARY</span>}
                          {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                        </div>
                        {e.type === 'person' && (
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: colors.textSec }}>
                            {e.spouseId && <span title={`Spouse: ${resolveName(e.spouseId)}`}>💍</span>}
                            {e.childIds.length > 0 && <span title={`${e.childIds.length} child${e.childIds.length > 1 ? 'ren' : ''}`}>🧒 {e.childIds.length}</span>}
                            {(() => { const hh = households.find(h => h.memberIds.includes(e.id)); return hh ? <span title={hh.name}>🏠</span> : null; })()}
                          </div>
                        )}
                      </div>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: colors.textSec, marginTop: 6 }}>
                        {getPrimary(e.emails)?.address && <span>✉️ {getPrimary(e.emails)!.address}</span>}
                        {getPrimary(e.phones)?.number && <span>📞 {(getPrimary(e.phones)!.countryCode || '+1')} {formatPhoneDisplay(getPrimary(e.phones)!.number)}</span>}
                        {e.type === 'company' && e.website && <span onClick={ev => ev.stopPropagation()}><a href={e.website} target="_blank" rel="noopener noreferrer" style={{ color: colors.primary, textDecoration: 'underline' }}>🌐 {e.website.replace(/^https?:\/\//, '')}</a></span>}
                        {getPrimary(e.addresses) && <span>📍 {formatAddr(getPrimary(e.addresses)!)}</span>}
                      </div>
                      {e.type === 'person' && (e.affiliations?.length > 0) && (
                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, fontSize: 12, color: colors.textSec, marginTop: 4 }}>
                          {e.affiliations.map(aff => {
                            const company = allCompanies.find(c => c.id === aff.companyId);
                            if (!company) return null;
                            return (
                              <span key={aff.companyId} style={{ display: 'inline-flex', alignItems: 'center', gap: 3, background: '#f1f3f4', borderRadius: 10, padding: '1px 8px' }}>
                                🏢 {company.name}{aff.title && <span> · {aff.title}</span>}
                              </span>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  );
                })}
                {totalPages > 1 && (
                  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6, marginTop: 16 }}>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(1)}>«</button>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))}>‹</button>
                    <span style={{ fontSize: 13, color: colors.textSec, margin: '0 8px' }}>Page {safeCurrentPage} of {totalPages}</span>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}>›</button>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(totalPages)}>»</button>
                  </div>
                )}
                <BulkActionsBar selectedIds={selectedIds} entries={entries} allPersons={allPersons} households={households} images={images} onClearSelection={() => { setSelectedIds(new Set()); setSelectMode(false); }} onBulkDelete={actions.handleBulkDelete} onBulkStatusChange={actions.handleBulkStatusChange} onBulkAssignHousehold={actions.handleBulkAssignHousehold} onCreateAndAssignHousehold={actions.handleCreateAndAssignHousehold} onError={setError} onToast={msg => addToast(msg)} />
              </>
            )}
          </>
        )}

        {/* ── PERSON FORM ── */}
        {view === 'personForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{personForm.editId ? 'Edit Person' : 'Add Person'}</h2>
            <DuplicateWarningBanner duplicates={personForm.duplicates} onViewEntry={id => { setSelectedId(id); setView('detail'); }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}><ProfileImage imageUrl={personForm.pImage} size={72} fallback="👤" editable onImageChange={personForm.setPImage} /><span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a profile photo</span></div>
            <div style={S.formGrid}>
              <div><label style={S.label}>First Name *</label><input ref={personForm.pFirstRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pFirst') ? { borderColor: colors.danger } : {}) }} value={personForm.pFirst} onChange={e => { personForm.setPFirst(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pFirst'); return n; }); }} onBlur={() => personForm.setPFirst(capitalizeName(personForm.pFirst))} />{personForm.fieldErrors.has('pFirst') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>First name is required</div>}</div>
              <div><label style={S.label}>Last Name *</label><input ref={personForm.pLastRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pLast') ? { borderColor: colors.danger } : {}) }} value={personForm.pLast} onChange={e => { personForm.setPLast(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pLast'); return n; }); }} onBlur={() => personForm.setPLast(capitalizeName(personForm.pLast))} />{personForm.fieldErrors.has('pLast') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Last name is required</div>}</div>
            </div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Personal Information</div></div>
              <div><label style={S.label}>Gender *</label><select ref={personForm.pGenderRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pGender') ? { borderColor: colors.danger } : {}) }} value={personForm.pGender} onChange={e => { personForm.setPGender(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pGender'); return n; }); }}>{GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}</select>{personForm.fieldErrors.has('pGender') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Gender is required</div>}</div>
              <div><label style={S.label}>Birthday</label><input style={S.input} type="date" value={personForm.pBirthday} onChange={e => personForm.setPBirthday(e.target.value)} /></div>
              <div><label style={S.label}>Status</label><select style={S.input} value={personForm.pStatus} onChange={e => personForm.setPStatus(e.target.value as 'active' | 'deceased')}><option value="active">Active</option><option value="deceased">Deceased</option></select></div>
              {personForm.pStatus === 'deceased' && <div><label style={S.label}>Date of Death</label><input style={S.input} type="date" value={personForm.pDeceasedDate} onChange={e => personForm.setPDeceasedDate(e.target.value)} /></div>}
            </div>
            <div ref={personForm.pEmailSectionRef}><MultiItemField title="Email Addresses" items={personForm.pEmails} onChange={v => { personForm.setPEmails(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pEmail'); return n; }); }} labels={EMAIL_LABELS_PERSON} itemName="Email" emptyFactory={p => ({ address: '', isPrimary: p, label: 'Personal' })} renderInput={(item, update) => <EmailInput placeholder="email@example.com" value={item.address} onChange={v => update({ ...item, address: v })} />} />{personForm.fieldErrors.has('pEmail') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid email addresses before saving.</div>}</div>
            <div ref={personForm.pPhoneSectionRef}><MultiItemField title="Phone Numbers" items={personForm.pPhones} onChange={v => { personForm.setPPhones(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pPhone'); return n; }); }} labels={PHONE_LABELS_PERSON} itemName="Phone" emptyFactory={p => ({ number: '', countryCode: '+1', isPrimary: p, label: 'Mobile' })} renderInput={(item, update) => <PhoneInput value={item.number} countryCode={item.countryCode} placeholder="(555) 123-4567" onChange={v => update({ ...item, number: v })} onCodeChange={code => update({ ...item, countryCode: code })} />} />{personForm.fieldErrors.has('pPhone') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid phone numbers before saving.</div>}</div>
            <div ref={personForm.pAddrSectionRef}><MultiAddressFields addresses={personForm.pAddrs} onChange={v => { personForm.setPAddrs(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pAddr'); return n; }); }} personMode />{personForm.fieldErrors.has('pAddr') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please complete all addresses — at least city and state are required.</div>}</div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Personal Relationships</div></div>
              <SpousePicker allPersons={[...allPersons, ...personForm.pendingPersons]} pendingIds={new Set(personForm.pendingPersons.map(p => p.id))} editId={personForm.editId} selectedSpouseId={personForm.pSpouseId} childIds={personForm.pChildIds} currentGender={personForm.pGender} onSelect={sid => { personForm.setPSpouseId(sid); const spouse = allPersons.find(p => p.id === sid); if (spouse) personForm.setPChildIds(prev => Array.from(new Set([...prev, ...spouse.childIds]))); }} onClear={() => { const wasP = personForm.pendingPersons.find(p => p.id === personForm.pSpouseId); personForm.setPSpouseId(''); personForm.setPAnniversary(''); if (wasP) personForm.removePendingPerson(wasP.id); }} onEditPending={id => { setEditingPendingId(id); setQuickAddMode('spouse'); }} onQuickAdd={(text) => { setQuickAddInitialName(text); setQuickAddMode('spouse'); }} />
              <div><label style={S.label}>Wedding Anniversary</label><input style={S.input} type="date" value={personForm.pAnniversary} onChange={e => personForm.setPAnniversary(e.target.value)} disabled={!personForm.pSpouseId} /></div>
              <RelationshipPicker label="Children" entries={[...allPersons.filter(p => { if (p.id === personForm.editId || p.id === personForm.pSpouseId) return false; if (personForm.pChildIds.includes(p.id)) return true; if (personForm.editId && p.childIds.includes(personForm.editId)) return false; const cid = personForm.editId || '__new__'; if (getAncestorIds(cid, allPersons).has(p.id)) return false; if (getDescendantIds(p.id, allPersons).has(cid)) return false; return allPersons.filter(o => o.id !== personForm.editId && o.id !== personForm.pSpouseId && o.childIds.includes(p.id)).length < 2; }), ...personForm.pendingPersons.filter(p => personForm.pChildIds.includes(p.id))]} pendingIds={new Set(personForm.pendingPersons.map(p => p.id))} selectedIds={personForm.pChildIds} onToggle={id => { const wasP = personForm.pendingPersons.find(p => p.id === id); if (wasP && personForm.pChildIds.includes(id)) { personForm.removePendingPerson(id); } personForm.setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]); }} onEditPending={id => { setEditingPendingId(id); setQuickAddMode('child'); }} onQuickAdd={(text) => { setQuickAddInitialName(text); setQuickAddMode('child'); }} />
              <HouseholdMembership allPersons={allPersons} households={households} editId={personForm.editId} selectedHouseholdId={personForm.pHouseholdId} onSelectHousehold={hid => { personForm.setPHouseholdId(hid); personForm.setHhCreateMode(false); personForm.setNewHhName(''); personForm.setHhNameError(''); }} onClearHousehold={() => { personForm.setPHouseholdId(''); personForm.setHhCreateMode(false); personForm.setNewHhName(''); personForm.setHhNameError(''); }}
                isEditMode={!!personForm.editId}
                canCreateHousehold={(() => {
                  // Create household only allowed on Add Person form (not edit)
                  if (personForm.editId) return false;
                  if (personForm.pHouseholdId) return false;
                  const hasFamily = !!personForm.pSpouseId || personForm.pChildIds.length > 0;
                  if (!hasFamily) return false;
                  const hasAddress = personForm.pAddrs.some(a => a.street.trim() && a.city.trim() && a.state.trim());
                  if (!hasAddress) return false;
                  // All family members must be new (pending) — not existing persons
                  const pendingIdSet = new Set(personForm.pendingPersons.map(p => p.id));
                  if (personForm.pSpouseId && !pendingIdSet.has(personForm.pSpouseId)) return false;
                  for (const cid of personForm.pChildIds) {
                    if (!pendingIdSet.has(cid)) return false;
                  }
                  return true;
                })()}
                hasFamily={!personForm.editId && !personForm.pHouseholdId && (!!personForm.pSpouseId || personForm.pChildIds.length > 0)}
                familyMemberNames={(() => {
                  const names: string[] = [`${personForm.pFirst.trim() || 'Current Person'} ${personForm.pLast.trim()}`.trim()];
                  if (personForm.pSpouseId) {
                    const sp = [...allPersons, ...personForm.pendingPersons].find(p => p.id === personForm.pSpouseId);
                    if (sp) names.push(`${sp.firstName} ${sp.lastName}`);
                  }
                  for (const cid of personForm.pChildIds) {
                    const ch = [...allPersons, ...personForm.pendingPersons].find(p => p.id === cid);
                    if (ch) names.push(`${ch.firstName} ${ch.lastName}`);
                  }
                  return names;
                })()}
                createMode={personForm.hhCreateMode}
                onToggleCreateMode={on => { personForm.setHhCreateMode(on); if (on) { personForm.setNewHhPrimary(personForm.editId || '__self__'); } else { personForm.setNewHhName(''); personForm.setHhNameError(''); personForm.setNewHhPrimary(''); } }}
                newHouseholdName={personForm.newHhName}
                onNewHouseholdNameChange={v => { personForm.setNewHhName(v); personForm.setHhNameError(''); }}
                householdNameError={personForm.hhNameError}
                newHouseholdPrimary={personForm.newHhPrimary}
                onNewHouseholdPrimaryChange={v => personForm.setNewHhPrimary(v)}
                familyMemberIds={(() => {
                  const ids: string[] = [personForm.editId || '__self__'];
                  if (personForm.pSpouseId) ids.push(personForm.pSpouseId);
                  for (const cid of personForm.pChildIds) {
                    if (!ids.includes(cid)) ids.push(cid);
                  }
                  return ids;
                })()}
              />
            </div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Professional Information</div></div>
              <div style={S.fieldFull}>
                <label style={{ ...S.label, display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', userSelect: 'none' }}>
                  <input type="checkbox" checked={personForm.pIsMissionary} onChange={e => personForm.setPIsMissionary(e.target.checked)} style={{ accentColor: colors.primary }} />
                  Missionary
                </label>
              </div>
              <AffiliationEditor
                affiliations={personForm.pAffiliations}
                allCompanies={allCompanies}
                pendingCompanies={personForm.pendingCompanies}
                isMissionary={personForm.pIsMissionary}
                onChange={personForm.setPAffiliations}
                onRemovePending={id => personForm.setPendingCompanies(prev => prev.filter(pc => pc.id !== id))}
                onEditPending={id => { setEditingPendingCompanyId(id); setQuickAddCompanyOpen(true); }}
                onQuickAdd={text => { setQuickAddCompanyInitName(text); setQuickAddCompanyOpen(true); }}
              />
            </div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Notes</div></div>
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={personForm.pNotes} onChange={e => personForm.setPNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}><button style={{ ...S.btn, ...S.btnPrimary }} onClick={async () => { const name = await personForm.save(); if (name) { addToast(`✅ ${name} saved`); } }}>Save Person</button><button style={{ ...S.btn, ...S.btnSec }} onClick={() => { personForm.reset(); setError(''); setView('list'); }}>Cancel</button></div>
          </>
        )}

        {/* ── COMPANY FORM ── */}
        {view === 'companyForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{companyForm.editId ? 'Edit Company' : 'Add Company'}</h2>
            <DuplicateWarningBanner duplicates={companyForm.duplicates} onViewEntry={id => { setSelectedId(id); setView('detail'); }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}><ProfileImage imageUrl={companyForm.cImage} size={72} fallback="🏢" editable onImageChange={companyForm.setCImage} /><span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a profile photo</span></div>
            <div style={S.formGrid}>
              <div><label style={S.label}>Company Name *</label><input ref={companyForm.cNameRef} style={{ ...S.input, ...(companyForm.fieldErrors.has('cName') ? { borderColor: colors.danger } : {}) }} value={companyForm.cName} onChange={e => { companyForm.setCName(e.target.value); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cName'); return n; }); }} onBlur={() => companyForm.setCName(capitalizeName(companyForm.cName))} />{companyForm.fieldErrors.has('cName') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Company name is required</div>}</div>
              <div><label style={S.label}>Industry</label><input style={S.input} value={companyForm.cIndustry} onChange={e => companyForm.setCIndustry(e.target.value)} /></div>
              <div><label style={S.label}>Status</label><select style={S.input} value={companyForm.cStatus} onChange={e => companyForm.setCStatus(e.target.value as 'active' | 'closed')}><option value="active">Active</option><option value="closed">Closed</option></select></div>
              {companyForm.cStatus !== 'active' && <div><label style={S.label}>Date Closed</label><input style={S.input} type="date" value={companyForm.cClosedDate} onChange={e => companyForm.setCClosedDate(e.target.value)} /></div>}
            </div>
            <div style={{ marginTop: 14 }}><label style={S.label}>Website</label><input ref={companyForm.cWebsiteRef} style={{ ...S.input, ...(companyForm.cWebsiteError ? { borderColor: colors.danger } : {}) }} type="url" placeholder="https://www.example.com" value={companyForm.cWebsite} onChange={e => { companyForm.setCWebsite(e.target.value); companyForm.setCWebsiteError(''); }} onBlur={() => { if (companyForm.cWebsite.trim()) { try { const raw = companyForm.cWebsite.trim().match(/^https?:\/\//) ? companyForm.cWebsite.trim() : `https://${companyForm.cWebsite.trim()}`; const parsed = new URL(raw); if (!parsed.hostname.includes('.')) throw new Error('invalid'); companyForm.setCWebsiteError(''); parsed.hostname = parsed.hostname.replace(/^www\./, ''); let n = parsed.toString(); if (parsed.pathname === '/' && !parsed.search && !parsed.hash) n = n.replace(/\/$/, ''); companyForm.setCWebsite(n); } catch { companyForm.setCWebsiteError('Please enter a valid URL (e.g. https://example.com)'); } } else { companyForm.setCWebsiteError(''); } }} />{companyForm.cWebsiteError && <div style={{ fontSize: 12, color: colors.danger, marginTop: 4 }}>{companyForm.cWebsiteError}</div>}</div>
            <div ref={companyForm.cEmailSectionRef}><MultiItemField title="Email Addresses" items={companyForm.cEmails} onChange={v => { companyForm.setCEmails(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cEmail'); return n; }); }} labels={EMAIL_LABELS_COMPANY} itemName="Email" emptyFactory={p => ({ address: '', isPrimary: p, label: 'Main' })} renderInput={(item, update) => <EmailInput placeholder="contact@company.com" value={item.address} onChange={v => update({ ...item, address: v })} />} />{companyForm.fieldErrors.has('cEmail') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid email addresses before saving.</div>}</div>
            <div ref={companyForm.cPhoneSectionRef}><MultiItemField title="Phone Numbers" items={companyForm.cPhones} onChange={v => { companyForm.setCPhones(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cPhone'); return n; }); }} labels={PHONE_LABELS_COMPANY} itemName="Phone" emptyFactory={p => ({ number: '', countryCode: '+1', isPrimary: p, label: 'Main' })} renderInput={(item, update) => <PhoneInput value={item.number} countryCode={item.countryCode} placeholder="(555) 123-4567" onChange={v => update({ ...item, number: v })} onCodeChange={code => update({ ...item, countryCode: code })} />} />{companyForm.fieldErrors.has('cPhone') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid phone numbers before saving.</div>}</div>
            <div ref={companyForm.cAddrSectionRef}><MultiAddressFields addresses={companyForm.cAddrs} onChange={v => { companyForm.setCAddrs(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cAddr'); return n; }); }} companyMode />{companyForm.fieldErrors.has('cAddr') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please complete all addresses — at least city and state are required.</div>}</div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Contact Persons</div></div>
              <div style={S.fieldFull}>
                <label style={S.label}>Contact Persons</label>
                {companyForm.cContactIds.length > 0 && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 10 }}>
                    {companyForm.cContactIds.map(pid => {
                      const person = allPersons.find(p => p.id === pid);
                      const name = person ? `${person.firstName} ${person.lastName}` : 'Unknown';
                      return (
                        <div key={pid} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', borderRadius: 8, border: `1px solid ${colors.border}`, background: '#fafbfc' }}>
                          <span style={{ fontWeight: 600, fontSize: 13, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{name}</span>
                          <span style={{ color: colors.textSec, fontSize: 12 }}>·</span>
                          <input
                            style={{ ...S.input, flex: 1, padding: '4px 8px', fontSize: 13 }}
                            placeholder="Title (e.g. Manager)"
                            value={companyForm.cContactTitles[pid] || ''}
                            onChange={e => companyForm.setCContactTitles(prev => ({ ...prev, [pid]: e.target.value }))}
                          />
                          <button style={{ ...S.chipRemove, fontSize: 16 }} onClick={() => {
                            companyForm.setCContactIds(prev => prev.filter(x => x !== pid));
                            companyForm.setCContactTitles(prev => { const n = { ...prev }; delete n[pid]; return n; });
                          }}>×</button>
                        </div>
                      );
                    })}
                  </div>
                )}
                <ContactPersonSearch
                  allPersons={allPersons}
                  excludeIds={companyForm.cContactIds}
                  editCompanyId={companyForm.editId}
                  onAdd={(pid, title) => {
                    companyForm.setCContactIds(prev => [...prev, pid]);
                    if (title) {
                      companyForm.setCContactTitles(prev => ({ ...prev, [pid]: title }));
                    }
                  }}
                />
              </div>
            </div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Notes</div></div>
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={companyForm.cNotes} onChange={e => companyForm.setCNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}><button style={{ ...S.btn, ...S.btnPrimary }} onClick={async () => { const name = await companyForm.save(); if (name) addToast(`✅ ${name} saved`); }}>Save Company</button><button style={{ ...S.btn, ...S.btnSec }} onClick={() => { companyForm.reset(); setError(''); setView('list'); }}>Cancel</button></div>
          </>
        )}

        {/* ── DETAIL VIEW ── */}
        {view === 'detail' && selectedEntry && (
          <DetailView entry={selectedEntry} entries={entries} allPersons={allPersons} households={households} images={images} collapsedSections={collapsedSections} toggleSection={toggleSection} setSelectedId={setSelectedId} setView={setView} setError={setError}
            onEdit={() => { if (selectedEntry.type === 'person') { personForm.fill(selectedEntry as Person); setView('personForm'); } else { companyForm.fill(selectedEntry as Company); setView('companyForm'); } }}
            onDelete={() => setDeleteTarget(selectedEntry)}
            onToast={msg => addToast(msg)} />
        )}

        {/* ── HOUSEHOLDS VIEW ── */}
        {view === 'households' && (
          <><div style={S.btnRow}>
            <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setView('list')}>← Back to Directory</button>
          </div><h2 style={{ marginBottom: 16 }}>🏠 Households</h2><HouseholdView households={households} allPersons={allPersons} images={images} onReload={reload} onToast={msg => addToast(msg)} /></>
        )}

        {/* ── IMPORT PREVIEW ── */}
        {view === 'import' && <ImportView importPreview={importPreview} importHouseholdsPreview={importHouseholdsPreview} importFileName={importFileName} importing={importing} onConfirm={handleImportConfirm} onCancel={handleImportCancel} />}
      </div>

      {/* ── DIALOGS ── */}
      {deleteTarget && <DeleteDialog target={deleteTarget} allPersons={allPersons} entries={entries} households={households} onCancel={() => setDeleteTarget(null)} onConfirm={async () => { const name = await actions.confirmDelete(); if (name) addToast(`🗑️ ${name} deleted`); }} />}
      {showDeleteAll && <DeleteAllDialog entryCount={entries.length} householdCount={households.length} onCancel={() => setShowDeleteAll(false)} onConfirm={async () => { const count = await actions.handleDeleteAll(); if (count) addToast(`🗑️ All ${count} records deleted`); }} />}
      {showPrintDialog && <PrintDialog entries={entries} households={households} images={images} onClose={() => setShowPrintDialog(false)} onError={setError} onSuccess={() => addToast('🖨️ Directory generated')} />}
      {quickAddMode && (
        <QuickAddRelativeDialog
          mode={quickAddMode}
          currentGender={personForm.pGender}
          defaultLastName={personForm.pLast}
          initialFirstName={quickAddInitialName}
          editPerson={editingPendingId ? personForm.pendingPersons.find(p => p.id === editingPendingId) : null}
          onCancel={() => { setQuickAddMode(null); setEditingPendingId(null); setQuickAddInitialName(''); }}
          onCreated={(person) => {
            if (editingPendingId) {
              personForm.updatePendingPerson(person);
              addToast(`✏️ ${person.firstName} ${person.lastName} updated`);
            } else {
              personForm.addPendingPerson(person);
              if (quickAddMode === 'spouse') {
                personForm.setPSpouseId(person.id);
              } else {
                personForm.setPChildIds(prev => [...prev, person.id]);
              }
              addToast(`✨ ${person.firstName} ${person.lastName} added as pending ${quickAddMode}`);
            }
            setQuickAddMode(null);
            setEditingPendingId(null);
            setQuickAddInitialName('');
          }}
        />
      )}
      {quickAddCompanyOpen && (
        <QuickAddCompanyDialog
          initialName={editingPendingCompanyId ? undefined : quickAddCompanyInitName}
          editCompany={editingPendingCompanyId ? personForm.pendingCompanies.find(pc => pc.id === editingPendingCompanyId) || null : null}
          onCancel={() => { setQuickAddCompanyOpen(false); setEditingPendingCompanyId(null); setQuickAddCompanyInitName(''); }}
          onCreated={(company) => {
            if (editingPendingCompanyId) {
              // Update existing pending company
              personForm.setPendingCompanies(prev => prev.map(pc => pc.id === editingPendingCompanyId ? company : pc));
              addToast(`✏️ ${company.name} updated`);
            } else {
              // Add new pending company and wire the affiliation
              personForm.setPendingCompanies(prev => [...prev, company]);
              personForm.setPAffiliations(prev => [...prev, { companyId: company.id, title: '' }]);
              addToast(`✨ ${company.name} added as pending company`);
            }
            setQuickAddCompanyOpen(false);
            setEditingPendingCompanyId(null);
            setQuickAddCompanyInitName('');
          }}
        />
      )}
    </div>
  );
};

export const App = () => (
  <ToastProvider>
    <AppInner />
  </ToastProvider>
);

export default App;

