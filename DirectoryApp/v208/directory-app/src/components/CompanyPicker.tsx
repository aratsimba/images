import React, { useState, useRef, useEffect } from 'react';
import type { Company } from '../types';
import { S, colors } from '../styles';

interface CompanyPickerProps {
  companies: Company[];
  selectedCompanyId: string;
  onSelect: (id: string) => void;
  onClear: () => void;
  allowCreate?: boolean;
  onQuickAdd?: (searchText: string) => void;
  pendingCompany?: Company | null;
  onEditPending?: () => void;
}

export function CompanyPicker({ companies, selectedCompanyId, onSelect, onClear, allowCreate, onQuickAdd, pendingCompany, onEditPending }: CompanyPickerProps) {
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

  const allCompanies = pendingCompany ? [...companies, pendingCompany] : companies;
  const selected = allCompanies.find(c => c.id === selectedCompanyId);

  if (selected) {
    const isPending = pendingCompany && selected.id === pendingCompany.id;
    return (
      <div>
        <label style={S.label}>Company</label>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ ...S.chip, ...(isPending ? { background: '#fff8e1', border: '1px solid #ffc107', cursor: 'pointer' } : {}) }}
            onClick={isPending && onEditPending ? onEditPending : undefined}
            title={isPending ? 'Click to edit' : undefined}>
            {isPending && <span style={{ fontSize: 11, fontWeight: 700, color: '#f57f17' }}>✨ new</span>}
            🏢 {selected.name}
            <button style={S.chipRemove} onClick={e => { e.stopPropagation(); onClear(); }}>×</button>
          </span>
        </div>
      </div>
    );
  }

  const filtered = companies.filter(c =>
    c.name.toLowerCase().includes(q.toLowerCase()) &&
    (!c.companyStatus || c.companyStatus === 'active')
  );

  return (
    <div ref={ref}>
      <label style={S.label}>Company</label>
      <input
        style={S.input}
        placeholder={allowCreate ? "Search or create a company..." : "Search for a company..."}
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
              onClick={() => { onSelect(c.id); setQ(''); setOpen(false); }}>
              🏢 {c.name}{c.industry ? <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({c.industry})</span> : null}
            </div>
          ))}
          {allowCreate && onQuickAdd && (
            <>
              <div style={{ borderTop: `1px solid ${colors.border}` }} />
              <div style={{ ...S.dropdownItem, color: colors.primary, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}
                onMouseEnter={e => (e.currentTarget.style.background = '#f0f7ff')}
                onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                onClick={() => { const text = q; setQ(''); setOpen(false); onQuickAdd(text); }}>
                ✨ Create new company…
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}

