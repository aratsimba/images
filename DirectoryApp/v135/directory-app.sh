#!/usr/bin/env bash
# Directory App — Self-Extracting Source Code
set -e
ROOT="directory-app"
mkdir -p "$ROOT/src/components" "$ROOT/src/hooks" "$ROOT/src/views"
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

export default defineConfig({ plugins: [react(), tsconfigPaths()] });

__EOF_VITE_CONFIG_TS__

cat > "$ROOT/index.html" << '__EOF_INDEX_HTML__'
<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Directory App</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>

__EOF_INDEX_HTML__

cat > "$ROOT/README.md" << '__EOF_README_MD__'
# Directory App

A personal/church directory application built with React + TypeScript + Vite.

## Getting Started

```bash
npm install
npm run dev
```

## Notes

- This export is a standalone version. Replace `@amzn/quick-pages-runtime-lib` storage calls with your own backend.

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
  street2: string;
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

export type EntryStatus = 'active' | 'deceased' | 'archived';
export type CompanyStatus = 'active' | 'closed' | 'archived';

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
  status?: EntryStatus;
  deceasedDate?: string;
}

export const GENDER_OPTIONS = ['', 'Male', 'Female'];

export interface Company {
  id: string;
  type: 'company';
  name: string;
  industry: string;
  website: string;
  emails: EmailEntry[];
  phones: PhoneEntry[];
  addresses: Address[];
  contactPersonIds: string[];
  notes: string;
  companyStatus?: CompanyStatus;
  closedDate?: string;
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
export type StatusFilter = 'active' | 'deceased' | 'closed' | 'all';

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

export const EMPTY_ADDR: Address = { street: '', street2: '', city: '', state: '', zip: '', country: 'United States', isPrimary: true, label: 'Home' };
export const EMPTY_PHONE: PhoneEntry = { number: '', countryCode: '+1', isPrimary: true, label: 'Mobile' };
export const EMPTY_EMAIL: EmailEntry = { address: '', isPrimary: true, label: 'Personal' };

export const ADDR_LABELS = ['Home', 'Work', 'Household', 'Other'];
export const ADDR_LABELS_COMPANY = ['Main', 'Custom'];
export const HOUSEHOLD_TABLE = 'directory-households';
export const PHONE_LABELS_PERSON = ['Home', 'Work', 'Mobile', 'Other'];
export const PHONE_LABELS_COMPANY = ['Main', 'Fax', 'Other'];
export const EMAIL_LABELS_PERSON = ['Personal', 'Work', 'Other'];
export const EMAIL_LABELS_COMPANY = ['Main', 'Other'];
// Legacy combined arrays for backward compatibility
export const PHONE_LABELS = ['Home', 'Work', 'Mobile', 'Main', 'Fax', 'Other'];
export const EMAIL_LABELS = ['Personal', 'Work', 'Main', 'Other'];

export const TABLE = 'directory-entries';
export const IMAGES_TABLE = 'directory-images';

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
  return [a.street, a.street2, a.city, a.state, a.zip, a.country || ''].filter(Boolean).join(', ') || '—';
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
  // Migrate addresses without country or street2
  if (Array.isArray(raw.addresses)) {
    raw.addresses = raw.addresses.map((a: any) => ({ ...a, country: a.country || 'United States', street2: a.street2 || '' }));
  }
  if (raw.type === 'person') {
    if (!raw.gender) raw.gender = '';
    if (!raw.birthday) raw.birthday = '';
    if (!raw.weddingAnniversary) raw.weddingAnniversary = '';
    if (!raw.status) raw.status = 'active';
    if (!raw.deceasedDate) raw.deceasedDate = '';
  }
  if (raw.type === 'company') {
    if (!raw.website) raw.website = '';
    if (!raw.companyStatus) raw.companyStatus = 'active';
    if (raw.companyStatus === 'acquired') raw.companyStatus = 'closed';
    if (!raw.closedDate) raw.closedDate = '';
    // Migrate old status/deceasedDate fields to new companyStatus/closedDate
    if (raw.status && !raw.companyStatus) {
      raw.companyStatus = raw.status === 'deceased' ? 'closed' : raw.status;
      delete raw.status;
    }
    if (raw.deceasedDate && !raw.closedDate) {
      raw.closedDate = raw.deceasedDate;
      delete raw.deceasedDate;
    }
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

// ─── Email & Phone validation ────────────────────────────────────────

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const PHONE_CHARS_REGEX = /^[0-9\s\-().+]+$/;

export function isValidEmail(address: string): boolean {
  const trimmed = address.trim();
  if (!trimmed) return true; // empty is valid (will be filtered out)
  return EMAIL_REGEX.test(trimmed);
}

export function isValidPhone(number: string): boolean {
  const trimmed = number.trim();
  if (!trimmed) return true; // empty is valid (will be filtered out)
  if (!PHONE_CHARS_REGEX.test(trimmed)) return false;
  const digitCount = (trimmed.match(/\d/g) || []).length;
  return digitCount >= 7;
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
import { TABLE, HOUSEHOLD_TABLE, IMAGES_TABLE } from './types';
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

// ─── Image CRUD ──────────────────────────────────────────────────────

export async function saveImage(entityId: string, dataUrl: string) {
  await putSharedItem({ tableName: IMAGES_TABLE, key: entityId, value: dataUrl });
}

export async function loadImage(entityId: string): Promise<string | null> {
  const r = await getSharedItem({ tableName: IMAGES_TABLE, key: entityId });
  return r ? r.item.value : null;
}

export async function loadAllImages(): Promise<Record<string, string>> {
  const images: Record<string, string> = {};
  let token: string | undefined;
  do {
    const r = await listSharedItems({ tableName: IMAGES_TABLE, nextToken: token });
    for (const i of r.items) images[i.key] = i.value;
    token = r.nextToken;
  } while (token);
  return images;
}

export async function removeImage(entityId: string) {
  await deleteSharedItem({ tableName: IMAGES_TABLE, key: entityId });
}

// ─── CSV Export / Import ─────────────────────────────────────────────

export const CSV_HEADERS = [
  'type', 'firstName', 'lastName', 'companyName', 'industry',
  'primaryEmail', 'primaryPhone', 'primaryStreet', 'primaryStreet2', 'primaryCity', 'primaryState', 'primaryZip',
  'spouseId', 'childIds', 'householdId', 'contactPersonIds', 'notes', 'imageId', '_json',
];

export function entryToCsvRow(e: DirectoryEntry, images: Record<string, string>): Record<string, string> {
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
    primaryStreet2: pAddr?.street2 || '',
    primaryCity: pAddr?.city || '',
    primaryState: pAddr?.state || '',
    primaryZip: pAddr?.zip || '',
    spouseId: e.type === 'person' ? e.spouseId : '',
    childIds: e.type === 'person' ? e.childIds.join(';') : '',
    householdId: e.type === 'person' ? e.householdId : '',
    contactPersonIds: e.type === 'company' ? e.contactPersonIds.join(';') : '',
    notes: e.notes,
    imageId: images[e.id] ? e.id : '',
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
    ? [{ street: row.primaryStreet.trim(), street2: row.primaryStreet2?.trim() || '', city: row.primaryCity?.trim() || '', state: row.primaryState?.trim() || '', zip: row.primaryZip?.trim() || '', country: 'United States', isPrimary: true, label: 'Home' }] : [];

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
      website: '',
      emails, phones, addresses,
      contactPersonIds: row.contactPersonIds ? row.contactPersonIds.split(';').map(s => s.trim()).filter(Boolean) : [],
      notes: row.notes?.trim() || '',
    } as Company;
  }
}

export function exportCsv(entries: DirectoryEntry[], images: Record<string, string>): string {
  const rows = entries.map(e => entryToCsvRow(e, images));
  return Papa.unparse(rows, { columns: CSV_HEADERS });
}

// ─── Household CSV Export / Import ───────────────────────────────────

export const HOUSEHOLD_CSV_HEADERS = [
  'id', 'name', 'street', 'street2', 'city', 'state', 'zip', 'country',
  'memberIds', 'primaryContactId', 'imageId', '_json',
];

export function householdToCsvRow(h: Household, images: Record<string, string>): Record<string, string> {
  return {
    id: h.id,
    name: h.name,
    street: h.address?.street || '',
    street2: h.address?.street2 || '',
    city: h.address?.city || '',
    state: h.address?.state || '',
    zip: h.address?.zip || '',
    country: h.address?.country || 'United States',
    memberIds: h.memberIds.join(';'),
    primaryContactId: h.primaryContactId,
    imageId: images[h.id] ? h.id : '',
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
      street2: row.street2?.trim() || '',
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

export function exportHouseholdsCsv(households: Household[], images: Record<string, string>): string {
  const rows = households.map(h => householdToCsvRow(h, images));
  return Papa.unparse(rows, { columns: HOUSEHOLD_CSV_HEADERS });
}

export function exportFullCsv(entries: DirectoryEntry[], households: Household[], images: Record<string, string>): string {
  const entryCsv = exportCsv(entries, images);
  if (households.length === 0) return entryCsv;
  const householdCsv = exportHouseholdsCsv(households, images);
  return entryCsv + '\n\n--- HOUSEHOLDS ---\n' + householdCsv;
}

export function parseCsvFile(file: File): Promise<{ entries: DirectoryEntry[]; households: Household[]; imageIdMap: Record<string, string>; errors: string[] }> {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => {
      const text = reader.result as string;
      const entries: DirectoryEntry[] = [];
      const households: Household[] = [];
      const errors: string[] = [];
      // Maps new entry ID -> original imageId from CSV (for re-linking images)
      const imageIdMap: Record<string, string> = {};

      // Split on household separator
      const separatorIdx = text.indexOf('--- HOUSEHOLDS ---');
      const entriesText = separatorIdx >= 0 ? text.substring(0, separatorIdx).trim() : text.trim();
      const householdsText = separatorIdx >= 0 ? text.substring(separatorIdx + '--- HOUSEHOLDS ---'.length).trim() : '';

      // Parse entries
      if (entriesText) {
        const result = Papa.parse(entriesText, { header: true, skipEmptyLines: true });
        (result.data as Record<string, string>[]).forEach((row, i) => {
          const entry = csvRowToEntry(row);
          if (entry) {
            entries.push(entry);
            if (row.imageId?.trim()) imageIdMap[entry.id] = row.imageId.trim();
          }
          else errors.push(`Row ${i + 2}: Could not parse (invalid or missing type)`);
        });
      }

      // Parse households
      if (householdsText) {
        const result = Papa.parse(householdsText, { header: true, skipEmptyLines: true });
        (result.data as Record<string, string>[]).forEach((row, i) => {
          const household = csvRowToHousehold(row);
          if (household) {
            households.push(household);
            if (row.imageId?.trim()) imageIdMap[household.id] = row.imageId.trim();
          }
          else errors.push(`Household row ${i + 2}: Could not parse (missing name)`);
        });
      }

      resolve({ entries, households, imageIdMap, errors });
    };
    reader.onerror = () => resolve({ entries: [], households: [], imageIdMap: {}, errors: ['Failed to read file'] });
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
import React, { useState, useEffect, useRef, useMemo } from 'react';
import { PageStorageError, downloadFile } from '@amzn/quick-pages-runtime-lib';

import type { DirectoryEntry, Person, Company, View, SortField, SortDir, TypeFilter, Household, StatusFilter } from './types';
import { EMAIL_LABELS_PERSON, EMAIL_LABELS_COMPANY, PHONE_LABELS_PERSON, PHONE_LABELS_COMPANY, GENDER_OPTIONS } from './types';
import { S, colors } from './styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr, getAncestorIds, getDescendantIds } from './utils';
import { exportFullCsv, parseCsvFile, saveEntry, saveHousehold, saveImage } from './storage';

import { useDirectoryData, useFilteredEntries } from './hooks/useDirectoryData';
import { useDirectoryActions } from './hooks/useDirectoryActions';
import { usePersonForm } from './hooks/usePersonForm';
import { useCompanyForm } from './hooks/useCompanyForm';

import { MultiAddressFields } from './components/AddressFields';
import { MultiItemField } from './components/MultiItemField';
import { RelationshipPicker } from './components/RelationshipPicker';
import { SpousePicker } from './components/SpousePicker';
import { HouseholdMembership } from './components/HouseholdPicker';
import { HouseholdView } from './components/HouseholdView';
import { DuplicateWarningBanner } from './components/DuplicateWarning';
import { FilterBar } from './components/FilterBar';
import { EmailInput } from './components/EmailInput';
import { PhoneInput } from './components/PhoneInput';
import { ProfileImage } from './components/ProfileImage';
import { useCollapsedSections } from './components/CollapsibleSection';
import { BulkActionsBar } from './components/BulkActions';
import { PrintDialog } from './components/PrintDirectory';
import { DeleteDialog, DeleteAllDialog } from './components/DeleteDialogs';
import { DetailView } from './views/DetailView';
import { ImportView } from './views/ImportView';
import { ToastProvider, useToast } from './components/Toast';
import { QuickAddRelativeDialog } from './components/QuickAddRelative';

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
import filterBarSource from './components/FilterBar.tsx?raw';
import phoneInputSource from './components/PhoneInput.tsx?raw';
import profileImageSource from './components/ProfileImage.tsx?raw';
import imageCropperSource from './components/ImageCropper.tsx?raw';
import familyTreeSource from './components/FamilyTree.tsx?raw';
import collapsibleSectionSource from './components/CollapsibleSection.tsx?raw';
import vcardExportSource from './components/VCardExport.tsx?raw';
import bulkActionsSource from './components/BulkActions.tsx?raw';
import printDirectorySource from './components/PrintDirectory.tsx?raw';
import deleteDialogsSource from './components/DeleteDialogs.tsx?raw';
import detailViewSource from './views/DetailView.tsx?raw';
import importViewSource from './views/ImportView.tsx?raw';
import useDirectoryDataSource from './hooks/useDirectoryData.ts?raw';
import useDirectoryActionsSource from './hooks/useDirectoryActions.ts?raw';
import usePersonFormSource from './hooks/usePersonForm.ts?raw';
import useCompanyFormSource from './hooks/useCompanyForm.ts?raw';
import emailInputSource from './components/EmailInput.tsx?raw';
import toastSource from './components/Toast.tsx?raw';
import quickAddRelativeSource from './components/QuickAddRelative.tsx?raw';

// ─── Main App ────────────────────────────────────────────────────────

const AppInner = () => {
  const { addToast } = useToast();
  const [view, setView] = useState<View>('list');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [searchQ, setSearchQ] = useState('');
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const searchRef = useRef<HTMLDivElement>(null);
  const [sortField, setSortField] = useState<SortField>('name');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all');
  const [industryFilter, setIndustryFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('active');
  const [pageSize, setPageSize] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);
  const [selectMode, setSelectMode] = useState(false);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [deleteTarget, setDeleteTarget] = useState<DirectoryEntry | null>(null);
  const [showDeleteAll, setShowDeleteAll] = useState(false);
  const [deletingAll, setDeletingAll] = useState(false);
  const [showPrintDialog, setShowPrintDialog] = useState(false);
  const [quickAddMode, setQuickAddMode] = useState<'spouse' | 'child' | null>(null);
  const [editingPendingId, setEditingPendingId] = useState<string | null>(null);
  const [importPreview, setImportPreview] = useState<DirectoryEntry[]>([]);
  const [importHouseholdsPreview, setImportHouseholdsPreview] = useState<Household[]>([]);
  const [importImageIdMap, setImportImageIdMap] = useState<Record<string, string>>({});
  const [importFileName, setImportFileName] = useState('');
  const [importing, setImporting] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const errorRef = useRef<HTMLDivElement>(null);

  const data = useDirectoryData();
  const { entries, households, images, loading, error, setError, reload, allPersons, allIndustries } = data;
  const { collapsed: collapsedSections, toggle: toggleSection } = useCollapsedSections();
  const { searchResults, filteredEntries } = useFilteredEntries(entries, searchQ, typeFilter, industryFilter, statusFilter, sortField, sortDir);

  const actions = useDirectoryActions({
    entries, allPersons, households, images, reload, setError,
    selectedId, setSelectedId, setView, setSelectMode, setSelectedIds,
    setDeletingAll, setShowDeleteAll, setDeleteTarget, deleteTarget,
  });

  const personForm = usePersonForm({ entries, allPersons, households, images, reload, setError, setView });
  const companyForm = useCompanyForm({ entries, images, reload, setError, setView });

  useEffect(() => { setCurrentPage(1); }, [searchQ, typeFilter, industryFilter, statusFilter, sortField, sortDir]);
  useEffect(() => {
    const h = (ev: MouseEvent) => { if (searchRef.current && !searchRef.current.contains(ev.target as Node)) setShowSearchDropdown(false); };
    document.addEventListener('mousedown', h);
    return () => document.removeEventListener('mousedown', h);
  }, []);

  const totalEntries = filteredEntries.length;
  const totalPages = Math.max(1, Math.ceil(totalEntries / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStart = (safeCurrentPage - 1) * pageSize;
  const pageEnd = Math.min(pageStart + pageSize, totalEntries);
  const paginatedEntries = filteredEntries.slice(pageStart, pageEnd);

  const selectedEntry = entries.find(e => e.id === selectedId);
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };

  // ── CSV / Import ──
  const handleExportCsv = async () => {
    if (entries.length === 0 && households.length === 0) { setError('No entries to export.'); return; }
    try {
      await downloadFile('directory-export.csv', new Blob([exportFullCsv(entries, households, images)], { type: 'text/csv' }));
      if (Object.keys(images).length > 0) await downloadFile('directory-images.json', new Blob([JSON.stringify(images, null, 2)], { type: 'application/json' }));
      addToast('📥 CSV exported successfully');
    } catch (e: any) { setError(e?.message || 'Export failed'); }
  };

  const handleFileSelect = async (file: File) => {
    setError(''); setImportFileName(file.name);
    if (file.name.endsWith('.json')) {
      try {
        const parsed = JSON.parse(await file.text()) as Record<string, string>;
        const count = Object.keys(parsed).length;
        if (count === 0) { setError('No images found in the JSON file.'); return; }
        for (const [id, dataUrl] of Object.entries(parsed)) { if (typeof dataUrl === 'string' && dataUrl.startsWith('data:image/')) await saveImage(id, dataUrl); }
        await reload();
        addToast(`✅ Successfully imported ${count} profile image${count === 1 ? '' : 's'}`);
      } catch (e) { if (e instanceof PageStorageError) setError(e.message); else setError('Failed to parse images JSON file.'); }
      return;
    }
    const { entries: parsed, households: parsedHH, imageIdMap, errors } = await parseCsvFile(file);
    if (errors.length > 0) setError(errors.slice(0, 5).join('. ') + (errors.length > 5 ? ` ...and ${errors.length - 5} more.` : ''));
    setImportPreview(parsed); setImportHouseholdsPreview(parsedHH); setImportImageIdMap(imageIdMap); setView('import');
  };

  const handleImportConfirm = async () => {
    if (importPreview.length === 0 && importHouseholdsPreview.length === 0) return;
    setImporting(true); setError('');
    try {
      let saved = 0;
      for (const entry of importPreview) { await saveEntry(entry); const oid = importImageIdMap[entry.id]; if (oid && images[oid] && oid !== entry.id) await saveImage(entry.id, images[oid]); saved++; }
      for (const hh of importHouseholdsPreview) { await saveHousehold(hh); const oid = importImageIdMap[hh.id]; if (oid && images[oid] && oid !== hh.id) await saveImage(hh.id, images[oid]); saved++; }
      await reload(); setImportPreview([]); setImportHouseholdsPreview([]); setImportImageIdMap({}); setImportFileName(''); setView('list');
      addToast(`✅ Successfully imported ${saved} record${saved === 1 ? '' : 's'}`);
    } catch (e) { if (e instanceof PageStorageError) setError(e.message); }
    finally { setImporting(false); }
  };
  const handleImportCancel = () => { setImportPreview([]); setImportHouseholdsPreview([]); setImportImageIdMap({}); setImportFileName(''); setView('list'); };

  // ── Code / Log export ──
  const handleDownloadMarkdown = async () => { try { await downloadFile('directory-app-conversation.md', new Blob([devLog], { type: 'text/markdown' })); addToast('📄 Conversation log exported'); } catch (e: any) { setError(e?.message || 'Download failed'); } };
  const handleDownloadCode = async () => {
    const pkgJson = JSON.stringify({ name: "directory-app", version: "0.1.0", private: true, type: "module", dependencies: { "papaparse": "^5.5.3", "react": "^18.2.0", "react-dom": "^18.2.0", "uuid": "^11.1.0" }, devDependencies: { "@types/papaparse": "^5.3.15", "@types/react": "^18.2.0", "@types/react-dom": "^18.2.25", "@types/uuid": "^10.0.0", "@vitejs/plugin-react": "^4.3.4", "typescript": "^5.1.6", "vite": "^6.4.1", "vite-tsconfig-paths": "^4.2.0" }, scripts: { dev: "vite", build: "tsc && vite build", preview: "vite preview" } }, null, 2);
    const tsJson = JSON.stringify({ compilerOptions: { target: "esnext", useDefineForClassFields: true, lib: ["DOM", "DOM.Iterable", "ESNext"], allowJs: false, skipLibCheck: true, esModuleInterop: false, allowSyntheticDefaultImports: true, strict: false, forceConsistentCasingInFileNames: true, module: "ESNext", moduleResolution: "Node", resolveJsonModule: true, isolatedModules: true, strictNullChecks: true, noEmit: true, jsx: "react-jsx", paths: { "@root/*": ["./src/*"] } }, include: ["src"] }, null, 2);
    const viteCfg = `import react from '@vitejs/plugin-react';\nimport { defineConfig } from 'vite';\nimport tsconfigPaths from 'vite-tsconfig-paths';\n\nexport default defineConfig({ plugins: [react(), tsconfigPaths()] });\n`;
    const indexHtml = `<!DOCTYPE html>\n<html lang="en"><head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>Directory App</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>\n`;
    const readme = `# Directory App\n\nA personal/church directory application built with React + TypeScript + Vite.\n\n## Getting Started\n\n\`\`\`bash\nnpm install\nnpm run dev\n\`\`\`\n\n## Notes\n\n- This export is a standalone version. Replace \`@amzn/quick-pages-runtime-lib\` storage calls with your own backend.\n`;
    const files: [string, string][] = [
      ['package.json', pkgJson], ['tsconfig.json', tsJson], ['vite.config.ts', viteCfg], ['index.html', indexHtml], ['README.md', readme],
      ['src/main.tsx', mainSource], ['src/vite-env.d.ts', viteEnvSource], ['src/types.ts', typesSource], ['src/styles.ts', stylesSource], ['src/utils.ts', utilsSource], ['src/storage.ts', storageSource], ['src/countryCodes.ts', countryCodesSource], ['src/App.tsx', appSource],
      ['src/hooks/useDirectoryData.ts', useDirectoryDataSource], ['src/hooks/useDirectoryActions.ts', useDirectoryActionsSource], ['src/hooks/usePersonForm.ts', usePersonFormSource], ['src/hooks/useCompanyForm.ts', useCompanyFormSource],
      ['src/views/DetailView.tsx', detailViewSource], ['src/views/ImportView.tsx', importViewSource],
      ['src/components/AddressFields.tsx', addressFieldsSource], ['src/components/MultiItemField.tsx', multiItemFieldSource], ['src/components/CountryCodeSelect.tsx', countryCodeSelectSource], ['src/components/RelationshipPicker.tsx', relationshipPickerSource], ['src/components/SpousePicker.tsx', spousePickerSource], ['src/components/HouseholdPicker.tsx', householdPickerSource], ['src/components/HouseholdView.tsx', householdViewSource], ['src/components/DuplicateWarning.tsx', duplicateWarningSource], ['src/components/FilterBar.tsx', filterBarSource], ['src/components/EmailInput.tsx', emailInputSource], ['src/components/PhoneInput.tsx', phoneInputSource], ['src/components/ProfileImage.tsx', profileImageSource], ['src/components/ImageCropper.tsx', imageCropperSource], ['src/components/FamilyTree.tsx', familyTreeSource], ['src/components/CollapsibleSection.tsx', collapsibleSectionSource], ['src/components/VCardExport.tsx', vcardExportSource], ['src/components/BulkActions.tsx', bulkActionsSource], ['src/components/PrintDirectory.tsx', printDirectorySource], ['src/components/DeleteDialogs.tsx', deleteDialogsSource], ['src/components/Toast.tsx', toastSource], ['src/components/QuickAddRelative.tsx', quickAddRelativeSource],
      ['DEVLOG.md', devLog],
    ];
    const lines = ['#!/usr/bin/env bash', '# Directory App — Self-Extracting Source Code', 'set -e', 'ROOT="directory-app"', 'mkdir -p "$ROOT/src/components" "$ROOT/src/hooks" "$ROOT/src/views"', 'echo "Extracting files into $ROOT/ ..."', ''];
    for (const [path, content] of files) { const d = `__EOF_${path.replace(/[^a-zA-Z0-9]/g, '_').toUpperCase()}__`; lines.push(`cat > "$ROOT/${path}" << '${d}'`, content, d, ''); }
    lines.push(`echo "✅ Done! Extracted ${files.length} files into $ROOT/"`, 'echo "To get started: cd $ROOT && npm install && npm run dev"');
    try { await downloadFile('directory-app.sh', new Blob([lines.join('\n')], { type: 'text/x-shellscript' })); addToast('💾 Source code exported'); } catch (e: any) { setError(e?.message || 'Download failed'); }
  };

  // ── Render ──
  return (
    <div style={S.app}>
      {/* Header */}
      <div style={S.header}>
        <h1 style={S.headerTitle} onClick={() => { setView('list'); setSelectedId(null); setSearchQ(''); }}>📒 Directory</h1>
        <div style={S.searchWrap} ref={searchRef}>
          <input style={S.searchInput} placeholder="Search persons & companies..." value={searchQ} onChange={e => { setSearchQ(e.target.value); setShowSearchDropdown(true); }} onFocus={() => setShowSearchDropdown(true)} />
          {showSearchDropdown && searchQ && (
            <div style={S.dropdown}>
              {searchResults.length === 0 && <div style={{ padding: 14, color: colors.textSec }}>No results</div>}
              {searchResults.slice(0, 10).map(e => (
                <div key={e.id} style={{ ...S.dropdownItem, display: 'flex', alignItems: 'center', gap: 8 }} onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)} onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')} onClick={() => { setSearchQ(getEntryName(e)); setShowSearchDropdown(false); setSelectedId(e.id); setView('detail'); }}>
                  <ProfileImage imageUrl={images[e.id] || null} size={24} fallback={e.type === 'person' ? '👤' : '🏢'} />
                  {getEntryName(e)}{e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({e.industry})</span>}
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
        {error && <div ref={errorRef} style={S.error}>{error}</div>}

        {/* ── LIST VIEW ── */}
        {view === 'list' && (
          <>
            <div style={S.btnRow}>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { personForm.reset(); setView('personForm'); }}>+ Add Person</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => { companyForm.reset(); setView('companyForm'); }}>+ Add Company</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setView('households')}>🏠 Households</button>
              <button style={{ ...S.btn, ...(selectMode ? { background: colors.primary, color: '#fff' } : S.btnSec) }} onClick={() => { setSelectMode(!selectMode); if (selectMode) setSelectedIds(new Set()); }}>{selectMode ? '✓ Selecting' : '☐ Select'}</button>
              <div style={{ flex: 1 }} />
              <button style={{ ...S.btn, ...S.btnSec }} onClick={handleExportCsv}>📥 Export CSV</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowPrintDialog(true)}>🖨️ Print</button>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => fileInputRef.current?.click()}>📤 Import CSV</button>
              <input ref={fileInputRef} type="file" accept=".csv,.json" style={{ display: 'none' }} onChange={e => { const f = e.target.files?.[0]; if (f) handleFileSelect(f); e.target.value = ''; }} />
              {entries.length > 0 && <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => setShowDeleteAll(true)} disabled={deletingAll}>{deletingAll ? '🗑️ Deleting...' : '🗑️ Delete All'}</button>}
            </div>
            <FilterBar sortField={sortField} setSortField={setSortField} sortDir={sortDir} setSortDir={setSortDir} typeFilter={typeFilter} setTypeFilter={setTypeFilter} industryFilter={industryFilter} setIndustryFilter={setIndustryFilter} allIndustries={allIndustries} statusFilter={statusFilter} setStatusFilter={setStatusFilter} totalCount={filteredEntries.length} />
            {loading ? <div style={S.emptyState}>Loading...</div> : filteredEntries.length === 0 ? <div style={S.emptyState}>{searchQ ? 'No matching entries.' : 'No entries yet. Add a person or company to get started.'}</div> : (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, fontSize: 13, color: colors.textSec }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    {selectMode && <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><button onClick={() => setSelectedIds(new Set(filteredEntries.map(e => e.id)))} style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }}>All</button><button onClick={() => setSelectedIds(new Set())} style={{ ...S.btn, padding: '2px 8px', fontSize: 11, ...S.btnSec }}>None</button></div>}
                    <span>Showing {pageStart + 1}–{pageEnd} of {totalEntries} entr{totalEntries === 1 ? 'y' : 'ies'}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><span>Per page:</span>{[25, 50, 100].map(size => <button key={size} onClick={() => { setPageSize(size); setCurrentPage(1); }} style={{ ...S.btn, padding: '3px 10px', fontSize: 12, background: pageSize === size ? colors.primary : 'transparent', color: pageSize === size ? '#fff' : colors.text, border: `1px solid ${pageSize === size ? colors.primary : colors.border}`, borderRadius: 4 }}>{size}</button>)}</div>
                </div>
                {paginatedEntries.map(e => {
                  const isInactive = e.type === 'person' ? e.status === 'deceased' : e.companyStatus === 'closed';
                  const isSelected = selectedIds.has(e.id);
                  return (
                    <div key={e.id} style={{ ...S.card, ...(isInactive ? { opacity: 0.7, borderLeft: '4px solid #9e9e9e' } : {}), ...(isSelected ? { border: `2px solid ${colors.primary}`, background: '#f0f7ff' } : {}) }} onMouseEnter={ev => (ev.currentTarget.style.boxShadow = '0 3px 10px rgba(0,0,0,.12)')} onMouseLeave={ev => (ev.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,.08)')} onClick={() => { if (selectMode) { setSelectedIds(prev => { const n = new Set(prev); if (n.has(e.id)) n.delete(e.id); else n.add(e.id); return n; }); } else { setSelectedId(e.id); setView('detail'); } }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          {selectMode && <div style={{ width: 20, height: 20, borderRadius: 4, border: `2px solid ${isSelected ? colors.primary : colors.border}`, background: isSelected ? colors.primary : '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{isSelected && <span style={{ color: '#fff', fontSize: 13, fontWeight: 700, lineHeight: 1 }}>✓</span>}</div>}
                          <ProfileImage imageUrl={images[e.id] || null} size={36} fallback={e.type === 'person' ? '👤' : '🏢'} />
                          <strong style={isInactive ? { color: colors.textSec } : {}}>{getEntryName(e)}</strong>
                          {isInactive && <span style={{ ...S.badge, background: '#e0e0e0', color: '#616161', fontSize: 10 }}>{e.type === 'person' ? '✝ DECEASED' : '🚫 CLOSED'}</span>}
                          {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                        </div>
                        {e.type === 'person' && (
                          <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: colors.textSec }}>
                            {e.spouseId && <span title={`Spouse: ${resolveName(e.spouseId)}`}>💍</span>}
                            {e.childIds.length > 0 && <span title={`${e.childIds.length} child${e.childIds.length > 1 ? 'ren' : ''}`}>🧒 {e.childIds.length}</span>}
                            {(() => { const hh = households.find(h => h.memberIds.includes(e.id)); return hh ? <span title={hh.name}>🏠</span> : null; })()}
                          </div>
                        )}
                      </div>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontSize: 13, color: colors.textSec, marginTop: 6 }}>
                        {getPrimary(e.emails)?.address && <span>✉️ {getPrimary(e.emails)!.address}</span>}
                        {getPrimary(e.phones)?.number && <span>📞 {(getPrimary(e.phones)!.countryCode || '+1')} {formatPhoneDisplay(getPrimary(e.phones)!.number)}</span>}
                        {e.type === 'company' && e.website && <span onClick={ev => ev.stopPropagation()}><a href={e.website} target="_blank" rel="noopener noreferrer" style={{ color: colors.primary, textDecoration: 'underline' }}>🌐 {e.website.replace(/^https?:\/\//, '')}</a></span>}
                        {getPrimary(e.addresses) && <span>📍 {formatAddr(getPrimary(e.addresses)!)}</span>}
                      </div>
                    </div>
                  );
                })}
                {totalPages > 1 && (
                  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6, marginTop: 16 }}>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(1)}>«</button>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))}>‹</button>
                    <span style={{ fontSize: 13, color: colors.textSec, margin: '0 8px' }}>Page {safeCurrentPage} of {totalPages}</span>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}>›</button>
                    <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }} disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(totalPages)}>»</button>
                  </div>
                )}
                <BulkActionsBar selectedIds={selectedIds} entries={entries} allPersons={allPersons} households={households} images={images} onClearSelection={() => { setSelectedIds(new Set()); setSelectMode(false); }} onBulkDelete={actions.handleBulkDelete} onBulkStatusChange={actions.handleBulkStatusChange} onBulkAssignHousehold={actions.handleBulkAssignHousehold} onCreateAndAssignHousehold={actions.handleCreateAndAssignHousehold} onError={setError} onToast={msg => addToast(msg)} />
              </>
            )}
          </>
        )}

        {/* ── PERSON FORM ── */}
        {view === 'personForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{personForm.editId ? 'Edit Person' : 'Add Person'}</h2>
            <DuplicateWarningBanner duplicates={personForm.duplicates} onViewEntry={id => { setSelectedId(id); setView('detail'); }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}><ProfileImage imageUrl={personForm.pImage} size={72} fallback="👤" editable onImageChange={personForm.setPImage} /><span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a profile photo</span></div>
            <div style={S.formGrid}>
              <div><label style={S.label}>First Name *</label><input ref={personForm.pFirstRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pFirst') ? { borderColor: colors.danger } : {}) }} value={personForm.pFirst} onChange={e => { personForm.setPFirst(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pFirst'); return n; }); }} />{personForm.fieldErrors.has('pFirst') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>First name is required</div>}</div>
              <div><label style={S.label}>Last Name *</label><input ref={personForm.pLastRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pLast') ? { borderColor: colors.danger } : {}) }} value={personForm.pLast} onChange={e => { personForm.setPLast(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pLast'); return n; }); }} />{personForm.fieldErrors.has('pLast') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Last name is required</div>}</div>
            </div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Personal Information</div></div>
              <div><label style={S.label}>Gender *</label><select ref={personForm.pGenderRef} style={{ ...S.input, ...(personForm.fieldErrors.has('pGender') ? { borderColor: colors.danger } : {}) }} value={personForm.pGender} onChange={e => { personForm.setPGender(e.target.value); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pGender'); return n; }); }}>{GENDER_OPTIONS.map(g => <option key={g} value={g}>{g || '— Select —'}</option>)}</select>{personForm.fieldErrors.has('pGender') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Gender is required</div>}</div>
              <div><label style={S.label}>Birthday</label><input style={S.input} type="date" value={personForm.pBirthday} onChange={e => personForm.setPBirthday(e.target.value)} /></div>
              <div><label style={S.label}>Status</label><select style={S.input} value={personForm.pStatus} onChange={e => personForm.setPStatus(e.target.value as 'active' | 'deceased')}><option value="active">Active</option><option value="deceased">Deceased</option></select></div>
              {personForm.pStatus === 'deceased' && <div><label style={S.label}>Date of Death</label><input style={S.input} type="date" value={personForm.pDeceasedDate} onChange={e => personForm.setPDeceasedDate(e.target.value)} /></div>}
            </div>
            <div ref={personForm.pEmailSectionRef}><MultiItemField title="Email Addresses" items={personForm.pEmails} onChange={v => { personForm.setPEmails(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pEmail'); return n; }); }} labels={EMAIL_LABELS_PERSON} itemName="Email" emptyFactory={p => ({ address: '', isPrimary: p, label: 'Personal' })} renderInput={(item, update) => <EmailInput placeholder="email@example.com" value={item.address} onChange={v => update({ ...item, address: v })} />} />{personForm.fieldErrors.has('pEmail') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid email addresses before saving.</div>}</div>
            <div ref={personForm.pPhoneSectionRef}><MultiItemField title="Phone Numbers" items={personForm.pPhones} onChange={v => { personForm.setPPhones(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pPhone'); return n; }); }} labels={PHONE_LABELS_PERSON} itemName="Phone" emptyFactory={p => ({ number: '', countryCode: '+1', isPrimary: p, label: 'Mobile' })} renderInput={(item, update) => <PhoneInput value={item.number} countryCode={item.countryCode} placeholder="(555) 123-4567" onChange={v => update({ ...item, number: v })} onCodeChange={code => update({ ...item, countryCode: code })} />} />{personForm.fieldErrors.has('pPhone') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid phone numbers before saving.</div>}</div>
            <div ref={personForm.pAddrSectionRef}><MultiAddressFields addresses={personForm.pAddrs} onChange={v => { personForm.setPAddrs(v); personForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('pAddr'); return n; }); }} personMode householdName={personForm.pHouseholdId ? households.find(h => h.id === personForm.pHouseholdId)?.name : undefined} onNavigateHousehold={() => setView('households')} />{personForm.fieldErrors.has('pAddr') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please complete all addresses — at least city and state are required.</div>}</div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={{ ...S.section, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <span>Relationships</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  {!personForm.pSpouseId && <button style={{ ...S.btn, padding: '3px 10px', fontSize: 12, background: colors.accent, color: colors.primary, border: `1px solid ${colors.primary}`, borderRadius: 4, fontWeight: 600 }} onClick={() => setQuickAddMode('spouse')}>+ Quick Add Spouse</button>}
                  <button style={{ ...S.btn, padding: '3px 10px', fontSize: 12, background: colors.accent, color: colors.primary, border: `1px solid ${colors.primary}`, borderRadius: 4, fontWeight: 600 }} onClick={() => setQuickAddMode('child')}>+ Quick Add Child</button>
                </div>
              </div></div>
              <SpousePicker allPersons={[...allPersons, ...personForm.pendingPersons]} pendingIds={new Set(personForm.pendingPersons.map(p => p.id))} editId={personForm.editId} selectedSpouseId={personForm.pSpouseId} childIds={personForm.pChildIds} currentGender={personForm.pGender} onSelect={sid => { personForm.setPSpouseId(sid); const spouse = allPersons.find(p => p.id === sid); if (spouse) personForm.setPChildIds(prev => Array.from(new Set([...prev, ...spouse.childIds]))); }} onClear={() => { const wasP = personForm.pendingPersons.find(p => p.id === personForm.pSpouseId); personForm.setPSpouseId(''); personForm.setPAnniversary(''); if (wasP) personForm.removePendingPerson(wasP.id); }} onEditPending={id => { setEditingPendingId(id); setQuickAddMode('spouse'); }} />
              <div><label style={S.label}>Wedding Anniversary</label><input style={S.input} type="date" value={personForm.pAnniversary} onChange={e => personForm.setPAnniversary(e.target.value)} disabled={!personForm.pSpouseId} /></div>
              <RelationshipPicker label="Children" entries={[...allPersons.filter(p => { if (p.id === personForm.editId || p.id === personForm.pSpouseId) return false; if (personForm.pChildIds.includes(p.id)) return true; if (personForm.editId && p.childIds.includes(personForm.editId)) return false; const cid = personForm.editId || '__new__'; if (getAncestorIds(cid, allPersons).has(p.id)) return false; if (getDescendantIds(p.id, allPersons).has(cid)) return false; return allPersons.filter(o => o.id !== personForm.editId && o.id !== personForm.pSpouseId && o.childIds.includes(p.id)).length < 2; }), ...personForm.pendingPersons.filter(p => personForm.pChildIds.includes(p.id))]} pendingIds={new Set(personForm.pendingPersons.map(p => p.id))} selectedIds={personForm.pChildIds} onToggle={id => { const wasP = personForm.pendingPersons.find(p => p.id === id); if (wasP && personForm.pChildIds.includes(id)) { personForm.removePendingPerson(id); } personForm.setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]); }} onEditPending={id => { setEditingPendingId(id); setQuickAddMode('child'); }} />
              <HouseholdMembership allPersons={allPersons} households={households} editId={personForm.editId} selectedHouseholdId={personForm.pHouseholdId} onSelectHousehold={hid => personForm.setPHouseholdId(hid)} onClearHousehold={() => personForm.setPHouseholdId('')} />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={personForm.pNotes} onChange={e => personForm.setPNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}><button style={{ ...S.btn, ...S.btnPrimary }} onClick={async () => { const name = await personForm.save(); if (name) addToast(`✅ ${name} saved`); }}>Save Person</button><button style={{ ...S.btn, ...S.btnSec }} onClick={() => { personForm.reset(); setError(''); setView('list'); }}>Cancel</button></div>
          </>
        )}

        {/* ── COMPANY FORM ── */}
        {view === 'companyForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{companyForm.editId ? 'Edit Company' : 'Add Company'}</h2>
            <DuplicateWarningBanner duplicates={companyForm.duplicates} onViewEntry={id => { setSelectedId(id); setView('detail'); }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}><ProfileImage imageUrl={companyForm.cImage} size={72} fallback="🏢" editable onImageChange={companyForm.setCImage} /><span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a profile photo</span></div>
            <div style={S.formGrid}>
              <div><label style={S.label}>Company Name *</label><input ref={companyForm.cNameRef} style={{ ...S.input, ...(companyForm.fieldErrors.has('cName') ? { borderColor: colors.danger } : {}) }} value={companyForm.cName} onChange={e => { companyForm.setCName(e.target.value); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cName'); return n; }); }} />{companyForm.fieldErrors.has('cName') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Company name is required</div>}</div>
              <div><label style={S.label}>Industry</label><input style={S.input} value={companyForm.cIndustry} onChange={e => companyForm.setCIndustry(e.target.value)} /></div>
              <div><label style={S.label}>Status</label><select style={S.input} value={companyForm.cStatus} onChange={e => companyForm.setCStatus(e.target.value as 'active' | 'closed')}><option value="active">Active</option><option value="closed">Closed</option></select></div>
              {companyForm.cStatus !== 'active' && <div><label style={S.label}>Date Closed</label><input style={S.input} type="date" value={companyForm.cClosedDate} onChange={e => companyForm.setCClosedDate(e.target.value)} /></div>}
            </div>
            <div style={{ marginTop: 14 }}><label style={S.label}>Website</label><input ref={companyForm.cWebsiteRef} style={{ ...S.input, ...(companyForm.cWebsiteError ? { borderColor: colors.danger } : {}) }} type="url" placeholder="https://www.example.com" value={companyForm.cWebsite} onChange={e => { companyForm.setCWebsite(e.target.value); companyForm.setCWebsiteError(''); }} onBlur={() => { if (companyForm.cWebsite.trim()) { try { const raw = companyForm.cWebsite.trim().match(/^https?:\/\//) ? companyForm.cWebsite.trim() : `https://${companyForm.cWebsite.trim()}`; const parsed = new URL(raw); if (!parsed.hostname.includes('.')) throw new Error('invalid'); companyForm.setCWebsiteError(''); parsed.hostname = parsed.hostname.replace(/^www\./, ''); let n = parsed.toString(); if (parsed.pathname === '/' && !parsed.search && !parsed.hash) n = n.replace(/\/$/, ''); companyForm.setCWebsite(n); } catch { companyForm.setCWebsiteError('Please enter a valid URL (e.g. https://example.com)'); } } else { companyForm.setCWebsiteError(''); } }} />{companyForm.cWebsiteError && <div style={{ fontSize: 12, color: colors.danger, marginTop: 4 }}>{companyForm.cWebsiteError}</div>}</div>
            <div ref={companyForm.cEmailSectionRef}><MultiItemField title="Email Addresses" items={companyForm.cEmails} onChange={v => { companyForm.setCEmails(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cEmail'); return n; }); }} labels={EMAIL_LABELS_COMPANY} itemName="Email" emptyFactory={p => ({ address: '', isPrimary: p, label: 'Main' })} renderInput={(item, update) => <EmailInput placeholder="contact@company.com" value={item.address} onChange={v => update({ ...item, address: v })} />} />{companyForm.fieldErrors.has('cEmail') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid email addresses before saving.</div>}</div>
            <div ref={companyForm.cPhoneSectionRef}><MultiItemField title="Phone Numbers" items={companyForm.cPhones} onChange={v => { companyForm.setCPhones(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cPhone'); return n; }); }} labels={PHONE_LABELS_COMPANY} itemName="Phone" emptyFactory={p => ({ number: '', countryCode: '+1', isPrimary: p, label: 'Main' })} renderInput={(item, update) => <PhoneInput value={item.number} countryCode={item.countryCode} placeholder="(555) 123-4567" onChange={v => update({ ...item, number: v })} onCodeChange={code => update({ ...item, countryCode: code })} />} />{companyForm.fieldErrors.has('cPhone') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please fix invalid phone numbers before saving.</div>}</div>
            <div ref={companyForm.cAddrSectionRef}><MultiAddressFields addresses={companyForm.cAddrs} onChange={v => { companyForm.setCAddrs(v); companyForm.setFieldErrors(prev => { const n = new Set(prev); n.delete('cAddr'); return n; }); }} companyMode />{companyForm.fieldErrors.has('cAddr') && <div style={{ fontSize: 12, color: colors.danger, marginTop: -6, marginBottom: 8 }}>Please complete all addresses — at least city and state are required.</div>}</div>
            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Contact Persons</div></div>
              <RelationshipPicker label="Contact Persons" entries={allPersons} selectedIds={companyForm.cContactIds} onToggle={id => companyForm.setCContactIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />
              <div style={S.fieldFull}><label style={S.label}>Notes</label><textarea style={S.textarea} value={companyForm.cNotes} onChange={e => companyForm.setCNotes(e.target.value)} /></div>
            </div>
            <div style={{ ...S.btnRow, marginTop: 18 }}><button style={{ ...S.btn, ...S.btnPrimary }} onClick={async () => { const name = await companyForm.save(); if (name) addToast(`✅ ${name} saved`); }}>Save Company</button><button style={{ ...S.btn, ...S.btnSec }} onClick={() => { companyForm.reset(); setError(''); setView('list'); }}>Cancel</button></div>
          </>
        )}

        {/* ── DETAIL VIEW ── */}
        {view === 'detail' && selectedEntry && (
          <DetailView entry={selectedEntry} entries={entries} allPersons={allPersons} households={households} images={images} collapsedSections={collapsedSections} toggleSection={toggleSection} setSelectedId={setSelectedId} setView={setView} setError={setError}
            onEdit={() => { if (selectedEntry.type === 'person') { personForm.fill(selectedEntry as Person); setView('personForm'); } else { companyForm.fill(selectedEntry as Company); setView('companyForm'); } }}
            onDelete={() => setDeleteTarget(selectedEntry)}
            onToast={msg => addToast(msg)} />
        )}

        {/* ── HOUSEHOLDS VIEW ── */}
        {view === 'households' && (
          <><div style={S.btnRow}><button style={{ ...S.btn, ...S.btnSec }} onClick={() => setView('list')}>← Back to Directory</button></div><h2 style={{ marginBottom: 16 }}>🏠 Households</h2><HouseholdView households={households} allPersons={allPersons} images={images} onReload={reload} /></>
        )}

        {/* ── IMPORT PREVIEW ── */}
        {view === 'import' && <ImportView importPreview={importPreview} importHouseholdsPreview={importHouseholdsPreview} importFileName={importFileName} importing={importing} onConfirm={handleImportConfirm} onCancel={handleImportCancel} />}
      </div>

      {/* ── DIALOGS ── */}
      {deleteTarget && <DeleteDialog target={deleteTarget} allPersons={allPersons} entries={entries} onCancel={() => setDeleteTarget(null)} onConfirm={async () => { const name = await actions.confirmDelete(); if (name) addToast(`🗑️ ${name} deleted`); }} />}
      {showDeleteAll && <DeleteAllDialog entryCount={entries.length} householdCount={households.length} onCancel={() => setShowDeleteAll(false)} onConfirm={async () => { const count = await actions.handleDeleteAll(); if (count) addToast(`🗑️ All ${count} records deleted`); }} />}
      {showPrintDialog && <PrintDialog entries={entries} households={households} images={images} onClose={() => setShowPrintDialog(false)} onError={setError} onSuccess={() => addToast('🖨️ Directory generated')} />}
      {quickAddMode && (
        <QuickAddRelativeDialog
          mode={quickAddMode}
          currentGender={personForm.pGender}
          defaultLastName={personForm.pLast}
          editPerson={editingPendingId ? personForm.pendingPersons.find(p => p.id === editingPendingId) : null}
          onCancel={() => { setQuickAddMode(null); setEditingPendingId(null); }}
          onCreated={(person) => {
            if (editingPendingId) {
              personForm.updatePendingPerson(person);
              addToast(`✏️ ${person.firstName} ${person.lastName} updated`);
            } else {
              personForm.addPendingPerson(person);
              if (quickAddMode === 'spouse') {
                personForm.setPSpouseId(person.id);
              } else {
                personForm.setPChildIds(prev => [...prev, person.id]);
              }
              addToast(`✨ ${person.firstName} ${person.lastName} added as pending ${quickAddMode}`);
            }
            setQuickAddMode(null);
            setEditingPendingId(null);
          }}
        />
      )}
    </div>
  );
};

export const App = () => (
  <ToastProvider>
    <AppInner />
  </ToastProvider>
);

export default App;

__EOF_SRC_APP_TSX__

cat > "$ROOT/src/hooks/useDirectoryData.ts" << '__EOF_SRC_HOOKS_USEDIRECTORYDATA_TS__'
import { useState, useCallback, useEffect, useMemo } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household, SortField, SortDir, TypeFilter, StatusFilter } from '../types';
import { getEntryName } from '../utils';
import { loadAll, loadAllHouseholds, loadAllImages } from '../storage';

export function useDirectoryData() {
  const [entries, setEntries] = useState<DirectoryEntry[]>([]);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [images, setImages] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const reload = useCallback(async () => {
    try {
      setLoading(true);
      setEntries(await loadAll());
      setHouseholds(await loadAllHouseholds());
      setImages(await loadAllImages());
    } catch (e) {
      if (e instanceof PageStorageError) setError((e as PageStorageError).message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { reload(); }, [reload]);

  const allPersons = useMemo(() => entries.filter((e): e is Person => e.type === 'person'), [entries]);

  const allIndustries = useMemo(() => {
    const set = new Set<string>();
    entries.forEach(e => { if (e.type === 'company' && e.industry.trim()) set.add(e.industry.trim()); });
    return Array.from(set).sort();
  }, [entries]);

  return { entries, households, images, loading, error, setError, reload, allPersons, allIndustries };
}

export function useFilteredEntries(
  entries: DirectoryEntry[],
  searchQ: string,
  typeFilter: TypeFilter,
  industryFilter: string,
  statusFilter: StatusFilter,
  sortField: SortField,
  sortDir: SortDir,
) {
  const sq = searchQ.toLowerCase();
  const searchResults = useMemo(() => entries.filter(e =>
    e.type === 'person'
      ? `${e.firstName} ${e.lastName} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
      : `${e.name} ${e.industry} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
  ), [entries, sq]);

  const filteredEntries = useMemo(() => {
    let list = searchQ ? searchResults : entries;
    if (typeFilter !== 'all') list = list.filter(e => e.type === typeFilter);
    if (industryFilter) list = list.filter(e => e.type === 'company' && e.industry.trim().toLowerCase() === industryFilter.toLowerCase());
    if (statusFilter === 'active') {
      list = list.filter(e => e.type === 'person' ? (e.status || 'active') === 'active' : (e.companyStatus || 'active') === 'active');
    } else if (statusFilter === 'deceased') {
      list = list.filter(e => e.type === 'person' && e.status === 'deceased');
    } else if (statusFilter === 'closed') {
      list = list.filter(e => e.type === 'company' && e.companyStatus === 'closed');
    } else {
      list = list.filter(e => e.type === 'person' ? (e.status || 'active') !== 'archived' : (e.companyStatus || 'active') !== 'archived');
    }
    list = [...list].sort((a, b) => {
      let cmp = 0;
      if (sortField === 'name') cmp = getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else if (sortField === 'type') cmp = a.type.localeCompare(b.type) || getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase());
      else cmp = a.id.localeCompare(b.id);
      return sortDir === 'desc' ? -cmp : cmp;
    });
    return list;
  }, [entries, searchQ, searchResults, typeFilter, industryFilter, statusFilter, sortField, sortDir]);

  return { searchResults, filteredEntries };
}

__EOF_SRC_HOOKS_USEDIRECTORYDATA_TS__

cat > "$ROOT/src/hooks/useDirectoryActions.ts" << '__EOF_SRC_HOOKS_USEDIRECTORYACTIONS_TS__'
import { useCallback } from 'react';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Household } from '../types';
import { getEntryName } from '../utils';
import { saveEntry, loadEntry, removeEntry, saveHousehold, loadHousehold, removeHousehold, saveImage, removeImage } from '../storage';

interface ActionsDeps {
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  reload: () => Promise<void>;
  setError: (msg: string) => void;
  selectedId: string | null;
  setSelectedId: (id: string | null) => void;
  setView: (v: any) => void;
  setSelectMode: (v: boolean) => void;
  setSelectedIds: (v: React.SetStateAction<Set<string>>) => void;
  setDeletingAll: (v: boolean) => void;
  setShowDeleteAll: (v: boolean) => void;
  setDeleteTarget: (v: DirectoryEntry | null) => void;
  deleteTarget: DirectoryEntry | null;
}

export function useDirectoryActions(deps: ActionsDeps) {
  const { entries, allPersons, households, images, reload, setError,
    selectedId, setSelectedId, setView, setSelectMode, setSelectedIds,
    setDeletingAll, setShowDeleteAll, setDeleteTarget, deleteTarget } = deps;

  const confirmDelete = useCallback(async () => {
    if (!deleteTarget) return null;
    const id = deleteTarget.id;
    const deletedName = getEntryName(deleteTarget);
    setDeleteTarget(null);
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person') {
        if (entry.spouseId) {
          const spouse = await loadEntry(entry.spouseId);
          if (spouse && spouse.type === 'person') {
            const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => cid !== id);
            await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
          }
        }
        for (const p of allPersons) {
          if (p.id !== id && p.childIds.includes(id)) await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
        }
        for (const e of entries) {
          if (e.type === 'company' && e.contactPersonIds.includes(id)) await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
        }
        if (entry.householdId) {
          const household = households.find(h => h.id === entry.householdId);
          if (household) {
            const remainingIds = household.memberIds.filter(mid => mid !== id);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') {
                  await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.isPrimary && a.label === 'Household' ? { ...a, label: 'Home' } : a) });
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
      await removeEntry(id);
      if (images[id]) await removeImage(id);
      await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
      return deletedName;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  }, [deleteTarget, allPersons, entries, households, images, reload, setError, selectedId, setSelectedId, setView, setDeleteTarget]);

  const handleDeleteAll = useCallback(async () => {
    setShowDeleteAll(false);
    setDeletingAll(true);
    try {
      const count = entries.length + households.length;
      for (const entry of entries) { await removeEntry(entry.id); if (images[entry.id]) await removeImage(entry.id); }
      for (const h of households) { await removeHousehold(h.id); if (images[h.id]) await removeImage(h.id); }
      await reload();
      setSelectedId(null);
      setView('list');
      return count;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
    finally { setDeletingAll(false); }
  }, [entries, households, images, reload, setError, setSelectedId, setView, setDeletingAll, setShowDeleteAll]);

  const handleBulkDelete = useCallback(async (ids: string[]) => {
    try {
      for (const id of ids) {
        const entry = await loadEntry(id);
        if (entry?.type === 'person') {
          if (entry.spouseId && !ids.includes(entry.spouseId)) {
            const spouse = await loadEntry(entry.spouseId);
            if (spouse && spouse.type === 'person') {
              const mergedChildren = Array.from(new Set([...spouse.childIds, ...entry.childIds])).filter(cid => !ids.includes(cid) && cid !== id);
              await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '', childIds: mergedChildren });
            }
          }
          for (const p of allPersons) {
            if (!ids.includes(p.id) && p.childIds.includes(id)) await saveEntry({ ...p, childIds: p.childIds.filter(c => c !== id) });
          }
          for (const e of entries) {
            if (e.type === 'company' && !ids.includes(e.id) && e.contactPersonIds.includes(id)) await saveEntry({ ...e, contactPersonIds: e.contactPersonIds.filter(c => c !== id) });
          }
          if (entry.householdId) {
            const household = households.find(h => h.id === entry.householdId);
            if (household) {
              const remainingIds = household.memberIds.filter(mid => !ids.includes(mid));
              if (remainingIds.length <= 1) {
                for (const mid of remainingIds) {
                  const member = await loadEntry(mid);
                  if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
                }
                await removeHousehold(household.id);
              } else {
                let newPrimary = household.primaryContactId;
                if (ids.includes(newPrimary)) newPrimary = remainingIds[0];
                await saveHousehold({ ...household, memberIds: remainingIds, primaryContactId: newPrimary });
              }
            }
          }
        }
        await removeEntry(id);
        if (images[id]) await removeImage(id);
      }
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
      return ids.length;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  }, [allPersons, entries, households, images, reload, setError, setSelectedIds, setSelectMode]);

  const handleBulkStatusChange = useCallback(async (ids: string[], status: 'active' | 'deceased' | 'closed') => {
    try {
      for (const id of ids) {
        const entry = await loadEntry(id);
        if (!entry) continue;
        if (entry.type === 'person') {
          const target = status === 'closed' ? 'active' : status;
          if ((entry.status || 'active') === target) continue;
          await saveEntry({ ...entry, status: target, deceasedDate: target === 'deceased' ? entry.deceasedDate || '' : '' });
        } else {
          const target = status === 'deceased' ? 'active' : (status === 'closed' ? 'closed' : 'active');
          if ((entry.companyStatus || 'active') === target) continue;
          await saveEntry({ ...entry, companyStatus: target, closedDate: target === 'closed' ? entry.closedDate || '' : '' });
        }
      }
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode]);

  const handleBulkAssignHousehold = useCallback(async (personIds: string[], householdId: string) => {
    try {
      const household = await loadHousehold(householdId);
      if (!household) return;
      const householdAddr = { ...household.address, isPrimary: true as const, label: 'Household' };
      const updatedMemberIds = [...household.memberIds];
      for (const pid of personIds) {
        const person = await loadEntry(pid);
        if (!person || person.type !== 'person') continue;
        if (person.householdId && person.householdId !== householdId) {
          const oldHousehold = await loadHousehold(person.householdId);
          if (oldHousehold) {
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== pid);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
              }
              await removeHousehold(oldHousehold.id);
            } else {
              let newPrimary = oldHousehold.primaryContactId;
              if (newPrimary === pid) newPrimary = remainingIds[0];
              await saveHousehold({ ...oldHousehold, memberIds: remainingIds, primaryContactId: newPrimary });
            }
          }
        }
        if (!updatedMemberIds.includes(pid)) updatedMemberIds.push(pid);
        const addrs = [...person.addresses];
        const pIdx = addrs.findIndex(a => a.isPrimary);
        if (pIdx >= 0) addrs[pIdx] = householdAddr; else if (addrs.length > 0) addrs[0] = householdAddr; else addrs.push(householdAddr);
        await saveEntry({ ...person, householdId, addresses: addrs });
      }
      await saveHousehold({ ...household, memberIds: updatedMemberIds });
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode]);

  const handleCreateAndAssignHousehold = useCallback(async (personIds: string[], household: Household) => {
    try {
      const householdAddr = { ...household.address, isPrimary: true as const, label: 'Household' };
      for (const pid of personIds) {
        const person = await loadEntry(pid);
        if (!person || person.type !== 'person') continue;
        if (person.householdId) {
          const oldHousehold = await loadHousehold(person.householdId);
          if (oldHousehold) {
            const remainingIds = oldHousehold.memberIds.filter(mid => mid !== pid);
            if (remainingIds.length <= 1) {
              for (const mid of remainingIds) {
                const member = await loadEntry(mid);
                if (member && member.type === 'person') await saveEntry({ ...member, householdId: '', addresses: member.addresses.map(a => a.label === 'Household' ? { ...a, label: 'Home' } : a) });
              }
              await removeHousehold(oldHousehold.id);
            } else {
              let newPrimary = oldHousehold.primaryContactId;
              if (newPrimary === pid) newPrimary = remainingIds[0];
              await saveHousehold({ ...oldHousehold, memberIds: remainingIds, primaryContactId: newPrimary });
            }
          }
        }
        const addrs = [...person.addresses];
        const pIdx = addrs.findIndex(a => a.isPrimary);
        if (pIdx >= 0) addrs[pIdx] = householdAddr; else if (addrs.length > 0) addrs[0] = householdAddr; else addrs.push(householdAddr);
        await saveEntry({ ...person, householdId: household.id, addresses: addrs });
      }
      await saveHousehold(household);
      setSelectedIds(new Set());
      setSelectMode(false);
      await reload();
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  }, [reload, setError, setSelectedIds, setSelectMode]);

  return { confirmDelete, handleDeleteAll, handleBulkDelete, handleBulkStatusChange, handleBulkAssignHousehold, handleCreateAndAssignHousehold };
}

__EOF_SRC_HOOKS_USEDIRECTORYACTIONS_TS__

cat > "$ROOT/src/hooks/usePersonForm.ts" << '__EOF_SRC_HOOKS_USEPERSONFORM_TS__'
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
  const [pendingPersons, setPendingPersons] = useState<Person[]>([]);

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
    setPendingPersons([]);
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
    setPendingPersons([]);
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
      // Persist any pending quick-added relatives (must happen before spouse sync)
      for (const pending of pendingPersons) {
        await saveEntry(pending);
      }
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person') {
          const needsUpdate = spouse.spouseId !== id || spouse.weddingAnniversary !== pAnniversary || JSON.stringify([...spouse.childIds].sort()) !== JSON.stringify([...pChildIds].sort());
          if (needsUpdate) await saveEntry({ ...spouse, spouseId: id, childIds: pChildIds, weddingAnniversary: pAnniversary });
        }
      }
      if (pImage) await saveImage(id, pImage);
      else if (editId && images[editId]) await removeImage(id);
      const savedName = `${pFirst.trim()} ${pLast.trim()}`;
      await reload(); reset(); setView('list');
      return savedName;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
  };

  const addPendingPerson = (person: Person) => {
    setPendingPersons(prev => [...prev, person]);
  };

  const removePendingPerson = (id: string) => {
    setPendingPersons(prev => prev.filter(p => p.id !== id));
  };

  const updatePendingPerson = (updated: Person) => {
    setPendingPersons(prev => prev.map(p => p.id === updated.id ? updated : p));
  };

  return {
    editId, pFirst, setPFirst, pLast, setPLast, pGender, setPGender,
    pBirthday, setPBirthday, pAnniversary, setPAnniversary,
    pEmails, setPEmails, pPhones, setPPhones, pAddrs, setPAddrs,
    pSpouseId, setPSpouseId, pChildIds, setPChildIds,
    pHouseholdId, setPHouseholdId, pNotes, setPNotes,
    pImage, setPImage, pStatus, setPStatus, pDeceasedDate, setPDeceasedDate,
    fieldErrors, setFieldErrors, duplicates,
    pendingPersons, addPendingPerson, removePendingPerson, updatePendingPerson,
    pFirstRef, pLastRef, pGenderRef, pEmailSectionRef, pPhoneSectionRef, pAddrSectionRef,
    reset, fill, save,
  };
}

__EOF_SRC_HOOKS_USEPERSONFORM_TS__

cat > "$ROOT/src/hooks/useCompanyForm.ts" << '__EOF_SRC_HOOKS_USECOMPANYFORM_TS__'
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
      const savedName = cName.trim();
      await reload(); reset(); setView('list');
      return savedName;
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); return null; }
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

__EOF_SRC_HOOKS_USECOMPANYFORM_TS__

cat > "$ROOT/src/views/DetailView.tsx" << '__EOF_SRC_VIEWS_DETAILVIEW_TSX__'
import React from 'react';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr, calculateAge } from '../utils';
import { ProfileImage } from '../components/ProfileImage';
import { FamilyTree } from '../components/FamilyTree';
import { CollapsibleSection } from '../components/CollapsibleSection';
import { downloadVCard } from '../components/VCardExport';

interface Props {
  entry: DirectoryEntry;
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  collapsedSections: Set<string>;
  toggleSection: (id: string) => void;
  setSelectedId: (id: string) => void;
  setView: (v: any) => void;
  onEdit: () => void;
  onDelete: () => void;
  setError: (msg: string) => void;
  onToast?: (msg: string) => void;
}

export function DetailView({ entry, entries, allPersons, households, images, collapsedSections, toggleSection, setSelectedId, setView, onEdit, onDelete, setError, onToast }: Props) {
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };

  return (
    <>
      <div style={S.btnRow}>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={() => { setView('list'); setSelectedId(''); }}>← Back</button>
        <button style={{ ...S.btn, ...S.btnPrimary }} onClick={onEdit}>Edit</button>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={async () => {
          try { await downloadVCard(entry, images[entry.id]); onToast?.(`📇 ${getEntryName(entry)} vCard exported`); }
          catch (e: any) { if (e?.message && !e.message.includes('declined')) setError(e.message); }
        }}>📇 Export vCard</button>
        <button style={{ ...S.btn, ...S.btnDanger }} onClick={onDelete}>Delete</button>
      </div>

      <div style={{ ...S.card, cursor: 'default', ...((entry.type === 'person' && entry.status === 'deceased') || (entry.type === 'company' && entry.companyStatus === 'closed') ? { borderLeft: '4px solid #9e9e9e' } : {}) }}>
        <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
          <div style={{ marginRight: 14 }}>
            <ProfileImage imageUrl={images[entry.id] || null} size={64} fallback={entry.type === 'person' ? '👤' : '🏢'} />
          </div>
          <div>
            <h2 style={{ margin: 0, ...((entry.type === 'person' && entry.status === 'deceased') || (entry.type === 'company' && entry.companyStatus === 'closed') ? { color: colors.textSec } : {}) }}>{getEntryName(entry)}</h2>
            {entry.type === 'person' && entry.status === 'deceased' && <span style={{ ...S.badge, marginTop: 4, background: '#e0e0e0', color: '#616161' }}>✝ Deceased{entry.deceasedDate ? ` · ${entry.deceasedDate}` : ''}</span>}
            {entry.type === 'company' && entry.companyStatus === 'closed' && <span style={{ ...S.badge, marginTop: 4, background: '#e0e0e0', color: '#616161' }}>🚫 Closed{entry.closedDate ? ` · ${entry.closedDate}` : ''}</span>}
            {entry.type === 'company' && <span style={{ ...S.badge, marginTop: 4, background: '#fce8e6', color: colors.danger }}>company</span>}
            {entry.type === 'company' && entry.industry && <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{entry.industry}</span>}
          </div>
        </div>

        {entry.type === 'company' && entry.website && (
          <CollapsibleSection id="website" title="Website" collapsed={collapsedSections.has('website')} onToggle={() => toggleSection('website')}>
            <div style={{ fontSize: 14 }}><a href={entry.website} target="_blank" rel="noopener noreferrer" style={{ color: colors.primary, textDecoration: 'underline' }}>{entry.website}</a></div>
          </CollapsibleSection>
        )}

        {entry.type === 'person' && (entry.gender || entry.birthday) && (
          <CollapsibleSection id="personal-info" title="Personal Information" collapsed={collapsedSections.has('personal-info')} onToggle={() => toggleSection('personal-info')}>
            {entry.gender && <div style={S.detailRow}><span style={S.detailLabel}>Gender</span><span>{entry.gender}</span></div>}
            {entry.birthday && <div style={S.detailRow}><span style={S.detailLabel}>Birthday</span><span>{entry.birthday}{calculateAge(entry.birthday) !== null && ` (Age ${calculateAge(entry.birthday)})`}</span></div>}
          </CollapsibleSection>
        )}

        <CollapsibleSection id="emails" title="Email Addresses" collapsed={collapsedSections.has('emails')} onToggle={() => toggleSection('emails')}>
          {entry.emails.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.emails.map((em, i) => (
              <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{em.label}</span>
                <span>{em.address}</span>
                {em.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
              </div>
            ))}
        </CollapsibleSection>

        <CollapsibleSection id="phones" title="Phone Numbers" collapsed={collapsedSections.has('phones')} onToggle={() => toggleSection('phones')}>
          {entry.phones.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.phones.map((ph, i) => (
              <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{ph.label}</span>
                <span>{ph.countryCode || '+1'} {formatPhoneDisplay(ph.number)}</span>
                {ph.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
              </div>
            ))}
        </CollapsibleSection>

        <CollapsibleSection id="addresses" title="Addresses" collapsed={collapsedSections.has('addresses')} onToggle={() => toggleSection('addresses')}>
          {entry.addresses.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
            entry.addresses.map((addr, i) => (
              <div key={i} style={{ padding: '8px 12px', marginBottom: 6, borderRadius: 6, border: `1px solid ${colors.border}`, background: addr.isPrimary ? '#f0f7ff' : '#fff' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                  <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{addr.label}</span>
                  {addr.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                </div>
                <div style={{ fontSize: 14 }}>{formatAddr(addr)}</div>
              </div>
            ))}
        </CollapsibleSection>

        {entry.type === 'person' && (
          <>
            <CollapsibleSection id="relationships" title="Relationships" collapsed={collapsedSections.has('relationships')} onToggle={() => toggleSection('relationships')}>
              <div style={S.detailRow}><span style={S.detailLabel}>Spouse</span><span>{entry.spouseId ? <span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(entry.spouseId)}>{resolveName(entry.spouseId)}</span> : '—'}</span></div>
              {entry.weddingAnniversary && <div style={S.detailRow}><span style={S.detailLabel}>Anniversary</span><span>💍 {entry.weddingAnniversary}</span></div>}
              <div style={S.detailRow}><span style={S.detailLabel}>Children</span><span style={{ display: 'flex', flexWrap: 'wrap' }}>{entry.childIds.length === 0 ? '—' : entry.childIds.map(cid => <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>{resolveName(cid)}</span>)}</span></div>
            </CollapsibleSection>
            <CollapsibleSection id="family-tree" title="Family Tree" collapsed={collapsedSections.has('family-tree')} onToggle={() => toggleSection('family-tree')}>
              <FamilyTree person={entry} allPersons={allPersons} images={images} onSelectPerson={id => setSelectedId(id)} />
            </CollapsibleSection>
            {(() => {
              const household = households.find(h => h.memberIds.includes(entry.id));
              return (
                <CollapsibleSection id="household" title="Household" collapsed={collapsedSections.has('household')} onToggle={() => toggleSection('household')}>
                  {household ? (
                    <>
                      <div style={S.detailRow}><span style={S.detailLabel}>Household</span><span>🏠 {household.name}</span></div>
                      <div style={S.detailRow}><span style={S.detailLabel}>Members</span><span style={{ display: 'flex', flexWrap: 'wrap' }}>
                        {household.memberIds.filter(mid => mid !== entry.id).map(mid => (
                          <span key={mid} style={{ ...S.chip, cursor: 'pointer', background: mid === household.primaryContactId ? '#c6f0c2' : colors.accent }} onClick={() => setSelectedId(mid)}>
                            {resolveName(mid)}{mid === household.primaryContactId && <span style={{ fontSize: 10, color: '#1b7a15', marginLeft: 2 }}>★ Primary</span>}
                          </span>
                        ))}
                        {household.memberIds.filter(mid => mid !== entry.id).length === 0 && '—'}
                      </span></div>
                    </>
                  ) : <div style={{ fontSize: 14, color: colors.textSec }}>Not assigned to any household.</div>}
                </CollapsibleSection>
              );
            })()}
          </>
        )}

        {entry.type === 'company' && (
          <CollapsibleSection id="contact-persons" title="Contact Persons" collapsed={collapsedSections.has('contact-persons')} onToggle={() => toggleSection('contact-persons')}>
            {entry.contactPersonIds.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
              <div style={{ display: 'flex', flexWrap: 'wrap' }}>{entry.contactPersonIds.map(pid => <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>{resolveName(pid)}</span>)}</div>}
          </CollapsibleSection>
        )}

        {entry.notes && (
          <CollapsibleSection id="notes" title="Notes" collapsed={collapsedSections.has('notes')} onToggle={() => toggleSection('notes')}>
            <div style={{ fontSize: 14, whiteSpace: 'pre-wrap' }}>{entry.notes}</div>
          </CollapsibleSection>
        )}
      </div>
    </>
  );
}

__EOF_SRC_VIEWS_DETAILVIEW_TSX__

cat > "$ROOT/src/views/ImportView.tsx" << '__EOF_SRC_VIEWS_IMPORTVIEW_TSX__'
import React from 'react';
import type { DirectoryEntry, Household } from '../types';
import { S, colors } from '../styles';
import { formatPhoneDisplay, getPrimary, getEntryName, formatAddr } from '../utils';

interface Props {
  importPreview: DirectoryEntry[];
  importHouseholdsPreview: Household[];
  importFileName: string;
  importing: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ImportView({ importPreview, importHouseholdsPreview, importFileName, importing, onConfirm, onCancel }: Props) {
  const total = importPreview.length + importHouseholdsPreview.length;
  return (
    <>
      <h2 style={{ marginBottom: 8 }}>📤 Import Preview</h2>
      <p style={{ fontSize: 13, color: colors.textSec, marginBottom: 16 }}>
        File: <strong>{importFileName}</strong> — {importPreview.length} entr{importPreview.length === 1 ? 'y' : 'ies'}
        {importHouseholdsPreview.length > 0 && ` and ${importHouseholdsPreview.length} household${importHouseholdsPreview.length === 1 ? '' : 's'}`} found.
      </p>
      {total === 0 ? <div style={S.emptyState}>No valid records found in the CSV file.</div> : (
        <>
          {importPreview.length > 0 && (
            <div style={{ overflowX: 'auto', marginBottom: 16 }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13, background: colors.card, borderRadius: 8, overflow: 'hidden' }}>
                <thead><tr style={{ background: colors.accent }}>
                  {['#', 'Type', 'Name', 'Primary Email', 'Primary Phone', 'City/State'].map(h => (
                    <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                  ))}
                </tr></thead>
                <tbody>
                  {importPreview.map((e, i) => (
                    <tr key={i} style={{ borderBottom: `1px solid ${colors.border}` }}>
                      <td style={{ padding: '8px 12px', color: colors.textSec }}>{i + 1}</td>
                      <td style={{ padding: '8px 12px' }}><span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>{e.type === 'person' ? '👤' : '🏢'}</span></td>
                      <td style={{ padding: '8px 12px', fontWeight: 600 }}>{getEntryName(e)}</td>
                      <td style={{ padding: '8px 12px' }}>{getPrimary(e.emails)?.address || '—'}</td>
                      <td style={{ padding: '8px 12px' }}>{getPrimary(e.phones)?.number ? formatPhoneDisplay(getPrimary(e.phones)!.number) : '—'}</td>
                      <td style={{ padding: '8px 12px' }}>{(() => { const a = getPrimary(e.addresses); return a ? [a.city, a.state].filter(Boolean).join(', ') || '—' : '—'; })()}</td>
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
                <thead><tr style={{ background: colors.accent }}>
                  {['#', 'Name', 'Address', 'Members'].map(h => (
                    <th key={h} style={{ padding: '10px 12px', textAlign: 'left', fontWeight: 700, borderBottom: `2px solid ${colors.border}` }}>{h}</th>
                  ))}
                </tr></thead>
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
        <button style={{ ...S.btn, ...S.btnPrimary }} onClick={onConfirm} disabled={importing || total === 0}>
          {importing ? 'Importing...' : `✅ Import ${total} Record${total === 1 ? '' : 's'}`}
        </button>
        <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel} disabled={importing}>Cancel</button>
      </div>
    </>
  );
}

__EOF_SRC_VIEWS_IMPORTVIEW_TSX__

cat > "$ROOT/src/components/AddressFields.tsx" << '__EOF_SRC_COMPONENTS_ADDRESSFIELDS_TSX__'
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
        <div style={S.fieldFull}>
          <label style={S.label}>Address Line 2 <span style={{ fontWeight: 400, color: colors.textSec }}>(optional)</span></label>
          <input style={S.input} value={addr.street2 || ''} placeholder="Apt, Suite, Floor, etc."
            disabled={readOnly}
            onChange={e => onChange({ ...addr, street2: e.target.value })} />
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

  const add = () => onChange([...addresses, { street: '', street2: '', city: '', state: '', zip: '', country: 'United States', isPrimary: false, label: companyMode ? 'Main' : addresses.length === 0 ? 'Home' : 'Work' }]);
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

export function RelationshipPicker({ label, entries, selectedIds, pendingIds, onToggle, onEditPending }: {
  label: string; entries: Person[]; selectedIds: string[]; pendingIds?: Set<string>; onToggle: (id: string) => void; onEditPending?: (id: string) => void;
}) {
  const [q, setQ] = useState('');
  const filtered = entries.filter(p => !selectedIds.includes(p.id) &&
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase()));
  const selected = entries.filter(p => selectedIds.includes(p.id));
  return (
    <div style={S.fieldFull}>
      <label style={S.label}>{label}</label>
      <div style={{ display: 'flex', flexWrap: 'wrap', marginBottom: 6 }}>
        {selected.map(p => {
          const isPending = pendingIds?.has(p.id);
          return (
            <span key={p.id} style={{ ...S.chip, ...(isPending ? { background: '#fff8e1', border: '1px solid #ffc107', cursor: 'pointer' } : {}) }}
              onClick={isPending && onEditPending ? () => onEditPending(p.id) : undefined}
              title={isPending ? 'Click to edit' : undefined}>
              {isPending && <span style={{ fontSize: 11, fontWeight: 700, color: '#f57f17' }}>✨ new</span>}
              {p.firstName} {p.lastName}
              <button style={S.chipRemove} onClick={e => { e.stopPropagation(); onToggle(p.id); }}>×</button>
            </span>
          );
        })}
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
  pendingIds?: Set<string>;
  editId: string | null;
  selectedSpouseId: string;
  childIds: string[];
  currentGender: string;
  onSelect: (id: string) => void;
  onClear: () => void;
  onEditPending?: (id: string) => void;
}

export function SpousePicker({ allPersons, pendingIds, editId, selectedSpouseId, childIds, currentGender, onSelect, onClear, onEditPending }: SpousePickerProps) {
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
    // Only show persons of the opposite gender
    if (currentGender && p.gender) {
      if (currentGender === p.gender) return false;
    }
    return true;
  });

  const filtered = eligible.filter(p =>
    `${p.firstName} ${p.lastName}`.toLowerCase().includes(q.toLowerCase())
  );

  if (spouse) {
    const isPending = pendingIds?.has(spouse.id);
    return (
      <div style={S.fieldFull}>
        <label style={S.label}>Spouse</label>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ ...S.chip, ...(isPending ? { background: '#fff8e1', border: '1px solid #ffc107', cursor: 'pointer' } : {}) }}
            onClick={isPending && onEditPending ? () => onEditPending(spouse.id) : undefined}
            title={isPending ? 'Click to edit' : undefined}>
            {isPending && <span style={{ fontSize: 11, fontWeight: 700, color: '#f57f17' }}>✨ new</span>}
            {spouse.firstName} {spouse.lastName}
            <button style={S.chipRemove} onClick={e => { e.stopPropagation(); onClear(); }}>×</button>
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
import React, { useState, useRef, useEffect, useCallback } from 'react';
import { v4 as uuidv4 } from 'uuid';
import { PageStorageError } from '@amzn/quick-pages-runtime-lib';
import type { Person, Household, Address, AddressSuggestion } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, formatAddr, suggestAddresses, useDebounce } from '../utils';
import { saveEntry, loadEntry, saveHousehold, removeHousehold, saveImage, removeImage } from '../storage';
import { COUNTRIES } from '../countryCodes';
import { ProfileImage } from './ProfileImage';

interface HouseholdViewProps {
  households: Household[];
  allPersons: Person[];
  images: Record<string, string>;
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
        <div style={S.fieldFull}>
          <label style={S.label}>Address Line 2 <span style={{ fontWeight: 400, color: colors.textSec }}>(optional)</span></label>
          <input style={S.input} value={address.street2 || ''} placeholder="Apt, Suite, Floor, etc."
            onChange={e => setAddress({ ...address, street2: e.target.value })} />
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

export function HouseholdView({ households, allPersons, images, onReload }: HouseholdViewProps) {
  const [editing, setEditing] = useState<Household | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Set<string>>(new Set());

  // Pagination
  const [pageSize, setPageSize] = useState(25);
  const [currentPage, setCurrentPage] = useState(1);

  // Form state
  const [name, setName] = useState('');
  const [address, setAddress] = useState<Address>({ ...EMPTY_ADDR, label: 'Household' });
  const [memberIds, setMemberIds] = useState<string[]>([]);
  const [primaryContactId, setPrimaryContactId] = useState('');
  const [hhImage, setHhImage] = useState<string | null>(null);

  // Refs for auto-focus and scroll
  const nameRef = useRef<HTMLInputElement>(null);
  const primaryRef = useRef<HTMLSelectElement>(null);
  const addressSectionRef = useRef<HTMLDivElement>(null);
  const membersSectionRef = useRef<HTMLDivElement>(null);

  const scrollToAndFocus = useCallback((ref: React.RefObject<HTMLElement | null>) => {
    setTimeout(() => {
      ref.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
      if (ref.current && 'focus' in ref.current) (ref.current as HTMLElement).focus();
    }, 50);
  }, []);

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
    setMemberIds([]); setPrimaryContactId(''); setHhImage(null); setEditing(null); setShowForm(false); setError(''); setFieldErrors(new Set());
  };

  const openCreate = () => { resetForm(); setShowForm(true); };

  const openEdit = (h: Household) => {
    setEditing(h);
    setName(h.name);
    setAddress({ ...h.address });
    setMemberIds([...h.memberIds]);
    setPrimaryContactId(h.primaryContactId);
    setHhImage(images[h.id] || null);
    setShowForm(true);
    setError('');
  };

  const handleSave = async () => {
    const errs = new Set<string>();
    if (!name.trim()) errs.add('hhName');
    if (!address.street.trim() && !address.city.trim()) errs.add('hhAddress');
    if (memberIds.length < 2) errs.add('hhMembers');
    if (!primaryContactId) errs.add('hhPrimary');
    if (primaryContactId && !memberIds.includes(primaryContactId)) errs.add('hhPrimary');

    if (errs.size > 0) {
      setFieldErrors(errs);
      setError('');
      // Scroll to and focus first invalid field
      if (errs.has('hhName')) { scrollToAndFocus(nameRef); return; }
      if (errs.has('hhAddress')) { scrollToAndFocus(addressSectionRef); return; }
      if (errs.has('hhMembers')) { scrollToAndFocus(membersSectionRef); return; }
      if (errs.has('hhPrimary')) { scrollToAndFocus(primaryRef); return; }
      return;
    }
    setFieldErrors(new Set());

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
      // Save or remove household image
      if (hhImage) await saveImage(id, hhImage);
      else if (editing && images[editing.id]) await removeImage(id);
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
      if (images[household.id]) await removeImage(household.id);
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

  // Pagination computed values
  const totalHouseholds = households.length;
  const totalPages = Math.max(1, Math.ceil(totalHouseholds / pageSize));
  const safeCurrentPage = Math.min(currentPage, totalPages);
  const pageStart = (safeCurrentPage - 1) * pageSize;
  const pageEnd = Math.min(pageStart + pageSize, totalHouseholds);
  const paginatedHouseholds = households.slice(pageStart, pageEnd);

  return (
    <>
      {error && <div style={{ fontSize: 13, color: colors.danger, marginBottom: 14 }}>{error}</div>}

      {!showForm ? (
        <>
          <div style={S.btnRow}>
            <button style={{ ...S.btn, ...S.btnPrimary }} onClick={openCreate}>+ Create Household</button>
          </div>

          {households.length === 0 ? (
            <div style={S.emptyState}>No households yet. Create one to get started.</div>
          ) : (
            <>
              {/* Pagination info & page size selector */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, fontSize: 13, color: colors.textSec }}>
                <span>Showing {pageStart + 1}–{pageEnd} of {totalHouseholds} household{totalHouseholds === 1 ? '' : 's'}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span>Per page:</span>
                  {[25, 50, 100].map(size => (
                    <button key={size} onClick={() => { setPageSize(size); setCurrentPage(1); }} style={{
                      ...S.btn, padding: '3px 10px', fontSize: 12,
                      background: pageSize === size ? colors.primary : 'transparent',
                      color: pageSize === size ? '#fff' : colors.text,
                      border: `1px solid ${pageSize === size ? colors.primary : colors.border}`,
                      borderRadius: 4,
                    }}>{size}</button>
                  ))}
                </div>
              </div>

              {paginatedHouseholds.map(h => (
              <div key={h.id} style={{ ...S.card, cursor: 'default' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <ProfileImage imageUrl={images[h.id] || null} size={36} fallback="🏠" />
                    <div>
                      <strong style={{ fontSize: 16 }}>{h.name}</strong>
                      <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>
                        📍 {formatAddr(h.address)}
                      </div>
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
              ))}

              {/* Pagination navigation */}
              {totalPages > 1 && (
                <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6, marginTop: 16 }}>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(1)}>«</button>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage <= 1} onClick={() => setCurrentPage(p => Math.max(1, p - 1))}>‹</button>
                  <span style={{ fontSize: 13, color: colors.textSec, margin: '0 8px' }}>
                    Page {safeCurrentPage} of {totalPages}
                  </span>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}>›</button>
                  <button style={{ ...S.btn, ...S.btnSec, padding: '6px 12px', fontSize: 13 }}
                    disabled={safeCurrentPage >= totalPages} onClick={() => setCurrentPage(totalPages)}>»</button>
                </div>
              )}
            </>
          )}
        </>
      ) : (
        <>
          <h2 style={{ marginBottom: 16 }}>{editing ? `Edit Household: ${editing.name}` : 'Create Household'}</h2>

          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 16 }}>
            <ProfileImage imageUrl={hhImage} size={72} fallback="🏠" editable onImageChange={setHhImage} />
            <span style={{ fontSize: 13, color: colors.textSec }}>Click to upload a household photo</span>
          </div>

          <div style={S.formGrid}>
            <div style={S.fieldFull}>
              <label style={S.label}>Household Name *</label>
              <input ref={nameRef} style={{ ...S.input, ...(fieldErrors.has('hhName') ? { borderColor: colors.danger } : {}) }} value={name} onChange={e => { setName(e.target.value); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhName'); return n; }); }} placeholder="e.g. The Smith Family" />
              {fieldErrors.has('hhName') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Household name is required</div>}
            </div>
          </div>

          <div ref={addressSectionRef}>
          <HouseholdAddressSection address={address} setAddress={a => { setAddress(a); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhAddress'); return n; }); }} />
          {fieldErrors.has('hhAddress') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3, marginBottom: 8 }}>At least a street or city is required</div>}
          </div>

          <div ref={membersSectionRef}>
          <div style={S.section}>Members{memberIds.length < 2 ? ' *' : ''}</div>
          <span style={{ fontSize: 12, color: colors.textSec, display: 'block', marginBottom: 8 }}>
            A household must have at least two members. One must be designated as primary contact.
          </span>
          {fieldErrors.has('hhMembers') && <div style={{ fontSize: 12, color: colors.danger, marginBottom: 8 }}>At least two members are required</div>}

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
                    setFieldErrors(prev => {
                      const n = new Set(prev);
                      if (newMembers.length < 2) n.add('hhMembers');
                      else n.delete('hhMembers');
                      // If a valid primary is auto-assigned (or was already valid), clear hhPrimary
                      const effectivePrimary = primaryContactId === mid ? newMembers[0] || '' : primaryContactId;
                      if (effectivePrimary && newMembers.includes(effectivePrimary)) n.delete('hhPrimary');
                      else if (!effectivePrimary) n.add('hhPrimary');
                      return n;
                    });
                  }}>×</button>
                </span>
              ))}
            </div>
          )}

          {memberIds.length > 0 && (
            <div style={{ marginBottom: 12 }}>
              <label style={S.label}>Primary Contact *</label>
              <select ref={primaryRef} style={{ ...S.input, ...(fieldErrors.has('hhPrimary') ? { borderColor: colors.danger } : {}) }} value={primaryContactId} onChange={e => { setPrimaryContactId(e.target.value); setFieldErrors(prev => { const n = new Set(prev); n.delete('hhPrimary'); return n; }); }}>
                <option value="">— Select primary contact —</option>
                {memberIds.map(mid => (
                  <option key={mid} value={mid}>{resolveName(mid)}</option>
                ))}
              </select>
              {fieldErrors.has('hhPrimary') && <div style={{ fontSize: 12, color: colors.danger, marginTop: 3 }}>Primary contact is required</div>}
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
                      const newMembers = [...memberIds, p.id];
                      setMemberIds(newMembers);
                      if (!primaryContactId) setPrimaryContactId(p.id);
                      setMemberQ(''); setMemberDropdownOpen(false);
                      setFieldErrors(prev => {
                        const n = new Set(prev);
                        if (newMembers.length >= 2) n.delete('hhMembers');
                        n.delete('hhPrimary');
                        return n;
                      });
                    }}>
                    {p.firstName} {p.lastName}
                  </div>
                ))}
              </div>
            )}
          </div>
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

cat > "$ROOT/src/components/FilterBar.tsx" << '__EOF_SRC_COMPONENTS_FILTERBAR_TSX__'
import React, { useState } from 'react';
import type { SortField, SortDir, TypeFilter, StatusFilter } from '../types';
import { colors } from '../styles';

interface FilterBarProps {
  sortField: SortField;
  setSortField: (v: SortField) => void;
  sortDir: SortDir;
  setSortDir: (v: SortDir) => void;
  typeFilter: TypeFilter;
  setTypeFilter: (v: TypeFilter) => void;
  industryFilter: string;
  setIndustryFilter: (v: string) => void;
  allIndustries: string[];
  statusFilter: StatusFilter;
  setStatusFilter: (v: StatusFilter) => void;
  totalCount: number;
}

type StatusOption = { value: StatusFilter; label: string };

function getStatusOptions(typeFilter: TypeFilter): StatusOption[] {
  if (typeFilter === 'person') {
    return [
      { value: 'active', label: '● Active' },
      { value: 'deceased', label: '✝ Deceased' },
      { value: 'all', label: '○ All' },
    ];
  }
  if (typeFilter === 'company') {
    return [
      { value: 'active', label: '● Active' },
      { value: 'closed', label: '🚫 Closed' },
      { value: 'all', label: '○ All' },
    ];
  }
  // 'all' type — show everything
  return [
    { value: 'active', label: '● Active' },
    { value: 'deceased', label: '✝ Deceased' },
    { value: 'closed', label: '🚫 Closed' },
    { value: 'all', label: '○ All' },
  ];
}

function getStatusChipLabel(statusFilter: StatusFilter): string {
  if (statusFilter === 'deceased') return '✝ Deceased';
  if (statusFilter === 'closed') return '🚫 Closed';
  if (statusFilter === 'all') return '○ All statuses';
  return '● Active';
}

export function FilterBar({
  sortField, setSortField, sortDir, setSortDir,
  typeFilter, setTypeFilter, industryFilter, setIndustryFilter,
  allIndustries, statusFilter, setStatusFilter, totalCount
}: FilterBarProps) {
  const [expanded, setExpanded] = useState(false);

  const hasActiveFilters = typeFilter !== 'all' || industryFilter !== '' || statusFilter !== 'active';
  const activeFilterCount = (typeFilter !== 'all' ? 1 : 0) + (industryFilter ? 1 : 0) + (statusFilter !== 'active' ? 1 : 0);

  const clearAll = () => {
    setTypeFilter('all');
    setIndustryFilter('');
    setStatusFilter('active');
  };

  const statusOptions = getStatusOptions(typeFilter);

  // If current status filter is not valid for the selected type, reset it
  const validValues = statusOptions.map(o => o.value);
  if (!validValues.includes(statusFilter)) {
    // Don't call setState in render — use effect-like approach
    setTimeout(() => setStatusFilter('active'), 0);
  }

  const chipStyle: React.CSSProperties = {
    display: 'inline-flex', alignItems: 'center', gap: 4,
    background: colors.accent, borderRadius: 14, padding: '3px 10px',
    fontSize: 12, fontWeight: 600, color: colors.primary,
  };
  const chipRemoveStyle: React.CSSProperties = {
    border: 'none', background: 'none', cursor: 'pointer',
    color: colors.textSec, fontWeight: 700, fontSize: 14, lineHeight: 1, padding: '0 0 0 2px',
  };

  return (
    <div style={{
      marginBottom: 16, borderRadius: 10, background: colors.card,
      border: `1px solid ${colors.border}`, overflow: 'hidden',
    }}>
      {/* Summary row — always visible */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, padding: '10px 16px',
        flexWrap: 'wrap',
      }}>
        {/* Sort control */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 12, color: colors.textSec, fontWeight: 600 }}>Sort:</span>
          <select style={{
            padding: '4px 8px', borderRadius: 5, border: `1px solid ${colors.border}`,
            fontSize: 12, outline: 'none', background: '#fff', cursor: 'pointer',
          }} value={sortField} onChange={e => setSortField(e.target.value as SortField)}>
            <option value="name">Name</option>
            <option value="type">Type</option>
            <option value="dateAdded">Date Added</option>
          </select>
          <button onClick={() => setSortDir(sortDir === 'asc' ? 'desc' : 'asc')}
            title={sortDir === 'asc' ? 'Ascending' : 'Descending'}
            style={{
              border: `1px solid ${colors.border}`, borderRadius: 5, background: '#fff',
              cursor: 'pointer', padding: '3px 7px', fontSize: 13, lineHeight: 1,
            }}>
            {sortDir === 'asc' ? '↑' : '↓'}
          </button>
        </div>

        <div style={{ width: 1, height: 20, background: colors.border }} />

        {/* Filter toggle button */}
        <button onClick={() => setExpanded(!expanded)} style={{
          display: 'flex', alignItems: 'center', gap: 5,
          border: `1px solid ${hasActiveFilters ? colors.primary : colors.border}`,
          borderRadius: 6, background: hasActiveFilters ? '#e8f0fe' : '#fff',
          cursor: 'pointer', padding: '5px 12px', fontSize: 12, fontWeight: 600,
          color: hasActiveFilters ? colors.primary : colors.text,
        }}>
          <span>🔽</span>
          Filters{activeFilterCount > 0 && ` (${activeFilterCount})`}
        </button>

        {/* Active filter chips */}
        {hasActiveFilters && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            {typeFilter !== 'all' && (
              <span style={chipStyle}>
                {typeFilter === 'person' ? '👤 Persons' : '🏢 Companies'}
                <button style={chipRemoveStyle} onClick={() => { setTypeFilter('all'); setIndustryFilter(''); }}>×</button>
              </span>
            )}
            {statusFilter !== 'active' && (
              <span style={chipStyle}>
                {getStatusChipLabel(statusFilter)}
                <button style={chipRemoveStyle} onClick={() => setStatusFilter('active')}>×</button>
              </span>
            )}
            {industryFilter && (
              <span style={chipStyle}>
                🏷 {industryFilter}
                <button style={chipRemoveStyle} onClick={() => setIndustryFilter('')}>×</button>
              </span>
            )}
            <button onClick={clearAll} style={{
              border: 'none', background: 'none', cursor: 'pointer',
              fontSize: 11, color: colors.danger, fontWeight: 600, textDecoration: 'underline', padding: '2px 4px',
            }}>Clear all</button>
          </div>
        )}

        {/* Result count */}
        <span style={{ marginLeft: 'auto', fontSize: 12, color: colors.textSec }}>
          {totalCount} result{totalCount !== 1 ? 's' : ''}
        </span>
      </div>

      {/* Expanded filter panel */}
      {expanded && (
        <div style={{
          borderTop: `1px solid ${colors.border}`, padding: '14px 16px',
          background: '#fafbfc', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: 16,
        }}>
          {/* Type filter */}
          <div>
            <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
              Entry Type
            </label>
            <div style={{ display: 'flex', gap: 4 }}>
              {(['all', 'person', 'company'] as TypeFilter[]).map(t => (
                <button key={t} onClick={() => { setTypeFilter(t); if (t !== 'company') setIndustryFilter(''); }}
                  style={{
                    flex: 1, padding: '6px 8px', fontSize: 12, fontWeight: 600,
                    border: `1px solid ${typeFilter === t ? colors.primary : colors.border}`,
                    borderRadius: 6, cursor: 'pointer',
                    background: typeFilter === t ? colors.primary : '#fff',
                    color: typeFilter === t ? '#fff' : colors.text,
                  }}>
                  {t === 'all' ? 'All' : t === 'person' ? '👤 Person' : '🏢 Company'}
                </button>
              ))}
            </div>
          </div>

          {/* Status filter — context-sensitive */}
          <div>
            <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
              Status
            </label>
            <div style={{ display: 'flex', gap: 4 }}>
              {statusOptions.map(opt => (
                <button key={opt.value} onClick={() => setStatusFilter(opt.value)}
                  style={{
                    flex: 1, padding: '6px 6px', fontSize: 11, fontWeight: 600,
                    border: `1px solid ${statusFilter === opt.value ? (opt.value === 'deceased' || opt.value === 'closed' ? '#5f6368' : colors.primary) : colors.border}`,
                    borderRadius: 6, cursor: 'pointer',
                    background: statusFilter === opt.value ? (opt.value === 'deceased' || opt.value === 'closed' ? '#5f6368' : colors.primary) : '#fff',
                    color: statusFilter === opt.value ? '#fff' : colors.text,
                  }}>
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Industry filter */}
          {allIndustries.length > 0 && (typeFilter === 'all' || typeFilter === 'company') && (
            <div>
              <label style={{ fontSize: 11, fontWeight: 700, color: colors.textSec, marginBottom: 6, display: 'block', textTransform: 'uppercase', letterSpacing: 0.5 }}>
                Industry
              </label>
              <select value={industryFilter}
                onChange={e => { setIndustryFilter(e.target.value); if (e.target.value) setTypeFilter('company'); }}
                style={{
                  width: '100%', padding: '6px 10px', borderRadius: 6,
                  border: `1px solid ${colors.border}`, fontSize: 12, outline: 'none',
                  background: '#fff', cursor: 'pointer',
                }}>
                <option value="">All Industries</option>
                {allIndustries.map(ind => <option key={ind} value={ind}>{ind}</option>)}
              </select>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

__EOF_SRC_COMPONENTS_FILTERBAR_TSX__

cat > "$ROOT/src/components/EmailInput.tsx" << '__EOF_SRC_COMPONENTS_EMAILINPUT_TSX__'
import React, { useState } from 'react';
import { S, colors } from '../styles';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function EmailInput({ value, placeholder, onChange }: {
  value: string; placeholder: string; onChange: (val: string) => void;
}) {
  const [error, setError] = useState('');

  const validate = (v: string) => {
    if (v.trim() && !EMAIL_REGEX.test(v.trim())) {
      setError('Please enter a valid email address');
    } else {
      setError('');
    }
  };

  return (
    <div>
      <input
        style={{ ...S.input, ...(error ? { borderColor: colors.danger } : {}) }}
        type="email"
        placeholder={placeholder}
        value={value}
        onChange={e => { onChange(e.target.value); if (error) setError(''); }}
        onBlur={() => validate(value)}
      />
      {error && <div style={{ fontSize: 12, color: colors.danger, marginTop: 2 }}>{error}</div>}
    </div>
  );
}

__EOF_SRC_COMPONENTS_EMAILINPUT_TSX__

cat > "$ROOT/src/components/PhoneInput.tsx" << '__EOF_SRC_COMPONENTS_PHONEINPUT_TSX__'
import React, { useState } from 'react';
import { S, colors } from '../styles';
import { CountryCodeSelect } from './CountryCodeSelect';

// Valid characters: digits, spaces, dashes, parens, dots, plus
const PHONE_CHARS_REGEX = /^[0-9\s\-().+]+$/;

function countDigits(v: string): number {
  return (v.match(/\d/g) || []).length;
}

/**
 * Format a phone number based on the country code.
 * Extracts only digits, then applies a country-specific pattern.
 */
function formatForCountry(raw: string, code: string): string {
  const digits = raw.replace(/[^\d]/g, '');
  if (!digits) return '';

  switch (code) {
    case '+1': {
      // NANP: US/Canada — (XXX) XXX-XXXX
      const d = digits.length === 11 && digits.startsWith('1') ? digits.slice(1) : digits;
      if (d.length === 10) return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
      return raw;
    }
    case '+44': {
      // UK: 0XXXX XXXXXX or XXXXX XXXXXX (10-11 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 4)} ${d.slice(4, 7)} ${d.slice(7)}`;
      if (d.length === 9) return `${d.slice(0, 3)} ${d.slice(3, 6)} ${d.slice(6)}`;
      return raw;
    }
    case '+61': {
      // Australia: XXXX XXX XXX (9 digits without leading 0)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 9) return `${d.slice(0, 4)} ${d.slice(4, 7)} ${d.slice(7)}`;
      return raw;
    }
    case '+49': {
      // Germany: variable length, group as XXXX XXXXXXX
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length >= 10 && d.length <= 11) return `${d.slice(0, 4)} ${d.slice(4)}`;
      return raw;
    }
    case '+33': {
      // France: XX XX XX XX XX (9 digits without leading 0)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 9) return `${d.slice(0, 1)} ${d.slice(1, 3)} ${d.slice(3, 5)} ${d.slice(5, 7)} ${d.slice(7)}`;
      return raw;
    }
    case '+91': {
      // India: XXXXX XXXXX (10 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 5)} ${d.slice(5)}`;
      return raw;
    }
    case '+81': {
      // Japan: XX-XXXX-XXXX (10-11 digits)
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 10) return `${d.slice(0, 2)}-${d.slice(2, 6)}-${d.slice(6)}`;
      if (d.length === 9) return `${d.slice(0, 1)}-${d.slice(1, 5)}-${d.slice(5)}`;
      return raw;
    }
    case '+86': {
      // China: XXX XXXX XXXX (11 digits)
      if (digits.length === 11) return `${digits.slice(0, 3)} ${digits.slice(3, 7)} ${digits.slice(7)}`;
      return raw;
    }
    case '+55': {
      // Brazil: (XX) XXXXX-XXXX or (XX) XXXX-XXXX
      const d = digits.startsWith('0') ? digits.slice(1) : digits;
      if (d.length === 11) return `(${d.slice(0, 2)}) ${d.slice(2, 7)}-${d.slice(7)}`;
      if (d.length === 10) return `(${d.slice(0, 2)}) ${d.slice(2, 6)}-${d.slice(6)}`;
      return raw;
    }
    case '+52': {
      // Mexico: XXX XXX XXXX (10 digits)
      if (digits.length === 10) return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
      return raw;
    }
    default: {
      // Generic: group in blocks of 3-4 digits
      if (digits.length >= 7 && digits.length <= 8) return `${digits.slice(0, 4)} ${digits.slice(4)}`;
      if (digits.length >= 9 && digits.length <= 10) return `${digits.slice(0, 3)} ${digits.slice(3, 6)} ${digits.slice(6)}`;
      if (digits.length >= 11) return `${digits.slice(0, 3)} ${digits.slice(3, 7)} ${digits.slice(7)}`;
      return raw;
    }
  }
}

export function PhoneInput({ value, countryCode, placeholder, onChange, onCodeChange }: {
  value: string; countryCode: string; placeholder: string;
  onChange: (val: string) => void; onCodeChange: (code: string) => void;
}) {
  const [error, setError] = useState('');

  const handleBlur = () => {
    const trimmed = value.trim();
    if (!trimmed) { setError(''); return; }
    if (!PHONE_CHARS_REGEX.test(trimmed)) {
      setError('Please enter a valid phone number');
      return;
    }
    if (countDigits(trimmed) < 7) {
      setError('Please enter a valid phone number');
      return;
    }
    setError('');
    // Format the valid number
    const formatted = formatForCountry(trimmed, countryCode);
    if (formatted !== value) onChange(formatted);
  };

  return (
    <div>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        <CountryCodeSelect value={countryCode} onChange={onCodeChange} />
        <input
          style={{ ...S.input, flex: 1, ...(error ? { borderColor: colors.danger } : {}) }}
          type="tel"
          placeholder={placeholder}
          value={value}
          onChange={e => { onChange(e.target.value); if (error) setError(''); }}
          onBlur={handleBlur}
        />
      </div>
      {error && <div style={{ fontSize: 12, color: colors.danger, marginTop: 2 }}>{error}</div>}
    </div>
  );
}

__EOF_SRC_COMPONENTS_PHONEINPUT_TSX__

cat > "$ROOT/src/components/ProfileImage.tsx" << '__EOF_SRC_COMPONENTS_PROFILEIMAGE_TSX__'
import React, { useRef, useState } from 'react';
import { colors } from '../styles';
import { ImageCropper } from './ImageCropper';

interface ProfileImageProps {
  imageUrl: string | null;
  size?: number;
  fallback: string; // emoji fallback like 👤 or 🏢 or 🏠
  editable?: boolean;
  onImageChange?: (dataUrl: string | null) => void;
}

function loadFileAsDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsDataURL(file);
  });
}

export function ProfileImage({ imageUrl, size = 40, fallback, editable = false, onImageChange }: ProfileImageProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [cropSrc, setCropSrc] = useState<string | null>(null);

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !onImageChange) return;
    e.target.value = '';
    try {
      const dataUrl = await loadFileAsDataUrl(file);
      setCropSrc(dataUrl);
    } catch {
      // silently fail
    }
  };

  const containerStyle: React.CSSProperties = {
    width: size,
    height: size,
    borderRadius: '50%',
    overflow: 'hidden',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: colors.hover,
    border: `2px solid ${colors.border}`,
    flexShrink: 0,
    position: 'relative',
    cursor: editable ? 'pointer' : 'default',
  };

  const imgStyle: React.CSSProperties = {
    width: '100%',
    height: '100%',
    objectFit: 'cover',
  };

  return (
    <>
      <div style={{ position: 'relative', width: size, height: size, flexShrink: 0 }}>
        <div
          style={containerStyle}
          onClick={editable ? () => inputRef.current?.click() : undefined}
          title={editable ? 'Click to change photo' : undefined}
        >
          {imageUrl ? (
            <img src={imageUrl} alt="Profile" style={imgStyle} />
          ) : (
            <span style={{ fontSize: size * 0.5, lineHeight: 1 }}>{fallback}</span>
          )}
          {editable && (
            <>
              <div style={{
                position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.3)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                opacity: 0, transition: 'opacity .15s',
              }}
                onMouseEnter={e => (e.currentTarget.style.opacity = '1')}
                onMouseLeave={e => (e.currentTarget.style.opacity = '0')}
              >
                <span style={{ color: '#fff', fontSize: size * 0.22, fontWeight: 700 }}>📷</span>
              </div>
              <input ref={inputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFile} />
            </>
          )}
        </div>
        {editable && imageUrl && (
          <button
            onClick={e => { e.stopPropagation(); onImageChange?.(null); }}
            style={{
              position: 'absolute', top: -2, right: -2, width: 18, height: 18,
              borderRadius: '50%', background: colors.danger, color: '#fff',
              border: 'none', cursor: 'pointer', fontSize: 11, lineHeight: 1,
              display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1,
            }}
            title="Remove photo"
          >×</button>
        )}
      </div>
      {cropSrc && (
        <ImageCropper
          imageSrc={cropSrc}
          onConfirm={(cropped) => { onImageChange?.(cropped); setCropSrc(null); }}
          onCancel={() => setCropSrc(null)}
        />
      )}
    </>
  );
}

__EOF_SRC_COMPONENTS_PROFILEIMAGE_TSX__

cat > "$ROOT/src/components/ImageCropper.tsx" << '__EOF_SRC_COMPONENTS_IMAGECROPPER_TSX__'
import React, { useState, useRef, useCallback, useEffect } from 'react';
import { colors } from '../styles';

interface ImageCropperProps {
  imageSrc: string;
  onConfirm: (croppedDataUrl: string) => void;
  onCancel: () => void;
}

const CROP_SIZE = 240;
const OUTPUT_SIZE = 200;
const MAX_BYTES = 300_000;
const MIN_ZOOM = 1;
const MAX_ZOOM = 4;

export function ImageCropper({ imageSrc, onConfirm, onCancel }: ImageCropperProps) {
  const [zoom, setZoom] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });
  const [imgDims, setImgDims] = useState({ w: 0, h: 0 });
  const [dragging, setDragging] = useState(false);
  const dragStart = useRef({ x: 0, y: 0, ox: 0, oy: 0 });
  const containerRef = useRef<HTMLDivElement>(null);

  // Load image dimensions
  useEffect(() => {
    const img = new Image();
    img.onload = () => {
      setImgDims({ w: img.width, h: img.height });
      setOffset({ x: 0, y: 0 });
      setZoom(1);
    };
    img.src = imageSrc;
  }, [imageSrc]);

  // Compute the scaled image size to fill the crop area at zoom=1
  const getScaledSize = useCallback(() => {
    if (!imgDims.w || !imgDims.h) return { sw: CROP_SIZE, sh: CROP_SIZE };
    const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
    return { sw: imgDims.w * ratio * zoom, sh: imgDims.h * ratio * zoom };
  }, [imgDims, zoom]);

  const clampOffset = useCallback((ox: number, oy: number) => {
    const { sw, sh } = getScaledSize();
    const maxX = Math.max(0, (sw - CROP_SIZE) / 2);
    const maxY = Math.max(0, (sh - CROP_SIZE) / 2);
    return { x: Math.max(-maxX, Math.min(maxX, ox)), y: Math.max(-maxY, Math.min(maxY, oy)) };
  }, [getScaledSize]);

  // Mouse/touch handlers
  const handlePointerDown = (e: React.PointerEvent) => {
    e.preventDefault();
    setDragging(true);
    dragStart.current = { x: e.clientX, y: e.clientY, ox: offset.x, oy: offset.y };
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    const dx = e.clientX - dragStart.current.x;
    const dy = e.clientY - dragStart.current.y;
    setOffset(clampOffset(dragStart.current.ox + dx, dragStart.current.oy + dy));
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    setDragging(false);
    (e.target as HTMLElement).releasePointerCapture(e.pointerId);
  };

  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const newZoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, zoom - e.deltaY * 0.002));
    setZoom(newZoom);
    // Re-clamp offset for new zoom
    const { sw, sh } = (() => {
      if (!imgDims.w || !imgDims.h) return { sw: CROP_SIZE, sh: CROP_SIZE };
      const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
      return { sw: imgDims.w * ratio * newZoom, sh: imgDims.h * ratio * newZoom };
    })();
    const maxX = Math.max(0, (sw - CROP_SIZE) / 2);
    const maxY = Math.max(0, (sh - CROP_SIZE) / 2);
    setOffset({ x: Math.max(-maxX, Math.min(maxX, offset.x)), y: Math.max(-maxY, Math.min(maxY, offset.y)) });
  };

  const handleConfirm = () => {
    const img = new Image();
    img.onload = () => {
      const baseRatio = Math.max(CROP_SIZE / img.width, CROP_SIZE / img.height);
      const scaledW = img.width * baseRatio * zoom;
      const scaledH = img.height * baseRatio * zoom;

      // Where the image top-left is relative to the crop area center
      const imgLeft = (CROP_SIZE - scaledW) / 2 + offset.x;
      const imgTop = (CROP_SIZE - scaledH) / 2 + offset.y;

      // Source rectangle in the original image coordinates
      const sx = (-imgLeft) / (baseRatio * zoom);
      const sy = (-imgTop) / (baseRatio * zoom);
      const sSize = CROP_SIZE / (baseRatio * zoom);

      const canvas = document.createElement('canvas');
      canvas.width = OUTPUT_SIZE;
      canvas.height = OUTPUT_SIZE;
      const ctx = canvas.getContext('2d')!;
      ctx.drawImage(img, sx, sy, sSize, sSize, 0, 0, OUTPUT_SIZE, OUTPUT_SIZE);

      let quality = 0.85;
      let dataUrl = canvas.toDataURL('image/jpeg', quality);
      while (dataUrl.length > MAX_BYTES && quality > 0.2) {
        quality -= 0.1;
        dataUrl = canvas.toDataURL('image/jpeg', quality);
      }
      onConfirm(dataUrl);
    };
    img.src = imageSrc;
  };

  const { sw, sh } = getScaledSize();

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,.6)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200,
    }} onClick={onCancel}>
      <div style={{
        background: '#fff', borderRadius: 12, padding: 24, maxWidth: 360, width: '90%',
        boxShadow: '0 8px 30px rgba(0,0,0,.25)',
      }} onClick={e => e.stopPropagation()}>
        <h3 style={{ margin: '0 0 12px', fontSize: 16, fontWeight: 700 }}>Crop Photo</h3>
        <p style={{ fontSize: 12, color: colors.textSec, margin: '0 0 12px' }}>
          Drag to reposition. Scroll or use slider to zoom.
        </p>

        {/* Crop area */}
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14 }}>
          <div
            ref={containerRef}
            style={{
              width: CROP_SIZE, height: CROP_SIZE, borderRadius: '50%',
              overflow: 'hidden', position: 'relative', cursor: dragging ? 'grabbing' : 'grab',
              border: `3px solid ${colors.primary}`, background: '#000',
            }}
            onPointerDown={handlePointerDown}
            onPointerMove={handlePointerMove}
            onPointerUp={handlePointerUp}
            onWheel={handleWheel}
          >
            <img
              src={imageSrc}
              alt="Crop preview"
              draggable={false}
              style={{
                position: 'absolute',
                width: sw, height: sh,
                left: (CROP_SIZE - sw) / 2 + offset.x,
                top: (CROP_SIZE - sh) / 2 + offset.y,
                pointerEvents: 'none', userSelect: 'none',
              }}
            />
          </div>
        </div>

        {/* Zoom slider */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
          <span style={{ fontSize: 12, color: colors.textSec }}>−</span>
          <input
            type="range" min={MIN_ZOOM} max={MAX_ZOOM} step={0.05} value={zoom}
            onChange={e => {
              const newZ = parseFloat(e.target.value);
              setZoom(newZ);
              // Re-clamp
              const ratio = Math.max(CROP_SIZE / imgDims.w, CROP_SIZE / imgDims.h);
              const nw = imgDims.w * ratio * newZ, nh = imgDims.h * ratio * newZ;
              const maxX = Math.max(0, (nw - CROP_SIZE) / 2);
              const maxY = Math.max(0, (nh - CROP_SIZE) / 2);
              setOffset(prev => ({ x: Math.max(-maxX, Math.min(maxX, prev.x)), y: Math.max(-maxY, Math.min(maxY, prev.y)) }));
            }}
            style={{ flex: 1 }}
          />
          <span style={{ fontSize: 12, color: colors.textSec }}>+</span>
        </div>

        {/* Actions */}
        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
          <button onClick={onCancel} style={{
            padding: '8px 16px', borderRadius: 6, border: `1px solid ${colors.border}`,
            background: colors.hover, color: colors.text, fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Cancel</button>
          <button onClick={handleConfirm} style={{
            padding: '8px 16px', borderRadius: 6, border: 'none',
            background: colors.primary, color: '#fff', fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>Confirm</button>
        </div>
      </div>
    </div>
  );
}

__EOF_SRC_COMPONENTS_IMAGECROPPER_TSX__

cat > "$ROOT/src/components/FamilyTree.tsx" << '__EOF_SRC_COMPONENTS_FAMILYTREE_TSX__'
import React, { useState, useMemo, useCallback } from 'react';
import type { Person } from '../types';
import { colors } from '../styles';
import { getEntryName } from '../utils';

interface FamilyTreeProps {
  person: Person;
  allPersons: Person[];
  images: Record<string, string>;
  onSelectPerson: (id: string) => void;
}

type NodeRole = 'self' | 'spouse' | 'parent' | 'child' | 'sibling' | 'grandparent' | 'grandchild';

interface TreeNode {
  id: string;
  name: string;
  imageUrl: string | null;
  role: NodeRole;
  expandable: boolean; // has further parents or children to show
  expanded: boolean;
  deceased: boolean;
}

const NODE_W = 100;
const NODE_H = 72;
const H_GAP = 16;
const V_GAP = 44;

const ROLE_COLORS: Record<NodeRole, { border: string; bg: string }> = {
  self: { border: colors.primary, bg: '#e3f2fd' },
  spouse: { border: '#e91e63', bg: '#fce4ec' },
  parent: { border: '#6a1b9a', bg: '#f3e5f5' },
  child: { border: '#2e7d32', bg: '#e8f5e9' },
  sibling: { border: colors.textSec, bg: '#f5f5f5' },
  grandparent: { border: '#4a148c', bg: '#ede7f6' },
  grandchild: { border: '#1b5e20', bg: '#c8e6c9' },
};

function PersonNode({ node, x, y, onSelect, onToggleExpand }: {
  node: TreeNode; x: number; y: number;
  onSelect: () => void; onToggleExpand: () => void;
}) {
  const { border: borderColor, bg: bgColor } = ROLE_COLORS[node.role];

  return (
    <g>
      <g style={{ cursor: node.role === 'self' ? 'default' : 'pointer' }} onClick={node.role !== 'self' ? onSelect : undefined}>
        <rect x={x} y={y} width={NODE_W} height={NODE_H} rx={8} ry={8}
          fill={node.deceased ? '#f5f5f5' : bgColor} stroke={node.deceased ? '#9e9e9e' : borderColor} strokeWidth={node.role === 'self' ? 2.5 : 1.5}
          opacity={node.deceased ? 0.75 : 1} />
        {node.imageUrl ? (
          <>
            <defs><clipPath id={`clip-${node.id}-${node.role}`}><circle cx={x + NODE_W / 2} cy={y + 22} r={14} /></clipPath></defs>
            <image href={node.imageUrl} x={x + NODE_W / 2 - 14} y={y + 8} width={28} height={28} clipPath={`url(#clip-${node.id}-${node.role})`}
              opacity={node.deceased ? 0.6 : 1} />
          </>
        ) : (
          <text x={x + NODE_W / 2} y={y + 26} textAnchor="middle" fontSize={16}>👤</text>
        )}
        {node.deceased && (
          <text x={x + NODE_W - 8} y={y + 14} textAnchor="middle" fontSize={12} fill="#616161">✝</text>
        )}
        <text x={x + NODE_W / 2} y={y + 50} textAnchor="middle" fontSize={10} fontWeight={node.role === 'self' ? 700 : 500}
          fill={node.deceased ? '#757575' : colors.text}>
          {node.name.length > 14 ? node.name.slice(0, 13) + '…' : node.name}
        </text>
        <text x={x + NODE_W / 2} y={y + 63} textAnchor="middle" fontSize={8} fill={node.deceased ? '#9e9e9e' : borderColor} fontWeight={600}>
          {node.role === 'self' ? '★ SELF' : node.role === 'grandparent' ? 'GRANDPARENT' : node.role === 'grandchild' ? 'GRANDCHILD' : node.role.toUpperCase()}
        </text>
      </g>
      {node.expandable && (
        <g style={{ cursor: 'pointer' }} onClick={e => { e.stopPropagation(); onToggleExpand(); }}>
          <circle
            cx={x + NODE_W / 2}
            cy={node.role === 'child' || node.role === 'grandchild' ? y + NODE_H + 10 : y - 10}
            r={9} fill="#fff" stroke={borderColor} strokeWidth={1.5} />
          <text
            x={x + NODE_W / 2}
            y={(node.role === 'child' || node.role === 'grandchild' ? y + NODE_H + 10 : y - 10) + 4}
            textAnchor="middle" fontSize={12} fontWeight={700} fill={borderColor}>
            {node.expanded ? '−' : '+'}
          </text>
        </g>
      )}
    </g>
  );
}

export function FamilyTree({ person, allPersons, images, onSelectPerson }: FamilyTreeProps) {
  // Track expanded nodes: set of person IDs that have been expanded
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  const toggleExpand = useCallback((id: string) => {
    setExpandedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const getParents = useCallback((id: string) => allPersons.filter(p => p.childIds.includes(id)), [allPersons]);
  const getChildren = useCallback((id: string) => {
    const p = allPersons.find(x => x.id === id);
    return p ? allPersons.filter(c => p.childIds.includes(c.id)) : [];
  }, [allPersons]);

  const tree = useMemo(() => {
    // Build rows dynamically based on expansions
    // Structure: ancestor rows (top) ... parent row ... self row ... child row ... descendant rows (bottom)
    type RowItem = { person: Person; role: NodeRole; expandable: boolean; expanded: boolean; parentLinkIds?: string[] };
    type Row = RowItem[];

    const rows: Row[] = [];
    const lines: { fromRow: number; fromIdx: number; toRow: number; toIdx: number; color: string; dashed?: boolean }[] = [];

    // === Build ancestor rows (upward from parents) ===
    const ancestorRows: Row[] = [];

    // Start with direct parents
    const parents = getParents(person.id);
    if (parents.length > 0) {
      const parentRow: Row = parents.map(p => {
        const hasGrandparents = getParents(p.id).length > 0;
        return { person: p, role: 'parent' as NodeRole, expandable: hasGrandparents, expanded: expandedIds.has(p.id) };
      });
      ancestorRows.push(parentRow);

      // Recursively expand upward
      let currentRow = parentRow;
      while (true) {
        const nextRow: Row = [];
        for (const item of currentRow) {
          if (item.expanded) {
            const gps = getParents(item.person.id);
            gps.forEach(gp => {
              const hasMore = getParents(gp.id).length > 0;
              nextRow.push({ person: gp, role: 'grandparent', expandable: hasMore, expanded: expandedIds.has(gp.id), parentLinkIds: [item.person.id] });
            });
          }
        }
        if (nextRow.length === 0) break;
        ancestorRows.push(nextRow);
        currentRow = nextRow;
      }
    }

    // Reverse ancestor rows so oldest generation is at top
    ancestorRows.reverse();

    // === Build self row (self + spouse + siblings) ===
    const spouse = person.spouseId ? allPersons.find(p => p.id === person.spouseId) : null;
    const siblingIds = new Set<string>();
    parents.forEach(p => p.childIds.forEach(cid => { if (cid !== person.id) siblingIds.add(cid); }));
    const siblings = allPersons.filter(p => siblingIds.has(p.id));

    // === Build descendant rows (downward from children) ===
    const descendantRows: Row[] = [];
    const children = getChildren(person.id);
    if (children.length > 0) {
      const childRow: Row = children.map(c => {
        const hasGrandchildren = c.childIds.length > 0;
        return { person: c, role: 'child' as NodeRole, expandable: hasGrandchildren, expanded: expandedIds.has(c.id) };
      });
      descendantRows.push(childRow);

      // Recursively expand downward
      let currentRow = childRow;
      while (true) {
        const nextRow: Row = [];
        for (const item of currentRow) {
          if (item.expanded) {
            const gcs = getChildren(item.person.id);
            gcs.forEach(gc => {
              const hasMore = gc.childIds.length > 0;
              nextRow.push({ person: gc, role: 'grandchild', expandable: hasMore, expanded: expandedIds.has(gc.id), parentLinkIds: [item.person.id] });
            });
          }
        }
        if (nextRow.length === 0) break;
        descendantRows.push(nextRow);
        currentRow = nextRow;
      }
    }

    // === Compute layout ===
    // All rows in order: ancestorRows... selfRow... descendantRows
    const selfRowItems: RowItem[] = [
      { person, role: 'self', expandable: false, expanded: false },
      ...(spouse ? [{ person: spouse, role: 'spouse' as NodeRole, expandable: false, expanded: false }] : []),
      ...siblings.map(s => ({ person: s, role: 'sibling' as NodeRole, expandable: false, expanded: false })),
    ];

    const allRows: Row[] = [...ancestorRows, selfRowItems, ...descendantRows];
    const selfRowIndex = ancestorRows.length;

    // Compute widths
    const rowWidths = allRows.map(r => r.length * NODE_W + (r.length > 0 ? (r.length - 1) * H_GAP : 0));
    const totalWidth = Math.max(...rowWidths, 300);
    const padX = 20;
    const padY = 24;
    const svgWidth = totalWidth + padX * 2;

    // Position nodes
    type PositionedNode = TreeNode & { x: number; y: number; rowIdx: number; colIdx: number };
    const positioned: PositionedNode[] = [];

    allRows.forEach((row, rowIdx) => {
      const rowWidth = rowWidths[rowIdx];
      const startX = padX + (totalWidth - rowWidth) / 2;
      const y = padY + rowIdx * (NODE_H + V_GAP);
      row.forEach((item, colIdx) => {
        const x = startX + colIdx * (NODE_W + H_GAP);
        positioned.push({
          id: item.person.id,
          name: getEntryName(item.person),
          imageUrl: images[item.person.id] || null,
          role: item.role,
          expandable: item.expandable,
          expanded: item.expanded,
          deceased: item.person.status === 'deceased',
          x, y, rowIdx, colIdx,
        });
      });
    });

    // Build connection lines
    const svgLines: { x1: number; y1: number; x2: number; y2: number; color: string; dashed?: boolean }[] = [];

    // Helper to find positioned node by id and role preference
    const findNode = (id: string, preferRole?: NodeRole) => {
      if (preferRole) {
        const n = positioned.find(n => n.id === id && n.role === preferRole);
        if (n) return n;
      }
      return positioned.find(n => n.id === id);
    };

    // Parent row -> self
    if (parents.length > 0) {
      const selfNode = findNode(person.id, 'self');
      if (selfNode) {
        parents.forEach(p => {
          const pNode = findNode(p.id, 'parent');
          if (pNode) {
            svgLines.push({ x1: pNode.x + NODE_W / 2, y1: pNode.y + NODE_H, x2: selfNode.x + NODE_W / 2, y2: selfNode.y, color: '#6a1b9a' });
          }
        });
        // Parents -> siblings
        siblings.forEach(s => {
          const sNode = findNode(s.id, 'sibling');
          if (sNode) {
            parents.forEach(p => {
              const pNode = findNode(p.id, 'parent');
              if (pNode) svgLines.push({ x1: pNode.x + NODE_W / 2, y1: pNode.y + NODE_H, x2: sNode.x + NODE_W / 2, y2: sNode.y, color: '#9e9e9e', dashed: true });
            });
          }
        });
      }
    }

    // Self -> spouse line
    if (spouse) {
      const selfNode = findNode(person.id, 'self');
      const spouseNode = findNode(spouse.id, 'spouse');
      if (selfNode && spouseNode) {
        svgLines.push({ x1: selfNode.x + NODE_W, y1: selfNode.y + NODE_H / 2, x2: spouseNode.x, y2: spouseNode.y + NODE_H / 2, color: '#e91e63' });
      }
    }

    // Self -> children
    if (children.length > 0) {
      const selfNode = findNode(person.id, 'self');
      const spouseNode = spouse ? findNode(spouse.id, 'spouse') : null;
      if (selfNode) {
        children.forEach(c => {
          const cNode = findNode(c.id, 'child');
          if (cNode) {
            svgLines.push({ x1: selfNode.x + NODE_W / 2, y1: selfNode.y + NODE_H, x2: cNode.x + NODE_W / 2, y2: cNode.y, color: '#2e7d32' });
            if (spouseNode) svgLines.push({ x1: spouseNode.x + NODE_W / 2, y1: spouseNode.y + NODE_H, x2: cNode.x + NODE_W / 2, y2: cNode.y, color: '#e91e63', dashed: true });
          }
        });
      }
    }

    // Expanded ancestor lines (grandparents -> parents)
    for (let i = 0; i < ancestorRows.length - 1; i++) {
      const upperRow = ancestorRows[i];
      const lowerRow = ancestorRows[i + 1];
      lowerRow.forEach(lowerItem => {
        const lowerNode = findNode(lowerItem.person.id);
        if (!lowerNode) return;
        // Find which upper items are parents of this lower item
        upperRow.forEach(upperItem => {
          if (upperItem.parentLinkIds?.includes(lowerItem.person.id)) {
            // This upper is a parent of this lower? No — parentLinkIds on upper means upper's parent is...
            // Actually parentLinkIds on the ITEM means "this node's child link target"
          }
        });
      });
    }

    // Better approach for ancestor/descendant links: iterate expanded nodes
    // Ancestor links
    ancestorRows.forEach((row, aIdx) => {
      const actualRowIdx = aIdx; // in allRows
      row.forEach(item => {
        if (item.parentLinkIds) {
          item.parentLinkIds.forEach(childId => {
            const parentNode = positioned.find(n => n.id === item.person.id && n.rowIdx === actualRowIdx);
            const childNode = positioned.find(n => n.id === childId);
            if (parentNode && childNode) {
              svgLines.push({ x1: parentNode.x + NODE_W / 2, y1: parentNode.y + NODE_H, x2: childNode.x + NODE_W / 2, y2: childNode.y, color: '#4a148c', dashed: true });
            }
          });
        }
      });
    });

    // Descendant links
    descendantRows.forEach((row, dIdx) => {
      const actualRowIdx = selfRowIndex + 1 + dIdx;
      row.forEach(item => {
        if (item.parentLinkIds) {
          item.parentLinkIds.forEach(parentId => {
            const childNode = positioned.find(n => n.id === item.person.id && n.rowIdx === actualRowIdx);
            const parentNode = positioned.find(n => n.id === parentId);
            if (parentNode && childNode) {
              svgLines.push({ x1: parentNode.x + NODE_W / 2, y1: parentNode.y + NODE_H, x2: childNode.x + NODE_W / 2, y2: childNode.y, color: '#1b5e20', dashed: true });
            }
          });
        }
      });
    });

    const svgHeight = padY + allRows.length * (NODE_H + V_GAP) - V_GAP + padY;

    return { nodes: positioned, lines: svgLines, svgWidth, svgHeight };
  }, [person, allPersons, images, expandedIds, getParents, getChildren]);

  if (tree.nodes.length <= 1) {
    return <div style={{ fontSize: 13, color: colors.textSec, padding: '12px 0' }}>No family relationships to display.</div>;
  }

  return (
    <div style={{ overflowX: 'auto', marginTop: 8 }}>
      <svg width={tree.svgWidth} height={tree.svgHeight} style={{ display: 'block' }}>
        {tree.lines.map((l, i) => (
          <line key={i} x1={l.x1} y1={l.y1} x2={l.x2} y2={l.y2}
            stroke={l.color} strokeWidth={1.5}
            strokeDasharray={l.dashed ? '4,3' : undefined}
            opacity={0.7} />
        ))}
        {tree.nodes.map((n, i) => (
          <PersonNode key={`${n.id}-${n.role}-${i}`} node={n} x={n.x} y={n.y}
            onSelect={() => onSelectPerson(n.id)}
            onToggleExpand={() => toggleExpand(n.id)} />
        ))}
      </svg>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12, marginTop: 8, fontSize: 11, color: colors.textSec }}>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#e3f2fd', border: `2px solid ${colors.primary}`, marginRight: 4 }}></span>Self</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#fce4ec', border: '2px solid #e91e63', marginRight: 4 }}></span>Spouse</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#f3e5f5', border: '2px solid #6a1b9a', marginRight: 4 }}></span>Parent</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#e8f5e9', border: '2px solid #2e7d32', marginRight: 4 }}></span>Child</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#f5f5f5', border: `2px solid ${colors.textSec}`, marginRight: 4 }}></span>Sibling</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#ede7f6', border: '2px solid #4a148c', marginRight: 4 }}></span>Grandparent+</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#c8e6c9', border: '2px solid #1b5e20', marginRight: 4 }}></span>Grandchild+</span>
        <span><span style={{ display: 'inline-block', width: 10, height: 10, borderRadius: 2, background: '#f5f5f5', border: '2px solid #9e9e9e', marginRight: 4, position: 'relative' }}></span>✝ Deceased</span>
      </div>
      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 6 }}>
        Click <strong>+</strong> on a node to expand further generations. Click a name to navigate.
      </div>
    </div>
  );
}

__EOF_SRC_COMPONENTS_FAMILYTREE_TSX__

cat > "$ROOT/src/components/CollapsibleSection.tsx" << '__EOF_SRC_COMPONENTS_COLLAPSIBLESECTION_TSX__'
import React, { useState, useEffect, useCallback } from 'react';
import { putPrivateItem, getPrivateItem, PageStorageError } from '@amzn/quick-pages-runtime-lib';
import { S, colors } from '../styles';

const PREFS_TABLE = 'user-preferences';
const PREFS_KEY = 'detail-collapsed-sections';

// Global cache to avoid re-fetching on every mount
let cachedCollapsed: Set<string> | null = null;
let loadPromise: Promise<Set<string>> | null = null;

async function loadCollapsedSections(): Promise<Set<string>> {
  if (cachedCollapsed) return cachedCollapsed;
  if (loadPromise) return loadPromise;
  loadPromise = (async () => {
    try {
      const r = await getPrivateItem({ tableName: PREFS_TABLE, key: PREFS_KEY });
      if (r) {
        cachedCollapsed = new Set(JSON.parse(r.item.value));
      } else {
        cachedCollapsed = new Set();
      }
    } catch {
      cachedCollapsed = new Set();
    }
    return cachedCollapsed!;
  })();
  return loadPromise;
}

async function saveCollapsedSections(sections: Set<string>) {
  cachedCollapsed = sections;
  try {
    await putPrivateItem({ tableName: PREFS_TABLE, key: PREFS_KEY, value: JSON.stringify([...sections]) });
  } catch {
    // silently fail
  }
}

export function useCollapsedSections() {
  const [collapsed, setCollapsed] = useState<Set<string>>(cachedCollapsed || new Set());
  const [loaded, setLoaded] = useState(!!cachedCollapsed);

  useEffect(() => {
    if (!cachedCollapsed) {
      loadCollapsedSections().then(s => { setCollapsed(new Set(s)); setLoaded(true); });
    } else {
      setLoaded(true);
    }
  }, []);

  const toggle = useCallback((sectionId: string) => {
    setCollapsed(prev => {
      const next = new Set(prev);
      if (next.has(sectionId)) next.delete(sectionId);
      else next.add(sectionId);
      saveCollapsedSections(next);
      return next;
    });
  }, []);

  return { collapsed, toggle, loaded };
}

interface CollapsibleSectionProps {
  id: string;
  title: string;
  collapsed: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}

export function CollapsibleSection({ id, title, collapsed, onToggle, children }: CollapsibleSectionProps) {
  return (
    <div>
      <div
        style={{ ...S.section, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'space-between', userSelect: 'none' }}
        onClick={onToggle}
      >
        <span>{title}</span>
        <span style={{ fontSize: 12, color: colors.textSec, fontWeight: 400 }}>
          {collapsed ? '▶' : '▼'}
        </span>
      </div>
      {!collapsed && children}
    </div>
  );
}

__EOF_SRC_COMPONENTS_COLLAPSIBLESECTION_TSX__

cat > "$ROOT/src/components/VCardExport.tsx" << '__EOF_SRC_COMPONENTS_VCARDEXPORT_TSX__'
import type { DirectoryEntry, Person, Company } from '../types';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';

function escapeVCard(str: string): string {
  return str.replace(/[\\;,]/g, m => '\\' + m).replace(/\n/g, '\\n');
}

function personToVCard(p: Person, imageDataUrl?: string): string {
  const lines: string[] = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    `N:${escapeVCard(p.lastName)};${escapeVCard(p.firstName)};;;`,
    `FN:${escapeVCard(p.firstName)} ${escapeVCard(p.lastName)}`,
  ];

  if (p.birthday) {
    lines.push(`BDAY:${p.birthday.replace(/-/g, '')}`);
  }

  for (const em of p.emails) {
    const type = em.label === 'Work' ? 'WORK' : 'HOME';
    lines.push(`EMAIL;TYPE=${type}${em.isPrimary ? ',PREF' : ''}:${em.address}`);
  }

  for (const ph of p.phones) {
    const type = ph.label === 'Work' ? 'WORK' : ph.label === 'Mobile' ? 'CELL' : 'HOME';
    lines.push(`TEL;TYPE=${type}${ph.isPrimary ? ',PREF' : ''}:${ph.countryCode || '+1'}${ph.number}`);
  }

  for (const addr of p.addresses) {
    const type = addr.label === 'Work' ? 'WORK' : 'HOME';
    lines.push(`ADR;TYPE=${type}${addr.isPrimary ? ',PREF' : ''}:;;${escapeVCard(addr.street)}${addr.street2 ? ' ' + escapeVCard(addr.street2) : ''};${escapeVCard(addr.city)};${escapeVCard(addr.state)};${escapeVCard(addr.zip)};${escapeVCard(addr.country)}`);
  }

  if (p.notes) {
    lines.push(`NOTE:${escapeVCard(p.notes)}`);
  }

  if (imageDataUrl) {
    const match = imageDataUrl.match(/^data:image\/(jpeg|png|gif);base64,(.+)$/);
    if (match) {
      lines.push(`PHOTO;ENCODING=b;TYPE=${match[1].toUpperCase()}:${match[2]}`);
    }
  }

  lines.push('END:VCARD');
  return lines.join('\r\n');
}

function companyToVCard(c: Company, imageDataUrl?: string): string {
  const lines: string[] = [
    'BEGIN:VCARD',
    'VERSION:3.0',
    `N:${escapeVCard(c.name)};;;;`,
    `FN:${escapeVCard(c.name)}`,
    `ORG:${escapeVCard(c.name)}`,
  ];

  if (c.website) {
    lines.push(`URL:${c.website}`);
  }

  for (const em of c.emails) {
    lines.push(`EMAIL;TYPE=WORK${em.isPrimary ? ',PREF' : ''}:${em.address}`);
  }

  for (const ph of c.phones) {
    const type = ph.label === 'Fax' ? 'FAX' : 'WORK';
    lines.push(`TEL;TYPE=${type}${ph.isPrimary ? ',PREF' : ''}:${ph.countryCode || '+1'}${ph.number}`);
  }

  for (const addr of c.addresses) {
    lines.push(`ADR;TYPE=WORK${addr.isPrimary ? ',PREF' : ''}:;;${escapeVCard(addr.street)}${addr.street2 ? ' ' + escapeVCard(addr.street2) : ''};${escapeVCard(addr.city)};${escapeVCard(addr.state)};${escapeVCard(addr.zip)};${escapeVCard(addr.country)}`);
  }

  if (c.notes) {
    lines.push(`NOTE:${escapeVCard(c.notes)}`);
  }

  if (imageDataUrl) {
    const match = imageDataUrl.match(/^data:image\/(jpeg|png|gif);base64,(.+)$/);
    if (match) {
      lines.push(`PHOTO;ENCODING=b;TYPE=${match[1].toUpperCase()}:${match[2]}`);
    }
  }

  lines.push('END:VCARD');
  return lines.join('\r\n');
}

export function entryToVCard(entry: DirectoryEntry, imageDataUrl?: string): string {
  return entry.type === 'person'
    ? personToVCard(entry, imageDataUrl)
    : companyToVCard(entry, imageDataUrl);
}

export async function downloadVCard(entry: DirectoryEntry, imageDataUrl?: string): Promise<void> {
  const vcf = entryToVCard(entry, imageDataUrl);
  const name = entry.type === 'person'
    ? `${entry.firstName}_${entry.lastName}`
    : entry.name;
  const filename = `${name.replace(/[^a-zA-Z0-9]/g, '_')}.vcf`;
  await downloadFile(filename, new Blob([vcf], { type: 'text/vcard' }));
}

__EOF_SRC_COMPONENTS_VCARDEXPORT_TSX__

cat > "$ROOT/src/components/BulkActions.tsx" << '__EOF_SRC_COMPONENTS_BULKACTIONS_TSX__'
import React, { useState, useEffect, useRef } from 'react';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import type { DirectoryEntry, Person, Household } from '../types';
import { EMPTY_ADDR } from '../types';
import { S, colors } from '../styles';
import { getEntryName, suggestAddresses, useDebounce } from '../utils';
import type { AddressSuggestion } from '../types';
import { entryToVCard } from './VCardExport';

interface BulkActionsBarProps {
  selectedIds: Set<string>;
  entries: DirectoryEntry[];
  allPersons: Person[];
  households: Household[];
  images: Record<string, string>;
  onClearSelection: () => void;
  onBulkDelete: (ids: string[]) => Promise<number | null>;
  onBulkStatusChange: (ids: string[], status: 'active' | 'deceased' | 'closed') => void;
  onBulkAssignHousehold: (personIds: string[], householdId: string) => void;
  onCreateAndAssignHousehold: (personIds: string[], household: Household) => void;
  onError: (msg: string) => void;
  onToast: (msg: string) => void;
}

export function BulkActionsBar({
  selectedIds, entries, allPersons, households, images,
  onClearSelection, onBulkDelete, onBulkStatusChange, onBulkAssignHousehold, onCreateAndAssignHousehold, onError, onToast,
}: BulkActionsBarProps) {
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showStatusPicker, setShowStatusPicker] = useState(false);
  const [showStatusConfirm, setShowStatusConfirm] = useState<'active' | 'deceased' | 'closed' | null>(null);
  const [showHouseholdPicker, setShowHouseholdPicker] = useState(false);
  const [showHouseholdConfirm, setShowHouseholdConfirm] = useState<Household | null>(null);
  const [householdSearch, setHouseholdSearch] = useState('');
  const [showCreateHousehold, setShowCreateHousehold] = useState(false);
  const [newHhName, setNewHhName] = useState('');
  const [newHhStreet, setNewHhStreet] = useState('');
  const [newHhStreet2, setNewHhStreet2] = useState('');
  const [newHhCity, setNewHhCity] = useState('');
  const [newHhState, setNewHhState] = useState('');
  const [newHhZip, setNewHhZip] = useState('');
  const [newHhError, setNewHhError] = useState('');
  const [addrSuggestions, setAddrSuggestions] = useState<AddressSuggestion[]>([]);
  const debouncedStreet = useDebounce(newHhStreet, 400);
  const addrWrapRef = useRef<HTMLDivElement>(null);

  // Fetch address suggestions when street input changes
  useEffect(() => {
    if (showCreateHousehold && debouncedStreet.length >= 3) {
      suggestAddresses(debouncedStreet).then(setAddrSuggestions);
    } else {
      setAddrSuggestions([]);
    }
  }, [debouncedStreet, showCreateHousehold]);

  // Close suggestions on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (addrWrapRef.current && !addrWrapRef.current.contains(e.target as Node)) setAddrSuggestions([]);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const count = selectedIds.size;
  if (count === 0) return null;

  const selectedEntries = entries.filter(e => selectedIds.has(e.id));
  const selectedPersons = selectedEntries.filter((e): e is Person => e.type === 'person');
  const selectedCompanies = selectedEntries.filter(e => e.type === 'company');

  const hasPersons = selectedPersons.length > 0;
  const hasCompanies = selectedCompanies.length > 0;
  const isMixed = hasPersons && hasCompanies;
  const isPersonsOnly = hasPersons && !hasCompanies;
  const isCompaniesOnly = hasCompanies && !hasPersons;

  // Compute which entries already have the target status
  const getStatusBreakdown = (status: 'active' | 'deceased' | 'closed') => {
    let alreadyCount = 0;
    const idsToChange: string[] = [];
    for (const e of selectedEntries) {
      if (e.type === 'person') {
        const current = e.status || 'active';
        const target = status === 'closed' ? 'active' : status;
        if (current === target) alreadyCount++;
        else idsToChange.push(e.id);
      } else {
        const current = e.companyStatus || 'active';
        const target = status === 'deceased' ? 'active' : status;
        if (current === target) alreadyCount++;
        else idsToChange.push(e.id);
      }
    }
    return { alreadyCount, willChange: idsToChange.length, idsToChange };
  };

  const handleExportVCard = async () => {
    try {
      const vcards = selectedEntries.map(e => entryToVCard(e, images[e.id]));
      const combined = vcards.join('\r\n');
      await downloadFile('contacts-export.vcf', new Blob([combined], { type: 'text/vcard' }));
      onToast(`📇 ${selectedEntries.length} contact${selectedEntries.length !== 1 ? 's' : ''} exported`);
    } catch (e: any) {
      if (e?.message && !e.message.includes('declined')) onError(e.message);
    }
  };

  const getCascadeEffects = () => {
    const effects: string[] = [];
    const ids = new Set(selectedIds);
    for (const entry of selectedEntries) {
      if (entry.type === 'person') {
        if (entry.spouseId && !ids.has(entry.spouseId)) {
          effects.push(`Unlink spouse of ${getEntryName(entry)}`);
        }
        const parents = allPersons.filter(p => !ids.has(p.id) && p.childIds.includes(entry.id));
        if (parents.length > 0) effects.push(`Remove ${getEntryName(entry)} as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
        const linkedCompanies = entries.filter(e => e.type === 'company' && !ids.has(e.id) && e.contactPersonIds.includes(entry.id));
        if (linkedCompanies.length > 0) effects.push(`Remove ${getEntryName(entry)} as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
      }
    }
    return effects;
  };

  const filteredHouseholds = households.filter(h =>
    !householdSearch || h.name.toLowerCase().includes(householdSearch.toLowerCase())
  );

  return (
    <>
      {/* Floating action bar */}
      <div style={{
        position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)',
        background: '#1a1a2e', color: '#fff', borderRadius: 12,
        padding: '12px 20px', display: 'flex', alignItems: 'center', gap: 14,
        boxShadow: '0 8px 32px rgba(0,0,0,.3)', zIndex: 50,
        fontSize: 13, maxWidth: '90vw', flexWrap: 'wrap',
      }}>
        <span style={{ fontWeight: 700, whiteSpace: 'nowrap' }}>
          {count} selected
        </span>

        <div style={{ width: 1, height: 20, background: 'rgba(255,255,255,.2)' }} />

        <button onClick={handleExportVCard} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
        }}>📇 Export vCard</button>

        <button onClick={() => setShowStatusPicker(true)} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
        }}>⚡ Change Status</button>

        {isPersonsOnly && (
          <button onClick={() => { setShowHouseholdPicker(true); setHouseholdSearch(''); }} style={{
            ...S.btn, padding: '6px 14px', fontSize: 12,
            background: 'rgba(255,255,255,.15)', color: '#fff', border: '1px solid rgba(255,255,255,.2)',
          }}>🏠 Assign Household</button>
        )}

        <button onClick={() => setShowDeleteConfirm(true)} style={{
          ...S.btn, padding: '6px 14px', fontSize: 12,
          background: 'rgba(217,48,37,.8)', color: '#fff', border: 'none',
        }}>🗑️ Delete</button>

        <div style={{ width: 1, height: 20, background: 'rgba(255,255,255,.2)' }} />

        <button onClick={onClearSelection} style={{
          ...S.btn, padding: '6px 12px', fontSize: 12,
          background: 'transparent', color: 'rgba(255,255,255,.7)', border: 'none',
          textDecoration: 'underline',
        }}>Clear</button>
      </div>

      {/* Bulk delete confirmation */}
      {showDeleteConfirm && (
        <div style={S.overlay} onClick={() => setShowDeleteConfirm(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🗑️ Delete {count} Entr{count === 1 ? 'y' : 'ies'}</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                Are you sure you want to delete the following?
              </div>
              <div style={{ maxHeight: 150, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                {selectedEntries.map(e => (
                  <div key={e.id} style={{ padding: '3px 0' }}>
                    {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                  </div>
                ))}
              </div>
              {(() => {
                const effects = getCascadeEffects();
                return effects.length > 0 ? (
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 4 }}>Side effects:</div>
                    <ul style={{ margin: 0, paddingLeft: 18, fontSize: 12, color: colors.textSec }}>
                      {effects.slice(0, 8).map((eff, i) => <li key={i}>{eff}</li>)}
                      {effects.length > 8 && <li>...and {effects.length - 8} more</li>}
                    </ul>
                  </div>
                ) : null;
              })()}
              <div style={{ marginTop: 10, fontSize: 13 }}>This action cannot be undone.</div>
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowDeleteConfirm(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={async () => {
                setShowDeleteConfirm(false);
                const count = await onBulkDelete(Array.from(selectedIds));
                if (count) onToast(`🗑️ ${count} entr${count === 1 ? 'y' : 'ies'} deleted`);
              }}>Delete {count}</button>
            </div>
          </div>
        </div>
      )}

      {/* Status change picker */}
      {showStatusPicker && (
        <div style={S.overlay} onClick={() => setShowStatusPicker(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>⚡ Change Status</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 12 }}>
                Change status for {count} selected entr{count === 1 ? 'y' : 'ies'}:
                {isMixed && (
                  <div style={{ fontSize: 12, color: colors.textSec, marginTop: 4 }}>
                    ({selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''}, {selectedCompanies.length} compan{selectedCompanies.length !== 1 ? 'ies' : 'y'})
                  </div>
                )}
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {(() => {
                  const b = getStatusBreakdown('active');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('active'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>● Active</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Active`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Active` : ''}`}
                      </div>
                    </button>
                  );
                })()}
                {!hasCompanies && (() => {
                  const b = getStatusBreakdown('deceased');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('deceased'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>✝ Deceased</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Deceased`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Deceased` : ''}`}
                      </div>
                    </button>
                  );
                })()}
                {!hasPersons && (() => {
                  const b = getStatusBreakdown('closed');
                  return (
                    <button onClick={() => { setShowStatusPicker(false); setShowStatusConfirm('closed'); }}
                      disabled={b.willChange === 0}
                      style={{ ...S.btn, ...S.btnSec, textAlign: 'left', padding: '10px 14px', ...(b.willChange === 0 ? { opacity: 0.5, cursor: 'default' } : {}) }}>
                      <div>🚫 Closed</div>
                      <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                        {b.willChange === 0
                          ? `All ${count} already Closed`
                          : `${b.willChange} of ${count} will change${b.alreadyCount > 0 ? ` — ${b.alreadyCount} already Closed` : ''}`}
                      </div>
                    </button>
                  );
                })()}
              </div>
              {isMixed && (
                <div style={{ fontSize: 12, color: colors.textSec, marginTop: 12, fontStyle: 'italic' }}>
                  Only statuses valid for both persons and companies are shown.
                </div>
              )}
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Status change confirmation */}
      {showStatusConfirm && (() => {
        const b = getStatusBreakdown(showStatusConfirm);
        const affectedEntries = selectedEntries.filter(e => b.idsToChange.includes(e.id));
        const skippedEntries = selectedEntries.filter(e => !b.idsToChange.includes(e.id));
        return (
        <div style={S.overlay} onClick={() => setShowStatusConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>⚡ Confirm Status Change</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                {b.willChange} of {count} selected entr{count === 1 ? 'y' : 'ies'} will change to <strong>{showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'}</strong>
                {b.alreadyCount > 0 && <span style={{ color: colors.textSec }}> — {b.alreadyCount} already {showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'}</span>}
              </div>
              {affectedEntries.length > 0 && (
                <div style={{ maxHeight: 120, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                  {affectedEntries.map(e => (
                    <div key={e.id} style={{ padding: '3px 0' }}>
                      {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                    </div>
                  ))}
                </div>
              )}
              {skippedEntries.length > 0 && (
                <div style={{ fontSize: 12, color: colors.textSec, marginBottom: 10 }}>
                  <div style={{ fontWeight: 600, marginBottom: 2 }}>Already {showStatusConfirm === 'active' ? 'Active' : showStatusConfirm === 'deceased' ? 'Deceased' : 'Closed'} (no change):</div>
                  <div style={{ maxHeight: 60, overflowY: 'auto' }}>
                    {skippedEntries.map(e => (
                      <div key={e.id} style={{ padding: '2px 0' }}>
                        {e.type === 'person' ? '👤' : '🏢'} {getEntryName(e)}
                      </div>
                    ))}
                  </div>
                </div>
              )}
              {showStatusConfirm === 'active' && affectedEntries.some(e => (e.type === 'person' && e.status === 'deceased') || (e.type === 'company' && e.companyStatus === 'closed')) && (
                <div style={{ fontSize: 12, color: colors.textSec }}>
                  This will reactivate any deceased persons or closed companies in the selection.
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowStatusConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                const status = showStatusConfirm;
                const n = b.willChange;
                setShowStatusConfirm(null);
                onBulkStatusChange(b.idsToChange, status);
                onToast(`✅ ${n} entr${n === 1 ? 'y' : 'ies'} updated to ${status}`);
              }}>Change {b.willChange}</button>
            </div>
          </div>
        </div>
        );
      })()}

      {/* Household assign picker */}
      {showHouseholdPicker && (
        <div style={S.overlay} onClick={() => setShowHouseholdPicker(false)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Assign to Household</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10, fontSize: 13 }}>
                Assign {selectedPersons.length} person{selectedPersons.length !== 1 ? 's' : ''} to a household:
              </div>

              {/* Create New Household button */}
              {(() => {
                const canCreate = selectedPersons.length >= 2;
                return (
                  <div
                    style={{
                      padding: '10px 12px', borderRadius: 6, marginBottom: 8,
                      border: `2px dashed ${canCreate ? colors.primary : colors.border}`,
                      cursor: canCreate ? 'pointer' : 'default',
                      background: canCreate ? '#f0f7ff' : '#f5f5f5', textAlign: 'center',
                      opacity: canCreate ? 1 : 0.6,
                    }}
                    onMouseEnter={ev => { if (canCreate) ev.currentTarget.style.background = '#e3effd'; }}
                    onMouseLeave={ev => { if (canCreate) ev.currentTarget.style.background = '#f0f7ff'; }}
                    onClick={() => {
                      if (!canCreate) return;
                      setShowHouseholdPicker(false);
                      setShowCreateHousehold(true);
                      setNewHhName(''); setNewHhStreet(''); setNewHhStreet2('');
                      setNewHhCity(''); setNewHhState(''); setNewHhZip(''); setNewHhError('');
                    }}>
                    <div style={{ fontWeight: 600, fontSize: 13, color: canCreate ? colors.primary : colors.textSec }}>+ Create New Household</div>
                    <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                      {canCreate
                        ? 'Create a household and assign selected persons'
                        : 'Select at least 2 persons to create a household'}
                    </div>
                  </div>
                );
              })()}

              {households.length > 0 && (
                <>
                  <input
                    style={{ ...S.input, marginBottom: 10 }}
                    placeholder="Search households..."
                    value={householdSearch}
                    onChange={e => setHouseholdSearch(e.target.value)}
                  />
                  <div style={{ maxHeight: 180, overflowY: 'auto' }}>
                    {filteredHouseholds.length === 0 ? (
                      <div style={{ fontSize: 13, color: colors.textSec, padding: 10 }}>No households found.</div>
                    ) : (
                      filteredHouseholds.map(h => (
                        <div key={h.id}
                          style={{
                            padding: '10px 12px', borderRadius: 6, marginBottom: 4,
                            border: `1px solid ${colors.border}`, cursor: 'pointer',
                            background: '#fff',
                          }}
                          onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)}
                          onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')}
                          onClick={() => {
                            setShowHouseholdPicker(false);
                            setShowHouseholdConfirm(h);
                          }}>
                          <div style={{ fontWeight: 600, fontSize: 13 }}>🏠 {h.name}</div>
                          <div style={{ fontSize: 11, color: colors.textSec, marginTop: 2 }}>
                            {h.memberIds.length} member{h.memberIds.length !== 1 ? 's' : ''}
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </>
              )}
            </div>
            <div style={{ ...S.dialogActions, marginTop: 16 }}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdPicker(false)}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Create new household form */}
      {showCreateHousehold && (
        <div style={S.overlay} onClick={() => setShowCreateHousehold(false)}>
          <div style={{ ...S.dialog, maxWidth: 480 }} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Create New Household & Assign</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 12, fontSize: 13 }}>
                Create a household and assign <strong>{selectedPersons.length}</strong> person{selectedPersons.length !== 1 ? 's' : ''} to it.
                The first person will be set as the primary contact.
                All members will share the household address.
              </div>

              {(() => {
                const movedPersons = selectedPersons.filter(p => {
                  const curr = households.find(h => h.memberIds.includes(p.id));
                  return !!curr;
                });
                return movedPersons.length > 0 ? (
                  <div style={{ fontSize: 12, color: '#b45309', background: '#fffbeb', border: '1px solid #fde68a', borderRadius: 6, padding: '8px 10px', marginBottom: 10 }}>
                    <strong>⚠ {movedPersons.length} person{movedPersons.length !== 1 ? 's' : ''}</strong> already belong{movedPersons.length === 1 ? 's' : ''} to a household and will be moved:
                    <div style={{ marginTop: 4 }}>
                      {movedPersons.map(p => {
                        const curr = households.find(h => h.memberIds.includes(p.id));
                        return (
                          <div key={p.id} style={{ padding: '1px 0' }}>
                            👤 {getEntryName(p)} <span style={{ color: '#92400e' }}>← currently in {curr!.name}</span>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ) : null;
              })()}

              {newHhError && <div style={{ color: colors.danger, fontSize: 12, marginBottom: 10 }}>{newHhError}</div>}

              <div style={{ marginBottom: 10 }}>
                <label style={S.label}>Household Name *</label>
                <input style={S.input} placeholder="e.g. The Smith Family"
                  value={newHhName} onChange={e => { setNewHhName(e.target.value); setNewHhError(''); }} />
              </div>

              <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Address *</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                <div style={{ position: 'relative' }} ref={addrWrapRef}>
                  <input style={S.input} placeholder="Start typing to auto-suggest..." value={newHhStreet}
                    onChange={e => setNewHhStreet(e.target.value)} />
                  {addrSuggestions.length > 0 && (
                    <div style={S.addrDropdown}>
                      {addrSuggestions.map((s, i) => (
                        <div key={i} style={S.addrItem}
                          onMouseEnter={e => (e.currentTarget.style.background = colors.hover)}
                          onMouseLeave={e => (e.currentTarget.style.background = '#fff')}
                          onClick={() => {
                            setNewHhStreet(s.street);
                            setNewHhCity(s.city);
                            setNewHhState(s.state);
                            setNewHhZip(s.zip);
                            setAddrSuggestions([]);
                          }}>
                          {s.street}, {s.city}, {s.state} {s.zip}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
                <input style={S.input} placeholder="Apt, Suite, Floor, etc. (optional)" value={newHhStreet2} onChange={e => setNewHhStreet2(e.target.value)} />
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
                  <input style={S.input} placeholder="City" value={newHhCity} onChange={e => setNewHhCity(e.target.value)} />
                  <input style={S.input} placeholder="State" value={newHhState} onChange={e => setNewHhState(e.target.value)} />
                </div>
                <input style={{ ...S.input, maxWidth: 140 }} placeholder="ZIP" value={newHhZip} onChange={e => setNewHhZip(e.target.value)} />
              </div>

              <div style={{ marginTop: 12, fontSize: 12, color: colors.textSec }}>
                <strong>Members to assign:</strong>
              </div>
              <div style={{ maxHeight: 100, overflowY: 'auto', marginTop: 4, fontSize: 13 }}>
                {selectedPersons.map((p, i) => (
                  <div key={p.id} style={{ padding: '2px 0' }}>
                    👤 {getEntryName(p)}{i === 0 && <span style={{ fontSize: 10, color: colors.primary, marginLeft: 6 }}>★ Primary</span>}
                  </div>
                ))}
              </div>
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowCreateHousehold(false)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                if (!newHhName.trim()) { setNewHhError('Household name is required.'); return; }
                if (!newHhStreet.trim()) { setNewHhError('Address is required — a household must have a shared address.'); return; }
                const newHousehold: Household = {
                  id: uuidv4(),
                  name: newHhName.trim(),
                  address: {
                    ...EMPTY_ADDR,
                    street: newHhStreet.trim(),
                    street2: newHhStreet2.trim(),
                    city: newHhCity.trim(),
                    state: newHhState.trim(),
                    zip: newHhZip.trim(),
                    label: 'Household',
                  },
                  memberIds: selectedPersons.map(p => p.id),
                  primaryContactId: selectedPersons[0]?.id || '',
                };
                setShowCreateHousehold(false);
                onCreateAndAssignHousehold(selectedPersons.map(p => p.id), newHousehold);
                onToast(`🏠 ${newHhName.trim()} created with ${selectedPersons.length} member${selectedPersons.length !== 1 ? 's' : ''}`);
              }}>Create & Assign</button>
            </div>
          </div>
        </div>
      )}

      {/* Household assign confirmation */}
      {showHouseholdConfirm && (
        <div style={S.overlay} onClick={() => setShowHouseholdConfirm(null)}>
          <div style={S.dialog} onClick={e => e.stopPropagation()}>
            <h3 style={S.dialogTitle}>🏠 Confirm Household Assignment</h3>
            <div style={S.dialogBody}>
              <div style={{ marginBottom: 10 }}>
                Assign <strong>{selectedPersons.length}</strong> person{selectedPersons.length !== 1 ? 's' : ''} to <strong>🏠 {showHouseholdConfirm.name}</strong>?
              </div>
              <div style={{ maxHeight: 150, overflowY: 'auto', marginBottom: 10, fontSize: 13 }}>
                {selectedPersons.map(p => {
                  const currentHousehold = households.find(h => h.memberIds.includes(p.id));
                  return (
                    <div key={p.id} style={{ padding: '3px 0', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <span>👤 {getEntryName(p)}</span>
                      {currentHousehold && currentHousehold.id !== showHouseholdConfirm.id && (
                        <span style={{ fontSize: 11, color: colors.textSec }}>
                          (moving from {currentHousehold.name})
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
              {selectedPersons.some(p => {
                const curr = households.find(h => h.memberIds.includes(p.id));
                return curr && curr.id !== showHouseholdConfirm.id;
              }) && (
                <div style={{ fontSize: 12, color: colors.textSec }}>
                  Persons currently in other households will be moved to the new one.
                </div>
              )}
            </div>
            <div style={S.dialogActions}>
              <button style={{ ...S.btn, ...S.btnSec }} onClick={() => setShowHouseholdConfirm(null)}>Cancel</button>
              <button style={{ ...S.btn, ...S.btnPrimary }} onClick={() => {
                const hId = showHouseholdConfirm.id;
                const hName = showHouseholdConfirm.name;
                const n = selectedPersons.length;
                setShowHouseholdConfirm(null);
                onBulkAssignHousehold(selectedPersons.map(p => p.id), hId);
                onToast(`🏠 ${n} person${n !== 1 ? 's' : ''} assigned to ${hName}`);
              }}>Assign</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

__EOF_SRC_COMPONENTS_BULKACTIONS_TSX__

cat > "$ROOT/src/components/PrintDirectory.tsx" << '__EOF_SRC_COMPONENTS_PRINTDIRECTORY_TSX__'
import React, { useState } from 'react';
import { downloadFile } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, Company, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName, getPrimary, formatPhoneDisplay } from '../utils';

export interface PrintConfig {
  includePersons: boolean;
  includeCompanies: boolean;
  includeHouseholds: boolean;
  statusFilter: 'active' | 'all';
  showPhotos: boolean;
  columns: 1 | 2;
}

interface PrintDialogProps {
  entries: DirectoryEntry[];
  households: Household[];
  images: Record<string, string>;
  onClose: () => void;
  onError: (msg: string) => void;
  onSuccess?: () => void;
}

export function PrintDialog({ entries, households, images, onClose, onError, onSuccess }: PrintDialogProps) {
  const [config, setConfig] = useState<PrintConfig>({
    includePersons: true,
    includeCompanies: true,
    includeHouseholds: false,
    statusFilter: 'active',
    showPhotos: true,
    columns: 2,
  });
  const [generating, setGenerating] = useState(false);

  const personCount = entries.filter(e => e.type === 'person' && (config.statusFilter === 'all' || (e.status || 'active') === 'active')).length;
  const companyCount = entries.filter(e => e.type === 'company' && (config.statusFilter === 'all' || (e.companyStatus || 'active') === 'active')).length;
  const householdCount = config.includeHouseholds ? households.filter(h => {
    if (config.statusFilter === 'active') {
      return h.memberIds.some(mid => {
        const p = entries.find(e => e.id === mid);
        return p && p.type === 'person' && (p.status || 'active') === 'active';
      });
    }
    return h.memberIds.length > 0;
  }).length : 0;
  const totalCount = (config.includePersons ? personCount : 0) + (config.includeCompanies ? companyCount : 0);

  const canGenerate = totalCount > 0 || householdCount > 0;

  const handleGenerate = async () => {
    if (!canGenerate) { onError('No entries to print with current settings.'); return; }
    setGenerating(true);
    try {
      await generatePrintDirectory({ entries, households, images, config });
      onClose();
      onSuccess?.();
    } catch (e: any) {
      if (e?.message && !e.message.includes('declined')) onError(e.message);
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div style={S.overlay} onClick={onClose}>
      <div style={{ ...S.dialog, maxWidth: 440 }} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🖨️ Print Directory</h3>
        <div style={S.dialogBody}>
          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Include</div>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', marginBottom: 6, fontSize: 13 }}>
              <input type="checkbox" checked={config.includePersons}
                onChange={e => setConfig(c => ({ ...c, includePersons: e.target.checked, ...(!e.target.checked && { includeHouseholds: false }) }))} />
              👤 Persons <span style={{ color: colors.textSec, fontSize: 11 }}>({personCount})</span>
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 13 }}>
              <input type="checkbox" checked={config.includeCompanies}
                onChange={e => setConfig(c => ({ ...c, includeCompanies: e.target.checked }))} />
              🏢 Companies <span style={{ color: colors.textSec, fontSize: 11 }}>({companyCount})</span>
            </label>
            <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: config.includePersons ? 'pointer' : 'not-allowed', marginTop: 6, fontSize: 13, opacity: config.includePersons ? 1 : 0.45 }}>
              <input type="checkbox" checked={config.includeHouseholds} disabled={!config.includePersons}
                onChange={e => setConfig(c => ({ ...c, includeHouseholds: e.target.checked }))} />
              🏠 Households <span style={{ color: colors.textSec, fontSize: 11 }}>({householdCount})</span>
            </label>
            {!config.includePersons && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4, marginLeft: 24 }}>
                Households require "Persons" to be included.
              </div>
            )}
            {config.includeHouseholds && config.includePersons && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4, marginLeft: 24 }}>
                Appends a family-grouped section — each household as a card with family name, shared address, and all members listed together.
              </div>
            )}
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Status Filter</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {(['active', 'all'] as const).map(opt => (
                <button key={opt} onClick={() => setConfig(c => ({ ...c, statusFilter: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.statusFilter === opt ? colors.primary : '#fff',
                    color: config.statusFilter === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.statusFilter === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt === 'active' ? '● Active Only' : '○ All Entries'}
                </button>
              ))}
            </div>
            {config.statusFilter === 'all' && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
                Includes deceased persons and closed companies (shown dimmed).
              </div>
            )}
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Profile Photos</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {([true, false] as const).map(opt => (
                <button key={String(opt)} onClick={() => setConfig(c => ({ ...c, showPhotos: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.showPhotos === opt ? colors.primary : '#fff',
                    color: config.showPhotos === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.showPhotos === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt ? '📷 Show Photos' : '🚫 No Photos'}
                </button>
              ))}
            </div>
            {!config.showPhotos && (
              <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
                Smaller file size, faster printing.
              </div>
            )}
          </div>

          <div style={{ marginBottom: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: colors.textSec, marginBottom: 6 }}>Layout</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {([1, 2] as const).map(opt => (
                <button key={opt} onClick={() => setConfig(c => ({ ...c, columns: opt }))}
                  style={{
                    ...S.btn, padding: '5px 14px', fontSize: 12,
                    background: config.columns === opt ? colors.primary : '#fff',
                    color: config.columns === opt ? '#fff' : colors.text,
                    border: `1px solid ${config.columns === opt ? colors.primary : colors.border}`,
                  }}>
                  {opt === 1 ? '▐ Single Column' : '▐▐ Two Columns'}
                </button>
              ))}
            </div>
            <div style={{ fontSize: 11, color: colors.textSec, marginTop: 4 }}>
              {config.columns === 1 ? 'Spacious layout — good for large print or wall posters.' : 'Compact layout — fits more entries per page.'}
            </div>
          </div>

          <div style={{ background: colors.accent, borderRadius: 6, padding: '8px 12px', fontSize: 12, color: colors.textSec }}>
            Preview: <strong>{totalCount}</strong> entr{totalCount === 1 ? 'y' : 'ies'}
            {config.includeHouseholds && <> + <strong>{householdCount}</strong> household{householdCount !== 1 ? 's' : ''}</>}
            {' '}will be included
            {config.showPhotos && Object.keys(images).length > 0 && <> · with photos</>}
            {' · '}{config.columns === 1 ? 'single' : 'two'}-column layout
          </div>
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onClose}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnPrimary }} onClick={handleGenerate} disabled={generating || !canGenerate}>
            {generating ? 'Generating...' : '🖨️ Download Print File'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── HTML Generation ─────────────────────────────────────────────────

interface GenerateOptions {
  entries: DirectoryEntry[];
  households: Household[];
  images: Record<string, string>;
  config: PrintConfig;
}

async function generatePrintDirectory({ entries, households, images, config }: GenerateOptions): Promise<void> {
  const sorted = [...entries]
    .filter(e => {
      if (e.type === 'person') {
        if (!config.includePersons) return false;
        if (config.statusFilter === 'active') return (e.status || 'active') === 'active';
        return (e.status || 'active') !== 'archived';
      }
      if (!config.includeCompanies) return false;
      if (config.statusFilter === 'active') return (e.companyStatus || 'active') === 'active';
      return (e.companyStatus || 'active') !== 'archived';
    })
    .sort((a, b) => getEntryName(a).toLowerCase().localeCompare(getEntryName(b).toLowerCase()));

  const persons = sorted.filter((e): e is Person => e.type === 'person');
  const companies = sorted.filter((e): e is Company => e.type === 'company');

  const getPhone = (e: DirectoryEntry) => {
    const p = getPrimary(e.phones);
    return p ? `${p.countryCode || '+1'} ${formatPhoneDisplay(p.number)}` : '';
  };
  const getEmail = (e: DirectoryEntry) => getPrimary(e.emails)?.address || '';
  const getAddr = (e: DirectoryEntry) => {
    const a = getPrimary(e.addresses);
    if (!a) return '';
    return [a.street, a.street2, a.city, a.state, a.zip].filter(Boolean).join(', ');
  };

  const colCount = config.columns;

  const entryCard = (e: DirectoryEntry) => {
    const name = getEntryName(e);
    const phone = getPhone(e);
    const email = getEmail(e);
    const addr = getAddr(e);
    const img = config.showPhotos ? images[e.id] : undefined;
    const isDeceased = e.type === 'person' && e.status === 'deceased';
    const isClosed = e.type === 'company' && e.companyStatus === 'closed';
    const inactive = isDeceased || isClosed;
    const household = e.type === 'person' ? households.find(h => h.memberIds.includes(e.id)) : null;

    return `<div class="entry${inactive ? ' inactive' : ''}">
      <div class="entry-header">
        ${img ? `<img class="avatar" src="${img}" alt="" />` : (config.showPhotos ? `<div class="avatar-placeholder">${e.type === 'person' ? '👤' : '🏢'}</div>` : '')}
        <div class="entry-name">
          <strong>${escHtml(name)}</strong>
          ${inactive ? `<span class="status">${isDeceased ? '✝ Deceased' : '🚫 Closed'}</span>` : ''}
          ${e.type === 'company' && e.industry ? `<span class="industry">${escHtml(e.industry)}</span>` : ''}
          ${household ? `<span class="household">🏠 ${escHtml(household.name)}</span>` : ''}
        </div>
      </div>
      <div class="entry-details">
        ${phone ? `<div class="detail"><span class="icon">📞</span> ${escHtml(phone)}</div>` : ''}
        ${email ? `<div class="detail"><span class="icon">✉️</span> ${escHtml(email)}</div>` : ''}
        ${addr ? `<div class="detail"><span class="icon">📍</span> ${escHtml(addr)}</div>` : ''}
      </div>
    </div>`;
  };

  // Group persons by first letter
  const letterGroups = new Map<string, Person[]>();
  for (const p of persons) {
    const letter = p.lastName.charAt(0).toUpperCase() || '#';
    if (!letterGroups.has(letter)) letterGroups.set(letter, []);
    letterGroups.get(letter)!.push(p);
  }
  const sortedLetters = Array.from(letterGroups.keys()).sort();

  // All persons for household lookups (independent of includePersons toggle)
  const allPersons = [...entries]
    .filter((e): e is Person => {
      if (e.type !== 'person') return false;
      if (config.statusFilter === 'active') return (e.status || 'active') === 'active';
      return (e.status || 'active') !== 'archived';
    })
    .sort((a, b) => `${a.lastName} ${a.firstName}`.toLowerCase().localeCompare(`${b.lastName} ${b.firstName}`.toLowerCase()));

  // Build household cards for print
  const householdSection = config.includeHouseholds ? (() => {
    const filteredHouseholds = households.filter(h => {
      if (config.statusFilter === 'active') {
        return h.memberIds.some(mid => {
          const p = allPersons.find(x => x.id === mid);
          return !!p;
        });
      }
      return h.memberIds.length > 0;
    }).sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));

    if (filteredHouseholds.length === 0) return '';

    const hhCards = filteredHouseholds.map(h => {
      const members = h.memberIds
        .map(mid => allPersons.find(p => p.id === mid))
        .filter((p): p is Person => !!p);
      const primary = members.find(m => m.id === h.primaryContactId);
      const addr = [h.address.street, h.address.street2, h.address.city, h.address.state, h.address.zip].filter(Boolean).join(', ');
      const hhImg = config.showPhotos ? images[h.id] : undefined;
      const phone = primary ? getPhone(primary) : '';
      const email = primary ? getEmail(primary) : '';

      return `<div class="hh-card">
        <div class="hh-header">
          ${hhImg ? `<img class="hh-avatar" src="${hhImg}" alt="" />` : (config.showPhotos ? `<div class="hh-avatar-placeholder">🏠</div>` : '')}
          <div>
            <div class="hh-name">${escHtml(h.name)}</div>
            ${addr ? `<div class="hh-addr">📍 ${escHtml(addr)}</div>` : ''}
            ${phone ? `<div class="hh-contact">📞 ${escHtml(phone)}</div>` : ''}
            ${email ? `<div class="hh-contact">✉️ ${escHtml(email)}</div>` : ''}
          </div>
        </div>
        <div class="hh-members">
          ${members.map(m => {
            const mImg = config.showPhotos ? images[m.id] : undefined;
            const mPhone = getPhone(m);
            const mEmail = getEmail(m);
            const isPrimary = m.id === h.primaryContactId;
            const isDeceased = m.status === 'deceased';
            return `<div class="hh-member${isDeceased ? ' inactive' : ''}">
              ${mImg ? `<img class="avatar-sm" src="${mImg}" alt="" />` : (config.showPhotos ? `<div class="avatar-sm-placeholder">👤</div>` : '')}
              <div class="hh-member-info">
                <span class="hh-member-name">${escHtml(m.firstName)} ${escHtml(m.lastName)}${isPrimary ? ' <span class="hh-primary">★ Primary</span>' : ''}${isDeceased ? ' <span class="status">✝ Deceased</span>' : ''}</span>
                ${mPhone || mEmail ? `<span class="hh-member-detail">${[mPhone, mEmail].filter(Boolean).join(' · ')}</span>` : ''}
              </div>
            </div>`;
          }).join('\n')}
        </div>
      </div>`;
    }).join('\n');

    return `
<div class="section-title" style="margin-top: 24px;">🏠 Households</div>
<div class="hh-grid">
${hhCards}
</div>`;
  })() : '';

  const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Directory — Printed ${today}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: ${colCount === 1 ? '12px' : '11px'}; color: #222; line-height: 1.4; padding: 0.5in; }
  h1 { font-size: ${colCount === 1 ? '24px' : '20px'}; text-align: center; margin-bottom: 4px; }
  .subtitle { text-align: center; color: #666; font-size: 11px; margin-bottom: 20px; }
  .section-title { font-size: ${colCount === 1 ? '16px' : '14px'}; font-weight: 700; color: #1a73e8; border-bottom: 2px solid #1a73e8; padding-bottom: 3px; margin: 16px 0 10px; page-break-after: avoid; }
  .letter-header { font-size: ${colCount === 1 ? '18px' : '16px'}; font-weight: 700; color: #333; background: #f0f4f8; padding: 4px 10px; border-radius: 4px; margin: 14px 0 8px; page-break-after: avoid; }
  .entries { column-count: ${colCount}; column-gap: 24px; }
  .entry { break-inside: avoid; border: 1px solid #e0e0e0; border-radius: 6px; padding: ${colCount === 1 ? '10px 14px' : '8px 10px'}; margin-bottom: ${colCount === 1 ? '10px' : '8px'}; background: #fff; }
  .entry.inactive { opacity: 0.6; border-left: 3px solid #9e9e9e; }
  .entry-header { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
  .avatar { width: ${colCount === 1 ? '36px' : '32px'}; height: ${colCount === 1 ? '36px' : '32px'}; border-radius: 50%; object-fit: cover; flex-shrink: 0; }
  .avatar-placeholder { width: ${colCount === 1 ? '36px' : '32px'}; height: ${colCount === 1 ? '36px' : '32px'}; border-radius: 50%; background: #f0f0f0; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0; }
  .entry-name { display: flex; flex-wrap: wrap; align-items: baseline; gap: 4px; }
  .entry-name strong { font-size: ${colCount === 1 ? '14px' : '12px'}; }
  .status { font-size: 9px; color: #666; background: #eee; padding: 1px 5px; border-radius: 8px; }
  .industry { font-size: 9px; color: #5f6368; }
  .household { font-size: 9px; color: #1a73e8; }
  .entry-details { ${config.showPhotos ? `padding-left: ${colCount === 1 ? '44px' : '40px'};` : ''} }
  .detail { margin-bottom: 2px; color: #444; }
  .icon { display: inline-block; width: 14px; text-align: center; }
  .stats { text-align: center; color: #666; font-size: 10px; margin-top: 16px; padding-top: 10px; border-top: 1px solid #ddd; }
  @media print {
    body { padding: 0.3in; }
    .entry { border-color: #ccc; }
    .no-print { display: none; }
  }
  .print-btn { display: block; margin: 0 auto 20px; padding: 10px 24px; font-size: 14px; font-weight: 600; background: #1a73e8; color: #fff; border: none; border-radius: 6px; cursor: pointer; }
  .print-btn:hover { background: #1558b0; }
  .hh-grid { column-count: ${colCount}; column-gap: 24px; }
  .hh-card { break-inside: avoid; border: 1px solid #d0d7de; border-radius: 8px; padding: ${colCount === 1 ? '14px 16px' : '10px 12px'}; margin-bottom: ${colCount === 1 ? '12px' : '10px'}; background: #fafcff; }
  .hh-header { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 8px; padding-bottom: 8px; border-bottom: 1px solid #e8ecf0; }
  .hh-avatar { width: ${colCount === 1 ? '44px' : '38px'}; height: ${colCount === 1 ? '44px' : '38px'}; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
  .hh-avatar-placeholder { width: ${colCount === 1 ? '44px' : '38px'}; height: ${colCount === 1 ? '44px' : '38px'}; border-radius: 8px; background: #e8f0fe; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
  .hh-name { font-size: ${colCount === 1 ? '15px' : '13px'}; font-weight: 700; color: #1a73e8; }
  .hh-addr { font-size: ${colCount === 1 ? '11px' : '10px'}; color: #555; margin-top: 2px; }
  .hh-contact { font-size: ${colCount === 1 ? '11px' : '10px'}; color: #555; margin-top: 1px; }
  .hh-members { display: flex; flex-direction: column; gap: 5px; }
  .hh-member { display: flex; align-items: center; gap: 8px; padding: 4px 0; }
  .hh-member.inactive { opacity: 0.55; }
  .avatar-sm { width: ${colCount === 1 ? '26px' : '22px'}; height: ${colCount === 1 ? '26px' : '22px'}; border-radius: 50%; object-fit: cover; flex-shrink: 0; }
  .avatar-sm-placeholder { width: ${colCount === 1 ? '26px' : '22px'}; height: ${colCount === 1 ? '26px' : '22px'}; border-radius: 50%; background: #f0f0f0; display: flex; align-items: center; justify-content: center; font-size: 10px; flex-shrink: 0; }
  .hh-member-info { display: flex; flex-direction: column; }
  .hh-member-name { font-size: ${colCount === 1 ? '12px' : '11px'}; font-weight: 500; }
  .hh-member-detail { font-size: ${colCount === 1 ? '10px' : '9px'}; color: #666; }
  .hh-primary { font-size: 9px; color: #1b7a15; font-weight: 600; }
</style>
</head>
<body>
<button class="print-btn no-print" onclick="window.print()">🖨️ Print This Directory</button>

<h1>📒 Directory</h1>
<div class="subtitle">Printed on ${escHtml(today)} · ${persons.length} person${persons.length !== 1 ? 's' : ''}${companies.length > 0 ? `, ${companies.length} compan${companies.length !== 1 ? 'ies' : 'y'}` : ''}${config.includeHouseholds && households.length > 0 ? `, ${households.length} household${households.length !== 1 ? 's' : ''}` : ''}</div>

${persons.length > 0 ? `
<div class="section-title">👤 Persons</div>
${sortedLetters.map(letter => `
<div class="letter-header">${escHtml(letter)}</div>
<div class="entries">
${letterGroups.get(letter)!.map(p => entryCard(p)).join('\n')}
</div>
`).join('\n')}
` : ''}

${companies.length > 0 ? `
<div class="section-title" style="margin-top: 24px;">🏢 Companies</div>
<div class="entries">
${companies.map(c => entryCard(c)).join('\n')}
</div>
` : ''}

${householdSection}

<div class="stats">
  ${persons.length} person${persons.length !== 1 ? 's' : ''}${companies.length > 0 ? ` · ${companies.length} compan${companies.length !== 1 ? 'ies' : 'y'}` : ''} · ${households.length} household${households.length !== 1 ? 's' : ''}
</div>

</body>
</html>`;

  await downloadFile('directory-print.html', new Blob([html], { type: 'text/html' }));
}

function escHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

__EOF_SRC_COMPONENTS_PRINTDIRECTORY_TSX__

cat > "$ROOT/src/components/DeleteDialogs.tsx" << '__EOF_SRC_COMPONENTS_DELETEDIALOGS_TSX__'
import React from 'react';
import type { DirectoryEntry, Person, Household } from '../types';
import { S, colors } from '../styles';
import { getEntryName } from '../utils';

interface DeleteDialogProps {
  target: DirectoryEntry;
  allPersons: Person[];
  entries: DirectoryEntry[];
  onCancel: () => void;
  onConfirm: () => void;
}

export function DeleteDialog({ target, allPersons, entries, onCancel, onConfirm }: DeleteDialogProps) {
  const resolveName = (id: string) => { const e = entries.find(x => x.id === id); return e ? getEntryName(e) : 'Unknown'; };
  const cascadeEffects: string[] = [];
  if (target.type === 'person') {
    if (target.spouseId) cascadeEffects.push(`Unlink spouse ${resolveName(target.spouseId)}`);
    const parents = allPersons.filter(p => p.id !== target.id && p.childIds.includes(target.id));
    if (parents.length > 0) cascadeEffects.push(`Remove as child from ${parents.map(p => getEntryName(p)).join(', ')}`);
    const linkedCompanies = entries.filter(e => e.type === 'company' && e.contactPersonIds.includes(target.id));
    if (linkedCompanies.length > 0) cascadeEffects.push(`Remove as contact from ${linkedCompanies.map(c => getEntryName(c)).join(', ')}`);
  }
  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={S.dialog} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🗑️ Delete {target.type === 'person' ? 'Person' : 'Company'}</h3>
        <div style={S.dialogBody}>
          Are you sure you want to delete <strong>{getEntryName(target)}</strong>?
          {cascadeEffects.length > 0 && <ul style={{ margin: '8px 0', paddingLeft: 20, fontSize: 13, color: colors.textSec }}>{cascadeEffects.map((eff, i) => <li key={i}>{eff}</li>)}</ul>}
          {' '}This action cannot be undone.
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnDanger }} onClick={onConfirm}>Delete</button>
        </div>
      </div>
    </div>
  );
}

interface DeleteAllDialogProps {
  entryCount: number;
  householdCount: number;
  onCancel: () => void;
  onConfirm: () => void;
}

export function DeleteAllDialog({ entryCount, householdCount, onCancel, onConfirm }: DeleteAllDialogProps) {
  return (
    <div style={S.overlay} onClick={onCancel}>
      <div style={S.dialog} onClick={e => e.stopPropagation()}>
        <h3 style={S.dialogTitle}>🗑️ Delete All Entries</h3>
        <div style={S.dialogBody}>
          Are you sure you want to delete <strong>all {entryCount} entr{entryCount === 1 ? 'y' : 'ies'}</strong>
          {householdCount > 0 && <> and <strong>{householdCount} household{householdCount === 1 ? '' : 's'}</strong></>}
          ? This action cannot be undone.
        </div>
        <div style={S.dialogActions}>
          <button style={{ ...S.btn, ...S.btnSec }} onClick={onCancel}>Cancel</button>
          <button style={{ ...S.btn, ...S.btnDanger }} onClick={onConfirm}>Delete All</button>
        </div>
      </div>
    </div>
  );
}

__EOF_SRC_COMPONENTS_DELETEDIALOGS_TSX__

cat > "$ROOT/src/components/Toast.tsx" << '__EOF_SRC_COMPONENTS_TOAST_TSX__'
import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { colors } from '../styles';

export type ToastType = 'success' | 'error' | 'info';

interface Toast {
  id: string;
  message: string;
  type: ToastType;
}

interface ToastContextValue {
  addToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextValue>({ addToast: () => {} });
export const useToast = () => useContext(ToastContext);

let _nextId = 0;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const timers = useRef<Record<string, number>>({});

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id));
    delete timers.current[id];
  }, []);

  const addToast = useCallback((message: string, type: ToastType = 'success') => {
    const id = `toast-${++_nextId}`;
    setToasts(prev => [...prev, { id, message, type }]);
    if (type !== 'error') {
      timers.current[id] = window.setTimeout(() => removeToast(id), 4000);
    }
  }, [removeToast]);

  // Cleanup timers on unmount
  useEffect(() => {
    return () => { Object.values(timers.current).forEach(t => clearTimeout(t)); };
  }, []);

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      {toasts.length > 0 && (
        <div style={{
          position: 'fixed', top: 70, right: 20, zIndex: 200,
          display: 'flex', flexDirection: 'column', gap: 8, maxWidth: 380,
          pointerEvents: 'none',
        }}>
          {toasts.map(t => (
            <ToastItem key={t.id} toast={t} onDismiss={() => {
              if (timers.current[t.id]) clearTimeout(timers.current[t.id]);
              removeToast(t.id);
            }} />
          ))}
        </div>
      )}
    </ToastContext.Provider>
  );
}

function ToastItem({ toast, onDismiss }: { toast: Toast; onDismiss: () => void }) {
  const [visible, setVisible] = useState(false);
  useEffect(() => { requestAnimationFrame(() => setVisible(true)); }, []);

  const bgColor = toast.type === 'error' ? '#fce8e6' : toast.type === 'info' ? '#e8f0fe' : '#e6f4ea';
  const borderColor = toast.type === 'error' ? colors.danger : toast.type === 'info' ? colors.primary : '#1b7a15';
  const textColor = toast.type === 'error' ? colors.danger : toast.type === 'info' ? colors.primary : '#1b7a15';

  return (
    <div style={{
      pointerEvents: 'auto',
      background: bgColor, borderLeft: `4px solid ${borderColor}`,
      borderRadius: 8, padding: '10px 14px', boxShadow: '0 4px 16px rgba(0,0,0,.15)',
      display: 'flex', alignItems: 'flex-start', gap: 10,
      opacity: visible ? 1 : 0, transform: visible ? 'translateX(0)' : 'translateX(40px)',
      transition: 'opacity .25s ease, transform .25s ease',
    }}>
      <div style={{ flex: 1, fontSize: 13, lineHeight: 1.45, color: textColor, fontWeight: 500 }}>
        {toast.message}
      </div>
      <button onClick={onDismiss} style={{
        border: 'none', background: 'none', cursor: 'pointer', fontSize: 16,
        color: textColor, opacity: 0.6, padding: 0, lineHeight: 1, flexShrink: 0, marginTop: 1,
      }} title="Dismiss">×</button>
    </div>
  );
}

__EOF_SRC_COMPONENTS_TOAST_TSX__

cat > "$ROOT/src/components/QuickAddRelative.tsx" << '__EOF_SRC_COMPONENTS_QUICKADDRELATIVE_TSX__'
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
  editPerson?: Person | null;
  onCreated: (person: Person) => void;
  onCancel: () => void;
}

export function QuickAddRelativeDialog({ mode, currentGender, defaultLastName, editPerson, onCreated, onCancel }: QuickAddRelativeProps) {
  const isEdit = !!editPerson;
  const [firstName, setFirstName] = useState(editPerson?.firstName || '');
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
          {!isEdit && mode === 'spouse' && currentGender && gender && (
            <div style={{ fontSize: 11, color: colors.textSec, marginTop: 3 }}>
              Defaulted to {gender} (opposite of {currentGender})
            </div>
          )}
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

__EOF_SRC_COMPONENTS_QUICKADDRELATIVE_TSX__

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

---

## Session 27 — Cancel Form Clears Validation Error

### Problem
When opening the "Add Person" or "Add Company" form, entering invalid data (e.g., an address missing city or state), and then clicking "Cancel," the validation error message ("Please complete all addresses — at least city and state are required.") would persist and display on the list view. Since the user canceled the action, no error message should be shown.

### Solution
Added `setError('')` to the Cancel button click handlers in both the Person and Company forms.

#### Changes to `App.tsx`
- **Person form Cancel button**: Changed from `{ resetPersonForm(); setView('list'); }` to `{ resetPersonForm(); setError(''); setView('list'); }`
- **Company form Cancel button**: Changed from `{ resetCompanyForm(); setView('list'); }` to `{ resetCompanyForm(); setError(''); setView('list'); }`

---

## Session 28 — Form Validation Prevents Saving Invalid Emails & Phone Numbers

### Problem
The EmailInput and PhoneInput components showed inline validation errors (red border + message) when a value was invalid, but these were purely informational. The form could still be submitted with invalid values, resulting in malformed data stored in the directory.

### Solution
Added validation checks in both `savePerson` and `saveCompany` that block form submission if any email or phone field contains an invalid value.

#### New Utility Functions Added to `utils.ts`
| Function | Logic |
|----------|-------|
| `isValidEmail(address)` | Returns `true` if empty (will be filtered out) or matches `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` |
| `isValidPhone(number)` | Returns `true` if empty (will be filtered out) or contains only valid characters (`0-9`, spaces, dashes, parens, dots, plus) AND has at least 7 digits |

These mirror the exact validation logic used in the `EmailInput` and `PhoneInput` components.

#### Changes to `App.tsx`
- Imported `isValidEmail` and `isValidPhone` from `./utils`
- **`savePerson`**: Added checks after name/gender validation:
  - If any email has an invalid address → error: "Please fix invalid email addresses before saving."
  - If any phone has an invalid number → error: "Please fix invalid phone numbers before saving."
- **`saveCompany`**: Added the same checks after name validation

#### Validation Order (both forms)
1. Required fields (name, gender for persons)
2. Email validation
3. Phone validation
4. Address completeness (city + state required)
5. Website URL validation (company only)

---

## Session 29 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 27–29 reflecting the latest conversation history

---

## Session 30 — Auto-Scroll to Error on Failed Form Validation

### Problem
When a form validation check fails (e.g., missing required fields, invalid email/phone, incomplete address), the error message appears at the top of the content area. If the user has scrolled down to the bottom of a long form, they won't see the error message without manually scrolling back up.

### Solution
Added automatic smooth scrolling to the error message when validation fails, ensuring the user immediately sees what needs to be fixed.

### Changes to `App.tsx`
- Added `errorRef` (`useRef<HTMLDivElement>`) attached to the error message div
- Created `setErrorAndScroll(msg)` helper that sets the error message and then uses `scrollIntoView({ behavior: 'smooth', block: 'nearest' })` to scroll the error into view (via `setTimeout` to ensure the DOM has rendered)
- Replaced `setError(...)` with `setErrorAndScroll(...)` in all validation checks within:
  - `savePerson`: name, gender, email, phone, and address validation
  - `saveCompany`: name, email, phone, address, and website validation
- Added `ref={errorRef}` to the error display div

---

## Session 31 — Phone Validation on Blur

### Action
Created a new `PhoneInput` component at `webapp/src/components/PhoneInput.tsx` that validates phone numbers when the user leaves the field (on blur), mirroring the pattern established by `EmailInput`.

### Validation Rules
- Only valid characters allowed: digits, spaces, dashes, parentheses, dots, plus signs
- Minimum 7 digits required

### Behavior
- Shows red error message "Please enter a valid phone number" below the field when validation fails
- Input border turns red to highlight validation issues
- Error clears automatically when user starts typing again
- Integrates `CountryCodeSelect` dropdown directly within the component

### Changes
- Created `webapp/src/components/PhoneInput.tsx`
- Integrated into both person and company phone fields in `App.tsx`
- Removed now-unused direct `CountryCodeSelect` import from `App.tsx`
- Added PhoneInput source to the code export feature

---

## Session 32 — Household Chip Remove Error Management

### Problem
When removing a member using the "×" button on their chip in the Household form:
- Dropping below 2 members didn't show the `hhMembers` validation error
- Removing the primary contact auto-reassigned primary to the first remaining member, but didn't clear the `hhPrimary` error if it was previously set

### Solution
Added symmetric error management to the chip remove handler in `HouseholdView.tsx`.

### Changes to `components/HouseholdView.tsx`
- **Shows `hhMembers` error** when removing a member drops the count below 2
- **Clears `hhMembers` error** if the count is still ≥ 2 after removal
- **Clears `hhPrimary` error** when the primary contact is auto-reassigned to a valid remaining member
- **Shows `hhPrimary` error** if all members are removed and no primary can be assigned
- Uses `setFieldErrors` with a functional update to compute the effective primary based on whether the removed member was the current primary

---

## Session 33 — Spouse & Children Picker Relationship Filters

### Part 1: Spouse Picker — Opposite Sex Filter
Added a `currentGender` prop to `SpousePicker` to filter candidates to only persons of the opposite sex, enforcing that married couples must be male/female.

#### Changes to `components/SpousePicker.tsx`
- Added `currentGender: string` to `SpousePickerProps` interface
- In the eligible filter, added: if both the current person and a candidate have a gender set and they match, the candidate is excluded
- If either person's gender is unset (empty string), no gender filtering is applied (allows picking a spouse when gender hasn't been specified)

#### Changes to `App.tsx`
- Passed `currentGender={pGender}` to the `SpousePicker` component

### Part 2: Children Picker — Exclude Parents
Added an explicit parent check to the children picker filter to prevent a person's parent from being listed as a potential child.

#### Changes to `App.tsx`
- Added: `if (editId && p.childIds.includes(editId)) return false;` — directly excludes any person who already has the current person listed as their child
- This complements the existing `getAncestorIds` cycle detection with a clear, direct parent check

---

## Session 34 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 31–34 reflecting the latest conversation history

---

## Session 35 — Profile Image Upload Feature

### Action
Added the ability for persons, companies, and households to upload a profile image that replaces the default emoji badge in list and detail views.

### New Components Created

#### `components/ProfileImage.tsx`
A reusable circular avatar component:
- Displays either an uploaded image or a fallback emoji (👤, 🏢, 🏠)
- **Editable mode**: Shows a camera overlay on hover and a remove (×) button when an image exists
- Clicking the avatar opens a file picker for image selection
- Uses `data:` URLs compatible with the CSP (`img-src data: blob:`)

#### `components/ImageCropper.tsx`
An interactive circular crop overlay modal:
- **Circular crop preview** — 240px circular window with a blue border shows exactly how the photo will appear
- **Drag to pan** — Click and drag to reposition the image (uses Pointer Events for mouse and touch)
- **Zoom control** — Mouse wheel/trackpad scroll on the crop area, plus a slider with − and + labels
- **Zoom range** — 1× (image fills the circle) to 4× magnification
- **Boundary clamping** — Image can't be dragged beyond its edges
- **Confirm/Cancel buttons** — Renders final 200×200px JPEG crop; compresses progressively to stay under 300KB
- Appears automatically when an image file is selected

### Storage

#### New Table: `directory-images`
- Added `IMAGES_TABLE` constant to `types.ts`
- Added CRUD functions to `storage.ts`: `saveImage`, `loadImage`, `loadAllImages`, `removeImage`
- Images stored as base64 data URLs (max ~300KB each)
- Images loaded in bulk on app mount alongside entries and households
- Images cleaned up when entries/households are deleted (including "Delete All")

### Integration Points
1. **List view** — Profile images replace emoji badges next to each entry name (36px)
2. **Detail view** — Larger (64px) profile image replaces the large emoji at the top
3. **Search dropdown** — Small (24px) profile images next to search results
4. **Person form** — Image upload widget at the top of the form (72px, editable)
5. **Company form** — Image upload widget at the top of the form (72px, editable)
6. **Household cards** — Profile images on household list cards (36px)
7. **Household form** — Image upload widget at the top of the form (72px, editable)

### Changes to `App.tsx`
- Added `images` state (`Record<string, string>`)
- Added `pImage` and `cImage` form state for person/company image editing
- Updated `reload` to also call `loadAllImages()`
- Updated `fillPersonForm` / `fillCompanyForm` to load existing images
- Updated `savePerson` / `saveCompany` to save/remove images
- Updated `confirmDelete` / `handleDeleteAll` to also remove images
- Replaced emoji badges with `<ProfileImage>` in list, detail, and search views
- Added `?raw` imports for `ProfileImage.tsx` and `ImageCropper.tsx` for code export

### Changes to `components/HouseholdView.tsx`
- Added `images` prop to `HouseholdViewProps`
- Added `hhImage` state for household image editing
- Profile image upload in household form
- Profile images on household list cards
- Image save/remove on household save/delete

---

## Session 36 — Image Export/Import as Separate JSON File

### Problem
The CSV export did not include profile images from the `directory-images` table.

### Solution
Added a separate JSON file export for images alongside the CSV, keeping the CSV lightweight and human-readable while providing a complete backup/restore path.

### Export Behavior (📥 Export CSV button)
1. **`directory-export.csv`** — Existing CSV with entries and households (unchanged)
2. **`directory-images.json`** — New JSON file with all profile images as `{ "entity-id": "data:image/jpeg;base64,..." }`. Only downloaded if images exist.

### Import Behavior (📤 Import CSV button)
File picker now accepts both `.csv` and `.json` files:
- **`.csv` files** — Imported as before (entries + households via preview flow)
- **`.json` files** — Recognized as images backup; parses JSON and saves each image to storage. Shows success toast with count.

### Changes to `App.tsx`
- Updated `handleExportCsv` to also download `directory-images.json` when images exist
- Updated `handleFileSelect` to detect `.json` files and import images directly
- Changed file input `accept` attribute from `.csv` to `.csv,.json`

---

## Session 37 — Image Cropper Enhancement (Interactive Circular Crop)

### Action
Replaced the automatic center-crop with an interactive cropper that gives users full control over how their photo appears.

### Flow
1. User clicks the profile image avatar → file picker opens
2. User selects an image → the **ImageCropper** modal appears with the full image loaded
3. User drags to reposition and zooms to frame their subject within the circular preview
4. User clicks **Confirm** → cropped 200×200px JPEG result is set as the profile image
5. Clicking **Cancel** or the backdrop dismisses without changes

### Technical Details
- Crop preview area: 240px diameter circle with blue border
- Output: 200×200px JPEG, progressively compressed to stay under 300KB
- Zoom: 1× to 4×, controllable via mouse wheel or range slider
- Pan: Pointer events for cross-device support (mouse + touch)
- Boundary clamping prevents blank areas in the crop

---

## Session 38 — Explicit `imageId` Column for CSV-to-JSON Linking

### Problem
The relationship between `directory-export.csv` and `directory-images.json` was implicit (both used entity IDs as keys). If CSV entries got new UUIDs during import (without `_json` column), image associations would be lost.

### Solution
Added an explicit `imageId` column to both entry and household CSV sections that references the key in the images JSON.

### Changes to `storage.ts`

**Entry CSV:**
- Added `imageId` to `CSV_HEADERS` array
- Updated `entryToCsvRow` to accept `images` parameter and populate `imageId` (entity ID if image exists, empty otherwise)
- Updated `exportCsv` signature to accept `images`

**Household CSV:**
- Added `imageId` to `HOUSEHOLD_CSV_HEADERS` array
- Updated `householdToCsvRow` to accept `images` parameter and populate `imageId`
- Updated `exportHouseholdsCsv` signature to accept `images`

**Full CSV Export:**
- Updated `exportFullCsv` to accept and pass `images` through to both export functions

**CSV Import:**
- Updated `parseCsvFile` return type to include `imageIdMap: Record<string, string>` (maps new entry ID → original imageId)
- Extracts `imageId` from each CSV row during parsing
- Returns the mapping for use during import confirmation

### Changes to `App.tsx`
- Passes `images` to `exportFullCsv(entries, households, images)`
- Added `importImageIdMap` state
- Updated `handleFileSelect` to capture `imageIdMap` from parsed CSV
- Updated `handleImportConfirm` to re-link images: when an imported entry has an `imageId` pointing to an existing image in storage, the image is copied to the new entry's ID
- Updated `handleImportCancel` to clear `importImageIdMap`

### Import Workflow for Full Restore
1. Import `directory-images.json` first → images loaded into storage
2. Import `directory-export.csv` → entries parsed with `imageId` references
3. On confirm → images automatically re-linked to new entries via `imageId` mapping

---

## Session 39 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 35–39 reflecting the latest conversation history

---

## Session 40 — Profile Image Remove Button Clipping Fix

### Problem
On the edit forms for person, company, and household, the profile image displayed a small red crescent in the top-right corner of the circle. This was the "remove photo" button (×) being clipped by the container's `overflow: hidden` into a crescent shape. In non-editable views (list and detail), the button doesn't render, so no crescent appeared.

### Root Cause
The remove button was absolutely positioned at `top: -2, right: -2` **inside** the circular container that has `overflow: hidden`. The container clipped the button, showing only the portion that fell within the circle boundary — creating the crescent artifact.

### Solution
Moved the remove button **outside** the clipped container by adding an outer wrapper div.

#### Changes to `components/ProfileImage.tsx`
- Added an outer wrapper `<div>` with `position: relative`, matching the avatar's `width` and `height`
- The circular container (with `overflow: hidden`) remains unchanged inside the wrapper
- The remove button is now a sibling of the circular container, positioned absolutely within the outer wrapper
- Added `zIndex: 1` to the remove button to ensure it renders above the avatar
- The button is no longer subject to `overflow: hidden` clipping

### Structure (before → after)
**Before:**
```
<div style={containerStyle (overflow: hidden, borderRadius: 50%)}>
  <img ... />
  <button (remove) /> ← CLIPPED by parent's overflow
</div>
```

**After:**
```
<div style={outerWrapper (position: relative)}>
  <div style={containerStyle (overflow: hidden, borderRadius: 50%)}>
    <img ... />
  </div>
  <button (remove) /> ← NOT clipped, positioned relative to outer wrapper
</div>
```

---

## Session 41 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 40–41 reflecting the latest conversation history

---

## Session 42 — Pagination Controls on Directory List View

### Action
Added pagination controls to the main directory list view to improve performance and usability as the directory grows.

### State Added to `App.tsx`
- `pageSize` — Number of entries per page (default: 25, options: 25/50/100)
- `currentPage` — Current page number (1-based)

### Computed Values
- `totalEntries` — Total number of filtered entries
- `totalPages` — Calculated from total entries / page size
- `safeCurrentPage` — Clamped to valid range (handles edge cases when filters reduce results)
- `pageStart` / `pageEnd` — Slice indices for the current page
- `paginatedEntries` — The subset of entries displayed on the current page

### Auto-Reset
- Page resets to 1 automatically when search query, type filter, industry filter, sort field, or sort direction changes (via `useEffect`)

### UI Controls
1. **Top bar** — Shows "Showing 1–25 of 142 entries" with per-page size buttons (25/50/100), highlighted active size
2. **Bottom navigation** — Shows « ‹ Page X of Y › » buttons:
   - First page («) and last page (») jump buttons
   - Previous (‹) and next (›) buttons
   - All buttons disabled appropriately at boundaries
   - Only appears when there are multiple pages

### Changes to `App.tsx`
- Added `pageSize` and `currentPage` state
- Added `useEffect` to reset page on filter/sort/search changes
- Added pagination computed values after `filteredEntries`
- Replaced `filteredEntries.map(...)` with `paginatedEntries.map(...)`
- Added pagination info bar above the cards
- Added pagination navigation below the cards

---

## Session 43 — Pagination Controls on Households List View

### Action
Added the same pagination controls to the Households list view for consistency.

### Changes to `components/HouseholdView.tsx`
- Added `pageSize` and `currentPage` state (default: 25)
- Added pagination computed values: `totalHouseholds`, `totalPages`, `safeCurrentPage`, `pageStart`, `pageEnd`, `paginatedHouseholds`
- Replaced `households.map(...)` with `paginatedHouseholds.map(...)`
- Added pagination info bar: "Showing 1–25 of X households" with per-page buttons (25/50/100)
- Added bottom navigation: « ‹ Page X of Y › » (only shown when multiple pages exist)

---

## Session 44 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 42–44 reflecting the latest conversation history

---

## Session 45 — Family Tree Visualization

### Action
Added a visual family tree/graph to the person detail view that displays parent-child, spouse, and sibling relationships at a glance.

### New Component: `components/FamilyTree.tsx`
An SVG-based tree visualization with three rows:

| Row | Content | Color |
|-----|---------|-------|
| Top | Parents (persons whose `childIds` include this person) | Purple |
| Middle | Self + Spouse + Siblings | Blue (self), Pink (spouse), Gray (siblings) |
| Bottom | Children | Green |

### Features
- **Color-coded nodes** — Each role has a distinct background and border color
- **Profile images** — Circular profile photos in each node (fallback to 👤 emoji)
- **Connecting lines** — Solid lines for direct relationships, dashed for indirect
- **Interactive** — Clicking any node (except self) navigates to that person's detail view
- **Siblings auto-detected** — Found by looking at other children of the same parents
- **Responsive** — Horizontally scrollable when tree is wider than viewport
- **Legend** — Compact color legend below the tree
- **Graceful fallback** — Shows "No family relationships to display" when no relationships exist

### Layout
- Nodes: 100×72px with 20px horizontal and 50px vertical gaps
- Each row centered horizontally, SVG width/height adjusts dynamically

### Integration
- Added `FamilyTree` import and render in App.tsx detail view under "Family Tree" section
- Added `?raw` import and code export entry for `FamilyTree.tsx`

---

## Session 46 — Multi-Generation Family Tree Expansion

### Action
Enhanced the Family Tree component to support multi-generation expansion with interactive "+" buttons on expandable nodes.

### New Features

**Expand/Collapse Nodes:**
- Parent nodes with their own parents show a **+** button above them — clicking reveals grandparents
- Child nodes with their own children show a **+** button below them — clicking reveals grandchildren
- Clicking **−** collapses an expanded node
- Expansion state tracked per-node via `expandedIds` state (Set)

**New Roles Added:**
| Role | Color | Description |
|------|-------|-------------|
| Grandparent+ | Dark purple (`#4a148c`, bg `#ede7f6`) | Any ancestor beyond direct parents |
| Grandchild+ | Dark green (`#1b5e20`, bg `#c8e6c9`) | Any descendant beyond direct children |

**Recursive Expansion:**
- Tree grows dynamically: expanding a grandparent reveals great-grandparents, and so on
- Same for descendants: expanding a grandchild reveals great-grandchildren
- No depth limit — follows the data as deep as relationships exist
- Each expanded level adds a new row to the SVG

**Visual Indicators:**
- **+** circle on nodes with further generations to reveal (positioned above ancestors, below descendants)
- **−** circle on already-expanded nodes (click to collapse)
- Dashed lines connect expanded generations to distinguish from direct relationships

**Technical Implementation:**
- `expandedIds` state (Set<string>) tracks which nodes are expanded
- `getParents` and `getChildren` helper functions for traversal
- Ancestor rows built by recursively expanding upward from parents
- Descendant rows built by recursively expanding downward from children
- `parentLinkIds` on each expanded row item tracks which node it connects back to
- SVG height dynamically adjusts based on number of visible rows
- `ROLE_COLORS` lookup table for consistent styling across all 7 role types

**Updated Legend:**
- Added "Grandparent+" and "Grandchild+" entries
- Added helper text: "Click + on a node to expand further generations. Click a name to navigate."

### Changes to `components/FamilyTree.tsx`
- Complete rewrite from static 3-row layout to dynamic multi-row expandable tree
- Added `useState` for `expandedIds`, `useCallback` for `toggleExpand`, `getParents`, `getChildren`
- `PersonNode` component now accepts `onToggleExpand` prop and renders +/− button when `expandable`
- `useMemo` recalculates layout whenever `expandedIds` changes

---

## Session 47 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 45–47 reflecting the latest conversation history

---

## Session 48 — Collapsible Detail View Sections

### Action
Added expand/collapse toggles to each section in the detail view with per-user persistence via private storage.

### New Component: `components/CollapsibleSection.tsx`

**`CollapsibleSection`** — A wrapper component that renders a section header with a ▶/▼ toggle indicator. Clicking the header expands or collapses the section content.

**`useCollapsedSections` hook** — Manages which sections are collapsed:
- Loads collapsed section IDs from private storage (`user-preferences` table, key `detail-collapsed-sections`) on first mount
- Caches in memory to avoid redundant API calls across re-renders
- Saves updated state back to private storage whenever a section is toggled
- Per-user persistence — each user's collapsed preferences are independent (uses `putPrivateItem`/`getPrivateItem`)

### Sections Made Collapsible

| Section ID | Title | Applies To |
|------------|-------|-----------|
| `website` | Website | Companies |
| `personal-info` | Personal Information | Persons |
| `emails` | Email Addresses | Both |
| `phones` | Phone Numbers | Both |
| `addresses` | Addresses | Both |
| `relationships` | Relationships | Persons |
| `family-tree` | Family Tree | Persons |
| `household` | Household | Persons |
| `contact-persons` | Contact Persons | Companies |
| `notes` | Notes | Both |

### Behavior
- All sections start **expanded** by default (first-time users see everything)
- Clicking a section header toggles between expanded (▼) and collapsed (▶)
- Collapsed state persists across sessions via private storage
- No content is rendered when collapsed (improves performance for heavy sections like Family Tree)
- Section header styling matches existing `S.section` style with added cursor pointer and flex layout

### Changes to `App.tsx`
- Imported `CollapsibleSection` and `useCollapsedSections` from new component
- Added `useCollapsedSections()` hook call near other state declarations
- Wrapped all detail view sections with `<CollapsibleSection>` passing unique `id`, `title`, `collapsed` state, and `onToggle` handler
- Added `?raw` import and code export entry for `CollapsibleSection.tsx`

### Storage
- Table: `user-preferences` (private)
- Key: `detail-collapsed-sections`
- Value: JSON array of collapsed section IDs (e.g., `["family-tree", "notes"]`)

---

## Session 49 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 48–49 reflecting the latest conversation history

---

## Current File Structure

```
webapp/src/
├── App.tsx                          # Main orchestrator component
├── types.ts                         # Interfaces, type aliases, constants
├── styles.ts                        # Colors and style definitions
├── utils.ts                         # Utility functions and custom hooks
├── storage.ts                       # Storage operations, CSV helpers, image CRUD
├── countryCodes.ts                  # Country code data
├── usStates.ts                      # US states data
├── main.tsx                         # React entry point
├── vite-env.d.ts                    # Vite type declarations
├── DEVLOG.md                        # This development log
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── CountryCodeSelect.tsx        # Country code dropdown
│   ├── RelationshipPicker.tsx       # Relationship selection
│   ├── SpousePicker.tsx             # Spouse selection with eligibility filtering
│   ├── HouseholdPicker.tsx          # Household member management
│   ├── HouseholdView.tsx            # Household CRUD view
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   ├── Toolbar.tsx                  # Sort/filter toolbar
│   ├── EmailInput.tsx               # Email input with blur validation
│   ├── PhoneInput.tsx               # Phone input with blur validation
│   ├── ProfileImage.tsx             # Profile image avatar with upload
│   └── ImageCropper.tsx             # Interactive circular crop overlay
└── assets/
    ├── dashboard-placeholder-chart-icon.svg
    └── dashboard-placeholder-error-icon.svg
```

## Registered Integrations
- **AI Inference** (`ai-inference`): Used for address auto-suggest functionality (Claude Haiku model)

## Storage Tables
| Table Name | Purpose | Key |
|------------|---------|-----|
| `directory-entries` | Persons and companies | Entity UUID |
| `directory-households` | Household groups | Household UUID |
| `directory-images` | Profile images (base64 data URLs) | Entity/Household UUID |
| `user-preferences` (private) | Collapsed section state per user | `detail-collapsed-sections` |

---

## Session 50 — Address Line 2 Field Added

### Action
Added an optional "Address Line 2" field to all address forms across the application, allowing users to capture apartment numbers, suite numbers, floor numbers, and similar secondary address information.

### Changes

#### `types.ts`
- Added `street2: string` to the `Address` interface
- Added `street2: ''` to the `EMPTY_ADDR` constant

#### `utils.ts`
- Updated `formatAddr()` to include `street2` in the formatted address display (empty values are filtered out automatically by `.filter(Boolean)`)
- Updated `migrateEntry()` to add `street2: ''` to any legacy addresses missing the field, ensuring backward compatibility with existing stored data

#### `components/AddressFields.tsx`
- Added an "Address Line 2" input field between the Street and City fields
- Label includes "(optional)" indicator in secondary text color
- Placeholder text: "Apt, Suite, Floor, etc."
- Field respects `readOnly` state for household-managed addresses (disabled when managed by household)
- Updated the `add()` function in `MultiAddressFields` to include `street2: ''` in newly created addresses

#### `components/HouseholdView.tsx`
- Added an "Address Line 2" input field to the `HouseholdAddressSection` component, positioned between Street and City
- Same label, placeholder, and styling as the person/company address form

#### `storage.ts`
- Added `primaryStreet2` to `CSV_HEADERS` array
- Added `primaryStreet2` output in `entryToCsvRow()` (reads from primary address's `street2`)
- Added `street2` to `HOUSEHOLD_CSV_HEADERS` array
- Added `street2` output in `householdToCsvRow()`
- Updated `csvRowToEntry()` to parse `primaryStreet2` from CSV and include it in constructed addresses
- Updated `csvRowToHousehold()` to parse `street2` from CSV and include it in constructed household addresses

### Behavior
- The field is completely optional — leaving it blank has no effect on validation or display
- Existing data without `street2` is gracefully handled:
  - `migrateEntry()` adds `street2: ''` during data loading
  - Form inputs use `addr.street2 || ''` as a fallback
  - `formatAddr()` filters out empty/falsy values, so addresses without a street2 display identically to before
- CSV export includes the column (empty for entries without street2)
- CSV import reads the column if present (defaults to empty string if missing)

---

## Session 51 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **vCard (.vcf) Export for Individual Contacts** — Add a "Download vCard" button to the detail view that generates a standard `.vcf` file for the selected person or company, enabling easy sharing with other address book applications.

2. **Dark Mode Toggle** — Add a persistent dark mode option toggled via a header button, with the preference saved per-user via private storage so it persists across sessions.

3. **Upcoming Birthdays Widget** — Add a section above the directory list highlighting birthdays occurring within the next 30 days, showing the person's profile image, name, date, and days until the birthday.

---

## Session 52 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 50–52 reflecting the latest conversation history

---

## Session 53 — Status Field for Deceased/Closed Entries

### Action
Added status fields for both persons and companies, allowing entries to be marked as inactive while remaining visible in the directory with visual distinction.

### Type Changes (`types.ts`)
- Added `EntryStatus = 'active' | 'deceased' | 'archived'` type
- Added `CompanyStatus = 'active' | 'closed' | 'archived'` type (originally included 'acquired', later removed in Session 55)
- Added `status?: EntryStatus` and `deceasedDate?: string` to `Person` interface
- Added `companyStatus?: CompanyStatus` and `closedDate?: string` to `Company` interface
- Added `StatusFilter = 'active' | 'deceased' | 'closed' | 'all'` type

### Migration (`utils.ts`)
- Updated `migrateEntry` to default `status: 'active'` and `deceasedDate: ''` for persons
- Updated `migrateEntry` to default `companyStatus: 'active'` and `closedDate: ''` for companies
- Added migration from old `status`/`deceasedDate` fields on companies to new `companyStatus`/`closedDate`

### Toolbar Status Filter (`components/Toolbar.tsx`)
- Added status filter buttons: Active, Deceased, Closed, All
- Gray background for inactive status buttons when selected
- Clear filters button updated to also reset status filter

### Upcoming Birthdays Widget (`components/UpcomingBirthdays.tsx`)
- New component showing active persons with birthdays in the next 30 days
- Sorted by proximity (nearest birthday first)
- Shows profile image, name, birthday date, and days until
- Click-to-navigate to person detail view
- Only shows active (non-deceased) persons

### vCard Export (`components/VCardExport.tsx`)
- New component generating vCard 3.0 files for persons and companies
- Includes: structured names, emails with types, phones with types, addresses, notes, birthday, organization, website
- Supports embedded profile photos (base64-encoded in the vCard)
- Export button added to detail view toolbar

### Family Tree Deceased Indicators (`components/FamilyTree.tsx`)
- Added `deceased` flag to `TreeNode` interface
- Deceased nodes render with gray background/border, reduced opacity (0.75), dimmed text
- ✝ symbol displayed in the top-right corner of deceased nodes
- Legend updated with "✝ Deceased" entry

### App.tsx Integration
- Person form: Status dropdown (Active/Deceased) + conditional "Date of Death" date input
- Company form: Status dropdown (Active/Closed) + conditional "Date Closed" date input
- `filteredEntries` logic: filters by status based on entry type
- List cards: Inactive entries shown with 0.7 opacity, gray left border, and status badges (✝ DECEASED, 🚫 CLOSED)
- Detail view: Status badges shown below name with date info
- vCard export button added to detail view toolbar
- Suppressed "User declined file download" error on vCard cancel

### Constraints
- Archived entries never shown in any filter view
- Deceased/closed entries remain visible but visually distinct
- "User declined file download" message suppressed for vCard cancellation

---

## Session 54 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Keyboard Shortcuts & Accessibility** — Add keyboard shortcuts for common actions and improve ARIA labels, focus management, and screen reader support.

2. **Contact Activity Timeline** — Track changes per entry with timestamps to show modification history.

3. **Smart Search with Filters Inline** — Support typed queries like `type:person city:Austin` with autocomplete, unifying search and filtering into a single input.

---

## Session 55 — Filter UI Redesign & Removal of "Acquired" Status

### Part 1: Filter UI Redesign — New `FilterBar` Component
Replaced the crowded `Toolbar` component with a cleaner, more logically organized `FilterBar` that uses progressive disclosure.

#### Old Toolbar (removed: `components/Toolbar.tsx`)
- All controls in a single row: sort dropdown, sort direction, type buttons, status buttons, industry dropdown, clear button
- Cluttered and hard to scan, especially on smaller screens

#### New FilterBar (`components/FilterBar.tsx`)
**Always-visible summary row (compact):**
- Sort controls — minimal dropdown + direction toggle arrow
- "Filters (N)" toggle button — shows active filter count, expands the panel
- Active filter chips — removable pills showing what's currently filtered (e.g., "👤 Persons", "✝ Deceased", "🏷 Tech")
- "Clear all" link when filters are active
- Result count aligned to far right

**Expandable filter panel (on demand):**
When the "Filters" button is clicked, a clean panel opens below with organized sections in a responsive grid:
- **Entry Type** — segmented button group (All / Person / Company)
- **Status** — context-sensitive segmented button group (changes based on selected type)
- **Industry** — dropdown (only shown when relevant)

### Part 2: Context-Sensitive Status Filter
Status filter options now dynamically change based on the selected entry type:

| Type Filter | Status Options Shown |
|-------------|---------------------|
| Person | ● Active, ✝ Deceased, ○ All |
| Company | ● Active, 🚫 Closed, ○ All |
| All | ● Active, ✝ Deceased, 🚫 Closed, ○ All |

- If the user changes type and the current status filter is no longer valid (e.g., was "deceased" and switched to "company"), it auto-resets to "active"

### Part 3: Removal of "Acquired" Company Status
The "Acquired" value was removed from the list of valid company statuses, simplifying to just Active and Closed.

#### Changes to `types.ts`
- `CompanyStatus` updated from `'active' | 'closed' | 'acquired' | 'archived'` to `'active' | 'closed' | 'archived'`

#### Changes to `utils.ts`
- Migration function now converts any old `'acquired'` values to `'closed'` for backward compatibility

#### Changes to `App.tsx`
- Company form dropdown: only "Active" and "Closed" options
- Form state type narrowed from `'active' | 'closed' | 'acquired'` to `'active' | 'closed'`
- List card badges simplified (no more "🤝 ACQUIRED" badge)
- Detail view: removed separate acquired badge and border logic
- `fillCompanyForm`: maps any old acquired status to `'closed'`
- Filter logic: `'closed'` filter only checks for `companyStatus === 'closed'`
- Removed unused `CompanyStatus` import

---

## Session 56 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Saved Filter Presets** — Allow users to save frequently used filter combinations as named presets for quick-access.

2. **Batch/Bulk Actions with Multi-Select** — Add multi-select mode for bulk status changes, exports, or deletions.

3. **Entry Last-Modified Timestamps & "Recently Updated" Sort** — Track modification dates and add a "Recently Updated" sort option.

---

## Session 57 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 53–57 reflecting the latest conversation history

---

## Session 58 — Bulk Actions with Multi-Select

### Action
Added multi-select mode to the directory list view with a floating bulk actions bar for performing operations on multiple entries simultaneously.

### New Component: `components/BulkActions.tsx`
A floating dark-themed action bar that appears at the bottom of the screen when entries are selected.

**Actions Available:**
| Action | Description |
|--------|-------------|
| 📇 Export vCard | Exports all selected entries as a combined `.vcf` file |
| ⚡ Change Status | Opens status picker dialog (Active/Deceased/Closed) |
| 🏠 Assign Household | Opens searchable household picker (persons only, companies skipped) |
| 🗑️ Delete | Delete all selected entries with cascade effects display |
| Clear | Deselects all entries |

**Delete Confirmation Dialog:**
- Lists all entries being deleted
- Shows cascade side effects (unlinking spouses, removing from parents' children, removing from companies' contacts)
- "This action cannot be undone" warning

**Status Change Dialog:**
- Two-step flow: first pick the status, then confirm
- Shows affected entries filtered by type
- Context-aware: "Deceased" only shown when persons are selected, "Closed" only for companies

**Household Assignment Dialog:**
- Two-step flow: first pick the household, then confirm
- Searchable household list
- Confirmation shows each person and their current household (if being moved)
- Note about persons being moved from other households

### Multi-Select State in `App.tsx`
- `selectMode` — Boolean toggle for selection mode
- `selectedIds` — `Set<string>` of selected entry IDs (persists across pages)
- "☐ Select" button in toolbar toggles select mode
- Checkboxes appear on each card when in select mode
- "Select All" / "Select None" quick buttons above the list
- Clicking a card in select mode toggles its selection (instead of navigating to detail)

### Bulk Handlers in `App.tsx`
- `handleBulkDelete(ids)` — Deletes entries with full cascade cleanup (spouse, parent, company, household)
- `handleBulkStatusChange(ids, status)` — Updates status for each entry (maps incompatible statuses to 'active')
- `handleBulkAssignHousehold(personIds, householdId)` — Removes persons from old households, adds to new household, syncs addresses

### Constraints
- Selection persists across pages so users can pick entries from different pages before acting
- Companies are skipped during bulk household assignment (only persons are assignable)
- A person can only belong to one household; bulk assign removes from old household before adding to new

---

## Session 59 — Bulk Assign Household Bug Fix (Stale State)

### Problem
When bulk-assigning two persons from the same old household to a new household:
1. Person A's reassignment worked correctly
2. Person B appeared in **both** the old and new households after the operation

**Root Cause:** The `handleBulkAssignHousehold` function read old household data from the React `households` state array, which is a stale snapshot captured when the function started. After Person A was removed from the old household and saved to storage, the stale state still showed Person A in the old household's `memberIds`. When Person B was processed, filtering the stale `memberIds` to remove only Person B resulted in re-saving the old household with Person A still in it — effectively undoing Person A's removal.

### Solution
Changed the old household lookup from `households.find(h => h.id === person.householdId)` (stale React state) to `await loadHousehold(person.householdId)` (fresh from storage). Also changed the target household lookup to `await loadHousehold(householdId)`. This ensures each iteration sees the current state of households, including any changes made by prior iterations.

#### Changes to `App.tsx`
- Added `loadHousehold` to imports from `./storage`
- In `handleBulkAssignHousehold`:
  - Replaced `households.find(h => h.id === householdId)` with `await loadHousehold(householdId)`
  - Replaced `households.find(h => h.id === person.householdId)` with `await loadHousehold(person.householdId)`
  - Added comment explaining the stale state issue

---

## Session 60 — Confirmation Dialogs for Bulk Status Change & Household Assignment

### Action
Added two-step confirmation dialogs to the "Change Status" and "Assign Household" bulk actions, matching the pattern already established by the "Delete" bulk action.

### Changes to `components/BulkActions.tsx`

**New State:**
- `showStatusConfirm` — `'active' | 'deceased' | 'closed' | null` — tracks which status was picked, triggers confirmation dialog
- `showHouseholdConfirm` — `Household | null` — tracks which household was selected, triggers confirmation dialog

**Status Change Flow (before → after):**
- Before: Pick status → immediately executes status change
- After: Pick status → confirmation dialog shows affected entries → "Confirm" executes

**Status Confirmation Dialog:**
- Title: "⚡ Confirm Status Change"
- Shows count and new status in question form (e.g., "Set 3 persons to Deceased?")
- Lists affected entries (filtered by type — only persons for "Deceased", only companies for "Closed", all for "Active")
- Note when reactivating: "This will reactivate any deceased persons or closed companies in the selection."
- Cancel and Confirm buttons

**Household Assignment Flow (before → after):**
- Before: Pick household → immediately executes assignment
- After: Pick household → confirmation dialog shows affected persons → "Assign" executes

**Household Confirmation Dialog:**
- Title: "🏠 Confirm Household Assignment"
- Shows count of persons and target household name
- Lists each person with their current household noted (e.g., "👤 John Smith (moving from Johnson Family)")
- Note: "Persons currently in other households will be moved to the new one."
- Cancel and Assign buttons

---

## Session 61 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 58–61 reflecting the latest conversation history

---

## Session 62 — Confirmation Dialogs for Bulk Status Change & Household Assignment

### Action
Added two-step confirmation dialogs to the "Change Status" and "Assign Household" bulk actions, matching the pattern already established by the "Delete" bulk action.

### Changes to `components/BulkActions.tsx`

**New State:**
- `showStatusConfirm` — `'active' | 'deceased' | 'closed' | null` — tracks which status was picked, triggers confirmation dialog
- `showHouseholdConfirm` — `Household | null` — tracks which household was selected, triggers confirmation dialog

**Status Change Flow (before → after):**
- Before: Pick status → immediately executes status change
- After: Pick status → confirmation dialog shows affected entries → "Confirm" executes

**Status Confirmation Dialog:**
- Title: "⚡ Confirm Status Change"
- Shows count and new status in question form (e.g., "Set 3 persons to Deceased?")
- Lists affected entries (filtered by type — only persons for "Deceased", only companies for "Closed", all for "Active")
- Note when reactivating: "This will reactivate any deceased persons or closed companies in the selection."
- Cancel and Confirm buttons

**Household Assignment Flow (before → after):**
- Before: Pick household → immediately executes assignment
- After: Pick household → confirmation dialog shows affected persons → "Assign" executes

**Household Confirmation Dialog:**
- Title: "🏠 Confirm Household Assignment"
- Shows count of persons and target household name
- Lists each person with their current household noted (e.g., "👤 John Smith (moving from Johnson Family)")
- Note: "Persons currently in other households will be moved to the new one."
- Cancel and Assign buttons

---

## Session 63 — "Create New Household" in Bulk Assign Dialog

### Action
Added a "Create New Household" option at the top of the household picker dialog with an inline name and address form, allowing users to create a household and assign selected persons in one flow.

### Changes to `components/BulkActions.tsx`

**New Prop:**
- `onCreateAndAssignHousehold: (personIds: string[], household: Household) => void`

**New State:**
- `showCreateHousehold` — boolean to show/hide the create form dialog
- `newHhName`, `newHhStreet`, `newHhStreet2`, `newHhCity`, `newHhState`, `newHhZip` — form fields
- `newHhError` — validation error message

**UI Changes:**
- Added a prominent "+ Create New Household" card at the top of the household picker, styled with a dashed blue border and light blue background
- Clicking it opens a dedicated creation dialog with:
  - Household name (required, validated)
  - Address fields (street, apt/suite, city/state grid, zip)
  - List of persons to be assigned, with the first person marked as ★ Primary
  - "Create & Assign" button
- The "🏠 Assign Household" button now appears even when no existing households exist

**Other:**
- Imported `uuid` and `EMPTY_ADDR` to construct the new household object

### Changes to `App.tsx`

**New Handler: `handleCreateAndAssignHousehold`**
- Removes each person from their old household (loading fresh from storage)
- Updates each person's `householdId` and syncs their primary address
- Saves the newly created household to storage
- Clears selection and reloads

**Prop Passed:**
- `onCreateAndAssignHousehold={handleCreateAndAssignHousehold}` added to `BulkActionsBar`

---

## Session 64 — Address Auto-Complete in "Create New Household" Dialog

### Action
Added AI-powered address auto-suggest to the street field in the "Create New Household" dialog within the bulk assign flow, matching the behavior of address fields throughout the rest of the application.

### Changes to `components/BulkActions.tsx`

**New Imports:**
- `useState` → `useState, useEffect, useRef` from React
- `suggestAddresses`, `useDebounce` from `../utils`
- `AddressSuggestion` type from `../types`

**New State & Hooks:**
- `addrSuggestions` — `AddressSuggestion[]` for the dropdown results
- `debouncedStreet` — debounced version of `newHhStreet` (400ms delay)
- `addrWrapRef` — ref for click-outside detection on the suggestion dropdown

**New Effects:**
- Address suggestion fetch: triggers `suggestAddresses(debouncedStreet)` when the create household dialog is open and street has 3+ characters
- Click-outside handler: dismisses suggestions when clicking outside the street field area

**UI Changes:**
- Street input placeholder changed from "Street" to "Start typing to auto-suggest..."
- Street field wrapped in a `position: relative` container with `ref={addrWrapRef}`
- Suggestion dropdown renders below the street input using `S.addrDropdown` / `S.addrItem` styles
- Clicking a suggestion auto-fills street, city, state, and ZIP fields and closes the dropdown
- Hover highlighting on suggestion items

### Behavior
- Same UX as the existing `SingleAddressFields` component used in person/company/household forms
- Powered by Claude Haiku model via `suggestAddresses()` utility
- 400ms debounce prevents excessive API calls while typing
- Minimum 3 characters before suggestions trigger
- Up to 5 US address suggestions shown

---

## Session 65 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 62–65 reflecting the latest conversation history

---

## Session 66 — Inline Household Creation in Person Form (Reverted)

### Action
Added a "+ Create New Household" option inside the person form's Household Picker with an inline creation form including address auto-suggest. This was subsequently reverted at the user's request.

### Changes (Reverted)
- `components/HouseholdPicker.tsx` — Added `onCreateHousehold` prop, inline form with name/address/auto-suggest, create & assign flow
- `App.tsx` — Added `onCreateHousehold` handler that saves the household and updates local state

### Reversion
- User requested undo; both files reverted to their Version 111 state

---

## Session 67 — Print-Friendly Directory Export

### Action
Added a "🖨️ Print" button to the directory toolbar that generates a self-contained, print-optimized HTML file as a download.

### New Component: `components/PrintDirectory.tsx`

**`generatePrintDirectory()` function:**
- Generates a standalone HTML document optimized for printing
- Sorts entries alphabetically, groups persons by last-name initial letter
- Two-column CSS layout using `column-count: 2`
- Entry cards with profile photos (base64 embedded), name, phone, email, address
- Deceased/closed entries shown dimmed with status badges
- Household membership displayed per person
- Companies listed in a separate section
- "Print This Directory" button in the HTML (hidden on actual print via `@media print`)
- Footer with entry/household counts

### Integration in `App.tsx`
- Added "🖨️ Print" button between Export CSV and Import CSV in the toolbar
- Added `?raw` import for code export
- Added to the exported project file list

---

## Session 68 — Print Directory Pre-Download Configuration Dialog

### Action
Added a customization dialog that appears before generating the print file, letting users tailor the output for different use cases.

### Changes to `components/PrintDirectory.tsx`

**New `PrintDialog` Component:**
A modal dialog with four configuration sections:

| Option | Choices | Default |
|--------|---------|---------|
| Include | ☑ Persons, ☑ Companies (checkboxes) | Both checked |
| Status Filter | ● Active Only / ○ All Entries | Active Only |
| Profile Photos | 📷 Show Photos / 🚫 No Photos | Show Photos |
| Layout | ▐ Single Column / ▐▐ Two Columns | Two Columns |

**Features:**
- Live entry counts update as options change (e.g., "👤 Persons (42)")
- Preview summary at bottom: "Preview: 42 entries will be included · with photos · two-column layout"
- Contextual helper text for each option (e.g., "Smaller file size, faster printing" for no photos)
- "Download Print File" button disabled when 0 entries would be included
- Generating state shows "Generating..." during file creation

**`PrintConfig` interface:**
```ts
interface PrintConfig {
  includePersons: boolean;
  includeCompanies: boolean;
  statusFilter: 'active' | 'all';
  showPhotos: boolean;
  columns: 1 | 2;
}
```

**Updated `generatePrintDirectory()`:**
- Now accepts `config: PrintConfig` parameter
- Filters entries by type and status based on config
- Conditionally embeds profile photos (significant file size reduction when disabled)
- Adjusts font sizes, padding, avatar sizes, and column count based on layout choice
- Single-column: larger fonts (12px body, 14px names, 24px title), more padding — good for wall posters
- Two-column: compact fonts (11px body, 12px names, 20px title) — fits more entries per page

### Changes to `App.tsx`
- Added `showPrintDialog` state
- "🖨️ Print" button now opens `PrintDialog` instead of directly generating
- Renders `<PrintDialog>` modal when active
- Dialog receives entries, households, images, onClose, and onError props

---

## Session 69 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 66–69 reflecting the latest conversation history

---

## Session 70 — Include Households in Printed Directory

### Action
Added an optional "Include Households" checkbox to the print dialog that appends a family-grouped view to printed directories, showing each household as a card with family name, shared address, and all members listed together.

### Changes to `components/PrintDirectory.tsx`

**PrintConfig Extended:**
- Added `includeHouseholds: boolean` to `PrintConfig` interface (default `false`)

**Print Dialog UI:**
- Added 🏠 Households checkbox with live count in the "Include" section
- Descriptive hint when checked: "Appends a family-grouped section — each household as a card with family name, shared address, and all members listed together."
- Updated preview summary to show household count when enabled
- Updated `canGenerate` logic to allow generating with only households selected

**Household HTML Generation:**
- `allPersons` array for household member resolution, independent of the "Include Persons" toggle
- Households filtered by status (active-only mode skips households with no active members)
- Alphabetically sorted by household name
- Each household card includes:
  - Household photo or 🏠 placeholder
  - Family name in blue
  - Shared address
  - Primary contact's phone and email
  - Member list with individual thumbnails, names, ★ Primary badge, phone/email
  - Deceased members shown dimmed
- Cards use `break-inside: avoid` and respect the 1/2 column layout setting

**New CSS Classes:**
- `.hh-grid`, `.hh-card`, `.hh-header`, `.hh-avatar`, `.hh-avatar-placeholder`
- `.hh-name`, `.hh-addr`, `.hh-contact`, `.hh-members`, `.hh-member`
- `.avatar-sm`, `.avatar-sm-placeholder`, `.hh-member-info`, `.hh-member-name`, `.hh-member-detail`, `.hh-primary`

**Printed Output Updated:**
- Subtitle and stats footer include household count when the option is enabled
- Household section appears after Companies section with its own section title

---

## Session 71 — Households Option Requires Persons to Be Selected

### Problem
The "Include Households" checkbox in the print dialog was available regardless of what entry types were selected. Since companies don't have households, the option should only be relevant when "Include Persons" is checked.

### Solution
Made the Households checkbox dependent on the Persons checkbox — it auto-unchecks and becomes disabled when Persons is toggled off.

### Changes to `components/PrintDirectory.tsx`

**Persons Checkbox Handler:**
- When Persons is unchecked, `includeHouseholds` is automatically set to `false`:
  ```ts
  onChange={e => setConfig(c => ({ ...c, includePersons: e.target.checked, ...(!e.target.checked && { includeHouseholds: false }) }))}
  ```

**Households Checkbox:**
- `disabled={!config.includePersons}` — checkbox is non-interactive when Persons is off
- Cursor changes to `not-allowed` when disabled
- Opacity reduced to 0.45 when disabled for visual clarity

**Hint Text:**
- When Persons is unchecked: "Households require 'Persons' to be included."
- When both Persons and Households are checked: existing description about family-grouped section

---

## Session 72 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications for Completed Actions** — Replace the inconsistent success feedback (some actions use `✅` prefix on the error banner, others have no feedback) with a lightweight toast notification system that confirms saves, deletes, bulk operations, and print downloads. Optionally include undo for destructive actions within a brief timeout window.

2. **Keyboard Shortcuts with Help Overlay** — Add keyboard shortcuts for power users: `N P` (new person), `N C` (new company), `/` (focus search), `Escape` (close dialogs), `?` (shortcut cheat sheet), `Ctrl+S` (save form), and arrow keys for list navigation.

3. **"Family Directory" Print Preset** — A dedicated preset that makes households the primary view with unaffiliated individuals in a separate section and an optional table of contents. A one-click preset button in the print dialog would auto-configure all the right toggles.

---

## Session 73 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 70–73 reflecting the latest conversation history

---

## Session 74 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications with Undo Support** — Replace inconsistent success feedback with a lightweight toast system showing auto-dismissing confirmations and time-limited undo buttons for destructive actions.

2. **Keyboard Shortcuts with `?` Help Overlay** — Add shortcuts like `/` (focus search), `Escape` (close dialogs), `N P` / `N C` (new person/company), `Ctrl+S` (save form), and `?` (toggle cheat sheet overlay).

3. **Directory Statistics Dashboard** — Add a collapsible overview panel showing counts, completeness indicators, household coverage, and top industries.

---

## Session 75 — Upcoming Birthdays Component Removed

### Context
The `UpcomingBirthdays` component was fully implemented and rendered in the list view — it showed active persons with birthdays within the next 30 days as clickable cards. However, because it only renders when matching birthdays exist (returns `null` otherwise), the user never saw it in practice and assumed it was partial/unimplemented code. The user decided they did not want the feature and requested cleanup.

### Removal
The component was completely removed from the codebase:

**Deleted file:**
- `webapp/src/components/UpcomingBirthdays.tsx`

**References removed from `App.tsx`:**
1. `import { UpcomingBirthdays } from './components/UpcomingBirthdays'` — component import
2. `import upcomingBirthdaysSource from './components/UpcomingBirthdays.tsx?raw'` — raw source import for code export
3. `<UpcomingBirthdays persons={allPersons} images={images} onSelect={...} />` — render call in list view
4. `['src/components/UpcomingBirthdays.tsx', upcomingBirthdaysSource]` — entry in code export file list

**Note:** The `calculateAge` utility function in `utils.ts` was retained — it is still used by the person detail view to display age next to the birthday field.

---

## Session 76 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications with Undo Support** — Replace inconsistent success feedback (some actions use `✅` in the error banner, others have none) with a toast system that shows brief, auto-dismissing confirmations and time-limited undo buttons for destructive actions.

2. **Inline Field Error Summary on Long Forms** — Show a compact error summary banner at the top listing all validation issues at once with clickable links that scroll to each offending field, eliminating the current trial-and-error loop of fix-one-save-discover-next.

3. **Search Across All Fields** — Expand the search bar to match against phone numbers, street addresses, city/state/ZIP, and notes content (not just names and emails), and show which field matched in the dropdown results.

---

## Session 77 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 74–77 reflecting the latest conversation history

---

## Session 78 — Major Refactoring: App.tsx from ~1,800 Lines to ~374 Lines

### Problem
The monolithic `App.tsx` file had grown to over 1,800 lines, containing all form state, save/delete/bulk handlers, view rendering, CSV/code export logic, and dialog rendering in a single component. This made it difficult to understand, maintain, and modify without risk of stale-state bugs.

### Solution
Extracted business logic into custom hooks and view components, leaving `App.tsx` as a thin orchestration shell that composes them.

### New Custom Hooks (`hooks/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `useDirectoryData.ts` | 70 | Core data loading (entries, households, images), `reload()`, `allPersons`, `allIndustries`, filtered/search results via `useFilteredEntries` |
| `useDirectoryActions.ts` | 150 | All delete & bulk handlers: `confirmDelete`, `handleDeleteAll`, `handleBulkDelete`, `handleBulkStatusChange`, `handleBulkAssignHousehold`, `handleCreateAndAssignHousehold` |
| `usePersonForm.ts` | 140 | All 16 person form state fields, refs for validation scroll, `reset()` / `fill(person)` / `save()` with full validation, spouse sync, household membership sync |
| `useCompanyForm.ts` | 110 | All 13 company form state fields, refs for validation scroll, `reset()` / `fill(company)` / `save()` with full validation, URL normalization |

### New View Components (`views/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `DetailView.tsx` | 115 | Person/company detail view with all collapsible sections (personal info, emails, phones, addresses, relationships, family tree, household, contact persons, notes) |
| `ImportView.tsx` | 65 | CSV/household import preview tables with entry and household sections, confirm/cancel |

### New Shared Component (`components/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `DeleteDialogs.tsx` | 55 | `DeleteDialog` (single entry with cascade effects) and `DeleteAllDialog` (all entries + households count) |

### App.tsx After Refactoring (~374 lines)
Now serves as a **thin orchestration shell** containing only:
- View routing (`view` state)
- Search dropdown rendering (header)
- List view card rendering with pagination
- Form view rendering (wiring hook state to form components)
- CSV/code export handlers
- Dialog composition (`DeleteDialog`, `DeleteAllDialog`, `PrintDialog`)
- No business logic, no save/delete handlers, no form state

### Code Export Updated
- Added `?raw` imports for all new files: `useDirectoryData.ts`, `useDirectoryActions.ts`, `usePersonForm.ts`, `useCompanyForm.ts`, `DetailView.tsx`, `ImportView.tsx`, `DeleteDialogs.tsx`, `EmailInput.tsx`
- Export shell script now creates `src/hooks/` and `src/views/` directories
- All new files included in the exported project

### Build Results
- Build succeeded with no errors
- 344 modules transformed (up from 329 due to new files + `?raw` imports)
- Final bundle: ~1,132 kB (gzip: ~305 kB) — virtually identical to pre-refactoring

---

## Session 79 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Full-Field Search with Match Context** — Expand search to match phone numbers, addresses, and notes, showing which field matched in the dropdown results. The search logic is now cleanly isolated in `useFilteredEntries`, making this a contained change.

2. **Multi-Error Validation Summary on Forms** — Show all validation issues at once in a clickable summary banner instead of scrolling to only the first error. Validation logic is now encapsulated in `usePersonForm` and `useCompanyForm`, making this a natural extension.

3. **Share Contact via Clipboard or QR Code** — Add a "📤 Share" button to the detail view with copy-to-clipboard (plain text summary) and QR code (MECARD/vCard encoding) options.

---

## Session 80 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 78–80 reflecting the latest conversation history

---

## Session 81 — Log Update

### Action
- Updated `DEVLOG.md` for export purposes

---

## Session 82 — Toast Notification System

### Action
Added a lightweight toast notification system to provide consistent, non-blocking feedback for all user actions across the application.

### New Component: `components/Toast.tsx`

**`ToastProvider` & `useToast` hook:**
- React Context-based provider wrapping the entire app
- `addToast(message)` function available to all components via `useToast()`
- Toasts render in a fixed container in the top-right corner of the screen
- Auto-stacking: multiple toasts stack vertically with spacing
- Auto-dismiss: success toasts fade out after ~3.5 seconds
- Manual dismiss: error toasts (containing "error" or "fail") persist until user clicks the × button
- Slide-in animation via CSS keyframes
- Dark themed (semi-transparent dark background, white text, rounded corners)

### Integration in `App.tsx`
- Wrapped `AppInner` in `<ToastProvider>`
- Replaced direct `setError('✅ ...')` success messages with `addToast(...)` calls throughout:
  - Save person/company: `✅ John Smith saved`
  - Delete entry: `🗑️ John Smith deleted`
  - Delete all: `🗑️ All 5 records deleted`
  - Bulk delete: `🗑️ 3 entries deleted`
  - Bulk status change: `✅ 5 entries updated to active`
  - Bulk household assign: `🏠 3 persons assigned to Smith Family`
  - Create & assign household: `🏠 Smith Family created with 3 members`
  - CSV export: `📥 CSV exported successfully`
  - CSV import: `✅ Successfully imported 5 records`
  - Image import: `✅ Successfully imported 3 profile images`
  - vCard export: `📇 3 contacts exported`
  - Print: `🖨️ Directory generated`
  - Code export: `💾 Source code exported`
  - Log export: `📄 Conversation log exported`

### Changes to `components/BulkActions.tsx`
- Added `onToast` prop to `BulkActionsBarProps`
- All bulk action confirmation dialogs now call `onToast(...)` on success

---

## Session 83 — Toast Position Moved to Top Right

### Action
Moved the toast notification container from bottom-right to top-right corner of the screen.

### Change to `components/Toast.tsx`
- Updated container style from `bottom: 20` to `top: 20`
- Updated slide-in animation from `translateY(40px)` (sliding up from below) to `translateY(-40px)` (sliding down from above)

---

## Session 84 — Bulk Actions: Household Picker Shows Existing Households & "Create New" Option

### Action
Adjusted the bulk assign household flow so that the "🏠 Assign Household" button appears for persons-only selections regardless of whether existing households exist, and the household picker always shows both a "Create New Household" option and the existing household list.

### Changes to `components/BulkActions.tsx`
- The "🏠 Assign Household" button in the floating bar now appears whenever the selection contains only persons (`isPersonsOnly`), not gated on `households.length > 0`
- The household picker dialog always shows the "+ Create New Household" card at the top
- Existing households section (search + list) only renders when `households.length > 0`

---

## Session 85 — Simplified Status Button Labels in Bulk Change Status Dialog

### Action
Simplified the status choice button labels in the "Change Status" picker dialog to show only the status name, since the introductory sentence already states the total count.

### Changes to `components/BulkActions.tsx`
- Before: Buttons read "Set to **Active** (3 entries)"
- After: Buttons read just "● Active", "✝ Deceased", "🚫 Closed"
- The count is conveyed by the introductory text: "Change status for 5 selected entries:"

---

## Session 86 — Status Change Breakdown: Preview Affected vs. Already-Matching Entries

### Action
Added a live breakdown in the "Change Status" dialog showing how many entries will actually change versus how many are already at the target status, and skipping unnecessary writes.

### Changes to `components/BulkActions.tsx`

**New Helper: `getStatusBreakdown(status)`**
- Iterates over selected entries and computes:
  - `willChange` — count of entries whose current status differs from the target
  - `alreadyCount` — count of entries already at the target status
  - `idsToChange` — array of IDs that actually need updating
- Handles person/company status mapping (e.g., "closed" is not valid for persons → maps to "active")

**Status Picker Buttons Updated:**
- Each button now shows a breakdown line below the status name:
  - When all entries already match: "All 5 already Active" (button disabled)
  - When some need changing: "3 of 5 will change — 2 already Active"
- Buttons are disabled (`opacity: 0.5`, non-clickable) when `willChange === 0`

**Status Confirmation Dialog Updated:**
- Header shows: "3 of 5 selected entries will change to **Active** — 2 already Active"
- Entries are split into two lists:
  - Affected entries (will change) — normal display
  - Skipped entries (already at target) — dimmed, under "Already Active (no change):" header
- Confirm button reads "Change 3" (only the count of entries that will change)
- Only `idsToChange` are passed to `onBulkStatusChange` (not all selected IDs)

### Changes to `hooks/useDirectoryActions.ts`
- `handleBulkStatusChange` now checks each entry's current status before saving
- Entries already at the target status are skipped (no write to storage)
- Acts as a backend safety net even if the UI already filters them

---

## Session 87 — Household Assignment: Minimum 2 Persons & Required Address

### Action
Corrected the "Assign Household" bulk action behavior with two constraints:

### Part 1: Minimum 2 Persons to Create a New Household
The "Create New Household" button in the household picker is now disabled when fewer than 2 persons are selected.

#### Changes to `components/BulkActions.tsx`
- Button is **disabled** (grayed out, non-clickable, reduced opacity 0.6) when `selectedPersons.length < 2`
- When disabled: dashed border uses `colors.border` instead of `colors.primary`, background is `#f5f5f5`
- Message when disabled: "Select at least 2 persons to create a household"
- Message when enabled: "Create a household and assign selected persons"
- Click handler returns early when `canCreate` is false

### Part 2: Address Is Required for New Household Creation
The address field in the "Create New Household & Assign" dialog is now required.

#### Changes to `components/BulkActions.tsx`
- Address section label changed from "Address" to "Address *" (marked as required)
- Intro text updated to include: "All members will share the household address."
- Validation added: if `newHhStreet` is empty, shows error "Address is required — a household must have a shared address."
- **Warning banner for existing household members**: When any selected persons already belong to a household, an amber/yellow warning banner appears listing each person and their current household (e.g., "👤 John Smith ← currently in The Smith Family"), making it clear they will be moved to the new household with the new address.

---

## Session 88 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Show Per-Entry Status Transitions in Confirmation Dialog** — Display the current-to-target status transition inline for each affected entry (e.g., "👤 John Smith *(Active → Deceased)*") to give users more confidence before confirming bulk status changes.

2. **Keyboard Shortcuts with Help Overlay** — Add keyboard shortcuts for power users: `N` for new person, `B` for new company, `/` to focus search, `Escape` to close dialogs/exit select mode, and `?` to toggle a shortcut cheat-sheet overlay.

3. **Smart Household Name Suggestion** — Auto-suggest a household name based on selected persons' shared surnames when creating a new household (e.g., "The Smith Family" if all selected persons share the last name "Smith", or "The Smith-Johnson Family" if surnames differ).

---

## Session 89 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 81–89 reflecting the latest conversation history

---

## Session 90 — Quick Add Spouse/Child Feature

### Action
Added the ability to quickly add a spouse or child directly from the "Add Person" form's Relationships section, without leaving the current form.

### New Component: `components/QuickAddRelative.tsx`
A modal dialog for creating a new person as a spouse or child:

**Spouse Mode:**
- First name and last name required
- Gender defaults to the opposite sex of the current person (e.g., if current person is Male, spouse defaults to Female)
- Gender is optional (can be left blank)

**Child Mode:**
- First name, last name, and gender are all required
- Gender validation prevents saving without a selection

**Common Features:**
- Auto-focuses the first name field on open
- Field-level validation with red borders and error messages on save attempt
- "Add Spouse" / "Add Child" button label
- Click-outside or Cancel button to dismiss

### Integration in `App.tsx`
- Added `quickAddMode` state (`'spouse' | 'child' | null`)
- Two new buttons in the Relationships section header:
  - **"+ Quick Add Spouse"** — hidden when a spouse is already selected
  - **"+ Quick Add Child"** — always available
- On creation, the new person is saved to storage immediately and linked:
  - Spouse: sets `pSpouseId` to the new person's ID
  - Child: appends the new person's ID to `pChildIds`
- Added `?raw` import and code export entry for `QuickAddRelative.tsx`

---

## Session 91 — Deferred Persistence with Pending Indicators

### Problem
Quick-added persons were saved to storage immediately when created in the dialog. If the user later cancelled the main person form, these entries would remain as orphaned records in the directory.

### Solution
Changed quick-added relatives to be held in memory as "pending" until the main person form is saved, with visual indicators distinguishing them from existing persons.

### Changes to `hooks/usePersonForm.ts`
- Added `pendingPersons` state array (`Person[]`)
- Added helper functions: `addPendingPerson`, `removePendingPerson`, `updatePendingPerson`
- `reset()` and `fill()` clear `pendingPersons` to `[]`
- `save()` persists all pending persons to storage **after** saving the main person but **before** spouse sync, so `loadEntry` can resolve them during relationship linking

### Changes to `components/QuickAddRelative.tsx`
- No longer calls `saveEntry` — returns the `Person` object in memory via `onCreated` callback
- Generates a UUID for the person but does not persist it

### Changes to `components/SpousePicker.tsx`
- Added optional `pendingIds` (`Set<string>`) and `onEditPending` props
- Pending spouse chips render with:
  - Yellow background (`#fff8e1`) and amber border (`#ffc107`)
  - **✨ new** badge in amber text
  - `cursor: pointer` and "Click to edit" tooltip
  - The × button uses `stopPropagation` to remove without triggering edit

### Changes to `components/RelationshipPicker.tsx`
- Added identical `pendingIds` and `onEditPending` props
- Pending child chips have the same yellow/amber styling and ✨ new badge

### Changes to `App.tsx`
- `onCreated` callback now calls `addPendingPerson` instead of `saveEntry`
- Passes `pendingPersons` merged into `allPersons` for both pickers
- Passes `pendingIds` set to both pickers
- Clearing a pending spouse also calls `removePendingPerson`
- Cancelling the form calls `reset()` which discards all pending persons

### Behavior
- Pending relatives appear as visually distinct chips in the form
- Only persisted to storage when the main person is saved
- Cancelling the form discards them entirely — no orphaned entries

---

## Session 92 — Inline Editing of Pending Relatives

### Problem
Once a pending spouse or child was quick-added, the only option was to remove them. If the user made a typo or wanted to change the gender, they had to remove and re-add the person.

### Solution
Added click-to-edit functionality on pending chips that reopens the Quick Add dialog pre-filled with the person's details.

### Changes to `components/QuickAddRelative.tsx`
- Added optional `editPerson` prop (`Person | null`)
- When editing:
  - Title changes to "💍 Edit Pending Spouse" or "🧒 Edit Pending Child"
  - All fields pre-filled from the existing person
  - The existing person's ID is preserved (not regenerated)
  - Submit button reads "Update" instead of "Add"
  - Subtitle changes to "Update the details below..."

### Changes to `hooks/usePersonForm.ts`
- Added `updatePendingPerson(person)` helper that replaces a pending person by ID

### Changes to `components/SpousePicker.tsx`
- Clicking a pending spouse chip calls `onEditPending(id)` (not the × button — that still removes)
- `onClick` and `stopPropagation` correctly separated between chip body (edit) and × button (remove)

### Changes to `components/RelationshipPicker.tsx`
- Same click-to-edit behavior on pending child chips

### Changes to `App.tsx`
- Added `editingPendingId` state to track which pending person is being edited
- When a pending chip is clicked, sets `editingPendingId` and opens the dialog in the correct mode
- `onCreated` callback calls `updatePendingPerson` (instead of `addPendingPerson`) when `editingPendingId` is set
- Both `editingPendingId` and `quickAddMode` are cleared on dialog close

---

## Session 93 — Auto-Populate Last Name in Quick Add Dialog

### Action
When quick-adding a spouse or child, the Last Name field is now automatically populated with the current person's last name, since family members commonly share a surname.

### Changes to `components/QuickAddRelative.tsx`
- Added optional `defaultLastName` prop to `QuickAddRelativeProps`
- When creating a new relative (not editing), `lastName` state initializes to `defaultLastName || ''`
- When editing an existing pending person, their own last name is used (default is ignored)
- The user can freely clear or change the pre-filled value

### Changes to `App.tsx`
- Passes `defaultLastName={personForm.pLast}` to `QuickAddRelativeDialog`

---

## Session 94 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Confirmation Dialog When Cancelling with Pending Relatives** — Show a warning dialog when the user clicks Cancel on the person form while pending relatives exist, preventing accidental data loss.

2. **Pending Relatives Summary Banner Above Save** — Display a compact banner listing all pending relatives by name and type just above the Save button for a final at-a-glance review before committing.

3. **Quick Add More Fields (Birthday, Email, Phone)** — Expand the Quick Add dialog with optional collapsible fields for birthday, email, and phone, allowing users to capture commonly-known family details in the same flow without needing to edit each relative afterward.

---

## Session 95 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 90–95 reflecting the latest conversation history

---

## Current File Structure

```
webapp/src/
├── App.tsx                          # Thin orchestration shell (~418 lines)
├── types.ts                         # Interfaces, type aliases, constants
├── styles.ts                        # Colors and style definitions
├── utils.ts                         # Utility functions and custom hooks
├── storage.ts                       # Storage operations, CSV helpers, image CRUD
├── countryCodes.ts                  # Country code data
├── usStates.ts                      # US states data
├── main.tsx                         # React entry point
├── vite-env.d.ts                    # Vite type declarations
├── DEVLOG.md                        # This development log
├── hooks/
│   ├── useDirectoryData.ts          # Core data loading, filtering, search
│   ├── useDirectoryActions.ts       # Delete/bulk action handlers
│   ├── usePersonForm.ts             # Person form state, validation, save, pending persons
│   └── useCompanyForm.ts            # Company form state, validation, save
├── views/
│   ├── DetailView.tsx               # Person/company detail view
│   └── ImportView.tsx               # CSV import preview
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── CountryCodeSelect.tsx        # Country code dropdown
│   ├── RelationshipPicker.tsx       # Relationship selection (with pending chip support)
│   ├── SpousePicker.tsx             # Spouse selection (with pending chip support)
│   ├── HouseholdPicker.tsx          # Household member management
│   ├── HouseholdView.tsx            # Household CRUD view
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   ├── DeleteDialogs.tsx            # Delete & Delete All confirmation dialogs
│   ├── FilterBar.tsx                # Sort/filter bar with expandable panel
│   ├── BulkActions.tsx              # Bulk actions floating bar with confirmations
│   ├── PrintDirectory.tsx           # Print dialog & HTML generation (with households)
│   ├── Toast.tsx                    # Toast notification system (provider + hook)
│   ├── EmailInput.tsx               # Email input with blur validation
│   ├── PhoneInput.tsx               # Phone input with blur validation
│   ├── ProfileImage.tsx             # Profile image avatar with upload
│   ├── ImageCropper.tsx             # Interactive circular crop overlay
│   ├── FamilyTree.tsx               # Multi-generation family tree visualization
│   ├── CollapsibleSection.tsx       # Expandable/collapsible section wrapper
│   ├── VCardExport.tsx              # vCard 3.0 file generation
│   └── QuickAddRelative.tsx         # Quick Add Spouse/Child modal dialog
└── assets/
    ├── dashboard-placeholder-chart-icon.svg
    └── dashboard-placeholder-error-icon.svg
```

## Registered Integrations
- **AI Inference** (`ai-inference`): Used for address auto-suggest functionality (Claude Haiku model)

## Storage Tables
| Table Name | Purpose | Key |
|------------|---------|-----|
| `directory-entries` | Persons and companies | Entity UUID |
| `directory-households` | Household groups | Household UUID |
| `directory-images` | Profile images (base64 data URLs) | Entity/Household UUID |
| `user-preferences` (private) | Collapsed section state per user | `detail-collapsed-sections` |

__EOF_DEVLOG_MD__

echo "✅ Done! Extracted 41 files into $ROOT/"
echo "To get started: cd $ROOT && npm install && npm run dev"