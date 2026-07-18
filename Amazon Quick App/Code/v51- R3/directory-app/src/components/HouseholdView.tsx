import React, { useState, useRef, useEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { Person, Household, Address, AddressSuggestion } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, formatAddr, suggestAddresses, useDebounce } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold } from '../storage';
import { COUNTRIES } from '../countryCodes';

interface HouseholdViewProps {
  households: Household[];
  allPersons: Person[];
  onReload: () => Promise<void>;
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

export function HouseholdView({ households, allPersons, onReload }: HouseholdViewProps) {
  const [editing, setEditing] = useState<Household | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());

  // Form state
  const [name, setName] = useState('');
  const [address, setAddress] = useState<Address>({ ...EMPTY_ADDR, label: 'Household' });
  const [memberIds, setMemberIds] = useState<string[]>([]);
  const [primaryContactId, setPrimaryContactId] = useState('');

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
    setMemberIds([]); setPrimaryContactId(''); setEditing(null); setShowForm(false); setError(''); setFieldErrors(new Set());
  };

  const openCreate = () => { resetForm(); setShowForm(true); };

  const openEdit = (h: Household) => {
    setEditing(h);
    setName(h.name);
    setAddress({ ...h.address });
    setMemberIds([...h.memberIds]);
    setPrimaryContactId(h.primaryContactId);
    setShowForm(true);
    setError('');
  };

  const handleSave = async () => {
    const errs = new Set<string>();
    if (!name.trim()) errs.add('hhName');
    if (!address.street.trim() && !address.city.trim()) errs.add('hhAddress');
    if (memberIds.length < 2) errs.add('hhMembers');
    if (!primaryContactId) errs.add('hhPrimary');
    if (primaryContactId && !memberIds.includes(primaryContactId)) errs.add('hhPrimary');

    if (errs.size > 0) {
      setFieldErrors(errs);
      setError('');
      // Scroll to and focus first invalid field
      if (errs.has('hhName')) { scrollToAndFocus(nameRef); return; }
      if (errs.has('hhAddress')) { scrollToAndFocus(addressSectionRef); return; }
      if (errs.has('hhMembers')) { scrollToAndFocus(membersSectionRef); return; }
      if (errs.has('hhPrimary')) { scrollToAndFocus(primaryRef); return; }
      return;
    }
    setFieldErrors(new Set());

    setError('');
    const id = editing?.id || uuidv4();
    const household: Household = { id, name: name.trim(), address, memberIds, primaryContactId };

    try {
      // If editing, handle members that were removed
      if (editing) {
        const removedIds = editing.memberIds.filter(mid => !memberIds.includes(mid));
        for (const mid of removedIds) {
          const member = await loadEntry(mid);
          if (member && member.type === 'person') {
            const addrs = member.addresses.map(a =>
              a.label === 'Household' ? { ...a, label: 'Home' } : a
            );
            await saveEntry({ ...member, householdId: '', addresses: addrs });
          }
        }
      }

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
      await onReload();
      resetForm();
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
      const remainingIds = household.memberIds.filter(id => id !== memberId);
      let newPrimary = household.primaryContactId;

      // Rule A: If removing primary contact, must have newPrimaryForRemoval
      if (memberId === household.primaryContactId) {
        if (!newPrimaryForRemoval) { setError('Please select a new primary contact.'); return; }
        newPrimary = newPrimaryForRemoval;
      }

      // Rule B: If this is the last member (remaining will be 0 after removal), revert addresses
      if (remainingIds.length === 0) {
        // Change address type from Household to Home for this member
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        // Delete household since no members remain
        await removeHousehold(householdId);
      } else if (remainingIds.length === 1) {
        // After removal only 1 member left — change their address from Household to Home, remove from household
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        const lastMemberId = remainingIds[0];
        const lastMember = await loadEntry(lastMemberId);
        if (lastMember && lastMember.type === 'person') {
          const addrs = lastMember.addresses.map(a =>
            a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...lastMember, householdId: '', addresses: addrs });
        }
        await removeHousehold(householdId);
      } else {
        // Normal removal: unlink member and change their Household address to Home
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
      }

      await onReload();
      setRemoveMemberTarget(null);
      setNewPrimaryForRemoval('');
      // If we're in the form, update state
      if (showForm && editing?.id === householdId) {
        if (remainingIds.length <= 1) { resetForm(); }
        else {
          setMemberIds(remainingIds);
          setPrimaryContactId(newPrimary);
          setEditing({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
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
      await onReload();
      setDeleteHouseholdTarget(null);
      if (showForm && editing?.id === household.id) resetForm();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  const resolveName = (id: string) => {
    const p = allPersons.find(x => x.id === id);
    return p ? getEntryName(p) : 'Unknown';
  };

  const eligibleMembers = allPersons.filter(p => {
    if (memberIds.includes(p.id)) return false;
    // Person must not be in another household
    const existingHousehold = households.find(h => h.memberIds.includes(p.id) && h.id !== editing?.id);
    if (existingHousehold) return false;
    return `${p.firstName} ${p.lastName}`.toLowerCase().includes(memberQ.toLowerCase());
  });

  return (
    <>
      {error && <div style={{ fontSize: 13, color: colors.danger, marginBottom: 14 }}>{error}</div>}

      {!showForm ? (
        <>
          <div style={S.btnRow}>
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={openCreate}>+ Create Household</button>
          </div>

          {households.length === 0 ? (
            <div style={S.emptyState}>No households yet. Create one to get started.</div>
          ) : (
            households.map(h => (
              <div key={h.id} style={{ ...S.card, cursor: 'default' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <strong style={{ fontSize: 16 }}>🏠 {h.name}</strong>
                    <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>
                      📍 {formatAddr(h.address)}
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
            ))
          )}
        </>
      ) : (
        <>
          <h2 style={{ marginBottom: 16 }}>{editing ? `Edit Household: ${editing.name}` : 'Create Household'}</h2>

          <div style={S.formGrid}>
            <div style={S.fieldFull}>
              <label style={S.label}>Household Name *</label>
              <input ref={nameRef} style={{ ...S.input, ...(fieldErrors.has('hhName') ? { borderColor: colors.danger } : {}) }} value={name} onChange={e => { setName(e.target.value); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhName'); return n; }); }} placeholder="e.g. The Smith Family" />
              {fieldErrors.has('hhName') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Household name is required</div>}
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
                      if (newMembers.length < 2) n.add('hhMembers');
                      else n.delete('hhMembers');
                      // If a valid primary is auto-assigned (or was already valid), clear hhPrimary
                      const effectivePrimary = primaryContactId === mid ? newMembers[0] || '' : primaryContactId;
                      if (effectivePrimary && newMembers.includes(effectivePrimary)) n.delete('hhPrimary');
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
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleSave}>Save Household</button>
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
        const isLast = remainingAfter.length <= 1;

        return (
          <div style={S.overlay} onClick={() => setRemoveMemberTarget(null)}>
            <div style={S.dialog} onClick={e => e.stopPropagation()}>
              <h3 style={S.dialogTitle}>Remove Member</h3>
              <div style={S.dialogBody}>
                Remove <strong>{memberName}</strong> from <strong>{household.name}</strong>?
                {isLast && (
                  <div style={{ marginTop: 8, color: colors.danger }}>
                    This will leave fewer than 2 members. The household will be dissolved and all remaining members' address type will change from "Household" to "Home".
                  </div>
                )}
                {isPrimary && !isLast && (
                  <div style={{ marginTop: 8 }}>
                    <strong>{memberName}</strong> is the primary contact. Please select a new primary:
                    <select style={{ ...S.input, marginTop: 6 }} value={newPrimaryForRemoval} onChange={e => setNewPrimaryForRemoval(e.target.value)}>
                      <option value="">— Select —</option>
                      {remainingAfter.map(mid => (
                        <option key={mid} value={mid}>{resolveName(mid)}</option>
                      ))}
                    </select>
                  </div>
                )}
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setRemoveMemberTarget(null)}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }}
                  disabled={isPrimary && !isLast && !newPrimaryForRemoval}
                  onClick={confirmRemoveMember}>Remove</button>
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

