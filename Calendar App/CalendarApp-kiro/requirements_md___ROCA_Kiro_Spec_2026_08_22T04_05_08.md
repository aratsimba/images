
# ROCA — Religious Organization Calendar Application
## Requirements

### Feature: Multi-Tenant Organization & Campus Management

#### 1. Organization Registration & Configuration
**As a** super administrator  
**I want to** register a new religious organization and configure its settings  
**So that** the organization can begin using the calendar system with denomination-specific features

**Acceptance Criteria (EARS):**
- WHEN a super admin submits organization registration details, THE SYSTEM SHALL create a new organization record with UUID, store denomination type, timezone, and branding settings
- WHEN an organization is created, THE SYSTEM SHALL automatically generate a default "Main Campus" and seed liturgical seasons based on the selected denomination
- WHEN a user attempts to access data from another organization, THE SYSTEM SHALL reject the request with AUTH_002 error and log the access attempt
- WHERE the system stores any data entity, THE SYSTEM SHALL include org_id as a mandatory foreign key for multi-tenancy isolation

#### 2. Campus Management
**As an** administrator  
**I want to** manage multiple campus locations for my organization  
**So that** events, rooms, and volunteers can be organized by physical site

**Acceptance Criteria (EARS):**
- WHEN an admin creates a new campus, THE SYSTEM SHALL validate required fields (name, address, timezone) and associate it with the current organization
- WHEN a campus is marked as primary, THE SYSTEM SHALL ensure only one campus per organization holds primary status
- WHEN a user filters by campus, THE SYSTEM SHALL display only events, rooms, and volunteers associated with that campus
- WHEN a campus is deactivated, THE SYSTEM SHALL soft-delete the record and cascade-hide all future events at that campus

#### 3. Room & Facility Booking
**As an** event coordinator  
**I want to** view room availability and book facilities for events  
**So that** scheduling conflicts are prevented and resources are managed efficiently

**Acceptance Criteria (EARS):**
- WHEN a user selects a room for an event, THE SYSTEM SHALL check for time conflicts with existing bookings and display availability status
- WHEN a room conflict is detected, THE SYSTEM SHALL return EVENT_002 error with details of the conflicting event
- WHEN a room is booked, THE SYSTEM SHALL display capacity, accessibility features (wheelchair, A/V), and amenities in the event detail
- WHERE a recurring event books a room, THE SYSTEM SHALL reserve the room for all instances in the recurrence series

---

### Feature: Event Management & Calendar

#### 4. Event Creation
**As a** leader or administrator  
**I want to** create events with detailed information including recurrence patterns  
**So that** community members can discover and attend church activities

**Acceptance Criteria (EARS):**
- WHEN a user submits a new event via the 4-step wizard (Basics → When/Where → Options → Review), THE SYSTEM SHALL validate all required fields and create the event record
- WHEN an event includes a recurrence rule, THE SYSTEM SHALL store it in RFC 5545 RRULE format and expand instances for calendar display up to the recurrence_end_date
- WHEN an event is created with visibility "members_only" or "leaders_only", THE SYSTEM SHALL restrict access based on the viewer's role
- WHEN an event is saved as draft, THE SYSTEM SHALL persist all entered data without publishing to the calendar
- WHEN an event is published, THE SYSTEM SHALL make it visible according to its visibility setting and trigger notifications to relevant subscribers

#### 5. Event Recurrence Management
**As an** administrator  
**I want to** edit individual or all instances of a recurring event  
**So that** I can handle exceptions (e.g., cancelling one Sunday for a holiday) without disrupting the series

**Acceptance Criteria (EARS):**
- WHEN a user edits a recurring event, THE SYSTEM SHALL prompt with scope options: "This event only", "This and future events", or "All events in series"
- WHEN "This event only" is selected, THE SYSTEM SHALL create an exception record with modified data while preserving the original series
- WHEN "This and future events" is selected, THE SYSTEM SHALL split the series at the selected date, ending the original and creating a new series
- WHEN "All events" is selected, THE SYSTEM SHALL update the master event record and regenerate all non-exception instances
- WHEN a single instance is cancelled, THE SYSTEM SHALL add an EXDATE to the RRULE and mark that instance as cancelled

#### 6. Calendar Display & Filtering
**As a** community member  
**I want to** view the calendar in multiple formats (month, week, day, list) with filtering options  
**So that** I can easily find events relevant to me

**Acceptance Criteria (EARS):**
- WHEN a user opens the calendar, THE SYSTEM SHALL display the current month view with color-coded event indicators by category
- WHEN a user selects a different view mode (week, day, list), THE SYSTEM SHALL re-render events in the chosen format within 800ms
- WHEN a user applies campus or category filters, THE SYSTEM SHALL update the display to show only matching events
- WHEN a day has more than 3 events in month view, THE SYSTEM SHALL show a "+N more" indicator and expand on click
- WHEN today's date is displayed, THE SYSTEM SHALL highlight it with the primary liturgical season color

#### 7. Event Detail Display
**As a** community member  
**I want to** view comprehensive event details including amenities, readings, and volunteer status  
**So that** I have all the information needed to attend or participate

**Acceptance Criteria (EARS):**
- WHEN a user clicks an event, THE SYSTEM SHALL display a detail flyout/panel with title, datetime, location, description, amenities, scripture readings, and volunteer roster
- WHEN the event has available capacity, THE SYSTEM SHALL show attendance count and remaining spots with a progress indicator
- WHEN the event offers livestream, THE SYSTEM SHALL display a "Watch Livestream" action button with the streaming URL
- WHEN the event has volunteer gaps, THE SYSTEM SHALL show open positions with "Sign Up" calls-to-action

---

### Feature: RSVP & Registration System

#### 8. Event Registration
**As a** community member  
**I want to** RSVP to events and manage my registrations  
**So that** organizers can plan capacity and I receive relevant reminders

**Acceptance Criteria (EARS):**
- WHEN a member submits an RSVP, THE SYSTEM SHALL create a registration record with status "registered" and increment the attendance count
- WHEN an event reaches maximum capacity, THE SYSTEM SHALL automatically place new registrations on a waitlist with status "waitlisted"
- WHEN a registered member cancels, THE SYSTEM SHALL promote the next waitlisted member to "registered" status and notify them
- WHEN a member attempts to register for an event they're already registered for, THE SYSTEM SHALL return REG_002 error
- WHEN an event requires RSVP, THE SYSTEM SHALL display "RSVP Required" badge and prevent access to livestream/details without registration

#### 9. Waitlist Management
**As an** administrator  
**I want to** manage waitlists with automatic promotion  
**So that** events remain at capacity even when cancellations occur

**Acceptance Criteria (EARS):**
- WHEN a cancellation creates an opening, THE SYSTEM SHALL auto-promote the earliest waitlisted member within 60 seconds
- WHEN a member is promoted from waitlist, THE SYSTEM SHALL send a push notification with deep link to the event detail
- WHEN multiple cancellations occur simultaneously, THE SYSTEM SHALL process promotions in FIFO order based on waitlist timestamp
- WHEN an admin exports registrations, THE SYSTEM SHALL generate a CSV with member name, email, party size, status, and registration timestamp

---

### Feature: Volunteer Scheduling System

#### 10. Volunteer Role Management
**As an** administrator  
**I want to** define volunteer roles with minimum/maximum requirements per event  
**So that** services are properly staffed and responsibilities are clear

**Acceptance Criteria (EARS):**
- WHEN an admin creates a volunteer role, THE SYSTEM SHALL store name, description, min/max volunteer counts, and required skills/training
- WHEN a role's minimum volunteer count is not met for an upcoming event, THE SYSTEM SHALL flag it as a "gap" and display it in the alert banner
- WHEN the volunteer schedule is viewed, THE SYSTEM SHALL display a role × event matrix with assignment status indicators (confirmed, pending, open)

#### 11. Volunteer Assignment & Confirmation
**As a** volunteer  
**I want to** view my assignments, confirm or decline shifts, and request swaps  
**So that** I can manage my serving commitments effectively

**Acceptance Criteria (EARS):**
- WHEN a volunteer is assigned to an event, THE SYSTEM SHALL send a notification with confirm/decline options
- WHEN a volunteer confirms, THE SYSTEM SHALL update assignment status to "confirmed" and display a green checkmark
- WHEN a volunteer declines, THE SYSTEM SHALL revert the assignment to "open" status and notify the admin
- WHEN a volunteer requests a swap, THE SYSTEM SHALL send a swap request to the target volunteer with both shift details
- WHEN a swap is accepted by both parties, THE SYSTEM SHALL atomically update both assignments and send confirmation to both

#### 12. Auto-Scheduling
**As an** administrator  
**I want to** auto-fill volunteer gaps based on availability and rotation fairness  
**So that** scheduling is efficient and equitable across the volunteer pool

**Acceptance Criteria (EARS):**
- WHEN an admin triggers auto-schedule, THE SYSTEM SHALL use a round-robin algorithm weighted by recent serving frequency
- WHEN auto-schedule generates assignments, THE SYSTEM SHALL present them as "draft" for admin review before publishing
- WHEN auto-schedule cannot fill all gaps, THE SYSTEM SHALL report which roles remain open and suggest expanding the volunteer pool
- WHEN auto-schedule assigns a volunteer, THE SYSTEM SHALL respect opt-out dates, maximum frequency preferences, and role qualifications

#### 13. Gap Detection & Alerts
**As an** administrator  
**I want to** be alerted about unfilled volunteer positions  
**So that** I can take action before events are understaffed

**Acceptance Criteria (EARS):**
- WHEN volunteer gaps exist for events within the next 14 days, THE SYSTEM SHALL display a prominent alert banner with gap count
- WHEN a user views the Openings tab, THE SYSTEM SHALL list all unfilled positions grouped by role with "Sign Me Up" actions
- WHEN a volunteer signs up for an opening, THE SYSTEM SHALL immediately update the gap count and send confirmation

---

### Feature: Liturgical Calendar & Scripture Integration

#### 14. Liturgical Season Management
**As a** pastor  
**I want to** manage liturgical seasons with automatic theming  
**So that** the app reflects the spiritual rhythm of the church year

**Acceptance Criteria (EARS):**
- WHEN the current date falls within a liturgical season's date range, THE SYSTEM SHALL apply that season's color theme across the interface
- WHEN a season transition occurs, THE SYSTEM SHALL update the theme within 24 hours of the new season start date
- WHEN a pastor generates seasons for a new year, THE SYSTEM SHALL compute dates based on denomination rules (e.g., Easter calculation for moveable feasts)
- WHERE the system displays a season banner, THE SYSTEM SHALL show the season name, week number, and associated color

#### 15. Scripture & Lectionary Integration
**As a** pastor  
**I want to** assign scripture readings to events and import lectionary cycles  
**So that** members can follow along with the church's reading plan

**Acceptance Criteria (EARS):**
- WHEN a pastor assigns readings to an event, THE SYSTEM SHALL store reading_type (first_reading, psalm, epistle, gospel), reference, and optional text
- WHEN a lectionary is bulk-imported, THE SYSTEM SHALL parse the file and create scripture_reading records for each date in the cycle (208+ readings per year)
- WHEN a member views an event with readings, THE SYSTEM SHALL display them organized by type with the reference prominently shown
- WHEN the home screen loads, THE SYSTEM SHALL display today's reading with reference and a key quote

#### 16. Prayer Focus Management
**As a** pastor  
**I want to** set weekly/monthly prayer focuses  
**So that** the community has shared spiritual emphasis

**Acceptance Criteria (EARS):**
- WHEN a pastor creates a prayer focus, THE SYSTEM SHALL store title, description, prayer_type (weekly/monthly/special), and date range
- WHEN the dashboard loads, THE SYSTEM SHALL display the currently active prayer focus based on the current date
- WHEN multiple prayer focuses overlap, THE SYSTEM SHALL display the one with the most specific type (special > weekly > monthly)

---

### Feature: Ministry Groups

#### 17. Group Management
**As a** leader  
**I want to** create and manage ministry groups with rosters  
**So that** small groups, committees, and teams can coordinate activities

**Acceptance Criteria (EARS):**
- WHEN a leader creates a group, THE SYSTEM SHALL store name, type, description, meeting schedule, campus, and designated leader
- WHEN a member joins a group, THE SYSTEM SHALL add them to the group_members table with their role (member/leader/admin)
- WHEN a group has a meeting schedule, THE SYSTEM SHALL auto-generate recurring calendar events linked to the group
- WHEN a user views "My Groups", THE SYSTEM SHALL display all groups they belong to with meeting times and member count

---

### Feature: Notifications & Communication

#### 18. Push Notification System
**As a** community member  
**I want to** receive timely notifications about events, volunteer assignments, and updates  
**So that** I stay informed and engaged with church activities

**Acceptance Criteria (EARS):**
- WHEN a notification trigger fires (event reminder, volunteer assignment, RSVP confirmation, schedule change, gap alert, waitlist promotion, swap request, new event, prayer update), THE SYSTEM SHALL create a notification record and dispatch via APNs (iOS) and FCM (Android)
- WHEN a user taps a notification, THE SYSTEM SHALL deep-link to the relevant screen using the URI scheme roca://{path}
- WHEN a user has quiet hours configured, THE SYSTEM SHALL queue notifications and deliver them after the quiet period ends
- WHEN a notification is delivered, THE SYSTEM SHALL update delivery status (created → queued → sent → delivered/failed)
- WHEN a user views the notification center, THE SYSTEM SHALL display notifications grouped by time period with read/unread indicators

#### 19. Event Reminders
**As a** registered attendee  
**I want to** receive reminders before events I've registered for  
**So that** I don't forget to attend

**Acceptance Criteria (EARS):**
- WHEN an event is 24 hours away, THE SYSTEM SHALL send a reminder notification to all registered members
- WHEN an event is 1 hour away, THE SYSTEM SHALL send a final reminder with quick actions (Get Directions, Watch Livestream)
- WHEN a volunteer is scheduled, THE SYSTEM SHALL send an additional reminder 2 hours before with role and check-in details

---

### Feature: Authentication & Authorization

#### 20. User Authentication
**As a** user  
**I want to** securely register, log in, and manage my session  
**So that** my account and data are protected

**Acceptance Criteria (EARS):**
- WHEN a user registers, THE SYSTEM SHALL hash the password with bcrypt (cost factor 12), create a member record, and return a JWT token pair
- WHEN a user logs in with valid credentials, THE SYSTEM SHALL issue an access token (15-minute TTL) and refresh token (7-day TTL)
- WHEN an access token expires, THE SYSTEM SHALL accept a valid refresh token and issue a new token pair without requiring re-login
- WHEN a refresh token expires or is revoked, THE SYSTEM SHALL force re-authentication
- WHEN a user attempts an action exceeding their role permissions, THE SYSTEM SHALL return AUTH_002 with a description of the required role

#### 21. Role-Based Access Control
**As an** administrator  
**I want to** assign roles that determine what users can see and do  
**So that** sensitive information and administrative functions are properly secured

**Acceptance Criteria (EARS):**
- WHERE the system evaluates access, THE SYSTEM SHALL enforce a 7-tier role hierarchy: guest < member < volunteer < leader < admin < pastor < super_admin
- WHEN a leader creates or edits events, THE SYSTEM SHALL scope their permissions to their assigned ministry group or campus only
- WHEN a guest accesses the system, THE SYSTEM SHALL restrict visibility to public events only
- WHEN an admin manages members, THE SYSTEM SHALL allow role assignment up to but not exceeding their own role level

---

### Feature: Calendar Sync & Export

#### 22. External Calendar Integration
**As a** community member  
**I want to** sync church events with my personal calendar  
**So that** I have a unified view of all my commitments

**Acceptance Criteria (EARS):**
- WHEN a user clicks "Add to Calendar", THE SYSTEM SHALL generate an iCal (.ics) file with all event metadata including recurrence rules
- WHEN a user subscribes to the calendar feed, THE SYSTEM SHALL provide an authenticated iCal URL that auto-updates when events change
- WHEN an event is exported, THE SYSTEM SHALL include location, description, organizer, and category in standard iCal fields
- WHEN a user selects Google Calendar or Outlook export, THE SYSTEM SHALL generate the appropriate deep link with pre-filled event data

---

### Feature: Mobile Experience

#### 23. Offline-First Mobile Access
**As a** community member on mobile  
**I want to** access my schedule and event details without an internet connection  
**So that** I can check information anytime, anywhere

**Acceptance Criteria (EARS):**
- WHEN the mobile app loads, THE SYSTEM SHALL cache the next 7 days of events, user assignments, and group data locally
- WHEN the device loses connectivity, THE SYSTEM SHALL display cached data with an "offline" indicator and queue any write actions
- WHEN connectivity is restored, THE SYSTEM SHALL sync queued actions in order, applying conflict resolution (server-wins for event data, last-write-wins for user preferences)
- WHEN cached data is older than 24 hours without refresh, THE SYSTEM SHALL display a staleness warning

#### 24. Mobile Navigation & Interactions
**As a** mobile user  
**I want to** navigate the app with intuitive gestures and a clear tab structure  
**So that** the experience feels native and efficient

**Acceptance Criteria (EARS):**
- WHEN the app launches, THE SYSTEM SHALL display the 5-tab bottom navigation: Home, Calendar, Add (FAB), Serve, More
- WHEN a user swipes left/right on the calendar, THE SYSTEM SHALL navigate to the next/previous week or month
- WHEN a user long-presses on a calendar date, THE SYSTEM SHALL open the quick-add bottom sheet for that date
- WHEN a user taps the center FAB, THE SYSTEM SHALL present the quick-add action sheet (Create Event, RSVP, Prayer Request, Sign Up to Serve)

---

### Feature: Search & Analytics

#### 25. Global Search
**As a** user  
**I want to** search across events, groups, members, and readings  
**So that** I can quickly find what I need

**Acceptance Criteria (EARS):**
- WHEN a user enters a search query, THE SYSTEM SHALL search across event titles, descriptions, group names, member names, and scripture references
- WHEN results are returned, THE SYSTEM SHALL group them by type (Events, Groups, People, Readings) with relevance ranking
- WHEN no results are found, THE SYSTEM SHALL suggest alternative search terms or related content

#### 26. Analytics & Reporting
**As an** administrator  
**I want to** view attendance trends, volunteer metrics, and engagement data  
**So that** I can make data-driven decisions about programming and resources

**Acceptance Criteria (EARS):**
- WHEN an admin accesses analytics, THE SYSTEM SHALL display attendance trends (weekly/monthly), volunteer participation rates, and RSVP conversion rates
- WHEN attendance data is charted, THE SYSTEM SHALL show comparison to previous periods and highlight growth/decline patterns
- WHEN volunteer metrics are displayed, THE SYSTEM SHALL show individual and aggregate serving frequency, gap rates, and role distribution

