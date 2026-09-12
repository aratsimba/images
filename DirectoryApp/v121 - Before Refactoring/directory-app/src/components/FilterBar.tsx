import React, { useState } from 'react';
import type { SortField, SortDir, TypeFilter, StatusFilter } from '../types';
import { colors } from '../styles';

interface FilterBarProps {
  sortField: SortField;
  setSortField: (v: SortField) => void;
  sortDir: SortDir;
  setSortDir: (v: SortDir) => void;
  typeFilter: TypeFilter;
  setTypeFilter: (v: TypeFilter) => void;
  industryFilter: string;
  setIndustryFilter: (v: string) => void;
  allIndustries: string[];
  statusFilter: StatusFilter;
  setStatusFilter: (v: StatusFilter) => void;
  totalCount: number;
}

type StatusOption = { value: StatusFilter; label: string };

function getStatusOptions(typeFilter: TypeFilter): StatusOption[] {
  if (typeFilter === 'person') {
    return [
      { value: 'active', label: '● Active' },
      { value: 'deceased', label: '✝ Deceased' },
      { value: 'all', label: '○ All' },
    ];
  }
  if (typeFilter === 'company') {
    return [
      { value: 'active', label: '● Active' },
      { value: 'closed', label: '🚫 Closed' },
      { value: 'all', label: '○ All' },
    ];
  }
  // 'all' type — show everything
  return [
    { value: 'active', label: '● Active' },
    { value: 'deceased', label: '✝ Deceased' },
    { value: 'closed', label: '🚫 Closed' },
    { value: 'all', label: '○ All' },
  ];
}

function getStatusChipLabel(statusFilter: StatusFilter): string {
  if (statusFilter === 'deceased') return '✝ Deceased';
  if (statusFilter === 'closed') return '🚫 Closed';
  if (statusFilter === 'all') return '○ All statuses';
  return '● Active';
}

export function FilterBar({
  sortField, setSortField, sortDir, setSortDir,
  typeFilter, setTypeFilter, industryFilter, setIndustryFilter,
  allIndustries, statusFilter, setStatusFilter, totalCount
}: FilterBarProps) {
  const [expanded, setExpanded] = useState(false);

  const hasActiveFilters = typeFilter !== 'all' || industryFilter !== '' || statusFilter !== 'active';
  const activeFilterCount = (typeFilter !== 'all' ? 1 : 0) + (industryFilter ? 1 : 0) + (statusFilter !== 'active' ? 1 : 0);

  const clearAll = () => {
    setTypeFilter('all');
    setIndustryFilter('');
    setStatusFilter('active');
  };

  const statusOptions = getStatusOptions(typeFilter);

  // If current status filter is not valid for the selected type, reset it
  const validValues = statusOptions.map(o => o.value);
  if (!validValues.includes(statusFilter)) {
    // Don't call setState in render — use effect-like approach
    setTimeout(() => setStatusFilter('active'), 0);
  }

  const chipStyle: React.CSSProperties = {
    display: 'inline-flex', alignItems: 'center', gap: 4,
    background: colors.accent, borderRadius: 14, padding: '3px 10px',
    fontSize: 12, fontWeight: 600, color: colors.primary,
  };
  const chipRemoveStyle: React.CSSProperties = {
    border: 'none', background: 'none', cursor: 'pointer',
    color: colors.textSec, fontWeight: 700, fontSize: 14, lineHeight: 1, padding: '0 0 0 2px',
  };

  return (
    <div style={{
      marginBottom: 16, borderRadius: 10, background: colors.card,
      border: `1px solid ${colors.border}`, overflow: 'hidden',
    }}>
      {/* Summary row — always visible */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px',
        flexWrap: 'wrap',
      }}>
        {/* Sort control */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 12, color: colors.textSec, fontWeight: 600 }}>Sort:</span>
          <select style={{
            padding: '4px 8px', borderRadius: 5, border: `1px solid ${colors.border}`,
            fontSize: 12, outline: 'none', background: '#fff', cursor: 'pointer',
          }} value={sortField} onChange={e => setSortField(e.target.value as SortField)}>
            <option value="name">Name</option>
            <option value="type">Type</option>
            <option value="dateAdded">Date Added</option>
          </select>
          <button onClick={() => setSortDir(sortDir === 'asc' ? 'desc' : 'asc')}
            title={sortDir === 'asc' ? 'Ascending' : 'Descending'}
            style={{
              border: `1px solid ${colors.border}`, borderRadius: 5, background: '#fff',
              cursor: 'pointer', padding: '3px 7px', fontSize: 13, lineHeight: 1,
            }}>
            {sortDir === 'asc' ? '↑' : '↓'}
          </button>
        </div>

        <div style={{ width: 1, height: 20, background: colors.border }} />

        {/* Filter toggle button */}
        <button onClick={() => setExpanded(!expanded)} style={{
          display: 'flex', alignItems: 'center', gap: 5,
          border: `1px solid ${hasActiveFilters ? colors.primary : colors.border}`,
          borderRadius: 6, background: hasActiveFilters ? '#e8f0fe' : '#fff',
          cursor: 'pointer', padding: '5px 12px', fontSize: 12, fontWeight: 600,
          color: hasActiveFilters ? colors.primary : colors.text,
        }}>
          <span>🔽</span>
          Filters{activeFilterCount > 0 && ` (${activeFilterCount})`}
        </button>

        {/* Active filter chips */}
        {hasActiveFilters && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            {typeFilter !== 'all' && (
              <span style={chipStyle}>
                {typeFilter === 'person' ? '👤 Persons' : '🏢 Companies'}
                <button style={chipRemoveStyle} onClick={() => { setTypeFilter('all'); setIndustryFilter(''); }}>×</button>
              </span>
            )}
            {statusFilter !== 'active' && (
              <span style={chipStyle}>
                {getStatusChipLabel(statusFilter)}
                <button style={chipRemoveStyle} onClick={() => setStatusFilter('active')}>×</button>
              </span>
            )}
            {industryFilter && (
              <span style={chipStyle}>
                🏷 {industryFilter}
                <button style={chipRemoveStyle} onClick={() => setIndustryFilter('')}>×</button>
              </span>
            )}
            <button onClick={clearAll} style={{
              border: 'none', background: 'none', cursor: 'pointer',
              fontSize: 11, color: colors.danger, fontWeight: 600, textDecoration: 'underline', padding: '2px 4px',
            }}>Clear all</button>
          </div>
        )}

        {/* Result count */}
        <span style={{ marginLeft: 'auto', fontSize: 12, color: colors.textSec }}>
          {totalCount} result{totalCount !== 1 ? 's' : ''}
        </span>
      </div>

      {/* Expanded filter panel */}
      {expanded && (
        <div style={{
          borderTop: `1px solid ${colors.border}`, padding: '14px 16px',
          background: '#fafbfc', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: 16,
        }}>
          {/* Type filter */}
          <div>
            <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
              Entry Type
            </label>
            <div style={{ display: 'flex', gap: 4 }}>
              {(['all', 'person', 'company'] as TypeFilter[]).map(t => (
                <button key={t} onClick={() => { setTypeFilter(t); if (t !== 'company') setIndustryFilter(''); }}
                  style={{
                    flex: 1, padding: '6px 8px', fontSize: 12, fontWeight: 600,
                    border: `1px solid ${typeFilter === t ? colors.primary : colors.border}`,
                    borderRadius: 6, cursor: 'pointer',
                    background: typeFilter === t ? colors.primary : '#fff',
                    color: typeFilter === t ? '#fff' : colors.text,
                  }}>
                  {t === 'all' ? 'All' : t === 'person' ? '👤 Person' : '🏢 Company'}
                </button>
              ))}
            </div>
          </div>

          {/* Status filter — context-sensitive */}
          <div>
            <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
              Status
            </label>
            <div style={{ display: 'flex', gap: 4 }}>
              {statusOptions.map(opt => (
                <button key={opt.value} onClick={() => setStatusFilter(opt.value)}
                  style={{
                    flex: 1, padding: '6px 6px', fontSize: 11, fontWeight: 600,
                    border: `1px solid ${statusFilter === opt.value ? (opt.value === 'deceased' || opt.value === 'closed' ? '#5f6368' : colors.primary) : colors.border}`,
                    borderRadius: 6, cursor: 'pointer',
                    background: statusFilter === opt.value ? (opt.value === 'deceased' || opt.value === 'closed' ? '#5f6368' : colors.primary) : '#fff',
                    color: statusFilter === opt.value ? '#fff' : colors.text,
                  }}>
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Industry filter */}
          {allIndustries.length > 0 && (typeFilter === 'all' || typeFilter === 'company') && (
            <div>
              <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
                Industry
              </label>
              <select value={industryFilter}
                onChange={e => { setIndustryFilter(e.target.value); if (e.target.value) setTypeFilter('company'); }}
                style={{
                  width: '100%', padding: '6px 10px', borderRadius: 6,
                  border: `1px solid ${colors.border}`, fontSize: 12, outline: 'none',
                  background: '#fff', cursor: 'pointer',
                }}>
                <option value="">All Industries</option>
                {allIndustries.map(ind => <option key={ind} value={ind}>{ind}</option>)}
              </select>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

