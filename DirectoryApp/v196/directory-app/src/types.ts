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

export interface Affiliation {
  companyId: string;
  title: string;
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
  companyId: string;
  title: string;
  affiliations: Affiliation[];
  isMissionary: boolean;
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

