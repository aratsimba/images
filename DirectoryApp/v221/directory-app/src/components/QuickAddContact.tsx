import React, { useState, useRef, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { S, colors } from '../styles';
import { GENDER_OPTIONS } from '../types';
import { capitalizeName } from '../utils';
import type { Person } from '../types';

interface QuickAddContactProps {
  initialFirstName?: string;
  editPerson?: Person | null;
  onCreated: (person: Person) => void;
  onCancel: () => void;
}

export function QuickAddContactDialog({ initialFirstName, editPerson, onCreated, onCancel }: QuickAddContactProps) {
  const isEdit = !!editPerson;
  // Split "Mary Jane Watson" into first="Mary Jane", last="Watson"
  const initParts = (!isEdit && initialFirstName) ? initialFirstName.trim().split(/\s+/) : [];
  const [firstName, setFirstName] = useState(() => {
    if (editPerson?.firstName) return editPerson.firstName;
    if (initParts.length > 1) return capitalizeName(initParts.slice(0, -1).join(' '));
    if (initParts.length === 1) return capitalizeName(initParts[0]);
    return '';
  });
  const [lastName, setLastName] = useState(() => {
    if (editPerson?.lastName) return editPerson.lastName;
    if (initParts.length > 1) return capitalizeName(initParts[initParts.length - 1]);
    return '';
  });
  const [gender, setGender] = useState(editPerson?.gender || '');
  const [isMissionary, setIsMissionary] = useState(editPerson?.isMissionary || false);
  const [touched, setTouched] = useState<Set<string>>(new Set());
  const firstRef = useRef<HTMLInputElement>(null);

  useEffect(() => { firstRef.current?.focus(); }, []);

  const validate = () => {
    const errs: string[] = [];
    if (!firstName.trim()) errs.push('firstName');
    if (!lastName.trim()) errs.push('lastName');
    if (!gender) errs.push('gender');
    return errs;
  };

  const errs = validate();

  const handleSave = () => {
    setTouched(new Set(['firstName', 'lastName', 'gender']));
    if (errs.length > 0) return;
    const person: Person = {
      id: editPerson?.id || uuidv4(), type: 'person',
      firstName: firstName.trim(), lastName: lastName.trim(),
      gender, birthday: '', weddingAnniversary: '',
      emails: [], phones: [], addresses: [],
      spouseId: '', childIds: [], householdId: '',
      companyId: '', title: '', affiliations: [], isMissionary,
      notes: '',
      status: 'active', deceasedDate: '',
    };
    onCreated(person);
  };

  const showErr = (field: string) => touched.has(field) && errs.includes(field);

  const title = isEdit ? '👤 Edit Pending Contact' : '👤 Quick Add Contact';
  const subtitle = isEdit
    ? 'Update the details below. Changes take effect when you save this company.'
    : 'Enter the contact person\'s details. They will be saved when you save this company.';

  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={{ ...S.dialog, maxWidth: 440 }} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>{title}</h3>
        <p style={{ fontSize: 13, color: colors.textSec, margin: '0 0 16px', lineHeight: 1.5 }}>{subtitle}</p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
          <div>
            <label style={S.label}>First Name *</label>
            <input
              ref={firstRef}
              style={{ ...S.input, ...(showErr('firstName') ? { borderColor: colors.danger } : {}) }}
              value={firstName}
              onChange={e => { setFirstName(e.target.value); setTouched(p => new Set(p).add('firstName')); }}
              onBlur={() => setFirstName(capitalizeName(firstName))}
              placeholder="First name"
            />
            {showErr('firstName') && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Required</div>}
          </div>
          <div>
            <label style={S.label}>Last Name *</label>
            <input
              style={{ ...S.input, ...(showErr('lastName') ? { borderColor: colors.danger } : {}) }}
              value={lastName}
              onChange={e => { setLastName(e.target.value); setTouched(p => new Set(p).add('lastName')); }}
              onBlur={() => setLastName(capitalizeName(lastName))}
              placeholder="Last name"
            />
            {showErr('lastName') && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Required</div>}
          </div>
        </div>
        <div style={{ marginBottom: 12 }}>
          <label style={S.label}>Gender *</label>
          <select
            style={{ ...S.input, ...(showErr('gender') ? { borderColor: colors.danger } : {}) }}
            value={gender}
            onChange={e => { setGender(e.target.value); setTouched(p => new Set(p).add('gender')); }}
          >
            {GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}
          </select>
          {showErr('gender') && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Gender is required</div>}
        </div>
        <div style={{ marginBottom: 20 }}>
          <label style={{ ...S.label, display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', userSelect: 'none' }}>
            <input type="checkbox" checked={isMissionary} onChange={e => setIsMissionary(e.target.checked)} style={{ accentColor: colors.primary }} />
            Missionary
          </label>
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleSave}>
            {isEdit ? 'Update' : 'Add Contact'}
          </button>
        </div>
      </div>
    </div>
  );
}

