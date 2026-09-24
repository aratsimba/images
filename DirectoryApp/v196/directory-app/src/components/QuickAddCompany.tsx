import React, { useState, useRef, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { S, colors } from '../styles';
import { capitalizeName } from '../utils';
import type { Company, Address } from '../types';
import { EMPTY_ADDR } from '../types';
import { MultiAddressFields } from './AddressFields';

interface QuickAddCompanyProps {
  initialName?: string;
  editCompany?: Company | null;
  onCreated: (company: Company) => void;
  onCancel: () => void;
}

export function QuickAddCompanyDialog({ initialName, editCompany, onCreated, onCancel }: QuickAddCompanyProps) {
  const isEdit = !!editCompany;
  const [name, setName] = useState(() => {
    if (editCompany) return editCompany.name;
    if (initialName) return capitalizeName(initialName);
    return '';
  });
  const [website, setWebsite] = useState(editCompany?.website || '');
  const [websiteError, setWebsiteError] = useState('');
  const [addrs, setAddrs] = useState<Address[]>(() => {
    if (editCompany && editCompany.addresses.length > 0) return [...editCompany.addresses];
    return [{ ...EMPTY_ADDR, label: 'Main' }];
  });
  const [touched, setTouched] = useState<Set<string>>(new Set());
  const nameRef = useRef<HTMLInputElement>(null);

  useEffect(() => { nameRef.current?.focus(); }, []);

  const hasNameError = !name.trim();

  const handleSave = () => {
    setTouched(new Set(['name']));
    if (hasNameError) return;

    // Validate website if provided
    if (website.trim()) {
      try {
        const raw = website.trim().match(/^https?:\/\//) ? website.trim() : `https://${website.trim()}`;
        const parsed = new URL(raw);
        if (!parsed.hostname.includes('.')) throw new Error('invalid');
      } catch {
        setWebsiteError('Please enter a valid URL (e.g. https://example.com)');
        return;
      }
    }

    let finalWebsite = website.trim();
    if (finalWebsite && !finalWebsite.match(/^https?:\/\//)) {
      finalWebsite = `https://${finalWebsite}`;
    }

    const cleanAddrs = addrs.filter(a => a.street.trim() || a.city.trim());

    const company: Company = {
      id: editCompany?.id || uuidv4(),
      type: 'company',
      name: name.trim(),
      industry: editCompany?.industry || '',
      website: finalWebsite,
      emails: editCompany?.emails || [],
      phones: editCompany?.phones || [],
      addresses: cleanAddrs,
      contactPersonIds: editCompany?.contactPersonIds || [],
      notes: editCompany?.notes || '',
      companyStatus: 'active',
      closedDate: '',
    };
    onCreated(company);
  };

  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={{ ...S.dialog, maxWidth: 520 }} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>{isEdit ? '🏢 Edit Pending Company' : '🏢 Quick Add Company'}</h3>
        <p style={{ fontSize: 13, color: colors.textSec, margin: '0 0 16px', lineHeight: 1.5 }}>
          {isEdit
            ? 'Update the company details below. Changes take effect when you save this person.'
            : 'Enter the company details. The company will be saved when you save this person.'}
        </p>
        <div style={{ marginBottom: 12 }}>
          <label style={S.label}>Company Name *</label>
          <input
            ref={nameRef}
            style={{ ...S.input, ...(touched.has('name') && hasNameError ? { borderColor: colors.danger } : {}) }}
            value={name}
            onChange={e => { setName(e.target.value); setTouched(p => new Set(p).add('name')); }}
            onBlur={() => setName(capitalizeName(name))}
            placeholder="Company name"
          />
          {touched.has('name') && hasNameError && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Company name is required</div>}
        </div>
        <div style={{ marginBottom: 12 }}>
          <label style={S.label}>Website</label>
          <input
            style={{ ...S.input, ...(websiteError ? { borderColor: colors.danger } : {}) }}
            value={website}
            onChange={e => { setWebsite(e.target.value); setWebsiteError(''); }}
            placeholder="https://www.example.com"
          />
          {websiteError && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>{websiteError}</div>}
        </div>
        <div style={{ marginBottom: 16 }}>
          <MultiAddressFields addresses={addrs} onChange={setAddrs} companyMode />
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleSave}>
            {isEdit ? 'Update' : 'Add Company'}
          </button>
        </div>
      </div>
    </div>
  );
}

