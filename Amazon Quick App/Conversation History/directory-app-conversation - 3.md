# 📒 Directory Application — Conversation Log

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
- Emails, phones, and addresses stored as arrays with `isPrimary` and `label` fields
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
- Data stored in shared `directory-entries` table, accessible to all app users
- Export via "📄 Export Log" button or a future CSV export feature

## 6. Multi-Value Enhancement
- Emails, phones, and addresses upgraded from single to multi-value with primary designation
- Phone numbers formatted to E.164 standard
- Legacy data auto-migrated on load

## 7. Follow-Up Suggestions (Round 3)
1. Tagging & Categorization System
2. Bulk Actions & Multi-Select
3. Map View for Addresses

## 8. Duplicate Detection Feature
- Added `findDuplicates` function that compares form values against existing entries
- Checks three fields: **name** (exact, case-insensitive), **primary email** (exact, case-insensitive), **primary phone** (normalized digits)
- Excludes the entry being edited from comparisons
- Added reusable `DuplicateWarningBanner` component with amber warning styling
- Banner shows each suspected duplicate with type badge, name, match reasons, and a "View" link
- Uses `React.useMemo` for real-time checking as user types in person or company forms
- Banner appears at top of both Person and Company forms, below heading

## 9. Follow-Up Suggestions (Round 4)
1. CSV Export & Import
2. Favorites & Quick Access
3. Activity Log / Recent Changes
