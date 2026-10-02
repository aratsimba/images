import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

interface ContactPersonSearchProps {
  allPersons: Person[];
  excludeIds: string[];
  editCompanyId: string | null;
  onAdd: (personId: string, title: string) => void;
  onQuickAdd?: (searchText: string) => void;
}

export const ContactPersonSearch: React.FC<ContactPersonSearchProps> = ({ allPersons, excludeIds, editCompanyId, onAdd, onQuickAdd }) => {
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

  const filtered = allPersons.filter(p =>
    !excludeIds.includes(p.id) &&
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase())
  );

  return (
    <div ref={ref}>
      <input style={S.input} placeholder={onQuickAdd ? "Search or create a contact person..." : "Search persons to add..."} value={q} onChange={e => { setQ(e.target.value); setOpen(true); }} onFocus={() => setOpen(true)} />
      {open && q && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'relative' as const, zIndex: 5 }}>
          {filtered.length === 0 && <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons</div>}
          {filtered.slice(0, 8).map(p => {
            const existingAff = (p.affiliations || []).find(a => a.companyId === editCompanyId);
            return (
              <div key={p.id} style={S.dropdownItem}
                onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                onClick={() => {
                  onAdd(p.id, existingAff?.title || '');
                  setQ(''); setOpen(false);
                }}>
                {p.firstName} {p.lastName}
              </div>
            );
          })}
          {onQuickAdd && (
            <>
              <div style={{ borderTop: `1px solid ${colors.border}` }} />
              <div style={{ ...S.dropdownItem, color: colors.primary, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}
                onMouseEnter={e => (e.currentTarget.style.background = '#f0f7ff')}
                onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                onClick={() => { const text = q; setQ(''); setOpen(false); onQuickAdd(text); }}>
                ✨ Create new contact…
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
};

