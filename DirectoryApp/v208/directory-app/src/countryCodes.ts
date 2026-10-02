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

