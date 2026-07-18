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

