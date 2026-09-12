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
| `user-preferences` (private) | Collapsed section state per user | `detail-collapsed-sections` |

---

## Session 50 — Address Line 2 Field Added

### Action
Added an optional "Address Line 2" field to all address forms across the application, allowing users to capture apartment numbers, suite numbers, floor numbers, and similar secondary address information.

### Changes

#### `types.ts`
- Added `street2: string` to the `Address` interface
- Added `street2: ''` to the `EMPTY_ADDR` constant

#### `utils.ts`
- Updated `formatAddr()` to include `street2` in the formatted address display (empty values are filtered out automatically by `.filter(Boolean)`)
- Updated `migrateEntry()` to add `street2: ''` to any legacy addresses missing the field, ensuring backward compatibility with existing stored data

#### `components/AddressFields.tsx`
- Added an "Address Line 2" input field between the Street and City fields
- Label includes "(optional)" indicator in secondary text color
- Placeholder text: "Apt, Suite, Floor, etc."
- Field respects `readOnly` state for household-managed addresses (disabled when managed by household)
- Updated the `add()` function in `MultiAddressFields` to include `street2: ''` in newly created addresses

#### `components/HouseholdView.tsx`
- Added an "Address Line 2" input field to the `HouseholdAddressSection` component, positioned between Street and City
- Same label, placeholder, and styling as the person/company address form

#### `storage.ts`
- Added `primaryStreet2` to `CSV_HEADERS` array
- Added `primaryStreet2` output in `entryToCsvRow()` (reads from primary address's `street2`)
- Added `street2` to `HOUSEHOLD_CSV_HEADERS` array
- Added `street2` output in `householdToCsvRow()`
- Updated `csvRowToEntry()` to parse `primaryStreet2` from CSV and include it in constructed addresses
- Updated `csvRowToHousehold()` to parse `street2` from CSV and include it in constructed household addresses

### Behavior
- The field is completely optional — leaving it blank has no effect on validation or display
- Existing data without `street2` is gracefully handled:
  - `migrateEntry()` adds `street2: ''` during data loading
  - Form inputs use `addr.street2 || ''` as a fallback
  - `formatAddr()` filters out empty/falsy values, so addresses without a street2 display identically to before
- CSV export includes the column (empty for entries without street2)
- CSV import reads the column if present (defaults to empty string if missing)

---

## Session 51 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **vCard (.vcf) Export for Individual Contacts** — Add a "Download vCard" button to the detail view that generates a standard `.vcf` file for the selected person or company, enabling easy sharing with other address book applications.

2. **Dark Mode Toggle** — Add a persistent dark mode option toggled via a header button, with the preference saved per-user via private storage so it persists across sessions.

3. **Upcoming Birthdays Widget** — Add a section above the directory list highlighting birthdays occurring within the next 30 days, showing the person's profile image, name, date, and days until the birthday.

---

## Session 52 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 50–52 reflecting the latest conversation history

---

## Session 53 — Status Field for Deceased/Closed Entries

### Action
Added status fields for both persons and companies, allowing entries to be marked as inactive while remaining visible in the directory with visual distinction.

### Type Changes (`types.ts`)
- Added `EntryStatus = 'active' | 'deceased' | 'archived'` type
- Added `CompanyStatus = 'active' | 'closed' | 'archived'` type (originally included 'acquired', later removed in Session 55)
- Added `status?: EntryStatus` and `deceasedDate?: string` to `Person` interface
- Added `companyStatus?: CompanyStatus` and `closedDate?: string` to `Company` interface
- Added `StatusFilter = 'active' | 'deceased' | 'closed' | 'all'` type

### Migration (`utils.ts`)
- Updated `migrateEntry` to default `status: 'active'` and `deceasedDate: ''` for persons
- Updated `migrateEntry` to default `companyStatus: 'active'` and `closedDate: ''` for companies
- Added migration from old `status`/`deceasedDate` fields on companies to new `companyStatus`/`closedDate`

### Toolbar Status Filter (`components/Toolbar.tsx`)
- Added status filter buttons: Active, Deceased, Closed, All
- Gray background for inactive status buttons when selected
- Clear filters button updated to also reset status filter

### Upcoming Birthdays Widget (`components/UpcomingBirthdays.tsx`)
- New component showing active persons with birthdays in the next 30 days
- Sorted by proximity (nearest birthday first)
- Shows profile image, name, birthday date, and days until
- Click-to-navigate to person detail view
- Only shows active (non-deceased) persons

### vCard Export (`components/VCardExport.tsx`)
- New component generating vCard 3.0 files for persons and companies
- Includes: structured names, emails with types, phones with types, addresses, notes, birthday, organization, website
- Supports embedded profile photos (base64-encoded in the vCard)
- Export button added to detail view toolbar

### Family Tree Deceased Indicators (`components/FamilyTree.tsx`)
- Added `deceased` flag to `TreeNode` interface
- Deceased nodes render with gray background/border, reduced opacity (0.75), dimmed text
- ✝ symbol displayed in the top-right corner of deceased nodes
- Legend updated with "✝ Deceased" entry

### App.tsx Integration
- Person form: Status dropdown (Active/Deceased) + conditional "Date of Death" date input
- Company form: Status dropdown (Active/Closed) + conditional "Date Closed" date input
- `filteredEntries` logic: filters by status based on entry type
- List cards: Inactive entries shown with 0.7 opacity, gray left border, and status badges (✝ DECEASED, 🚫 CLOSED)
- Detail view: Status badges shown below name with date info
- vCard export button added to detail view toolbar
- Suppressed "User declined file download" error on vCard cancel

### Constraints
- Archived entries never shown in any filter view
- Deceased/closed entries remain visible but visually distinct
- "User declined file download" message suppressed for vCard cancellation

---

## Session 54 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Keyboard Shortcuts & Accessibility** — Add keyboard shortcuts for common actions and improve ARIA labels, focus management, and screen reader support.

2. **Contact Activity Timeline** — Track changes per entry with timestamps to show modification history.

3. **Smart Search with Filters Inline** — Support typed queries like `type:person city:Austin` with autocomplete, unifying search and filtering into a single input.

---

## Session 55 — Filter UI Redesign & Removal of "Acquired" Status

### Part 1: Filter UI Redesign — New `FilterBar` Component
Replaced the crowded `Toolbar` component with a cleaner, more logically organized `FilterBar` that uses progressive disclosure.

#### Old Toolbar (removed: `components/Toolbar.tsx`)
- All controls in a single row: sort dropdown, sort direction, type buttons, status buttons, industry dropdown, clear button
- Cluttered and hard to scan, especially on smaller screens

#### New FilterBar (`components/FilterBar.tsx`)
**Always-visible summary row (compact):**
- Sort controls — minimal dropdown + direction toggle arrow
- "Filters (N)" toggle button — shows active filter count, expands the panel
- Active filter chips — removable pills showing what's currently filtered (e.g., "👤 Persons", "✝ Deceased", "🏷 Tech")
- "Clear all" link when filters are active
- Result count aligned to far right

**Expandable filter panel (on demand):**
When the "Filters" button is clicked, a clean panel opens below with organized sections in a responsive grid:
- **Entry Type** — segmented button group (All / Person / Company)
- **Status** — context-sensitive segmented button group (changes based on selected type)
- **Industry** — dropdown (only shown when relevant)

### Part 2: Context-Sensitive Status Filter
Status filter options now dynamically change based on the selected entry type:

| Type Filter | Status Options Shown |
|-------------|---------------------|
| Person | ● Active, ✝ Deceased, ○ All |
| Company | ● Active, 🚫 Closed, ○ All |
| All | ● Active, ✝ Deceased, 🚫 Closed, ○ All |

- If the user changes type and the current status filter is no longer valid (e.g., was "deceased" and switched to "company"), it auto-resets to "active"

### Part 3: Removal of "Acquired" Company Status
The "Acquired" value was removed from the list of valid company statuses, simplifying to just Active and Closed.

#### Changes to `types.ts`
- `CompanyStatus` updated from `'active' | 'closed' | 'acquired' | 'archived'` to `'active' | 'closed' | 'archived'`

#### Changes to `utils.ts`
- Migration function now converts any old `'acquired'` values to `'closed'` for backward compatibility

#### Changes to `App.tsx`
- Company form dropdown: only "Active" and "Closed" options
- Form state type narrowed from `'active' | 'closed' | 'acquired'` to `'active' | 'closed'`
- List card badges simplified (no more "🤝 ACQUIRED" badge)
- Detail view: removed separate acquired badge and border logic
- `fillCompanyForm`: maps any old acquired status to `'closed'`
- Filter logic: `'closed'` filter only checks for `companyStatus === 'closed'`
- Removed unused `CompanyStatus` import

---

## Session 56 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Saved Filter Presets** — Allow users to save frequently used filter combinations as named presets for quick-access.

2. **Batch/Bulk Actions with Multi-Select** — Add multi-select mode for bulk status changes, exports, or deletions.

3. **Entry Last-Modified Timestamps & "Recently Updated" Sort** — Track modification dates and add a "Recently Updated" sort option.

---

## Session 57 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 53–57 reflecting the latest conversation history

---

## Session 58 — Bulk Actions with Multi-Select

### Action
Added multi-select mode to the directory list view with a floating bulk actions bar for performing operations on multiple entries simultaneously.

### New Component: `components/BulkActions.tsx`
A floating dark-themed action bar that appears at the bottom of the screen when entries are selected.

**Actions Available:**
| Action | Description |
|--------|-------------|
| 📇 Export vCard | Exports all selected entries as a combined `.vcf` file |
| ⚡ Change Status | Opens status picker dialog (Active/Deceased/Closed) |
| 🏠 Assign Household | Opens searchable household picker (persons only, companies skipped) |
| 🗑️ Delete | Delete all selected entries with cascade effects display |
| Clear | Deselects all entries |

**Delete Confirmation Dialog:**
- Lists all entries being deleted
- Shows cascade side effects (unlinking spouses, removing from parents' children, removing from companies' contacts)
- "This action cannot be undone" warning

**Status Change Dialog:**
- Two-step flow: first pick the status, then confirm
- Shows affected entries filtered by type
- Context-aware: "Deceased" only shown when persons are selected, "Closed" only for companies

**Household Assignment Dialog:**
- Two-step flow: first pick the household, then confirm
- Searchable household list
- Confirmation shows each person and their current household (if being moved)
- Note about persons being moved from other households

### Multi-Select State in `App.tsx`
- `selectMode` — Boolean toggle for selection mode
- `selectedIds` — `Set<string>` of selected entry IDs (persists across pages)
- "☐ Select" button in toolbar toggles select mode
- Checkboxes appear on each card when in select mode
- "Select All" / "Select None" quick buttons above the list
- Clicking a card in select mode toggles its selection (instead of navigating to detail)

### Bulk Handlers in `App.tsx`
- `handleBulkDelete(ids)` — Deletes entries with full cascade cleanup (spouse, parent, company, household)
- `handleBulkStatusChange(ids, status)` — Updates status for each entry (maps incompatible statuses to 'active')
- `handleBulkAssignHousehold(personIds, householdId)` — Removes persons from old households, adds to new household, syncs addresses

### Constraints
- Selection persists across pages so users can pick entries from different pages before acting
- Companies are skipped during bulk household assignment (only persons are assignable)
- A person can only belong to one household; bulk assign removes from old household before adding to new

---

## Session 59 — Bulk Assign Household Bug Fix (Stale State)

### Problem
When bulk-assigning two persons from the same old household to a new household:
1. Person A's reassignment worked correctly
2. Person B appeared in **both** the old and new households after the operation

**Root Cause:** The `handleBulkAssignHousehold` function read old household data from the React `households` state array, which is a stale snapshot captured when the function started. After Person A was removed from the old household and saved to storage, the stale state still showed Person A in the old household's `memberIds`. When Person B was processed, filtering the stale `memberIds` to remove only Person B resulted in re-saving the old household with Person A still in it — effectively undoing Person A's removal.

### Solution
Changed the old household lookup from `households.find(h => h.id === person.householdId)` (stale React state) to `await loadHousehold(person.householdId)` (fresh from storage). Also changed the target household lookup to `await loadHousehold(householdId)`. This ensures each iteration sees the current state of households, including any changes made by prior iterations.

#### Changes to `App.tsx`
- Added `loadHousehold` to imports from `./storage`
- In `handleBulkAssignHousehold`:
  - Replaced `households.find(h => h.id === householdId)` with `await loadHousehold(householdId)`
  - Replaced `households.find(h => h.id === person.householdId)` with `await loadHousehold(person.householdId)`
  - Added comment explaining the stale state issue

---

## Session 60 — Confirmation Dialogs for Bulk Status Change & Household Assignment

### Action
Added two-step confirmation dialogs to the "Change Status" and "Assign Household" bulk actions, matching the pattern already established by the "Delete" bulk action.

### Changes to `components/BulkActions.tsx`

**New State:**
- `showStatusConfirm` — `'active' | 'deceased' | 'closed' | null` — tracks which status was picked, triggers confirmation dialog
- `showHouseholdConfirm` — `Household | null` — tracks which household was selected, triggers confirmation dialog

**Status Change Flow (before → after):**
- Before: Pick status → immediately executes status change
- After: Pick status → confirmation dialog shows affected entries → "Confirm" executes

**Status Confirmation Dialog:**
- Title: "⚡ Confirm Status Change"
- Shows count and new status in question form (e.g., "Set 3 persons to Deceased?")
- Lists affected entries (filtered by type — only persons for "Deceased", only companies for "Closed", all for "Active")
- Note when reactivating: "This will reactivate any deceased persons or closed companies in the selection."
- Cancel and Confirm buttons

**Household Assignment Flow (before → after):**
- Before: Pick household → immediately executes assignment
- After: Pick household → confirmation dialog shows affected persons → "Assign" executes

**Household Confirmation Dialog:**
- Title: "🏠 Confirm Household Assignment"
- Shows count of persons and target household name
- Lists each person with their current household noted (e.g., "👤 John Smith (moving from Johnson Family)")
- Note: "Persons currently in other households will be moved to the new one."
- Cancel and Assign buttons

---

## Session 61 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 58–61 reflecting the latest conversation history

---

## Session 62 — Confirmation Dialogs for Bulk Status Change & Household Assignment

### Action
Added two-step confirmation dialogs to the "Change Status" and "Assign Household" bulk actions, matching the pattern already established by the "Delete" bulk action.

### Changes to `components/BulkActions.tsx`

**New State:**
- `showStatusConfirm` — `'active' | 'deceased' | 'closed' | null` — tracks which status was picked, triggers confirmation dialog
- `showHouseholdConfirm` — `Household | null` — tracks which household was selected, triggers confirmation dialog

**Status Change Flow (before → after):**
- Before: Pick status → immediately executes status change
- After: Pick status → confirmation dialog shows affected entries → "Confirm" executes

**Status Confirmation Dialog:**
- Title: "⚡ Confirm Status Change"
- Shows count and new status in question form (e.g., "Set 3 persons to Deceased?")
- Lists affected entries (filtered by type — only persons for "Deceased", only companies for "Closed", all for "Active")
- Note when reactivating: "This will reactivate any deceased persons or closed companies in the selection."
- Cancel and Confirm buttons

**Household Assignment Flow (before → after):**
- Before: Pick household → immediately executes assignment
- After: Pick household → confirmation dialog shows affected persons → "Assign" executes

**Household Confirmation Dialog:**
- Title: "🏠 Confirm Household Assignment"
- Shows count of persons and target household name
- Lists each person with their current household noted (e.g., "👤 John Smith (moving from Johnson Family)")
- Note: "Persons currently in other households will be moved to the new one."
- Cancel and Assign buttons

---

## Session 63 — "Create New Household" in Bulk Assign Dialog

### Action
Added a "Create New Household" option at the top of the household picker dialog with an inline name and address form, allowing users to create a household and assign selected persons in one flow.

### Changes to `components/BulkActions.tsx`

**New Prop:**
- `onCreateAndAssignHousehold: (personIds: string[], household: Household) => void`

**New State:**
- `showCreateHousehold` — boolean to show/hide the create form dialog
- `newHhName`, `newHhStreet`, `newHhStreet2`, `newHhCity`, `newHhState`, `newHhZip` — form fields
- `newHhError` — validation error message

**UI Changes:**
- Added a prominent "+ Create New Household" card at the top of the household picker, styled with a dashed blue border and light blue background
- Clicking it opens a dedicated creation dialog with:
  - Household name (required, validated)
  - Address fields (street, apt/suite, city/state grid, zip)
  - List of persons to be assigned, with the first person marked as ★ Primary
  - "Create & Assign" button
- The "🏠 Assign Household" button now appears even when no existing households exist

**Other:**
- Imported `uuid` and `EMPTY_ADDR` to construct the new household object

### Changes to `App.tsx`

**New Handler: `handleCreateAndAssignHousehold`**
- Removes each person from their old household (loading fresh from storage)
- Updates each person's `householdId` and syncs their primary address
- Saves the newly created household to storage
- Clears selection and reloads

**Prop Passed:**
- `onCreateAndAssignHousehold={handleCreateAndAssignHousehold}` added to `BulkActionsBar`

---

## Session 64 — Address Auto-Complete in "Create New Household" Dialog

### Action
Added AI-powered address auto-suggest to the street field in the "Create New Household" dialog within the bulk assign flow, matching the behavior of address fields throughout the rest of the application.

### Changes to `components/BulkActions.tsx`

**New Imports:**
- `useState` → `useState, useEffect, useRef` from React
- `suggestAddresses`, `useDebounce` from `../utils`
- `AddressSuggestion` type from `../types`

**New State & Hooks:**
- `addrSuggestions` — `AddressSuggestion[]` for the dropdown results
- `debouncedStreet` — debounced version of `newHhStreet` (400ms delay)
- `addrWrapRef` — ref for click-outside detection on the suggestion dropdown

**New Effects:**
- Address suggestion fetch: triggers `suggestAddresses(debouncedStreet)` when the create household dialog is open and street has 3+ characters
- Click-outside handler: dismisses suggestions when clicking outside the street field area

**UI Changes:**
- Street input placeholder changed from "Street" to "Start typing to auto-suggest..."
- Street field wrapped in a `position: relative` container with `ref={addrWrapRef}`
- Suggestion dropdown renders below the street input using `S.addrDropdown` / `S.addrItem` styles
- Clicking a suggestion auto-fills street, city, state, and ZIP fields and closes the dropdown
- Hover highlighting on suggestion items

### Behavior
- Same UX as the existing `SingleAddressFields` component used in person/company/household forms
- Powered by Claude Haiku model via `suggestAddresses()` utility
- 400ms debounce prevents excessive API calls while typing
- Minimum 3 characters before suggestions trigger
- Up to 5 US address suggestions shown

---

## Session 65 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 62–65 reflecting the latest conversation history

---

## Session 66 — Inline Household Creation in Person Form (Reverted)

### Action
Added a "+ Create New Household" option inside the person form's Household Picker with an inline creation form including address auto-suggest. This was subsequently reverted at the user's request.

### Changes (Reverted)
- `components/HouseholdPicker.tsx` — Added `onCreateHousehold` prop, inline form with name/address/auto-suggest, create & assign flow
- `App.tsx` — Added `onCreateHousehold` handler that saves the household and updates local state

### Reversion
- User requested undo; both files reverted to their Version 111 state

---

## Session 67 — Print-Friendly Directory Export

### Action
Added a "🖨️ Print" button to the directory toolbar that generates a self-contained, print-optimized HTML file as a download.

### New Component: `components/PrintDirectory.tsx`

**`generatePrintDirectory()` function:**
- Generates a standalone HTML document optimized for printing
- Sorts entries alphabetically, groups persons by last-name initial letter
- Two-column CSS layout using `column-count: 2`
- Entry cards with profile photos (base64 embedded), name, phone, email, address
- Deceased/closed entries shown dimmed with status badges
- Household membership displayed per person
- Companies listed in a separate section
- "Print This Directory" button in the HTML (hidden on actual print via `@media print`)
- Footer with entry/household counts

### Integration in `App.tsx`
- Added "🖨️ Print" button between Export CSV and Import CSV in the toolbar
- Added `?raw` import for code export
- Added to the exported project file list

---

## Session 68 — Print Directory Pre-Download Configuration Dialog

### Action
Added a customization dialog that appears before generating the print file, letting users tailor the output for different use cases.

### Changes to `components/PrintDirectory.tsx`

**New `PrintDialog` Component:**
A modal dialog with four configuration sections:

| Option | Choices | Default |
|--------|---------|---------|
| Include | ☑ Persons, ☑ Companies (checkboxes) | Both checked |
| Status Filter | ● Active Only / ○ All Entries | Active Only |
| Profile Photos | 📷 Show Photos / 🚫 No Photos | Show Photos |
| Layout | ▐ Single Column / ▐▐ Two Columns | Two Columns |

**Features:**
- Live entry counts update as options change (e.g., "👤 Persons (42)")
- Preview summary at bottom: "Preview: 42 entries will be included · with photos · two-column layout"
- Contextual helper text for each option (e.g., "Smaller file size, faster printing" for no photos)
- "Download Print File" button disabled when 0 entries would be included
- Generating state shows "Generating..." during file creation

**`PrintConfig` interface:**
```ts
interface PrintConfig {
  includePersons: boolean;
  includeCompanies: boolean;
  statusFilter: 'active' | 'all';
  showPhotos: boolean;
  columns: 1 | 2;
}
```

**Updated `generatePrintDirectory()`:**
- Now accepts `config: PrintConfig` parameter
- Filters entries by type and status based on config
- Conditionally embeds profile photos (significant file size reduction when disabled)
- Adjusts font sizes, padding, avatar sizes, and column count based on layout choice
- Single-column: larger fonts (12px body, 14px names, 24px title), more padding — good for wall posters
- Two-column: compact fonts (11px body, 12px names, 20px title) — fits more entries per page

### Changes to `App.tsx`
- Added `showPrintDialog` state
- "🖨️ Print" button now opens `PrintDialog` instead of directly generating
- Renders `<PrintDialog>` modal when active
- Dialog receives entries, households, images, onClose, and onError props

---

## Session 69 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 66–69 reflecting the latest conversation history

---

## Session 70 — Include Households in Printed Directory

### Action
Added an optional "Include Households" checkbox to the print dialog that appends a family-grouped view to printed directories, showing each household as a card with family name, shared address, and all members listed together.

### Changes to `components/PrintDirectory.tsx`

**PrintConfig Extended:**
- Added `includeHouseholds: boolean` to `PrintConfig` interface (default `false`)

**Print Dialog UI:**
- Added 🏠 Households checkbox with live count in the "Include" section
- Descriptive hint when checked: "Appends a family-grouped section — each household as a card with family name, shared address, and all members listed together."
- Updated preview summary to show household count when enabled
- Updated `canGenerate` logic to allow generating with only households selected

**Household HTML Generation:**
- `allPersons` array for household member resolution, independent of the "Include Persons" toggle
- Households filtered by status (active-only mode skips households with no active members)
- Alphabetically sorted by household name
- Each household card includes:
  - Household photo or 🏠 placeholder
  - Family name in blue
  - Shared address
  - Primary contact's phone and email
  - Member list with individual thumbnails, names, ★ Primary badge, phone/email
  - Deceased members shown dimmed
- Cards use `break-inside: avoid` and respect the 1/2 column layout setting

**New CSS Classes:**
- `.hh-grid`, `.hh-card`, `.hh-header`, `.hh-avatar`, `.hh-avatar-placeholder`
- `.hh-name`, `.hh-addr`, `.hh-contact`, `.hh-members`, `.hh-member`
- `.avatar-sm`, `.avatar-sm-placeholder`, `.hh-member-info`, `.hh-member-name`, `.hh-member-detail`, `.hh-primary`

**Printed Output Updated:**
- Subtitle and stats footer include household count when the option is enabled
- Household section appears after Companies section with its own section title

---

## Session 71 — Households Option Requires Persons to Be Selected

### Problem
The "Include Households" checkbox in the print dialog was available regardless of what entry types were selected. Since companies don't have households, the option should only be relevant when "Include Persons" is checked.

### Solution
Made the Households checkbox dependent on the Persons checkbox — it auto-unchecks and becomes disabled when Persons is toggled off.

### Changes to `components/PrintDirectory.tsx`

**Persons Checkbox Handler:**
- When Persons is unchecked, `includeHouseholds` is automatically set to `false`:
  ```ts
  onChange={e => setConfig(c => ({ ...c, includePersons: e.target.checked, ...(!e.target.checked && { includeHouseholds: false }) }))}
  ```

**Households Checkbox:**
- `disabled={!config.includePersons}` — checkbox is non-interactive when Persons is off
- Cursor changes to `not-allowed` when disabled
- Opacity reduced to 0.45 when disabled for visual clarity

**Hint Text:**
- When Persons is unchecked: "Households require 'Persons' to be included."
- When both Persons and Households are checked: existing description about family-grouped section

---

## Session 72 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications for Completed Actions** — Replace the inconsistent success feedback (some actions use `✅` prefix on the error banner, others have no feedback) with a lightweight toast notification system that confirms saves, deletes, bulk operations, and print downloads. Optionally include undo for destructive actions within a brief timeout window.

2. **Keyboard Shortcuts with Help Overlay** — Add keyboard shortcuts for power users: `N P` (new person), `N C` (new company), `/` (focus search), `Escape` (close dialogs), `?` (shortcut cheat sheet), `Ctrl+S` (save form), and arrow keys for list navigation.

3. **"Family Directory" Print Preset** — A dedicated preset that makes households the primary view with unaffiliated individuals in a separate section and an optional table of contents. A one-click preset button in the print dialog would auto-configure all the right toggles.

---

## Session 73 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 70–73 reflecting the latest conversation history

---

## Session 74 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications with Undo Support** — Replace inconsistent success feedback with a lightweight toast system showing auto-dismissing confirmations and time-limited undo buttons for destructive actions.

2. **Keyboard Shortcuts with `?` Help Overlay** — Add shortcuts like `/` (focus search), `Escape` (close dialogs), `N P` / `N C` (new person/company), `Ctrl+S` (save form), and `?` (toggle cheat sheet overlay).

3. **Directory Statistics Dashboard** — Add a collapsible overview panel showing counts, completeness indicators, household coverage, and top industries.

---

## Session 75 — Upcoming Birthdays Component Removed

### Context
The `UpcomingBirthdays` component was fully implemented and rendered in the list view — it showed active persons with birthdays within the next 30 days as clickable cards. However, because it only renders when matching birthdays exist (returns `null` otherwise), the user never saw it in practice and assumed it was partial/unimplemented code. The user decided they did not want the feature and requested cleanup.

### Removal
The component was completely removed from the codebase:

**Deleted file:**
- `webapp/src/components/UpcomingBirthdays.tsx`

**References removed from `App.tsx`:**
1. `import { UpcomingBirthdays } from './components/UpcomingBirthdays'` — component import
2. `import upcomingBirthdaysSource from './components/UpcomingBirthdays.tsx?raw'` — raw source import for code export
3. `<UpcomingBirthdays persons={allPersons} images={images} onSelect={...} />` — render call in list view
4. `['src/components/UpcomingBirthdays.tsx', upcomingBirthdaysSource]` — entry in code export file list

**Note:** The `calculateAge` utility function in `utils.ts` was retained — it is still used by the person detail view to display age next to the birthday field.

---

## Session 76 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Toast Notifications with Undo Support** — Replace inconsistent success feedback (some actions use `✅` in the error banner, others have none) with a toast system that shows brief, auto-dismissing confirmations and time-limited undo buttons for destructive actions.

2. **Inline Field Error Summary on Long Forms** — Show a compact error summary banner at the top listing all validation issues at once with clickable links that scroll to each offending field, eliminating the current trial-and-error loop of fix-one-save-discover-next.

3. **Search Across All Fields** — Expand the search bar to match against phone numbers, street addresses, city/state/ZIP, and notes content (not just names and emails), and show which field matched in the dropdown results.

---

## Session 77 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 74–77 reflecting the latest conversation history

---

## Session 78 — Major Refactoring: App.tsx from ~1,800 Lines to ~374 Lines

### Problem
The monolithic `App.tsx` file had grown to over 1,800 lines, containing all form state, save/delete/bulk handlers, view rendering, CSV/code export logic, and dialog rendering in a single component. This made it difficult to understand, maintain, and modify without risk of stale-state bugs.

### Solution
Extracted business logic into custom hooks and view components, leaving `App.tsx` as a thin orchestration shell that composes them.

### New Custom Hooks (`hooks/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `useDirectoryData.ts` | 70 | Core data loading (entries, households, images), `reload()`, `allPersons`, `allIndustries`, filtered/search results via `useFilteredEntries` |
| `useDirectoryActions.ts` | 150 | All delete & bulk handlers: `confirmDelete`, `handleDeleteAll`, `handleBulkDelete`, `handleBulkStatusChange`, `handleBulkAssignHousehold`, `handleCreateAndAssignHousehold` |
| `usePersonForm.ts` | 140 | All 16 person form state fields, refs for validation scroll, `reset()` / `fill(person)` / `save()` with full validation, spouse sync, household membership sync |
| `useCompanyForm.ts` | 110 | All 13 company form state fields, refs for validation scroll, `reset()` / `fill(company)` / `save()` with full validation, URL normalization |

### New View Components (`views/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `DetailView.tsx` | 115 | Person/company detail view with all collapsible sections (personal info, emails, phones, addresses, relationships, family tree, household, contact persons, notes) |
| `ImportView.tsx` | 65 | CSV/household import preview tables with entry and household sections, confirm/cancel |

### New Shared Component (`components/`)

| File | ~Lines | Responsibility |
|------|--------|---------------|
| `DeleteDialogs.tsx` | 55 | `DeleteDialog` (single entry with cascade effects) and `DeleteAllDialog` (all entries + households count) |

### App.tsx After Refactoring (~374 lines)
Now serves as a **thin orchestration shell** containing only:
- View routing (`view` state)
- Search dropdown rendering (header)
- List view card rendering with pagination
- Form view rendering (wiring hook state to form components)
- CSV/code export handlers
- Dialog composition (`DeleteDialog`, `DeleteAllDialog`, `PrintDialog`)
- No business logic, no save/delete handlers, no form state

### Code Export Updated
- Added `?raw` imports for all new files: `useDirectoryData.ts`, `useDirectoryActions.ts`, `usePersonForm.ts`, `useCompanyForm.ts`, `DetailView.tsx`, `ImportView.tsx`, `DeleteDialogs.tsx`, `EmailInput.tsx`
- Export shell script now creates `src/hooks/` and `src/views/` directories
- All new files included in the exported project

### Build Results
- Build succeeded with no errors
- 344 modules transformed (up from 329 due to new files + `?raw` imports)
- Final bundle: ~1,132 kB (gzip: ~305 kB) — virtually identical to pre-refactoring

---

## Session 79 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Full-Field Search with Match Context** — Expand search to match phone numbers, addresses, and notes, showing which field matched in the dropdown results. The search logic is now cleanly isolated in `useFilteredEntries`, making this a contained change.

2. **Multi-Error Validation Summary on Forms** — Show all validation issues at once in a clickable summary banner instead of scrolling to only the first error. Validation logic is now encapsulated in `usePersonForm` and `useCompanyForm`, making this a natural extension.

3. **Share Contact via Clipboard or QR Code** — Add a "📤 Share" button to the detail view with copy-to-clipboard (plain text summary) and QR code (MECARD/vCard encoding) options.

---

## Session 80 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 78–80 reflecting the latest conversation history

---

## Session 81 — Log Update

### Action
- Updated `DEVLOG.md` for export purposes

---

## Session 82 — Toast Notification System

### Action
Added a lightweight toast notification system to provide consistent, non-blocking feedback for all user actions across the application.

### New Component: `components/Toast.tsx`

**`ToastProvider` & `useToast` hook:**
- React Context-based provider wrapping the entire app
- `addToast(message)` function available to all components via `useToast()`
- Toasts render in a fixed container in the top-right corner of the screen
- Auto-stacking: multiple toasts stack vertically with spacing
- Auto-dismiss: success toasts fade out after ~3.5 seconds
- Manual dismiss: error toasts (containing "error" or "fail") persist until user clicks the × button
- Slide-in animation via CSS keyframes
- Dark themed (semi-transparent dark background, white text, rounded corners)

### Integration in `App.tsx`
- Wrapped `AppInner` in `<ToastProvider>`
- Replaced direct `setError('✅ ...')` success messages with `addToast(...)` calls throughout:
  - Save person/company: `✅ John Smith saved`
  - Delete entry: `🗑️ John Smith deleted`
  - Delete all: `🗑️ All 5 records deleted`
  - Bulk delete: `🗑️ 3 entries deleted`
  - Bulk status change: `✅ 5 entries updated to active`
  - Bulk household assign: `🏠 3 persons assigned to Smith Family`
  - Create & assign household: `🏠 Smith Family created with 3 members`
  - CSV export: `📥 CSV exported successfully`
  - CSV import: `✅ Successfully imported 5 records`
  - Image import: `✅ Successfully imported 3 profile images`
  - vCard export: `📇 3 contacts exported`
  - Print: `🖨️ Directory generated`
  - Code export: `💾 Source code exported`
  - Log export: `📄 Conversation log exported`

### Changes to `components/BulkActions.tsx`
- Added `onToast` prop to `BulkActionsBarProps`
- All bulk action confirmation dialogs now call `onToast(...)` on success

---

## Session 83 — Toast Position Moved to Top Right

### Action
Moved the toast notification container from bottom-right to top-right corner of the screen.

### Change to `components/Toast.tsx`
- Updated container style from `bottom: 20` to `top: 20`
- Updated slide-in animation from `translateY(40px)` (sliding up from below) to `translateY(-40px)` (sliding down from above)

---

## Session 84 — Bulk Actions: Household Picker Shows Existing Households & "Create New" Option

### Action
Adjusted the bulk assign household flow so that the "🏠 Assign Household" button appears for persons-only selections regardless of whether existing households exist, and the household picker always shows both a "Create New Household" option and the existing household list.

### Changes to `components/BulkActions.tsx`
- The "🏠 Assign Household" button in the floating bar now appears whenever the selection contains only persons (`isPersonsOnly`), not gated on `households.length > 0`
- The household picker dialog always shows the "+ Create New Household" card at the top
- Existing households section (search + list) only renders when `households.length > 0`

---

## Session 85 — Simplified Status Button Labels in Bulk Change Status Dialog

### Action
Simplified the status choice button labels in the "Change Status" picker dialog to show only the status name, since the introductory sentence already states the total count.

### Changes to `components/BulkActions.tsx`
- Before: Buttons read "Set to **Active** (3 entries)"
- After: Buttons read just "● Active", "✝ Deceased", "🚫 Closed"
- The count is conveyed by the introductory text: "Change status for 5 selected entries:"

---

## Session 86 — Status Change Breakdown: Preview Affected vs. Already-Matching Entries

### Action
Added a live breakdown in the "Change Status" dialog showing how many entries will actually change versus how many are already at the target status, and skipping unnecessary writes.

### Changes to `components/BulkActions.tsx`

**New Helper: `getStatusBreakdown(status)`**
- Iterates over selected entries and computes:
  - `willChange` — count of entries whose current status differs from the target
  - `alreadyCount` — count of entries already at the target status
  - `idsToChange` — array of IDs that actually need updating
- Handles person/company status mapping (e.g., "closed" is not valid for persons → maps to "active")

**Status Picker Buttons Updated:**
- Each button now shows a breakdown line below the status name:
  - When all entries already match: "All 5 already Active" (button disabled)
  - When some need changing: "3 of 5 will change — 2 already Active"
- Buttons are disabled (`opacity: 0.5`, non-clickable) when `willChange === 0`

**Status Confirmation Dialog Updated:**
- Header shows: "3 of 5 selected entries will change to **Active** — 2 already Active"
- Entries are split into two lists:
  - Affected entries (will change) — normal display
  - Skipped entries (already at target) — dimmed, under "Already Active (no change):" header
- Confirm button reads "Change 3" (only the count of entries that will change)
- Only `idsToChange` are passed to `onBulkStatusChange` (not all selected IDs)

### Changes to `hooks/useDirectoryActions.ts`
- `handleBulkStatusChange` now checks each entry's current status before saving
- Entries already at the target status are skipped (no write to storage)
- Acts as a backend safety net even if the UI already filters them

---

## Session 87 — Household Assignment: Minimum 2 Persons & Required Address

### Action
Corrected the "Assign Household" bulk action behavior with two constraints:

### Part 1: Minimum 2 Persons to Create a New Household
The "Create New Household" button in the household picker is now disabled when fewer than 2 persons are selected.

#### Changes to `components/BulkActions.tsx`
- Button is **disabled** (grayed out, non-clickable, reduced opacity 0.6) when `selectedPersons.length < 2`
- When disabled: dashed border uses `colors.border` instead of `colors.primary`, background is `#f5f5f5`
- Message when disabled: "Select at least 2 persons to create a household"
- Message when enabled: "Create a household and assign selected persons"
- Click handler returns early when `canCreate` is false

### Part 2: Address Is Required for New Household Creation
The address field in the "Create New Household & Assign" dialog is now required.

#### Changes to `components/BulkActions.tsx`
- Address section label changed from "Address" to "Address *" (marked as required)
- Intro text updated to include: "All members will share the household address."
- Validation added: if `newHhStreet` is empty, shows error "Address is required — a household must have a shared address."
- **Warning banner for existing household members**: When any selected persons already belong to a household, an amber/yellow warning banner appears listing each person and their current household (e.g., "👤 John Smith ← currently in The Smith Family"), making it clear they will be moved to the new household with the new address.

---

## Session 88 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Show Per-Entry Status Transitions in Confirmation Dialog** — Display the current-to-target status transition inline for each affected entry (e.g., "👤 John Smith *(Active → Deceased)*") to give users more confidence before confirming bulk status changes.

2. **Keyboard Shortcuts with Help Overlay** — Add keyboard shortcuts for power users: `N` for new person, `B` for new company, `/` to focus search, `Escape` to close dialogs/exit select mode, and `?` to toggle a shortcut cheat-sheet overlay.

3. **Smart Household Name Suggestion** — Auto-suggest a household name based on selected persons' shared surnames when creating a new household (e.g., "The Smith Family" if all selected persons share the last name "Smith", or "The Smith-Johnson Family" if surnames differ).

---

## Session 89 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 81–89 reflecting the latest conversation history

---

## Session 90 — Quick Add Spouse/Child Feature

### Action
Added the ability to quickly add a spouse or child directly from the "Add Person" form's Relationships section, without leaving the current form.

### New Component: `components/QuickAddRelative.tsx`
A modal dialog for creating a new person as a spouse or child:

**Spouse Mode:**
- First name and last name required
- Gender defaults to the opposite sex of the current person (e.g., if current person is Male, spouse defaults to Female)
- Gender is optional (can be left blank)

**Child Mode:**
- First name, last name, and gender are all required
- Gender validation prevents saving without a selection

**Common Features:**
- Auto-focuses the first name field on open
- Field-level validation with red borders and error messages on save attempt
- "Add Spouse" / "Add Child" button label
- Click-outside or Cancel button to dismiss

### Integration in `App.tsx`
- Added `quickAddMode` state (`'spouse' | 'child' | null`)
- Two new buttons in the Relationships section header:
  - **"+ Quick Add Spouse"** — hidden when a spouse is already selected
  - **"+ Quick Add Child"** — always available
- On creation, the new person is saved to storage immediately and linked:
  - Spouse: sets `pSpouseId` to the new person's ID
  - Child: appends the new person's ID to `pChildIds`
- Added `?raw` import and code export entry for `QuickAddRelative.tsx`

---

## Session 91 — Deferred Persistence with Pending Indicators

### Problem
Quick-added persons were saved to storage immediately when created in the dialog. If the user later cancelled the main person form, these entries would remain as orphaned records in the directory.

### Solution
Changed quick-added relatives to be held in memory as "pending" until the main person form is saved, with visual indicators distinguishing them from existing persons.

### Changes to `hooks/usePersonForm.ts`
- Added `pendingPersons` state array (`Person[]`)
- Added helper functions: `addPendingPerson`, `removePendingPerson`, `updatePendingPerson`
- `reset()` and `fill()` clear `pendingPersons` to `[]`
- `save()` persists all pending persons to storage **after** saving the main person but **before** spouse sync, so `loadEntry` can resolve them during relationship linking

### Changes to `components/QuickAddRelative.tsx`
- No longer calls `saveEntry` — returns the `Person` object in memory via `onCreated` callback
- Generates a UUID for the person but does not persist it

### Changes to `components/SpousePicker.tsx`
- Added optional `pendingIds` (`Set<string>`) and `onEditPending` props
- Pending spouse chips render with:
  - Yellow background (`#fff8e1`) and amber border (`#ffc107`)
  - **✨ new** badge in amber text
  - `cursor: pointer` and "Click to edit" tooltip
  - The × button uses `stopPropagation` to remove without triggering edit

### Changes to `components/RelationshipPicker.tsx`
- Added identical `pendingIds` and `onEditPending` props
- Pending child chips have the same yellow/amber styling and ✨ new badge

### Changes to `App.tsx`
- `onCreated` callback now calls `addPendingPerson` instead of `saveEntry`
- Passes `pendingPersons` merged into `allPersons` for both pickers
- Passes `pendingIds` set to both pickers
- Clearing a pending spouse also calls `removePendingPerson`
- Cancelling the form calls `reset()` which discards all pending persons

### Behavior
- Pending relatives appear as visually distinct chips in the form
- Only persisted to storage when the main person is saved
- Cancelling the form discards them entirely — no orphaned entries

---

## Session 92 — Inline Editing of Pending Relatives

### Problem
Once a pending spouse or child was quick-added, the only option was to remove them. If the user made a typo or wanted to change the gender, they had to remove and re-add the person.

### Solution
Added click-to-edit functionality on pending chips that reopens the Quick Add dialog pre-filled with the person's details.

### Changes to `components/QuickAddRelative.tsx`
- Added optional `editPerson` prop (`Person | null`)
- When editing:
  - Title changes to "💍 Edit Pending Spouse" or "🧒 Edit Pending Child"
  - All fields pre-filled from the existing person
  - The existing person's ID is preserved (not regenerated)
  - Submit button reads "Update" instead of "Add"
  - Subtitle changes to "Update the details below..."

### Changes to `hooks/usePersonForm.ts`
- Added `updatePendingPerson(person)` helper that replaces a pending person by ID

### Changes to `components/SpousePicker.tsx`
- Clicking a pending spouse chip calls `onEditPending(id)` (not the × button — that still removes)
- `onClick` and `stopPropagation` correctly separated between chip body (edit) and × button (remove)

### Changes to `components/RelationshipPicker.tsx`
- Same click-to-edit behavior on pending child chips

### Changes to `App.tsx`
- Added `editingPendingId` state to track which pending person is being edited
- When a pending chip is clicked, sets `editingPendingId` and opens the dialog in the correct mode
- `onCreated` callback calls `updatePendingPerson` (instead of `addPendingPerson`) when `editingPendingId` is set
- Both `editingPendingId` and `quickAddMode` are cleared on dialog close

---

## Session 93 — Auto-Populate Last Name in Quick Add Dialog

### Action
When quick-adding a spouse or child, the Last Name field is now automatically populated with the current person's last name, since family members commonly share a surname.

### Changes to `components/QuickAddRelative.tsx`
- Added optional `defaultLastName` prop to `QuickAddRelativeProps`
- When creating a new relative (not editing), `lastName` state initializes to `defaultLastName || ''`
- When editing an existing pending person, their own last name is used (default is ignored)
- The user can freely clear or change the pre-filled value

### Changes to `App.tsx`
- Passes `defaultLastName={personForm.pLast}` to `QuickAddRelativeDialog`

---

## Session 94 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Confirmation Dialog When Cancelling with Pending Relatives** — Show a warning dialog when the user clicks Cancel on the person form while pending relatives exist, preventing accidental data loss.

2. **Pending Relatives Summary Banner Above Save** — Display a compact banner listing all pending relatives by name and type just above the Save button for a final at-a-glance review before committing.

3. **Quick Add More Fields (Birthday, Email, Phone)** — Expand the Quick Add dialog with optional collapsible fields for birthday, email, and phone, allowing users to capture commonly-known family details in the same flow without needing to edit each relative afterward.

---

## Session 95 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 90–95 reflecting the latest conversation history

---

## Session 96 — "Create New" Option in Spouse & Children Search Dropdowns

### Action
Moved the Quick Add Spouse/Child entry points from standalone buttons in the Relationships section header into the search dropdowns themselves, making discovery more contextual and natural.

### Changes to `components/SpousePicker.tsx`
- Added optional `onQuickAdd` prop
- When the search dropdown is open and the user has typed a query, a **"✨ Create new spouse…"** option appears at the bottom of the dropdown, separated by a thin border
- Styled in primary blue with bold text; hover highlights in light blue
- Clicking it closes the dropdown and triggers the Quick Add dialog

### Changes to `components/RelationshipPicker.tsx`
- Added optional `onQuickAdd` prop with the same pattern
- A **"✨ Create new child…"** option appears at the bottom of the children search dropdown
- The dropdown now also opens when there are **zero matches** but `onQuickAdd` is provided, showing "No matching persons" followed by the create option — ensuring the user can always create a new person even when no existing match exists

### Changes to `App.tsx`
- **Removed** the two standalone "+ Quick Add Spouse" and "+ Quick Add Child" buttons from the Relationships section header
- The Relationships section header reverted to a simple `<div style={S.section}>Relationships</div>`
- Passes `onQuickAdd` callbacks to both `SpousePicker` and `RelationshipPicker`

---

## Session 97 — Remove Unnecessary Gender Default Message

### Action
Removed the "Defaulted to Female (opposite of Male)" hint text that appeared below the gender dropdown in the Quick Add Spouse dialog. The behavior (auto-selecting the opposite gender) is self-evident from the pre-selected value.

### Changes to `components/QuickAddRelative.tsx`
- Removed the conditional block that rendered the default-gender explanation text below the gender select when in spouse mode

---

## Session 98 — Household Assignment Breakdown: Preview Affected vs. Already-in-Target

### Action
Added a live breakdown in the "Confirm Assign Household" dialog showing how many selected persons will actually be reassigned versus how many are already in the target household, mirroring the pattern established by the "Change Status" dialog in Session 86.

### Changes to `components/BulkActions.tsx`

**New Computed Values in Confirmation Dialog:**
- `alreadyInTarget` — persons whose `householdId` already matches the target household
- `willChange` — persons whose `householdId` differs from the target (these will actually be updated)

**Confirmation Dialog Updated:**
- Header now shows: "**X** of Y persons will be assigned to **🏠 Household Name**" with a note of how many are already members
- When all selected persons are already in the target: "All N already belong to **🏠 Household Name**"
- Person list split into two sections:
  - **Persons that will change** — normal display with "moving from" annotations for those in other households
  - **Already in [household] (no change)** — muted/dimmed section listing skipped persons
- Confirm button reads "Assign N" (only the count of persons that will actually change)
- Button is **disabled** with reduced opacity when `willChange` is empty (all already in target)
- Only `willChange` IDs are passed to `onBulkAssignHousehold`, preventing unnecessary writes

---

## Session 99 — Clear Button in Directory Search Box

### Action
Added a clear (×) button to the header search input that appears when text is entered, allowing users to quickly reset the search.

### Changes to `App.tsx`
- The search input's right padding dynamically increases to 32px when `searchQ` is non-empty, preventing text from overlapping the button
- A small circular **×** button renders absolutely positioned at the right edge of the input when `searchQ` is non-empty
- Clicking the button resets `searchQ` to empty and hides the search dropdown
- Button styled as a semi-transparent dark circle (20×20px) with white text, centered vertically

---

## Session 101 — Search Dropdown White-on-White Text Fix

### Problem
In the header search bar, matching persons' names appeared blank (invisible) in the dropdown as the user typed. The text was white on a white background.

### Root Cause
The `dropdownItem` style in `styles.ts` did not explicitly set a `color`, and the inherited color from the dark header background was white — making text invisible against the white dropdown background.

### Solution
Added explicit `color: colors.text` to the `dropdownItem` style in `styles.ts`.

### Changes to `styles.ts`
- Added `color: colors.text` (dark text) to the `dropdownItem` style definition

---

## Session 102 — Household List: Sort by Name

### Action
Added a sort toggle button to the Households list allowing users to sort households alphabetically by name in ascending (A→Z) or descending (Z→A) order.

### Changes to `components/HouseholdView.tsx`
- Added `sortDir` state (`'asc' | 'desc'`, default `'asc'`)
- Computed `sortedHouseholds` via `useMemo` — sorts households alphabetically by `name` using `localeCompare`
- Added a toggle button displaying "A→Z" or "Z→A" that flips `sortDir` on click
- Pagination now operates on `sortedHouseholds` instead of the raw `households` array

---

## Session 103 — Household List: Real-Time Search/Filter

### Action
Added a search input to the Households list that filters households in real time by name, address fields, or member names.

### Changes to `components/HouseholdView.tsx`
- Added `filterQ` state for the search query
- Filtering logic matches against:
  - Household name
  - Address fields (street, street2, city, state, ZIP, country)
  - Member names (resolved via `resolveName`)
- Search input with a clear (×) button when text is entered
- "No households match your filter" empty state when no results
- Pagination resets to page 1 when the filter query changes
- `resolveName` converted to `useCallback` for proper dependency tracking

---

## Session 104 — Unique Household Name Validation

### Action
Enforced that household names must be unique (case-insensitive, trimmed) across all creation and editing flows.

### Changes to `components/HouseholdView.tsx`
- Added `hhNameDupe` to the `fieldErrors` set when a duplicate name is detected on save
- Validation checks all other households (excluding the one being edited) for a case-insensitive name match
- Error message: "A household with this name already exists"
- Input border turns red and inline error appears below the name field
- Error clears automatically when the user modifies the name

### Changes to `components/BulkActions.tsx`
- Added the same unique name validation to the "Create & Assign" household dialog in the bulk actions flow
- Error message: "A household with this name already exists."
- Checks against the full `households` array passed as a prop

---

## Session 105 — Toast Notifications for Household Actions

### Action
Added toast notifications to all household CRUD operations, matching the feedback pattern already established for person/company actions.

### Changes to `components/HouseholdView.tsx`
- Added `onToast` prop to `HouseholdViewProps`
- Toast messages for:
  - Create: `🏠 [Name] created`
  - Update: `🏠 [Name] updated`
  - Delete: `🗑️ [Name] deleted`
  - Member removal (household dissolved): `🗑️ [Name] dissolved (last member removed)`
  - Member removal (member removed): `👤 [Member Name] removed from [Household Name]`

### Changes to `App.tsx`
- Passed `onToast={msg => addToast(msg)}` prop to `HouseholdView`

---

## Session 106 — Exclude Deceased Persons from Household Member Search

### Action
Updated the household member search to only show persons with an `active` status. Deceased or other inactive persons are no longer included in the search dropdown when adding members to a household.

### Changes to `components/HouseholdView.tsx`
- Added `(p.status || 'active') !== 'active'` filter to the `eligibleMembers` computation
- Persons with status `'deceased'` or any non-active status are excluded from the household member search dropdown

---

## Session 107 — Updated Placeholder Text for Spouse & Children Fields

### Action
Updated the placeholder text in the Spouse and Children search inputs to reflect that both fields now support searching existing persons *and* creating new ones inline.

### Changes to `components/SpousePicker.tsx`
- Placeholder changed from `"Search for a spouse..."` to `"Search or create a spouse..."`

### Changes to `components/RelationshipPicker.tsx`
- Placeholder changed from `"Search persons to add as {label}..."` to `"Search or create {label}..."`

---

## Session 108 — Follow-Up Improvement Suggestions

Three suggestions were provided:

1. **Add a "Parents" row in the Person detail view** — Display parent relationships by reverse-looking up `childIds`, enabling bidirectional family navigation from the detail view.

2. **Confirmation dialog when cancelling with unsaved pending relatives** — Show a warning dialog when the user clicks Cancel on the person form while pending (✨ new) relatives exist, preventing accidental loss of quick-added data.

3. **Warn when a household contains a deceased member** — Display a visual warning (⚠️ badge or banner) on households that contain members whose status has since changed to deceased, helping maintainers keep rosters accurate.

---

## Session 109 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 101–109 reflecting the latest conversation history

## Session 110 — Conditional Household Creation in Person Form

### Action
Added conditional household creation logic to the "Add Person" form, allowing users to create a new household directly from the person form when a spouse and/or children have been assigned and the person has an address.

### Conditional Logic
| Condition | Behavior |
|-----------|----------|
| Spouse/children assigned + address populated | Show "Create New Household" option with inline name field |
| Spouse/children assigned + NO address | Show message: "Enter an address for this person to create a household with this person and their family members." |
| No spouse/children | Show existing "Assign to existing household" search |

### Constraints
- "Create New Household" and "Assign to existing household" must **never** appear simultaneously — they are mutually exclusive
- Household name must be unique (validated against all existing households)

### Changes to `components/HouseholdPicker.tsx`
- Added `hasRelatives`, `hasAddress`, `primaryAddress`, and `allHouseholds` props
- Conditional rendering: shows create-household UI when `hasRelatives && hasAddress`, address prompt when `hasRelatives && !hasAddress`, or existing-household search otherwise
- "Create New Household" inline form with name input and expandable dialog
- Descriptive message: "Create a new household with this person and their family members. The person's address will be used as the household address."
- Removed "Not assigned to any household." message on empty state (self-evident for new records)

### Changes to `hooks/usePersonForm.ts`
- Added `createHouseholdName` state for the inline household name field
- `save()` logic: when `createHouseholdName` is set, creates a new household with:
  - All related persons (self + spouse + children) as members
  - Current person as primary contact
  - Person's primary address as household address
  - Sets household address label to "Household" for all members
  - Syncs household address to spouse and children

### Changes to `App.tsx`
- Passes `hasRelatives`, `hasAddress`, `primaryAddress`, and `allHouseholds` props to `HouseholdPicker`

---

## Session 111 — Household Creation Fixes: Mutual Exclusivity & Address Sync

### Problem
Two issues with the household creation flow on the Add Person form:
1. Both "Create New Household" and "Assign to existing household" appeared simultaneously under certain conditions
2. When creating a new household, the current person's address type wasn't set to "Household" and spouse/children's addresses were blank instead of being synced

### Solution

#### Changes to `components/HouseholdPicker.tsx`
- Enforced strict mutual exclusivity: create-eligible mode and assign-to-existing mode are never shown at the same time

#### Changes to `hooks/usePersonForm.ts`
- Fixed address sync on household creation:
  - Current person's primary address label is set to "Household"
  - Spouse and children receive the same address with label "Household"
  - All members' `householdId` is correctly set to the new household's ID

---

## Session 112 — Household Creation UX Refinements

### Action
Cleaned up messaging in the household assignment section of the person form.

### Changes to `components/HouseholdPicker.tsx`
- Removed redundant "Not assigned to any household." message when adding a new person (self-evident)
- Updated descriptive text under "Household Membership" section: "Create a new household with this person and their family members. The person's address will be used as the household address."
- Removed duplicate message from the "New Household" dialog (shares the section-level message instead)

---

## Session 113 — Conditional Household Message for Missing Address

### Action
Added a contextual message when a person has relatives but no address, guiding them to complete the address first.

### Changes to `components/HouseholdPicker.tsx`
- When `hasRelatives && !hasAddress`: displays "Enter an address for this person to create a household with this person and their family members."
- When `hasRelatives && hasAddress`: shows the "Create New Household" option (existing behavior)
- When no relatives: shows the "Assign to existing household" search (existing behavior)

### Changes to `App.tsx`
- Updated prop passing to include address presence detection

---

## Session 114 — Pre-Fill First Name in Quick Add Dialogs

### Action
When creating a new spouse or child via the "Create new spouse…" or "Create new child…" options in the search dropdowns, the First Name field is now pre-filled with the text the user typed in the search field.

### Changes to `components/SpousePicker.tsx`
- Changed `onQuickAdd` callback signature to `(searchText: string) => void`
- "Create new spouse…" option now passes the current search query text to the callback

### Changes to `components/RelationshipPicker.tsx`
- Same `onQuickAdd` signature change to `(searchText: string) => void`
- "Create new child…" option passes the current search query text

### Changes to `components/QuickAddRelative.tsx`
- Added optional `initialFirstName` prop
- When creating a new relative (not editing), the First Name field initializes to `initialFirstName || ''`
- When editing an existing pending person, their own first name is used (initial is ignored)

### Changes to `App.tsx`
- Added `quickAddInitialName` state to store the search text
- `onQuickAdd` callbacks capture the search text and set it as the initial first name
- Passes `initialFirstName={quickAddInitialName}` to `QuickAddRelativeDialog`

---

## Session 115 — Navigate Household Link Opens Edit Mode

### Action
In the Edit Person form, clicking the "Managed by \<household name\>" link now opens the person's household record directly in edit mode, instead of navigating to the Households list view.

### Changes to `App.tsx`
- Added `editHouseholdId` state
- The `onNavigateHousehold` callback now sets `editHouseholdId` to the person's household ID before navigating to the households view

### Changes to `components/HouseholdView.tsx`
- Added `editHouseholdId` and `onClearEditHouseholdId` props
- Added `useEffect` that auto-opens the household edit form when `editHouseholdId` is set and matches an existing household

---

## Session 116 — Contextual "← Back to Person" Navigation (Added then Reverted)

### Action
Added a contextual "← Back to Person" link in the Households view when navigating from a person edit form, preserving in-progress form state for round-trip editing.

### Changes to `App.tsx`
- Added `returnToPersonForm` state tracking the person being edited
- When navigating from person form to household, sets the return state
- Households view conditionally shows "← Back to Person" or "← Back to Directory"

### Reversion (Session 117)
User requested the change be undone. `returnToPersonForm` state removed; households view reverted to always showing "← Back to Directory".

---

## Session 117 — Reverted "← Back to Person" Navigation

### Action
Reverted the contextual back-navigation feature added in Session 116. The Households view now always shows "← Back to Directory" as its only back-navigation option.

### Changes to `App.tsx`
- Removed `returnToPersonForm` state
- Removed conditional back-navigation logic from households view

---

## Session 118 — Simplified Household Address Editing (Inline on Person Form)

### Problem
Editing a household address required navigating from the Edit Person form to the Edit Household form and back — overly complicated for a common task.

### Solution
Made household addresses editable directly on the person form. When saved, changes propagate to all other household members automatically.

### Changes to `components/AddressFields.tsx`
- Removed `householdName`, `onNavigateHousehold`, and `readOnly` behavior for household-managed addresses
- Removed "Managed by \<household name\>" link text entirely
- Added `lockLabel` prop: when set, the address label shows a static "Household" badge (not changeable via dropdown) and the address cannot be deleted
- All address input fields (street, street2, city, state, ZIP, country) are now fully editable regardless of household membership

### Changes to `hooks/usePersonForm.ts`
- Added household address sync logic in `save()`:
  - After saving the person, checks if they belong to a household
  - If the household address changed, updates the household record with the new address
  - Propagates the updated address to all other household members
  - Only syncs if the address actually changed (compares field-by-field)

### Changes to `components/HouseholdView.tsx`
- Removed `editHouseholdId` and `onClearEditHouseholdId` props
- Removed the `useEffect` that auto-opened a household edit form from an external trigger

### Changes to `App.tsx`
- Removed `editHouseholdId` state and related props
- Removed `householdName` and `onNavigateHousehold` props from `MultiAddressFields`
- Passes `lockLabel` prop for household-managed addresses

### Behavior Summary
| Before | After |
|--------|-------|
| Household address shown as read-only with "Managed by \<name\>" link | Household address fields fully editable inline |
| Editing required navigating to Household view | Edit directly on person form, save propagates to all members |
| Address label changeable | Label locked to "Household" badge (not deletable) |

---

## Session 119 — Log Update

### Action
- Updated `DEVLOG.md` to include Sessions 110–119 reflecting the latest conversation history

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
├── hooks/
│   ├── useDirectoryData.ts          # Core data loading, filtering, search
│   ├── useDirectoryActions.ts       # Delete & bulk action handlers
│   ├── usePersonForm.ts             # Person form state, validation, save logic
│   └── useCompanyForm.ts            # Company form state, validation, save logic
├── views/
│   ├── DetailView.tsx               # Person/company detail view with collapsible sections
│   └── ImportView.tsx               # CSV/household import preview
├── components/
│   ├── AddressFields.tsx            # Address form with AI auto-suggest, lockLabel for households
│   ├── BulkActions.tsx              # Multi-select bulk actions bar
│   ├── CollapsibleSection.tsx       # Expand/collapse section wrapper
│   ├── CountryCodeSelect.tsx        # Country code dropdown
│   ├── DeleteDialogs.tsx            # Delete and Delete All confirmation dialogs
│   ├── DuplicateWarning.tsx         # Duplicate detection warnings
│   ├── EmailInput.tsx               # Email input with blur validation
│   ├── FamilyTree.tsx               # Multi-generation family tree visualization
│   ├── FilterBar.tsx                # Progressive disclosure filter UI
│   ├── HouseholdPicker.tsx          # Household member management with inline creation
│   ├── HouseholdView.tsx            # Household CRUD view
│   ├── ImageCropper.tsx             # Interactive circular crop overlay
│   ├── MultiItemField.tsx           # Multi-item selector with search/chips
│   ├── PhoneInput.tsx               # Phone input with blur validation
│   ├── PrintDirectory.tsx           # Print-optimized directory export
│   ├── ProfileImage.tsx             # Profile image avatar with upload
│   ├── QuickAddRelative.tsx         # Quick add spouse/child dialog with initialFirstName
│   ├── RelationshipPicker.tsx       # Children picker with "Create new child…" option
│   ├── SpousePicker.tsx             # Spouse picker with "Create new spouse…" option
│   ├── Toast.tsx                    # Toast notification system
│   └── VCardExport.tsx              # vCard 3.0 export
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
| `user-preferences` (private) | Collapsed section state per user | `detail-collapsed-sections` |

## Outstanding Tasks
- Auto-suggest household name from person's last name (e.g., "The Smith Family")
- Add "Or search for an existing household…" link in create-eligible mode
- Enhance save toast to confirm household address was synced across members
