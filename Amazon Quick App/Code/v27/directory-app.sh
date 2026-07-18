#!/usr/bin/env bash
# Directory App — Self-Extracting Source Code
# Run: bash directory-app.sh
# This will create a "directory-app/" folder with the full project structure.

set -e
ROOT="directory-app"
mkdir -p "$ROOT/src/components"
echo "Extracting files into $ROOT/ ..."

cat > "$ROOT/src/types.ts" << '__EOF_SRC_TYPES_TS__'
export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  isPrimary: boolean;
  label: string;
}

export interface PhoneEntry {
  number: string;
  isPrimary: boolean;
  label: string;
}

export interface EmailEntry {
  address: string;
  isPrimary: boolean;
  label: string;
}

export interface Person {
  id: string;
  type: 'person';
  firstName: string;
  lastName: string;
  emails: EmailEntry[];
  phones: PhoneEntry[];
  addresses: Address[];
  spouseId: string;
  childIds: string[];
  householdId: string;
  notes: string;
}

export interface Company {
  id: string;
  type: 'company';
  name: string;
  industry: string;
  emails: EmailEntry[];
  phones: PhoneEntry[];
  addresses: Address[];
  contactPersonIds: string[];
  notes: string;
}

export type DirectoryEntry = Person | Company;
export type View = 'list' | 'personForm' | 'companyForm' | 'detail' | 'import';
export type SortField = 'name' | 'type' | 'dateAdded';
export type SortDir = 'asc' | 'desc';
export type TypeFilter = 'all' | 'person' | 'company';

export interface AddressSuggestion {
  street: string;
  city: string;
  state: string;
  zip: string;
}

export interface DuplicateMatch {
  entry: DirectoryEntry;
  reasons: string[];
}

export const EMPTY_ADDR: Address = { street: '', city: '', state: '', zip: '', isPrimary: true, label: 'Home' };
export const EMPTY_PHONE: PhoneEntry = { number: '', isPrimary: true, label: 'Mobile' };
export const EMPTY_EMAIL: EmailEntry = { address: '', isPrimary: true, label: 'Personal' };

export const ADDR_LABELS = ['Home', 'Work', 'Other'];
export const PHONE_LABELS_PERSON = ['Home', 'Work', 'Mobile', 'Other'];
export const PHONE_LABELS_COMPANY = ['Main', 'Fax', 'Other'];
export const EMAIL_LABELS_PERSON = ['Personal', 'Work', 'Other'];
export const EMAIL_LABELS_COMPANY = ['Main', 'Other'];
// Legacy combined arrays for backward compatibility
export const PHONE_LABELS = ['Home', 'Work', 'Mobile', 'Main', 'Fax', 'Other'];
export const EMAIL_LABELS = ['Personal', 'Work', 'Main', 'Other'];

export const TABLE = 'directory-entries';

__EOF_SRC_TYPES_TS__

cat > "$ROOT/src/styles.ts" << '__EOF_SRC_STYLES_TS__'
import React from 'react';

export const colors = {
  bg: '#f4f6f9', card: '#fff', primary: '#1a73e8', primaryDark: '#1558b0',
  danger: '#d93025', dangerDark: '#b3261e', text: '#202124', textSec: '#5f6368',
  border: '#dadce0', hover: '#f1f3f4', accent: '#e8f0fe',
};

export const S: Record<string, React.CSSProperties> = {
  app: { fontFamily: '"Amazon Ember", -apple-system, sans-serif', background: colors.bg, minHeight: '100vh', color: colors.text },
  header: { background: colors.primary, color: '#fff', padding: '16px 24px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', boxShadow: '0 2px 4px rgba(0,0,0,.1)' },
  headerTitle: { fontSize: 22, fontWeight: 700, margin: 0, cursor: 'pointer' },
  body: { maxWidth: 960, margin: '0 auto', padding: '24px 16px' },
  searchWrap: { position: 'relative' as const, flex: 1, maxWidth: 420, marginLeft: 24 },
  searchInput: { width: '100%', padding: '8px 12px', borderRadius: 6, border: 'none', fontSize: 14, outline: 'none', boxSizing: 'border-box' as const },
  dropdown: { position: 'absolute' as const, top: 40, left: 0, right: 0, background: '#fff', borderRadius: 6, boxShadow: '0 4px 12px rgba(0,0,0,.15)', zIndex: 10, maxHeight: 280, overflowY: 'auto' as const },
  dropdownItem: { padding: '10px 14px', cursor: 'pointer', borderBottom: `1px solid ${colors.border}`, fontSize: 14 },
  btnRow: { display: 'flex', gap: 10, marginBottom: 20, flexWrap: 'wrap' as const },
  btn: { padding: '9px 18px', borderRadius: 6, border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: 14, transition: 'background .15s' },
  btnPrimary: { background: colors.primary, color: '#fff' },
  btnDanger: { background: colors.danger, color: '#fff' },
  btnSec: { background: colors.hover, color: colors.text, border: `1px solid ${colors.border}` },
  card: { background: colors.card, borderRadius: 10, padding: 20, marginBottom: 14, boxShadow: '0 1px 3px rgba(0,0,0,.08)', border: `1px solid ${colors.border}`, cursor: 'pointer', transition: 'box-shadow .15s' },
  badge: { display: 'inline-block', padding: '2px 10px', borderRadius: 12, fontSize: 11, fontWeight: 700, marginRight: 8, textTransform: 'uppercase' as const },
  formGrid: { display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 },
  label: { fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 4, display: 'block' },
  input: { width: '100%', padding: '8px 10px', borderRadius: 6, border: `1px solid ${colors.border}`, fontSize: 14, boxSizing: 'border-box' as const, outline: 'none' },
  textarea: { width: '100%', padding: '8px 10px', borderRadius: 6, border: `1px solid ${colors.border}`, fontSize: 14, boxSizing: 'border-box' as const, outline: 'none', minHeight: 60, resize: 'vertical' as const },
  fieldFull: { gridColumn: '1 / -1' },
  section: { marginTop: 18, marginBottom: 10, fontWeight: 700, fontSize: 15, borderBottom: `2px solid ${colors.primary}`, paddingBottom: 4, color: colors.primary },
  detailRow: { display: 'flex', gap: 8, marginBottom: 6, fontSize: 14 },
  detailLabel: { fontWeight: 600, minWidth: 100, color: colors.textSec },
  chip: { display: 'inline-flex', alignItems: 'center', gap: 6, background: colors.accent, borderRadius: 16, padding: '4px 12px', fontSize: 13, marginRight: 6, marginBottom: 6 },
  chipRemove: { cursor: 'pointer', fontWeight: 700, color: colors.danger, fontSize: 14, lineHeight: 1, border: 'none', background: 'none', padding: 0 },
  addrDropdown: { position: 'absolute' as const, top: '100%', left: 0, right: 0, background: '#fff', borderRadius: 6, boxShadow: '0 4px 12px rgba(0,0,0,.15)', zIndex: 10 },
  addrItem: { padding: '8px 12px', cursor: 'pointer', borderBottom: `1px solid ${colors.border}`, fontSize: 13 },
  emptyState: { textAlign: 'center' as const, padding: 60, color: colors.textSec },
  error: { background: '#fce8e6', color: colors.danger, padding: '10px 14px', borderRadius: 6, marginBottom: 14, fontSize: 13 },
  overlay: { position: 'fixed' as const, inset: 0, background: 'rgba(0,0,0,.45)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  dialog: { background: '#fff', borderRadius: 12, padding: '28px 32px', maxWidth: 420, width: '90%', boxShadow: '0 8px 30px rgba(0,0,0,.2)' },
  dialogTitle: { margin: '0 0 8px', fontSize: 18, fontWeight: 700 },
  dialogBody: { fontSize: 14, color: colors.textSec, marginBottom: 22, lineHeight: 1.5 },
  dialogActions: { display: 'flex', justifyContent: 'flex-end', gap: 10 },
};

__EOF_SRC_STYLES_TS__

cat > "$ROOT/src/utils.ts" << '__EOF_SRC_UTILS_TS__'
import { useState, useEffect } from 'react';
import { aiClient, AIInferenceError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, AddressSuggestion, Address } from './types';

// ─── E.164 Phone Formatting ─────────────────────────────────────────

export function toE164(raw: string): string {
  const digits = raw.replace(/[^\d]/g, '');
  if (!digits) return '';
  if (digits.length === 10) return `+1${digits}`;
  if (digits.length === 11 && digits.startsWith('1')) return `+${digits}`;
  if (digits.startsWith('+')) return raw.replace(/[^\d+]/g, '');
  return `+${digits}`;
}

export function formatPhoneDisplay(e164: string): string {
  if (!e164) return '';
  const d = e164.replace(/[^\d]/g, '');
  if (d.length === 11 && d.startsWith('1')) {
    return `+1 (${d.slice(1, 4)}) ${d.slice(4, 7)}-${d.slice(7)}`;
  }
  return e164;
}

// ─── Primary helpers ─────────────────────────────────────────────────

export function ensureOnePrimary<T extends { isPrimary: boolean }>(arr: T[], setIdx?: number): T[] {
  if (arr.length === 0) return arr;
  const result = arr.map((item, i) => ({ ...item, isPrimary: i === (setIdx ?? 0) }));
  if (!result.some(x => x.isPrimary)) result[0].isPrimary = true;
  return result;
}

export function getPrimary<T extends { isPrimary: boolean }>(arr: T[]): T | undefined {
  return arr.find(x => x.isPrimary) || arr[0];
}

// ─── Entry name helper ───────────────────────────────────────────────

export function getEntryName(e: DirectoryEntry): string {
  return e.type === 'person' ? `${e.firstName} ${e.lastName}` : e.name;
}

// ─── Address formatting ─────────────────────────────────────────────

export function formatAddr(a: Address): string {
  return [a.street, a.city, a.state, a.zip].filter(Boolean).join(', ') || '—';
}

// ─── Debounce hook ───────────────────────────────────────────────────

export function useDebounce<T>(value: T, ms: number): T {
  const [d, setD] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setD(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return d;
}

// ─── Migration helper ────────────────────────────────────────────────

export function migrateEntry(raw: any): DirectoryEntry {
  if (raw.email !== undefined && !raw.emails) {
    raw.emails = raw.email ? [{ address: raw.email, isPrimary: true, label: 'Personal' }] : [];
    delete raw.email;
  }
  if (raw.phone !== undefined && !raw.phones) {
    raw.phones = raw.phone ? [{ number: toE164(raw.phone), isPrimary: true, label: 'Mobile' }] : [];
    delete raw.phone;
  }
  if (raw.address !== undefined && !raw.addresses) {
    const a = raw.address;
    raw.addresses = (a && a.street) ? [{ ...a, isPrimary: true, label: 'Home' }] : [];
    delete raw.address;
  }
  return raw as DirectoryEntry;
}

// ─── Address AI Suggest ──────────────────────────────────────────────

export async function suggestAddresses(partial: string): Promise<AddressSuggestion[]> {
  if (!partial.trim()) return [];
  try {
    const resp = await aiClient.prompt(
      'anthropic.claude-haiku-4-5-20251001-v1:0',
      `Suggest up to 5 valid US addresses that match or complete: "${partial}". Return ONLY a JSON array of objects with keys: street, city, state (2-letter), zip. No extra text.`,
      'You are an address lookup service. Return only valid JSON arrays.'
    );
    const parsed = JSON.parse(resp.replace(/```json?\n?/g, '').replace(/```/g, '').trim());
    if (Array.isArray(parsed)) return parsed.slice(0, 5);
  } catch (e) {
    if (e instanceof AIInferenceError) console.warn(e.message);
  }
  return [];
}

__EOF_SRC_UTILS_TS__

cat > "$ROOT/src/storage.ts" << '__EOF_SRC_STORAGE_TS__'
import {
  putSharedItem, getSharedItem, listSharedItems, deleteSharedItem,
} from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import Papa from 'papaparse';
import type { DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address } from './types';
import { TABLE } from './types';
import { migrateEntry, toE164, getPrimary } from './utils';

// ─── CRUD ────────────────────────────────────────────────────────────

export async function saveEntry(entry: DirectoryEntry) {
  await putSharedItem({ tableName: TABLE, key: entry.id, value: JSON.stringify(entry), tag: entry.type });
}

export async function loadEntry(id: string): Promise<DirectoryEntry | null> {
  const r = await getSharedItem({ tableName: TABLE, key: id });
  return r ? migrateEntry(JSON.parse(r.item.value)) : null;
}

export async function loadAll(): Promise<DirectoryEntry[]> {
  const items: DirectoryEntry[] = [];
  let token: string | undefined;
  do {
    const r = await listSharedItems({ tableName: TABLE, nextToken: token });
    for (const i of r.items) items.push(migrateEntry(JSON.parse(i.value)));
    token = r.nextToken;
  } while (token);
  return items;
}

export async function removeEntry(id: string) {
  await deleteSharedItem({ tableName: TABLE, key: id });
}

// ─── CSV Export / Import ─────────────────────────────────────────────

export const CSV_HEADERS = [
  'type', 'firstName', 'lastName', 'companyName', 'industry',
  'primaryEmail', 'primaryPhone', 'primaryStreet', 'primaryCity', 'primaryState', 'primaryZip',
  'spouseId', 'childIds', 'householdId', 'contactPersonIds', 'notes', '_json',
];

export function entryToCsvRow(e: DirectoryEntry): Record<string, string> {
  const pEmail = getPrimary(e.emails)?.address || '';
  const pPhone = getPrimary(e.phones)?.number || '';
  const pAddr = getPrimary(e.addresses);
  return {
    type: e.type,
    firstName: e.type === 'person' ? e.firstName : '',
    lastName: e.type === 'person' ? e.lastName : '',
    companyName: e.type === 'company' ? e.name : '',
    industry: e.type === 'company' ? e.industry : '',
    primaryEmail: pEmail,
    primaryPhone: pPhone,
    primaryStreet: pAddr?.street || '',
    primaryCity: pAddr?.city || '',
    primaryState: pAddr?.state || '',
    primaryZip: pAddr?.zip || '',
    spouseId: e.type === 'person' ? e.spouseId : '',
    childIds: e.type === 'person' ? e.childIds.join(';') : '',
    householdId: e.type === 'person' ? e.householdId : '',
    contactPersonIds: e.type === 'company' ? e.contactPersonIds.join(';') : '',
    notes: e.notes,
    _json: JSON.stringify(e),
  };
}

export function csvRowToEntry(row: Record<string, string>): DirectoryEntry | null {
  if (row._json) {
    try {
      const parsed = JSON.parse(row._json);
      if (parsed && parsed.id && parsed.type) return migrateEntry(parsed);
    } catch { /* fall through */ }
  }
  const type = (row.type || '').trim().toLowerCase();
  if (type !== 'person' && type !== 'company') return null;

  const id = uuidv4();
  const emails: EmailEntry[] = row.primaryEmail?.trim()
    ? [{ address: row.primaryEmail.trim(), isPrimary: true, label: type === 'person' ? 'Personal' : 'Main' }] : [];
  const phones: PhoneEntry[] = row.primaryPhone?.trim()
    ? [{ number: toE164(row.primaryPhone.trim()), isPrimary: true, label: type === 'person' ? 'Mobile' : 'Main' }] : [];
  const addresses: Address[] = row.primaryStreet?.trim()
    ? [{ street: row.primaryStreet.trim(), city: row.primaryCity?.trim() || '', state: row.primaryState?.trim() || '', zip: row.primaryZip?.trim() || '', isPrimary: true, label: 'Home' }] : [];

  if (type === 'person') {
    return {
      id, type: 'person',
      firstName: row.firstName?.trim() || '', lastName: row.lastName?.trim() || '',
      emails, phones, addresses,
      spouseId: row.spouseId?.trim() || '',
      childIds: row.childIds ? row.childIds.split(';').map(s => s.trim()).filter(Boolean) : [],
      householdId: row.householdId?.trim() || uuidv4(),
      notes: row.notes?.trim() || '',
    } as Person;
  } else {
    return {
      id, type: 'company',
      name: row.companyName?.trim() || '', industry: row.industry?.trim() || '',
      emails, phones, addresses,
      contactPersonIds: row.contactPersonIds ? row.contactPersonIds.split(';').map(s => s.trim()).filter(Boolean) : [],
      notes: row.notes?.trim() || '',
    } as Company;
  }
}

export function exportCsv(entries: DirectoryEntry[]): string {
  const rows = entries.map(entryToCsvRow);
  return Papa.unparse(rows, { columns: CSV_HEADERS });
}

export function parseCsvFile(file: File): Promise<{ entries: DirectoryEntry[]; errors: string[] }> {
  return new Promise((resolve) => {
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: (result) => {
        const entries: DirectoryEntry[] = [];
        const errors: string[] = [];
        (result.data as Record<string, string>[]).forEach((row, i) => {
          const entry = csvRowToEntry(row);
          if (entry) entries.push(entry);
          else errors.push(`Row ${i + 2}: Could not parse (invalid or missing type)`);
        });
        resolve({ entries, errors });
      },
      error: (err) => resolve({ entries: [], errors: [`CSV parse error: ${err.message}`] }),
    });
  });
}

__EOF_SRC_STORAGE_TS__

cat > "$ROOT/src/components/AddressFields.tsx" << '__EOF_SRC_COMPONENTS_ADDRESSFIELDS_TSX__'
import React, { useState, useEffect, useRef } from 'react';
import type { Address, AddressSuggestion } from '../types';
import { ADDR_LABELS } from '../types';
import { suggestAddresses, useDebounce, ensureOnePrimary } from '../utils';
import { S, colors } from '../styles';

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
      </div>
    </div>
  );
}

export function MultiAddressFields({ addresses, onChange }: { addresses: Address[]; onChange: (a: Address[]) => void }) {
  const add = () => onChange([...addresses, { street: '', city: '', state: '', zip: '', isPrimary: false, label: addresses.length === 0 ? 'Home' : 'Work' }]);
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

__EOF_SRC_COMPONENTS_ADDRESSFIELDS_TSX__

cat > "$ROOT/src/components/MultiItemField.tsx" << '__EOF_SRC_COMPONENTS_MULTIITEMFIELD_TSX__'
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

__EOF_SRC_COMPONENTS_MULTIITEMFIELD_TSX__

cat > "$ROOT/src/components/RelationshipPicker.tsx" << '__EOF_SRC_COMPONENTS_RELATIONSHIPPICKER_TSX__'
import React, { useState } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

export function RelationshipPicker({ label, entries, selectedIds, onToggle }: {
  label: string; entries: Person[]; selectedIds: string[]; onToggle: (id: string) => void;
}) {
  const [q, setQ] = useState('');
  const filtered = entries.filter(p => !selectedIds.includes(p.id) &&
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase()));
  const selected = entries.filter(p => selectedIds.includes(p.id));
  return (
    <div style={S.fieldFull}>
      <label style={S.label}>{label}</label>
      <div style={{ display: 'flex', flexWrap: 'wrap', marginBottom: 6 }}>
        {selected.map(p => (
          <span key={p.id} style={S.chip}>
            {p.firstName} {p.lastName}
            <button style={S.chipRemove} onClick={() => onToggle(p.id)}>×</button>
          </span>
        ))}
      </div>
      <input style={S.input} placeholder={`Search persons to add as ${label.toLowerCase()}...`}
        value={q} onChange={e => setQ(e.target.value)} />
      {q && filtered.length > 0 && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 150, overflowY: 'auto', marginTop: 4 }}>
          {filtered.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onToggle(p.id); setQ(''); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_RELATIONSHIPPICKER_TSX__

cat > "$ROOT/src/components/SpousePicker.tsx" << '__EOF_SRC_COMPONENTS_SPOUSEPICKER_TSX__'
import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

interface SpousePickerProps {
  allPersons: Person[];
  editId: string | null;
  selectedSpouseId: string;
  childIds: string[];
  onSelect: (id: string) => void;
  onClear: () => void;
}

export function SpousePicker({ allPersons, editId, selectedSpouseId, childIds, onSelect, onClear }: SpousePickerProps) {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (ref.current && !ref.current.contains(ev.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const spouse = allPersons.find(p => p.id === selectedSpouseId);

  // Filter: exclude self, exclude current children, exclude persons already married to someone else
  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (childIds.includes(p.id)) return false;
    if (p.spouseId && p.spouseId !== editId) return false;
    return true;
  });

  const filtered = eligible.filter(p =>
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase())
  );

  if (spouse) {
    return (
      <div style={S.fieldFull}>
        <label style={S.label}>Spouse</label>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={S.chip}>
            {spouse.firstName} {spouse.lastName}
            <button style={S.chipRemove} onClick={onClear}>×</button>
          </span>
        </div>
      </div>
    );
  }

  return (
    <div style={S.fieldFull} ref={ref}>
      <label style={S.label}>Spouse</label>
      <input
        style={S.input}
        placeholder="Search for a spouse..."
        value={q}
        onChange={e => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => setOpen(true)}
      />
      {open && q && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'relative' as const, zIndex: 5 }}>
          {filtered.length === 0 && (
            <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons</div>
          )}
          {filtered.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onSelect(p.id); setQ(''); setOpen(false); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_SPOUSEPICKER_TSX__

cat > "$ROOT/src/components/HouseholdPicker.tsx" << '__EOF_SRC_COMPONENTS_HOUSEHOLDPICKER_TSX__'
import React, { useState, useRef, useEffect } from 'react';
import type { Person } from '../types';
import { S, colors } from '../styles';

interface HouseholdPickerProps {
  allPersons: Person[];
  editId: string | null;
  spouseId: string;
  childIds: string[];
  /** Manually-added household member IDs (beyond spouse/children) */
  extraMemberIds: string[];
  onAddMember: (id: string) => void;
  onRemoveMember: (id: string) => void;
  onRemoveFromHousehold: (id: string) => void;
}

export function HouseholdPicker({
  allPersons, editId, spouseId, childIds, extraMemberIds, onAddMember, onRemoveMember,
  onRemoveFromHousehold,
}: HouseholdPickerProps) {
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (ref.current && !ref.current.contains(ev.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const autoIds = [...new Set([...(spouseId ? [spouseId] : []), ...childIds])];
  const allMemberIds = [...new Set([...autoIds, ...extraMemberIds])];

  const resolve = (id: string) => allPersons.find(p => p.id === id);

  const roleLabel = (id: string): string => {
    if (id === spouseId) return 'spouse';
    if (childIds.includes(id)) return 'child';
    return '';
  };

  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (allMemberIds.includes(p.id)) return false;
    return `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase());
  });

  return (
    <div style={S.fieldFull} ref={ref}>
      <div style={S.section}>Household Members</div>
      <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
        Members share the same primary address. Spouse and children are automatically included. Removing from household does not affect relationships.
      </span>

      {allMemberIds.length === 0 ? (
        <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>No household members yet.</div>
      ) : (
        <div style={{ display: 'flex', flexWrap: 'wrap', marginBottom: 8 }}>
          {allMemberIds.map(id => {
            const p = resolve(id);
            if (!p) return null;
            const isAuto = autoIds.includes(id);
            const role = roleLabel(id);
            return (
              <span key={id} style={{ ...S.chip, background: isAuto ? '#e8f5e9' : colors.accent }}>
                {p.firstName} {p.lastName}
                {role && <span style={{ fontSize: 10, color: colors.textSec, marginLeft: 2 }}>({role})</span>}
                {isAuto ? (
                  <button style={S.chipRemove} title={`Remove ${p.firstName} from household (keeps relationship)`}
                    onClick={() => onRemoveFromHousehold(id)}>×</button>
                ) : (
                  <button style={S.chipRemove} onClick={() => onRemoveMember(id)}>×</button>
                )}
              </span>
            );
          })}
        </div>
      )}

      <input
        style={S.input}
        placeholder="Search for a person to add to household..."
        value={q}
        onChange={e => { setQ(e.target.value); setOpen(true); }}
        onFocus={() => { if (q) setOpen(true); }}
      />
      {open && q && (
        <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4 }}>
          {eligible.length === 0 && (
            <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons</div>
          )}
          {eligible.slice(0, 8).map(p => (
            <div key={p.id} style={S.dropdownItem}
              onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
              onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
              onClick={() => { onAddMember(p.id); setQ(''); setOpen(false); }}>
              {p.firstName} {p.lastName}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_HOUSEHOLDPICKER_TSX__

cat > "$ROOT/src/components/DuplicateWarning.tsx" << '__EOF_SRC_COMPONENTS_DUPLICATEWARNING_TSX__'
import React from 'react';
import type { DirectoryEntry, DuplicateMatch } from '../types';
import { S, colors } from '../styles';
import { getPrimary, toE164 } from '../utils';

export function findDuplicates(
  entries: DirectoryEntry[],
  editId: string | null,
  name: string,
  primaryEmail: string,
  primaryPhone: string,
): DuplicateMatch[] {
  const normName = name.trim().toLowerCase();
  const normEmail = primaryEmail.trim().toLowerCase();
  const normPhone = primaryPhone ? toE164(primaryPhone).replace(/[^\d]/g, '') : '';
  if (!normName && !normEmail && !normPhone) return [];

  const matches: DuplicateMatch[] = [];
  for (const e of entries) {
    if (e.id === editId) continue;
    const reasons: string[] = [];
    const eName = e.type === 'person' ? `${e.firstName} ${e.lastName}`.toLowerCase() : e.name.toLowerCase();
    if (normName && eName && normName === eName) reasons.push('Same name');
    const ePrimEmail = getPrimary(e.emails)?.address?.trim().toLowerCase() || '';
    if (normEmail && ePrimEmail && normEmail === ePrimEmail) reasons.push('Same primary email');
    const ePrimPhone = getPrimary(e.phones)?.number ? toE164(getPrimary(e.phones)!.number).replace(/[^\d]/g, '') : '';
    if (normPhone && ePrimPhone && normPhone === ePrimPhone) reasons.push('Same primary phone');
    if (reasons.length > 0) matches.push({ entry: e, reasons });
  }
  return matches;
}

export function DuplicateWarningBanner({ duplicates, onViewEntry }: {
  duplicates: DuplicateMatch[];
  onViewEntry: (id: string) => void;
}) {
  if (duplicates.length === 0) return null;
  return (
    <div style={{ background: '#fef7e0', border: '1px solid #f9c642', borderRadius: 8, padding: '12px 16px', marginBottom: 16 }}>
      <div style={{ fontWeight: 700, fontSize: 14, color: '#7a5c00', marginBottom: 8 }}>
        ⚠️ Potential duplicate{duplicates.length > 1 ? 's' : ''} found
      </div>
      {duplicates.map(d => (
        <div key={d.entry.id} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6, fontSize: 13 }}>
          <span style={{
            ...S.badge,
            background: d.entry.type === 'person' ? '#e8f0fe' : '#fce8e6',
            color: d.entry.type === 'person' ? colors.primary : colors.danger,
          }}>
            {d.entry.type === 'person' ? '👤' : '🏢'}
          </span>
          <span style={{ fontWeight: 600 }}>
            {d.entry.type === 'person' ? `${d.entry.firstName} ${d.entry.lastName}` : d.entry.name}
          </span>
          <span style={{ color: '#7a5c00' }}>— {d.reasons.join(', ')}</span>
          <button style={{ ...S.btn, padding: '2px 10px', fontSize: 12, ...S.btnSec, marginLeft: 'auto' }}
            onClick={() => onViewEntry(d.entry.id)}>View</button>
        </div>
      ))}
      <div style={{ fontSize: 12, color: '#7a5c00', marginTop: 6 }}>
        Review the entries above before saving to avoid duplicates.
      </div>
    </div>
  );
}

__EOF_SRC_COMPONENTS_DUPLICATEWARNING_TSX__

cat > "$ROOT/src/components/Toolbar.tsx" << '__EOF_SRC_COMPONENTS_TOOLBAR_TSX__'
import React from 'react';
import type { SortField, SortDir, TypeFilter } from '../types';
import { S, colors } from '../styles';

export function Toolbar({ sortField, setSortField, sortDir, setSortDir, typeFilter, setTypeFilter,
  industryFilter, setIndustryFilter, allIndustries }: {
  sortField: SortField; setSortField: (v: SortField) => void;
  sortDir: SortDir; setSortDir: (v: SortDir) => void;
  typeFilter: TypeFilter; setTypeFilter: (v: TypeFilter) => void;
  industryFilter: string; setIndustryFilter: (v: string) => void;
  allIndustries: string[];
}) {
  return (
    <div style={{
      display: 'flex', flexWrap: 'wrap', gap: 12, alignItems: 'center',
      padding: '10px 16px', marginBottom: 16, borderRadius: 8,
      background: colors.card, border: `1px solid ${colors.border}`,
    }}>
      <span style={{ fontSize: 13, fontWeight: 700, color: colors.textSec, marginRight: 4 }}>Sort:</span>
      <select style={{ ...S.input, width: 'auto', padding: '5px 8px', fontSize: 13 }}
        value={sortField} onChange={e => setSortField(e.target.value as SortField)}>
        <option value="name">Name</option>
        <option value="type">Type</option>
        <option value="dateAdded">Date Added</option>
      </select>
      <button style={{ ...S.btn, padding: '4px 10px', fontSize: 13, ...S.btnSec }}
        onClick={() => setSortDir(sortDir === 'asc' ? 'desc' : 'asc')}
        title={`Currently: ${sortDir === 'asc' ? 'Ascending' : 'Descending'}`}>
        {sortDir === 'asc' ? '↑ A–Z' : '↓ Z–A'}
      </button>

      <div style={{ width: 1, height: 24, background: colors.border, margin: '0 4px' }} />

      <span style={{ fontSize: 13, fontWeight: 700, color: colors.textSec, marginRight: 4 }}>Filter:</span>
      {(['all', 'person', 'company'] as TypeFilter[]).map(t => (
        <button key={t} style={{
          ...S.btn, padding: '4px 12px', fontSize: 13,
          background: typeFilter === t ? colors.primary : 'transparent',
          color: typeFilter === t ? '#fff' : colors.text,
          border: `1px solid ${typeFilter === t ? colors.primary : colors.border}`,
          borderRadius: 16,
        }} onClick={() => { setTypeFilter(t); if (t !== 'company') setIndustryFilter(''); }}>
          {t === 'all' ? 'All' : t === 'person' ? '👤 Persons' : '🏢 Companies'}
        </button>
      ))}

      {allIndustries.length > 0 && (typeFilter === 'all' || typeFilter === 'company') && (
        <select style={{ ...S.input, width: 'auto', padding: '5px 8px', fontSize: 13 }}
          value={industryFilter} onChange={e => { setIndustryFilter(e.target.value); if (e.target.value) setTypeFilter('company'); }}>
          <option value="">All Industries</option>
          {allIndustries.map(ind => <option key={ind} value={ind}>{ind}</option>)}
        </select>
      )}

      {(typeFilter !== 'all' || industryFilter) && (
        <button style={{ ...S.btn, padding: '4px 10px', fontSize: 12, color: colors.danger, background: 'transparent', border: 'none', textDecoration: 'underline' }}
          onClick={() => { setTypeFilter('all'); setIndustryFilter(''); }}>
          Clear Filters
        </button>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_TOOLBAR_TSX__

cat > "$ROOT/src/App.tsx" << '__EOF_SRC_APP_TSX__'
import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';

import type {
  DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address,
  View, SortField, SortDir, TypeFilter,
} from './types';
import { EMPTY_ADDR, EMPTY_PHONE, EMPTY_EMAIL, EMAIL_LABELS_PERSON, EMAIL_LABELS_COMPANY, PHONE_LABELS_PERSON, PHONE_LABELS_COMPANY } from './types';
import { S, colors } from './styles';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, getEntryName, formatAddr } from './utils';
import { saveEntry, loadEntry, loadAll, removeEntry, exportCsv, parseCsvFile } from './storage';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { RelationshipPicker } from './components/RelationshipPicker';
import { SpousePicker } from './components/SpousePicker';
import { HouseholdPicker } from './components/HouseholdPicker';
import { findDuplicates, DuplicateWarningBanner } from './components/DuplicateWarning';
import { Toolbar } from './components/Toolbar';

import appSource from './App.tsx?raw';
import devLog from './DEVLOG.md?raw';
import typesSource from './types.ts?raw';
import stylesSource from './styles.ts?raw';
import utilsSource from './utils.ts?raw';
import storageSource from './storage.ts?raw';
import addressFieldsSource from './components/AddressFields.tsx?raw';
import multiItemFieldSource from './components/MultiItemField.tsx?raw';
import relationshipPickerSource from './components/RelationshipPicker.tsx?raw';
import spousePickerSource from './components/SpousePicker.tsx?raw';
import householdPickerSource from './components/HouseholdPicker.tsx?raw';
import duplicateWarningSource from './components/DuplicateWarning.tsx?raw';
import toolbarSource from './components/Toolbar.tsx?raw';

// ─── Main App ────────────────────────────────────────────────────────

export const App = () => {
  const [view, setView] = useState<View>('list');
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [editId, setEditId] = useState<string | null>(null);

  // Search
  const [searchQ, setSearchQ] = useState('');
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);

  // Sort & Filter
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all');
  const [industryFilter, setIndustryFilter] = useState('');

  // Person form state
  const [pFirst, setPFirst] = useState('');
  const [pLast, setPLast] = useState('');
  const [pEmails, setPEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [pPhones, setPPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [pAddrs, setPAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [pSpouseId, setPSpouseId] = useState('');
  const [pChildIds, setPChildIds] = useState<string[]>([]);
  const [pHouseholdId, setPHouseholdId] = useState('');
  const [pHouseholdExtraIds, setPHouseholdExtraIds] = useState<string[]>([]);
  const [pHouseholdExcludedIds, setPHouseholdExcludedIds] = useState<string[]>([]);
  const [pNotes, setPNotes] = useState('');

  // Company form state
  const [cName, setCName] = useState('');
  const [cIndustry, setCIndustry] = useState('');
  const [cEmails, setCEmails] = useState<EmailEntry[]>([{ ...EMPTY_EMAIL }]);
  const [cPhones, setCPhones] = useState<PhoneEntry[]>([{ ...EMPTY_PHONE }]);
  const [cAddrs, setCAddrs] = useState<Address[]>([{ ...EMPTY_ADDR }]);
  const [cContactIds, setCContactIds] = useState<string[]>([]);
  const [cNotes, setCNotes] = useState('');

  // Import state
  const [importPreview, setImportPreview] = useState<DirectoryEntry[]>([]);
  const [importFileName, setImportFileName] = useState('');
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Delete confirmation
  const [deleteTarget, setDeleteTarget] = useState<DirectoryEntry | null>(null);

  const allPersons = entries.filter((e): e is Person => e.type === 'person');

  // Duplicate detection
  const personDuplicates = useMemo(() =>
    findDuplicates(entries, editId, `${pFirst} ${pLast}`, getPrimary(pEmails)?.address || '', getPrimary(pPhones)?.number || ''),
    [entries, editId, pFirst, pLast, pEmails, pPhones]
  );
  const companyDuplicates = useMemo(() =>
    findDuplicates(entries, editId, cName, getPrimary(cEmails)?.address || '', getPrimary(cPhones)?.number || ''),
    [entries, editId, cName, cEmails, cPhones]
  );

  const viewDuplicate = (id: string) => { setSelectedId(id); setView('detail'); };

  // Load
  const reload = useCallback(async () => {
    try { setLoading(true); setEntries(await loadAll()); }
    catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { reload(); }, [reload]);

  // Search
  const sq = searchQ.toLowerCase();
  const searchResults = entries.filter(e =>
    e.type === 'person'
      ? `${e.firstName} ${e.lastName} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
      : `${e.name} ${e.industry} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
  );

  const allIndustries = useMemo(() => {
    const set = new Set<string>();
    entries.forEach(e => { if (e.type === 'company' && e.industry.trim()) set.add(e.industry.trim()); });
    return Array.from(set).sort();
  }, [entries]);

  const filteredEntries = useMemo(() => {
    let list = searchQ ? searchResults : entries;
    if (typeFilter !== 'all') list = list.filter(e => e.type === typeFilter);
    if (industryFilter) list = list.filter(e => e.type === 'company' && e.industry.trim().toLowerCase() === industryFilter.toLowerCase());
    list = [...list].sort((a, b) => {
      let cmp = 0;
      if (sortField === 'name') cmp = getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else if (sortField === 'type') cmp = a.type.localeCompare(b.type) || getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else cmp = a.id.localeCompare(b.id);
      return sortDir === 'desc' ? -cmp : cmp;
    });
    return list;
  }, [entries, searchQ, searchResults, typeFilter, industryFilter, sortField, sortDir]);

  // Close search dropdown on outside click
  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (searchRef.current && !searchRef.current.contains(ev.target as Node)) setShowSearchDropdown(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  // ── Form helpers ──

  const resetPersonForm = () => {
    setPFirst(''); setPLast('');
    setPEmails([{ ...EMPTY_EMAIL }]); setPPhones([{ ...EMPTY_PHONE }]); setPAddrs([{ ...EMPTY_ADDR }]);
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(uuidv4()); setPHouseholdExtraIds([]); setPHouseholdExcludedIds([]); setPNotes(''); setEditId(null);
  };

  const resetCompanyForm = () => {
    setCName(''); setCIndustry('');
    setCEmails([{ ...EMPTY_EMAIL }]); setCPhones([{ ...EMPTY_PHONE }]); setCAddrs([{ ...EMPTY_ADDR }]);
    setCContactIds([]); setCNotes(''); setEditId(null);
  };

  const fillPersonForm = (p: Person) => {
    setPFirst(p.firstName); setPLast(p.lastName);
    setPEmails(p.emails.length ? [...p.emails] : [{ ...EMPTY_EMAIL }]);
    setPPhones(p.phones.length ? [...p.phones] : [{ ...EMPTY_PHONE }]);
    setPAddrs(p.addresses.length ? [...p.addresses] : [{ ...EMPTY_ADDR }]);
    setPSpouseId(p.spouseId);
    // Merge children with spouse's children to ensure sync
    let mergedChildIds = [...p.childIds];
    if (p.spouseId) {
      const spouse = entries.find(e => e.id === p.spouseId);
      if (spouse && spouse.type === 'person') {
        mergedChildIds = Array.from(new Set([...p.childIds, ...spouse.childIds]));
      }
    }
    setPChildIds(mergedChildIds);
    setPHouseholdId(p.householdId);
    // Compute extra household members: same householdId but not self, spouse, or children
    const autoIds = new Set([...(p.spouseId ? [p.spouseId] : []), ...mergedChildIds]);
    const extras = allPersons
      .filter(m => m.id !== p.id && m.householdId === p.householdId && !autoIds.has(m.id))
      .map(m => m.id);
    setPHouseholdExtraIds(extras);
    // Compute excluded auto-members: spouse/children with a different householdId
    const excluded = [...autoIds].filter(id => {
      const m = allPersons.find(x => x.id === id);
      return m && m.householdId !== p.householdId;
    });
    setPHouseholdExcludedIds(excluded);
    setPNotes(p.notes); setEditId(p.id);
  };

  const fillCompanyForm = (c: Company) => {
    setCName(c.name); setCIndustry(c.industry);
    setCEmails(c.emails.length ? [...c.emails] : [{ ...EMPTY_EMAIL }]);
    setCPhones(c.phones.length ? [...c.phones] : [{ ...EMPTY_PHONE }]);
    setCAddrs(c.addresses.length ? [...c.addresses] : [{ ...EMPTY_ADDR }]);
    setCContactIds([...c.contactPersonIds]); setCNotes(c.notes); setEditId(c.id);
  };

  // ── Save person ──
  const savePerson = async () => {
    if (!pFirst.trim() || !pLast.trim()) { setError('First and last name are required.'); return; }
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
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId, notes: pNotes.trim(),
    };

    // Collect all household member IDs (spouse + children + extras), excluding those removed from household
    const householdMemberIds = [...new Set([
      ...(pSpouseId && !pHouseholdExcludedIds.includes(pSpouseId) ? [pSpouseId] : []),
      ...pChildIds.filter(id => !pHouseholdExcludedIds.includes(id)),
      ...pHouseholdExtraIds,
    ])];

    try {
      // If editing and spouse changed, clear old spouse's link
      if (editId) {
        const oldPerson = allPersons.find(p => p.id === editId);
        if (oldPerson && oldPerson.spouseId && oldPerson.spouseId !== pSpouseId) {
          const oldSpouse = await loadEntry(oldPerson.spouseId);
          if (oldSpouse && oldSpouse.type === 'person')
            await saveEntry({ ...oldSpouse, spouseId: '' });
        }
      }

      await saveEntry(person);

      // Sync spouse's childIds and householdId (only if spouse is in household)
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const spouseInHousehold = !pHouseholdExcludedIds.includes(pSpouseId);
          const newHouseholdId = spouseInHousehold ? pHouseholdId : spouse.householdId;
          const needsUpdate = spouse.spouseId !== id ||
            spouse.householdId !== newHouseholdId ||
            JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate)
            await saveEntry({ ...spouse, spouseId: id, householdId: newHouseholdId, childIds: pChildIds });
        }
      }

      // Sync householdId and primary address for all household members
      const primaryAddr = getPrimary(finalAddrs);
      for (const memberId of householdMemberIds) {
        if (memberId === pSpouseId) {
          // Spouse already handled above for childIds/spouseId; just sync address if needed
          if (primaryAddr) {
            const spouse = await loadEntry(memberId);
            if (spouse && spouse.type === 'person') {
              const mAddrs = [...spouse.addresses];
              const pIdx = mAddrs.findIndex(a => a.isPrimary);
              if (pIdx >= 0) mAddrs[pIdx] = { ...primaryAddr, label: mAddrs[pIdx].label };
              else if (mAddrs.length > 0) { mAddrs[0] = { ...primaryAddr, label: mAddrs[0].label, isPrimary: true }; }
              else mAddrs.push({ ...primaryAddr });
              await saveEntry({ ...spouse, householdId: pHouseholdId, addresses: mAddrs });
            }
          }
          continue;
        }
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const updates: Partial<Person> = { householdId: pHouseholdId };
          if (primaryAddr) {
            const mAddrs = [...member.addresses];
            const pIdx = mAddrs.findIndex(a => a.isPrimary);
            if (pIdx >= 0) mAddrs[pIdx] = { ...primaryAddr, label: mAddrs[pIdx].label };
            else if (mAddrs.length > 0) { mAddrs[0] = { ...primaryAddr, label: mAddrs[0].label, isPrimary: true }; }
            else mAddrs.push({ ...primaryAddr });
            updates.addresses = mAddrs;
          }
          await saveEntry({ ...member, ...updates });
        }
      }

      await reload(); resetPersonForm(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Save company ──
  const saveCompany = async () => {
    if (!cName.trim()) { setError('Company name is required.'); return; }
    setError('');
    const id = editId || uuidv4();
    const cleanPhones = cPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = cEmails.filter(e => e.address.trim());
    const cleanAddrs = cAddrs.filter(a => a.street.trim() || a.city.trim());
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];

    const company: Company = {
      id, type: 'company', name: cName.trim(), industry: cIndustry.trim(),
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      contactPersonIds: cContactIds, notes: cNotes.trim(),
    };
    try {
      await saveEntry(company); await reload(); resetCompanyForm(); setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Delete ──
  const requestDelete = (entry: DirectoryEntry) => setDeleteTarget(entry);
  const cancelDelete = () => setDeleteTarget(null);
  const confirmDelete = async () => {
    if (!deleteTarget) return;
    const id = deleteTarget.id;
    setDeleteTarget(null);
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person') {
        // Unlink spouse
        if (entry.spouseId) {
          const spouse = await loadEntry(entry.spouseId);
          if (spouse && spouse.type === 'person') await saveEntry({ ...spouse, spouseId: '' });
        }
        // Remove from all parents' childIds
        for (const p of allPersons) {
          if (p.id !== id && p.childIds.includes(id)) {
            await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
          }
        }
        // Remove from all companies' contactPersonIds
        for (const e of entries) {
          if (e.type === 'company' && e.contactPersonIds.includes(id)) {
            await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
          }
        }
      }
      await removeEntry(id); await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Helpers ──
  const resolveName = (id: string) => {
    const e = entries.find(x => x.id === id);
    return e ? getEntryName(e) : 'Unknown';
  };
  const getPrimaryEmail = (e: DirectoryEntry) => getPrimary(e.emails)?.address || '';
  const getPrimaryAddr = (e: DirectoryEntry) => { const a = getPrimary(e.addresses); return a ? formatAddr(a) : '—'; };

  const selectedEntry = entries.find(e => e.id === selectedId);

  // ── Downloads ──
  const handleDownloadCode = async () => {
    const files: [string, string][] = [
      ['src/types.ts', typesSource],
      ['src/styles.ts', stylesSource],
      ['src/utils.ts', utilsSource],
      ['src/storage.ts', storageSource],
      ['src/components/AddressFields.tsx', addressFieldsSource],
      ['src/components/MultiItemField.tsx', multiItemFieldSource],
      ['src/components/RelationshipPicker.tsx', relationshipPickerSource],
      ['src/components/SpousePicker.tsx', spousePickerSource],
      ['src/components/HouseholdPicker.tsx', householdPickerSource],
      ['src/components/DuplicateWarning.tsx', duplicateWarningSource],
      ['src/components/Toolbar.tsx', toolbarSource],
      ['src/App.tsx', appSource],
      ['DEVLOG.md', devLog],
    ];

    // Build a self-extracting shell script using heredocs
    const lines: string[] = [
      '#!/usr/bin/env bash',
      '# Directory App — Self-Extracting Source Code',
      '# Run: bash directory-app.sh',
      '# This will create a "directory-app/" folder with the full project structure.',
      '',
      'set -e',
      'ROOT="directory-app"',
      'mkdir -p "$ROOT/src/components"',
      'echo "Extracting files into $ROOT/ ..."',
      '',
    ];

    for (const [path, content] of files) {
      // Use a unique heredoc delimiter per file to avoid collisions
      const delim = `__EOF_${path.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}__`;
      lines.push(`cat > "$ROOT/${path}" << '${delim}'`);
      lines.push(content);
      lines.push(delim);
      lines.push('');
    }

    lines.push('echo "✅ Done! Extracted ' + files.length + ' files into $ROOT/"');
    lines.push('echo ""');
    lines.push('echo "Project structure:"');
    lines.push('if command -v tree &> /dev/null; then tree "$ROOT"; else find "$ROOT" -type f | sort; fi');

    const script = lines.join('\n');
    try { await downloadFile('directory-app.sh', new Blob([script], { type: 'text/x-shellscript' })); }
    catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  const handleDownloadMarkdown = async () => {
    try { await downloadFile('directory-app-conversation.md', new Blob([devLog], { type: 'text/markdown' })); }
    catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  // ── CSV ──
  const handleExportCsv = async () => {
    if (entries.length === 0) { setError('No entries to export.'); return; }
    try { await downloadFile('directory-export.csv', new Blob([exportCsv(entries)], { type: 'text/csv' })); }
    catch (e: any) { setError(e?.message || 'Export failed'); }
  };

  const handleFileSelect = async (file: File) => {
    setError(''); setImportFileName(file.name);
    const { entries: parsed, errors } = await parseCsvFile(file);
    if (errors.length > 0) setError(errors.slice(0, 5).join('. ') + (errors.length > 5 ? ` ...and ${errors.length - 5} more.` : ''));
    setImportPreview(parsed); setView('import');
  };

  const handleImportConfirm = async () => {
    if (importPreview.length === 0) return;
    setImporting(true); setError('');
    try {
      let saved = 0;
      for (const entry of importPreview) { await saveEntry(entry); saved++; }
      await reload(); setImportPreview([]); setImportFileName(''); setView('list');
      setError(`✅ Successfully imported ${saved} entr${saved === 1 ? 'y' : 'ies'}.`);
      setTimeout(() => setError(prev => prev.startsWith('✅') ? '' : prev), 3000);
    } catch (e) { if (e instanceof PageStorageError) setError(e.message); }
    finally { setImporting(false); }
  };

  const handleImportCancel = () => { setImportPreview([]); setImportFileName(''); setView('list'); };

  // ── Render ──
  return (
    <div style={S.app}>
      {/* Header */}
      <div style={S.header}>
        <h1 style={S.headerTitle} onClick={() => { setView('list'); setSelectedId(null); setSearchQ(''); }}>📒 Directory</h1>
        <div style={S.searchWrap} ref={searchRef}>
          <input style={S.searchInput} placeholder="Search persons & companies..."
            value={searchQ} onChange={e => { setSearchQ(e.target.value); setShowSearchDropdown(true); }}
            onFocus={() => setShowSearchDropdown(true)} />
          {showSearchDropdown && searchQ && (
            <div style={S.dropdown}>
              {searchResults.length === 0 && <div style={{ padding: 14, color: colors.textSec }}>No results</div>}
              {searchResults.slice(0, 10).map(e => (
                <div key={e.id} style={S.dropdownItem}
                  onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)}
                  onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')}
                  onClick={() => { setSearchQ(getEntryName(e)); setShowSearchDropdown(false); setSelectedId(e.id); setView('detail'); }}>
                  <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                    {e.type === 'person' ? '👤' : '🏢'}
                  </span>
                  {getEntryName(e)}
                  {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({e.industry})</span>}
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', gap: 8, marginLeft: 12 }}>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }} onClick={handleDownloadCode} title="Download source code">💾 Export Code</button>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }} onClick={handleDownloadMarkdown} title="Download conversation log">📄 Export Log</button>
        </div>
      </div>

      <div style={S.body}>
        {error && <div style={S.error}>{error}</div>}

        {/* ── LIST VIEW ── */}
        {view === 'list' && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { resetPersonForm(); setView('personForm'); }}>+ Add Person</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { resetCompanyForm(); setView('companyForm'); }}>+ Add Company</button>
              <div style={{ flex: 1 }} />
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleExportCsv}>📥 Export CSV</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => fileInputRef.current?.click()}>📤 Import CSV</button>
              <input ref={fileInputRef} type="file" accept=".csv" style={{ display: 'none' }}
                onChange={e => { const f = e.target.files?.[0]; if (f) handleFileSelect(f); e.target.value = ''; }} />
            </div>

            <Toolbar sortField={sortField} setSortField={setSortField} sortDir={sortDir} setSortDir={setSortDir}
              typeFilter={typeFilter} setTypeFilter={setTypeFilter} industryFilter={industryFilter}
              setIndustryFilter={setIndustryFilter} allIndustries={allIndustries} />

            {loading ? <div style={S.emptyState}>Loading...</div> :
              filteredEntries.length === 0 ? <div style={S.emptyState}>{searchQ ? 'No matching entries.' : 'No entries yet. Add a person or company to get started.'}</div> :
                filteredEntries.map(e => (
                  <div key={e.id} style={S.card}
                    onMouseEnter={ev => (ev.currentTarget.style.boxShadow = '0 3px 10px rgba(0,0,0,.12)')}
                    onMouseLeave={ev => (ev.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,.08)')}
                    onClick={() => { setSelectedId(e.id); setView('detail'); }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>{e.type}</span>
                        <strong>{getEntryName(e)}</strong>
                        {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: colors.textSec, marginTop: 6 }}>
                      {getPrimaryEmail(e) && <span>✉️ {getPrimaryEmail(e)}</span>}
                      {getPrimary(e.phones)?.number && <span>📞 {formatPhoneDisplay(getPrimary(e.phones)!.number)}</span>}
                      <span>📍 {getPrimaryAddr(e)}</span>
                    </div>
                  </div>
                ))
            }
          </>
        )}

        {/* ── PERSON FORM ── */}
        {view === 'personForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{editId ? 'Edit Person' : 'Add Person'}</h2>
            <DuplicateWarningBanner duplicates={personDuplicates} onViewEntry={viewDuplicate} />
            <div style={S.formGrid}>
              <div><label style={S.label}>First Name *</label><input style={S.input} value={pFirst} onChange={e => setPFirst(e.target.value)} /></div>
              <div><label style={S.label}>Last Name *</label><input style={S.input} value={pLast} onChange={e => setPLast(e.target.value)} /></div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={pEmails} onChange={setPEmails} labels={EMAIL_LABELS_PERSON} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Personal' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="email@example.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={pPhones} onChange={setPPhones} labels={PHONE_LABELS_PERSON} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Mobile' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={pAddrs} onChange={setPAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Relationships</div></div>
              <SpousePicker
                allPersons={allPersons}
                editId={editId}
                selectedSpouseId={pSpouseId}
                childIds={pChildIds}
                onSelect={sid => {
                  setPSpouseId(sid);
                  const spouse = allPersons.find(p => p.id === sid);
                  if (spouse) setPHouseholdId(spouse.householdId || pHouseholdId);
                }}
                onClear={() => setPSpouseId('')}
              />
              <RelationshipPicker label="Children" entries={allPersons.filter(p => {
                if (p.id === editId || p.id === pSpouseId) return false;
                // Already selected as a child of this person — always show so it can be removed
                if (pChildIds.includes(p.id)) return true;
                // Count how many other parents already claim this person (excluding current editor & their spouse)
                const parentCount = allPersons.filter(
                  other => other.id !== editId && other.id !== pSpouseId && other.childIds.includes(p.id)
                ).length;
                return parentCount < 2;
              })}
                selectedIds={pChildIds} onToggle={id => setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <HouseholdPicker
                allPersons={allPersons}
                editId={editId}
                spouseId={pHouseholdExcludedIds.includes(pSpouseId) ? '' : pSpouseId}
                childIds={pChildIds.filter(id => !pHouseholdExcludedIds.includes(id))}
                extraMemberIds={pHouseholdExtraIds}
                onAddMember={id => { setPHouseholdExtraIds(prev => [...prev, id]); setPHouseholdExcludedIds(prev => prev.filter(x => x !== id)); }}
                onRemoveMember={id => setPHouseholdExtraIds(prev => prev.filter(x => x !== id))}
                onRemoveFromHousehold={id => setPHouseholdExcludedIds(prev => [...prev, id])}
              />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={pNotes} onChange={e => setPNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={savePerson}>Save Person</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { resetPersonForm(); setView('list'); }}>Cancel</button>
            </div>
          </>
        )}

        {/* ── COMPANY FORM ── */}
        {view === 'companyForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{editId ? 'Edit Company' : 'Add Company'}</h2>
            <DuplicateWarningBanner duplicates={companyDuplicates} onViewEntry={viewDuplicate} />
            <div style={S.formGrid}>
              <div><label style={S.label}>Company Name *</label><input style={S.input} value={cName} onChange={e => setCName(e.target.value)} /></div>
              <div><label style={S.label}>Industry</label><input style={S.input} value={cIndustry} onChange={e => setCIndustry(e.target.value)} /></div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={cEmails} onChange={setCEmails} labels={EMAIL_LABELS_COMPANY} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Main' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="contact@company.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={cPhones} onChange={setCPhones} labels={PHONE_LABELS_COMPANY} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Main' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={cAddrs} onChange={setCAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Contact Persons</div></div>
              <RelationshipPicker label="Contact Persons" entries={allPersons}
                selectedIds={cContactIds} onToggle={id => setCContactIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={cNotes} onChange={e => setCNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={saveCompany}>Save Company</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { resetCompanyForm(); setView('list'); }}>Cancel</button>
            </div>
          </>
        )}

        {/* ── DETAIL VIEW ── */}
        {view === 'detail' && selectedEntry && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('list'); setSelectedId(null); }}>← Back</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                if (selectedEntry.type === 'person') { fillPersonForm(selectedEntry); setView('personForm'); }
                else { fillCompanyForm(selectedEntry); setView('companyForm'); }
              }}>Edit</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => requestDelete(selectedEntry)}>Delete</button>
            </div>

            <div style={{ ...S.card, cursor: 'default' }}>
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
                <span style={{ fontSize: 36, marginRight: 14 }}>{selectedEntry.type === 'person' ? '👤' : '🏢'}</span>
                <div>
                  <h2 style={{ margin: 0 }}>{getEntryName(selectedEntry)}</h2>
                  <span style={{ ...S.badge, marginTop: 4, background: selectedEntry.type === 'person' ? '#e8f0fe' : '#fce8e6', color: selectedEntry.type === 'person' ? colors.primary : colors.danger }}>
                    {selectedEntry.type}
                  </span>
                  {selectedEntry.type === 'company' && selectedEntry.industry && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{selectedEntry.industry}</span>}
                </div>
              </div>

              <div style={S.section}>Email Addresses</div>
              {selectedEntry.emails.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.emails.map((em, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{em.label}</span>
                    <span>{em.address}</span>
                    {em.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))}

              <div style={S.section}>Phone Numbers</div>
              {selectedEntry.phones.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.phones.map((ph, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{ph.label}</span>
                    <span>{formatPhoneDisplay(ph.number)}</span>
                    {ph.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))}

              <div style={S.section}>Addresses</div>
              {selectedEntry.addresses.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.addresses.map((addr, i) => (
                  <div key={i} style={{ padding: '8px 12px', marginBottom: 6, borderRadius: 6, border: `1px solid ${colors.border}`, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                      <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{addr.label}</span>
                      {addr.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                    </div>
                    <div style={{ fontSize: 14 }}>{formatAddr(addr)}</div>
                  </div>
                ))}

              {selectedEntry.type === 'person' && (
                <>
                  <div style={S.section}>Relationships</div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Spouse</span>
                    <span>{selectedEntry.spouseId ? (
                      <span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(selectedEntry.spouseId)}>{resolveName(selectedEntry.spouseId)}</span>
                    ) : '—'}</span>
                  </div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Children</span>
                    <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.childIds.length === 0 ? '—' : selectedEntry.childIds.map(cid => (
                        <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>
                      ))}
                    </span>
                  </div>
                  {(() => {
                    const housemates = allPersons.filter(p => p.householdId === selectedEntry.householdId && p.id !== selectedEntry.id);
                    return (
                      <>
                        <div style={S.section}>Household Members</div>
                        <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>Members share the same primary address.</span>
                        {housemates.length === 0
                          ? <div style={{ fontSize: 14, color: colors.textSec }}>No other household members.</div>
                          : <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                              {housemates.map(p => {
                                const isSpouse = p.id === selectedEntry.spouseId;
                                const isChild = selectedEntry.childIds.includes(p.id);
                                const role = isSpouse ? 'spouse' : isChild ? 'child' : '';
                                return (
                                  <span key={p.id} style={{ ...S.chip, cursor: 'pointer', background: (isSpouse || isChild) ? '#e8f5e9' : colors.accent }} onClick={() => setSelectedId(p.id)}>
                                    {p.firstName} {p.lastName}
                                    {role && <span style={{ fontSize: 10, color: colors.textSec, marginLeft: 2 }}>({role})</span>}
                                  </span>
                                );
                              })}
                            </div>
                        }
                      </>
                    );
                  })()}
                </>
              )}

              {selectedEntry.type === 'company' && (
                <>
                  <div style={S.section}>Contact Persons</div>
                  {selectedEntry.contactPersonIds.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                    <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.contactPersonIds.map(pid => (
                        <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>{resolveName(pid)}</span>
                      ))}
                    </div>}
                </>
              )}

              {selectedEntry.notes && (
                <>
                  <div style={S.section}>Notes</div>
                  <div style={{ fontSize: 14, whiteSpace: 'pre-wrap' }}>{selectedEntry.notes}</div>
                </>
              )}
            </div>
          </>
        )}

        {/* ── IMPORT PREVIEW ── */}
        {view === 'import' && (
          <>
            <h2 style={{ marginBottom: 8 }}>📤 Import Preview</h2>
            <p style={{ fontSize: 13, color: colors.textSec, marginBottom: 16 }}>
              File: <strong>{importFileName}</strong> — {importPreview.length} entr{importPreview.length === 1 ? 'y' : 'ies'} found.
            </p>
            {importPreview.length === 0 ? <div style={S.emptyState}>No valid entries found in the CSV file.</div> : (
              <div style={{ overflowX: 'auto', marginBottom: 16 }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                  <thead>
                    <tr style={{ background: colors.accent }}>
                      {['#', 'Type', 'Name', 'Primary Email', 'Primary Phone', 'City/State'].map(h => (
                        <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {importPreview.map((e, i) => (
                      <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                        <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                        <td style={{ padding: '8px 12px' }}>
                          <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                            {e.type === 'person' ? '👤' : '🏢'}
                          </span>
                        </td>
                        <td style={{ padding: '8px 12px', fontWeight: 600 }}>{getEntryName(e)}</td>
                        <td style={{ padding: '8px 12px' }}>{getPrimary(e.emails)?.address || '—'}</td>
                        <td style={{ padding: '8px 12px' }}>{getPrimary(e.phones)?.number ? formatPhoneDisplay(getPrimary(e.phones)!.number) : '—'}</td>
                        <td style={{ padding: '8px 12px' }}>
                          {(() => { const a = getPrimary(e.addresses); return a ? [a.city, a.state].filter(Boolean).join(', ') || '—' : '—'; })()}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            <div style={{ ...S.btnRow, marginTop: 8 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleImportConfirm} disabled={importing || importPreview.length === 0}>
                {importing ? 'Importing...' : `✅ Import ${importPreview.length} Entr${importPreview.length === 1 ? 'y' : 'ies'}`}
              </button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleImportCancel} disabled={importing}>Cancel</button>
            </div>
          </>
        )}
      </div>

      {/* ── DELETE CONFIRMATION ── */}
      {deleteTarget && (() => {
        const cascadeEffects: string[] = [];
        if (deleteTarget.type === 'person') {
          if (deleteTarget.spouseId) cascadeEffects.push(`Unlink spouse ${resolveName(deleteTarget.spouseId)}`);
          const parents = allPersons.filter(p => p.id !== deleteTarget.id && p.childIds.includes(deleteTarget.id));
          if (parents.length > 0) cascadeEffects.push(`Remove as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
          const linkedCompanies = entries.filter(e => e.type === 'company' && e.contactPersonIds.includes(deleteTarget.id));
          if (linkedCompanies.length > 0) cascadeEffects.push(`Remove as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
        }
        return (
          <div style={S.overlay} onClick={cancelDelete}>
            <div style={S.dialog} onClick={e => e.stopPropagation()}>
              <h3 style={S.dialogTitle}>🗑️ Delete {deleteTarget.type === 'person' ? 'Person' : 'Company'}</h3>
              <div style={S.dialogBody}>
                Are you sure you want to delete <strong>{getEntryName(deleteTarget)}</strong>?
                {cascadeEffects.length > 0 && (
                  <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>
                    {cascadeEffects.map((eff, i) => <li key={i}>{eff}</li>)}
                  </ul>
                )}
                This action cannot be undone.
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={cancelDelete}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmDelete}>Delete</button>
              </div>
            </div>
          </div>
        );
      })()}
    </div>
  );
};

export default App;

__EOF_SRC_APP_TSX__

cat > "$ROOT/DEVLOG.md" << '__EOF_DEVLOG_MD__'
# Development Log — Directory Application

## Overview
A directory application for managing biographical information about persons and companies, with relationship tracking, address auto-suggest, and unified search capabilities.

---

## Session 1 — Project Setup & Requirements Gathering

### Requirements Defined
The user requested a directory application with the following features:
- **Person management**: Track spouse and child relationships; same household members share the same primary address
- **Company management**: Track contact persons associated with companies
- **Address functionality**: Look-up and auto-suggest valid USA addresses
- **Search capability**: Unified search across persons and companies with auto-suggest and auto-fill as users type partial letters

### Development Environment Exploration
- Examined project structure: template directory, workspace directory, and key configuration files
- Identified available dependencies: React 18.2.0, react-router-dom, axios, lodash, framer-motion, recharts, leaflet, three.js, mammoth, pdf-lib, xlsx, papaparse, and `@amzn/quick-pages-runtime-lib`
- Explored the runtime library capabilities:
  - **Page Storage Client**: Private and shared item storage (put, get, list, delete) with table-based organization, key-value storage, optional tagging, pagination, and sorting
  - **AI Client**: Bedrock Claude integration for inference (prompt method, invoke with tools, multi-step tool-use loops)
  - **Additional exports**: QuickSuite client, user client (`getCurrentUser`), download client, dashboard utilities

### Next Steps Planned
- Register AI inference integration for address lookup functionality

---

## Session 2 — Full Application Implementation

### Application Built (Single-File App.tsx)
The complete directory application was implemented with all requested features:

#### Person Management
- Form with fields: first name, last name, email, phone, address, notes
- Spouse selection via dropdown with automatic bidirectional relationship and shared household ID
- Children picker with searchable interface and chip-based display
- Household ID system: all members (spouse, children) automatically share the same primary address
- Address synchronization logic across all household members

#### Company Management
- Form with fields: company name, industry, email, phone, address, notes
- Contact persons picker with searchable interface for multiple person associations

#### AI-Powered Address Auto-Suggest
- Integrated with Claude Haiku model (`anthropic.claude-haiku-4-5-20251001-v1:0`)
- Triggers when user types 3+ characters in street field
- 400ms debounce for API call optimization
- Dropdown with up to 5 suggestions; auto-fills all address fields on selection
- Click-outside handler to close dropdown

#### Unified Search
- Header-mounted search bar filtering both persons and companies simultaneously
- Live dropdown showing up to 10 matching results with type badges (👤 person, 🏢 company)
- Results include contextual info (industry for companies)
- Clicking a result navigates to detail view

#### Detail View
- Comprehensive info display for selected person or company
- Clickable relationship chips (spouse, children, contact persons, household members)
- Household members section for all persons sharing the same household ID
- Edit and delete functionality with back navigation

### Technical Details
- **Storage**: Shared storage, table name `directory-entries`, key-value with JSON serialization, tag-based categorization by entry type
- **UI**: Inline styles, Amazon Ember font, modern color scheme, hover effects, badge system, chip-based relationship display, 2-column grid forms
- **Hooks**: Custom `useDebounce` (400ms), useState, useEffect, useCallback, useRef
- **Integrations Registered**: AI Inference (for address auto-suggest)

---

## Session 3 — Code Refactoring to Modular Architecture

### Motivation
The single-file App.tsx had grown large and needed to be refactored for maintainability.

### Extracted Modules

| File | Contents |
|------|----------|
| `types.ts` | All interfaces, type aliases, constants, and label arrays |
| `styles.ts` | Colors object and style definitions dictionary |
| `utils.ts` | Pure utility functions: `toE164`, `formatPhoneDisplay`, `ensureOnePrimary`, `getPrimary`, `getEntryName`, `formatAddr`, `useDebounce` hook, `migrateEntry`, `suggestAddresses` |
| `storage.ts` | Storage operations: `saveEntry`, `loadEntry`, `loadAll`, `removeEntry`; CSV helpers: `exportCsv`, `parseCsvFile`, `entryToCsvRow`, `csvRowToEntry` |
| `components/AddressFields.tsx` | Address form fields with AI-powered auto-suggest |
| `components/MultiItemField.tsx` | Reusable multi-item selector with search and chips |
| `components/RelationshipPicker.tsx` | Relationship selection component |
| `components/DuplicateWarning.tsx` | Duplicate entry detection and warning display |
| `components/Toolbar.tsx` | Top toolbar/navigation component |
| `App.tsx` | Streamlined orchestrator: state management, view routing, save/delete handlers, rendering |

### Build Results
- Build succeeded with no errors
- Final bundle: **336.53 kB** (gzip: 99.17 kB), 147 modules transformed
- Build time: ~4.34s (vite build)
- Functionally identical behavior to pre-refactoring state

---

## Session 4 — Log Creation

### Action
- Created this `DEVLOG.md` to capture the full conversation history and development timeline

---

## Session 5 — Delete Confirmation Dialog

### Action
- Added a confirmation prompt before deleting a person or company

### Changes
- **Styles** (`styles.ts`): Added `overlay`, `dialog`, `dialogTitle`, `dialogBody`, and `dialogActions` styles for the modal UI
- **State Management** (`App.tsx`): Added `deleteTarget` state variable to track the entry pending deletion
- **Delete Flow Refactoring** (`App.tsx`):
  - Renamed `handleDelete` to `confirmDelete` — executes actual deletion
  - Created `requestDelete` — sets the `deleteTarget` to show the confirmation dialog
  - Created `cancelDelete` — clears `deleteTarget` to dismiss the dialog
  - Updated the Delete button in detail view to call `requestDelete` instead of directly deleting
- **Dialog Component** (`App.tsx`):
  - Displays when `deleteTarget` is not null
  - Shows entity type (Person/Company) and name
  - Warns about cascading effects: if deleting a person with a spouse, mentions unlinking the spouse by name
  - Includes "This action cannot be undone" warning
  - Provides Cancel and Delete buttons
  - Click-outside-to-close with `stopPropagation` on dialog content

---

## Session 6 — Spouse Picker UX Refinement

### Action
- Ineligible persons (those already married to someone else or listed as children) are now hidden entirely from the spouse picker dropdown, rather than being displayed greyed out with explanatory reasons

### Changes
- Removed `getIneligibleReason()` function
- Removed `ineligible` array and its greyed-out rendering
- Dropdown now shows only filtered eligible candidates (up to 8 results)
- "No matching persons" message triggers when no eligible matches exist

---

## Session 7 — Cascading Delete Cleanup & Household Member Removal

### Part 1: Enhanced Delete with Full Cascading Cleanup
When deleting a person, the `confirmDelete` function now performs a complete relationship cleanup:
- **Spouse unlinking** (existing): Clears the deleted person's ID from their spouse's `spouseId`
- **Parent→child cleanup** (new): Removes the deleted person's ID from all parents' `childIds` arrays
- **Company→contact cleanup** (new): Removes the deleted person's ID from all companies' `contactPersonIds` arrays

The delete confirmation dialog now dynamically computes and displays a bulleted list of all side effects:
- "Unlink spouse **Jane Doe**"
- "Remove as child from **John Doe**, **Jane Doe**"
- "Remove as contact from **Acme Corp**"

### Part 2: Allow Removing Spouse & Children from Household
Previously, spouse and children were "auto" household members without remove buttons. Now all members can be removed.

#### Changes to `HouseholdPicker.tsx`
- Added new callback props: `onRemoveSpouse` and `onRemoveChild(id)`
- Every household member chip now shows a **×** remove button — not just manually-added extras
- Clicking **×** on a spouse chip calls `onRemoveSpouse` (clears spouse relationship)
- Clicking **×** on a child chip calls `onRemoveChild(id)` (removes child from parent-child relationship)
- Updated helper text: *"Spouse and children are automatically included but can be removed."*

#### Changes to `App.tsx`
- Wired `onRemoveSpouse` → sets `pSpouseId` to `''`
- Wired `onRemoveChild` → filters the removed child out of `pChildIds`
- Changes take effect when the user clicks **Save Person**

---

## Current File Structure

```
webapp/src/
├── App.tsx                          # Main orchestrator component
├── types.ts                         # Interfaces, type aliases, constants
├── styles.ts                        # Colors and style definitions
├── utils.ts                         # Utility functions and custom hooks
├── storage.ts                       # Storage operations and CSV helpers
├── main.tsx                         # React entry point
├── vite-env.d.ts                    # Vite type declarations
├── DEVLOG.md                        # This development log
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── RelationshipPicker.tsx       # Relationship selection
│   ├── SpousePicker.tsx             # Spouse selection with eligibility filtering
│   ├── HouseholdPicker.tsx          # Household member management (spouse/children/extras)
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   └── Toolbar.tsx                  # Sort/filter toolbar
└── assets/
    ├── dashboard-placeholder-chart-icon.svg
    └── dashboard-placeholder-error-icon.svg
```

## Registered Integrations
- **AI Inference** (`ai-inference`): Used for address auto-suggest functionality (Claude Haiku model)

---

## Session 8 — Export Fixes

### Part 1: Log Export Fix
The **📄 Export Log** button was downloading a hardcoded 5-line stub instead of the actual `DEVLOG.md`. Fixed by importing `DEVLOG.md` via Vite's `?raw` suffix and using the imported content in `handleDownloadMarkdown`.

### Part 2: Code Export Fix
The **💾 Export Code** button was only exporting `App.tsx` — a single file out of the 12-file modular codebase. Fixed by:
- Adding `?raw` imports for all source files: `types.ts`, `styles.ts`, `utils.ts`, `storage.ts`, and all 7 component files
- Generating a self-extracting shell script (`directory-app.sh`) that recreates the full project structure
- Running `bash directory-app.sh` creates a `directory-app/` folder with `src/`, `src/components/`, and all 13 files in their correct paths
- Also includes `DEVLOG.md` in the export

---

## Session 9 — Standalone Deployment Discussion

### Question
The user asked whether the app can be deployed to their own AWS cloud infrastructure.

### Answer
The app **cannot** be directly deployed standalone because it depends on Quick Suite runtime services:
- Sandboxed iframe with strict CSP (`default-src 'none'`)
- `window.bridge` communication layer provided by the QuickSight runtime
- `@amzn/quick-pages-runtime-lib` for storage, AI inference, user identity, and file downloads

### Migration Guide Provided
A comprehensive step-by-step rewrite plan was documented for migrating to a standalone deployment:

#### Phase 1: Project Setup
- Create a new React + TypeScript project (Vite, CRA, or Next.js)
- Copy over component files, styles, and types (standard React code is reusable)

#### Phase 2: Replace Quick Suite Runtime Services
| Quick Suite Feature | Standalone Replacement |
|---|---|
| `putSharedItem` / `getSharedItem` / `listSharedItems` / `deleteSharedItem` | DynamoDB or RDS + API Gateway + Lambda |
| `getCurrentUser()` | Amazon Cognito / Auth0 / Firebase Auth |
| `aiClient.prompt()` / `aiClient.invoke()` | Amazon Bedrock Converse API (via backend proxy) |
| Action Connectors | Direct third-party API integration |
| Dashboard Placeholders | QuickSight Embedding SDK |
| `downloadFile()` | `URL.createObjectURL()` + anchor element / FileSaver.js |

#### Phase 3: Remove Sandbox Constraints
- Remove CSP restrictions (can load external resources freely)
- Use standard HTML `<form>` elements
- Use standard external links without bridge workarounds

#### Phase 4: Build & Test
- Remove all `@amzn/quick-pages-runtime-lib` imports
- Create service abstraction layers (`storageService.ts`, `authService.ts`, `aiService.ts`)
- Test CRUD, auth flows, data persistence, and AI features end-to-end

#### Phase 5: Deploy
Hosting options presented:
| Option | Frontend | Backend | Best For |
|--------|----------|---------|----------|
| AWS Amplify | Amplify Hosting | Amplify Functions / AppSync | Fastest all-in-one AWS setup |
| S3 + CloudFront | S3 static hosting | API Gateway + Lambda | Cost-effective, serverless |
| Vercel / Netlify | Managed hosting | Serverless functions | Simplicity, fast iteration |
| ECS / EC2 | Containerized or VM | Same container/VM | Full control |

Additional deployment considerations: CI/CD pipeline, custom domain with Route 53 + ACM SSL, and monitoring (CloudWatch / Sentry / Datadog).

---

## Session 10 — Context-Specific Labels & Household Relationship Preservation

### Part 1: Household Group Removal No Longer Breaks Relationships
Previously, removing a member from a household group would also remove their spouse or child relationships. This was incorrect — household membership and family relationships are independent concepts.

#### Change
- Updated `HouseholdPicker.tsx` so that removing a person from a household group **only** clears their household association
- Spouse and child relationships remain intact regardless of household membership status

### Part 2: Context-Specific Email and Phone Labels
Different entity types now have distinct label options for email and phone fields.

#### New Constants Added to `types.ts`
| Constant | Values |
|----------|--------|
| `EMAIL_LABELS_PERSON` | Home, Work, Other |
| `EMAIL_LABELS_COMPANY` | Main, Other |
| `PHONE_LABELS_PERSON` | Home, Work, Mobile, Other |
| `PHONE_LABELS_COMPANY` | Main, Fax, Other |

#### Changes to `App.tsx`
- Person form email fields use `EMAIL_LABELS_PERSON`
- Person form phone fields use `PHONE_LABELS_PERSON`
- Company form email fields use `EMAIL_LABELS_COMPANY`
- Company form phone fields use `PHONE_LABELS_COMPANY`
- Updated `emptyFactory` defaults for company fields from `'Work'` to `'Main'`
- Legacy combined label arrays preserved for backward compatibility with existing data

---

## Session 11 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 10–11 reflecting the latest conversation history

__EOF_DEVLOG_MD__

echo "✅ Done! Extracted 13 files into $ROOT/"
echo ""
echo "Project structure:"
if command -v tree &> /dev/null; then tree "$ROOT"; else find "$ROOT" -type f | sort; fi