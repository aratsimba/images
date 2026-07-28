import React, { useState, useEffect, useRef } from 'react';
import type { Address, AddressSuggestion } from '../types';
import { ADDR_LABELS, ADDR_LABELS_COMPANY } from '../types';
import { suggestAddresses, useDebounce, ensureOnePrimary } from '../utils';
import { S, colors } from '../styles';
import { COUNTRIES } from '../countryCodes';
import { US_STATES } from '../usStates';

function SingleAddressFields({ addr, onChange, onRemove, canRemove, onSetPrimary, readOnly, hideSetPrimary, labels, householdName, onNavigateHousehold, allowCustomLabel }: {
  addr: Address; onChange: (a: Address) => void; onRemove: () => void; canRemove: boolean; onSetPrimary: () => void;
  readOnly?: boolean; hideSetPrimary?: boolean; labels: string[]; householdName?: string; onNavigateHousehold?: () => void; allowCustomLabel?: boolean;
}) {
  const [suggestions, setSuggestions] = useState<AddressSuggestion[]>([]);
  const [query, setQuery] = useState(addr.street);
  const [addrError, setAddrError] = useState('');
  const [customLabel, setCustomLabel] = useState(() => {
    if (allowCustomLabel && addr.label && !labels.includes(addr.label)) return addr.label;
    return '';
  });
  const debounced = useDebounce(query, 400);
  const wrapRef = useRef<HTMLDivElement>(null);

  const isCustomSelected = allowCustomLabel && (addr.label === 'Custom' || (addr.label && !labels.includes(addr.label) && addr.label !== 'Custom'));
  const selectValue = isCustomSelected ? 'Custom' : addr.label;
  const isPickingRef = useRef(false);

  useEffect(() => { setQuery(addr.street); }, [addr.street]);

  useEffect(() => {
    if (debounced.length >= 3) suggestAddresses(debounced).then(setSuggestions);
    else setSuggestions([]);
  }, [debounced]);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setSuggestions([]);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  // Validate that if any field has data, at least city and state/country are filled
  const validateAddress = (a: Address) => {
    const hasAnyContent = a.street.trim() || a.city.trim() || a.state.trim() || a.zip.trim();
    if (!hasAnyContent) { setAddrError(''); return; }
    const missingFields: string[] = [];
    if (!a.city.trim()) missingFields.push('city');
    if (!a.state.trim()) missingFields.push('state');
    if (missingFields.length > 0) {
      setAddrError(`Please enter at least a ${missingFields.join(' and ')} for this address`);
    } else {
      setAddrError('');
    }
  };

  const handleFieldBlur = () => {
    // Skip validation if user is clicking on a suggestion
    if (isPickingRef.current) return;
    validateAddress(addr);
  };

  const pick = (s: AddressSuggestion) => {
    isPickingRef.current = false;
    const updated = { ...addr, ...s };
    onChange(updated);
    setQuery(s.street);
    setSuggestions([]);
    setAddrError('');
  };

  return (
    <div style={{ border: `1px solid ${colors.border}`, borderRadius: 8, padding: 12, marginBottom: 10, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {readOnly ? (
            <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 11 }}>{addr.label}</span>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <select style={{ ...S.input, width: 'auto', padding: '4px 8px', fontSize: 12 }} value={selectValue}
                onChange={e => {
                  const val = e.target.value;
                  if (val === 'Custom') {
                    setCustomLabel('');
                    onChange({ ...addr, label: 'Custom' });
                  } else {
                    setCustomLabel('');
                    onChange({ ...addr, label: val });
                  }
                }}>
                {labels.map(l => <option key={l} value={l}>{l}</option>)}
              </select>
              {allowCustomLabel && isCustomSelected && (
                <input style={{ ...S.input, width: 120, padding: '4px 8px', fontSize: 12 }}
                  placeholder="Label name"
                  value={customLabel}
                  onChange={e => {
                    setCustomLabel(e.target.value);
                    onChange({ ...addr, label: e.target.value || 'Custom' });
                  }} />
              )}
            </div>
          )}
          {addr.isPrimary ? (
            <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>
          ) : (
            !hideSetPrimary && !readOnly && <button style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }} onClick={onSetPrimary}>Set Primary</button>
          )}
          {readOnly && (
            householdName ? (
              <span style={{ fontSize: 11, color: colors.textSec, fontStyle: 'italic' }}>
                Managed by{' '}
                <span style={{ color: colors.primary, cursor: 'pointer', textDecoration: 'underline' }} onClick={onNavigateHousehold}>{householdName}</span>
              </span>
            ) : (
              <span style={{ fontSize: 11, color: colors.textSec, fontStyle: 'italic' }}>Managed by household</span>
            )
          )}
        </div>
        {canRemove && !readOnly && <button style={S.chipRemove} onClick={onRemove}>×</button>}
      </div>
      <div style={{ ...S.formGrid, position: 'relative' }} ref={wrapRef}>
        <div style={S.fieldFull}>
          <label style={S.label}>Street</label>
          <input style={S.input} value={query} placeholder="Start typing to auto-suggest..."
            disabled={readOnly}
            onChange={e => { setQuery(e.target.value); onChange({ ...addr, street: e.target.value }); if (addrError) setAddrError(''); }}
            onBlur={handleFieldBlur} />
          {!readOnly && suggestions.length > 0 && (
            <div style={S.addrDropdown} onMouseDown={() => { isPickingRef.current = true; }}>
              {suggestions.map((s, i) => (
                <div key={i} style={S.addrItem}
                  onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                  onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                  onClick={() => pick(s)}>
                  {s.street}, {s.city}, {s.state} {s.zip}
                </div>
              ))}
            </div>
          )}
        </div>
        <div><label style={S.label}>City</label><input style={{ ...S.input, ...(addrError && !addr.city.trim() ? { borderColor: colors.danger } : {}) }} value={addr.city} disabled={readOnly} onChange={e => { onChange({ ...addr, city: e.target.value }); if (addrError) setAddrError(''); }} onBlur={handleFieldBlur} /></div>
        <div><label style={S.label}>State</label>
          {(addr.country || 'United States') === 'United States' ? (
            <select style={{ ...S.input, ...(addrError && !addr.state.trim() ? { borderColor: colors.danger } : {}) }} value={addr.state} disabled={readOnly} onChange={e => { onChange({ ...addr, state: e.target.value }); if (addrError) setAddrError(''); }} onBlur={handleFieldBlur}>
              <option value="">Select state</option>
              {US_STATES.map(s => <option key={s.code} value={s.code}>{s.code} - {s.name}</option>)}
            </select>
          ) : (
            <input style={{ ...S.input, ...(addrError && !addr.state.trim() ? { borderColor: colors.danger } : {}) }} value={addr.state} placeholder="State/Province" disabled={readOnly} onChange={e => { onChange({ ...addr, state: e.target.value }); if (addrError) setAddrError(''); }} onBlur={handleFieldBlur} />
          )}
        </div>
        <div><label style={S.label}>ZIP</label><input style={S.input} value={addr.zip} disabled={readOnly} onChange={e => onChange({ ...addr, zip: e.target.value })} onBlur={handleFieldBlur} /></div>
        <div><label style={S.label}>Country</label>
          <select style={S.input} value={addr.country || 'United States'} disabled={readOnly} onChange={e => {
            const newCountry = e.target.value;
            const oldCountry = addr.country || 'United States';
            const stateReset = newCountry !== oldCountry ? '' : addr.state;
            onChange({ ...addr, country: newCountry, state: stateReset });
          }}>
            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
        {addrError && <div style={{ ...S.fieldFull, fontSize: 12, color: colors.danger, marginTop: -4 }}>{addrError}</div>}
      </div>
    </div>
  );
}

export function MultiAddressFields({ addresses, onChange, personMode, companyMode, householdName, onNavigateHousehold }: { addresses: Address[]; onChange: (a: Address[]) => void; personMode?: boolean; companyMode?: boolean; householdName?: string; onNavigateHousehold?: () => void }) {
  const hasHouseholdAddr = personMode && addresses.some(a => a.label === 'Household');
  const labelsForPerson = ADDR_LABELS.filter(l => l !== 'Household');
  const labels = companyMode ? ADDR_LABELS_COMPANY : personMode ? labelsForPerson : ADDR_LABELS;

  const add = () => onChange([...addresses, { street: '', city: '', state: '', zip: '', country: 'United States', isPrimary: false, label: companyMode ? 'Main' : addresses.length === 0 ? 'Home' : 'Work' }]);
  const update = (i: number, a: Address) => { const n = [...addresses]; n[i] = a; onChange(n); };
  const remove = (i: number) => {
    const n = addresses.filter((_, j) => j !== i);
    if (n.length > 0 && !n.some(x => x.isPrimary)) n[0].isPrimary = true;
    onChange(n);
  };
  const setPrimary = (i: number) => onChange(ensureOnePrimary(addresses, i));

  return (
    <div style={S.fieldFull}>
      <div style={{ ...S.section, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span>Addresses</span>
        <button style={{ ...S.btn, padding: '3px 10px', fontSize: 12, ...S.btnPrimary }} onClick={add}>+ Add Address</button>
      </div>
      {addresses.length === 0 && <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>No addresses. Click "+ Add Address" to add one.</div>}
      {addresses.map((a, i) => {
        const isHousehold = personMode && a.label === 'Household';
        return (
          <SingleAddressFields key={i} addr={a} onChange={v => update(i, v)} onRemove={() => remove(i)}
            canRemove={!isHousehold}
            onSetPrimary={() => setPrimary(i)}
            readOnly={isHousehold}
            hideSetPrimary={hasHouseholdAddr}
            labels={labels}
            allowCustomLabel={companyMode}
            householdName={isHousehold ? householdName : undefined}
            onNavigateHousehold={isHousehold ? onNavigateHousehold : undefined} />
        );
      })}
    </div>
  );
}

