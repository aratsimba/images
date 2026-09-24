import { useState, useEffect } from 'react';
import { aiClient, AIInferenceError } from '@amzn/quick-pages-runtime-lib';
import type { DirectoryEntry, Person, AddressSuggestion, Address } from './types';
import { INDUSTRY_OPTIONS, INDUSTRY_MIGRATION_MAP } from './types';

// ─── Name capitalization ─────────────────────────────────────────────

/** Capitalize the first letter of a name string. */
export function capitalizeName(name: string): string {
  const trimmed = name.trimStart();
  if (!trimmed) return name;
  return name.slice(0, name.length - trimmed.length) + trimmed.charAt(0).toUpperCase() + trimmed.slice(1);
}

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

// ─── Industry validation ─────────────────────────────────────────────

const _industrySet = new Set(INDUSTRY_OPTIONS.map(i => i.toLowerCase()));

/** Returns true if the industry value matches one of the predefined INDUSTRY_OPTIONS or is an "Other — ..." value. */
export function isValidIndustry(industry: string): boolean {
  if (!industry.trim()) return true;
  if (industry.trim() === 'Other' || industry.trim().startsWith('Other — ')) return true;
  return _industrySet.has(industry.trim().toLowerCase());
}

/** Attempt to map a legacy free-text industry value to a canonical option. Returns the mapped value or the original if no mapping found. */
export function migrateIndustry(raw: string): string {
  if (!raw.trim()) return '';
  // Already valid?
  if (_industrySet.has(raw.trim().toLowerCase())) {
    // Return canonical casing
    return INDUSTRY_OPTIONS.find(o => o.toLowerCase() === raw.trim().toLowerCase()) || raw.trim();
  }
  // Check migration map
  const mapped = INDUSTRY_MIGRATION_MAP[raw.trim().toLowerCase()];
  return mapped || raw.trim();
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
    if (!raw.companyId) raw.companyId = '';
    if (!raw.title) raw.title = '';
    // Migrate old single companyId/title to affiliations array
    if (!raw.affiliations) {
      if (raw.companyId) {
        raw.affiliations = [{ companyId: raw.companyId, title: raw.title || '' }];
      } else {
        raw.affiliations = [];
      }
    }
    // Deduplicate affiliations by companyId (keep first occurrence)
    if (Array.isArray(raw.affiliations)) {
      const seen = new Set<string>();
      raw.affiliations = raw.affiliations.filter((a: any) => {
        if (!a.companyId || seen.has(a.companyId)) return false;
        seen.add(a.companyId);
        return true;
      });
    }
    if (raw.isMissionary === undefined) raw.isMissionary = false;
  }
  if (raw.type === 'company') {
    if (!raw.website) raw.website = '';
    if (!raw.contactPersonIds) raw.contactPersonIds = [];
    if (!raw.companyStatus) raw.companyStatus = 'active';
    if (raw.companyStatus === 'acquired') raw.companyStatus = 'closed';
    if (!raw.closedDate) raw.closedDate = '';
    // Auto-migrate legacy free-text industry values
    if (raw.industry) raw.industry = migrateIndustry(raw.industry);
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

// ─── Household primary contact selection ─────────────────────────────

/**
 * Select a new primary contact from remaining household members using precedence:
 * 1) The removed person's spouse
 * 2) A member who is a parent (has childIds)
 * 3) A member who has a phone number
 * 4) Any of the other members
 */
export function selectNewPrimaryContact(
  removedPersonId: string,
  remainingIds: string[],
  allPersons: Person[],
): string {
  if (remainingIds.length === 0) return '';
  const removedPerson = allPersons.find(p => p.id === removedPersonId);

  // 1) Spouse of the removed person
  if (removedPerson?.spouseId && remainingIds.includes(removedPerson.spouseId)) {
    return removedPerson.spouseId;
  }
  // 2) A parent (has children)
  for (const mid of remainingIds) {
    const m = allPersons.find(p => p.id === mid);
    if (m && m.childIds.length > 0) return mid;
  }
  // 3) A member with a phone number
  for (const mid of remainingIds) {
    const m = allPersons.find(p => p.id === mid);
    if (m && m.phones.length > 0 && m.phones.some(ph => ph.number.trim())) return mid;
  }
  // 4) First remaining member
  return remainingIds[0];
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

