import React, { useState, useRef, useEffect } from 'react';
import type { Company } from '../types';
import { S, colors } from '../styles';

interface Affiliation {
  companyId: string;
  title: string;
}

interface AffiliationEditorProps {
  affiliations: Affiliation[];
  allCompanies: Company[];
  pendingCompanies: Company[];
  isMissionary: boolean;
  onChange: (affiliations: Affiliation[]) => void;
  onRemovePending: (companyId: string) => void;
  onEditPending: (companyId: string) => void;
  onQuickAdd: (searchText: string) => void;
}

export const AffiliationEditor: React.FC<AffiliationEditorProps> = ({
  affiliations, allCompanies, pendingCompanies, isMissionary,
  onChange, onRemovePending, onEditPending, onQuickAdd,
}) => {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (ref.current && !ref.current.contains(ev.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const allAvailable = [...allCompanies, ...pendingCompanies];
  const selectedIds = new Set(affiliations.map(a => a.companyId));
  const titlePlaceholder = isMissionary ? 'Title (e.g. Pastor or Missionary)' : 'Title (e.g. Owner)';

  const filtered = allCompanies.filter(c =>
    !selectedIds.has(c.id) &&
    (!c.companyStatus || c.companyStatus === 'active') &&
    c.name.toLowerCase().includes(q.toLowerCase())
  );

  const handleRemove = (companyId: string) => {
    onChange(affiliations.filter(a => a.companyId !== companyId));
    const isPending = pendingCompanies.find(pc => pc.id === companyId);
    if (isPending) onRemovePending(companyId);
  };

  const handleTitleChange = (companyId: string, title: string) => {
    onChange(affiliations.map(a => a.companyId === companyId ? { ...a, title } : a));
  };

  const handleSelect = (companyId: string) => {
    if (selectedIds.has(companyId)) return;
    onChange([...affiliations, { companyId, title: '' }]);
    setQ(''); setOpen(false);
  };

  return (
    <div style={{ gridColumn: '1 / -1' }}>
      <label style={S.label}>Company Affiliations</label>

      {/* List of current affiliations */}
      {affiliations.length > 0 && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 10 }}>
          {affiliations.map(aff => {
            const company = allAvailable.find(c => c.id === aff.companyId);
            if (!company) return null;
            const isPending = pendingCompanies.find(pc => pc.id === aff.companyId);
            return (
              <div key={aff.companyId} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', borderRadius: 8, border: `1px solid ${isPending ? '#ffc107' : colors.border}`, background: isPending ? '#fffde7' : '#fafbfc' }}>
                <span
                  style={{ fontWeight: 600, fontSize: 13, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', display: 'flex', alignItems: 'center', gap: 4, ...(isPending ? { cursor: 'pointer' } : {}) }}
                  onClick={isPending ? () => onEditPending(aff.companyId) : undefined}
                  title={isPending ? 'Click to edit pending company' : undefined}
                >
                  {isPending && <span style={{ fontSize: 10, fontWeight: 700, color: '#f57f17' }}>✨</span>}
                  🏢 {company.name}
                </span>
                <span style={{ color: colors.textSec, fontSize: 12 }}>·</span>
                <input
                  style={{ ...S.input, flex: 1, padding: '4px 8px', fontSize: 13 }}
                  placeholder={titlePlaceholder}
                  value={aff.title}
                  onChange={e => handleTitleChange(aff.companyId, e.target.value)}
                />
                <button
                  style={{ ...S.chipRemove, fontSize: 16 }}
                  onClick={() => handleRemove(aff.companyId)}
                  title="Remove affiliation"
                >×</button>
              </div>
            );
          })}
        </div>
      )}

      {/* Search / create input */}
      <div ref={ref}>
        <input
          style={S.input}
          placeholder="Search or create a company to add..."
          value={q}
          onChange={e => { setQ(e.target.value); setOpen(true); }}
          onFocus={() => setOpen(true)}
        />
        {open && q && (
          <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'relative' as const, zIndex: 5 }}>
            {filtered.length === 0 && (
              <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching companies</div>
            )}
            {filtered.slice(0, 8).map(c => (
              <div key={c.id} style={S.dropdownItem}
                onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                onClick={() => handleSelect(c.id)}>
                🏢 {c.name}{c.industry ? <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({c.industry})</span> : null}
              </div>
            ))}
            <div style={{ borderTop: `1px solid ${colors.border}` }} />
            <div style={{ ...S.dropdownItem, color: colors.primary, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}
              onMouseEnter={e => (e.currentTarget.style.background = '#f0f7ff')}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { const text = q; setQ(''); setOpen(false); onQuickAdd(text); }}>
              ✨ Create new company…
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

