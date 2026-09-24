import React, { useState, useEffect, useRef } from 'react';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import type { DirectoryEntry, Person, Household } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, suggestAddresses, useDebounce, selectNewPrimaryContact } from '../utils';
import type { AddressSuggestion } from '../types';
import { entryToVCard } from './VCardExport';

interface BulkActionsBarProps {
  selectedIds: Set<string>;
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  onClearSelection: () => void;
  onBulkDelete: (ids: string[]) => Promise<number | null>;
  onBulkStatusChange: (ids: string[], status: 'active' | 'deceased' | 'closed') => void;
  onBulkAssignHousehold: (personIds: string[], householdId: string) => void;
  onCreateAndAssignHousehold: (personIds: string[], household: Household) => void;
  onError: (msg: string) => void;
  onToast: (msg: string) => void;
}

export function BulkActionsBar({
  selectedIds, entries, allPersons, households, images,
  onClearSelection, onBulkDelete, onBulkStatusChange, onBulkAssignHousehold, onCreateAndAssignHousehold, onError, onToast,
}: BulkActionsBarProps) {
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showStatusPicker, setShowStatusPicker] = useState(false);
  const [showStatusConfirm, setShowStatusConfirm] = useState<'active' | 'deceased' | 'closed' | null>(null);
  const [showHouseholdPicker, setShowHouseholdPicker] = useState(false);
  const [showHouseholdConfirm, setShowHouseholdConfirm] = useState<Household | null>(null);
  const [householdSearch, setHouseholdSearch] = useState('');
  const [showCreateHousehold, setShowCreateHousehold] = useState(false);
  const [newHhName, setNewHhName] = useState('');
  const [newHhStreet, setNewHhStreet] = useState('');
  const [newHhStreet2, setNewHhStreet2] = useState('');
  const [newHhCity, setNewHhCity] = useState('');
  const [newHhState, setNewHhState] = useState('');
  const [newHhZip, setNewHhZip] = useState('');
  const [newHhError, setNewHhError] = useState('');
  const [newHhPrimary, setNewHhPrimary] = useState('');
  const [addrSuggestions, setAddrSuggestions] = useState<AddressSuggestion[]>([]);
  const debouncedStreet = useDebounce(newHhStreet, 400);
  const addrWrapRef = useRef<HTMLDivElement>(null);

  // Fetch address suggestions when street input changes
  useEffect(() => {
    if (showCreateHousehold && debouncedStreet.length >= 3) {
      suggestAddresses(debouncedStreet).then(setAddrSuggestions);
    } else {
      setAddrSuggestions([]);
    }
  }, [debouncedStreet, showCreateHousehold]);

  // Close suggestions on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (addrWrapRef.current && !addrWrapRef.current.contains(e.target as Node)) setAddrSuggestions([]);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const count = selectedIds.size;
  if (count === 0) return null;

  const selectedEntries = entries.filter(e => selectedIds.has(e.id));
  const selectedPersons = selectedEntries.filter((e): e is Person => e.type === 'person');
  const selectedCompanies = selectedEntries.filter(e => e.type === 'company');

  const hasPersons = selectedPersons.length > 0;
  const hasCompanies = selectedCompanies.length > 0;
  const isMixed = hasPersons && hasCompanies;
  const isPersonsOnly = hasPersons && !hasCompanies;
  const isCompaniesOnly = hasCompanies && !hasPersons;

  // Compute which entries already have the target status
  const getStatusBreakdown = (status: 'active' | 'deceased' | 'closed') => {
    let alreadyCount = 0;
    const idsToChange: string[] = [];
    for (const e of selectedEntries) {
      if (e.type === 'person') {
        const current = e.status || 'active';
        const target = status === 'closed' ? 'active' : status;
        if (current === target) alreadyCount++;
        else idsToChange.push(e.id);
      } else {
        const current = e.companyStatus || 'active';
        const target = status === 'deceased' ? 'active' : status;
        if (current === target) alreadyCount++;
        else idsToChange.push(e.id);
      }
    }
    return { alreadyCount, willChange: idsToChange.length, idsToChange };
  };

  const handleExportVCard = async () => {
    try {
      const vcards = selectedEntries.map(e => entryToVCard(e, images[e.id]));
      const combined = vcards.join('\r\n');
      await downloadFile('contacts-export.vcf', new Blob([combined], { type: 'text/vcard' }));
      onToast(`📇 ${selectedEntries.length} contact${selectedEntries.length !== 1 ? 's' : ''} exported`);
    } catch (e: any) {
      if (e?.message && !e.message.includes('declined')) onError(e.message);
    }
  };

  const getCascadeEffects = () => {
    const effects: { icon: string; text: string }[] = [];
    const ids = new Set(selectedIds);
    // Track household impacts to avoid duplicates when multiple selected persons share a household
    const processedHouseholds = new Map<string, string[]>();
    for (const entry of selectedEntries) {
      if (entry.type === 'person') {
        if (entry.spouseId && !ids.has(entry.spouseId)) {
          effects.push({ icon: '💍', text: `Unlink spouse of ${getEntryName(entry)}.` });
        }
        const parents = allPersons.filter(p => !ids.has(p.id) && p.childIds.includes(entry.id));
        if (parents.length > 0) effects.push({ icon: '🧒', text: `Remove ${getEntryName(entry)} as child from ${parents.map(p => getEntryName(p)).join(', ')}.` });
        const linkedCompanies = entries.filter(e => e.type === 'company' && !ids.has(e.id) && e.contactPersonIds.includes(entry.id));
        if (linkedCompanies.length > 0) effects.push({ icon: '🏢', text: `Remove ${getEntryName(entry)} as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}.` });
        if (entry.householdId) {
          const existing = processedHouseholds.get(entry.householdId);
          if (existing) { existing.push(entry.id); }
          else { processedHouseholds.set(entry.householdId, [entry.id]); }
        }
      }
    }
    // Process each affected household once
    for (const [hhId, removedIds] of processedHouseholds) {
      const hh = households.find(h => h.id === hhId);
      if (!hh) continue;
      const remainingIds = hh.memberIds.filter(mid => !ids.has(mid));
      const removedNames = removedIds.map(rid => { const p = allPersons.find(x => x.id === rid); return p ? getEntryName(p) : 'Unknown'; });
      if (remainingIds.length < 2) {
        effects.push({ icon: '🏚️', text: `${hh.name} will be dissolved (fewer than 2 members remaining).` });
        if (remainingIds.length === 1) {
          const lastPerson = allPersons.find(p => p.id === remainingIds[0]);
          if (lastPerson) effects.push({ icon: '🏠', text: `${getEntryName(lastPerson)}'s address label will change from "Household" to "Home".` });
        }
      } else {
        effects.push({ icon: '🏠', text: `Remove ${removedNames.join(' and ')} from ${hh.name} (${remainingIds.length} members will remain).` });
        if (removedIds.includes(hh.primaryContactId)) {
          const newPrimary = selectNewPrimaryContact(hh.primaryContactId, remainingIds, allPersons);
          const newPrimaryPerson = allPersons.find(p => p.id === newPrimary);
          if (newPrimaryPerson) effects.push({ icon: '★', text: `${hh.name}'s primary contact will change to ${getEntryName(newPrimaryPerson)}.` });
        }
      }
    }
    return effects;
  };

  const filteredHouseholds = households.filter(h =>
    !householdSearch || h.name.toLowerCase().includes(householdSearch.toLowerCase())
  );

  /** Compute side effects when moving persons out of their current households */
  const getHouseholdMoveSideEffects = (movedPersons: Person[]) => {
    const effects: { icon: string; text: string }[] = [];
    const oldHouseholdImpact = new Map<string, { household: Household; removedIds: string[] }>();
    for (const p of movedPersons) {
      const oldHh = households.find(h => h.memberIds.includes(p.id));
      if (oldHh) {
        const existing = oldHouseholdImpact.get(oldHh.id);
        if (existing) { existing.removedIds.push(p.id); }
        else { oldHouseholdImpact.set(oldHh.id, { household: oldHh, removedIds: [p.id] }); }
      }
    }
    for (const [, { household: oldHh, removedIds }] of oldHouseholdImpact) {
      const remainingIds = oldHh.memberIds.filter(mid => !removedIds.includes(mid));
      const removedNames = removedIds.map(rid => { const p = allPersons.find(x => x.id === rid); return p ? getEntryName(p) : 'Unknown'; });
      if (remainingIds.length < 2) {
        effects.push({ icon: '🏚️', text: `${oldHh.name} will be dissolved (${removedNames.join(' and ')} leaving makes fewer than 2 members).` });
        if (remainingIds.length === 1) {
          const lastPerson = allPersons.find(p => p.id === remainingIds[0]);
          if (lastPerson) {
            effects.push({ icon: '🏠', text: `${getEntryName(lastPerson)}'s address label will change from "Household" to "Home".` });
          }
        }
      } else {
        effects.push({ icon: '🏠', text: `Remove ${removedNames.join(' and ')} from ${oldHh.name} (${remainingIds.length} members will remain).` });
        const primaryBeingRemoved = removedIds.includes(oldHh.primaryContactId);
        if (primaryBeingRemoved) {
          const newPrimary = selectNewPrimaryContact(oldHh.primaryContactId, remainingIds, allPersons);
          const newPrimaryPerson = allPersons.find(p => p.id === newPrimary);
          if (newPrimaryPerson) {
            effects.push({ icon: '★', text: `${oldHh.name}'s primary contact will change to ${getEntryName(newPrimaryPerson)}.` });
          }
        }
      }
    }
    return effects;
  };

  return (
    <>
      {/* Floating action bar */}
      <div style={{
        position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)',
        background: '#1a1a2e', color: '#fff', borderRadius: 12,
        padding: '12px 20px', display: 'flex', alignItems: 'center', gap: 14,
        boxShadow: '0 8px 32px rgba(0,0,0,.3)', zIndex: 50,
        fontSize: 13, maxWidth: '90vw', flexWrap: 'wrap',
      }}>
        <span style={{ fontWeight: 700, whiteSpace: 'nowrap' }}>
          {count} selected
        </span>

        <div style={{ width: 1, height: 20, background: 'rgba(255,255,255,.2)' }} />

        <button onClick={handleExportVCard} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
        }}>📇 Export vCard</button>

        <button onClick={() => setShowStatusPicker(true)} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
        }}>⚡ Change Status</button>

        {isPersonsOnly && (
          <button onClick={() => { setShowHouseholdPicker(true); setHouseholdSearch(''); }} style={{
            ...S.btn, padding: '6px 14px', fontSize: 12,
            background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
          }}>🏠 Assign Household</button>
        )}

        <button onClick={() => setShowDeleteConfirm(true)} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(217,48,37,.8)', color: '#fff', border: 'none',
        }}>🗑️ Delete</button>

        <div style={{ width: 1, height: 20, background: 'rgba(255,255,255,.2)' }} />

        <button onClick={onClearSelection} style={{
          ...S.btn, padding: '6px 12px', fontSize: 12,
          background: 'transparent', color: 'rgba(255,255,255,.7)', border: 'none',
          textDecoration: 'underline',
        }}>Clear</button>
      </div>

      {/* Bulk delete confirmation */}
      {showDeleteConfirm && (
        <div style={S.overlay} onClick={() => setShowDeleteConfirm(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete {count} Entr{count === 1 ? 'y' : 'ies'}</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                Are you sure you want to delete the following?
              </div>
              <div style={{ maxHeight: 150, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                {selectedEntries.map(e => (
                  <div key={e.id} style={{ padding: '3px 0' }}>
                    {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                  </div>
                ))}
              </div>
              {(() => {
                const effects = getCascadeEffects();
                return effects.length > 0 ? (
                  <div style={{ background: '#fff8e1', border: '1px solid #ffe082', borderRadius: 8, padding: '10px 14px', marginBottom: 10, fontSize: 13, lineHeight: 1.6 }}>
                    <div style={{ fontWeight: 600, marginBottom: 4, color: '#e65100' }}>⚠ Pending changes on save:</div>
                    {effects.slice(0, 8).map((e, i) => (
                      <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                        <span style={{ flexShrink: 0 }}>{e.icon}</span>
                        <span style={{ color: colors.text }}>{e.text}</span>
                      </div>
                    ))}
                    {effects.length > 8 && (
                      <div style={{ color: colors.textSec, marginTop: 2 }}>...and {effects.length - 8} more</div>
                    )}
                  </div>
                ) : null;
              })()}
              <div style={{ marginTop: 10, fontSize: 13 }}>This action cannot be undone.</div>
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowDeleteConfirm(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={async () => {
                setShowDeleteConfirm(false);
                const count = await onBulkDelete(Array.from(selectedIds));
                if (count) onToast(`🗑️ ${count} entr${count === 1 ? 'y' : 'ies'} deleted`);
              }}>Delete {count}</button>
            </div>
          </div>
        </div>
      )}

      {/* Status change picker */}
      {showStatusPicker && (
        <div style={S.overlay} onClick={() => setShowStatusPicker(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>⚡ Change Status</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 12 }}>
                Change status for {count} selected entr{count === 1 ? 'y' : 'ies'}:
                {isMixed && (
                  <div style={{ fontSize: 12, color: colors.textSec, marginTop: 4 }}>
                    ({selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''}, {selectedCompanies.length} compan{selectedCompanies.length !== 1 ? 'ies' : 'y'})
                  </div>
                )}
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {(() => {
                  const b = getStatusBreakdown('active');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('active'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>● Active</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Active`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Active` : ''}`}
                      </div>
                    </button>
                  );
                })()}
                {!hasCompanies && (() => {
                  const b = getStatusBreakdown('deceased');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('deceased'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>✝ Deceased</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Deceased`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Deceased` : ''}`}
                      </div>
                    </button>
                  );
                })()}
                {!hasPersons && (() => {
                  const b = getStatusBreakdown('closed');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('closed'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>🚫 Closed</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Closed`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Closed` : ''}`}
                      </div>
                    </button>
                  );
                })()}
              </div>
              {isMixed && (
                <div style={{ fontSize: 12, color: colors.textSec, marginTop: 12, fontStyle: 'italic' }}>
                  Only statuses valid for both persons and companies are shown.
                </div>
              )}
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Status change confirmation */}
      {showStatusConfirm && (() => {
        const b = getStatusBreakdown(showStatusConfirm);
        const affectedEntries = selectedEntries.filter(e => b.idsToChange.includes(e.id));
        const skippedEntries = selectedEntries.filter(e => !b.idsToChange.includes(e.id));
        return (
        <div style={S.overlay} onClick={() => setShowStatusConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>⚡ Confirm Status Change</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                {b.willChange} of {count} selected entr{count === 1 ? 'y' : 'ies'} will change to <strong>{showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'}</strong>
                {b.alreadyCount > 0 && <span style={{ color: colors.textSec }}> — {b.alreadyCount} already {showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'}</span>}
              </div>
              {affectedEntries.length > 0 && (
                <div style={{ maxHeight: 120, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                  {affectedEntries.map(e => (
                    <div key={e.id} style={{ padding: '3px 0' }}>
                      {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                    </div>
                  ))}
                </div>
              )}
              {skippedEntries.length > 0 && (
                <div style={{ fontSize: 12, color: colors.textSec, marginBottom: 10 }}>
                  <div style={{ fontWeight: 600, marginBottom: 2 }}>Already {showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'} (no change):</div>
                  <div style={{ maxHeight: 60, overflowY: 'auto' }}>
                    {skippedEntries.map(e => (
                      <div key={e.id} style={{ padding: '2px 0' }}>
                        {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                      </div>
                    ))}
                  </div>
                </div>
              )}
              {showStatusConfirm === 'active' && affectedEntries.some(e => (e.type === 'person' && e.status === 'deceased') || (e.type === 'company' && e.companyStatus === 'closed')) && (
                <div style={{ fontSize: 12, color: colors.textSec }}>
                  This will reactivate any deceased persons or closed companies in the selection.
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                const status = showStatusConfirm;
                const n = b.willChange;
                setShowStatusConfirm(null);
                onBulkStatusChange(b.idsToChange, status);
                onToast(`✅ ${n} entr${n === 1 ? 'y' : 'ies'} updated to ${status}`);
              }}>Change {b.willChange}</button>
            </div>
          </div>
        </div>
        );
      })()}

      {/* Household assign picker */}
      {showHouseholdPicker && (
        <div style={S.overlay} onClick={() => setShowHouseholdPicker(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Assign to Household</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10, fontSize: 13 }}>
                Assign {selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''} to a household:
              </div>

              {/* Create New Household button */}
              {(() => {
                const canCreate = selectedPersons.length >= 2;
                return (
                  <div
                    style={{
                      padding: '10px 12px', borderRadius: 6, marginBottom: 8,
                      border: `2px dashed ${canCreate ? colors.primary : colors.border}`,
                      cursor: canCreate ? 'pointer' : 'default',
                      background: canCreate ? '#f0f7ff' : '#f5f5f5', textAlign: 'center',
                      opacity: canCreate ? 1 : 0.6,
                    }}
                    onMouseEnter={ev => { if (canCreate) ev.currentTarget.style.background = '#e3effd'; }}
                    onMouseLeave={ev => { if (canCreate) ev.currentTarget.style.background = '#f0f7ff'; }}
                    onClick={() => {
                      if (!canCreate) return;
                      setShowHouseholdPicker(false);
                      setShowCreateHousehold(true);
                      setNewHhName(''); setNewHhStreet(''); setNewHhStreet2('');
                      setNewHhCity(''); setNewHhState(''); setNewHhZip(''); setNewHhError('');
                      setNewHhPrimary(selectedPersons[0]?.id || '');
                    }}>
                    <div style={{ fontWeight: 600, fontSize: 13, color: canCreate ? colors.primary : colors.textSec }}>+ Create New Household</div>
                    <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                      {canCreate
                        ? 'Create a household and assign selected persons'
                        : 'Select at least 2 persons to create a household'}
                    </div>
                  </div>
                );
              })()}

              {households.length > 0 && (
                <>
                  <input
                    style={{ ...S.input, marginBottom: 10 }}
                    placeholder="Search households..."
                    value={householdSearch}
                    onChange={e => setHouseholdSearch(e.target.value)}
                  />
                  <div style={{ maxHeight: 180, overflowY: 'auto' }}>
                    {filteredHouseholds.length === 0 ? (
                      <div style={{ fontSize: 13, color: colors.textSec, padding: 10 }}>No households found.</div>
                    ) : (
                      filteredHouseholds.map(h => (
                        <div key={h.id}
                          style={{
                            padding: '10px 12px', borderRadius: 6, marginBottom: 4,
                            border: `1px solid ${colors.border}`, cursor: 'pointer',
                            background: '#fff',
                          }}
                          onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)}
                          onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')}
                          onClick={() => {
                            setShowHouseholdPicker(false);
                            setShowHouseholdConfirm(h);
                          }}>
                          <div style={{ fontWeight: 600, fontSize: 13 }}>🏠 {h.name}</div>
                          <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                            {h.memberIds.length} member{h.memberIds.length !== 1 ? 's' : ''}
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </>
              )}
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Create new household form */}
      {showCreateHousehold && (
        <div style={S.overlay} onClick={() => setShowCreateHousehold(false)}>
          <div style={{ ...S.dialog, maxWidth: 480 }} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Create New Household & Assign</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 12, fontSize: 13 }}>
                Create a household and assign <strong>{selectedPersons.length}</strong> person{selectedPersons.length !== 1 ? 's' : ''} to it.
                All members will share the household address.
              </div>

              {(() => {
                const movedPersons = selectedPersons.filter(p => {
                  const curr = households.find(h => h.memberIds.includes(p.id));
                  return !!curr;
                });
                if (movedPersons.length === 0) return null;
                const effects = getHouseholdMoveSideEffects(movedPersons);
                return (
                  <div style={{ background: '#fff8e1', border: '1px solid #ffe082', borderRadius: 8, padding: '10px 14px', marginBottom: 10, fontSize: 13, lineHeight: 1.6 }}>
                    <div style={{ fontWeight: 600, marginBottom: 4, color: '#e65100' }}>⚠ Pending changes on save:</div>
                    {movedPersons.map(p => {
                      const curr = households.find(h => h.memberIds.includes(p.id));
                      return (
                        <div key={p.id} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                          <span style={{ flexShrink: 0 }}>👤</span>
                          <span style={{ color: colors.text }}>{getEntryName(p)} will be moved from {curr!.name}.</span>
                        </div>
                      );
                    })}
                    {effects.map((e, i) => (
                      <div key={`eff-${i}`} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                        <span style={{ flexShrink: 0 }}>{e.icon}</span>
                        <span style={{ color: colors.text }}>{e.text}</span>
                      </div>
                    ))}
                  </div>
                );
              })()}

              {newHhError && <div style={{ color: colors.danger, fontSize: 12, marginBottom: 10 }}>{newHhError}</div>}

              <div style={{ marginBottom: 10 }}>
                <label style={S.label}>Household Name *</label>
                <input style={S.input} placeholder="e.g. Smith Family"
                  value={newHhName} onChange={e => { setNewHhName(e.target.value); setNewHhError(''); }} />
              </div>

              <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Address *</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ position: 'relative' }} ref={addrWrapRef}>
                  <input style={S.input} placeholder="Start typing to auto-suggest..." value={newHhStreet}
                    onChange={e => setNewHhStreet(e.target.value)} />
                  {addrSuggestions.length > 0 && (
                    <div style={S.addrDropdown}>
                      {addrSuggestions.map((s, i) => (
                        <div key={i} style={S.addrItem}
                          onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                          onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                          onClick={() => {
                            setNewHhStreet(s.street);
                            setNewHhCity(s.city);
                            setNewHhState(s.state);
                            setNewHhZip(s.zip);
                            setAddrSuggestions([]);
                          }}>
                          {s.street}, {s.city}, {s.state} {s.zip}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
                <input style={S.input} placeholder="Apt, Suite, Floor, etc. (optional)" value={newHhStreet2} onChange={e => setNewHhStreet2(e.target.value)} />
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                  <input style={S.input} placeholder="City" value={newHhCity} onChange={e => setNewHhCity(e.target.value)} />
                  <input style={S.input} placeholder="State" value={newHhState} onChange={e => setNewHhState(e.target.value)} />
                </div>
                <input style={{ ...S.input, maxWidth: 140 }} placeholder="ZIP" value={newHhZip} onChange={e => setNewHhZip(e.target.value)} />
              </div>

              <div style={{ marginTop: 12, fontSize: 12, color: colors.textSec }}>
                <strong>Members to assign:</strong>
              </div>
              <div style={{ maxHeight: 100, overflowY: 'auto', marginTop: 4, fontSize: 13 }}>
                {selectedPersons.map(p => (
                  <div key={p.id} style={{ padding: '2px 4px', borderRadius: 4, background: p.id === newHhPrimary ? '#c6f0c2' : 'transparent' }}>
                    👤 {getEntryName(p)}{p.id === newHhPrimary && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 6 }}>★ Primary</span>}
                  </div>
                ))}
              </div>

              <div style={{ marginTop: 10, marginBottom: 4 }}>
                <label style={S.label}>Primary Contact *</label>
                <select style={S.input} value={newHhPrimary} onChange={e => setNewHhPrimary(e.target.value)}>
                  {selectedPersons.map(p => (
                    <option key={p.id} value={p.id}>{getEntryName(p)}</option>
                  ))}
                </select>
              </div>
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowCreateHousehold(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                if (!newHhName.trim()) { setNewHhError('Household name is required.'); return; }
                if (households.some(h => h.name.trim().toLowerCase() === newHhName.trim().toLowerCase())) { setNewHhError('A household with this name already exists.'); return; }
                if (!newHhStreet.trim()) { setNewHhError('Address is required — a household must have a shared address.'); return; }
                const newHousehold: Household = {
                  id: uuidv4(),
                  name: newHhName.trim(),
                  address: {
                    ...EMPTY_ADDR,
                    street: newHhStreet.trim(),
                    street2: newHhStreet2.trim(),
                    city: newHhCity.trim(),
                    state: newHhState.trim(),
                    zip: newHhZip.trim(),
                    label: 'Household',
                  },
                  memberIds: selectedPersons.map(p => p.id),
                  primaryContactId: newHhPrimary || selectedPersons[0]?.id || '',
                };
                setShowCreateHousehold(false);
                onCreateAndAssignHousehold(selectedPersons.map(p => p.id), newHousehold);
                onToast(`🏠 ${newHhName.trim()} created with ${selectedPersons.length} member${selectedPersons.length !== 1 ? 's' : ''}`);
              }}>Create & Assign</button>
            </div>
          </div>
        </div>
      )}

      {/* Household assign confirmation */}
      {showHouseholdConfirm && (() => {
        const targetId = showHouseholdConfirm.id;
        const alreadyInTarget = selectedPersons.filter(p => p.householdId === targetId);
        const willChange = selectedPersons.filter(p => p.householdId !== targetId);

        // Compute side effects for persons being moved from other households
        const movedFromOther = willChange.filter(p => {
          const oldHh = households.find(h => h.memberIds.includes(p.id));
          return oldHh && oldHh.id !== targetId;
        });
        const sideEffects = getHouseholdMoveSideEffects(movedFromOther);

        // Address sync effect
        if (willChange.length > 0) {
          const addrSubject = willChange.length === 1 ? getEntryName(willChange[0]) + "'s" : willChange.length + " persons'";
          sideEffects.push({ icon: '📍', text: `${addrSubject} primary address will sync to ${showHouseholdConfirm.name}'s household address.` });
        }

        return (
        <div style={S.overlay} onClick={() => setShowHouseholdConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Confirm Household Assignment</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                {willChange.length === 0
                  ? <>All <strong>{selectedPersons.length}</strong> selected person{selectedPersons.length !== 1 ? 's' : ''} already belong{selectedPersons.length === 1 ? 's' : ''} to <strong>🏠 {showHouseholdConfirm.name}</strong>.</>
                  : <><strong>{willChange.length}</strong> of {selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''} will be assigned to <strong>🏠 {showHouseholdConfirm.name}</strong>
                    {alreadyInTarget.length > 0 && <span style={{ color: colors.textSec }}> — {alreadyInTarget.length} already in this household</span>}
                  </>}
              </div>
              {willChange.length > 0 && (
                <div style={{ maxHeight: 120, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                  {willChange.map(p => {
                    const currentHousehold = households.find(h => h.memberIds.includes(p.id));
                    return (
                      <div key={p.id} style={{ padding: '3px 0', display: 'flex', alignItems: 'center', gap: 6 }}>
                        <span>👤 {getEntryName(p)}</span>
                        {currentHousehold && currentHousehold.id !== targetId && (
                          <span style={{ fontSize: 11, color: colors.textSec }}>
                            (moving from {currentHousehold.name})
                          </span>
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
              {alreadyInTarget.length > 0 && (
                <div style={{ fontSize: 12, color: colors.textSec, marginBottom: 10 }}>
                  <div style={{ fontWeight: 600, marginBottom: 2 }}>Already in {showHouseholdConfirm.name} (no change):</div>
                  <div style={{ maxHeight: 60, overflowY: 'auto' }}>
                    {alreadyInTarget.map(p => (
                      <div key={p.id} style={{ padding: '2px 0' }}>👤 {getEntryName(p)}</div>
                    ))}
                  </div>
                </div>
              )}
              {sideEffects.length > 0 && (
                <div style={{ background: '#fff8e1', border: '1px solid #ffe082', borderRadius: 8, padding: '10px 14px', marginBottom: 10, fontSize: 13, lineHeight: 1.6 }}>
                  <div style={{ fontWeight: 600, marginBottom: 4, color: '#e65100' }}>⚠ Pending changes on save:</div>
                  {sideEffects.map((s, i) => (
                    <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'baseline' }}>
                      <span style={{ flexShrink: 0 }}>{s.icon}</span>
                      <span style={{ color: colors.text }}>{s.text}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary, ...(willChange.length === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}
                disabled={willChange.length === 0}
                onClick={() => {
                  const hId = showHouseholdConfirm.id;
                  const hName = showHouseholdConfirm.name;
                  const n = willChange.length;
                  setShowHouseholdConfirm(null);
                  onBulkAssignHousehold(willChange.map(p => p.id), hId);
                  onToast(`🏠 ${n} person${n !== 1 ? 's' : ''} assigned to ${hName}`);
                }}>Assign {willChange.length}</button>
            </div>
          </div>
        </div>
        );
      })()}
    </>
  );
}

