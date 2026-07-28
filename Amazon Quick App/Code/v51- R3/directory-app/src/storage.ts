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
      website: '',
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

