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

export const INDUSTRY_OPTIONS = [
  'Accounting & Tax Services',
  'Banking & Financial Services',
  'Food Service',
  'Church',
  'Construction & Renovation',
  'Education & Training',
  'Elder Care & Senior Services',
  'Facilities & Maintenance',
  'Funeral Services',
  'Insurance',
  'IT & Technology',
  'Legal Services',
  'Missions',
  'Music & Worship Resources',
  'Office Supplies & Equipment',
  'Publishing & Curriculum',
  'Real Estate',
  'Transportation',
  'Utilities',
];

/** Maps common legacy free-text industry values to their canonical INDUSTRY_OPTIONS equivalent. */
export const INDUSTRY_MIGRATION_MAP: Record<string, string> = {
  // IT & Technology
  'tech': 'IT & Technology', 'technology': 'IT & Technology', 'it': 'IT & Technology',
  'software': 'IT & Technology', 'computer': 'IT & Technology', 'computers': 'IT & Technology',
  'information technology': 'IT & Technology', 'web': 'IT & Technology', 'internet': 'IT & Technology',
  // Banking & Financial Services
  'finance': 'Banking & Financial Services', 'financial': 'Banking & Financial Services',
  'banking': 'Banking & Financial Services', 'bank': 'Banking & Financial Services',
  'financial services': 'Banking & Financial Services', 'investment': 'Banking & Financial Services',
  // Accounting & Tax Services
  'accounting': 'Accounting & Tax Services', 'tax': 'Accounting & Tax Services',
  'cpa': 'Accounting & Tax Services', 'bookkeeping': 'Accounting & Tax Services',
  // Insurance
  'insurance': 'Insurance',
  // Legal Services
  'legal': 'Legal Services', 'law': 'Legal Services', 'attorney': 'Legal Services', 'lawyer': 'Legal Services',
  // Real Estate
  'real estate': 'Real Estate', 'realty': 'Real Estate', 'property': 'Real Estate',
  // Education & Training
  'education': 'Education & Training', 'school': 'Education & Training', 'training': 'Education & Training',
  'academy': 'Education & Training', 'university': 'Education & Training', 'college': 'Education & Training',
  // Construction & Renovation
  'construction': 'Construction & Renovation', 'renovation': 'Construction & Renovation',
  'building': 'Construction & Renovation', 'contractor': 'Construction & Renovation',
  'contracting': 'Construction & Renovation', 'remodeling': 'Construction & Renovation',
  // Food Service
  'food': 'Food Service', 'restaurant': 'Food Service', 'catering': 'Food Service',
  'food service': 'Food Service', 'dining': 'Food Service',
  // Church
  'church': 'Church', 'ministry': 'Church', 'worship': 'Church', 'religious': 'Church',
  // Missions
  'missions': 'Missions', 'mission': 'Missions', 'missionary': 'Missions',
  // Transportation
  'transportation': 'Transportation', 'transport': 'Transportation', 'trucking': 'Transportation',
  'logistics': 'Transportation', 'shipping': 'Transportation',
  // Utilities
  'utilities': 'Utilities', 'utility': 'Utilities', 'electric': 'Utilities',
  'power': 'Utilities', 'water': 'Utilities', 'gas': 'Utilities', 'energy': 'Utilities',
  // Elder Care & Senior Services
  'elder care': 'Elder Care & Senior Services', 'senior care': 'Elder Care & Senior Services',
  'senior services': 'Elder Care & Senior Services', 'nursing': 'Elder Care & Senior Services',
  'assisted living': 'Elder Care & Senior Services', 'home health': 'Elder Care & Senior Services',
  // Facilities & Maintenance
  'facilities': 'Facilities & Maintenance', 'maintenance': 'Facilities & Maintenance',
  'janitorial': 'Facilities & Maintenance', 'cleaning': 'Facilities & Maintenance',
  // Funeral Services
  'funeral': 'Funeral Services', 'mortuary': 'Funeral Services', 'funeral home': 'Funeral Services',
  // Music & Worship Resources
  'music': 'Music & Worship Resources',
  // Office Supplies & Equipment
  'office supplies': 'Office Supplies & Equipment', 'office equipment': 'Office Supplies & Equipment',
  // Publishing & Curriculum
  'publishing': 'Publishing & Curriculum', 'curriculum': 'Publishing & Curriculum',
  'media': 'Publishing & Curriculum', 'print': 'Publishing & Curriculum',
};

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

