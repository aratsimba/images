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

