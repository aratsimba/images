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

