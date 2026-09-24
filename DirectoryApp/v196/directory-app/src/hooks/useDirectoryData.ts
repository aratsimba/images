import { useState, useCallback, useEffect, useMemo } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household, SortField, SortDir, TypeFilter, StatusFilter } from '../types';
import { getEntryName } from '../utils';
import { loadAll, loadAllHouseholds, loadAllImages } from '../storage';

export function useDirectoryData() {
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [images, setImages] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const reload = useCallback(async () => {
    try {
      setLoading(true);
      setEntries(await loadAll());
      setHouseholds(await loadAllHouseholds());
      setImages(await loadAllImages());
    } catch (e) {
      if (e instanceof PageStorageError) setError((e as PageStorageError).message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { reload(); }, [reload]);

  const allPersons = useMemo(() => entries.filter((e): e is Person => e.type === 'person'), [entries]);

  const allIndustries = useMemo(() => {
    const set = new Set<string>();
    entries.forEach(e => { if (e.type === 'company' && e.industry.trim()) set.add(e.industry.trim()); });
    return Array.from(set).sort();
  }, [entries]);

  const allAffiliatedCompanies = useMemo(() => {
    const companyIds = new Set<string>();
    for (const e of entries) {
      if (e.type === 'person' && e.affiliations) {
        for (const a of e.affiliations) companyIds.add(a.companyId);
      }
    }
    return entries
      .filter((e): e is import('../types').Company => e.type === 'company' && companyIds.has(e.id))
      .map(c => ({ id: c.id, name: c.name }))
      .sort((a, b) => a.name.localeCompare(b.name));
  }, [entries]);

  return { entries, households, images, loading, error, setError, reload, allPersons, allIndustries, allAffiliatedCompanies };
}

export function useFilteredEntries(
  entries: DirectoryEntry[],
  searchQ: string,
  typeFilter: TypeFilter,
  industryFilter: string,
  statusFilter: StatusFilter,
  sortField: SortField,
  sortDir: SortDir,
  missionaryFilter?: boolean,
  companyFilter?: string,
) {
  const sq = searchQ.toLowerCase();
  const searchResults = useMemo(() => entries.filter(e =>
    e.type === 'person'
      ? `${e.firstName} ${e.lastName} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
      : `${e.name} ${e.industry} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
  ), [entries, sq]);

  const filteredEntries = useMemo(() => {
    let list = searchQ ? searchResults : entries;
    if (typeFilter !== 'all') list = list.filter(e => e.type === typeFilter);
    if (industryFilter) list = list.filter(e => e.type === 'company' && e.industry.trim().toLowerCase() === industryFilter.toLowerCase());
    if (missionaryFilter) list = list.filter(e => e.type === 'person' && e.isMissionary);
    if (companyFilter) list = list.filter(e => e.type === 'person' && (e.affiliations || []).some(a => a.companyId === companyFilter));
    if (statusFilter === 'active') {
      list = list.filter(e => e.type === 'person' ? (e.status || 'active') === 'active' : (e.companyStatus || 'active') === 'active');
    } else if (statusFilter === 'deceased') {
      list = list.filter(e => e.type === 'person' && e.status === 'deceased');
    } else if (statusFilter === 'closed') {
      list = list.filter(e => e.type === 'company' && e.companyStatus === 'closed');
    } else {
      list = list.filter(e => e.type === 'person' ? (e.status || 'active') !== 'archived' : (e.companyStatus || 'active') !== 'archived');
    }
    list = [...list].sort((a, b) => {
      let cmp = 0;
      if (sortField === 'name') cmp = getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else if (sortField === 'type') cmp = a.type.localeCompare(b.type) || getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else cmp = a.id.localeCompare(b.id);
      return sortDir === 'desc' ? -cmp : cmp;
    });
    return list;
  }, [entries, searchQ, searchResults, typeFilter, industryFilter, statusFilter, sortField, sortDir, missionaryFilter, companyFilter]);

  return { searchResults, filteredEntries };
}

