import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { Person, Household, Address, AddressSuggestion } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, formatAddr, suggestAddresses, useDebounce, selectNewPrimaryContact } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold, removePersonFromHousehold, loadHousehold, saveImage, removeImage } from '../storage';
import { COUNTRIES } from '../countryCodes';
import { ProfileImage } from './ProfileImage';

interface HouseholdViewProps {
  households: Household[];
  allPersons: Person[];
  images: Record<string, string>;
  onReload: () => Promise<void>;
  onToast: (msg: string) => void;
}

function HouseholdAddressSection({ address, setAddress }: { address: Address; setAddress: (a: Address) => void }) {
  const [streetQuery, setStreetQuery] = useState(address.street);
  const [suggestions, setSuggestions] = useState<AddressSuggestion[]>([]);
  const debounced = useDebounce(streetQuery, 400);
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setStreetQuery(address.street); }, [address.street]);

  useEffect(() => {
    if (debounced.length >= 3) suggestAddresses(debounced).then(setSuggestions);
    else setSuggestions([]);
  }, [debounced]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setSuggestions([]);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const pick = (s: AddressSuggestion) => {
    setAddress({ ...address, ...s });
    setStreetQuery(s.street);
    setSuggestions([]);
  };

  return (
    <>
      <div style={S.section}>Address *</div>
      <div style={S.formGrid}>
        <div style={{ ...S.fieldFull, position: 'relative' }} ref={wrapRef}>
          <label style={S.label}>Street</label>
          <input style={S.input} value={streetQuery} placeholder="Start typing to auto-suggest..."
            onChange={e => { setStreetQuery(e.target.value); setAddress({ ...address, street: e.target.value }); }} />
          {suggestions.length > 0 && (
            <div style={S.addrDropdown}>
              {suggestions.map((s, i) => (
                <div key={i} style={S.addrItem}
                  onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                  onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                  onClick={() => pick(s)}>
                  {s.street}, {s.city}, {s.state} {s.zip}
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={S.fieldFull}>
          <label style={S.label}>Address Line 2 <span style={{ fontWeight: 400, color: colors.textSec }}>(optional)</span></label>
          <input style={S.input} value={address.street2 || ''} placeholder="Apt, Suite, Floor, etc."
            onChange={e => setAddress({ ...address, street2: e.target.value })} />
        </div>
        <div><label style={S.label}>City</label><input style={S.input} value={address.city} onChange={e => setAddress({ ...address, city: e.target.value })} /></div>
        <div><label style={S.label}>State</label><input style={S.input} value={address.state} maxLength={2} placeholder="e.g. CA" onChange={e => setAddress({ ...address, state: e.target.value.toUpperCase() })} /></div>
        <div><label style={S.label}>ZIP</label><input style={S.input} value={address.zip} onChange={e => setAddress({ ...address, zip: e.target.value })} /></div>
        <div><label style={S.label}>Country</label>
          <select style={S.input} value={address.country || 'United States'} onChange={e => setAddress({ ...address, country: e.target.value })}>
            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>
    </>
  );
}

export function HouseholdView({ households, allPersons, images, onReload, onToast }: HouseholdViewProps) {
  const [editing, setEditing] = useState<Household | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());

  // Search, Sort & Pagination
  const [filterQ, setFilterQ] = useState('');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');
  const [pageSize, setPageSize] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);

  // Form state
  const [name, setName] = useState('');
  const [address, setAddress] = useState<Address>({ ...EMPTY_ADDR, label: 'Household' });
  const [memberIds, setMemberIds] = useState<string[]>([]);
  const [primaryContactId, setPrimaryContactId] = useState('');
  const [hhImage, setHhImage] = useState<string | null>(null);

  // Refs for auto-focus and scroll
  const nameRef = useRef<HTMLInputElement>(null);
  const primaryRef = useRef<HTMLSelectElement>(null);
  const addressSectionRef = useRef<HTMLDivElement>(null);
  const membersSectionRef = useRef<HTMLDivElement>(null);

  const scrollToAndFocus = useCallback((ref: React.RefObject<HTMLElement | null>) => {
    setTimeout(() => {
      ref.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      if (ref.current && 'focus' in ref.current) (ref.current as HTMLElement).focus();
    }, 50);
  }, []);

  // Dialogs
  const [removeMemberTarget, setRemoveMemberTarget] = useState<{ householdId: string; memberId: string } | null>(null);
  const [deleteHouseholdTarget, setDeleteHouseholdTarget] = useState<Household | null>(null);
  const [newPrimaryForRemoval, setNewPrimaryForRemoval] = useState('');

  // Member search
  const [memberQ, setMemberQ] = useState('');
  const [memberDropdownOpen, setMemberDropdownOpen] = useState(false);
  const memberRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (memberRef.current && !memberRef.current.contains(ev.target as Node)) setMemberDropdownOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const resetForm = () => {
    setName(''); setAddress({ ...EMPTY_ADDR, label: 'Household' });
    setMemberIds([]); setPrimaryContactId(''); setHhImage(null); setEditing(null); setShowForm(false); setError(''); setFieldErrors(new Set());
  };

  const openCreate = () => { resetForm(); setShowForm(true); };

  const openEdit = (h: Household) => {
    setEditing(h);
    setName(h.name);
    setAddress({ ...h.address });
    setMemberIds([...h.memberIds]);
    setPrimaryContactId(h.primaryContactId);
    setHhImage(images[h.id] || null);
    setShowForm(true);
    setError('');
  };

  const handleSave = async () => {
    const errs = new Set<string>();
    if (!name.trim()) errs.add('hhName');
    else if (households.some(h => h.id !== (editing?.id) && h.name.trim().toLowerCase() === name.trim().toLowerCase())) errs.add('hhNameDupe');
    if (!address.street.trim() && !address.city.trim()) errs.add('hhAddress');

    // When editing an existing household, allow fewer than 2 members — the
    // dissolution logic handles it. Only enforce the minimum for new households.
    const willDissolve = editing && memberIds.length < 2;
    if (!willDissolve) {
      if (memberIds.length < 2) errs.add('hhMembers');
      if (!primaryContactId) errs.add('hhPrimary');
      if (primaryContactId && !memberIds.includes(primaryContactId)) errs.add('hhPrimary');
    }

    if (errs.size > 0) {
      setFieldErrors(errs);
      setError('');
      // Scroll to and focus first invalid field
      if (errs.has('hhName') || errs.has('hhNameDupe')) { scrollToAndFocus(nameRef); return; }
      if (errs.has('hhAddress')) { scrollToAndFocus(addressSectionRef); return; }
      if (errs.has('hhMembers')) { scrollToAndFocus(membersSectionRef); return; }
      if (errs.has('hhPrimary')) { scrollToAndFocus(primaryRef); return; }
      return;
    }
    setFieldErrors(new Set());

    setError('');
    const id = editing?.id || uuidv4();

    try {
      // If editing, handle members that were removed
      let dissolved = false;
      if (editing) {
        const removedIds = editing.memberIds.filter(mid => !memberIds.includes(mid));
        // Track remaining members to feed an accurate household state to each removal
        let currentMemberIds = [...editing.memberIds];
        let currentPrimary = editing.primaryContactId;
        for (const mid of removedIds) {
          if (dissolved) {
            // Household already dissolved — the dissolution may have relabeled
            // this member's "Household" address to "Home". Re-load from storage
            // to get the current state and strip the household-origin address
            // by matching its content against the household address.
            const member = await loadEntry(mid);
            if (member && member.type === 'person') {
              const hhAddr = editing.address;
              const isHouseholdAddr = (a: Address) =>
                a.label === 'Household' ||
                (a.label === 'Home' && a.street === hhAddr.street && a.city === hhAddr.city && a.state === hhAddr.state && a.zip === hhAddr.zip);
              const addrs = member.addresses.filter(a => !isHouseholdAddr(a));
              if (addrs.length > 0 && !addrs.some(a => a.isPrimary)) addrs[0] = { ...addrs[0], isPrimary: true };
              await saveEntry({ ...member, householdId: '', addresses: addrs });
            }
          } else {
            const currentHousehold = { ...editing, memberIds: currentMemberIds, primaryContactId: currentPrimary };
            const result = await removePersonFromHousehold(mid, currentHousehold, allPersons);
            if (result === 'dissolved') {
              dissolved = true;
            } else {
              currentMemberIds = currentMemberIds.filter(id => id !== mid);
              if (currentPrimary === mid) currentPrimary = currentMemberIds[0] || '';
            }
          }
        }
      }

      if (!dissolved) {
        const household: Household = { id, name: name.trim(), address, memberIds, primaryContactId };
        // Set householdId on all members and sync address
        for (const mid of memberIds) {
          const member = await loadEntry(mid);
          if (member && member.type === 'person') {
            const addrs = [...member.addresses];
            const householdAddr = { ...address, isPrimary: true, label: 'Household' };
            const pIdx = addrs.findIndex(a => a.isPrimary);
            if (pIdx >= 0) addrs[pIdx] = householdAddr;
            else if (addrs.length > 0) { addrs[0] = householdAddr; }
            else addrs.push(householdAddr);
            await saveEntry({ ...member, householdId: id, addresses: addrs });
          }
        }

        await saveHousehold(household);
        // Save or remove household image
        if (hhImage) await saveImage(id, hhImage);
        else if (editing && images[editing.id]) await removeImage(id);
      } else {
        // Household was dissolved — clean up image if present
        if (editing && images[editing.id]) await removeImage(id);
      }

      await onReload();
      const savedName = name.trim();
      resetForm();
      if (dissolved) {
        onToast(`🏚️ ${savedName} dissolved`);
      } else {
        onToast(editing ? `✏️ ${savedName} updated` : `✅ ${savedName} created`);
      }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // Remove member flow
  const initiateRemoveMember = (householdId: string, memberId: string) => {
    setRemoveMemberTarget({ householdId, memberId });
    setNewPrimaryForRemoval('');
  };

  const confirmRemoveMember = async () => {
    if (!removeMemberTarget) return;
    const { householdId, memberId } = removeMemberTarget;
    const household = households.find(h => h.id === householdId);
    if (!household) { setRemoveMemberTarget(null); return; }

    try {
      const result = await removePersonFromHousehold(memberId, household, allPersons);
      const remainingIds = household.memberIds.filter(id => id !== memberId);

      await onReload();
      const removedName = resolveName(memberId);
      setRemoveMemberTarget(null);
      setNewPrimaryForRemoval('');
      if (result === 'dissolved') {
        onToast(`🏠 ${household.name} dissolved — ${removedName} removed`);
      } else {
        onToast(`👤 ${removedName} removed from ${household.name}`);
      }
      // If we're in the form, update state
      if (showForm && editing?.id === householdId) {
        if (result === 'dissolved') { resetForm(); }
        else {
          // Reload the household to get the updated primaryContactId
          setMemberIds(remainingIds);
          const reloaded = await loadHousehold(householdId);
          if (reloaded) {
            setPrimaryContactId(reloaded.primaryContactId);
            setEditing(reloaded);
          }
        }
      }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // Delete household flow
  const confirmDeleteHousehold = async () => {
    if (!deleteHouseholdTarget) return;
    const household = deleteHouseholdTarget;

    try {
      // Remove all members according to removal rules
      for (const mid of household.memberIds) {
        const member = await loadEntry(mid);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
      }
      await removeHousehold(household.id);
      if (images[household.id]) await removeImage(household.id);
      await onReload();
      const deletedName = household.name;
      setDeleteHouseholdTarget(null);
      if (showForm && editing?.id === household.id) resetForm();
      onToast(`🗑️ ${deletedName} deleted`);
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  const resolveName = useCallback((id: string) => {
    const p = allPersons.find(x => x.id === id);
    return p ? getEntryName(p) : 'Unknown';
  }, [allPersons]);

  const eligibleMembers = allPersons.filter(p => {
    if (memberIds.includes(p.id)) return false;
    // Only active persons can be added to a household
    if ((p.status || 'active') !== 'active') return false;
    // Person must not be in another household
    const existingHousehold = households.find(h => h.memberIds.includes(p.id) && h.id !== editing?.id);
    if (existingHousehold) return false;
    return `${p.firstName} ${p.lastName}`.toLowerCase().includes(memberQ.toLowerCase());
  });

  // Filtered, sorted & paginated households
  const sortedHouseholds = useMemo(() => {
    const q = filterQ.toLowerCase().trim();
    const filtered = q ? households.filter(h => {
      if (h.name.toLowerCase().includes(q)) return true;
      const a = h.address;
      if ([a.street, a.street2, a.city, a.state, a.zip, a.country].some(f => f && f.toLowerCase().includes(q))) return true;
      // Also match member names
      return h.memberIds.some(mid => resolveName(mid).toLowerCase().includes(q));
    }) : households;
    return [...filtered].sort((a, b) => {
      const cmp = a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });
      return sortDir === 'asc' ? cmp : -cmp;
    });
  }, [households, filterQ, sortDir, resolveName]);
  const totalHouseholds = sortedHouseholds.length;
  const totalPages = Math.max(1, Math.ceil(totalHouseholds / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStart = (safeCurrentPage - 1) * pageSize;
  const pageEnd = Math.min(pageStart + pageSize, totalHouseholds);
  const paginatedHouseholds = sortedHouseholds.slice(pageStart, pageEnd);

  return (
    <>
      {error && <div style={{ fontSize: 13, color: colors.danger, marginBottom: 14 }}>{error}</div>}

      {!showForm ? (
        <>
          <div style={S.btnRow}>
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={openCreate}>+ Create Household</button>
          </div>

          {/* Search / Filter */}
          <div style={{ position: 'relative', marginBottom: 14 }}>
            <input
              style={{ ...S.input, paddingRight: filterQ ? 32 : 12 }}
              placeholder="Search households by name, address, or member..."
              value={filterQ}
              onChange={e => { setFilterQ(e.target.value); setCurrentPage(1); }}
            />
            {filterQ && (
              <button onClick={() => { setFilterQ(''); setCurrentPage(1); }} title="Clear search" style={{ position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)', border: 'none', background: colors.hover, color: colors.textSec, borderRadius: '50%', width: 20, height: 20, fontSize: 13, lineHeight: 1, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 0 }}>×</button>
            )}
          </div>

          {households.length === 0 ? (
            <div style={S.emptyState}>No households yet. Create one to get started.</div>
          ) : sortedHouseholds.length === 0 ? (
            <div style={S.emptyState}>No households match "{filterQ}".</div>
          ) : (
            <>
              {/* Pagination info & page size selector */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, fontSize: 13, color: colors.textSec }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span>Showing {pageStart + 1}–{pageEnd} of {totalHouseholds} household{totalHouseholds === 1 ? '' : 's'}</span>
                  <button onClick={() => { setSortDir(d => d === 'asc' ? 'desc' : 'asc'); setCurrentPage(1); }} style={{ ...S.btn, ...S.btnSec, padding: '3px 10px', fontSize: 12 }} title={`Sort by name ${sortDir === 'asc' ? 'Z→A' : 'A→Z'}`}>
                    Name {sortDir === 'asc' ? '↑' : '↓'}
                  </button>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span>Per page:</span>
                  {[25, 50, 100].map(size => (
                    <button key={size} onClick={() => { setPageSize(size); setCurrentPage(1); }} style={{
                      ...S.btn, padding: '3px 10px', fontSize: 12,
                      background: pageSize === size ? colors.primary : 'transparent',
                      color: pageSize === size ? '#fff' : colors.text,
                      border: `1px solid ${pageSize === size ? colors.primary : colors.border}`,
                      borderRadius: 4,
                    }}>{size}</button>
                  ))}
                </div>
              </div>

              {paginatedHouseholds.map(h => (
              <div key={h.id} style={{ ...S.card, cursor: 'default' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <ProfileImage imageUrl={images[h.id] || null} size={36} fallback="🏠" />
                    <div>
                      <strong style={{ fontSize: 16 }}>{h.name}</strong>
                      <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>
                        📍 {formatAddr(h.address)}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} onClick={() => openEdit(h)}>Edit</button>
                    <button style={{ ...S.btn, ...S.btnDanger, padding: '6px 12px', fontSize: 13 }} onClick={() => setDeleteHouseholdTarget(h)}>Delete</button>
                  </div>
                </div>
                <div style={{ marginTop: 10, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                  {h.memberIds.map(mid => (
                    <span key={mid} style={{ ...S.chip, background: mid === h.primaryContactId ? '#c6f0c2' : colors.accent }}>
                      {resolveName(mid)}
                      {mid === h.primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 4 }}>★ Primary</span>}
                    </span>
                  ))}
                  {h.memberIds.length === 0 && <span style={{ fontSize: 13, color: colors.textSec }}>No members</span>}
                </div>
              </div>
              ))}

              {/* Pagination navigation */}
              {totalPages > 1 && (
                <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6, marginTop: 16 }}>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(1)}>«</button>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))}>‹</button>
                  <span style={{ fontSize: 13, color: colors.textSec, margin: '0 8px' }}>
                    Page {safeCurrentPage} of {totalPages}
                  </span>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}>›</button>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(totalPages)}>»</button>
                </div>
              )}
            </>
          )}
        </>
      ) : (
        <>
          <h2 style={{ marginBottom: 16 }}>{editing ? `Edit Household: ${editing.name}` : 'Create Household'}</h2>

          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
            <ProfileImage imageUrl={hhImage} size={72} fallback="🏠" editable onImageChange={setHhImage} />
            <span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a household photo</span>
          </div>

          <div style={S.formGrid}>
            <div style={S.fieldFull}>
              <label style={S.label}>Household Name *</label>
              <input ref={nameRef} style={{ ...S.input, ...((fieldErrors.has('hhName') || fieldErrors.has('hhNameDupe')) ? { borderColor: colors.danger } : {}) }} value={name} onChange={e => { setName(e.target.value); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhName'); n.delete('hhNameDupe'); return n; }); }} placeholder="e.g. Smith Family" />
              {fieldErrors.has('hhName') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Household name is required</div>}
              {fieldErrors.has('hhNameDupe') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>A household with this name already exists</div>}
            </div>
          </div>

          <div ref={addressSectionRef}>
          <HouseholdAddressSection address={address} setAddress={a => { setAddress(a); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhAddress'); return n; }); }} />
          {fieldErrors.has('hhAddress') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3, marginBottom: 8 }}>At least a street or city is required</div>}
          </div>

          <div ref={membersSectionRef}>
          <div style={S.section}>Members{memberIds.length < 2 ? ' *' : ''}</div>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            A household must have at least two members. One must be designated as primary contact.
          </span>
          {fieldErrors.has('hhMembers') && <div style={{ fontSize: 12, color: colors.danger, marginBottom: 8 }}>At least two members are required</div>}

          {memberIds.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 12 }}>
              {memberIds.map(mid => (
                <span key={mid} style={{ ...S.chip, background: mid === primaryContactId ? '#c6f0c2' : colors.accent }}>
                  {resolveName(mid)}
                  {mid === primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 4 }}>★</span>}
                  <button style={S.chipRemove} onClick={() => {
                    const newMembers = memberIds.filter(x => x !== mid);
                    setMemberIds(newMembers);
                    if (primaryContactId === mid) setPrimaryContactId(newMembers[0] || '');
                    setFieldErrors(prev => {
                      const n = new Set(prev);
                      // When editing, allow < 2 members (dissolution will handle it)
                      if (!editing && newMembers.length < 2) n.add('hhMembers');
                      else n.delete('hhMembers');
                      // If a valid primary is auto-assigned (or was already valid), clear hhPrimary
                      const effectivePrimary = primaryContactId === mid ? newMembers[0] || '' : primaryContactId;
                      if (editing && newMembers.length < 2) {
                        // Dissolution path — no primary needed
                        n.delete('hhPrimary');
                      } else if (effectivePrimary && newMembers.includes(effectivePrimary)) n.delete('hhPrimary');
                      else if (!effectivePrimary) n.add('hhPrimary');
                      return n;
                    });
                  }}>×</button>
                </span>
              ))}
            </div>
          )}

          {memberIds.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={S.label}>Primary Contact *</label>
              <select ref={primaryRef} style={{ ...S.input, ...(fieldErrors.has('hhPrimary') ? { borderColor: colors.danger } : {}) }} value={primaryContactId} onChange={e => { setPrimaryContactId(e.target.value); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhPrimary'); return n; }); }}>
                <option value="">— Select primary contact —</option>
                {memberIds.map(mid => (
                  <option key={mid} value={mid}>{resolveName(mid)}</option>
                ))}
              </select>
              {fieldErrors.has('hhPrimary') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Primary contact is required</div>}
            </div>
          )}

          {/* Inline removal consequences preview */}
          {editing && (() => {
            const pendingRemovals = editing.memberIds.filter(mid => !memberIds.includes(mid));
            if (pendingRemovals.length === 0) return null;
            const remainingCount = editing.memberIds.length - pendingRemovals.length;
            const willDissolve = remainingCount <= 1;
            const warnings: { icon: string; text: string }[] = [];

            if (willDissolve) {
              warnings.push({ icon: '🏚️', text: `Removing ${pendingRemovals.length} member${pendingRemovals.length > 1 ? 's' : ''} will dissolve this household (fewer than 2 remaining).` });
              if (remainingCount === 1) {
                const lastId = editing.memberIds.find(mid => memberIds.includes(mid));
                const lastName = lastId ? resolveName(lastId) : 'the remaining member';
                warnings.push({ icon: '🏠', text: `${lastName}'s address label will change from "Household" to "Home".` });
              }
            } else {
              warnings.push({ icon: '👥', text: `Removing ${pendingRemovals.length} member${pendingRemovals.length > 1 ? 's' : ''} — ${remainingCount} will remain.` });
              // Check if current primary is being removed
              const primaryBeingRemoved = pendingRemovals.includes(editing.primaryContactId);
              if (primaryBeingRemoved) {
                const remainingIds = editing.memberIds.filter(mid => !pendingRemovals.includes(mid));
                const newPrimary = selectNewPrimaryContact(editing.primaryContactId, remainingIds, allPersons);
                const newPrimaryPerson = allPersons.find(p => p.id === newPrimary);
                if (newPrimaryPerson) {
                  const removedPerson = allPersons.find(p => p.id === editing.primaryContactId);
                  let reason = '';
                  if (removedPerson?.spouseId === newPrimary) reason = 'spouse';
                  else if (newPrimaryPerson.childIds.length > 0) reason = 'parent';
                  else if (newPrimaryPerson.phones.some(ph => ph.number.trim())) reason = 'has phone';
                  else reason = 'next member';
                  warnings.push({ icon: '★', text: `Primary contact will be reassigned to ${getEntryName(newPrimaryPerson)} (${reason}).` });
                }
              }
            }
            for (const mid of pendingRemovals) {
              warnings.push({ icon: '📍', text: `The household address will be removed from ${resolveName(mid)}'s record.` });
            }

            return (
              <div style={{ background: '#fff8e1', border: '1px solid #ffe082', borderRadius: 8, padding: '10px 14px', marginBottom: 14, fontSize: 13, lineHeight: 1.6 }}>
                <div style={{ fontWeight: 600, marginBottom: 4, color: '#e65100' }}>⚠ Pending changes on save:</div>
                {warnings.map((w, i) => (
                  <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                    <span style={{ flexShrink: 0 }}>{w.icon}</span>
                    <span style={{ color: colors.text }}>{w.text}</span>
                  </div>
                ))}
              </div>
            );
          })()}

          <div ref={memberRef} style={{ position: 'relative', marginBottom: 16 }}>
            <input
              style={S.input}
              placeholder="Search for a person to add..."
              value={memberQ}
              onChange={e => { setMemberQ(e.target.value); setMemberDropdownOpen(true); }}
              onFocus={() => { if (memberQ) setMemberDropdownOpen(true); }}
            />
            {memberDropdownOpen && memberQ && (
              <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'absolute', left: 0, right: 0, zIndex: 10 }}>
                {eligibleMembers.length === 0 && (
                  <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons available</div>
                )}
                {eligibleMembers.slice(0, 8).map(p => (
                  <div key={p.id} style={S.dropdownItem}
                    onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                    onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                    onClick={() => {
                      const newMembers = [...memberIds, p.id];
                      setMemberIds(newMembers);
                      if (!primaryContactId) setPrimaryContactId(p.id);
                      setMemberQ(''); setMemberDropdownOpen(false);
                      setFieldErrors(prev => {
                        const n = new Set(prev);
                        if (newMembers.length >= 2) n.delete('hhMembers');
                        n.delete('hhPrimary');
                        return n;
                      });
                    }}>
                    {p.firstName} {p.lastName}
                  </div>
                ))}
              </div>
            )}
          </div>
          </div>

          <div style={{ ...S.btnRow, marginTop: 18 }}>
            <button style={{ ...S.btn, ...(editing && memberIds.length < 2 ? S.btnDanger : S.btnPrimary) }} onClick={handleSave}>{editing && memberIds.length < 2 ? 'Dissolve Household' : 'Save Household'}</button>
            <button style={{ ...S.btn, ...S.btnSec }} onClick={resetForm}>Cancel</button>
          </div>
        </>
      )}

      {/* Remove Member Confirmation Dialog */}
      {removeMemberTarget && (() => {
        const household = households.find(h => h.id === removeMemberTarget.householdId);
        if (!household) return null;
        const memberName = resolveName(removeMemberTarget.memberId);
        const isPrimary = removeMemberTarget.memberId === household.primaryContactId;
        const remainingAfter = household.memberIds.filter(id => id !== removeMemberTarget.memberId);
        const willDissolve = remainingAfter.length <= 1;

        return (
          <div style={S.overlay} onClick={() => setRemoveMemberTarget(null)}>
            <div style={S.dialog} onClick={e => e.stopPropagation()}>
              <h3 style={S.dialogTitle}>Remove Member</h3>
              <div style={S.dialogBody}>
                Remove <strong>{memberName}</strong> from <strong>{household.name}</strong>?
                {willDissolve && (
                  <div style={{ marginTop: 8, color: colors.danger }}>
                    This will leave fewer than 2 members. The household will be dissolved. The other member's address type will change from "Household" to "Home".
                  </div>
                )}
                {!willDissolve && (
                  <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>
                    <li>The household address will be removed from {memberName}'s record</li>
                    {isPrimary && <li>A new primary contact will be automatically assigned</li>}
                  </ul>
                )}
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setRemoveMemberTarget(null)}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmRemoveMember}>Remove</button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Delete Household Confirmation Dialog */}
      {deleteHouseholdTarget && (
        <div style={S.overlay} onClick={() => setDeleteHouseholdTarget(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete Household</h3>
            <div style={S.dialogBody}>
              Are you sure you want to delete <strong>{deleteHouseholdTarget.name}</strong>?
              {deleteHouseholdTarget.memberIds.length > 0 && (
                <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>
                  <li>All {deleteHouseholdTarget.memberIds.length} member(s) will be removed from this household</li>
                  <li>Members' primary address type will change from "Household" to "Home"</li>
                </ul>
              )}
              This action cannot be undone.
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setDeleteHouseholdTarget(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmDeleteHousehold}>Delete</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

