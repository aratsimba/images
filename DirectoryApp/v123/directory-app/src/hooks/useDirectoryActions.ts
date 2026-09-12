import { useCallback } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household } from '../types';
import { saveEntry, loadEntry, removeEntry, saveHousehold, loadHousehold, removeHousehold, saveImage, removeImage } from '../storage';

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
    if (!deleteTarget) return;
    const id = deleteTarget.id;
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
          if (e.type === 'company' && e.contactPersonIds.includes(id)) await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
        }
        if (entry.householdId) {
          const household = households.find(h => h.id === entry.householdId);
          if (household) {
            const remainingIds = household.memberIds.filter(mid => mid !== id);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') {
                  await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a) });
                }
              }
              await removeHousehold(household.id);
            } else {
              let newPrimary = household.primaryContactId;
              if (newPrimary === id) newPrimary = remainingIds[0];
              await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
            }
          }
        }
      }
      await removeEntry(id);
      if (images[id]) await removeImage(id);
      await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [deleteTarget, allPersons, entries, households, images, reload, setError, selectedId, setSelectedId, setView, setDeleteTarget]);

  const handleDeleteAll = useCallback(async () => {
    setShowDeleteAll(false);
    setDeletingAll(true);
    try {
      for (const entry of entries) { await removeEntry(entry.id); if (images[entry.id]) await removeImage(entry.id); }
      for (const h of households) { await removeHousehold(h.id); if (images[h.id]) await removeImage(h.id); }
      await reload();
      setSelectedId(null);
      setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
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
            if (e.type === 'company' && !ids.includes(e.id) && e.contactPersonIds.includes(id)) await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
          }
          if (entry.householdId) {
            const household = households.find(h => h.id === entry.householdId);
            if (household) {
              const remainingIds = household.memberIds.filter(mid => !ids.includes(mid));
              if (remainingIds.length <= 1) {
                for (const mid of remainingIds) {
                  const member = await loadEntry(mid);
                  if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
                }
                await removeHousehold(household.id);
              } else {
                let newPrimary = household.primaryContactId;
                if (ids.includes(newPrimary)) newPrimary = remainingIds[0];
                await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
              }
            }
          }
        }
        await removeEntry(id);
        if (images[id]) await removeImage(id);
      }
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [allPersons, entries, households, images, reload, setError, setSelectedIds, setSelectMode]);

  const handleBulkStatusChange = useCallback(async (ids: string[], status: 'active' | 'deceased' | 'closed') => {
    try {
      for (const id of ids) {
        const entry = await loadEntry(id);
        if (!entry) continue;
        if (entry.type === 'person') {
          const newStatus = status === 'closed' ? 'active' : status;
          await saveEntry({ ...entry, status: newStatus, deceasedDate: newStatus === 'deceased' ? entry.deceasedDate || '' : '' });
        } else {
          const newStatus = status === 'deceased' ? 'active' : (status === 'closed' ? 'closed' : 'active');
          await saveEntry({ ...entry, companyStatus: newStatus, closedDate: newStatus === 'closed' ? entry.closedDate || '' : '' });
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
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== pid);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
              }
              await removeHousehold(oldHousehold.id);
            } else {
              let newPrimary = oldHousehold.primaryContactId;
              if (newPrimary === pid) newPrimary = remainingIds[0];
              await saveHousehold({ ...oldHousehold, memberIds: remainingIds, primaryContactId: newPrimary });
            }
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
  }, [reload, setError, setSelectedIds, setSelectMode]);

  const handleCreateAndAssignHousehold = useCallback(async (personIds: string[], household: Household) => {
    try {
      const householdAddr = { ...household.address, isPrimary: true as const, label: 'Household' };
      for (const pid of personIds) {
        const person = await loadEntry(pid);
        if (!person || person.type !== 'person') continue;
        if (person.householdId) {
          const oldHousehold = await loadHousehold(person.householdId);
          if (oldHousehold) {
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== pid);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
              }
              await removeHousehold(oldHousehold.id);
            } else {
              let newPrimary = oldHousehold.primaryContactId;
              if (newPrimary === pid) newPrimary = remainingIds[0];
              await saveHousehold({ ...oldHousehold, memberIds: remainingIds, primaryContactId: newPrimary });
            }
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
  }, [reload, setError, setSelectedIds, setSelectMode]);

  return { confirmDelete, handleDeleteAll, handleBulkDelete, handleBulkStatusChange, handleBulkAssignHousehold, handleCreateAndAssignHousehold };
}

