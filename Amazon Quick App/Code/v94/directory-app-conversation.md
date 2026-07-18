# Development Log — Directory Application

## Overview
A directory application for managing biographical information about persons and companies, with relationship tracking, address auto-suggest, and unified search capabilities.

---

## Session 1 — Project Setup & Requirements Gathering

### Requirements Defined
The user requested a directory application with the following features:
- **Person management**: Track spouse and child relationships; same household members share the same primary address
- **Company management**: Track contact persons associated with companies
- **Address functionality**: Look-up and auto-suggest valid USA addresses
- **Search capability**: Unified search across persons and companies with auto-suggest and auto-fill as users type partial letters

### Development Environment Exploration
- Examined project structure: template directory, workspace directory, and key configuration files
- Identified available dependencies: React 18.2.0, react-router-dom, axios, lodash, framer-motion, recharts, leaflet, three.js, mammoth, pdf-lib, xlsx, papaparse, and `@amzn/quick-pages-runtime-lib`
- Explored the runtime library capabilities:
  - **Page Storage Client**: Private and shared item storage (put, get, list, delete) with table-based organization, key-value storage, optional tagging, pagination, and sorting
  - **AI Client**: Bedrock Claude integration for inference (prompt method, invoke with tools, multi-step tool-use loops)
  - **Additional exports**: QuickSuite client, user client (`getCurrentUser`), download client, dashboard utilities

### Next Steps Planned
- Register AI inference integration for address lookup functionality

---

## Session 2 — Full Application Implementation

### Application Built (Single-File App.tsx)
The complete directory application was implemented with all requested features:

#### Person Management
- Form with fields: first name, last name, email, phone, address, notes
- Spouse selection via dropdown with automatic bidirectional relationship and shared household ID
- Children picker with searchable interface and chip-based display
- Household ID system: all members (spouse, children) automatically share the same primary address
- Address synchronization logic across all household members

#### Company Management
- Form with fields: company name, industry, email, phone, address, notes
- Contact persons picker with searchable interface for multiple person associations

#### AI-Powered Address Auto-Suggest
- Integrated with Claude Haiku model (`anthropic.claude-haiku-4-5-20251001-v1:0`)
- Triggers when user types 3+ characters in street field
- 400ms debounce for API call optimization
- Dropdown with up to 5 suggestions; auto-fills all address fields on selection
- Click-outside handler to close dropdown

#### Unified Search
- Header-mounted search bar filtering both persons and companies simultaneously
- Live dropdown showing up to 10 matching results with type badges (👤 person, 🏢 company)
- Results include contextual info (industry for companies)
- Clicking a result navigates to detail view

#### Detail View
- Comprehensive info display for selected person or company
- Clickable relationship chips (spouse, children, contact persons, household members)
- Household members section for all persons sharing the same household ID
- Edit and delete functionality with back navigation

### Technical Details
- **Storage**: Shared storage, table name `directory-entries`, key-value with JSON serialization, tag-based categorization by entry type
- **UI**: Inline styles, Amazon Ember font, modern color scheme, hover effects, badge system, chip-based relationship display, 2-column grid forms
- **Hooks**: Custom `useDebounce` (400ms), useState, useEffect, useCallback, useRef
- **Integrations Registered**: AI Inference (for address auto-suggest)

---

## Session 3 — Code Refactoring to Modular Architecture

### Motivation
The single-file App.tsx had grown large and needed to be refactored for maintainability.

### Extracted Modules

| File | Contents |
|------|----------|
| `types.ts` | All interfaces, type aliases, constants, and label arrays |
| `styles.ts` | Colors object and style definitions dictionary |
| `utils.ts` | Pure utility functions: `toE164`, `formatPhoneDisplay`, `ensureOnePrimary`, `getPrimary`, `getEntryName`, `formatAddr`, `useDebounce` hook, `migrateEntry`, `suggestAddresses` |
| `storage.ts` | Storage operations: `saveEntry`, `loadEntry`, `loadAll`, `removeEntry`; CSV helpers: `exportCsv`, `parseCsvFile`, `entryToCsvRow`, `csvRowToEntry` |
| `components/AddressFields.tsx` | Address form fields with AI-powered auto-suggest |
| `components/MultiItemField.tsx` | Reusable multi-item selector with search and chips |
| `components/RelationshipPicker.tsx` | Relationship selection component |
| `components/DuplicateWarning.tsx` | Duplicate entry detection and warning display |
| `components/Toolbar.tsx` | Top toolbar/navigation component |
| `App.tsx` | Streamlined orchestrator: state management, view routing, save/delete handlers, rendering |

### Build Results
- Build succeeded with no errors
- Final bundle: **336.53 kB** (gzip: 99.17 kB), 147 modules transformed
- Build time: ~4.34s (vite build)
- Functionally identical behavior to pre-refactoring state

---

## Session 4 — Log Creation

### Action
- Created this `DEVLOG.md` to capture the full conversation history and development timeline

---

## Session 5 — Delete Confirmation Dialog

### Action
- Added a confirmation prompt before deleting a person or company

### Changes
- **Styles** (`styles.ts`): Added `overlay`, `dialog`, `dialogTitle`, `dialogBody`, and `dialogActions` styles for the modal UI
- **State Management** (`App.tsx`): Added `deleteTarget` state variable to track the entry pending deletion
- **Delete Flow Refactoring** (`App.tsx`):
  - Renamed `handleDelete` to `confirmDelete` — executes actual deletion
  - Created `requestDelete` — sets the `deleteTarget` to show the confirmation dialog
  - Created `cancelDelete` — clears `deleteTarget` to dismiss the dialog
  - Updated the Delete button in detail view to call `requestDelete` instead of directly deleting
- **Dialog Component** (`App.tsx`):
  - Displays when `deleteTarget` is not null
  - Shows entity type (Person/Company) and name
  - Warns about cascading effects: if deleting a person with a spouse, mentions unlinking the spouse by name
  - Includes "This action cannot be undone" warning
  - Provides Cancel and Delete buttons
  - Click-outside-to-close with `stopPropagation` on dialog content

---

## Session 6 — Spouse Picker UX Refinement

### Action
- Ineligible persons (those already married to someone else or listed as children) are now hidden entirely from the spouse picker dropdown, rather than being displayed greyed out with explanatory reasons

### Changes
- Removed `getIneligibleReason()` function
- Removed `ineligible` array and its greyed-out rendering
- Dropdown now shows only filtered eligible candidates (up to 8 results)
- "No matching persons" message triggers when no eligible matches exist

---

## Session 7 — Cascading Delete Cleanup & Household Member Removal

### Part 1: Enhanced Delete with Full Cascading Cleanup
When deleting a person, the `confirmDelete` function now performs a complete relationship cleanup:
- **Spouse unlinking** (existing): Clears the deleted person's ID from their spouse's `spouseId`
- **Parent→child cleanup** (new): Removes the deleted person's ID from all parents' `childIds` arrays
- **Company→contact cleanup** (new): Removes the deleted person's ID from all companies' `contactPersonIds` arrays

The delete confirmation dialog now dynamically computes and displays a bulleted list of all side effects:
- "Unlink spouse **Jane Doe**"
- "Remove as child from **John Doe**, **Jane Doe**"
- "Remove as contact from **Acme Corp**"

### Part 2: Allow Removing Spouse & Children from Household
Previously, spouse and children were "auto" household members without remove buttons. Now all members can be removed.

#### Changes to `HouseholdPicker.tsx`
- Added new callback props: `onRemoveSpouse` and `onRemoveChild(id)`
- Every household member chip now shows a **×** remove button — not just manually-added extras
- Clicking **×** on a spouse chip calls `onRemoveSpouse` (clears spouse relationship)
- Clicking **×** on a child chip calls `onRemoveChild(id)` (removes child from parent-child relationship)
- Updated helper text: *"Spouse and children are automatically included but can be removed."*

#### Changes to `App.tsx`
- Wired `onRemoveSpouse` → sets `pSpouseId` to `''`
- Wired `onRemoveChild` → filters the removed child out of `pChildIds`
- Changes take effect when the user clicks **Save Person**

---

## Current File Structure

```
webapp/src/
├── App.tsx                          # Main orchestrator component
├── types.ts                         # Interfaces, type aliases, constants
├── styles.ts                        # Colors and style definitions
├── utils.ts                         # Utility functions and custom hooks
├── storage.ts                       # Storage operations and CSV helpers
├── main.tsx                         # React entry point
├── vite-env.d.ts                    # Vite type declarations
├── DEVLOG.md                        # This development log
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── RelationshipPicker.tsx       # Relationship selection
│   ├── SpousePicker.tsx             # Spouse selection with eligibility filtering
│   ├── HouseholdPicker.tsx          # Household member management (spouse/children/extras)
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   └── Toolbar.tsx                  # Sort/filter toolbar
└── assets/
    ├── dashboard-placeholder-chart-icon.svg
    └── dashboard-placeholder-error-icon.svg
```

## Registered Integrations
- **AI Inference** (`ai-inference`): Used for address auto-suggest functionality (Claude Haiku model)

---

## Session 8 — Export Fixes

### Part 1: Log Export Fix
The **📄 Export Log** button was downloading a hardcoded 5-line stub instead of the actual `DEVLOG.md`. Fixed by importing `DEVLOG.md` via Vite's `?raw` suffix and using the imported content in `handleDownloadMarkdown`.

### Part 2: Code Export Fix
The **💾 Export Code** button was only exporting `App.tsx` — a single file out of the 12-file modular codebase. Fixed by:
- Adding `?raw` imports for all source files: `types.ts`, `styles.ts`, `utils.ts`, `storage.ts`, and all 7 component files
- Generating a self-extracting shell script (`directory-app.sh`) that recreates the full project structure
- Running `bash directory-app.sh` creates a `directory-app/` folder with `src/`, `src/components/`, and all 13 files in their correct paths
- Also includes `DEVLOG.md` in the export

---

## Session 9 — Standalone Deployment Discussion

### Question
The user asked whether the app can be deployed to their own AWS cloud infrastructure.

### Answer
The app **cannot** be directly deployed standalone because it depends on Quick Suite runtime services:
- Sandboxed iframe with strict CSP (`default-src 'none'`)
- `window.bridge` communication layer provided by the QuickSight runtime
- `@amzn/quick-pages-runtime-lib` for storage, AI inference, user identity, and file downloads

### Migration Guide Provided
A comprehensive step-by-step rewrite plan was documented for migrating to a standalone deployment:

#### Phase 1: Project Setup
- Create a new React + TypeScript project (Vite, CRA, or Next.js)
- Copy over component files, styles, and types (standard React code is reusable)

#### Phase 2: Replace Quick Suite Runtime Services
| Quick Suite Feature | Standalone Replacement |
|---|---|
| `putSharedItem` / `getSharedItem` / `listSharedItems` / `deleteSharedItem` | DynamoDB or RDS + API Gateway + Lambda |
| `getCurrentUser()` | Amazon Cognito / Auth0 / Firebase Auth |
| `aiClient.prompt()` / `aiClient.invoke()` | Amazon Bedrock Converse API (via backend proxy) |
| Action Connectors | Direct third-party API integration |
| Dashboard Placeholders | QuickSight Embedding SDK |
| `downloadFile()` | `URL.createObjectURL()` + anchor element / FileSaver.js |

#### Phase 3: Remove Sandbox Constraints
- Remove CSP restrictions (can load external resources freely)
- Use standard HTML `<form>` elements
- Use standard external links without bridge workarounds

#### Phase 4: Build & Test
- Remove all `@amzn/quick-pages-runtime-lib` imports
- Create service abstraction layers (`storageService.ts`, `authService.ts`, `aiService.ts`)
- Test CRUD, auth flows, data persistence, and AI features end-to-end

#### Phase 5: Deploy
Hosting options presented:
| Option | Frontend | Backend | Best For |
|--------|----------|---------|----------|
| AWS Amplify | Amplify Hosting | Amplify Functions / AppSync | Fastest all-in-one AWS setup |
| S3 + CloudFront | S3 static hosting | API Gateway + Lambda | Cost-effective, serverless |
| Vercel / Netlify | Managed hosting | Serverless functions | Simplicity, fast iteration |
| ECS / EC2 | Containerized or VM | Same container/VM | Full control |

Additional deployment considerations: CI/CD pipeline, custom domain with Route 53 + ACM SSL, and monitoring (CloudWatch / Sentry / Datadog).

---

## Session 10 — Context-Specific Labels & Household Relationship Preservation

### Part 1: Household Group Removal No Longer Breaks Relationships
Previously, removing a member from a household group would also remove their spouse or child relationships. This was incorrect — household membership and family relationships are independent concepts.

#### Change
- Updated `HouseholdPicker.tsx` so that removing a person from a household group **only** clears their household association
- Spouse and child relationships remain intact regardless of household membership status

### Part 2: Context-Specific Email and Phone Labels
Different entity types now have distinct label options for email and phone fields.

#### New Constants Added to `types.ts`
| Constant | Values |
|----------|--------|
| `EMAIL_LABELS_PERSON` | Home, Work, Other |
| `EMAIL_LABELS_COMPANY` | Main, Other |
| `PHONE_LABELS_PERSON` | Home, Work, Mobile, Other |
| `PHONE_LABELS_COMPANY` | Main, Fax, Other |

#### Changes to `App.tsx`
- Person form email fields use `EMAIL_LABELS_PERSON`
- Person form phone fields use `PHONE_LABELS_PERSON`
- Company form email fields use `EMAIL_LABELS_COMPANY`
- Company form phone fields use `PHONE_LABELS_COMPANY`
- Updated `emptyFactory` defaults for company fields from `'Work'` to `'Main'`
- Legacy combined label arrays preserved for backward compatibility with existing data

---

## Session 11 — Wedding Anniversary & Spouse Delete Improvements

### Part 1: Clear Wedding Anniversary When Deleting a Person's Spouse
When a person is deleted, the surviving spouse's `weddingAnniversary` field is now cleared in addition to unlinking the `spouseId`.

#### Change to `confirmDelete` in `App.tsx`
- Updated the spouse unlinking logic: `await saveEntry({ ...spouse, spouseId: '', weddingAnniversary: '' })`

### Part 2: Move Wedding Anniversary to Relationships Section
The Wedding Anniversary field was moved from "Personal Information" to "Relationships" in both the form and detail view, since it's inherently tied to the spouse relationship.

#### Form Changes (`App.tsx`)
- Removed the Wedding Anniversary date input from the Personal Information grid
- Added it to the Relationships section, directly after the Spouse Picker
- The field is **disabled** when no spouse is selected (no anniversary without a spouse)
- Clearing the spouse via the "Clear" button also automatically clears the anniversary

#### Detail View Changes (`App.tsx`)
- Removed Wedding Anniversary from "Personal Information" display
- Now shown in the "Relationships" section below the spouse name (whenever it has a value)

---

## Session 12 — Clear Anniversary on Both Sides When Removing Spouse

### Action
When editing a person and removing or changing their spouse, the Wedding Anniversary is now cleared on **both sides** of the relationship.

#### Change to `savePerson` in `App.tsx`
- When detecting that the spouse has changed (`oldPerson.spouseId !== pSpouseId`):
  - The **old spouse's** `weddingAnniversary` is cleared: `await saveEntry({ ...oldSpouse, spouseId: '', weddingAnniversary: '' })`
  - The **current person's** `weddingAnniversary` is also cleared: `person.weddingAnniversary = ''`

This ensures anniversary data is never orphaned on either side when a marriage relationship is dissolved.

---

## Session 13 — Delete Confirmation Dialog Spacing Fix

### Action
Added a space between the two sentences in the delete confirmation prompt for improved readability.

#### Change
- Before: `"Are you sure you want to delete Jean Grey?This action cannot be undone."`
- After: `"Are you sure you want to delete Jean Grey? This action cannot be undone."`
- Used `{' '}` JSX spacing before "This action cannot be undone."

---

## Session 14 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 11–14 reflecting the latest conversation history

---

## Session 15 — Improvement Suggestions & Log Update

### Part 1: Follow-Up Improvement Suggestions
The user asked for 2–3 suggestions to enhance the app. Three suggestions were provided:

1. **Family Tree Visualization** — Display a visual tree/graph showing parent-child and spouse relationships for a selected person, helping users quickly understand complex family structures at a glance.

2. **Search/Filter by Relationship** — Allow users to filter the list view by relationship criteria (e.g., "persons without a spouse," "persons with children," "members of a specific household"), making relationship data auditing easier.

3. **Bulk Relationship Management** — Provide a way to assign multiple children to a couple at once (selecting a parent pair and checking off multiple children in a single action), streamlining data entry for large families.

### Part 2: Log Update
- Updated `DEVLOG.md` to include Session 15 reflecting the latest conversation history

---

## Session 16 — Log Update

### Action
- Updated `DEVLOG.md` to include Session 16 reflecting the latest conversation history (user requested log update for export purposes)

---

## Session 17 — Remove Automatic Household Creation for Spouse/Child Relationships

### Problem
When a spouse or child relationship was added to a person, they were automatically included in that person's household group. This forced household membership through relationships, which was not always desired.

### Solution
Made household membership fully manual — spouses and children are no longer auto-added to a person's household but can be added manually through the Household Picker.

### Changes

#### `components/HouseholdPicker.tsx`
- Removed `onRemoveFromHousehold` prop (no longer needed since nothing is auto-added)
- Removed the `autoIds` concept — all members in `extraMemberIds` are treated uniformly as manually-added
- Updated helper text from *"Spouse and children are automatically included"* to *"Add spouse, children, or others manually"*
- Simplified chip rendering — no more special "auto" vs "extra" distinction; all members have the same remove button behavior
- Members who happen to be a spouse or child still show role labels (e.g., "(spouse)", "(child)") and green highlighting for visual context

#### `App.tsx`
- **Removed `pHouseholdExcludedIds` state** — no longer needed since there are no auto-inclusions to exclude
- **SpousePicker `onSelect` handler**: Removed `setPHouseholdId(spouse.householdId || pHouseholdId)` — selecting a spouse no longer adopts their household ID
- **`resetPersonForm`**: Removed `setPHouseholdExcludedIds([])` reset
- **`fillPersonForm`**: All persons sharing the same `householdId` are now loaded uniformly into `pHouseholdExtraIds` (no more separate auto/excluded computation)
- **`savePerson`**: `householdMemberIds` now equals `pHouseholdExtraIds` only — spouse and children are only synced to the household if explicitly added
- **Spouse sync logic**: Only updates the spouse's `householdId` if the spouse was explicitly added to the household members list
- **HouseholdPicker usage in form**: Removed `onRemoveFromHousehold` prop and excluded IDs filtering

### Behavior Summary
| Before | After |
|--------|-------|
| Adding spouse → auto-joins household | Adding spouse → no household change |
| Adding child → auto-joins household | Adding child → no household change |
| Spouse/children shown as "auto" members with special remove behavior | All household members are manually added and uniformly removable |
| Selecting spouse adopted their household ID | Selecting spouse has no effect on household |

---

## Session 18 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **"Quick Add to Household" prompt when linking a spouse or child** — After selecting a spouse or adding a child, display a brief inline prompt (e.g., "Also add [Name] to this household?") with a one-click button. Preserves the manual-only principle while making the common case frictionless.

2. **Household group view/management page** — A dedicated view showing all households as grouped cards, making it easy to see which persons share a household, who's unassigned, and to bulk-assign members. Currently households are only manageable from individual person forms.

3. **Parent relationship display in detail view** — The detail view shows a person's spouse and children but not their parents. Adding a "Parents" row (computed by finding persons whose `childIds` include the current person) would make family navigation more intuitive and complete.

---

## Session 19 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 17–19 reflecting the latest conversation history

---

## Session 20 — Delete Confirmation Dialog Implementation (from context)

### Action
Added a confirmation prompt before deleting a person or company (continued refinements from Session 5).

---

## Session 21 — Context-Specific Labels & Household Relationship Preservation (from context)

### Actions
1. Do not remove spouse or child relationships when removing a member from a household group
2. Email types for companies: "Main" or "Other" only
3. Phone number types for persons: "Home", "Work", "Mobile", or "Other"
4. Phone number types for companies: "Main", "Fax", or "Other"

---

## Session 22 — UX Enhancements: Household Link, Badge Cleanup, Relationship Indicators

### Part 1: Household Name on Read-Only Address Card (Edit Person Page)
The address card for a household-managed address previously showed generic text "Managed by household." Now it displays the household name (e.g., "Managed by The Smith Family") as a clickable link that navigates to the Households view.

#### Changes to `components/AddressFields.tsx`
- Added `householdName` and `onNavigateHousehold` props to `SingleAddressFields`
- Added `householdName` and `onNavigateHousehold` props to `MultiAddressFields`
- Updated the "Managed by household" text:
  - If `householdName` is provided, displays: "Managed by **[Household Name]**" with the name as a clickable, underlined link in the primary color
  - Clicking the name calls `onNavigateHousehold` (navigates to Households view)
  - Falls back to generic "Managed by household" if no name is available

#### Changes to `App.tsx`
- Passes `householdName` (resolved from `households` state via `pHouseholdId`) and `onNavigateHousehold` (navigates to `'households'` view) to `MultiAddressFields` in the person form

### Part 2: Removed "Person" Label from Person Detail Page
The detail view previously showed a type badge ("person" or "company") below the entry name. Since the 👤 icon already indicates it's a person, the redundant "person" badge has been removed.

#### Changes to `App.tsx`
- The type badge now only renders for companies (showing "company" badge + industry)
- Person entries show only the 👤 icon and name without a label badge

### Part 3: Relationship Indicator Icons on List Cards
Each person card in the directory list now displays small relationship indicator icons on the right side for at-a-glance connectivity information.

#### Indicators Added
| Icon | Meaning | Tooltip |
|------|---------|---------|
| 💍 | Has a spouse | "Spouse: [Name]" |
| 👶 + count | Has children | "[N] child/children" |
| 🏠 | Member of a household | "[Household Name]" |

#### Changes to `App.tsx`
- Added a right-aligned container within each person card's header row
- Conditionally renders each indicator icon only when the relationship exists
- Each icon has a `title` attribute for native browser tooltip on hover
- Household indicator resolves the household name from the `households` state

### Part 4: Follow-Up Improvement Suggestions
Three suggestions were provided:

1. **Quick preview hover card on list items** — Show a small popover with key details on hover to speed up browsing without clicking into the full detail view.

2. **"Recently Viewed" section** — Track the last 3–5 entries viewed/edited and display them as compact chips above the main list for quick navigation.

3. **Alphabetical section headers and jump-to-letter sidebar** — When sorted by name, group entries under letter headers (A, B, C…) with a clickable letter index for instant scrolling.

---

## Session 23 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 20–23 reflecting the latest conversation history

---

## Session 24 — Follow-Up Suggestions & Export Code Enhancement

### Part 1: Follow-Up Improvement Suggestions
Three suggestions were provided:

1. **Add a "Parents" row in the Person detail view** — Display parent relationships by finding persons whose `childIds` include the current person, enabling bidirectional family navigation.

2. **Include households in "Delete All"** — The Delete All button removes persons and companies but leaves household records orphaned in storage. Update to also remove households and show the count in the confirmation dialog.

3. **Add an upcoming birthdays widget** — Show persons with birthdays in the next 7–14 days on the list view or a dedicated tab to make the directory proactively useful.

### Part 2: Export Code Enhancement — Fully Buildable Project
The "💾 Export Code" button previously exported only source files without project configuration, meaning the export couldn't be built or run standalone.

#### Changes to `App.tsx`
- Added new `?raw` imports for previously missing files: `countryCodes.ts`, `main.tsx`, `vite-env.d.ts`, `CountryCodeSelect.tsx`
- Rewrote `handleDownloadCode` to include:
  - **`package.json`** — Standalone dependencies (react, papaparse, uuid, vite, typescript) without proprietary runtime lib
  - **`tsconfig.json`** — TypeScript configuration
  - **`vite.config.ts`** — Simplified Vite config (react + tsconfig-paths plugins only)
  - **`index.html`** — Clean entry point without sandbox/bridge infrastructure
  - **`README.md`** — Getting started instructions, build commands, and notes about replacing Quick Suite storage calls
  - All 17 source files in correct directory structure
- Updated the shell script's output messages to include "To get started: cd directory-app && npm install && npm run dev"

#### Export Now Produces
Running `bash directory-app.sh` creates a fully structured project:
```
directory-app/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── index.html
├── README.md
├── DEVLOG.md
└── src/
    ├── main.tsx
    ├── vite-env.d.ts
    ├── types.ts
    ├── styles.ts
    ├── utils.ts
    ├── storage.ts
    ├── countryCodes.ts
    ├── App.tsx
    └── components/
        ├── AddressFields.tsx
        ├── MultiItemField.tsx
        ├── CountryCodeSelect.tsx
        ├── RelationshipPicker.tsx
        ├── SpousePicker.tsx
        ├── HouseholdPicker.tsx
        ├── HouseholdView.tsx
        ├── DuplicateWarning.tsx
        └── Toolbar.tsx
```

---

## Session 25 — Delete All Now Includes Households

### Problem
The "Delete All" button removed all persons and companies but left household records intact in storage, creating orphaned households.

### Solution
Updated the delete-all flow to also remove all households and show the household count in the confirmation dialog.

#### Changes to `App.tsx`

**`handleDeleteAll` function:**
- Added a loop to delete all households after deleting entries: `for (const h of households) await removeHousehold(h.id);`

**Delete All confirmation dialog:**
- Now conditionally shows household count: *"Are you sure you want to delete **all 5 entries** and **2 households**?"*
- Only shows the household clause when `households.length > 0`
- Singular/plural handled correctly for both entries and households

---

## Session 26 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 24–26 reflecting the latest conversation history

---

## Session 27 — Cancel Form Clears Validation Error

### Problem
When opening the "Add Person" or "Add Company" form, entering invalid data (e.g., an address missing city or state), and then clicking "Cancel," the validation error message ("Please complete all addresses — at least city and state are required.") would persist and display on the list view. Since the user canceled the action, no error message should be shown.

### Solution
Added `setError('')` to the Cancel button click handlers in both the Person and Company forms.

#### Changes to `App.tsx`
- **Person form Cancel button**: Changed from `{ resetPersonForm(); setView('list'); }` to `{ resetPersonForm(); setError(''); setView('list'); }`
- **Company form Cancel button**: Changed from `{ resetCompanyForm(); setView('list'); }` to `{ resetCompanyForm(); setError(''); setView('list'); }`

---

## Session 28 — Form Validation Prevents Saving Invalid Emails & Phone Numbers

### Problem
The EmailInput and PhoneInput components showed inline validation errors (red border + message) when a value was invalid, but these were purely informational. The form could still be submitted with invalid values, resulting in malformed data stored in the directory.

### Solution
Added validation checks in both `savePerson` and `saveCompany` that block form submission if any email or phone field contains an invalid value.

#### New Utility Functions Added to `utils.ts`
| Function | Logic |
|----------|-------|
| `isValidEmail(address)` | Returns `true` if empty (will be filtered out) or matches `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` |
| `isValidPhone(number)` | Returns `true` if empty (will be filtered out) or contains only valid characters (`0-9`, spaces, dashes, parens, dots, plus) AND has at least 7 digits |

These mirror the exact validation logic used in the `EmailInput` and `PhoneInput` components.

#### Changes to `App.tsx`
- Imported `isValidEmail` and `isValidPhone` from `./utils`
- **`savePerson`**: Added checks after name/gender validation:
  - If any email has an invalid address → error: "Please fix invalid email addresses before saving."
  - If any phone has an invalid number → error: "Please fix invalid phone numbers before saving."
- **`saveCompany`**: Added the same checks after name validation

#### Validation Order (both forms)
1. Required fields (name, gender for persons)
2. Email validation
3. Phone validation
4. Address completeness (city + state required)
5. Website URL validation (company only)

---

## Session 29 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 27–29 reflecting the latest conversation history

---

## Session 30 — Auto-Scroll to Error on Failed Form Validation

### Problem
When a form validation check fails (e.g., missing required fields, invalid email/phone, incomplete address), the error message appears at the top of the content area. If the user has scrolled down to the bottom of a long form, they won't see the error message without manually scrolling back up.

### Solution
Added automatic smooth scrolling to the error message when validation fails, ensuring the user immediately sees what needs to be fixed.

### Changes to `App.tsx`
- Added `errorRef` (`useRef<HTMLDivElement>`) attached to the error message div
- Created `setErrorAndScroll(msg)` helper that sets the error message and then uses `scrollIntoView({ behavior: 'smooth', block: 'nearest' })` to scroll the error into view (via `setTimeout` to ensure the DOM has rendered)
- Replaced `setError(...)` with `setErrorAndScroll(...)` in all validation checks within:
  - `savePerson`: name, gender, email, phone, and address validation
  - `saveCompany`: name, email, phone, address, and website validation
- Added `ref={errorRef}` to the error display div

---

## Session 31 — Phone Validation on Blur

### Action
Created a new `PhoneInput` component at `webapp/src/components/PhoneInput.tsx` that validates phone numbers when the user leaves the field (on blur), mirroring the pattern established by `EmailInput`.

### Validation Rules
- Only valid characters allowed: digits, spaces, dashes, parentheses, dots, plus signs
- Minimum 7 digits required

### Behavior
- Shows red error message "Please enter a valid phone number" below the field when validation fails
- Input border turns red to highlight validation issues
- Error clears automatically when user starts typing again
- Integrates `CountryCodeSelect` dropdown directly within the component

### Changes
- Created `webapp/src/components/PhoneInput.tsx`
- Integrated into both person and company phone fields in `App.tsx`
- Removed now-unused direct `CountryCodeSelect` import from `App.tsx`
- Added PhoneInput source to the code export feature

---

## Session 32 — Household Chip Remove Error Management

### Problem
When removing a member using the "×" button on their chip in the Household form:
- Dropping below 2 members didn't show the `hhMembers` validation error
- Removing the primary contact auto-reassigned primary to the first remaining member, but didn't clear the `hhPrimary` error if it was previously set

### Solution
Added symmetric error management to the chip remove handler in `HouseholdView.tsx`.

### Changes to `components/HouseholdView.tsx`
- **Shows `hhMembers` error** when removing a member drops the count below 2
- **Clears `hhMembers` error** if the count is still ≥ 2 after removal
- **Clears `hhPrimary` error** when the primary contact is auto-reassigned to a valid remaining member
- **Shows `hhPrimary` error** if all members are removed and no primary can be assigned
- Uses `setFieldErrors` with a functional update to compute the effective primary based on whether the removed member was the current primary

---

## Session 33 — Spouse & Children Picker Relationship Filters

### Part 1: Spouse Picker — Opposite Sex Filter
Added a `currentGender` prop to `SpousePicker` to filter candidates to only persons of the opposite sex, enforcing that married couples must be male/female.

#### Changes to `components/SpousePicker.tsx`
- Added `currentGender: string` to `SpousePickerProps` interface
- In the eligible filter, added: if both the current person and a candidate have a gender set and they match, the candidate is excluded
- If either person's gender is unset (empty string), no gender filtering is applied (allows picking a spouse when gender hasn't been specified)

#### Changes to `App.tsx`
- Passed `currentGender={pGender}` to the `SpousePicker` component

### Part 2: Children Picker — Exclude Parents
Added an explicit parent check to the children picker filter to prevent a person's parent from being listed as a potential child.

#### Changes to `App.tsx`
- Added: `if (editId && p.childIds.includes(editId)) return false;` — directly excludes any person who already has the current person listed as their child
- This complements the existing `getAncestorIds` cycle detection with a clear, direct parent check

---

## Session 34 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 31–34 reflecting the latest conversation history

---

## Session 35 — Profile Image Upload Feature

### Action
Added the ability for persons, companies, and households to upload a profile image that replaces the default emoji badge in list and detail views.

### New Components Created

#### `components/ProfileImage.tsx`
A reusable circular avatar component:
- Displays either an uploaded image or a fallback emoji (👤, 🏢, 🏠)
- **Editable mode**: Shows a camera overlay on hover and a remove (×) button when an image exists
- Clicking the avatar opens a file picker for image selection
- Uses `data:` URLs compatible with the CSP (`img-src data: blob:`)

#### `components/ImageCropper.tsx`
An interactive circular crop overlay modal:
- **Circular crop preview** — 240px circular window with a blue border shows exactly how the photo will appear
- **Drag to pan** — Click and drag to reposition the image (uses Pointer Events for mouse and touch)
- **Zoom control** — Mouse wheel/trackpad scroll on the crop area, plus a slider with − and + labels
- **Zoom range** — 1× (image fills the circle) to 4× magnification
- **Boundary clamping** — Image can't be dragged beyond its edges
- **Confirm/Cancel buttons** — Renders final 200×200px JPEG crop; compresses progressively to stay under 300KB
- Appears automatically when an image file is selected

### Storage

#### New Table: `directory-images`
- Added `IMAGES_TABLE` constant to `types.ts`
- Added CRUD functions to `storage.ts`: `saveImage`, `loadImage`, `loadAllImages`, `removeImage`
- Images stored as base64 data URLs (max ~300KB each)
- Images loaded in bulk on app mount alongside entries and households
- Images cleaned up when entries/households are deleted (including "Delete All")

### Integration Points
1. **List view** — Profile images replace emoji badges next to each entry name (36px)
2. **Detail view** — Larger (64px) profile image replaces the large emoji at the top
3. **Search dropdown** — Small (24px) profile images next to search results
4. **Person form** — Image upload widget at the top of the form (72px, editable)
5. **Company form** — Image upload widget at the top of the form (72px, editable)
6. **Household cards** — Profile images on household list cards (36px)
7. **Household form** — Image upload widget at the top of the form (72px, editable)

### Changes to `App.tsx`
- Added `images` state (`Record<string, string>`)
- Added `pImage` and `cImage` form state for person/company image editing
- Updated `reload` to also call `loadAllImages()`
- Updated `fillPersonForm` / `fillCompanyForm` to load existing images
- Updated `savePerson` / `saveCompany` to save/remove images
- Updated `confirmDelete` / `handleDeleteAll` to also remove images
- Replaced emoji badges with `<ProfileImage>` in list, detail, and search views
- Added `?raw` imports for `ProfileImage.tsx` and `ImageCropper.tsx` for code export

### Changes to `components/HouseholdView.tsx`
- Added `images` prop to `HouseholdViewProps`
- Added `hhImage` state for household image editing
- Profile image upload in household form
- Profile images on household list cards
- Image save/remove on household save/delete

---

## Session 36 — Image Export/Import as Separate JSON File

### Problem
The CSV export did not include profile images from the `directory-images` table.

### Solution
Added a separate JSON file export for images alongside the CSV, keeping the CSV lightweight and human-readable while providing a complete backup/restore path.

### Export Behavior (📥 Export CSV button)
1. **`directory-export.csv`** — Existing CSV with entries and households (unchanged)
2. **`directory-images.json`** — New JSON file with all profile images as `{ "entity-id": "data:image/jpeg;base64,..." }`. Only downloaded if images exist.

### Import Behavior (📤 Import CSV button)
File picker now accepts both `.csv` and `.json` files:
- **`.csv` files** — Imported as before (entries + households via preview flow)
- **`.json` files** — Recognized as images backup; parses JSON and saves each image to storage. Shows success toast with count.

### Changes to `App.tsx`
- Updated `handleExportCsv` to also download `directory-images.json` when images exist
- Updated `handleFileSelect` to detect `.json` files and import images directly
- Changed file input `accept` attribute from `.csv` to `.csv,.json`

---

## Session 37 — Image Cropper Enhancement (Interactive Circular Crop)

### Action
Replaced the automatic center-crop with an interactive cropper that gives users full control over how their photo appears.

### Flow
1. User clicks the profile image avatar → file picker opens
2. User selects an image → the **ImageCropper** modal appears with the full image loaded
3. User drags to reposition and zooms to frame their subject within the circular preview
4. User clicks **Confirm** → cropped 200×200px JPEG result is set as the profile image
5. Clicking **Cancel** or the backdrop dismisses without changes

### Technical Details
- Crop preview area: 240px diameter circle with blue border
- Output: 200×200px JPEG, progressively compressed to stay under 300KB
- Zoom: 1× to 4×, controllable via mouse wheel or range slider
- Pan: Pointer events for cross-device support (mouse + touch)
- Boundary clamping prevents blank areas in the crop

---

## Session 38 — Explicit `imageId` Column for CSV-to-JSON Linking

### Problem
The relationship between `directory-export.csv` and `directory-images.json` was implicit (both used entity IDs as keys). If CSV entries got new UUIDs during import (without `_json` column), image associations would be lost.

### Solution
Added an explicit `imageId` column to both entry and household CSV sections that references the key in the images JSON.

### Changes to `storage.ts`

**Entry CSV:**
- Added `imageId` to `CSV_HEADERS` array
- Updated `entryToCsvRow` to accept `images` parameter and populate `imageId` (entity ID if image exists, empty otherwise)
- Updated `exportCsv` signature to accept `images`

**Household CSV:**
- Added `imageId` to `HOUSEHOLD_CSV_HEADERS` array
- Updated `householdToCsvRow` to accept `images` parameter and populate `imageId`
- Updated `exportHouseholdsCsv` signature to accept `images`

**Full CSV Export:**
- Updated `exportFullCsv` to accept and pass `images` through to both export functions

**CSV Import:**
- Updated `parseCsvFile` return type to include `imageIdMap: Record<string, string>` (maps new entry ID → original imageId)
- Extracts `imageId` from each CSV row during parsing
- Returns the mapping for use during import confirmation

### Changes to `App.tsx`
- Passes `images` to `exportFullCsv(entries, households, images)`
- Added `importImageIdMap` state
- Updated `handleFileSelect` to capture `imageIdMap` from parsed CSV
- Updated `handleImportConfirm` to re-link images: when an imported entry has an `imageId` pointing to an existing image in storage, the image is copied to the new entry's ID
- Updated `handleImportCancel` to clear `importImageIdMap`

### Import Workflow for Full Restore
1. Import `directory-images.json` first → images loaded into storage
2. Import `directory-export.csv` → entries parsed with `imageId` references
3. On confirm → images automatically re-linked to new entries via `imageId` mapping

---

## Session 39 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 35–39 reflecting the latest conversation history

---

## Session 40 — Profile Image Remove Button Clipping Fix

### Problem
On the edit forms for person, company, and household, the profile image displayed a small red crescent in the top-right corner of the circle. This was the "remove photo" button (×) being clipped by the container's `overflow: hidden` into a crescent shape. In non-editable views (list and detail), the button doesn't render, so no crescent appeared.

### Root Cause
The remove button was absolutely positioned at `top: -2, right: -2` **inside** the circular container that has `overflow: hidden`. The container clipped the button, showing only the portion that fell within the circle boundary — creating the crescent artifact.

### Solution
Moved the remove button **outside** the clipped container by adding an outer wrapper div.

#### Changes to `components/ProfileImage.tsx`
- Added an outer wrapper `<div>` with `position: relative`, matching the avatar's `width` and `height`
- The circular container (with `overflow: hidden`) remains unchanged inside the wrapper
- The remove button is now a sibling of the circular container, positioned absolutely within the outer wrapper
- Added `zIndex: 1` to the remove button to ensure it renders above the avatar
- The button is no longer subject to `overflow: hidden` clipping

### Structure (before → after)
**Before:**
```
<div style={containerStyle (overflow: hidden, borderRadius: 50%)}>
  <img ... />
  <button (remove) /> ← CLIPPED by parent's overflow
</div>
```

**After:**
```
<div style={outerWrapper (position: relative)}>
  <div style={containerStyle (overflow: hidden, borderRadius: 50%)}>
    <img ... />
  </div>
  <button (remove) /> ← NOT clipped, positioned relative to outer wrapper
</div>
```

---

## Session 41 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 40–41 reflecting the latest conversation history

---

## Session 42 — Pagination Controls on Directory List View

### Action
Added pagination controls to the main directory list view to improve performance and usability as the directory grows.

### State Added to `App.tsx`
- `pageSize` — Number of entries per page (default: 25, options: 25/50/100)
- `currentPage` — Current page number (1-based)

### Computed Values
- `totalEntries` — Total number of filtered entries
- `totalPages` — Calculated from total entries / page size
- `safeCurrentPage` — Clamped to valid range (handles edge cases when filters reduce results)
- `pageStart` / `pageEnd` — Slice indices for the current page
- `paginatedEntries` — The subset of entries displayed on the current page

### Auto-Reset
- Page resets to 1 automatically when search query, type filter, industry filter, sort field, or sort direction changes (via `useEffect`)

### UI Controls
1. **Top bar** — Shows "Showing 1–25 of 142 entries" with per-page size buttons (25/50/100), highlighted active size
2. **Bottom navigation** — Shows « ‹ Page X of Y › » buttons:
   - First page («) and last page (») jump buttons
   - Previous (‹) and next (›) buttons
   - All buttons disabled appropriately at boundaries
   - Only appears when there are multiple pages

### Changes to `App.tsx`
- Added `pageSize` and `currentPage` state
- Added `useEffect` to reset page on filter/sort/search changes
- Added pagination computed values after `filteredEntries`
- Replaced `filteredEntries.map(...)` with `paginatedEntries.map(...)`
- Added pagination info bar above the cards
- Added pagination navigation below the cards

---

## Session 43 — Pagination Controls on Households List View

### Action
Added the same pagination controls to the Households list view for consistency.

### Changes to `components/HouseholdView.tsx`
- Added `pageSize` and `currentPage` state (default: 25)
- Added pagination computed values: `totalHouseholds`, `totalPages`, `safeCurrentPage`, `pageStart`, `pageEnd`, `paginatedHouseholds`
- Replaced `households.map(...)` with `paginatedHouseholds.map(...)`
- Added pagination info bar: "Showing 1–25 of X households" with per-page buttons (25/50/100)
- Added bottom navigation: « ‹ Page X of Y › » (only shown when multiple pages exist)

---

## Session 44 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 42–44 reflecting the latest conversation history

---

## Session 45 — Family Tree Visualization

### Action
Added a visual family tree/graph to the person detail view that displays parent-child, spouse, and sibling relationships at a glance.

### New Component: `components/FamilyTree.tsx`
An SVG-based tree visualization with three rows:

| Row | Content | Color |
|-----|---------|-------|
| Top | Parents (persons whose `childIds` include this person) | Purple |
| Middle | Self + Spouse + Siblings | Blue (self), Pink (spouse), Gray (siblings) |
| Bottom | Children | Green |

### Features
- **Color-coded nodes** — Each role has a distinct background and border color
- **Profile images** — Circular profile photos in each node (fallback to 👤 emoji)
- **Connecting lines** — Solid lines for direct relationships, dashed for indirect
- **Interactive** — Clicking any node (except self) navigates to that person's detail view
- **Siblings auto-detected** — Found by looking at other children of the same parents
- **Responsive** — Horizontally scrollable when tree is wider than viewport
- **Legend** — Compact color legend below the tree
- **Graceful fallback** — Shows "No family relationships to display" when no relationships exist

### Layout
- Nodes: 100×72px with 20px horizontal and 50px vertical gaps
- Each row centered horizontally, SVG width/height adjusts dynamically

### Integration
- Added `FamilyTree` import and render in App.tsx detail view under "Family Tree" section
- Added `?raw` import and code export entry for `FamilyTree.tsx`

---

## Session 46 — Multi-Generation Family Tree Expansion

### Action
Enhanced the Family Tree component to support multi-generation expansion with interactive "+" buttons on expandable nodes.

### New Features

**Expand/Collapse Nodes:**
- Parent nodes with their own parents show a **+** button above them — clicking reveals grandparents
- Child nodes with their own children show a **+** button below them — clicking reveals grandchildren
- Clicking **−** collapses an expanded node
- Expansion state tracked per-node via `expandedIds` state (Set)

**New Roles Added:**
| Role | Color | Description |
|------|-------|-------------|
| Grandparent+ | Dark purple (`#4a148c`, bg `#ede7f6`) | Any ancestor beyond direct parents |
| Grandchild+ | Dark green (`#1b5e20`, bg `#c8e6c9`) | Any descendant beyond direct children |

**Recursive Expansion:**
- Tree grows dynamically: expanding a grandparent reveals great-grandparents, and so on
- Same for descendants: expanding a grandchild reveals great-grandchildren
- No depth limit — follows the data as deep as relationships exist
- Each expanded level adds a new row to the SVG

**Visual Indicators:**
- **+** circle on nodes with further generations to reveal (positioned above ancestors, below descendants)
- **−** circle on already-expanded nodes (click to collapse)
- Dashed lines connect expanded generations to distinguish from direct relationships

**Technical Implementation:**
- `expandedIds` state (Set<string>) tracks which nodes are expanded
- `getParents` and `getChildren` helper functions for traversal
- Ancestor rows built by recursively expanding upward from parents
- Descendant rows built by recursively expanding downward from children
- `parentLinkIds` on each expanded row item tracks which node it connects back to
- SVG height dynamically adjusts based on number of visible rows
- `ROLE_COLORS` lookup table for consistent styling across all 7 role types

**Updated Legend:**
- Added "Grandparent+" and "Grandchild+" entries
- Added helper text: "Click + on a node to expand further generations. Click a name to navigate."

### Changes to `components/FamilyTree.tsx`
- Complete rewrite from static 3-row layout to dynamic multi-row expandable tree
- Added `useState` for `expandedIds`, `useCallback` for `toggleExpand`, `getParents`, `getChildren`
- `PersonNode` component now accepts `onToggleExpand` prop and renders +/− button when `expandable`
- `useMemo` recalculates layout whenever `expandedIds` changes

---

## Session 47 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 45–47 reflecting the latest conversation history

---

## Session 48 — Collapsible Detail View Sections

### Action
Added expand/collapse toggles to each section in the detail view with per-user persistence via private storage.

### New Component: `components/CollapsibleSection.tsx`

**`CollapsibleSection`** — A wrapper component that renders a section header with a ▶/▼ toggle indicator. Clicking the header expands or collapses the section content.

**`useCollapsedSections` hook** — Manages which sections are collapsed:
- Loads collapsed section IDs from private storage (`user-preferences` table, key `detail-collapsed-sections`) on first mount
- Caches in memory to avoid redundant API calls across re-renders
- Saves updated state back to private storage whenever a section is toggled
- Per-user persistence — each user's collapsed preferences are independent (uses `putPrivateItem`/`getPrivateItem`)

### Sections Made Collapsible

| Section ID | Title | Applies To |
|------------|-------|-----------|
| `website` | Website | Companies |
| `personal-info` | Personal Information | Persons |
| `emails` | Email Addresses | Both |
| `phones` | Phone Numbers | Both |
| `addresses` | Addresses | Both |
| `relationships` | Relationships | Persons |
| `family-tree` | Family Tree | Persons |
| `household` | Household | Persons |
| `contact-persons` | Contact Persons | Companies |
| `notes` | Notes | Both |

### Behavior
- All sections start **expanded** by default (first-time users see everything)
- Clicking a section header toggles between expanded (▼) and collapsed (▶)
- Collapsed state persists across sessions via private storage
- No content is rendered when collapsed (improves performance for heavy sections like Family Tree)
- Section header styling matches existing `S.section` style with added cursor pointer and flex layout

### Changes to `App.tsx`
- Imported `CollapsibleSection` and `useCollapsedSections` from new component
- Added `useCollapsedSections()` hook call near other state declarations
- Wrapped all detail view sections with `<CollapsibleSection>` passing unique `id`, `title`, `collapsed` state, and `onToggle` handler
- Added `?raw` import and code export entry for `CollapsibleSection.tsx`

### Storage
- Table: `user-preferences` (private)
- Key: `detail-collapsed-sections`
- Value: JSON array of collapsed section IDs (e.g., `["family-tree", "notes"]`)

---

## Session 49 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 48–49 reflecting the latest conversation history

---

## Current File Structure

```
webapp/src/
├── App.tsx                          # Main orchestrator component
├── types.ts                         # Interfaces, type aliases, constants
├── styles.ts                        # Colors and style definitions
├── utils.ts                         # Utility functions and custom hooks
├── storage.ts                       # Storage operations, CSV helpers, image CRUD
├── countryCodes.ts                  # Country code data
├── usStates.ts                      # US states data
├── main.tsx                         # React entry point
├── vite-env.d.ts                    # Vite type declarations
├── DEVLOG.md                        # This development log
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── CountryCodeSelect.tsx        # Country code dropdown
│   ├── RelationshipPicker.tsx       # Relationship selection
│   ├── SpousePicker.tsx             # Spouse selection with eligibility filtering
│   ├── HouseholdPicker.tsx          # Household member management
│   ├── HouseholdView.tsx            # Household CRUD view
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   ├── Toolbar.tsx                  # Sort/filter toolbar
│   ├── EmailInput.tsx               # Email input with blur validation
│   ├── PhoneInput.tsx               # Phone input with blur validation
│   ├── ProfileImage.tsx             # Profile image avatar with upload
│   └── ImageCropper.tsx             # Interactive circular crop overlay
└── assets/
    ├── dashboard-placeholder-chart-icon.svg
    └── dashboard-placeholder-error-icon.svg
```

## Registered Integrations
- **AI Inference** (`ai-inference`): Used for address auto-suggest functionality (Claude Haiku model)

## Storage Tables
| Table Name | Purpose | Key |
|------------|---------|-----|
| `directory-entries` | Persons and companies | Entity UUID |
| `directory-households` | Household groups | Household UUID |
| `directory-images` | Profile images (base64 data URLs) | Entity/Household UUID |
