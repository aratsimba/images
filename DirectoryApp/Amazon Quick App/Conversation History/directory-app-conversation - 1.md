# 📒 Directory Application — Conversation Log

## 1. Initial Request

> Create a directory application that manages person and company biographical information. In addition, the application meets the following requirements:
>
> 1) For a person, the application keeps tracks of spouse and child relationships. If they are part of the same household, they will have the same primary address.
> 2) For a company, the application keeps track of its contact persons.
> 3) For an address, the application will look-up and auto-suggest valid addresses in the USA.
> 4) The application provides a unified search capability that searches the persons and companies in the directory. This capability offers an auto-suggest and auto-fill feature as the user enters partial letters in the search field.

---

## 2. Application Summary

### Features Built

#### Person Management
- Add/edit/delete persons with first name, last name, email, phone, address, and notes
- **Spouse relationships** — selecting a spouse automatically links both persons bidirectionally and assigns them to the same household
- **Children relationships** — add multiple children via a searchable picker with chip-based selection
- **Household system** — persons in the same household (spouse, children) automatically share the same primary address. When any household member's address is updated, all other members' addresses sync automatically

#### Company Management
- Add/edit/delete companies with name, industry, email, phone, address, and notes
- **Contact persons** — link multiple persons from the directory as company contacts via a searchable picker

#### Address Auto-Suggest (AI-powered)
- When typing in the Street field (3+ characters), the app uses AI inference to suggest up to 5 valid US addresses
- Selecting a suggestion auto-fills all address fields (street, city, state, ZIP)
- Debounced at 400ms to avoid excessive API calls

#### Unified Search
- Header search bar searches across all persons and companies simultaneously
- **Auto-suggest dropdown** — as you type, matching entries appear in a dropdown with type icons (👤/🏢)
- **Auto-fill** — clicking a suggestion fills the search field and navigates to the detail view
- Filters the main list in real-time

#### Detail View
- Clickable relationship chips (spouse, children, contacts, household members) navigate between entries
- Household members section shows all persons sharing the same address

#### Data Persistence
- All data is stored in shared server-side storage, accessible to anyone with app access

### Data Model

```typescript
interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
}

interface Person {
  id: string;
  type: 'person';
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: Address;
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
  email: string;
  phone: string;
  address: Address;
  contactPersonIds: string[];
  notes: string;
}
```

### Key Design Decisions
- **Household ID** — a UUID shared by household members. When a spouse is selected, the household IDs are unified automatically.
- **Bidirectional spouse link** — saving a person with a spouse also updates the spouse record to point back.
- **Address sync** — saving a person propagates the address to all members of the same household.
- **AI address suggest** — uses Claude Haiku for fast, low-cost address completion with a 400ms debounce.
- **Shared storage** — all directory data is stored in a single `directory-entries` table using shared App Storage, so all app users see the same data.

### Integrations Used
- **AI Inference** — address auto-suggest via Claude Haiku
- **App Storage (Shared)** — persistent directory data

---

## 3. Follow-Up Improvement Suggestions

1. **Export & Import Directory Data** — Add the ability to export the entire directory (or filtered results) as a CSV file for offline use or sharing, and an import capability to bulk-load persons and companies from a CSV. This would be especially useful for migrating existing contact lists into the app or creating backups.

2. **Dashboard Analytics & Summary Stats** — Add a dashboard view at the top of the list page showing key metrics such as total persons, total companies, number of households, and industry breakdown (e.g., a bar or pie chart using Recharts). This would give users a quick at-a-glance overview of their directory's composition without scrolling through entries.

3. **Sorting & Filtering Controls** — Add controls above the list to sort entries by name, date added, or type (person/company), and filter by type, state/city, or industry. This would make it much easier to navigate large directories — for example, quickly viewing only companies in a specific industry, or all persons in a particular state.
