import { useState, useMemo, useRef } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import type { DirectoryEntry, Company, Person, EmailEntry, PhoneEntry, Address } from '../types';
import { EMPTY_EMAIL, EMPTY_PHONE, EMPTY_ADDR } from '../types';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, isValidEmail, isValidPhone } from '../utils';
import { saveEntry, saveImage, removeImage } from '../storage';
import { findDuplicates } from '../components/DuplicateWarning';

interface CompanyFormDeps {
  entries: DirectoryEntry[];
  images: Record<string, string>;
  reload: () => Promise<void>;
  setError: (msg: string) => void;
  setView: (v: any) => void;
}

export function useCompanyForm(deps: CompanyFormDeps) {
  const { entries, images, reload, setError, setView } = deps;

  const [editId, setEditId] = useState<string | null>(null);
  const [cName, setCName] = useState('');
  const [cIndustry, setCIndustry] = useState('');
  const [cWebsite, setCWebsite] = useState('');
  const [cWebsiteError, setCWebsiteError] = useState('');
  const [cEmails, setCEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [cPhones, setCPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [cAddrs, setCAddrs] = useState<Address[]>([{ ...EMPTY_ADDR, label: 'Main' }]);
  const [cContactIds, setCContactIds] = useState<string[]>([]);
  const [cNotes, setCNotes] = useState('');
  const [cImage, setCImage] = useState<string | null>(null);
  const [cStatus, setCStatus] = useState<'active' | 'closed'>('active');
  const [cClosedDate, setCClosedDate] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());

  const cNameRef = useRef<HTMLInputElement>(null);
  const cWebsiteRef = useRef<HTMLInputElement>(null);
  const cEmailSectionRef = useRef<HTMLDivElement>(null);
  const cPhoneSectionRef = useRef<HTMLDivElement>(null);
  const cAddrSectionRef = useRef<HTMLDivElement>(null);

  const duplicates = useMemo(() =>
    findDuplicates(entries, editId, cName, getPrimary(cEmails)?.address || '', getPrimary(cPhones)?.number || ''),
    [entries, editId, cName, cEmails, cPhones]
  );

  const reset = () => {
    setCName(''); setCIndustry(''); setCWebsite(''); setCWebsiteError('');
    setCEmails([{ ...EMPTY_EMAIL }]); setCPhones([{ ...EMPTY_PHONE }]); setCAddrs([{ ...EMPTY_ADDR, label: 'Main' }]);
    setCContactIds([]); setCNotes(''); setCImage(null);
    setCStatus('active'); setCClosedDate(''); setEditId(null); setFieldErrors(new Set());
  };

  const fill = (c: Company) => {
    setCName(c.name); setCIndustry(c.industry); setCWebsite(c.website || ''); setCWebsiteError('');
    setCEmails(c.emails.length ? [...c.emails] : [{ ...EMPTY_EMAIL }]);
    setCPhones(c.phones.length ? c.phones.map(ph => ({ ...ph, number: formatPhoneDisplay(ph.number) })) : [{ ...EMPTY_PHONE }]);
    setCAddrs(c.addresses.length ? [...c.addresses] : [{ ...EMPTY_ADDR }]);
    setCContactIds([...c.contactPersonIds]); setCNotes(c.notes); setCImage(images[c.id] || null);
    setCStatus(c.companyStatus === 'closed' ? 'closed' : 'active');
    setCClosedDate(c.closedDate || '');
    setEditId(c.id);
  };

  const scrollToAndFocus = (ref: React.RefObject<HTMLElement | null>) => {
    setTimeout(() => { ref.current?.scrollIntoView({ behavior: 'smooth', block: 'center' }); if (ref.current && 'focus' in ref.current) (ref.current as HTMLElement).focus(); }, 50);
  };

  const save = async () => {
    const errs = new Set<string>();
    if (!cName.trim()) errs.add('cName');
    if (cEmails.find(e => !isValidEmail(e.address))) errs.add('cEmail');
    if (cPhones.find(p => !isValidPhone(p.number))) errs.add('cPhone');
    if (cAddrs.find(a => (a.street.trim() || a.city.trim() || a.state.trim() || a.zip.trim()) && (!a.city.trim() || !a.state.trim()))) errs.add('cAddr');
    if (cWebsite.trim()) {
      try {
        const url = cWebsite.trim().match(/^https?:\/\//) ? cWebsite.trim() : `https://${cWebsite.trim()}`;
        const parsed = new URL(url);
        if (!parsed.hostname.includes('.')) throw new Error('invalid');
        setCWebsiteError('');
      } catch { setCWebsiteError('Please enter a valid URL (e.g. https://example.com)'); errs.add('cWebsite'); }
    } else { setCWebsiteError(''); }

    if (errs.size > 0) {
      setFieldErrors(errs);
      setError('');
      if (errs.has('cName')) { scrollToAndFocus(cNameRef); return; }
      if (errs.has('cWebsite')) { scrollToAndFocus(cWebsiteRef); return; }
      if (errs.has('cEmail')) { scrollToAndFocus(cEmailSectionRef); return; }
      if (errs.has('cPhone')) { scrollToAndFocus(cPhoneSectionRef); return; }
      if (errs.has('cAddr')) { scrollToAndFocus(cAddrSectionRef); return; }
      return;
    }
    setFieldErrors(new Set());
    setError('');
    const id = editId || uuidv4();
    const cleanPhones = cPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = cEmails.filter(e => e.address.trim());
    const cleanAddrs = cAddrs.filter(a => a.street.trim() || a.city.trim());
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];
    let websiteValue = cWebsite.trim();
    if (websiteValue) {
      if (!websiteValue.match(/^https?:\/\//)) websiteValue = `https://${websiteValue}`;
      const parsed = new URL(websiteValue);
      parsed.hostname = parsed.hostname.replace(/^www\./, '');
      websiteValue = parsed.toString();
      if (parsed.pathname === '/' && !parsed.search && !parsed.hash) websiteValue = websiteValue.replace(/\/$/, '');
    }
    const company: Company = {
      id, type: 'company', name: cName.trim(), industry: cIndustry.trim(), website: websiteValue,
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      contactPersonIds: cContactIds, notes: cNotes.trim(),
      companyStatus: cStatus, closedDate: cStatus !== 'active' ? cClosedDate : '',
    };
    try {
      await saveEntry(company);
      if (cImage) await saveImage(id, cImage);
      else if (editId && images[editId]) await removeImage(id);
      await reload(); reset(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  return {
    editId, cName, setCName, cIndustry, setCIndustry, cWebsite, setCWebsite, cWebsiteError, setCWebsiteError,
    cEmails, setCEmails, cPhones, setCPhones, cAddrs, setCAddrs,
    cContactIds, setCContactIds, cNotes, setCNotes,
    cImage, setCImage, cStatus, setCStatus, cClosedDate, setCClosedDate,
    fieldErrors, setFieldErrors, duplicates,
    cNameRef, cWebsiteRef, cEmailSectionRef, cPhoneSectionRef, cAddrSectionRef,
    reset, fill, save,
  };
}

