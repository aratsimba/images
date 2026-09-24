import { useCallback } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household } from '../types';
import { getEntryName } from '../utils';
import { saveEntry, loadEntry, removeEntry, saveHousehold, loadHousehold, removeHousehold, removePersonFromHousehold, saveImage, removeImage } from '../storage';

interface ActionsDeps {
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  reload: () => Promise<void>;
  setError: (msg: string) => void;
  selectedId: string | null;
  setSelectedId: (id: string | null) => void;
  setView: (v: any) => void;
  setSelectMode: (v: boolean) => void;
  setSelectedIds: (v: React.SetStateAction<Set<string>>) => void;
  setDeletingAll: (v: boolean) => void;
  setShowDeleteAll: (v: boolean) => void;
  setDeleteTarget: (v: DirectoryEntry | null) => void;
  deleteTarget: DirectoryEntry | null;
}

export function useDirectoryActions(deps: ActionsDeps) {
  const { entries, allPersons, households, images, reload, setError,
    selectedId, setSelectedId, setView, setSelectMode, setSelectedIds,
    setDeletingAll, setShowDeleteAll, setDeleteTarget, deleteTarget } = deps;

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return null;
    const id = deleteTarget.id;
    const deletedName = getEntryName(deleteTarget);
    setDeleteTarget(null);
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person') {
        if (entry.spouseId) {
          const spouse = await loadEntry(entry.spouseId);
          if (spouse && spouse.type === 'person') {
            const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => cid !== id);
            await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
        }
        for (const p of allPersons) {
          if (p.id !== id && p.childIds.includes(id)) await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
        }
        for (const e of entries) {
          if (e.type === 'company' && (e.contactPersonIds || []).includes(id)) await saveEntry({ ...e, contactPersonIds: (e.contactPersonIds || []).filter(c => c !== id) });
        }
        // Clear person from all affiliated companies' contactPersonIds
        if (entry.affiliations && entry.affiliations.length > 0) {
          for (const aff of entry.affiliations) {
            const company = await loadEntry(aff.companyId);
            if (company && company.type === 'company' && company.contactPersonIds.includes(id)) {
              await saveEntry({ ...company, contactPersonIds: company.contactPersonIds.filter(c => c !== id) });
            }
          }
        } else if (entry.companyId) {
          // Legacy fallback
          const company = await loadEntry(entry.companyId);
          if (company && company.type === 'company' && company.contactPersonIds.includes(id)) {
            await saveEntry({ ...company, contactPersonIds: company.contactPersonIds.filter(c => c !== id) });
          }
        }
        if (entry.householdId) {
          const household = households.find(h => h.id === entry.householdId);
          if (household) {
            await removePersonFromHousehold(id, household, allPersons);
          }
        }
      }
      if (entry?.type === 'company') {
        // Clear this company from all persons' affiliations
        for (const p of allPersons) {
          if (p.companyId === id || (p.affiliations || []).some(a => a.companyId === id)) {
            const newAffs = (p.affiliations || []).filter(a => a.companyId !== id);
            const primaryAff = newAffs.length > 0 ? newAffs[0] : null;
            await saveEntry({ ...p, affiliations: newAffs, companyId: primaryAff?.companyId || '', title: primaryAff?.title || '' });
          }
        }
      }
      await removeEntry(id);
      if (images[id]) await removeImage(id);
      await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
      return deletedName;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  }, [deleteTarget, allPersons, entries, households, images, reload, setError, selectedId, setSelectedId, setView, setDeleteTarget]);

  const handleDeleteAll = useCallback(async () => {
    setShowDeleteAll(false);
    setDeletingAll(true);
    try {
      const count = entries.length + households.length;
      for (const entry of entries) { await removeEntry(entry.id); if (images[entry.id]) await removeImage(entry.id); }
      for (const h of households) { await removeHousehold(h.id); if (images[h.id]) await removeImage(h.id); }
      await reload();
      setSelectedId(null);
      setView('list');
      return count;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
    finally { setDeletingAll(false); }
  }, [entries, households, images, reload, setError, setSelectedId, setView, setDeletingAll, setShowDeleteAll]);

  const handleBulkDelete = useCallback(async (ids: string[]) => {
    try {
      for (const id of ids) {
        const entry = await loadEntry(id);
        if (entry?.type === 'person') {
          if (entry.spouseId && !ids.includes(entry.spouseId)) {
            const spouse = await loadEntry(entry.spouseId);
            if (spouse && spouse.type === 'person') {
              const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => !ids.includes(cid) && cid !== id);
              await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
            }
          }
          for (const p of allPersons) {
            if (!ids.includes(p.id) && p.childIds.includes(id)) await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
          }
          for (const e of entries) {
            if (e.type === 'company' && !ids.includes(e.id) && (e.contactPersonIds || []).includes(id)) await saveEntry({ ...e, contactPersonIds: (e.contactPersonIds || []).filter(c => c !== id) });
          }
          // Clear person from all affiliated companies' contactPersonIds
          if (entry.affiliations && entry.affiliations.length > 0) {
            for (const aff of entry.affiliations) {
              if (!ids.includes(aff.companyId)) {
                const company = await loadEntry(aff.companyId);
                if (company && company.type === 'company' && company.contactPersonIds.includes(id)) {
                  await saveEntry({ ...company, contactPersonIds: company.contactPersonIds.filter(c => c !== id) });
                }
              }
            }
          } else if (entry.companyId && !ids.includes(entry.companyId)) {
            const company = await loadEntry(entry.companyId);
            if (company && company.type === 'company' && company.contactPersonIds.includes(id)) {
              await saveEntry({ ...company, contactPersonIds: company.contactPersonIds.filter(c => c !== id) });
            }
          }
          if (entry.householdId) {
            const household = households.find(h => h.id === entry.householdId);
            if (household) {
              // Only process if household still has this member (might have been dissolved already)
              if (household.memberIds.includes(id)) {
                await removePersonFromHousehold(id, household, allPersons);
              }
            }
          }
        }
        if (entry?.type === 'company') {
          // Clear this company from all persons' affiliations
          for (const p of allPersons) {
            if (!ids.includes(p.id) && (p.companyId === id || (p.affiliations || []).some(a => a.companyId === id))) {
              const newAffs = (p.affiliations || []).filter(a => a.companyId !== id);
              const primaryAff = newAffs.length > 0 ? newAffs[0] : null;
              await saveEntry({ ...p, affiliations: newAffs, companyId: primaryAff?.companyId || '', title: primaryAff?.title || '' });
            }
          }
        }
        await removeEntry(id);
        if (images[id]) await removeImage(id);
      }
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
      return ids.length;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  }, [allPersons, entries, households, images, reload, setError, setSelectedIds, setSelectMode]);

  const handleBulkStatusChange = useCallback(async (ids: string[], status: 'active' | 'deceased' | 'closed') => {
    try {
      for (const id of ids) {
        const entry = await loadEntry(id);
        if (!entry) continue;
        if (entry.type === 'person') {
          const target = status === 'closed' ? 'active' : status;
          if ((entry.status || 'active') === target) continue;
          await saveEntry({ ...entry, status: target, deceasedDate: target === 'deceased' ? entry.deceasedDate || '' : '' });
        } else {
          const target = status === 'deceased' ? 'active' : (status === 'closed' ? 'closed' : 'active');
          if ((entry.companyStatus || 'active') === target) continue;
          await saveEntry({ ...entry, companyStatus: target, closedDate: target === 'closed' ? entry.closedDate || '' : '' });
        }
      }
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode]);

  const handleBulkAssignHousehold = useCallback(async (personIds: string[], householdId: string) => {
    try {
      const household = await loadHousehold(householdId);
      if (!household) return;
      const householdAddr = { ...household.address, isPrimary: true as const, label: 'Household' };
      const updatedMemberIds = [...household.memberIds];
      for (const pid of personIds) {
        const person = await loadEntry(pid);
        if (!person || person.type !== 'person') continue;
        if (person.householdId && person.householdId !== householdId) {
          const oldHousehold = await loadHousehold(person.householdId);
          if (oldHousehold) {
            await removePersonFromHousehold(pid, oldHousehold, allPersons);
          }
        }
        if (!updatedMemberIds.includes(pid)) updatedMemberIds.push(pid);
        const addrs = [...person.addresses];
        const pIdx = addrs.findIndex(a => a.isPrimary);
        if (pIdx >= 0) addrs[pIdx] = householdAddr; else if (addrs.length > 0) addrs[0] = householdAddr; else addrs.push(householdAddr);
        await saveEntry({ ...person, householdId, addresses: addrs });
      }
      await saveHousehold({ ...household, memberIds: updatedMemberIds });
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode, allPersons]);

  const handleCreateAndAssignHousehold = useCallback(async (personIds: string[], household: Household) => {
    try {
      const householdAddr = { ...household.address, isPrimary: true as const, label: 'Household' };
      for (const pid of personIds) {
        const person = await loadEntry(pid);
        if (!person || person.type !== 'person') continue;
        if (person.householdId) {
          const oldHousehold = await loadHousehold(person.householdId);
          if (oldHousehold) {
            await removePersonFromHousehold(pid, oldHousehold, allPersons);
          }
        }
        const addrs = [...person.addresses];
        const pIdx = addrs.findIndex(a => a.isPrimary);
        if (pIdx >= 0) addrs[pIdx] = householdAddr; else if (addrs.length > 0) addrs[0] = householdAddr; else addrs.push(householdAddr);
        await saveEntry({ ...person, householdId: household.id, addresses: addrs });
      }
      await saveHousehold(household);
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode, allPersons]);

  return { confirmDelete, handleDeleteAll, handleBulkDelete, handleBulkStatusChange, handleBulkAssignHousehold, handleCreateAndAssignHousehold };
}

