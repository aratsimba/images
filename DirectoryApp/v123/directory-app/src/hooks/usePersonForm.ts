import { useState, useMemo, useRef } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import type { DirectoryEntry, Person, EmailEntry, PhoneEntry, Address, Household } from '../types';
import { EMPTY_EMAIL, EMPTY_PHONE, EMPTY_ADDR } from '../types';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, isValidEmail, isValidPhone } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold, saveImage, removeImage } from '../storage';
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
  const [pStatus, setPStatus] = useState<'active' | 'deceased'>('active');
  const [pDeceasedDate, setPDeceasedDate] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());

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
    setPStatus('active'); setPDeceasedDate(''); setEditId(null); setFieldErrors(new Set());
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
    setPNotes(p.notes); setPImage(images[p.id] || null);
    setPStatus(p.status === 'deceased' ? 'deceased' : 'active');
    setPDeceasedDate(p.deceasedDate || '');
    setEditId(p.id);
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
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId, notes: pNotes.trim(),
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
          person.addresses = person.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a);
          const oldHousehold = households.find(h => h.id === oldHouseholdId);
          if (oldHousehold) {
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== id);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a) });
              }
              await removeHousehold(oldHouseholdId);
            } else {
              let newPrimary = oldHousehold.primaryContactId;
              if (newPrimary === id) newPrimary = remainingIds[0];
              await saveHousehold({ ...oldHousehold, memberIds: remainingIds, primaryContactId: newPrimary });
            }
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
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const needsUpdate = spouse.spouseId !== id || spouse.weddingAnniversary !== pAnniversary || JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate) await saveEntry({ ...spouse, spouseId: id, childIds: pChildIds, weddingAnniversary: pAnniversary });
        }
      }
      if (pImage) await saveImage(id, pImage);
      else if (editId && images[editId]) await removeImage(id);
      await reload(); reset(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  return {
    editId, pFirst, setPFirst, pLast, setPLast, pGender, setPGender,
    pBirthday, setPBirthday, pAnniversary, setPAnniversary,
    pEmails, setPEmails, pPhones, setPPhones, pAddrs, setPAddrs,
    pSpouseId, setPSpouseId, pChildIds, setPChildIds,
    pHouseholdId, setPHouseholdId, pNotes, setPNotes,
    pImage, setPImage, pStatus, setPStatus, pDeceasedDate, setPDeceasedDate,
    fieldErrors, setFieldErrors, duplicates,
    pFirstRef, pLastRef, pGenderRef, pEmailSectionRef, pPhoneSectionRef, pAddrSectionRef,
    reset, fill, save,
  };
}

