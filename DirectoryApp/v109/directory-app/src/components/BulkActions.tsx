import React, { useState } from 'react';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName } from '../utils';
import { entryToVCard } from './VCardExport';

interface BulkActionsBarProps {
  selectedIds: Set<string>;
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  onClearSelection: () => void;
  onBulkDelete: (ids: string[]) => void;
  onBulkStatusChange: (ids: string[], status: 'active' | 'deceased' | 'closed') => void;
  onBulkAssignHousehold: (personIds: string[], householdId: string) => void;
  onError: (msg: string) => void;
}

export function BulkActionsBar({
  selectedIds, entries, allPersons, households, images,
  onClearSelection, onBulkDelete, onBulkStatusChange, onBulkAssignHousehold, onError,
}: BulkActionsBarProps) {
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showStatusPicker, setShowStatusPicker] = useState(false);
  const [showStatusConfirm, setShowStatusConfirm] = useState<'active' | 'deceased' | 'closed' | null>(null);
  const [showHouseholdPicker, setShowHouseholdPicker] = useState(false);
  const [showHouseholdConfirm, setShowHouseholdConfirm] = useState<Household | null>(null);
  const [householdSearch, setHouseholdSearch] = useState('');

  const count = selectedIds.size;
  if (count === 0) return null;

  const selectedEntries = entries.filter(e => selectedIds.has(e.id));
  const selectedPersons = selectedEntries.filter((e): e is Person => e.type === 'person');
  const selectedCompanies = selectedEntries.filter(e => e.type === 'company');

  const handleExportVCard = async () => {
    try {
      const vcards = selectedEntries.map(e => entryToVCard(e, images[e.id]));
      const combined = vcards.join('\r\n');
      await downloadFile('contacts-export.vcf', new Blob([combined], { type: 'text/vcard' }));
    } catch (e: any) {
      if (e?.message && !e.message.includes('declined')) onError(e.message);
    }
  };

  const getCascadeEffects = () => {
    const effects: string[] = [];
    const ids = new Set(selectedIds);
    for (const entry of selectedEntries) {
      if (entry.type === 'person') {
        if (entry.spouseId && !ids.has(entry.spouseId)) {
          effects.push(`Unlink spouse of ${getEntryName(entry)}`);
        }
        const parents = allPersons.filter(p => !ids.has(p.id) && p.childIds.includes(entry.id));
        if (parents.length > 0) effects.push(`Remove ${getEntryName(entry)} as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
        const linkedCompanies = entries.filter(e => e.type === 'company' && !ids.has(e.id) && e.contactPersonIds.includes(entry.id));
        if (linkedCompanies.length > 0) effects.push(`Remove ${getEntryName(entry)} as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
      }
    }
    return effects;
  };

  const filteredHouseholds = households.filter(h =>
    !householdSearch || h.name.toLowerCase().includes(householdSearch.toLowerCase())
  );

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

        {selectedPersons.length > 0 && households.length > 0 && (
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
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 4 }}>Side effects:</div>
                    <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, color: colors.textSec }}>
                      {effects.slice(0, 8).map((eff, i) => <li key={i}>{eff}</li>)}
                      {effects.length > 8 && <li>...and {effects.length - 8} more</li>}
                    </ul>
                  </div>
                ) : null;
              })()}
              <div style={{ marginTop: 10, fontSize: 13 }}>This action cannot be undone.</div>
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowDeleteConfirm(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => {
                setShowDeleteConfirm(false);
                onBulkDelete(Array.from(selectedIds));
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
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('active'); }}
                  style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px' }}>
                  ● Set to <strong>Active</strong>
                  <span style={{ fontSize: 11, color: colors.textSec, marginLeft: 8 }}>({count} entr{count === 1 ? 'y' : 'ies'})</span>
                </button>
                {selectedPersons.length > 0 && (
                  <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('deceased'); }}
                    style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px' }}>
                    ✝ Set persons to <strong>Deceased</strong>
                    <span style={{ fontSize: 11, color: colors.textSec, marginLeft: 8 }}>({selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''})</span>
                  </button>
                )}
                {selectedCompanies.length > 0 && (
                  <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('closed'); }}
                    style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px' }}>
                    🚫 Set companies to <strong>Closed</strong>
                    <span style={{ fontSize: 11, color: colors.textSec, marginLeft: 8 }}>({selectedCompanies.length} compan{selectedCompanies.length !== 1 ? 'ies' : 'y'})</span>
                  </button>
                )}
              </div>
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Status change confirmation */}
      {showStatusConfirm && (
        <div style={S.overlay} onClick={() => setShowStatusConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>⚡ Confirm Status Change</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                {showStatusConfirm === 'active' && <>Set <strong>{count}</strong> entr{count === 1 ? 'y' : 'ies'} to <strong>Active</strong>?</>}
                {showStatusConfirm === 'deceased' && <>Set <strong>{selectedPersons.length}</strong> person{selectedPersons.length !== 1 ? 's' : ''} to <strong>Deceased</strong>?</>}
                {showStatusConfirm === 'closed' && <>Set <strong>{selectedCompanies.length}</strong> compan{selectedCompanies.length !== 1 ? 'ies' : 'y'} to <strong>Closed</strong>?</>}
              </div>
              <div style={{ maxHeight: 150, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                {(showStatusConfirm === 'deceased' ? selectedPersons : showStatusConfirm === 'closed' ? selectedCompanies : selectedEntries).map(e => (
                  <div key={e.id} style={{ padding: '3px 0' }}>
                    {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                  </div>
                ))}
              </div>
              {showStatusConfirm === 'active' && (selectedPersons.some(p => p.status === 'deceased') || selectedCompanies.some(c => c.companyStatus === 'closed')) && (
                <div style={{ fontSize: 12, color: colors.textSec }}>
                  This will reactivate any deceased persons or closed companies in the selection.
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                const status = showStatusConfirm;
                setShowStatusConfirm(null);
                onBulkStatusChange(Array.from(selectedIds), status);
              }}>Confirm</button>
            </div>
          </div>
        </div>
      )}

      {/* Household assign picker */}
      {showHouseholdPicker && (
        <div style={S.overlay} onClick={() => setShowHouseholdPicker(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Assign to Household</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10, fontSize: 13 }}>
                Assign {selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''} to a household:
                {selectedCompanies.length > 0 && (
                  <span style={{ color: colors.textSec, marginLeft: 4 }}>
                    ({selectedCompanies.length} compan{selectedCompanies.length !== 1 ? 'ies' : 'y'} will be skipped)
                  </span>
                )}
              </div>
              <input
                style={{ ...S.input, marginBottom: 10 }}
                placeholder="Search households..."
                value={householdSearch}
                onChange={e => setHouseholdSearch(e.target.value)}
              />
              <div style={{ maxHeight: 200, overflowY: 'auto' }}>
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
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Household assign confirmation */}
      {showHouseholdConfirm && (
        <div style={S.overlay} onClick={() => setShowHouseholdConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Confirm Household Assignment</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                Assign <strong>{selectedPersons.length}</strong> person{selectedPersons.length !== 1 ? 's' : ''} to <strong>🏠 {showHouseholdConfirm.name}</strong>?
              </div>
              <div style={{ maxHeight: 150, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                {selectedPersons.map(p => {
                  const currentHousehold = households.find(h => h.memberIds.includes(p.id));
                  return (
                    <div key={p.id} style={{ padding: '3px 0', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span>👤 {getEntryName(p)}</span>
                      {currentHousehold && currentHousehold.id !== showHouseholdConfirm.id && (
                        <span style={{ fontSize: 11, color: colors.textSec }}>
                          (moving from {currentHousehold.name})
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
              {selectedPersons.some(p => {
                const curr = households.find(h => h.memberIds.includes(p.id));
                return curr && curr.id !== showHouseholdConfirm.id;
              }) && (
                <div style={{ fontSize: 12, color: colors.textSec }}>
                  Persons currently in other households will be moved to the new one.
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                const hId = showHouseholdConfirm.id;
                setShowHouseholdConfirm(null);
                onBulkAssignHousehold(selectedPersons.map(p => p.id), hId);
              }}>Assign</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

