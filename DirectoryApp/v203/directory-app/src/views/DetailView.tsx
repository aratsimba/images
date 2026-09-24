import React, { useState, useRef, useEffect } from 'react';
import type { DirectoryEntry, Person, Company, Household } from '../types';
import { INDUSTRY_OPTIONS } from '../types';
import { S, colors } from '../styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr, calculateAge, isValidIndustry } from '../utils';
import { ProfileImage } from '../components/ProfileImage';
import { FamilyTree } from '../components/FamilyTree';
import { CollapsibleSection } from '../components/CollapsibleSection';
import { downloadVCard } from '../components/VCardExport';
import { saveEntry } from '../storage';

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
  onToast?: (msg: string) => void;
  onReload?: () => Promise<void>;
}

export function DetailView({ entry, entries, allPersons, households, images, collapsedSections, toggleSection, setSelectedId, setView, onEdit, onDelete, setError, onToast, onReload }: Props) {
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };
  const [fixingIndustry, setFixingIndustry] = useState(false);
  const fixRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!fixingIndustry) return;
    const h = (ev: MouseEvent) => { if (fixRef.current && !fixRef.current.contains(ev.target as Node)) setFixingIndustry(false); };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, [fixingIndustry]);

  const handleFixIndustry = async (newIndustry: string) => {
    if (entry.type !== 'company') return;
    try {
      await saveEntry({ ...entry, industry: newIndustry });
      onToast?.(`✅ Industry updated to "${newIndustry}"`);
      setFixingIndustry(false);
      await onReload?.();
    } catch (e: any) { setError(e?.message || 'Failed to update industry'); }
  };

  return (
    <>
      <div style={S.btnRow}>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('list'); setSelectedId(''); }}>← Back</button>
        <button style={{ ...S.btn, ...S.btnPrimary }} onClick={onEdit}>Edit</button>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={async () => {
          try { await downloadVCard(entry, images[entry.id]); onToast?.(`📇 ${getEntryName(entry)} vCard exported`); }
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
            {entry.type === 'company' && entry.industry && isValidIndustry(entry.industry) && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{entry.industry}</span>}
            {entry.type === 'company' && entry.industry && !isValidIndustry(entry.industry) && (
              <div ref={fixRef} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginLeft: 4, position: 'relative' }}>
                <span style={{ fontSize: 13, color: '#e65100' }}>{entry.industry}</span>
                <span style={{ ...S.badge, background: '#fff3e0', color: '#e65100', fontSize: 10, cursor: 'pointer' }} onClick={() => setFixingIndustry(!fixingIndustry)} title="Click to reassign to a recognized industry">⚠️ Fix</span>
                {fixingIndustry && (
                  <div style={{ position: 'absolute', top: '100%', left: 0, marginTop: 4, background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 8, boxShadow: '0 4px 16px rgba(0,0,0,.15)', zIndex: 100, maxHeight: 240, overflowY: 'auto', minWidth: 260 }}>
                    <div style={{ padding: '8px 12px', fontSize: 11, color: colors.textSec, borderBottom: `1px solid ${colors.border}`, fontWeight: 600 }}>Reassign "{entry.industry}" to:</div>
                    {INDUSTRY_OPTIONS.map(ind => (
                      <div key={ind} style={{ padding: '8px 12px', fontSize: 13, cursor: 'pointer', color: colors.text }} onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)} onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')} onClick={() => handleFixIndustry(ind)}>{ind}</div>
                    ))}
                    <div style={{ padding: '8px 12px', fontSize: 13, cursor: 'pointer', color: colors.text, borderTop: `1px solid ${colors.border}` }} onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)} onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')} onClick={() => handleFixIndustry(entry.industry ? `Other — ${(entry as Company).industry}` : 'Other')}>Other — keep "{(entry as Company).industry}" as custom</div>
                  </div>
                )}
              </div>
            )}
            {entry.type === 'company' && !entry.industry && <span style={{ fontSize: 13, color: '#e65100', marginLeft: 4, fontStyle: 'italic' }}>No industry set</span>}
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
            <CollapsibleSection id="relationships" title="Personal Relationships" collapsed={collapsedSections.has('relationships')} onToggle={() => toggleSection('relationships')}>
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
            {(() => {
              const affiliations = entry.affiliations?.length
                ? entry.affiliations
                : (entry.companyId ? [{ companyId: entry.companyId, title: entry.title }] : []);
              return (affiliations.length > 0 || entry.isMissionary) ? (
                <CollapsibleSection id="professional" title="Professional Information" collapsed={collapsedSections.has('professional')} onToggle={() => toggleSection('professional')}>
                  {entry.isMissionary && <div style={S.detailRow}><span style={S.detailLabel}>Missionary</span><span>✅ Yes</span></div>}
                  {affiliations.map((aff, i) => {
                    const company = entries.find(e => e.id === aff.companyId) as Company | undefined;
                    return (
                      <div key={aff.companyId + i} style={{ padding: '8px 12px', marginBottom: 6, borderRadius: 6, border: `1px solid ${colors.border}`, background: '#fff' }}>
                        {company && <div style={S.detailRow}><span style={S.detailLabel}>Company</span><span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(company.id)}>🏢 {company.name}</span></div>}
                        {aff.companyId && !company && <div style={S.detailRow}><span style={S.detailLabel}>Company</span><span style={{ color: colors.textSec, fontStyle: 'italic' }}>Company not found</span></div>}
                        {aff.title && <div style={S.detailRow}><span style={S.detailLabel}>Title</span><span>{aff.title}</span></div>}
                      </div>
                    );
                  })}
                </CollapsibleSection>
              ) : null;
            })()}
          </>
        )}

        {entry.type === 'company' && (() => {
          // Merge contactPersonIds with persons who have this company in their affiliations
          const linkedPersonIds = allPersons.filter(p =>
            p.companyId === entry.id || (p.affiliations || []).some(a => a.companyId === entry.id)
          ).map(p => p.id);
          const allContactIds = Array.from(new Set([...(entry.contactPersonIds || []), ...linkedPersonIds]));
          return (
            <CollapsibleSection id="contact-persons" title={`Contact Persons (${allContactIds.length})`} collapsed={collapsedSections.has('contact-persons')} onToggle={() => toggleSection('contact-persons')}>
              {allContactIds.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                <div style={{ display: 'flex', flexWrap: 'wrap' }}>{allContactIds.map(pid => {
                  const person = allPersons.find(p => p.id === pid);
                  const aff = person?.affiliations?.find(a => a.companyId === entry.id);
                  const title = aff?.title || person?.title;
                  return (
                    <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>
                      {resolveName(pid)}{title && <span style={{ fontSize: 11, color: colors.textSec, marginLeft: 4 }}>· {title}</span>}
                    </span>
                  );
                })}</div>}
            </CollapsibleSection>
          );
        })()}

        {entry.notes && (
          <CollapsibleSection id="notes" title="Notes" collapsed={collapsedSections.has('notes')} onToggle={() => toggleSection('notes')}>
            <div style={{ fontSize: 14, whiteSpace: 'pre-wrap' }}>{entry.notes}</div>
          </CollapsibleSection>
        )}
      </div>
    </>
  );
}

