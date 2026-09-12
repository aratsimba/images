import React, { useState, useRef, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { S, colors } from '../styles';
import { GENDER_OPTIONS } from '../types';
import type { Person } from '../types';

type Mode = 'spouse' | 'child';

interface QuickAddRelativeProps {
  mode: Mode;
  currentGender: string;
  defaultLastName?: string;
  initialFirstName?: string;
  editPerson?: Person | null;
  onCreated: (person: Person) => void;
  onCancel: () => void;
}

export function QuickAddRelativeDialog({ mode, currentGender, defaultLastName, initialFirstName, editPerson, onCreated, onCancel }: QuickAddRelativeProps) {
  const isEdit = !!editPerson;
  const [firstName, setFirstName] = useState(editPerson?.firstName || (!isEdit && initialFirstName ? initialFirstName : ''));
  const [lastName, setLastName] = useState(editPerson?.lastName || (isEdit ? '' : defaultLastName || ''));
  const [gender, setGender] = useState(() => {
    if (editPerson) return editPerson.gender || '';
    if (mode === 'spouse') {
      if (currentGender === 'Male') return 'Female';
      if (currentGender === 'Female') return 'Male';
      return '';
    }
    return '';
  });
  const [touched, setTouched] = useState<Set<string>>(new Set());
  const firstRef = useRef<HTMLInputElement>(null);

  useEffect(() => { firstRef.current?.focus(); }, []);

  const validate = () => {
    const errs: string[] = [];
    if (!firstName.trim()) errs.push('firstName');
    if (!lastName.trim()) errs.push('lastName');
    if (mode === 'child' && !gender) errs.push('gender');
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
      spouseId: '', childIds: [], householdId: '', notes: '',
      status: 'active', deceasedDate: '',
    };
    onCreated(person);
  };

  const showErr = (field: string) => touched.has(field) && errs.includes(field);

  const title = isEdit
    ? (mode === 'spouse' ? '💍 Edit Pending Spouse' : '🧒 Edit Pending Child')
    : (mode === 'spouse' ? '💍 Quick Add Spouse' : '🧒 Quick Add Child');

  const subtitle = isEdit
    ? 'Update the details below. Changes take effect when you save this person.'
    : (mode === 'spouse'
      ? 'Enter the spouse\'s name. They will be saved when you save this person.'
      : 'Enter the child\'s name and gender. They will be saved when you save this person.');

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
              placeholder="Last name"
            />
            {showErr('lastName') && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Required</div>}
          </div>
        </div>
        <div style={{ marginBottom: 20 }}>
          <label style={S.label}>Gender {mode === 'child' ? '*' : ''}</label>
          <select
            style={{ ...S.input, ...(showErr('gender') ? { borderColor: colors.danger } : {}) }}
            value={gender}
            onChange={e => { setGender(e.target.value); setTouched(p => new Set(p).add('gender')); }}
          >
            {GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}
          </select>

          {showErr('gender') && <div style={{ fontSize: 11, color: colors.danger, marginTop: 2 }}>Gender is required</div>}
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleSave}>
            {isEdit ? 'Update' : `Add ${mode === 'spouse' ? 'Spouse' : 'Child'}`}
          </button>
        </div>
      </div>
    </div>
  );
}

