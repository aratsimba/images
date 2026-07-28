import React, { useState, useEffect, useRef } from 'react';
import type { Address, AddressSuggestion } from '../types';
import { ADDR_LABELS } from '../types';
import { suggestAddresses, useDebounce, ensureOnePrimary } from '../utils';
import { S, colors } from '../styles';
import { COUNTRIES } from '../countryCodes';

function SingleAddressFields({ addr, onChange, onRemove, canRemove, onSetPrimary }: {
  addr: Address; onChange: (a: Address) => void; onRemove: () => void; canRemove: boolean; onSetPrimary: () => void;
}) {
  const [suggestions, setSuggestions] = useState<AddressSuggestion[]>([]);
  const [query, setQuery] = useState(addr.street);
  const debounced = useDebounce(query, 400);
  const wrapRef = useRef<HTMLDivElement>(null);

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

  const pick = (s: AddressSuggestion) => {
    onChange({ ...addr, ...s });
    setQuery(s.street);
    setSuggestions([]);
  };

  return (
    <div style={{ border: `1px solid ${colors.border}`, borderRadius: 8, padding: 12, marginBottom: 10, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <select style={{ ...S.input, width: 'auto', padding: '4px 8px', fontSize: 12 }} value={addr.label}
            onChange={e => onChange({ ...addr, label: e.target.value })}>
            {ADDR_LABELS.map(l => <option key={l} value={l}>{l}</option>)}
          </select>
          {addr.isPrimary ? (
            <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>
          ) : (
            <button style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }} onClick={onSetPrimary}>Set Primary</button>
          )}
        </div>
        {canRemove && <button style={S.chipRemove} onClick={onRemove}>×</button>}
      </div>
      <div style={{ ...S.formGrid, position: 'relative' }} ref={wrapRef}>
        <div style={S.fieldFull}>
          <label style={S.label}>Street</label>
          <input style={S.input} value={query} placeholder="Start typing to auto-suggest..."
            onChange={e => { setQuery(e.target.value); onChange({ ...addr, street: e.target.value }); }} />
          {suggestions.length > 0 && (
            <div style={S.addrDropdown}>
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
        <div><label style={S.label}>City</label><input style={S.input} value={addr.city} onChange={e => onChange({ ...addr, city: e.target.value })} /></div>
        <div><label style={S.label}>State</label><input style={S.input} value={addr.state} maxLength={2} placeholder="e.g. CA" onChange={e => onChange({ ...addr, state: e.target.value.toUpperCase() })} /></div>
        <div><label style={S.label}>ZIP</label><input style={S.input} value={addr.zip} onChange={e => onChange({ ...addr, zip: e.target.value })} /></div>
        <div><label style={S.label}>Country</label>
          <select style={S.input} value={addr.country || 'United States'} onChange={e => onChange({ ...addr, country: e.target.value })}>
            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>
    </div>
  );
}

export function MultiAddressFields({ addresses, onChange }: { addresses: Address[]; onChange: (a: Address[]) => void }) {
  const add = () => onChange([...addresses, { street: '', city: '', state: '', zip: '', country: 'United States', isPrimary: false, label: addresses.length === 0 ? 'Home' : 'Work' }]);
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
      {addresses.map((a, i) => (
        <SingleAddressFields key={i} addr={a} onChange={v => update(i, v)} onRemove={() => remove(i)}
          canRemove={addresses.length > 1} onSetPrimary={() => setPrimary(i)} />
      ))}
    </div>
  );
}

