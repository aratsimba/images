import React from 'react';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr, calculateAge } from '../utils';
import { ProfileImage } from '../components/ProfileImage';
import { FamilyTree } from '../components/FamilyTree';
import { CollapsibleSection } from '../components/CollapsibleSection';
import { downloadVCard } from '../components/VCardExport';

interface Props {
  entry: DirectoryEntry;
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  collapsedSections: Set<string>;
  toggleSection: (id: string) => void;
  setSelectedId: (id: string) => void;
  setView: (v: any) => void;
  onEdit: () => void;
  onDelete: () => void;
  setError: (msg: string) => void;
}

export function DetailView({ entry, entries, allPersons, households, images, collapsedSections, toggleSection, setSelectedId, setView, onEdit, onDelete, setError }: Props) {
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };

  return (
    <>
      <div style={S.btnRow}>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('list'); setSelectedId(''); }}>← Back</button>
        <button style={{ ...S.btn, ...S.btnPrimary }} onClick={onEdit}>Edit</button>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={async () => {
          try { await downloadVCard(entry, images[entry.id]); }
          catch (e: any) { if (e?.message && !e.message.includes('declined')) setError(e.message); }
        }}>📇 Export vCard</button>
        <button style={{ ...S.btn, ...S.btnDanger }} onClick={onDelete}>Delete</button>
      </div>

      <div style={{ ...S.card, cursor: 'default', ...((entry.type === 'person' && entry.status === 'deceased') || (entry.type === 'company' && entry.companyStatus === 'closed') ? { borderLeft: '4px solid #9e9e9e' } : {}) }}>
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
          <div style={{ marginRight: 14 }}>
            <ProfileImage imageUrl={images[entry.id] || null} size={64} fallback={entry.type === 'person' ? '👤' : '🏢'} />
          </div>
          <div>
            <h2 style={{ margin: 0, ...((entry.type === 'person' && entry.status === 'deceased') || (entry.type === 'company' && entry.companyStatus === 'closed') ? { color: colors.textSec } : {}) }}>{getEntryName(entry)}</h2>
            {entry.type === 'person' && entry.status === 'deceased' && <span style={{ ...S.badge, marginTop: 4, background: '#e0e0e0', color: '#616161' }}>✝ Deceased{entry.deceasedDate ? ` · ${entry.deceasedDate}` : ''}</span>}
            {entry.type === 'company' && entry.companyStatus === 'closed' && <span style={{ ...S.badge, marginTop: 4, background: '#e0e0e0', color: '#616161' }}>🚫 Closed{entry.closedDate ? ` · ${entry.closedDate}` : ''}</span>}
            {entry.type === 'company' && <span style={{ ...S.badge, marginTop: 4, background: '#fce8e6', color: colors.danger }}>company</span>}
            {entry.type === 'company' && entry.industry && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{entry.industry}</span>}
          </div>
        </div>

        {entry.type === 'company' && entry.website && (
          <CollapsibleSection id="website" title="Website" collapsed={collapsedSections.has('website')} onToggle={() => toggleSection('website')}>
            <div style={{ fontSize: 14 }}><a href={entry.website} target="_blank" rel="noopener noreferrer" style={{ color: colors.primary, textDecoration: 'underline' }}>{entry.website}</a></div>
          </CollapsibleSection>
        )}

        {entry.type === 'person' && (entry.gender || entry.birthday) && (
          <CollapsibleSection id="personal-info" title="Personal Information" collapsed={collapsedSections.has('personal-info')} onToggle={() => toggleSection('personal-info')}>
            {entry.gender && <div style={S.detailRow}><span style={S.detailLabel}>Gender</span><span>{entry.gender}</span></div>}
            {entry.birthday && <div style={S.detailRow}><span style={S.detailLabel}>Birthday</span><span>{entry.birthday}{calculateAge(entry.birthday) !== null && ` (Age ${calculateAge(entry.birthday)})`}</span></div>}
          </CollapsibleSection>
        )}

        <CollapsibleSection id="emails" title="Email Addresses" collapsed={collapsedSections.has('emails')} onToggle={() => toggleSection('emails')}>
          {entry.emails.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.emails.map((em, i) => (
              <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{em.label}</span>
                <span>{em.address}</span>
                {em.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
              </div>
            ))}
        </CollapsibleSection>

        <CollapsibleSection id="phones" title="Phone Numbers" collapsed={collapsedSections.has('phones')} onToggle={() => toggleSection('phones')}>
          {entry.phones.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.phones.map((ph, i) => (
              <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{ph.label}</span>
                <span>{ph.countryCode || '+1'} {formatPhoneDisplay(ph.number)}</span>
                {ph.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
              </div>
            ))}
        </CollapsibleSection>

        <CollapsibleSection id="addresses" title="Addresses" collapsed={collapsedSections.has('addresses')} onToggle={() => toggleSection('addresses')}>
          {entry.addresses.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.addresses.map((addr, i) => (
              <div key={i} style={{ padding: '8px 12px', marginBottom: 6, borderRadius: 6, border: `1px solid ${colors.border}`, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                  <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{addr.label}</span>
                  {addr.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                </div>
                <div style={{ fontSize: 14 }}>{formatAddr(addr)}</div>
              </div>
            ))}
        </CollapsibleSection>

        {entry.type === 'person' && (
          <>
            <CollapsibleSection id="relationships" title="Relationships" collapsed={collapsedSections.has('relationships')} onToggle={() => toggleSection('relationships')}>
              <div style={S.detailRow}><span style={S.detailLabel}>Spouse</span><span>{entry.spouseId ? <span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(entry.spouseId)}>{resolveName(entry.spouseId)}</span> : '—'}</span></div>
              {entry.weddingAnniversary && <div style={S.detailRow}><span style={S.detailLabel}>Anniversary</span><span>💍 {entry.weddingAnniversary}</span></div>}
              <div style={S.detailRow}><span style={S.detailLabel}>Children</span><span style={{ display: 'flex', flexWrap: 'wrap' }}>{entry.childIds.length === 0 ? '—' : entry.childIds.map(cid => <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>)}</span></div>
            </CollapsibleSection>
            <CollapsibleSection id="family-tree" title="Family Tree" collapsed={collapsedSections.has('family-tree')} onToggle={() => toggleSection('family-tree')}>
              <FamilyTree person={entry} allPersons={allPersons} images={images} onSelectPerson={id => setSelectedId(id)} />
            </CollapsibleSection>
            {(() => {
              const household = households.find(h => h.memberIds.includes(entry.id));
              return (
                <CollapsibleSection id="household" title="Household" collapsed={collapsedSections.has('household')} onToggle={() => toggleSection('household')}>
                  {household ? (
                    <>
                      <div style={S.detailRow}><span style={S.detailLabel}>Household</span><span>🏠 {household.name}</span></div>
                      <div style={S.detailRow}><span style={S.detailLabel}>Members</span><span style={{ display: 'flex', flexWrap: 'wrap' }}>
                        {household.memberIds.filter(mid => mid !== entry.id).map(mid => (
                          <span key={mid} style={{ ...S.chip, cursor: 'pointer', background: mid === household.primaryContactId ? '#c6f0c2' : colors.accent }} onClick={() => setSelectedId(mid)}>
                            {resolveName(mid)}{mid === household.primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 2 }}>★ Primary</span>}
                          </span>
                        ))}
                        {household.memberIds.filter(mid => mid !== entry.id).length === 0 && '—'}
                      </span></div>
                    </>
                  ) : <div style={{ fontSize: 14, color: colors.textSec }}>Not assigned to any household.</div>}
                </CollapsibleSection>
              );
            })()}
          </>
        )}

        {entry.type === 'company' && (
          <CollapsibleSection id="contact-persons" title="Contact Persons" collapsed={collapsedSections.has('contact-persons')} onToggle={() => toggleSection('contact-persons')}>
            {entry.contactPersonIds.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
              <div style={{ display: 'flex', flexWrap: 'wrap' }}>{entry.contactPersonIds.map(pid => <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>{resolveName(pid)}</span>)}</div>}
          </CollapsibleSection>
        )}

        {entry.notes && (
          <CollapsibleSection id="notes" title="Notes" collapsed={collapsedSections.has('notes')} onToggle={() => toggleSection('notes')}>
            <div style={{ fontSize: 14, whiteSpace: 'pre-wrap' }}>{entry.notes}</div>
          </CollapsibleSection>
        )}
      </div>
    </>
  );
}

