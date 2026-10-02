import React from 'react';
import { S, colors } from '../styles';
import { ensureOnePrimary } from '../utils';

export function MultiItemField<T extends { isPrimary: boolean; label: string }>({ title, items, onChange, labels, renderInput, emptyFactory, itemName }: {
  title: string; items: T[]; onChange: (items: T[]) => void; labels: string[];
  renderInput: (item: T, update: (v: T) => void) => React.ReactNode;
  emptyFactory: (isPrimary: boolean) => T; itemName: string;
}) {
  const add = () => onChange([...items, emptyFactory(items.length === 0)]);
  const update = (i: number, v: T) => { const n = [...items]; n[i] = v; onChange(n); };
  const remove = (i: number) => {
    const n = items.filter((_, j) => j !== i);
    if (n.length > 0 && !n.some(x => x.isPrimary)) n[0].isPrimary = true;
    onChange(n);
  };
  const setPrimary = (i: number) => onChange(ensureOnePrimary(items, i));

  return (
    <div style={S.fieldFull}>
      <div style={{ ...S.section, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span>{title}</span>
        <button style={{ ...S.btn, padding: '3px 10px', fontSize: 12, ...S.btnPrimary }} onClick={add}>+ Add {itemName}</button>
      </div>
      {items.length === 0 && <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>No {title.toLowerCase()}. Click "+ Add {itemName}" to add one.</div>}
      {items.map((item, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8, padding: '6px 10px', border: `1px solid ${colors.border}`, borderRadius: 6, background: item.isPrimary ? '#f0f7ff' : '#fff' }}>
          <select style={{ ...S.input, width: 'auto', padding: '4px 8px', fontSize: 12, flex: '0 0 auto' }} value={item.label}
            onChange={e => update(i, { ...item, label: e.target.value })}>
            {labels.map(l => <option key={l} value={l}>{l}</option>)}
          </select>
          <div style={{ flex: 1 }}>{renderInput(item, v => update(i, v))}</div>
          {item.isPrimary ? (
            <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10, flex: '0 0 auto' }}>PRIMARY</span>
          ) : (
            <button style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec, flex: '0 0 auto' }} onClick={() => setPrimary(i)}>Primary</button>
          )}
          {items.length > 1 && <button style={{ ...S.chipRemove, flex: '0 0 auto' }} onClick={() => remove(i)}>×</button>}
        </div>
      ))}
    </div>
  );
}

