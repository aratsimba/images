import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  putSharedItem,
  getSharedItem,
  listSharedItems,
  deleteSharedItem,
  PageStorageError,
  aiClient,
  AIInferenceError,
  downloadFile,
} from '@amzn/quick-pages-runtime-lib';
import { v4 as uuidv4 } from 'uuid';
import appSource from './App.tsx?raw';

// ─── Types ───────────────────────────────────────────────────────────

interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  isPrimary: boolean;
  label: string; // e.g. "Home", "Work", "Other"
}

interface PhoneEntry {
  number: string; // E.164 format
  isPrimary: boolean;
  label: string;
}

interface EmailEntry {
  address: string;
  isPrimary: boolean;
  label: string;
}

interface Person {
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

interface Company {
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

type DirectoryEntry = Person | Company;
type View = 'list' | 'personForm' | 'companyForm' | 'detail';

const TABLE = 'directory-entries';
const EMPTY_ADDR: Address = { street: '', city: '', state: '', zip: '', isPrimary: true, label: 'Home' };
const EMPTY_PHONE: PhoneEntry = { number: '', isPrimary: true, label: 'Mobile' };
const EMPTY_EMAIL: EmailEntry = { address: '', isPrimary: true, label: 'Personal' };

// ─── E.164 Phone Formatting ─────────────────────────────────────────

function toE164(raw: string): string {
  const digits = raw.replace(/[^\d]/g, '');
  if (!digits) return '';
  if (digits.length === 10) return `+1${digits}`;
  if (digits.length === 11 && digits.startsWith('1')) return `+${digits}`;
  if (digits.startsWith('+')) return raw.replace(/[^\d+]/g, '');
  return `+${digits}`;
}

function formatPhoneDisplay(e164: string): string {
  if (!e164) return '';
  const d = e164.replace(/[^\d]/g, '');
  if (d.length === 11 && d.startsWith('1')) {
    return `+1 (${d.slice(1, 4)}) ${d.slice(4, 7)}-${d.slice(7)}`;
  }
  return e164;
}

// ─── Helpers: ensure one primary ─────────────────────────────────────

function ensureOnePrimary<T extends { isPrimary: boolean }>(arr: T[], setIdx?: number): T[] {
  if (arr.length === 0) return arr;
  const result = arr.map((item, i) => ({ ...item, isPrimary: i === (setIdx ?? 0) }));
  if (!result.some(x => x.isPrimary)) result[0].isPrimary = true;
  return result;
}

function getPrimary<T extends { isPrimary: boolean }>(arr: T[]): T | undefined {
  return arr.find(x => x.isPrimary) || arr[0];
}

// ─── Hooks ───────────────────────────────────────────────────────────

function useDebounce<T>(value: T, ms: number): T {
  const [d, setD] = useState(value);
  useEffect(() => {
    const t = setTimeout(() => setD(value), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return d;
}

// ─── Migration helper (old single → new multi) ──────────────────────

function migrateEntry(raw: any): DirectoryEntry {
  // Handle legacy single-value fields
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

// ─── Storage helpers ─────────────────────────────────────────────────

async function saveEntry(entry: DirectoryEntry) {
  await putSharedItem({ tableName: TABLE, key: entry.id, value: JSON.stringify(entry), tag: entry.type });
}

async function loadEntry(id: string): Promise<DirectoryEntry | null> {
  const r = await getSharedItem({ tableName: TABLE, key: id });
  return r ? migrateEntry(JSON.parse(r.item.value)) : null;
}

async function loadAll(): Promise<DirectoryEntry[]> {
  const items: DirectoryEntry[] = [];
  let token: string | undefined;
  do {
    const r = await listSharedItems({ tableName: TABLE, nextToken: token });
    for (const i of r.items) items.push(migrateEntry(JSON.parse(i.value)));
    token = r.nextToken;
  } while (token);
  return items;
}

async function removeEntry(id: string) {
  await deleteSharedItem({ tableName: TABLE, key: id });
}

// ─── Address AI Suggest ──────────────────────────────────────────────

interface AddressSuggestion { street: string; city: string; state: string; zip: string; }

async function suggestAddresses(partial: string): Promise<AddressSuggestion[]> {
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

// ─── Styles ──────────────────────────────────────────────────────────

const colors = {
  bg: '#f4f6f9', card: '#fff', primary: '#1a73e8', primaryDark: '#1558b0',
  danger: '#d93025', dangerDark: '#b3261e', text: '#202124', textSec: '#5f6368',
  border: '#dadce0', hover: '#f1f3f4', accent: '#e8f0fe',
};

const S: Record<string, React.CSSProperties> = {
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
};

// ─── Components ──────────────────────────────────────────────────────

const ADDR_LABELS = ['Home', 'Work', 'Other'];
const PHONE_LABELS = ['Mobile', 'Home', 'Work', 'Fax', 'Other'];
const EMAIL_LABELS = ['Personal', 'Work', 'Other'];

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

function MultiAddressFields({ addresses, onChange }: { addresses: Address[]; onChange: (a: Address[]) => void }) {
  const add = () => onChange([...addresses, { ...EMPTY_ADDR, isPrimary: false, label: addresses.length === 0 ? 'Home' : 'Work' }]);
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

function MultiItemField<T extends { isPrimary: boolean; label: string }>({ title, items, onChange, labels, renderInput, emptyFactory, itemName }: {
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

function RelationshipPicker({ label, entries, selectedIds, onToggle }: {
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

  // Person form state
  const [pFirst, setPFirst] = useState('');
  const [pLast, setPLast] = useState('');
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

  const allPersons = entries.filter((e): e is Person => e.type === 'person');

  // Load
  const reload = useCallback(async () => {
    try { setLoading(true); setEntries(await loadAll()); }
    catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { reload(); }, [reload]);

  // Search filtering
  const sq = searchQ.toLowerCase();
  const searchResults = entries.filter(e =>
    e.type === 'person'
      ? `${e.firstName} ${e.lastName} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
      : `${e.name} ${e.industry} ${e.emails.map(x => x.address).join(' ')}`.toLowerCase().includes(sq)
  );
  const filteredEntries = searchQ ? searchResults : entries;

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
    setPSpouseId(''); setPChildIds([]); setPHouseholdId(uuidv4()); setPNotes(''); setEditId(null);
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
    setPSpouseId(p.spouseId); setPChildIds([...p.childIds]);
    setPHouseholdId(p.householdId); setPNotes(p.notes); setEditId(p.id);
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
    // Format phones to E.164 and filter empty
    const cleanPhones = pPhones.filter(p => p.number.trim()).map(p => ({ ...p, number: toE164(p.number) }));
    const cleanEmails = pEmails.filter(e => e.address.trim());
    const cleanAddrs = pAddrs.filter(a => a.street.trim() || a.city.trim());
    // Ensure primaries
    const finalPhones = cleanPhones.length ? ensureOnePrimary(cleanPhones, cleanPhones.findIndex(p => p.isPrimary)) : [];
    const finalEmails = cleanEmails.length ? ensureOnePrimary(cleanEmails, cleanEmails.findIndex(e => e.isPrimary)) : [];
    const finalAddrs = cleanAddrs.length ? ensureOnePrimary(cleanAddrs, cleanAddrs.findIndex(a => a.isPrimary)) : [];

    const person: Person = {
      id, type: 'person', firstName: pFirst.trim(), lastName: pLast.trim(),
      emails: finalEmails, phones: finalPhones, addresses: finalAddrs,
      spouseId: pSpouseId, childIds: pChildIds, householdId: pHouseholdId, notes: pNotes.trim(),
    };
    try {
      await saveEntry(person);

      // Sync primary address to household members
      const primaryAddr = getPrimary(finalAddrs);
      if (primaryAddr) {
        const householdMembers = allPersons.filter(p => p.id !== id && p.householdId === person.householdId);
        for (const m of householdMembers) {
          const mAddrs = [...m.addresses];
          const pIdx = mAddrs.findIndex(a => a.isPrimary);
          if (pIdx >= 0) {
            mAddrs[pIdx] = { ...primaryAddr, label: mAddrs[pIdx].label };
          } else {
            mAddrs.unshift({ ...primaryAddr });
          }
          await saveEntry({ ...m, addresses: mAddrs });
        }
      }

      // Bidirectional spouse link
      if (pSpouseId) {
        const spouse = await loadEntry(pSpouseId);
        if (spouse && spouse.type === 'person' && spouse.spouseId !== id) {
          await saveEntry({ ...spouse, spouseId: id, householdId: person.householdId });
        }
      }

      await reload();
      resetPersonForm();
      setView('list');
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
      await saveEntry(company);
      await reload();
      resetCompanyForm();
      setView('list');
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Delete ──
  const handleDelete = async (id: string) => {
    try {
      const entry = await loadEntry(id);
      if (entry?.type === 'person' && entry.spouseId) {
        const spouse = await loadEntry(entry.spouseId);
        if (spouse && spouse.type === 'person') {
          await saveEntry({ ...spouse, spouseId: '' });
        }
      }
      await removeEntry(id);
      await reload();
      if (selectedId === id) { setSelectedId(null); setView('list'); }
    } catch (e) { if (e instanceof PageStorageError) setError((e as PageStorageError).message); }
  };

  // ── Resolve name ──
  const resolveName = (id: string) => {
    const e = entries.find(x => x.id === id);
    if (!e) return 'Unknown';
    return e.type === 'person' ? `${e.firstName} ${e.lastName}` : e.name;
  };

  const formatAddr = (a: Address) =>
    [a.street, a.city, a.state, a.zip].filter(Boolean).join(', ') || '—';

  const getPrimaryEmail = (e: DirectoryEntry) => getPrimary(e.emails)?.address || '';
  const getPrimaryPhone = (e: DirectoryEntry) => {
    const p = getPrimary(e.phones);
    return p ? formatPhoneDisplay(p.number) : '';
  };
  const getPrimaryAddr = (e: DirectoryEntry) => {
    const a = getPrimary(e.addresses);
    return a ? formatAddr(a) : '—';
  };

  // ── Detail view ──
  const selectedEntry = entries.find(e => e.id === selectedId);

  // ── Download source code ──
  const handleDownloadCode = async () => {
    try {
      await downloadFile('App.tsx', new Blob([appSource], { type: 'text/plain' }));
    } catch (e: any) {
      setError(e?.message || 'Download failed');
    }
  };

  // ── Download conversation markdown ──
  const handleDownloadMarkdown = async () => {
    const md = `# 📒 Directory Application — Conversation Log

## 1. Initial Request

> Create a directory application that manages person and company biographical information with:
> 1) Spouse and child relationships with shared household primary address
> 2) Company contact persons tracking
> 3) AI-powered US address auto-suggest
> 4) Unified search with auto-suggest and auto-fill

---

## 2. Application Summary

### Features Built

#### Person & Company Management
- Add/edit/delete persons and companies with full biographical info
- **Multiple emails** with labels (Personal/Work/Other) — one designated as primary
- **Multiple phone numbers** with labels (Mobile/Home/Work/Fax/Other) — one designated as primary, formatted to E.164 standard
- **Multiple addresses** with labels (Home/Work/Other) — one designated as primary, with AI auto-suggest
- Spouse/children relationships for persons, contact persons for companies
- Household system syncs primary address across household members

#### Data Model
- Emails, phones, and addresses stored as arrays with \`isPrimary\` and \`label\` fields
- Phone numbers normalized to E.164 format (e.g. +12125551234)
- Backward-compatible migration for legacy single-value entries

#### Integrations
- **AI Inference** — address auto-suggest via Claude Haiku
- **App Storage (Shared)** — persistent directory data

---

## 3. Follow-Up Suggestions (Round 1)
1. Export & Import Directory Data (CSV)
2. Dashboard Analytics & Summary Stats
3. Sorting & Filtering Controls

## 4. Follow-Up Suggestions (Round 2)
1. Duplicate Detection & Merge
2. Favorites & Quick Access
3. Activity Log / Recent Changes

## 5. Data Access Information
- Data stored in shared \`directory-entries\` table, accessible to all app users
- Export via "📄 Export Log" button or a future CSV export feature

## 6. Multi-Value Enhancement
- Emails, phones, and addresses upgraded from single to multi-value with primary designation
- Phone numbers formatted to E.164 standard
- Legacy data auto-migrated on load

## 7. Follow-Up Suggestions (Round 3)
1. Tagging & Categorization System
2. Bulk Actions & Multi-Select
3. Map View for Addresses
`;
    try {
      await downloadFile('directory-app-conversation.md', new Blob([md], { type: 'text/markdown' }));
    } catch (e: any) {
      setError(e?.message || 'Download failed');
    }
  };

  // ── Render ──
  return (
    <div style={S.app}>
      {/* Header */}
      <div style={S.header}>
        <h1 style={S.headerTitle} onClick={() => { setView('list'); setSelectedId(null); setSearchQ(''); }}>
          📒 Directory
        </h1>
        <div style={S.searchWrap} ref={searchRef}>
          <input style={S.searchInput} placeholder="Search persons & companies..."
            value={searchQ}
            onChange={e => { setSearchQ(e.target.value); setShowSearchDropdown(true); }}
            onFocus={() => setShowSearchDropdown(true)} />
          {showSearchDropdown && searchQ && (
            <div style={S.dropdown}>
              {searchResults.length === 0 && <div style={{ padding: 14, color: colors.textSec }}>No results</div>}
              {searchResults.slice(0, 10).map(e => (
                <div key={e.id} style={S.dropdownItem}
                  onMouseEnter={ev => (ev.currentTarget.style.background = colors.hover)}
                  onMouseLeave={ev => (ev.currentTarget.style.background = '#fff')}
                  onClick={() => {
                    setSearchQ(e.type === 'person' ? `${e.firstName} ${e.lastName}` : e.name);
                    setShowSearchDropdown(false);
                    setSelectedId(e.id);
                    setView('detail');
                  }}>
                  <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                    {e.type === 'person' ? '👤' : '🏢'}
                  </span>
                  {e.type === 'person' ? `${e.firstName} ${e.lastName}` : e.name}
                  {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 12 }}>({e.industry})</span>}
                </div>
              ))}
            </div>
          )}
        </div>
        <div style={{ display: 'flex', gap: 8, marginLeft: 12 }}>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }}
            onClick={handleDownloadCode} title="Download complete source code">
            💾 Export Code
          </button>
          <button style={{ ...S.btn, background: 'rgba(255,255,255,0.2)', color: '#fff', fontSize: 13 }}
            onClick={handleDownloadMarkdown} title="Download conversation log">
            📄 Export Log
          </button>
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
            </div>
            {loading ? <div style={S.emptyState}>Loading...</div> :
              filteredEntries.length === 0 ? <div style={S.emptyState}>{searchQ ? 'No matching entries.' : 'No entries yet. Add a person or company to get started.'}</div> :
                filteredEntries.map(e => (
                  <div key={e.id} style={S.card}
                    onMouseEnter={ev => (ev.currentTarget.style.boxShadow = '0 3px 10px rgba(0,0,0,.12)')}
                    onMouseLeave={ev => (ev.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,.08)')}
                    onClick={() => { setSelectedId(e.id); setView('detail'); }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <span style={{ ...S.badge, background: e.type === 'person' ? '#e8f0fe' : '#fce8e6', color: e.type === 'person' ? colors.primary : colors.danger }}>
                          {e.type}
                        </span>
                        <strong>{e.type === 'person' ? `${e.firstName} ${e.lastName}` : e.name}</strong>
                        {e.type === 'company' && e.industry && <span style={{ color: colors.textSec, marginLeft: 8, fontSize: 13 }}>· {e.industry}</span>}
                      </div>
                      <span style={{ fontSize: 13, color: colors.textSec }}>{getPrimaryEmail(e)}</span>
                    </div>
                    <div style={{ fontSize: 13, color: colors.textSec, marginTop: 4 }}>{getPrimaryAddr(e)}</div>
                  </div>
                ))
            }
          </>
        )}

        {/* ── PERSON FORM ── */}
        {view === 'personForm' && (
          <>
            <h2 style={{ marginBottom: 16 }}>{editId ? 'Edit Person' : 'Add Person'}</h2>
            <div style={S.formGrid}>
              <div><label style={S.label}>First Name *</label><input style={S.input} value={pFirst} onChange={e => setPFirst(e.target.value)} /></div>
              <div><label style={S.label}>Last Name *</label><input style={S.input} value={pLast} onChange={e => setPLast(e.target.value)} /></div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={pEmails} onChange={setPEmails} labels={EMAIL_LABELS} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Personal' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="email@example.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={pPhones} onChange={setPPhones} labels={PHONE_LABELS} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Mobile' })}
              renderInput={(item, update) => (
                <input style={S.input} type="tel" placeholder="+1 (555) 123-4567" value={item.number}
                  onChange={e => update({ ...item, number: e.target.value })}
                  onBlur={e => { if (e.target.value.trim()) update({ ...item, number: formatPhoneDisplay(toE164(e.target.value)) }); }} />
              )} />

            <MultiAddressFields addresses={pAddrs} onChange={setPAddrs} />

            <div style={S.formGrid}>
              <div style={S.fieldFull}><div style={S.section}>Relationships</div></div>

              <div style={S.fieldFull}>
                <label style={S.label}>Spouse</label>
                <select style={{ ...S.input, background: '#fff' }} value={pSpouseId} onChange={e => {
                  const sid = e.target.value;
                  setPSpouseId(sid);
                  if (sid) {
                    const spouse = allPersons.find(p => p.id === sid);
                    if (spouse) setPHouseholdId(spouse.householdId || pHouseholdId);
                  }
                }}>
                  <option value="">— None —</option>
                  {allPersons.filter(p => p.id !== editId).map(p => (
                    <option key={p.id} value={p.id}>{p.firstName} {p.lastName}</option>
                  ))}
                </select>
              </div>

              <RelationshipPicker label="Children" entries={allPersons.filter(p => p.id !== editId)}
                selectedIds={pChildIds} onToggle={id => setPChildIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id])} />

              <div style={S.fieldFull}>
                <label style={S.label}>Household ID</label>
                <input style={{ ...S.input, background: '#f8f9fa' }} value={pHouseholdId} readOnly />
                <span style={{ fontSize: 11, color: colors.textSec }}>
                  Members of the same household share the primary address. Linked automatically when spouse is set.
                </span>
              </div>

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
            <div style={S.formGrid}>
              <div><label style={S.label}>Company Name *</label><input style={S.input} value={cName} onChange={e => setCName(e.target.value)} /></div>
              <div><label style={S.label}>Industry</label><input style={S.input} value={cIndustry} onChange={e => setCIndustry(e.target.value)} /></div>
            </div>

            <MultiItemField<EmailEntry> title="Email Addresses" items={cEmails} onChange={setCEmails} labels={EMAIL_LABELS} itemName="Email"
              emptyFactory={(isPrimary) => ({ address: '', isPrimary, label: 'Work' })}
              renderInput={(item, update) => (
                <input style={S.input} type="email" placeholder="contact@company.com" value={item.address}
                  onChange={e => update({ ...item, address: e.target.value })} />
              )} />

            <MultiItemField<PhoneEntry> title="Phone Numbers" items={cPhones} onChange={setCPhones} labels={PHONE_LABELS} itemName="Phone"
              emptyFactory={(isPrimary) => ({ number: '', isPrimary, label: 'Work' })}
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
              <button style={{ ...S.btn, ...S.btnDanger }} onClick={() => handleDelete(selectedEntry.id)}>Delete</button>
            </div>

            <div style={{ ...S.card, cursor: 'default' }}>
              <div style={{ display: 'flex', alignItems: 'center', marginBottom: 14 }}>
                <span style={{ fontSize: 36, marginRight: 14 }}>{selectedEntry.type === 'person' ? '👤' : '🏢'}</span>
                <div>
                  <h2 style={{ margin: 0 }}>
                    {selectedEntry.type === 'person' ? `${selectedEntry.firstName} ${selectedEntry.lastName}` : selectedEntry.name}
                  </h2>
                  <span style={{ ...S.badge, marginTop: 4, background: selectedEntry.type === 'person' ? '#e8f0fe' : '#fce8e6', color: selectedEntry.type === 'person' ? colors.primary : colors.danger }}>
                    {selectedEntry.type}
                  </span>
                  {selectedEntry.type === 'company' && selectedEntry.industry && (
                    <span style={{ fontSize: 13, color: colors.textSec, marginLeft: 4 }}>{selectedEntry.industry}</span>
                  )}
                </div>
              </div>

              {/* Emails */}
              <div style={S.section}>Email Addresses</div>
              {selectedEntry.emails.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.emails.map((em, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{em.label}</span>
                    <span>{em.address}</span>
                    {em.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))
              }

              {/* Phones */}
              <div style={S.section}>Phone Numbers</div>
              {selectedEntry.phones.length === 0 ? <div style={{ fontSize: 14, color: colors.textSec }}>—</div> :
                selectedEntry.phones.map((ph, i) => (
                  <div key={i} style={{ ...S.detailRow, alignItems: 'center' }}>
                    <span style={{ ...S.badge, background: '#f1f3f4', color: colors.textSec, fontSize: 10 }}>{ph.label}</span>
                    <span>{formatPhoneDisplay(ph.number)}</span>
                    {ph.isPrimary && <span style={{ ...S.badge, background: '#c6f0c2', color: '#1b7a15', fontSize: 10 }}>PRIMARY</span>}
                  </div>
                ))
              }

              {/* Addresses */}
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
                ))
              }

              {selectedEntry.type === 'person' && (
                <>
                  <div style={S.section}>Relationships</div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Spouse</span>
                    <span>{selectedEntry.spouseId ? (
                      <span style={{ ...S.chip, cursor: 'pointer' }} onClick={() => { setSelectedId(selectedEntry.spouseId); }}>
                        {resolveName(selectedEntry.spouseId)}
                      </span>
                    ) : '—'}</span>
                  </div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Children</span>
                    <span style={{ display: 'flex', flexWrap: 'wrap' }}>
                      {selectedEntry.childIds.length === 0 ? '—' : selectedEntry.childIds.map(cid => (
                        <span key={cid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(cid)}>
                          {resolveName(cid)}
                        </span>
                      ))}
                    </span>
                  </div>
                  <div style={S.detailRow}>
                    <span style={S.detailLabel}>Household</span>
                    <span style={{ fontSize: 12, color: colors.textSec }}>{selectedEntry.householdId}</span>
                  </div>

                  {/* Show household members */}
                  {(() => {
                    const housemates = allPersons.filter(p => p.householdId === selectedEntry.householdId && p.id !== selectedEntry.id);
                    if (housemates.length === 0) return null;
                    return (
                      <>
                        <div style={S.section}>Household Members (shared primary address)</div>
                        <div style={{ display: 'flex', flexWrap: 'wrap' }}>
                          {housemates.map(p => (
                            <span key={p.id} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(p.id)}>
                              {p.firstName} {p.lastName}
                            </span>
                          ))}
                        </div>
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
                        <span key={pid} style={{ ...S.chip, cursor: 'pointer' }} onClick={() => setSelectedId(pid)}>
                          {resolveName(pid)}
                        </span>
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
      </div>
    </div>
  );
};

export default App;
