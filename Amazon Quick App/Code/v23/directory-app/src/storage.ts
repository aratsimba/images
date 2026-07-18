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
    ? [{ address: row.primaryEmail.trim(), isPrimary: true, label: type === 'person' ? 'Personal' : 'Work' }] : [];
  const phones: PhoneEntry[] = row.primaryPhone?.trim()
    ? [{ number: toE164(row.primaryPhone.trim()), isPrimary: true, label: type === 'person' ? 'Mobile' : 'Work' }] : [];
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

