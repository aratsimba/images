import { useState, useMemo, useRef } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import type { DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address, Household } from '../types';
import { EMPTY_EMAIL, EMPTY_PHONE, EMPTY_ADDR } from '../types';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, isValidEmail, isValidPhone } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold, removePersonFromHousehold, saveImage, removeImage } from '../storage';
import { findDuplicates } from '../components/DuplicateWarning';

interface PersonFormDeps {
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  reload: () => Promise<void>;
  setError: (msg: string) => void;
  setView: (v: any) => void;
}

export function usePersonForm(deps: PersonFormDeps) {
  const { entries, allPersons, households, images, reload, setError, setView } = deps;

  const [editId, setEditId] = useState<string | null>(null);
  const [pFirst, setPFirst] = useState('');
  const [pLast, setPLast] = useState('');
  const [pGender, setPGender] = useState('');
  const [pBirthday, setPBirthday] = useState('');
  const [pAnniversary, setPAnniversary] = useState('');
  const [pEmails, setPEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [pPhones, setPPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [pAddrs, setPAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [pSpouseId, setPSpouseId] = useState('');
  const [pChildIds, setPChildIds] = useState<string[]>([]);
  const [pHouseholdId, setPHouseholdId] = useState('');
  const [pNotes, setPNotes] = useState('');
  const [pImage, setPImage] = useState<string | null>(null);
  const [pCompanyId, setPCompanyId] = useState('');
  const [pTitle, setPTitle] = useState('');
  const [pendingCompany, setPendingCompany] = useState<Company | null>(null);
  const [pStatus, setPStatus] = useState<'active' | 'deceased'>('active');
  const [pDeceasedDate, setPDeceasedDate] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());
  const [pendingPersons, setPendingPersons] = useState<Person[]>([]);
  const [hhCreateMode, setHhCreateMode] = useState(false);
  const [newHhName, setNewHhName] = useState('');
  const [hhNameError, setHhNameError] = useState('');
  const [newHhPrimary, setNewHhPrimary] = useState('');

  const pFirstRef = useRef<HTMLInputElement>(null);
  const pLastRef = useRef<HTMLInputElement>(null);
  const pGenderRef = useRef<HTMLSelectElement>(null);
  const pEmailSectionRef = useRef<HTMLDivElement>(null);
  const pPhoneSectionRef = useRef<HTMLDivElement>(null);
  const pAddrSectionRef = useRef<HTMLDivElement>(null);

  const duplicates = useMemo(() =>
    findDuplicates(entries, editId, `${pFirst} ${pLast}`, getPrimary(pEmails)?.address || '', getPrimary(pPhones)?.number || ''),
    [entries, editId, pFirst, pLast, pEmails, pPhones]
  );

  const reset = () => {
    setPFirst(''); setPLast(''); setPGender(''); setPBirthday(''); setPAnniversary('');
    setPEmails([{ ...EMPTY_EMAIL }]); setPPhones([{ ...EMPTY_PHONE }]); setPAddrs([{ ...EMPTY_ADDR }]);
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(''); setPNotes(''); setPImage(null);
    setPCompanyId(''); setPTitle(''); setPendingCompany(null);
    setPStatus('active'); setPDeceasedDate(''); setEditId(null); setFieldErrors(new Set());
    setPendingPersons([]); setHhCreateMode(false); setNewHhName(''); setHhNameError(''); setNewHhPrimary('');
  };

  const fill = (p: Person) => {
    setPFirst(p.firstName); setPLast(p.lastName);
    setPGender(p.gender || ''); setPBirthday(p.birthday || ''); setPAnniversary(p.weddingAnniversary || '');
    setPEmails(p.emails.length ? [...p.emails] : [{ ...EMPTY_EMAIL }]);
    setPPhones(p.phones.length ? p.phones.map(ph => ({ ...ph, number: formatPhoneDisplay(ph.number) })) : [{ ...EMPTY_PHONE }]);
    setPAddrs(p.addresses.length ? [...p.addresses] : [{ ...EMPTY_ADDR }]);
    setPSpouseId(p.spouseId);
    let mergedChildIds = [...p.childIds];
    if (p.spouseId) {
      const spouse = entries.find(e => e.id === p.spouseId);
      if (spouse && spouse.type === 'person') mergedChildIds = Array.from(new Set([...p.childIds, ...spouse.childIds]));
    }
    setPChildIds(mergedChildIds);
    setPHouseholdId(p.householdId || '');
    setPCompanyId(p.companyId || '');
    setPTitle(p.title || '');
    setPendingCompany(null);
    setPNotes(p.notes); setPImage(images[p.id] || null);
    setPStatus(p.status === 'deceased' ? 'deceased' : 'active');
    setPDeceasedDate(p.deceasedDate || '');
    setEditId(p.id);
    setPendingPersons([]); setHhCreateMode(false); setNewHhName(''); setHhNameError(''); setNewHhPrimary('');
  };

  const scrollToAndFocus = (ref: React.RefObject<HTMLElement | null>) => {
    setTimeout(() => { ref.current?.scrollIntoView({ behavior: 'smooth', block: 'center' }); if (ref.current && 'focus' in ref.current) (ref.current as HTMLElement).focus(); }, 50);
  };

  const save = async () => {
    const errs = new Set<string>();
    if (!pFirst.trim()) errs.add('pFirst');
    if (!pLast.trim()) errs.add('pLast');
    if (!pGender) errs.add('pGender');
    if (pEmails.find(e => !isValidEmail(e.address))) errs.add('pEmail');
    if (pPhones.find(p => !isValidPhone(p.number))) errs.add('pPhone');
    if (pAddrs.find(a => (a.street.trim() || a.city.trim() || a.state.trim() || a.zip.trim()) && (!a.city.trim() || !a.state.trim()))) errs.add('pAddr');

    if (errs.size > 0) {
      setFieldErrors(errs);
      setError('');
      if (errs.has('pFirst')) { scrollToAndFocus(pFirstRef); return; }
      if (errs.has('pLast')) { scrollToAndFocus(pLastRef); return; }
      if (errs.has('pGender')) { scrollToAndFocus(pGenderRef); return; }
      if (errs.has('pEmail')) { scrollToAndFocus(pEmailSectionRef); return; }
      if (errs.has('pPhone')) { scrollToAndFocus(pPhoneSectionRef); return; }
      if (errs.has('pAddr')) { scrollToAndFocus(pAddrSectionRef); return; }
      return;
    }

    // Validate new household name if create mode is active and conditions are still met
    const hasFamily = !!pSpouseId || pChildIds.length > 0;
    const hasAddress = pAddrs.some(a => a.street.trim() && a.city.trim() && a.state.trim());
    const shouldCreateHousehold = hhCreateMode && !pHouseholdId && hasFamily && hasAddress;
    if (shouldCreateHousehold) {
      const trimmedName = newHhName.trim();
      if (!trimmedName) {
        setHhNameError('Household name is required');
        return;
      }
      const isDupe = households.some(h => h.name.trim().toLowerCase() === trimmedName.toLowerCase());
      if (isDupe) {
        setHhNameError('A household with this name already exists');
        return;
      }
      setHhNameError('');
    }
    setFieldErrors(new Set());
    setError('');
    const id = editId || uuidv4();
    const cleanPhones = pPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = pEmails.filter(e => e.address.trim());
    const cleanAddrs = pAddrs.filter(a => a.street.trim() || a.city.trim());
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];

    const person: Person = {
      id, type: 'person', firstName: pFirst.trim(), lastName: pLast.trim(),
      gender: pGender, birthday: pBirthday, weddingAnniversary: pAnniversary,
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId,
      companyId: pCompanyId, title: pTitle.trim(),
      notes: pNotes.trim(),
      status: pStatus, deceasedDate: pStatus === 'deceased' ? pDeceasedDate : '',
    };

    try {
      if (editId) {
        const oldPerson = allPersons.find(p => p.id === editId);
        if (oldPerson && oldPerson.spouseId && oldPerson.spouseId !== pSpouseId) {
          const oldSpouse = await loadEntry(oldPerson.spouseId);
          if (oldSpouse && oldSpouse.type === 'person') {
            await saveEntry({ ...oldSpouse, spouseId: '', weddingAnniversary: '', childIds: Array.from(new Set([...oldSpouse.childIds, ...pChildIds])) });
          }
          person.weddingAnniversary = '';
        }
        const oldHouseholdId = oldPerson?.householdId || '';
        if (oldHouseholdId && oldHouseholdId !== pHouseholdId) {
          // Remove household address entirely from this person
          person.addresses = person.addresses.filter(a => a.label !== 'Household');
          if (person.addresses.length > 0 && !person.addresses.some(a => a.isPrimary)) {
            person.addresses[0] = { ...person.addresses[0], isPrimary: true };
          }
          const oldHousehold = households.find(h => h.id === oldHouseholdId);
          if (oldHousehold) {
            await removePersonFromHousehold(id, oldHousehold, allPersons);
            // removePersonFromHousehold already saves the removed person's address changes,
            // but we're about to saveEntry(person) below with all final changes anyway
          }
        }
        if (pHouseholdId && pHouseholdId !== oldHouseholdId) {
          const newHousehold = households.find(h => h.id === pHouseholdId);
          if (newHousehold && !newHousehold.memberIds.includes(id)) {
            await saveHousehold({ ...newHousehold, memberIds: [...newHousehold.memberIds, id] });
            const householdAddr = { ...newHousehold.address, isPrimary: true as const, label: 'Household' };
            const pIdx = person.addresses.findIndex(a => a.isPrimary);
            if (pIdx >= 0) person.addresses[pIdx] = householdAddr;
            else if (person.addresses.length > 0) person.addresses[0] = householdAddr;
            else person.addresses.push(householdAddr);
          }
        }
      } else if (pHouseholdId) {
        const newHousehold = households.find(h => h.id === pHouseholdId);
        if (newHousehold && !newHousehold.memberIds.includes(id)) {
          await saveHousehold({ ...newHousehold, memberIds: [...newHousehold.memberIds, id] });
          const householdAddr = { ...newHousehold.address, isPrimary: true as const, label: 'Household' };
          const pIdx = person.addresses.findIndex(a => a.isPrimary);
          if (pIdx >= 0) person.addresses[pIdx] = householdAddr;
          else if (person.addresses.length > 0) person.addresses[0] = householdAddr;
          else person.addresses.push(householdAddr);
        }
      }
      await saveEntry(person);

      // ── Bidirectional company–person sync ──
      const oldCompanyId = editId ? (allPersons.find(p => p.id === editId)?.companyId || '') : '';
      const newCompanyId = pCompanyId;
      // Remove person from old company's contactPersonIds if company changed
      if (oldCompanyId && oldCompanyId !== newCompanyId) {
        const oldCompany = entries.find(e => e.id === oldCompanyId);
        if (oldCompany && oldCompany.type === 'company' && oldCompany.contactPersonIds.includes(id)) {
          await saveEntry({ ...oldCompany, contactPersonIds: oldCompany.contactPersonIds.filter(pid => pid !== id) });
        }
      }
      // Add person to new company's contactPersonIds if not already present
      if (newCompanyId && newCompanyId !== oldCompanyId) {
        // Company may be the pending one (not yet saved) or existing
        const existingCompany = entries.find(e => e.id === newCompanyId);
        if (existingCompany && existingCompany.type === 'company' && !existingCompany.contactPersonIds.includes(id)) {
          await saveEntry({ ...existingCompany, contactPersonIds: [...existingCompany.contactPersonIds, id] });
        }
      }

      // If the person belongs to a household, check if the household address was changed
      if (person.householdId) {
        const hhAddr = person.addresses.find(a => a.label === 'Household');
        if (hhAddr) {
          const household = households.find(h => h.id === person.householdId);
          if (household) {
            const oldA = household.address;
            const changed = oldA.street !== hhAddr.street || oldA.street2 !== (hhAddr.street2 || '') ||
              oldA.city !== hhAddr.city || oldA.state !== hhAddr.state ||
              oldA.zip !== hhAddr.zip || oldA.country !== hhAddr.country;
            if (changed) {
              const newHhAddr = { ...hhAddr, label: 'Household', isPrimary: true };
              // Update the household record
              await saveHousehold({ ...household, address: { ...hhAddr, label: 'Household' } });
              // Update all other members' household address
              for (const mid of household.memberIds) {
                if (mid === id) continue;
                const member = await loadEntry(mid);
                if (member && member.type === 'person') {
                  const memberAddrs = member.addresses.map(a =>
                    a.label === 'Household' ? { ...newHhAddr } : a
                  );
                  await saveEntry({ ...member, addresses: memberAddrs });
                }
              }
            }
          }
        }
      }

      // Persist any pending quick-added relatives (must happen before spouse sync)
      for (const pending of pendingPersons) {
        await saveEntry(pending);
      }
      // Persist pending quick-added company (with this person as contact)
      if (pendingCompany) {
        const companyToSave = pendingCompany.id === newCompanyId && !pendingCompany.contactPersonIds.includes(id)
          ? { ...pendingCompany, contactPersonIds: [...pendingCompany.contactPersonIds, id] }
          : pendingCompany;
        await saveEntry(companyToSave);
      }
      // Create new household if in create mode
      if (shouldCreateHousehold && newHhName.trim()) {
        const primaryAddr = getPrimary(person.addresses);
        const hhAddr = primaryAddr
          ? { ...primaryAddr, isPrimary: true, label: 'Household' }
          : { street: '', street2: '', city: '', state: '', zip: '', country: 'United States', isPrimary: true, label: 'Household' };
        const memberIds = [id];
        if (pSpouseId) memberIds.push(pSpouseId);
        for (const cid of pChildIds) {
          if (!memberIds.includes(cid)) memberIds.push(cid);
        }
        const hhId = uuidv4();
        const resolvedPrimary = newHhPrimary === '__self__' ? id : newHhPrimary;
        const newHousehold: Household = {
          id: hhId, name: newHhName.trim(), address: hhAddr,
          memberIds, primaryContactId: resolvedPrimary && memberIds.includes(resolvedPrimary) ? resolvedPrimary : id,
        };
        await saveHousehold(newHousehold);
        // Update current person's householdId and set primary address label to "Household"
        person.householdId = hhId;
        const pIdx = person.addresses.findIndex(a => a.isPrimary);
        if (pIdx >= 0) person.addresses[pIdx] = { ...person.addresses[pIdx], label: 'Household' };
        await saveEntry(person);
        // Update all other members: set householdId and copy household address
        for (const mid of memberIds) {
          if (mid === id) continue;
          const member = await loadEntry(mid);
          if (member && member.type === 'person') {
            const memberAddrs = [...member.addresses];
            const mIdx = memberAddrs.findIndex(a => a.isPrimary);
            if (mIdx >= 0) {
              memberAddrs[mIdx] = { ...hhAddr, isPrimary: true };
            } else if (memberAddrs.length > 0) {
              memberAddrs[0] = { ...hhAddr, isPrimary: true };
            } else {
              memberAddrs.push({ ...hhAddr, isPrimary: true });
            }
            await saveEntry({ ...member, householdId: hhId, addresses: memberAddrs });
          }
        }
      }
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const needsUpdate = spouse.spouseId !== id || spouse.weddingAnniversary !== pAnniversary || JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate) await saveEntry({ ...spouse, spouseId: id, childIds: pChildIds, weddingAnniversary: pAnniversary });
        }
      }
      if (pImage) await saveImage(id, pImage);
      else if (editId && images[editId]) await removeImage(id);
      const savedName = `${pFirst.trim()} ${pLast.trim()}`;
      await reload(); reset(); setView('list');
      return savedName;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  };

  const addPendingPerson = (person: Person) => {
    setPendingPersons(prev => [...prev, person]);
  };

  const removePendingPerson = (id: string) => {
    setPendingPersons(prev => prev.filter(p => p.id !== id));
  };

  const updatePendingPerson = (updated: Person) => {
    setPendingPersons(prev => prev.map(p => p.id === updated.id ? updated : p));
  };

  return {
    editId, pFirst, setPFirst, pLast, setPLast, pGender, setPGender,
    pBirthday, setPBirthday, pAnniversary, setPAnniversary,
    pEmails, setPEmails, pPhones, setPPhones, pAddrs, setPAddrs,
    pSpouseId, setPSpouseId, pChildIds, setPChildIds,
    pHouseholdId, setPHouseholdId, pNotes, setPNotes,
    pImage, setPImage, pCompanyId, setPCompanyId, pTitle, setPTitle,
    pendingCompany, setPendingCompany,
    pStatus, setPStatus, pDeceasedDate, setPDeceasedDate,
    fieldErrors, setFieldErrors, duplicates,
    pendingPersons, addPendingPerson, removePendingPerson, updatePendingPerson,
    hhCreateMode, setHhCreateMode, newHhName, setNewHhName, hhNameError, setHhNameError,
    newHhPrimary, setNewHhPrimary,
    pFirstRef, pLastRef, pGenderRef, pEmailSectionRef, pPhoneSectionRef, pAddrSectionRef,
    reset, fill, save,
  };
}

