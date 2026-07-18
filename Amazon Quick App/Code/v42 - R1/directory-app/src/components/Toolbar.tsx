import React from 'react';
import type { SortField, SortDir, TypeFilter } from '../types';
import { S, colors } from '../styles';

export function Toolbar({ sortField, setSortField, sortDir, setSortDir, typeFilter, setTypeFilter,
  industryFilter, setIndustryFilter, allIndustries }: {
  sortField: SortField; setSortField: (v: SortField) => void;
  sortDir: SortDir; setSortDir: (v: SortDir) => void;
  typeFilter: TypeFilter; setTypeFilter: (v: TypeFilter) => void;
  industryFilter: string; setIndustryFilter: (v: string) => void;
  allIndustries: string[];
}) {
  return (
    <div style={{
      display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center',
      padding: '10px 16px', marginBottom: 16, borderRadius: 8,
      background: colors.card, border: `1px solid ${colors.border}`,
    }}>
      <span style={{ fontSize: 13, fontWeight: 700, color: colors.textSec, marginRight: 4 }}>Sort:</span>
      <select style={{ ...S.input, width: 'auto', padding: '5px 8px', fontSize: 13 }}
        value={sortField} onChange={e => setSortField(e.target.value as SortField)}>
        <option value="name">Name</option>
        <option value="type">Type</option>
        <option value="dateAdded">Date Added</option>
      </select>
      <button style={{ ...S.btn, padding: '4px 10px', fontSize: 13, ...S.btnSec }}
        onClick={() => setSortDir(sortDir === 'asc' ? 'desc' : 'asc')}
        title={`Currently: ${sortDir === 'asc' ? 'Ascending' : 'Descending'}`}>
        {sortDir === 'asc' ? '↑ A–Z' : '↓ Z–A'}
      </button>

      <div style={{ width: 1, height: 24, background: colors.border, margin: '0 4px' }} />

      <span style={{ fontSize: 13, fontWeight: 700, color: colors.textSec, marginRight: 4 }}>Filter:</span>
      {(['all', 'person', 'company'] as TypeFilter[]).map(t => (
        <button key={t} style={{
          ...S.btn, padding: '4px 12px', fontSize: 13,
          background: typeFilter === t ? colors.primary : 'transparent',
          color: typeFilter === t ? '#fff' : colors.text,
          border: `1px solid ${typeFilter === t ? colors.primary : colors.border}`,
          borderRadius: 16,
        }} onClick={() => { setTypeFilter(t); if (t !== 'company') setIndustryFilter(''); }}>
          {t === 'all' ? 'All' : t === 'person' ? '👤 Persons' : '🏢 Companies'}
        </button>
      ))}

      {allIndustries.length > 0 && (typeFilter === 'all' || typeFilter === 'company') && (
        <select style={{ ...S.input, width: 'auto', padding: '5px 8px', fontSize: 13 }}
          value={industryFilter} onChange={e => { setIndustryFilter(e.target.value); if (e.target.value) setTypeFilter('company'); }}>
          <option value="">All Industries</option>
          {allIndustries.map(ind => <option key={ind} value={ind}>{ind}</option>)}
        </select>
      )}

      {(typeFilter !== 'all' || industryFilter) && (
        <button style={{ ...S.btn, padding: '4px 10px', fontSize: 12, color: colors.danger, background: 'transparent', border: 'none', textDecoration: 'underline' }}
          onClick={() => { setTypeFilter('all'); setIndustryFilter(''); }}>
          Clear Filters
        </button>
      )}
    </div>
  );
}

