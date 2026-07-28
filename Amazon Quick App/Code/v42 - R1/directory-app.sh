#!/usr/bin/env bash
# Directory App — Self-Extracting Source Code
# Run: bash directory-app.sh
# This will create a "directory-app/" folder with the full project structure.

set -e
ROOT="directory-app"
mkdir -p "$ROOT/src/components"
echo "Extracting files into $ROOT/ ..."

cat > "$ROOT/package.json" << '__EOF_PACKAGE_JSON__'
{
  "name": "directory-app",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "dependencies": {
    "papaparse": "^5.5.3",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "uuid": "^11.1.0"
  },
  "devDependencies": {
    "@types/papaparse": "^5.3.15",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.25",
    "@types/uuid": "^10.0.0",
    "@vitejs/plugin-react": "^4.3.4",
    "typescript": "^5.1.6",
    "vite": "^6.4.1",
    "vite-tsconfig-paths": "^4.2.0"
  },
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  }
}
__EOF_PACKAGE_JSON__

cat > "$ROOT/tsconfig.json" << '__EOF_TSCONFIG_JSON__'
{
  "compilerOptions": {
    "target": "esnext",
    "useDefineForClassFields": true,
    "lib": [
      "DOM",
      "DOM.Iterable",
      "ESNext"
    ],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": false,
    "allowSyntheticDefaultImports": true,
    "strict": false,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "strictNullChecks": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "paths": {
      "@root/*": [
        "./src/*"
      ]
    }
  },
  "include": [
    "src"
  ]
}
__EOF_TSCONFIG_JSON__

cat > "$ROOT/vite.config.ts" << '__EOF_VITE_CONFIG_TS__'
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
});

__EOF_VITE_CONFIG_TS__

cat > "$ROOT/index.html" << '__EOF_INDEX_HTML__'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Directory App</title>
</head>
<body>
<div id="root"></div>
<script type="module" src="/src/main.tsx"></script>
</body>
</html>

__EOF_INDEX_HTML__

cat > "$ROOT/README.md" << '__EOF_README_MD__'
# Directory App

A personal/church directory application built with React + TypeScript + Vite.

## Getting Started

```bash
npm install
npm run dev
```

## Building

```bash
npm run build
```

## Notes

- This export is a standalone version. The original app uses `@amzn/quick-pages-runtime-lib`
  for persistent storage (App Storage APIs). In this standalone version, you'll need to
  replace those calls with your own storage backend (e.g. localStorage, a REST API, etc.).
- Search for `putSharedItem`, `getSharedItem`, `listSharedItems`, `deleteSharedItem`
  in `src/storage.ts` to see where storage calls are made.
- The `downloadFile` import would also need to be replaced with standard browser download logic.

__EOF_README_MD__

cat > "$ROOT/src/main.tsx" << '__EOF_SRC_MAIN_TSX__'
import App from '@root/App';
import { createRoot } from 'react-dom/client';

// Wait for storage cache to hydrate from MFE before rendering
// so that any component reading localStorage on mount gets real data
declare global {
  interface Window {
    _storageReady: Promise<void>;
  }
}

window._storageReady.then(() => {
  createRoot(document.querySelector('#root')!).render(<App />);
});

__EOF_SRC_MAIN_TSX__

cat > "$ROOT/src/vite-env.d.ts" << '__EOF_SRC_VITE_ENV_D_TS__'
/// <reference types="vite/client" />

__EOF_SRC_VITE_ENV_D_TS__

cat > "$ROOT/src/types.ts" << '__EOF_SRC_TYPES_TS__'
export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country: string;
  isPrimary: boolean;
  label: string;
}

export interface PhoneEntry {
  number: string;
  countryCode: string;
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
  gender: string;
  birthday: string;
  weddingAnniversary: string;
  emails: EmailEntry[];
  phones: PhoneEntry[];
  addresses: Address[];
  spouseId: string;
  childIds: string[];
  householdId: string;
  notes: string;
}

export const GENDER_OPTIONS = ['', 'Male', 'Female'];

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

export interface Household {
  id: string;
  name: string;
  address: Address;
  memberIds: string[];
  primaryContactId: string;
}

export type DirectoryEntry = Person | Company;
export type View = 'list' | 'personForm' | 'companyForm' | 'detail' | 'import' | 'households';
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

export const EMPTY_ADDR: Address = { street: '', city: '', state: '', zip: '', country: 'United States', isPrimary: true, label: 'Home' };
export const EMPTY_PHONE: PhoneEntry = { number: '', countryCode: '+1', isPrimary: true, label: 'Mobile' };
export const EMPTY_EMAIL: EmailEntry = { address: '', isPrimary: true, label: 'Personal' };

export const ADDR_LABELS = ['Home', 'Work', 'Household', 'Other'];
export const HOUSEHOLD_TABLE = 'directory-households';
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
import type { DirectoryEntry, Person, AddressSuggestion, Address } from './types';

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
  // If it looks like a US number with country code baked in, format nicely
  if (d.length === 11 && d.startsWith('1')) {
    return `(${d.slice(1, 4)}) ${d.slice(4, 7)}-${d.slice(7)}`;
  }
  // If 10-digit US number without country code
  if (d.length === 10) {
    return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
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
  return [a.street, a.city, a.state, a.zip, a.country || ''].filter(Boolean).join(', ') || '—';
}

// ─── Age calculation ─────────────────────────────────────────────────

export function calculateAge(birthday: string): number | null {
  if (!birthday) return null;
  const birth = new Date(birthday);
  if (isNaN(birth.getTime())) return null;
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
  return age >= 0 ? age : null;
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
    raw.phones = raw.phone ? [{ number: toE164(raw.phone), countryCode: '+1', isPrimary: true, label: 'Mobile' }] : [];
    delete raw.phone;
  }
  if (raw.address !== undefined && !raw.addresses) {
    const a = raw.address;
    raw.addresses = (a && a.street) ? [{ ...a, country: a.country || 'United States', isPrimary: true, label: 'Home' }] : [];
    delete raw.address;
  }
  // Migrate phones without countryCode
  if (Array.isArray(raw.phones)) {
    raw.phones = raw.phones.map((p: any) => ({ ...p, countryCode: p.countryCode || '+1' }));
  }
  // Migrate addresses without country
  if (Array.isArray(raw.addresses)) {
    raw.addresses = raw.addresses.map((a: any) => ({ ...a, country: a.country || 'United States' }));
  }
  if (raw.type === 'person') {
    if (!raw.gender) raw.gender = '';
    if (!raw.birthday) raw.birthday = '';
    if (!raw.weddingAnniversary) raw.weddingAnniversary = '';
  }
  return raw as DirectoryEntry;
}

// ─── Ancestor/Descendant cycle detection ─────────────────────────────

/**
 * Returns the set of all ancestor IDs of a person (following childIds upward).
 * A person X is an ancestor of Y if Y appears in X.childIds, or in the childIds
 * of any ancestor of X, etc.
 */
export function getAncestorIds(personId: string, allPersons: Person[]): Set<string> {
  const ancestors = new Set<string>();
  const queue = [personId];
  while (queue.length > 0) {
    const current = queue.pop()!;
    for (const p of allPersons) {
      if (p.childIds.includes(current) && !ancestors.has(p.id)) {
        ancestors.add(p.id);
        queue.push(p.id);
      }
    }
  }
  return ancestors;
}

/**
 * Returns the set of all descendant IDs of a person (following childIds downward).
 */
export function getDescendantIds(personId: string, allPersons: Person[]): Set<string> {
  const descendants = new Set<string>();
  const person = allPersons.find(p => p.id === personId);
  if (!person) return descendants;
  const queue = [...person.childIds];
  while (queue.length > 0) {
    const current = queue.pop()!;
    if (descendants.has(current)) continue;
    descendants.add(current);
    const child = allPersons.find(p => p.id === current);
    if (child) queue.push(...child.childIds);
  }
  return descendants;
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
import type { DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address, Household } from './types';
import { TABLE, HOUSEHOLD_TABLE } from './types';
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

// ─── Household CRUD ──────────────────────────────────────────────────

export async function saveHousehold(household: Household) {
  await putSharedItem({ tableName: HOUSEHOLD_TABLE, key: household.id, value: JSON.stringify(household) });
}

export async function loadHousehold(id: string): Promise<Household | null> {
  const r = await getSharedItem({ tableName: HOUSEHOLD_TABLE, key: id });
  return r ? JSON.parse(r.item.value) : null;
}

export async function loadAllHouseholds(): Promise<Household[]> {
  const items: Household[] = [];
  let token: string | undefined;
  do {
    const r = await listSharedItems({ tableName: HOUSEHOLD_TABLE, nextToken: token });
    for (const i of r.items) items.push(JSON.parse(i.value));
    token = r.nextToken;
  } while (token);
  return items;
}

export async function removeHousehold(id: string) {
  await deleteSharedItem({ tableName: HOUSEHOLD_TABLE, key: id });
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
    ? [{ number: toE164(row.primaryPhone.trim()), countryCode: '+1', isPrimary: true, label: type === 'person' ? 'Mobile' : 'Main' }] : [];
  const addresses: Address[] = row.primaryStreet?.trim()
    ? [{ street: row.primaryStreet.trim(), city: row.primaryCity?.trim() || '', state: row.primaryState?.trim() || '', zip: row.primaryZip?.trim() || '', country: 'United States', isPrimary: true, label: 'Home' }] : [];

  if (type === 'person') {
    return {
      id, type: 'person',
      firstName: row.firstName?.trim() || '', lastName: row.lastName?.trim() || '',
      gender: '', birthday: '', weddingAnniversary: '',
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

// ─── Household CSV Export / Import ───────────────────────────────────

export const HOUSEHOLD_CSV_HEADERS = [
  'id', 'name', 'street', 'city', 'state', 'zip', 'country',
  'memberIds', 'primaryContactId', '_json',
];

export function householdToCsvRow(h: Household): Record<string, string> {
  return {
    id: h.id,
    name: h.name,
    street: h.address?.street || '',
    city: h.address?.city || '',
    state: h.address?.state || '',
    zip: h.address?.zip || '',
    country: h.address?.country || 'United States',
    memberIds: h.memberIds.join(';'),
    primaryContactId: h.primaryContactId,
    _json: JSON.stringify(h),
  };
}

export function csvRowToHousehold(row: Record<string, string>): Household | null {
  if (row._json) {
    try {
      const parsed = JSON.parse(row._json);
      if (parsed && parsed.id && parsed.name) return parsed as Household;
    } catch { /* fall through */ }
  }
  if (!row.name?.trim()) return null;
  return {
    id: row.id?.trim() || uuidv4(),
    name: row.name.trim(),
    address: {
      street: row.street?.trim() || '',
      city: row.city?.trim() || '',
      state: row.state?.trim() || '',
      zip: row.zip?.trim() || '',
      country: row.country?.trim() || 'United States',
      isPrimary: true,
      label: 'Household',
    },
    memberIds: row.memberIds ? row.memberIds.split(';').map(s => s.trim()).filter(Boolean) : [],
    primaryContactId: row.primaryContactId?.trim() || '',
  };
}

export function exportHouseholdsCsv(households: Household[]): string {
  const rows = households.map(householdToCsvRow);
  return Papa.unparse(rows, { columns: HOUSEHOLD_CSV_HEADERS });
}

export function exportFullCsv(entries: DirectoryEntry[], households: Household[]): string {
  const entryCsv = exportCsv(entries);
  if (households.length === 0) return entryCsv;
  const householdCsv = exportHouseholdsCsv(households);
  return entryCsv + '\n\n--- HOUSEHOLDS ---\n' + householdCsv;
}

export function parseCsvFile(file: File): Promise<{ entries: DirectoryEntry[]; households: Household[]; errors: string[] }> {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result as string;
      const entries: DirectoryEntry[] = [];
      const households: Household[] = [];
      const errors: string[] = [];

      // Split on household separator
      const separatorIdx = text.indexOf('--- HOUSEHOLDS ---');
      const entriesText = separatorIdx >= 0 ? text.substring(0, separatorIdx).trim() : text.trim();
      const householdsText = separatorIdx >= 0 ? text.substring(separatorIdx + '--- HOUSEHOLDS ---'.length).trim() : '';

      // Parse entries
      if (entriesText) {
        const result = Papa.parse(entriesText, { header: true, skipEmptyLines: true });
        (result.data as Record<string, string>[]).forEach((row, i) => {
          const entry = csvRowToEntry(row);
          if (entry) entries.push(entry);
          else errors.push(`Row ${i + 2}: Could not parse (invalid or missing type)`);
        });
      }

      // Parse households
      if (householdsText) {
        const result = Papa.parse(householdsText, { header: true, skipEmptyLines: true });
        (result.data as Record<string, string>[]).forEach((row, i) => {
          const household = csvRowToHousehold(row);
          if (household) households.push(household);
          else errors.push(`Household row ${i + 2}: Could not parse (missing name)`);
        });
      }

      resolve({ entries, households, errors });
    };
    reader.onerror = () => resolve({ entries: [], households: [], errors: ['Failed to read file'] });
    reader.readAsText(file);
  });
}

__EOF_SRC_STORAGE_TS__

cat > "$ROOT/src/countryCodes.ts" << '__EOF_SRC_COUNTRYCODES_TS__'
export interface CountryCodeEntry {
  flag: string;
  name: string;
  code: string;
}

const ALL_COUNTRY_CODES: CountryCodeEntry[] = [
  { flag: '🇺🇸', name: 'United States', code: '+1' },
  { flag: '🇨🇦', name: 'Canada', code: '+1' },
  { flag: '🇬🇧', name: 'United Kingdom', code: '+44' },
  { flag: '🇦🇺', name: 'Australia', code: '+61' },
  { flag: '🇩🇪', name: 'Germany', code: '+49' },
  { flag: '🇫🇷', name: 'France', code: '+33' },
  { flag: '🇮🇹', name: 'Italy', code: '+39' },
  { flag: '🇪🇸', name: 'Spain', code: '+34' },
  { flag: '🇧🇷', name: 'Brazil', code: '+55' },
  { flag: '🇲🇽', name: 'Mexico', code: '+52' },
  { flag: '🇮🇳', name: 'India', code: '+91' },
  { flag: '🇨🇳', name: 'China', code: '+86' },
  { flag: '🇯🇵', name: 'Japan', code: '+81' },
  { flag: '🇰🇷', name: 'South Korea', code: '+82' },
  { flag: '🇷🇺', name: 'Russia', code: '+7' },
  { flag: '🇿🇦', name: 'South Africa', code: '+27' },
  { flag: '🇳🇬', name: 'Nigeria', code: '+234' },
  { flag: '🇪🇬', name: 'Egypt', code: '+20' },
  { flag: '🇸🇦', name: 'Saudi Arabia', code: '+966' },
  { flag: '🇦🇪', name: 'United Arab Emirates', code: '+971' },
  { flag: '🇮🇱', name: 'Israel', code: '+972' },
  { flag: '🇹🇷', name: 'Turkey', code: '+90' },
  { flag: '🇳🇱', name: 'Netherlands', code: '+31' },
  { flag: '🇧🇪', name: 'Belgium', code: '+32' },
  { flag: '🇨🇭', name: 'Switzerland', code: '+41' },
  { flag: '🇦🇹', name: 'Austria', code: '+43' },
  { flag: '🇸🇪', name: 'Sweden', code: '+46' },
  { flag: '🇳🇴', name: 'Norway', code: '+47' },
  { flag: '🇩🇰', name: 'Denmark', code: '+45' },
  { flag: '🇫🇮', name: 'Finland', code: '+358' },
  { flag: '🇵🇱', name: 'Poland', code: '+48' },
  { flag: '🇵🇹', name: 'Portugal', code: '+351' },
  { flag: '🇮🇪', name: 'Ireland', code: '+353' },
  { flag: '🇬🇷', name: 'Greece', code: '+30' },
  { flag: '🇦🇷', name: 'Argentina', code: '+54' },
  { flag: '🇨🇴', name: 'Colombia', code: '+57' },
  { flag: '🇨🇱', name: 'Chile', code: '+56' },
  { flag: '🇵🇪', name: 'Peru', code: '+51' },
  { flag: '🇻🇪', name: 'Venezuela', code: '+58' },
  { flag: '🇵🇭', name: 'Philippines', code: '+63' },
  { flag: '🇹🇭', name: 'Thailand', code: '+66' },
  { flag: '🇻🇳', name: 'Vietnam', code: '+84' },
  { flag: '🇲🇾', name: 'Malaysia', code: '+60' },
  { flag: '🇸🇬', name: 'Singapore', code: '+65' },
  { flag: '🇮🇩', name: 'Indonesia', code: '+62' },
  { flag: '🇵🇰', name: 'Pakistan', code: '+92' },
  { flag: '🇧🇩', name: 'Bangladesh', code: '+880' },
  { flag: '🇳🇿', name: 'New Zealand', code: '+64' },
  { flag: '🇭🇰', name: 'Hong Kong', code: '+852' },
  { flag: '🇹🇼', name: 'Taiwan', code: '+886' },
];

// United States first, then the rest sorted alphabetically by name
export const COUNTRY_CODES: CountryCodeEntry[] = [
  ALL_COUNTRY_CODES[0],
  ...ALL_COUNTRY_CODES.slice(1).sort((a, b) => a.name.localeCompare(b.name)),
];

export const COUNTRIES: string[] = ['United States', ...ALL_COUNTRY_CODES.slice(1).map(c => c.name).sort()];

__EOF_SRC_COUNTRYCODES_TS__

cat > "$ROOT/src/App.tsx" << '__EOF_SRC_APP_TSX__'
import React, { useState, useEffect, useCallback, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';

import type {
  DirectoryEntry, Person, Company, EmailEntry, PhoneEntry, Address,
  View, SortField, SortDir, TypeFilter, Household,
} from './types';
import { EMPTY_ADDR, EMPTY_PHONE, EMPTY_EMAIL, EMAIL_LABELS_PERSON, EMAIL_LABELS_COMPANY, PHONE_LABELS_PERSON, PHONE_LABELS_COMPANY, GENDER_OPTIONS } from './types';
import { S, colors } from './styles';
import { toE164, formatPhoneDisplay, ensureOnePrimary, getPrimary, getEntryName, formatAddr, calculateAge, getAncestorIds, getDescendantIds } from './utils';
import { saveEntry, loadEntry, loadAll, removeEntry, exportCsv, exportFullCsv, parseCsvFile, saveHousehold, loadAllHouseholds, removeHousehold } from './storage';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { CountryCodeSelect } from './components/CountryCodeSelect';
import { RelationshipPicker } from './components/RelationshipPicker';
import { SpousePicker } from './components/SpousePicker';
import { HouseholdMembership } from './components/HouseholdPicker';
import { HouseholdView } from './components/HouseholdView';
import { findDuplicates, DuplicateWarningBanner } from './components/DuplicateWarning';
import { Toolbar } from './components/Toolbar';

import appSource from './App.tsx?raw';
import devLog from './DEVLOG.md?raw';
import typesSource from './types.ts?raw';
import stylesSource from './styles.ts?raw';
import utilsSource from './utils.ts?raw';
import storageSource from './storage.ts?raw';
import countryCodesSource from './countryCodes.ts?raw';
import mainSource from './main.tsx?raw';
import viteEnvSource from './vite-env.d.ts?raw';
import addressFieldsSource from './components/AddressFields.tsx?raw';
import multiItemFieldSource from './components/MultiItemField.tsx?raw';
import countryCodeSelectSource from './components/CountryCodeSelect.tsx?raw';
import relationshipPickerSource from './components/RelationshipPicker.tsx?raw';
import spousePickerSource from './components/SpousePicker.tsx?raw';
import householdPickerSource from './components/HouseholdPicker.tsx?raw';
import householdViewSource from './components/HouseholdView.tsx?raw';
import duplicateWarningSource from './components/DuplicateWarning.tsx?raw';
import toolbarSource from './components/Toolbar.tsx?raw';

// ─── Main App ────────────────────────────────────────────────────────

export const App = () => {
  const [view, setView] = useState<View>('list');
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
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
  const [importHouseholdsPreview, setImportHouseholdsPreview] = useState<Household[]>([]);
  const [importFileName, setImportFileName] = useState('');
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Delete confirmation
  const [deleteTarget, setDeleteTarget] = useState<DirectoryEntry | null>(null);
  const [showDeleteAll, setShowDeleteAll] = useState(false);
  const [deletingAll, setDeletingAll] = useState(false);

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
    try { setLoading(true); setEntries(await loadAll()); setHouseholds(await loadAllHouseholds()); }
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
    setPFirst(''); setPLast(''); setPGender(''); setPBirthday(''); setPAnniversary('');
    setPEmails([{ ...EMPTY_EMAIL }]); setPPhones([{ ...EMPTY_PHONE }]); setPAddrs([{ ...EMPTY_ADDR }]);
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(''); setPNotes(''); setEditId(null);
  };

  const resetCompanyForm = () => {
    setCName(''); setCIndustry('');
    setCEmails([{ ...EMPTY_EMAIL }]); setCPhones([{ ...EMPTY_PHONE }]); setCAddrs([{ ...EMPTY_ADDR }]);
    setCContactIds([]); setCNotes(''); setEditId(null);
  };

  const fillPersonForm = (p: Person) => {
    setPFirst(p.firstName); setPLast(p.lastName);
    setPGender(p.gender || ''); setPBirthday(p.birthday || ''); setPAnniversary(p.weddingAnniversary || '');
    setPEmails(p.emails.length ? [...p.emails] : [{ ...EMPTY_EMAIL }]);
    setPPhones(p.phones.length ? p.phones.map(ph => ({ ...ph, number: formatPhoneDisplay(ph.number) })) : [{ ...EMPTY_PHONE }]);
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
    setPHouseholdId(p.householdId || '');
    setPNotes(p.notes); setEditId(p.id);
  };

  const fillCompanyForm = (c: Company) => {
    setCName(c.name); setCIndustry(c.industry);
    setCEmails(c.emails.length ? [...c.emails] : [{ ...EMPTY_EMAIL }]);
    setCPhones(c.phones.length ? c.phones.map(ph => ({ ...ph, number: formatPhoneDisplay(ph.number) })) : [{ ...EMPTY_PHONE }]);
    setCAddrs(c.addresses.length ? [...c.addresses] : [{ ...EMPTY_ADDR }]);
    setCContactIds([...c.contactPersonIds]); setCNotes(c.notes); setEditId(c.id);
  };

  // ── Save person ──
  const savePerson = async () => {
    if (!pFirst.trim() || !pLast.trim()) { setError('First and last name are required.'); return; }
    if (!pGender) { setError('Gender is required.'); return; }
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
    };

    try {
      // If editing and spouse changed, clear old spouse's link and anniversary on both sides
      if (editId) {
        const oldPerson = allPersons.find(p => p.id === editId);
        if (oldPerson && oldPerson.spouseId && oldPerson.spouseId !== pSpouseId) {
          const oldSpouse = await loadEntry(oldPerson.spouseId);
          if (oldSpouse && oldSpouse.type === 'person') {
            const mergedChildren = Array.from(new Set([...oldSpouse.childIds, ...pChildIds]));
            await saveEntry({ ...oldSpouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
          person.weddingAnniversary = '';
        }

        // Handle household membership changes
        const oldHouseholdId = oldPerson?.householdId || '';
        if (oldHouseholdId && oldHouseholdId !== pHouseholdId) {
          // Leaving old household: change this person's Household address to Home
          person.addresses = person.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          // Remove from old household
          const oldHousehold = households.find(h => h.id === oldHouseholdId);
          if (oldHousehold) {
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== id);
            if (remainingIds.length <= 1) {
              // Dissolve household: change remaining member address from Household to Home
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') {
                  const addrs = member.addresses.map(a =>
                    a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
                  );
                  await saveEntry({ ...member, householdId: '', addresses: addrs });
                }
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
          // Joining new household: add to new household and sync address
          const newHousehold = households.find(h => h.id === pHouseholdId);
          if (newHousehold && !newHousehold.memberIds.includes(id)) {
            const updatedMembers = [...newHousehold.memberIds, id];
            await saveHousehold({ ...newHousehold, memberIds: updatedMembers });
            // Sync person's primary address with household address
            const householdAddr = { ...newHousehold.address, isPrimary: true, label: 'Household' };
            const pIdx = person.addresses.findIndex(a => a.isPrimary);
            if (pIdx >= 0) person.addresses[pIdx] = householdAddr;
            else if (person.addresses.length > 0) { person.addresses[0] = householdAddr; }
            else person.addresses.push(householdAddr);
          }
        }
      } else if (pHouseholdId) {
        // New person joining a household
        const newHousehold = households.find(h => h.id === pHouseholdId);
        if (newHousehold && !newHousehold.memberIds.includes(id)) {
          const updatedMembers = [...newHousehold.memberIds, id];
          await saveHousehold({ ...newHousehold, memberIds: updatedMembers });
          const householdAddr = { ...newHousehold.address, isPrimary: true, label: 'Household' };
          const pIdx = person.addresses.findIndex(a => a.isPrimary);
          if (pIdx >= 0) person.addresses[pIdx] = householdAddr;
          else if (person.addresses.length > 0) { person.addresses[0] = householdAddr; }
          else person.addresses.push(householdAddr);
        }
      }

      await saveEntry(person);

      // Sync spouse's childIds
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const needsUpdate = spouse.spouseId !== id ||
            spouse.weddingAnniversary !== pAnniversary ||
            JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate)
            await saveEntry({ ...spouse, spouseId: id, childIds: pChildIds, weddingAnniversary: pAnniversary });
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
        // Unlink spouse, clear their wedding anniversary, and transfer full children set
        if (entry.spouseId) {
          const spouse = await loadEntry(entry.spouseId);
          if (spouse && spouse.type === 'person') {
            const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => cid !== id);
            await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
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
        // Remove from household
        if (entry.householdId) {
          const household = households.find(h => h.id === entry.householdId);
          if (household) {
            const remainingIds = household.memberIds.filter(mid => mid !== id);
            if (remainingIds.length <= 1) {
              // Dissolve household
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') {
                  const addrs = member.addresses.map(a =>
                    a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
                  );
                  await saveEntry({ ...member, householdId: '', addresses: addrs });
                }
              }
              await removeHousehold(household.id);
            } else {
              let newPrimary = household.primaryContactId;
              if (newPrimary === id) newPrimary = remainingIds[0];
              await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
            }
          }
        }
      }
      await removeEntry(id); await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Delete All ──
  const handleDeleteAll = async () => {
    setShowDeleteAll(false);
    setDeletingAll(true);
    try {
      for (const entry of entries) await removeEntry(entry.id);
      for (const h of households) await removeHousehold(h.id);
      await reload();
      setSelectedId(null);
      setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
    finally { setDeletingAll(false); }
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
    // Config files as inline strings (these don't change and can't use ?raw imports)
    const packageJson = JSON.stringify({
      name: "directory-app",
      version: "0.1.0",
      private: true,
      type: "module",
      dependencies: {
        "papaparse": "^5.5.3",
        "react": "^18.2.0",
        "react-dom": "^18.2.0",
        "uuid": "^11.1.0"
      },
      devDependencies: {
        "@types/papaparse": "^5.3.15",
        "@types/react": "^18.2.0",
        "@types/react-dom": "^18.2.25",
        "@types/uuid": "^10.0.0",
        "@vitejs/plugin-react": "^4.3.4",
        "typescript": "^5.1.6",
        "vite": "^6.4.1",
        "vite-tsconfig-paths": "^4.2.0"
      },
      scripts: {
        dev: "vite",
        build: "tsc && vite build",
        preview: "vite preview"
      }
    }, null, 2);

    const tsconfigJson = JSON.stringify({
      compilerOptions: {
        target: "esnext",
        useDefineForClassFields: true,
        lib: ["DOM", "DOM.Iterable", "ESNext"],
        allowJs: false,
        skipLibCheck: true,
        esModuleInterop: false,
        allowSyntheticDefaultImports: true,
        strict: false,
        forceConsistentCasingInFileNames: true,
        module: "ESNext",
        moduleResolution: "Node",
        resolveJsonModule: true,
        isolatedModules: true,
        strictNullChecks: true,
        noEmit: true,
        jsx: "react-jsx",
        paths: { "@root/*": ["./src/*"] }
      },
      include: ["src"]
    }, null, 2);

    const viteConfig = `import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
});
`;

    const indexHtml = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Directory App</title>
</head>
<body>
<div id="root"></div>
<script type="module" src="/src/main.tsx"></script>
</body>
</html>
`;

    const readmeMd = `# Directory App

A personal/church directory application built with React + TypeScript + Vite.

## Getting Started

\`\`\`bash
npm install
npm run dev
\`\`\`

## Building

\`\`\`bash
npm run build
\`\`\`

## Notes

- This export is a standalone version. The original app uses \`@amzn/quick-pages-runtime-lib\`
  for persistent storage (App Storage APIs). In this standalone version, you'll need to
  replace those calls with your own storage backend (e.g. localStorage, a REST API, etc.).
- Search for \`putSharedItem\`, \`getSharedItem\`, \`listSharedItems\`, \`deleteSharedItem\`
  in \`src/storage.ts\` to see where storage calls are made.
- The \`downloadFile\` import would also need to be replaced with standard browser download logic.
`;

    const files: [string, string][] = [
      // Config files
      ['package.json', packageJson],
      ['tsconfig.json', tsconfigJson],
      ['vite.config.ts', viteConfig],
      ['index.html', indexHtml],
      ['README.md', readmeMd],
      // Source files
      ['src/main.tsx', mainSource],
      ['src/vite-env.d.ts', viteEnvSource],
      ['src/types.ts', typesSource],
      ['src/styles.ts', stylesSource],
      ['src/utils.ts', utilsSource],
      ['src/storage.ts', storageSource],
      ['src/countryCodes.ts', countryCodesSource],
      ['src/App.tsx', appSource],
      ['src/components/AddressFields.tsx', addressFieldsSource],
      ['src/components/MultiItemField.tsx', multiItemFieldSource],
      ['src/components/CountryCodeSelect.tsx', countryCodeSelectSource],
      ['src/components/RelationshipPicker.tsx', relationshipPickerSource],
      ['src/components/SpousePicker.tsx', spousePickerSource],
      ['src/components/HouseholdPicker.tsx', householdPickerSource],
      ['src/components/HouseholdView.tsx', householdViewSource],
      ['src/components/DuplicateWarning.tsx', duplicateWarningSource],
      ['src/components/Toolbar.tsx', toolbarSource],
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
    lines.push('echo "To get started:"');
    lines.push('echo "  cd $ROOT"');
    lines.push('echo "  npm install"');
    lines.push('echo "  npm run dev"');
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
    if (entries.length === 0 && households.length === 0) { setError('No entries to export.'); return; }
    try { await downloadFile('directory-export.csv', new Blob([exportFullCsv(entries, households)], { type: 'text/csv' })); }
    catch (e: any) { setError(e?.message || 'Export failed'); }
  };

  const handleFileSelect = async (file: File) => {
    setError(''); setImportFileName(file.name);
    const { entries: parsed, households: parsedHouseholds, errors } = await parseCsvFile(file);
    if (errors.length > 0) setError(errors.slice(0, 5).join('. ') + (errors.length > 5 ? ` ...and ${errors.length - 5} more.` : ''));
    setImportPreview(parsed); setImportHouseholdsPreview(parsedHouseholds); setView('import');
  };

  const handleImportConfirm = async () => {
    if (importPreview.length === 0 && importHouseholdsPreview.length === 0) return;
    setImporting(true); setError('');
    try {
      let saved = 0;
      for (const entry of importPreview) { await saveEntry(entry); saved++; }
      for (const household of importHouseholdsPreview) { await saveHousehold(household); saved++; }
      await reload(); setImportPreview([]); setImportHouseholdsPreview([]); setImportFileName(''); setView('list');
      setError(`✅ Successfully imported ${saved} record${saved === 1 ? '' : 's'}.`);
      setTimeout(() => setError(prev => prev.startsWith('✅') ? '' : prev), 3000);
    } catch (e) { if (e instanceof PageStorageError) setError(e.message); }
    finally { setImporting(false); }
  };

  const handleImportCancel = () => { setImportPreview([]); setImportHouseholdsPreview([]); setImportFileName(''); setView('list'); };

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
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setView('households')}>🏠 Households</button>
              <div style={{ flex: 1 }} />
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleExportCsv}>📥 Export CSV</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => fileInputRef.current?.click()}>📤 Import CSV</button>
              <input ref={fileInputRef} type="file" accept=".csv" style={{ display: 'none' }}
                onChange={e => { const f = e.target.files?.[0]; if (f) handleFileSelect(f); e.target.value = ''; }} />
              {entries.length > 0 && (
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => setShowDeleteAll(true)} disabled={deletingAll}>
                  {deletingAll ? '🗑️ Deleting...' : '🗑️ Delete All'}
                </button>
              )}
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
                      <div style={{ display: 'flex', alignItems: 'center' }}>
                        <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                          {e.type === 'person' ? '👤' : '🏢'}
                        </span>
                        <strong>{getEntryName(e)}</strong>
                        {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                      </div>
                      {e.type === 'person' && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: colors.textSec }}>
                          {e.spouseId && <span title={`Spouse: ${resolveName(e.spouseId)}`}>💍</span>}
                          {e.childIds.length > 0 && <span title={`${e.childIds.length} child${e.childIds.length > 1 ? 'ren' : ''}`}>👶 {e.childIds.length}</span>}
                          {(() => {
                            const hh = households.find(h => h.memberIds.includes(e.id));
                            return hh ? <span title={hh.name}>🏠</span> : null;
                          })()}
                        </div>
                      )}
                    </div>
                    <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: colors.textSec, marginTop: 6 }}>
                      {getPrimaryEmail(e) && <span>✉️ {getPrimaryEmail(e)}</span>}
                      {getPrimary(e.phones)?.number && <span>📞 {(getPrimary(e.phones)!.countryCode || '+1')} {formatPhoneDisplay(getPrimary(e.phones)!.number)}</span>}
                      {getPrimary(e.addresses) && <span>📍 {formatAddr(getPrimary(e.addresses)!)}</span>}
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

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Personal Information</div></div>
              <div>
                <label style={S.label}>Gender *</label>
                <select style={S.input} value={pGender} onChange={e => setPGender(e.target.value)}>
                  {GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}
                </select>
              </div>
              <div>
                <label style={S.label}>Birthday</label>
                <input style={S.input} type="date" value={pBirthday} onChange={e => setPBirthday(e.target.value)} />
              </div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={pEmails} onChange={setPEmails} labels={EMAIL_LABELS_PERSON} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Personal' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="email@example.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={pPhones} onChange={setPPhones} labels={PHONE_LABELS_PERSON} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', countryCode: '+1', isPrimary, label: 'Mobile' })}
              renderInput={(item, update) => (
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <CountryCodeSelect value={item.countryCode} onChange={code => update({ ...item, countryCode: code })} />
                  <input style={{ ...S.input, flex: 1 }} type="tel" placeholder="(555) 123-4567" value={item.number}
                    onChange={e => update({ ...item, number: e.target.value })}
                    onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
                </div>
              )} />

            <MultiAddressFields addresses={pAddrs} onChange={setPAddrs} personMode
              householdName={pHouseholdId ? households.find(h => h.id === pHouseholdId)?.name : undefined}
              onNavigateHousehold={() => setView('households')} />

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
                  if (spouse) {
                    // Merge children from both persons
                    setPChildIds(prev => Array.from(new Set([...prev, ...spouse.childIds])));
                  }
                }}
                onClear={() => { setPSpouseId(''); setPAnniversary(''); }}
              />
              <div>
                <label style={S.label}>Wedding Anniversary</label>
                <input style={S.input} type="date" value={pAnniversary} onChange={e => setPAnniversary(e.target.value)} disabled={!pSpouseId} />
              </div>
              <RelationshipPicker label="Children" entries={allPersons.filter(p => {
                if (p.id === editId || p.id === pSpouseId) return false;
                // Already selected as a child of this person — always show so it can be removed
                if (pChildIds.includes(p.id)) return true;
                // Prevent cycles: cannot add an ancestor as a child
                const currentId = editId || '__new__';
                const ancestors = getAncestorIds(currentId, allPersons);
                if (ancestors.has(p.id)) return false;
                // Cannot add someone who is a descendant's ancestor through another path
                // (i.e., if adding p as child would create a cycle because p has currentId as descendant)
                const pDescendants = getDescendantIds(p.id, allPersons);
                if (pDescendants.has(currentId)) return false;
                // Count how many other parents already claim this person (excluding current editor & their spouse)
                const parentCount = allPersons.filter(
                  other => other.id !== editId && other.id !== pSpouseId && other.childIds.includes(p.id)
                ).length;
                return parentCount < 2;
              })}
                selectedIds={pChildIds} onToggle={id => setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <HouseholdMembership
                allPersons={allPersons}
                households={households}
                editId={editId}
                selectedHouseholdId={pHouseholdId}
                onSelectHousehold={hid => setPHouseholdId(hid)}
                onClearHousehold={() => setPHouseholdId('')}
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
              emptyFactory={(isPrimary) => ({ number: '', countryCode: '+1', isPrimary, label: 'Main' })}
              renderInput={(item, update) => (
                <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                  <CountryCodeSelect value={item.countryCode} onChange={code => update({ ...item, countryCode: code })} />
                  <input style={{ ...S.input, flex: 1 }} type="tel" placeholder="(555) 123-4567" value={item.number}
                    onChange={e => update({ ...item, number: e.target.value })}
                    onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
                </div>
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
                  {selectedEntry.type === 'company' && (
                    <span style={{ ...S.badge, marginTop: 4, background: '#fce8e6', color: colors.danger }}>
                      company
                    </span>
                  )}
                  {selectedEntry.type === 'company' && selectedEntry.industry && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{selectedEntry.industry}</span>}
                </div>
              </div>

              {selectedEntry.type === 'person' && (selectedEntry.gender || selectedEntry.birthday) && (
                <>
                  <div style={S.section}>Personal Information</div>
                  {selectedEntry.gender && <div style={S.detailRow}><span style={S.detailLabel}>Gender</span><span>{selectedEntry.gender}</span></div>}
                  {selectedEntry.birthday && <div style={S.detailRow}><span style={S.detailLabel}>Birthday</span><span>{selectedEntry.birthday}{calculateAge(selectedEntry.birthday) !== null && ` (Age ${calculateAge(selectedEntry.birthday)})`}</span></div>}
                </>
              )}

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
                    <span>{ph.countryCode || '+1'} {formatPhoneDisplay(ph.number)}</span>
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
                  {selectedEntry.weddingAnniversary && (
                    <div style={S.detailRow}>
                      <span style={S.detailLabel}>Anniversary</span>
                      <span>💍 {selectedEntry.weddingAnniversary}</span>
                    </div>
                  )}
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Children</span>
                    <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.childIds.length === 0 ? '—' : selectedEntry.childIds.map(cid => (
                        <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>
                      ))}
                    </span>
                  </div>
                  {(() => {
                    const household = households.find(h => h.memberIds.includes(selectedEntry.id));
                    return (
                      <>
                        <div style={S.section}>Household</div>
                        {household ? (
                          <>
                            <div style={S.detailRow}>
                              <span style={S.detailLabel}>Household</span>
                              <span>🏠 {household.name}</span>
                            </div>
                            <div style={S.detailRow}>
                              <span style={S.detailLabel}>Members</span>
                              <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                                {household.memberIds.filter(mid => mid !== selectedEntry.id).map(mid => (
                                  <span key={mid} style={{ ...S.chip, cursor: 'pointer', background: mid === household.primaryContactId ? '#c6f0c2' : colors.accent }} onClick={() => setSelectedId(mid)}>
                                    {resolveName(mid)}
                                    {mid === household.primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 2 }}>★ Primary</span>}
                                  </span>
                                ))}
                                {household.memberIds.filter(mid => mid !== selectedEntry.id).length === 0 && '—'}
                              </span>
                            </div>
                          </>
                        ) : (
                          <div style={{ fontSize: 14, color: colors.textSec }}>Not assigned to any household.</div>
                        )}
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

        {/* ── HOUSEHOLDS VIEW ── */}
        {view === 'households' && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setView('list')}>← Back to Directory</button>
            </div>
            <h2 style={{ marginBottom: 16 }}>🏠 Households</h2>
            <HouseholdView households={households} allPersons={allPersons} onReload={reload} />
          </>
        )}

        {/* ── IMPORT PREVIEW ── */}
        {view === 'import' && (
          <>
            <h2 style={{ marginBottom: 8 }}>📤 Import Preview</h2>
            <p style={{ fontSize: 13, color: colors.textSec, marginBottom: 16 }}>
              File: <strong>{importFileName}</strong> — {importPreview.length} entr{importPreview.length === 1 ? 'y' : 'ies'}
              {importHouseholdsPreview.length > 0 && ` and ${importHouseholdsPreview.length} household${importHouseholdsPreview.length === 1 ? '' : 's'}`} found.
            </p>
            {importPreview.length === 0 && importHouseholdsPreview.length === 0 ? <div style={S.emptyState}>No valid records found in the CSV file.</div> : (
              <>
                {importPreview.length > 0 && (
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
                {importHouseholdsPreview.length > 0 && (
                  <div style={{ overflowX: 'auto', marginBottom: 16 }}>
                    <h3 style={{ fontSize: 15, marginBottom: 8 }}>🏠 Households</h3>
                    <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                      <thead>
                        <tr style={{ background: colors.accent }}>
                          {['#', 'Name', 'Address', 'Members'].map(h => (
                            <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {importHouseholdsPreview.map((h, i) => (
                          <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                            <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                            <td style={{ padding: '8px 12px', fontWeight: 600 }}>🏠 {h.name}</td>
                            <td style={{ padding: '8px 12px' }}>{h.address ? formatAddr(h.address) : '—'}</td>
                            <td style={{ padding: '8px 12px' }}>{h.memberIds.length} member{h.memberIds.length === 1 ? '' : 's'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </>
            )}
            <div style={{ ...S.btnRow, marginTop: 8 }}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleImportConfirm} disabled={importing || (importPreview.length === 0 && importHouseholdsPreview.length === 0)}>
                {importing ? 'Importing...' : `✅ Import ${importPreview.length + importHouseholdsPreview.length} Record${(importPreview.length + importHouseholdsPreview.length) === 1 ? '' : 's'}`}
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
                {' '}This action cannot be undone.
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={cancelDelete}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmDelete}>Delete</button>
              </div>
            </div>
          </div>
        );
      })()}
      {/* ── DELETE ALL CONFIRMATION ── */}
      {showDeleteAll && (
        <div style={S.overlay} onClick={() => setShowDeleteAll(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete All Entries</h3>
            <div style={S.dialogBody}>
              Are you sure you want to delete <strong>all {entries.length} entr{entries.length === 1 ? 'y' : 'ies'}</strong>
              {households.length > 0 && <> and <strong>{households.length} household{households.length === 1 ? '' : 's'}</strong></>}
              ? This action cannot be undone.
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowDeleteAll(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={handleDeleteAll}>Delete All</button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default App;

__EOF_SRC_APP_TSX__

cat > "$ROOT/src/components/AddressFields.tsx" << '__EOF_SRC_COMPONENTS_ADDRESSFIELDS_TSX__'
import React, { useState, useEffect, useRef } from 'react';
import type { Address, AddressSuggestion } from '../types';
import { ADDR_LABELS } from '../types';
import { suggestAddresses, useDebounce, ensureOnePrimary } from '../utils';
import { S, colors } from '../styles';
import { COUNTRIES } from '../countryCodes';

function SingleAddressFields({ addr, onChange, onRemove, canRemove, onSetPrimary, readOnly, hideSetPrimary, labels, householdName, onNavigateHousehold }: {
  addr: Address; onChange: (a: Address) => void; onRemove: () => void; canRemove: boolean; onSetPrimary: () => void;
  readOnly?: boolean; hideSetPrimary?: boolean; labels: string[]; householdName?: string; onNavigateHousehold?: () => void;
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
          {readOnly ? (
            <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 11 }}>{addr.label}</span>
          ) : (
            <select style={{ ...S.input, width: 'auto', padding: '4px 8px', fontSize: 12 }} value={addr.label}
              onChange={e => onChange({ ...addr, label: e.target.value })}>
              {labels.map(l => <option key={l} value={l}>{l}</option>)}
            </select>
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
            onChange={e => { setQuery(e.target.value); onChange({ ...addr, street: e.target.value }); }} />
          {!readOnly && suggestions.length > 0 && (
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
        <div><label style={S.label}>City</label><input style={S.input} value={addr.city} disabled={readOnly} onChange={e => onChange({ ...addr, city: e.target.value })} /></div>
        <div><label style={S.label}>State</label><input style={S.input} value={addr.state} maxLength={2} placeholder="e.g. CA" disabled={readOnly} onChange={e => onChange({ ...addr, state: e.target.value.toUpperCase() })} /></div>
        <div><label style={S.label}>ZIP</label><input style={S.input} value={addr.zip} disabled={readOnly} onChange={e => onChange({ ...addr, zip: e.target.value })} /></div>
        <div><label style={S.label}>Country</label>
          <select style={S.input} value={addr.country || 'United States'} disabled={readOnly} onChange={e => onChange({ ...addr, country: e.target.value })}>
            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>
    </div>
  );
}

export function MultiAddressFields({ addresses, onChange, personMode, householdName, onNavigateHousehold }: { addresses: Address[]; onChange: (a: Address[]) => void; personMode?: boolean; householdName?: string; onNavigateHousehold?: () => void }) {
  const hasHouseholdAddr = personMode && addresses.some(a => a.label === 'Household');
  const labelsForPerson = ADDR_LABELS.filter(l => l !== 'Household');

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
      {addresses.map((a, i) => {
        const isHousehold = personMode && a.label === 'Household';
        return (
          <SingleAddressFields key={i} addr={a} onChange={v => update(i, v)} onRemove={() => remove(i)}
            canRemove={addresses.length > 1 && !isHousehold}
            onSetPrimary={() => setPrimary(i)}
            readOnly={isHousehold}
            hideSetPrimary={hasHouseholdAddr}
            labels={personMode ? labelsForPerson : ADDR_LABELS}
            householdName={isHousehold ? householdName : undefined}
            onNavigateHousehold={isHousehold ? onNavigateHousehold : undefined} />
        );
      })}
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

cat > "$ROOT/src/components/CountryCodeSelect.tsx" << '__EOF_SRC_COMPONENTS_COUNTRYCODESELECT_TSX__'
import React from 'react';
import { S, colors } from '../styles';
import { COUNTRY_CODES } from '../countryCodes';

export function CountryCodeSelect({ value, onChange }: { value: string; onChange: (code: string) => void }) {
  return (
    <select
      style={{ ...S.input, width: 'auto', minWidth: 160, padding: '4px 8px', fontSize: 12, flex: '0 0 auto' }}
      value={value || '+1'}
      onChange={e => onChange(e.target.value)}
    >
      {COUNTRY_CODES.map((c, i) => (
        <option key={`${c.code}-${i}`} value={c.code}>
          {c.flag} {c.name} ({c.code})
        </option>
      ))}
    </select>
  );
}

__EOF_SRC_COMPONENTS_COUNTRYCODESELECT_TSX__

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
import { getAncestorIds, getDescendantIds } from '../utils';

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

  // Filter: exclude self, exclude current children, exclude persons already married to someone else,
  // exclude ancestors and descendants (to prevent cycles)
  const currentId = editId || '__new__';
  const ancestors = getAncestorIds(currentId, allPersons);
  const descendants = getDescendantIds(currentId, allPersons);
  const eligible = allPersons.filter(p => {
    if (p.id === editId) return false;
    if (childIds.includes(p.id)) return false;
    if (p.spouseId && p.spouseId !== editId) return false;
    if (ancestors.has(p.id)) return false;
    if (descendants.has(p.id)) return false;
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
import type { Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName } from '../utils';

interface HouseholdMembershipProps {
  allPersons: Person[];
  households: Household[];
  editId: string | null;
  selectedHouseholdId: string;
  onSelectHousehold: (householdId: string) => void;
  onClearHousehold: () => void;
}

export function HouseholdMembership({
  allPersons, households, editId, selectedHouseholdId, onSelectHousehold, onClearHousehold,
}: HouseholdMembershipProps) {
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

  const currentHousehold = households.find(h => h.id === selectedHouseholdId);

  // Filter households for search: exclude households that already have this person
  // (they can still see their current household)
  const eligible = households.filter(h => {
    if (h.id === selectedHouseholdId) return false;
    return h.name.toLowerCase().includes(q.toLowerCase());
  });

  const memberNames = (h: Household) =>
    h.memberIds.map(mid => {
      const p = allPersons.find(x => x.id === mid);
      return p ? getEntryName(p) : 'Unknown';
    });

  return (
    <div style={S.fieldFull} ref={ref}>
      <div style={S.section}>Household Membership</div>
      <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
        Assign this person to a household. Their primary address will sync with the household address.
      </span>

      {currentHousehold ? (
        <div style={{ background: colors.accent, borderRadius: 8, padding: 12, marginBottom: 10 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <strong>🏠 {currentHousehold.name}</strong>
            <button style={{ ...S.btn, ...S.btnSec, padding: '4px 10px', fontSize: 12 }} onClick={onClearHousehold}>Leave Household</button>
          </div>
          <div style={{ fontSize: 13, color: colors.textSec, marginTop: 6 }}>
            Members: {memberNames(currentHousehold).join(', ') || 'None'}
          </div>
        </div>
      ) : (
        <div style={{ fontSize: 13, color: colors.textSec, marginBottom: 8 }}>Not assigned to any household.</div>
      )}

      {!currentHousehold && (
        <>
          <input
            style={S.input}
            placeholder="Search for a household to join..."
            value={q}
            onChange={e => { setQ(e.target.value); setOpen(true); }}
            onFocus={() => { if (q) setOpen(true); }}
          />
          {open && q && (
            <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4 }}>
              {eligible.length === 0 && (
                <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching households</div>
              )}
              {eligible.slice(0, 8).map(h => (
                <div key={h.id} style={S.dropdownItem}
                  onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                  onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                  onClick={() => { onSelectHousehold(h.id); setQ(''); setOpen(false); }}>
                  🏠 {h.name}
                  <span style={{ fontSize: 12, color: colors.textSec, marginLeft: 8 }}>
                    ({h.memberIds.length} members)
                  </span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_HOUSEHOLDPICKER_TSX__

cat > "$ROOT/src/components/HouseholdView.tsx" << '__EOF_SRC_COMPONENTS_HOUSEHOLDVIEW_TSX__'
import React, { useState, useRef, useEffect } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { Person, Household, Address, AddressSuggestion } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, formatAddr, suggestAddresses, useDebounce } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold } from '../storage';
import { COUNTRIES } from '../countryCodes';

interface HouseholdViewProps {
  households: Household[];
  allPersons: Person[];
  onReload: () => Promise<void>;
}

function HouseholdAddressSection({ address, setAddress }: { address: Address; setAddress: (a: Address) => void }) {
  const [streetQuery, setStreetQuery] = useState(address.street);
  const [suggestions, setSuggestions] = useState<AddressSuggestion[]>([]);
  const debounced = useDebounce(streetQuery, 400);
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setStreetQuery(address.street); }, [address.street]);

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
    setAddress({ ...address, ...s });
    setStreetQuery(s.street);
    setSuggestions([]);
  };

  return (
    <>
      <div style={S.section}>Address *</div>
      <div style={S.formGrid}>
        <div style={{ ...S.fieldFull, position: 'relative' }} ref={wrapRef}>
          <label style={S.label}>Street</label>
          <input style={S.input} value={streetQuery} placeholder="Start typing to auto-suggest..."
            onChange={e => { setStreetQuery(e.target.value); setAddress({ ...address, street: e.target.value }); }} />
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
        <div><label style={S.label}>City</label><input style={S.input} value={address.city} onChange={e => setAddress({ ...address, city: e.target.value })} /></div>
        <div><label style={S.label}>State</label><input style={S.input} value={address.state} maxLength={2} placeholder="e.g. CA" onChange={e => setAddress({ ...address, state: e.target.value.toUpperCase() })} /></div>
        <div><label style={S.label}>ZIP</label><input style={S.input} value={address.zip} onChange={e => setAddress({ ...address, zip: e.target.value })} /></div>
        <div><label style={S.label}>Country</label>
          <select style={S.input} value={address.country || 'United States'} onChange={e => setAddress({ ...address, country: e.target.value })}>
            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
          </select>
        </div>
      </div>
    </>
  );
}

export function HouseholdView({ households, allPersons, onReload }: HouseholdViewProps) {
  const [editing, setEditing] = useState<Household | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState('');

  // Form state
  const [name, setName] = useState('');
  const [address, setAddress] = useState<Address>({ ...EMPTY_ADDR, label: 'Household' });
  const [memberIds, setMemberIds] = useState<string[]>([]);
  const [primaryContactId, setPrimaryContactId] = useState('');

  // Dialogs
  const [removeMemberTarget, setRemoveMemberTarget] = useState<{ householdId: string; memberId: string } | null>(null);
  const [deleteHouseholdTarget, setDeleteHouseholdTarget] = useState<Household | null>(null);
  const [newPrimaryForRemoval, setNewPrimaryForRemoval] = useState('');

  // Member search
  const [memberQ, setMemberQ] = useState('');
  const [memberDropdownOpen, setMemberDropdownOpen] = useState(false);
  const memberRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const h = (ev: MouseEvent) => {
      if (memberRef.current && !memberRef.current.contains(ev.target as Node)) setMemberDropdownOpen(false);
    };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const resetForm = () => {
    setName(''); setAddress({ ...EMPTY_ADDR, label: 'Household' });
    setMemberIds([]); setPrimaryContactId(''); setEditing(null); setShowForm(false); setError('');
  };

  const openCreate = () => { resetForm(); setShowForm(true); };

  const openEdit = (h: Household) => {
    setEditing(h);
    setName(h.name);
    setAddress({ ...h.address });
    setMemberIds([...h.memberIds]);
    setPrimaryContactId(h.primaryContactId);
    setShowForm(true);
    setError('');
  };

  const handleSave = async () => {
    if (!name.trim()) { setError('Household name is required.'); return; }
    if (!address.street.trim() && !address.city.trim()) { setError('Address is required.'); return; }
    if (memberIds.length < 2) { setError('A household must have at least two members.'); return; }
    if (!primaryContactId) { setError('Please select a primary contact.'); return; }
    if (!memberIds.includes(primaryContactId)) { setError('Primary contact must be a member.'); return; }

    setError('');
    const id = editing?.id || uuidv4();
    const household: Household = { id, name: name.trim(), address, memberIds, primaryContactId };

    try {
      // If editing, handle members that were removed
      if (editing) {
        const removedIds = editing.memberIds.filter(mid => !memberIds.includes(mid));
        for (const mid of removedIds) {
          const member = await loadEntry(mid);
          if (member && member.type === 'person') {
            const addrs = member.addresses.map(a =>
              a.label === 'Household' ? { ...a, label: 'Home' } : a
            );
            await saveEntry({ ...member, householdId: '', addresses: addrs });
          }
        }
      }

      // Set householdId on all members and sync address
      for (const mid of memberIds) {
        const member = await loadEntry(mid);
        if (member && member.type === 'person') {
          const addrs = [...member.addresses];
          const householdAddr = { ...address, isPrimary: true, label: 'Household' };
          const pIdx = addrs.findIndex(a => a.isPrimary);
          if (pIdx >= 0) addrs[pIdx] = householdAddr;
          else if (addrs.length > 0) { addrs[0] = householdAddr; }
          else addrs.push(householdAddr);
          await saveEntry({ ...member, householdId: id, addresses: addrs });
        }
      }

      await saveHousehold(household);
      await onReload();
      resetForm();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // Remove member flow
  const initiateRemoveMember = (householdId: string, memberId: string) => {
    setRemoveMemberTarget({ householdId, memberId });
    setNewPrimaryForRemoval('');
  };

  const confirmRemoveMember = async () => {
    if (!removeMemberTarget) return;
    const { householdId, memberId } = removeMemberTarget;
    const household = households.find(h => h.id === householdId);
    if (!household) { setRemoveMemberTarget(null); return; }

    try {
      const remainingIds = household.memberIds.filter(id => id !== memberId);
      let newPrimary = household.primaryContactId;

      // Rule A: If removing primary contact, must have newPrimaryForRemoval
      if (memberId === household.primaryContactId) {
        if (!newPrimaryForRemoval) { setError('Please select a new primary contact.'); return; }
        newPrimary = newPrimaryForRemoval;
      }

      // Rule B: If this is the last member (remaining will be 0 after removal), revert addresses
      if (remainingIds.length === 0) {
        // Change address type from Household to Home for this member
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        // Delete household since no members remain
        await removeHousehold(householdId);
      } else if (remainingIds.length === 1) {
        // After removal only 1 member left — change their address from Household to Home, remove from household
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        const lastMemberId = remainingIds[0];
        const lastMember = await loadEntry(lastMemberId);
        if (lastMember && lastMember.type === 'person') {
          const addrs = lastMember.addresses.map(a =>
            a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...lastMember, householdId: '', addresses: addrs });
        }
        await removeHousehold(householdId);
      } else {
        // Normal removal: unlink member and change their Household address to Home
        const member = await loadEntry(memberId);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
        await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
      }

      await onReload();
      setRemoveMemberTarget(null);
      setNewPrimaryForRemoval('');
      // If we're in the form, update state
      if (showForm && editing?.id === householdId) {
        if (remainingIds.length <= 1) { resetForm(); }
        else {
          setMemberIds(remainingIds);
          setPrimaryContactId(newPrimary);
          setEditing({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
        }
      }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // Delete household flow
  const confirmDeleteHousehold = async () => {
    if (!deleteHouseholdTarget) return;
    const household = deleteHouseholdTarget;

    try {
      // Remove all members according to removal rules
      for (const mid of household.memberIds) {
        const member = await loadEntry(mid);
        if (member && member.type === 'person') {
          const addrs = member.addresses.map(a =>
            a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a
          );
          await saveEntry({ ...member, householdId: '', addresses: addrs });
        }
      }
      await removeHousehold(household.id);
      await onReload();
      setDeleteHouseholdTarget(null);
      if (showForm && editing?.id === household.id) resetForm();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  const resolveName = (id: string) => {
    const p = allPersons.find(x => x.id === id);
    return p ? getEntryName(p) : 'Unknown';
  };

  const eligibleMembers = allPersons.filter(p => {
    if (memberIds.includes(p.id)) return false;
    // Person must not be in another household
    const existingHousehold = households.find(h => h.memberIds.includes(p.id) && h.id !== editing?.id);
    if (existingHousehold) return false;
    return `${p.firstName} ${p.lastName}`.toLowerCase().includes(memberQ.toLowerCase());
  });

  return (
    <>
      {error && <div style={S.error}>{error}</div>}

      {!showForm ? (
        <>
          <div style={S.btnRow}>
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={openCreate}>+ Create Household</button>
          </div>

          {households.length === 0 ? (
            <div style={S.emptyState}>No households yet. Create one to get started.</div>
          ) : (
            households.map(h => (
              <div key={h.id} style={{ ...S.card, cursor: 'default' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <strong style={{ fontSize: 16 }}>🏠 {h.name}</strong>
                    <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>
                      📍 {formatAddr(h.address)}
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} onClick={() => openEdit(h)}>Edit</button>
                    <button style={{ ...S.btn, ...S.btnDanger, padding: '6px 12px', fontSize: 13 }} onClick={() => setDeleteHouseholdTarget(h)}>Delete</button>
                  </div>
                </div>
                <div style={{ marginTop: 10, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                  {h.memberIds.map(mid => (
                    <span key={mid} style={{ ...S.chip, background: mid === h.primaryContactId ? '#c6f0c2' : colors.accent }}>
                      {resolveName(mid)}
                      {mid === h.primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 4 }}>★ Primary</span>}
                    </span>
                  ))}
                  {h.memberIds.length === 0 && <span style={{ fontSize: 13, color: colors.textSec }}>No members</span>}
                </div>
              </div>
            ))
          )}
        </>
      ) : (
        <>
          <h2 style={{ marginBottom: 16 }}>{editing ? `Edit Household: ${editing.name}` : 'Create Household'}</h2>

          <div style={S.formGrid}>
            <div style={S.fieldFull}>
              <label style={S.label}>Household Name *</label>
              <input style={S.input} value={name} onChange={e => setName(e.target.value)} placeholder="e.g. The Smith Family" />
            </div>
          </div>

          <HouseholdAddressSection address={address} setAddress={setAddress} />

          <div style={S.section}>Members</div>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            A household must have at least two members. One must be designated as primary contact.
          </span>

          {memberIds.length > 0 && (
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 12 }}>
              {memberIds.map(mid => (
                <span key={mid} style={{ ...S.chip, background: mid === primaryContactId ? '#c6f0c2' : colors.accent }}>
                  {resolveName(mid)}
                  {mid === primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 4 }}>★</span>}
                  <button style={S.chipRemove} onClick={() => {
                    const newMembers = memberIds.filter(x => x !== mid);
                    setMemberIds(newMembers);
                    if (primaryContactId === mid) setPrimaryContactId(newMembers[0] || '');
                  }}>×</button>
                </span>
              ))}
            </div>
          )}

          {memberIds.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={S.label}>Primary Contact *</label>
              <select style={S.input} value={primaryContactId} onChange={e => setPrimaryContactId(e.target.value)}>
                <option value="">— Select primary contact —</option>
                {memberIds.map(mid => (
                  <option key={mid} value={mid}>{resolveName(mid)}</option>
                ))}
              </select>
            </div>
          )}

          <div ref={memberRef} style={{ position: 'relative', marginBottom: 16 }}>
            <input
              style={S.input}
              placeholder="Search for a person to add..."
              value={memberQ}
              onChange={e => { setMemberQ(e.target.value); setMemberDropdownOpen(true); }}
              onFocus={() => { if (memberQ) setMemberDropdownOpen(true); }}
            />
            {memberDropdownOpen && memberQ && (
              <div style={{ background: '#fff', border: `1px solid ${colors.border}`, borderRadius: 6, maxHeight: 180, overflowY: 'auto', marginTop: 4, position: 'absolute', left: 0, right: 0, zIndex: 10 }}>
                {eligibleMembers.length === 0 && (
                  <div style={{ padding: 12, color: colors.textSec, fontSize: 13 }}>No matching persons available</div>
                )}
                {eligibleMembers.slice(0, 8).map(p => (
                  <div key={p.id} style={S.dropdownItem}
                    onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                    onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                    onClick={() => {
                      setMemberIds(prev => [...prev, p.id]);
                      if (!primaryContactId) setPrimaryContactId(p.id);
                      setMemberQ(''); setMemberDropdownOpen(false);
                    }}>
                    {p.firstName} {p.lastName}
                  </div>
                ))}
              </div>
            )}
          </div>

          <div style={{ ...S.btnRow, marginTop: 18 }}>
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleSave}>Save Household</button>
            <button style={{ ...S.btn, ...S.btnSec }} onClick={resetForm}>Cancel</button>
          </div>
        </>
      )}

      {/* Remove Member Confirmation Dialog */}
      {removeMemberTarget && (() => {
        const household = households.find(h => h.id === removeMemberTarget.householdId);
        if (!household) return null;
        const memberName = resolveName(removeMemberTarget.memberId);
        const isPrimary = removeMemberTarget.memberId === household.primaryContactId;
        const remainingAfter = household.memberIds.filter(id => id !== removeMemberTarget.memberId);
        const isLast = remainingAfter.length <= 1;

        return (
          <div style={S.overlay} onClick={() => setRemoveMemberTarget(null)}>
            <div style={S.dialog} onClick={e => e.stopPropagation()}>
              <h3 style={S.dialogTitle}>Remove Member</h3>
              <div style={S.dialogBody}>
                Remove <strong>{memberName}</strong> from <strong>{household.name}</strong>?
                {isLast && (
                  <div style={{ marginTop: 8, color: colors.danger }}>
                    This will leave fewer than 2 members. The household will be dissolved and all remaining members' address type will change from "Household" to "Home".
                  </div>
                )}
                {isPrimary && !isLast && (
                  <div style={{ marginTop: 8 }}>
                    <strong>{memberName}</strong> is the primary contact. Please select a new primary:
                    <select style={{ ...S.input, marginTop: 6 }} value={newPrimaryForRemoval} onChange={e => setNewPrimaryForRemoval(e.target.value)}>
                      <option value="">— Select —</option>
                      {remainingAfter.map(mid => (
                        <option key={mid} value={mid}>{resolveName(mid)}</option>
                      ))}
                    </select>
                  </div>
                )}
              </div>
              <div style={S.dialogActions}>
                <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setRemoveMemberTarget(null)}>Cancel</button>
                <button style={{ ...S.btn, ...S.btnDanger }}
                  disabled={isPrimary && !isLast && !newPrimaryForRemoval}
                  onClick={confirmRemoveMember}>Remove</button>
              </div>
            </div>
          </div>
        );
      })()}

      {/* Delete Household Confirmation Dialog */}
      {deleteHouseholdTarget && (
        <div style={S.overlay} onClick={() => setDeleteHouseholdTarget(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete Household</h3>
            <div style={S.dialogBody}>
              Are you sure you want to delete <strong>{deleteHouseholdTarget.name}</strong>?
              {deleteHouseholdTarget.memberIds.length > 0 && (
                <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>
                  <li>All {deleteHouseholdTarget.memberIds.length} member(s) will be removed from this household</li>
                  <li>Members' primary address type will change from "Household" to "Home"</li>
                </ul>
              )}
              This action cannot be undone.
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setDeleteHouseholdTarget(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={confirmDeleteHousehold}>Delete</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

__EOF_SRC_COMPONENTS_HOUSEHOLDVIEW_TSX__

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

## Session 11 — Wedding Anniversary & Spouse Delete Improvements

### Part 1: Clear Wedding Anniversary When Deleting a Person's Spouse
When a person is deleted, the surviving spouse's `weddingAnniversary` field is now cleared in addition to unlinking the `spouseId`.

#### Change to `confirmDelete` in `App.tsx`
- Updated the spouse unlinking logic: `await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '' })`

### Part 2: Move Wedding Anniversary to Relationships Section
The Wedding Anniversary field was moved from "Personal Information" to "Relationships" in both the form and detail view, since it's inherently tied to the spouse relationship.

#### Form Changes (`App.tsx`)
- Removed the Wedding Anniversary date input from the Personal Information grid
- Added it to the Relationships section, directly after the Spouse Picker
- The field is **disabled** when no spouse is selected (no anniversary without a spouse)
- Clearing the spouse via the "Clear" button also automatically clears the anniversary

#### Detail View Changes (`App.tsx`)
- Removed Wedding Anniversary from "Personal Information" display
- Now shown in the "Relationships" section below the spouse name (whenever it has a value)

---

## Session 12 — Clear Anniversary on Both Sides When Removing Spouse

### Action
When editing a person and removing or changing their spouse, the Wedding Anniversary is now cleared on **both sides** of the relationship.

#### Change to `savePerson` in `App.tsx`
- When detecting that the spouse has changed (`oldPerson.spouseId !== pSpouseId`):
  - The **old spouse's** `weddingAnniversary` is cleared: `await saveEntry({ ...oldSpouse, spouseId: '', weddingAnniversary: '' })`
  - The **current person's** `weddingAnniversary` is also cleared: `person.weddingAnniversary = ''`

This ensures anniversary data is never orphaned on either side when a marriage relationship is dissolved.

---

## Session 13 — Delete Confirmation Dialog Spacing Fix

### Action
Added a space between the two sentences in the delete confirmation prompt for improved readability.

#### Change
- Before: `"Are you sure you want to delete Jean Grey?This action cannot be undone."`
- After: `"Are you sure you want to delete Jean Grey? This action cannot be undone."`
- Used `{' '}` JSX spacing before "This action cannot be undone."

---

## Session 14 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 11–14 reflecting the latest conversation history

---

## Session 15 — Improvement Suggestions & Log Update

### Part 1: Follow-Up Improvement Suggestions
The user asked for 2–3 suggestions to enhance the app. Three suggestions were provided:

1. **Family Tree Visualization** — Display a visual tree/graph showing parent-child and spouse relationships for a selected person, helping users quickly understand complex family structures at a glance.

2. **Search/Filter by Relationship** — Allow users to filter the list view by relationship criteria (e.g., "persons without a spouse," "persons with children," "members of a specific household"), making relationship data auditing easier.

3. **Bulk Relationship Management** — Provide a way to assign multiple children to a couple at once (selecting a parent pair and checking off multiple children in a single action), streamlining data entry for large families.

### Part 2: Log Update
- Updated `DEVLOG.md` to include Session 15 reflecting the latest conversation history

---

## Session 16 — Log Update

### Action
- Updated `DEVLOG.md` to include Session 16 reflecting the latest conversation history (user requested log update for export purposes)

---

## Session 17 — Remove Automatic Household Creation for Spouse/Child Relationships

### Problem
When a spouse or child relationship was added to a person, they were automatically included in that person's household group. This forced household membership through relationships, which was not always desired.

### Solution
Made household membership fully manual — spouses and children are no longer auto-added to a person's household but can be added manually through the Household Picker.

### Changes

#### `components/HouseholdPicker.tsx`
- Removed `onRemoveFromHousehold` prop (no longer needed since nothing is auto-added)
- Removed the `autoIds` concept — all members in `extraMemberIds` are treated uniformly as manually-added
- Updated helper text from *"Spouse and children are automatically included"* to *"Add spouse, children, or others manually"*
- Simplified chip rendering — no more special "auto" vs "extra" distinction; all members have the same remove button behavior
- Members who happen to be a spouse or child still show role labels (e.g., "(spouse)", "(child)") and green highlighting for visual context

#### `App.tsx`
- **Removed `pHouseholdExcludedIds` state** — no longer needed since there are no auto-inclusions to exclude
- **SpousePicker `onSelect` handler**: Removed `setPHouseholdId(spouse.householdId || pHouseholdId)` — selecting a spouse no longer adopts their household ID
- **`resetPersonForm`**: Removed `setPHouseholdExcludedIds([])` reset
- **`fillPersonForm`**: All persons sharing the same `householdId` are now loaded uniformly into `pHouseholdExtraIds` (no more separate auto/excluded computation)
- **`savePerson`**: `householdMemberIds` now equals `pHouseholdExtraIds` only — spouse and children are only synced to the household if explicitly added
- **Spouse sync logic**: Only updates the spouse's `householdId` if the spouse was explicitly added to the household members list
- **HouseholdPicker usage in form**: Removed `onRemoveFromHousehold` prop and excluded IDs filtering

### Behavior Summary
| Before | After |
|--------|-------|
| Adding spouse → auto-joins household | Adding spouse → no household change |
| Adding child → auto-joins household | Adding child → no household change |
| Spouse/children shown as "auto" members with special remove behavior | All household members are manually added and uniformly removable |
| Selecting spouse adopted their household ID | Selecting spouse has no effect on household |

---

## Session 18 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **"Quick Add to Household" prompt when linking a spouse or child** — After selecting a spouse or adding a child, display a brief inline prompt (e.g., "Also add [Name] to this household?") with a one-click button. Preserves the manual-only principle while making the common case frictionless.

2. **Household group view/management page** — A dedicated view showing all households as grouped cards, making it easy to see which persons share a household, who's unassigned, and to bulk-assign members. Currently households are only manageable from individual person forms.

3. **Parent relationship display in detail view** — The detail view shows a person's spouse and children but not their parents. Adding a "Parents" row (computed by finding persons whose `childIds` include the current person) would make family navigation more intuitive and complete.

---

## Session 19 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 17–19 reflecting the latest conversation history

---

## Session 20 — Delete Confirmation Dialog Implementation (from context)

### Action
Added a confirmation prompt before deleting a person or company (continued refinements from Session 5).

---

## Session 21 — Context-Specific Labels & Household Relationship Preservation (from context)

### Actions
1. Do not remove spouse or child relationships when removing a member from a household group
2. Email types for companies: "Main" or "Other" only
3. Phone number types for persons: "Home", "Work", "Mobile", or "Other"
4. Phone number types for companies: "Main", "Fax", or "Other"

---

## Session 22 — UX Enhancements: Household Link, Badge Cleanup, Relationship Indicators

### Part 1: Household Name on Read-Only Address Card (Edit Person Page)
The address card for a household-managed address previously showed generic text "Managed by household." Now it displays the household name (e.g., "Managed by The Smith Family") as a clickable link that navigates to the Households view.

#### Changes to `components/AddressFields.tsx`
- Added `householdName` and `onNavigateHousehold` props to `SingleAddressFields`
- Added `householdName` and `onNavigateHousehold` props to `MultiAddressFields`
- Updated the "Managed by household" text:
  - If `householdName` is provided, displays: "Managed by **[Household Name]**" with the name as a clickable, underlined link in the primary color
  - Clicking the name calls `onNavigateHousehold` (navigates to Households view)
  - Falls back to generic "Managed by household" if no name is available

#### Changes to `App.tsx`
- Passes `householdName` (resolved from `households` state via `pHouseholdId`) and `onNavigateHousehold` (navigates to `'households'` view) to `MultiAddressFields` in the person form

### Part 2: Removed "Person" Label from Person Detail Page
The detail view previously showed a type badge ("person" or "company") below the entry name. Since the 👤 icon already indicates it's a person, the redundant "person" badge has been removed.

#### Changes to `App.tsx`
- The type badge now only renders for companies (showing "company" badge + industry)
- Person entries show only the 👤 icon and name without a label badge

### Part 3: Relationship Indicator Icons on List Cards
Each person card in the directory list now displays small relationship indicator icons on the right side for at-a-glance connectivity information.

#### Indicators Added
| Icon | Meaning | Tooltip |
|------|---------|---------|
| 💍 | Has a spouse | "Spouse: [Name]" |
| 👶 + count | Has children | "[N] child/children" |
| 🏠 | Member of a household | "[Household Name]" |

#### Changes to `App.tsx`
- Added a right-aligned container within each person card's header row
- Conditionally renders each indicator icon only when the relationship exists
- Each icon has a `title` attribute for native browser tooltip on hover
- Household indicator resolves the household name from the `households` state

### Part 4: Follow-Up Improvement Suggestions
Three suggestions were provided:

1. **Quick preview hover card on list items** — Show a small popover with key details on hover to speed up browsing without clicking into the full detail view.

2. **"Recently Viewed" section** — Track the last 3–5 entries viewed/edited and display them as compact chips above the main list for quick navigation.

3. **Alphabetical section headers and jump-to-letter sidebar** — When sorted by name, group entries under letter headers (A, B, C…) with a clickable letter index for instant scrolling.

---

## Session 23 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 20–23 reflecting the latest conversation history

---

## Session 24 — Follow-Up Suggestions & Export Code Enhancement

### Part 1: Follow-Up Improvement Suggestions
Three suggestions were provided:

1. **Add a "Parents" row in the Person detail view** — Display parent relationships by finding persons whose `childIds` include the current person, enabling bidirectional family navigation.

2. **Include households in "Delete All"** — The Delete All button removes persons and companies but leaves household records orphaned in storage. Update to also remove households and show the count in the confirmation dialog.

3. **Add an upcoming birthdays widget** — Show persons with birthdays in the next 7–14 days on the list view or a dedicated tab to make the directory proactively useful.

### Part 2: Export Code Enhancement — Fully Buildable Project
The "💾 Export Code" button previously exported only source files without project configuration, meaning the export couldn't be built or run standalone.

#### Changes to `App.tsx`
- Added new `?raw` imports for previously missing files: `countryCodes.ts`, `main.tsx`, `vite-env.d.ts`, `CountryCodeSelect.tsx`
- Rewrote `handleDownloadCode` to include:
  - **`package.json`** — Standalone dependencies (react, papaparse, uuid, vite, typescript) without proprietary runtime lib
  - **`tsconfig.json`** — TypeScript configuration
  - **`vite.config.ts`** — Simplified Vite config (react + tsconfig-paths plugins only)
  - **`index.html`** — Clean entry point without sandbox/bridge infrastructure
  - **`README.md`** — Getting started instructions, build commands, and notes about replacing Quick Suite storage calls
  - All 17 source files in correct directory structure
- Updated the shell script's output messages to include "To get started: cd directory-app && npm install && npm run dev"

#### Export Now Produces
Running `bash directory-app.sh` creates a fully structured project:
```
directory-app/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── index.html
├── README.md
├── DEVLOG.md
└── src/
    ├── main.tsx
    ├── vite-env.d.ts
    ├── types.ts
    ├── styles.ts
    ├── utils.ts
    ├── storage.ts
    ├── countryCodes.ts
    ├── App.tsx
    └── components/
        ├── AddressFields.tsx
        ├── MultiItemField.tsx
        ├── CountryCodeSelect.tsx
        ├── RelationshipPicker.tsx
        ├── SpousePicker.tsx
        ├── HouseholdPicker.tsx
        ├── HouseholdView.tsx
        ├── DuplicateWarning.tsx
        └── Toolbar.tsx
```

---

## Session 25 — Delete All Now Includes Households

### Problem
The "Delete All" button removed all persons and companies but left household records intact in storage, creating orphaned households.

### Solution
Updated the delete-all flow to also remove all households and show the household count in the confirmation dialog.

#### Changes to `App.tsx`

**`handleDeleteAll` function:**
- Added a loop to delete all households after deleting entries: `for (const h of households) await removeHousehold(h.id);`

**Delete All confirmation dialog:**
- Now conditionally shows household count: *"Are you sure you want to delete **all 5 entries** and **2 households**?"*
- Only shows the household clause when `households.length > 0`
- Singular/plural handled correctly for both entries and households

---

## Session 26 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 24–26 reflecting the latest conversation history

__EOF_DEVLOG_MD__

echo "✅ Done! Extracted 23 files into $ROOT/"
echo ""
echo "To get started:"
echo "  cd $ROOT"
echo "  npm install"
echo "  npm run dev"
echo ""
echo "Project structure:"
if command -v tree &> /dev/null; then tree "$ROOT"; else find "$ROOT" -type f | sort; fi