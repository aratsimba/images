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
    raw.phones = raw.phone ? [{ number: toE164(raw.phone), isPrimary: true, label: 'Mobile' }] : [];
    delete raw.phone;
  }
  if (raw.address !== undefined && !raw.addresses) {
    const a = raw.address;
    raw.addresses = (a && a.street) ? [{ ...a, isPrimary: true, label: 'Home' }] : [];
    delete raw.address;
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

