
# User Flows & State Diagrams
## Religious Organization Calendar App (ROCA)

---

## 1. User Flows

### 1.1 New Member Onboarding Flow

```
┌─────────┐     ┌──────────┐     ┌──────────────┐     ┌──────────────┐
│  START  │────▶│ Download │────▶│ Select Org   │────▶│ Create Acct  │
│         │     │   App    │     │ (search/code)│     │ (name/email/ │
└─────────┘     └──────────┘     └──────────────┘     │  password)   │
                                                       └──────┬───────┘
                                                              │
                                                              ▼
┌─────────────┐     ┌──────────────┐     ┌───────────────────────────┐
│  Dashboard  │◀────│ Admin Approves│◀────│ Pending Approval Screen   │
│  (Active)   │     │  (or auto)   │     │ "We'll notify you when    │
└──────┬──────┘     └──────────────┘     │  approved"                │
       │                                  └───────────────────────────┘
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  ONBOARDING WIZARD (first-time only)                             │
│                                                                  │
│  Step 1: Select Campus ──▶ Step 2: Choose Categories ──▶         │
│  Step 3: Join Groups ──▶ Step 4: Set Notification Prefs ──▶      │
│  Step 5: Volunteer Interests (optional) ──▶ DONE                 │
└──────────────────────────────────────────────────────────────────┘
```

---

### 1.2 Event Discovery & RSVP Flow

```
                    ┌─────────────────────────────────┐
                    │         ENTRY POINTS             │
                    ├─────────────────────────────────┤
                    │ • Dashboard upcoming list        │
                    │ • Calendar tap on date           │
                    │ • Push notification              │
                    │ • Search results                 │
                    │ • Group event listing            │
                    │ • Shared link (deep link)        │
                    └──────────────┬──────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────┐
                    │       EVENT DETAIL SCREEN        │
                    │                                  │
                    │  Title, date, time, location,    │
                    │  description, amenities,         │
                    │  scripture, volunteers           │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────┼──────────────────┐
                    │              │                  │
                    ▼              ▼                  ▼
         ┌──────────────┐ ┌─────────────┐ ┌─────────────────┐
         │ RSVP/Register│ │ Add to Cal  │ │ Watch Livestream │
         └──────┬───────┘ └─────────────┘ └─────────────────┘
                │
                ▼
     ┌────────────────────┐
     │ Capacity Available? │
     └────────┬───────────┘
              │
       ┌──────┴──────┐
       │YES          │NO
       ▼             ▼
┌─────────────┐  ┌───────────────┐
│ Party Size  │  │ Join Waitlist?│
│ + Notes     │  └──────┬────────┘
└──────┬──────┘         │
       │          ┌─────┴─────┐
       ▼          │YES        │NO
┌─────────────┐   ▼           ▼
│ Confirmation│  ┌────────┐  ┌──────┐
│ + Email     │  │Waitlist│  │ End  │
│ + Calendar  │  │Confirm │  └──────┘
│   .ics file │  └────────┘
└─────────────┘
```

---

### 1.3 Event Creation Flow (Leader/Admin/Pastor)

```
┌─────────────┐
│ Entry Points│
│ • FAB (+)   │
│ • Calendar  │
│   long-press│
│ • Admin menu│
└──────┬──────┘
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│                     EVENT CREATION WIZARD                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────┐    ┌─────────────┐    ┌─────────┐    ┌─────────┐  │
│  │ STEP 1  │───▶│   STEP 2    │───▶│ STEP 3  │───▶│ STEP 4  │  │
│  │ Basics  │    │ When/Where  │    │ Options │    │ Review  │  │
│  │         │    │             │    │         │    │         │  │
│  │• Title  │    │• Start date │    │• RSVP   │    │• Preview│  │
│  │• Category│    │• End date   │    │• Capacity│    │• Confirm│  │
│  │• Type   │    │• Recurring? │    │• Childcr│    │         │  │
│  │• Descrip│    │• Campus     │    │• Live   │    │[Publish]│  │
│  │         │    │• Room       │    │• Vis.   │    │[Draft]  │  │
│  │         │    │             │    │• Contact│    │         │  │
│  └─────────┘    └──────┬──────┘    └─────────┘    └────┬────┘  │
│                        │                                │       │
│                        ▼                                │       │
│               ┌─────────────────┐                       │       │
│               │ CONFLICT CHECK  │                       │       │
│               │ (room/time)     │                       │       │
│               └────────┬────────┘                       │       │
│                   ┌────┴────┐                           │       │
│                   │CLEAR    │CONFLICT                   │       │
│                   ▼         ▼                           │       │
│              Continue   ┌──────────┐                    │       │
│                         │ Show     │                    │       │
│                         │ conflicts│                    │       │
│                         │ + suggest│                    │       │
│                         │ alt rooms│                    │       │
│                         └──────────┘                    │       │
└─────────────────────────────────────────────────────────┼───────┘
                                                          │
                                              ┌───────────┴──────────┐
                                              │                      │
                                              ▼                      ▼
                                     ┌──────────────┐      ┌──────────────┐
                                     │   PUBLISHED  │      │   DRAFT      │
                                     │ • Visible    │      │ • Not visible│
                                     │ • Notifies   │      │ • Editable   │
                                     │   subscribers│      │ • Resumable  │
                                     └──────────────┘      └──────────────┘
```

---

### 1.4 Volunteer Assignment & Confirmation Flow

```
                         ┌──────────────────────────┐
                         │     SCHEDULING PATHS      │
                         ├──────────────────────────┤
                         │ A) Admin manual assign    │
                         │ B) Auto-scheduler         │
                         │ C) Volunteer self sign-up │
                         └─────────────┬────────────┘
                                       │
            ┌──────────────────────────┼─────────────────────────┐
            │ A                        │ B                        │ C
            ▼                          ▼                          ▼
┌───────────────────┐    ┌────────────────────────┐   ┌───────────────────┐
│ Admin selects:    │    │ Auto-scheduler runs:   │   │ Volunteer browses │
│ • Event           │    │ • Date range           │   │ "Available        │
│ • Role            │    │ • Strategy (round-     │   │  Openings" tab    │
│ • Volunteer       │    │   robin/weighted)      │   │                   │
│                   │    │ • Produces draft        │   │ Taps "Sign Me Up" │
└────────┬──────────┘    └───────────┬────────────┘   └─────────┬─────────┘
         │                           │                          │
         │                           ▼                          │
         │               ┌────────────────────────┐             │
         │               │ Admin reviews draft    │             │
         │               │ • Approve all          │             │
         │               │ • Modify individuals   │             │
         │               │ • Reject & re-run      │             │
         │               └───────────┬────────────┘             │
         │                           │                          │
         └───────────────────────────┼──────────────────────────┘
                                     │
                                     ▼
                        ┌────────────────────────┐
                        │  ASSIGNMENT CREATED     │
                        │  Status: ASSIGNED       │
                        │  Push notification sent │
                        └───────────┬────────────┘
                                    │
                                    ▼
                        ┌────────────────────────┐
                        │  VOLUNTEER RESPONDS     │
                        └───────────┬────────────┘
                                    │
                   ┌────────────────┼────────────────┐
                   │                │                 │
                   ▼                ▼                 ▼
          ┌──────────────┐ ┌──────────────┐ ┌───────────────┐
          │   CONFIRM    │ │   DECLINE    │ │  REQUEST SWAP │
          │              │ │              │ │               │
          │ Status:      │ │ Status:      │ │ Select person │
          │ CONFIRMED    │ │ DECLINED     │ │ to swap with  │
          └──────────────┘ └──────┬───────┘ └───────┬───────┘
                                  │                  │
                                  ▼                  ▼
                        ┌──────────────┐   ┌──────────────────┐
                        │ GAP CREATED  │   │ SWAP REQUEST     │
                        │              │   │ Status: PENDING  │
                        │ • Alert admin│   │                  │
                        │ • Post to    │   │ Notify target    │
                        │   "Openings" │   │ volunteer        │
                        │ • Notify     │   └────────┬─────────┘
                        │   eligible   │            │
                        │   volunteers │     ┌──────┴──────┐
                        └──────────────┘     │             │
                                             ▼             ▼
                                    ┌───────────┐ ┌───────────┐
                                    │  ACCEPTED │ │ REJECTED  │
                                    │           │ │           │
                                    │ Both      │ │ Original  │
                                    │ updated   │ │ assignment│
                                    │ Notified  │ │ unchanged │
                                    └───────────┘ └───────────┘
```

---

### 1.5 Event Cancellation & Notification Flow

```
┌──────────────────┐
│ Admin/Pastor     │
│ opens event      │
│ → Menu → Cancel  │
└────────┬─────────┘
         │
         ▼
┌────────────────────────────────────┐
│  IS EVENT RECURRING?               │
└────────────────┬───────────────────┘
                 │
    ┌────────────┼────────────────┐
    │ ONE-TIME   │ RECURRING      │
    ▼            ▼                │
┌────────┐   ┌────────────────┐   │
│ Cancel │   │ Cancel scope:  │   │
│ Event  │   │ ○ This only    │   │
│        │   │ ○ This+future  │   │
└───┬────┘   │ ○ All          │   │
    │        └───────┬────────┘   │
    │                │            │
    └────────────────┘            │
              │                   │
              ▼                   │
┌────────────────────────────────┐│
│  CANCELLATION FORM             ││
│                                ││
│  Reason: [________________]    ││
│                                ││
│  ☑ Notify registered attendees ││
│  ☑ Notify assigned volunteers  ││
│  ☐ Post public announcement    ││
│                                ││
│  [Cancel Event]  [Go Back]     ││
└──────────────┬─────────────────┘│
               │                   │
               ▼                   │
┌──────────────────────────────────┘
│  SYSTEM ACTIONS:
│
│  1. Event status → CANCELLED
│  2. Volunteer assignments → RELEASED
│  3. Push notifications → all registered
│  4. Email → all registered + volunteers
│  5. Calendar .ics update → CANCELLED
│  6. Dashboard alert posted
│  7. Waitlisted users notified (if rescheduled)
│  8. Webhook fired: event.cancelled
└──────────────────────────────────────
```

---

### 1.6 Scripture & Lectionary Management Flow (Pastor)

```
┌──────────────────────────────────────────────────────────┐
│                   ENTRY PATHS                             │
├──────────────────────────────────────────────────────────┤
│  A) Manual entry per event/date                          │
│  B) Bulk import from lectionary template                 │
│  C) Edit existing reading assignment                     │
└──────────────────────────┬───────────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          │ A              │ B              │ C
          ▼                ▼                ▼
┌──────────────┐  ┌────────────────┐  ┌──────────────────┐
│ Select event │  │ Choose:        │  │ Navigate to      │
│ or date      │  │ • Lectionary   │  │ existing reading │
│              │  │   (RCL/Cath/   │  │ via event detail │
│ Add reading: │  │    Lutheran)   │  │ or calendar      │
│ • Type       │  │ • Year (A/B/C) │  │                  │
│ • Reference  │  │ • Date range   │  │ Edit reference   │
│ • Full text  │  │                │  │ or text          │
│   (optional) │  │ [Import →]     │  │                  │
└──────┬───────┘  └───────┬────────┘  └────────┬─────────┘
       │                  │                     │
       │                  ▼                     │
       │        ┌────────────────────┐          │
       │        │ Preview import:    │          │
       │        │ "52 weeks, 208     │          │
       │        │  readings to add"  │          │
       │        │                    │          │
       │        │ [Confirm] [Cancel] │          │
       │        └────────┬───────────┘          │
       │                 │                      │
       └─────────────────┼──────────────────────┘
                         │
                         ▼
              ┌────────────────────┐
              │ READINGS SAVED     │
              │                    │
              │ • Visible on event │
              │   detail screens   │
              │ • Dashboard today's│
              │   scripture card   │
              │ • Widget display   │
              │ • Daily push (opt) │
              └────────────────────┘
```

---

### 1.7 Recurring Event Management Flow

```
┌───────────────────────────────────┐
│  CREATE RECURRING EVENT           │
│                                   │
│  Pattern: [Weekly          ▾]     │
│  On:      [☑ Sun ☐ Mon ... ]     │
│  Until:   [○ Never ○ Date ○ After N] │
│                                   │
│  RRULE generated:                 │
│  FREQ=WEEKLY;BYDAY=SU;            │
│  UNTIL=20261231                   │
└──────────────────┬────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────────────────┐
│                    EDIT SCOPE DECISION                          │
│                                                                │
│  When editing or cancelling a recurring event instance:        │
│                                                                │
│  ┌──────────────────┐  ┌─────────────────┐  ┌──────────────┐  │
│  │  THIS INSTANCE   │  │ THIS & FUTURE   │  │ ALL INSTANCES│  │
│  │  ONLY            │  │                 │  │              │  │
│  │                  │  │ Creates new     │  │ Updates the  │  │
│  │ Creates an       │  │ series from     │  │ master event │  │
│  │ exception to     │  │ this date with  │  │ + all past & │  │
│  │ the series       │  │ new properties  │  │ future       │  │
│  │                  │  │                 │  │              │  │
│  │ Original series  │  │ Original series │  │              │  │
│  │ unchanged        │  │ ends day before │  │              │  │
│  └──────────────────┘  └─────────────────┘  └──────────────┘  │
└────────────────────────────────────────────────────────────────┘

              Exception Storage:
              ┌─────────────────────────────┐
              │ recurrence_exceptions table │
              │                             │
              │ • exception_id (UUID)       │
              │ • event_id (parent series)  │
              │ • original_date (DATE)      │
              │ • exception_type:           │
              │   - modified (new details)  │
              │   - cancelled (skipped)     │
              │   - rescheduled (new date)  │
              │ • override_event_id (UUID)  │
              │   (points to modified copy) │
              └─────────────────────────────┘
```

---

### 1.8 Push Notification Engagement Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                     NOTIFICATION LIFECYCLE                         │
└──────────────────────────────────────────────────────────────────┘

  TRIGGER EVENT                    SYSTEM PROCESSES              USER ACTION
  ─────────────                    ────────────────              ───────────

  Event in 1 hour ─────────▶ ┌───────────────────┐
                             │ Notification       │
  Volunteer assigned ───────▶│ Service evaluates: │
                             │                    │
  Event cancelled ──────────▶│ • User preferences │
                             │ • Quiet hours?     │
  Volunteer gap found ──────▶│ • Category sub'd?  │
                             │ • Device token     │
  RSVP confirmed ──────────▶│ • Badge count      │
                             └─────────┬─────────┘
                                       │
                          ┌────────────┼────────────┐
                          │            │            │
                          ▼            ▼            ▼
                   ┌──────────┐ ┌──────────┐ ┌──────────────┐
                   │   PUSH   │ │  IN-APP  │ │    EMAIL     │
                   │          │ │  BADGE   │ │  (digest or  │
                   │ • Title  │ │          │ │   instant)   │
                   │ • Body   │ │ 🔔 count │ │              │
                   │ • Action │ │ updated  │ │              │
                   │ • Deep   │ │          │ │              │
                   │   link   │ │          │ │              │
                   └─────┬────┘ └──────────┘ └──────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │ USER TAPS PUSH      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────────────────────┐
              │ DEEP LINK ROUTING                    │
              ├─────────────────────────────────────┤
              │ roca://event/{id}      → Event Detail│
              │ roca://serve/schedule  → My Schedule │
              │ roca://serve/openings  → Openings   │
              │ roca://notifications   → Notif List │
              │ roca://groups/{id}     → Group Page │
              └─────────────────────────────────────┘
```

---

## 2. State Diagrams

### 2.1 Event Lifecycle States

```
                              ┌───────────────────────────────────────┐
                              │          EVENT STATE MACHINE           │
                              └───────────────────────────────────────┘

                                        ┌─────────┐
                                        │  DRAFT  │
                                        └────┬────┘
                                             │
                                             │ [publish]
                                             ▼
                    ┌───────────────────────────────────────────────┐
                    │                   ACTIVE                       │
                    │                                               │
                    │  (accepting RSVPs, visible per visibility)    │
                    └───────────────────┬──────────────────┬────────┘
                                        │                  │
                       ┌────────────────┼─────────┐        │
                       │                │         │        │ [cancel]
                       │ [postpone]     │ [time   │        │
                       │                │  passes]│        ▼
                       ▼                │         │    ┌──────────┐
                  ┌──────────┐          │         │    │CANCELLED │
                  │POSTPONED │          │         │    │          │
                  │          │          │         │    │• Reason  │
                  │• New date│          │         │    │• Notified│
                  │  TBD     │          │         │    └──────────┘
                  └─────┬────┘          │         │
                        │               │         │
                        │ [reschedule]  │         │
                        │               │         │
                        └───────────────┘         │
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │  IN PROGRESS │
                                          │  (happening  │
                                          │   now)       │
                                          └──────┬───────┘
                                                 │
                                                 │ [end time reached]
                                                 ▼
                                          ┌──────────────┐
                                          │  COMPLETED   │
                                          │              │
                                          │  • Archived  │
                                          │  • Attendance│
                                          │    recorded  │
                                          └──────────────┘


  TRANSITIONS:
  ──────────────────────────────────────────────────────────
  From        │ To          │ Trigger        │ Who
  ────────────┼─────────────┼────────────────┼─────────────
  DRAFT       │ ACTIVE      │ Publish action │ Creator+
  DRAFT       │ (deleted)   │ Discard action │ Creator+
  ACTIVE      │ CANCELLED   │ Cancel action  │ Admin/Pastor
  ACTIVE      │ POSTPONED   │ Postpone action│ Admin/Pastor
  ACTIVE      │ IN_PROGRESS │ Start time hit │ System
  POSTPONED   │ ACTIVE      │ Reschedule     │ Admin/Pastor
  POSTPONED   │ CANCELLED   │ Cancel action  │ Admin/Pastor
  IN_PROGRESS │ COMPLETED   │ End time hit   │ System
  ──────────────────────────────────────────────────────────
```

---

### 2.2 Registration / RSVP States

```
                    ┌───────────────────────────────────────────────┐
                    │        REGISTRATION STATE MACHINE              │
                    └───────────────────────────────────────────────┘

                              ┌───────────────┐
                              │   REGISTERED  │◀──────────────────────────┐
                              │               │                           │
                              │ • Spot held   │                           │
                              │ • Confirm sent│                           │
                              └───────┬───────┘                           │
                                      │                                   │
                         ┌────────────┼────────────┐                      │
                         │            │            │                      │
                         │ [cancel]   │ [event     │                      │
                         │            │  starts]   │                      │
                         ▼            ▼            │                      │
                  ┌──────────┐ ┌──────────┐        │                      │
                  │CANCELLED │ │ ATTENDED │        │          [spot opens │
                  │(by user) │ │(checked  │        │           + promoted]│
                  │          │ │  in)     │        │                      │
                  │• Spot    │ └──────────┘        │                      │
                  │  freed   │                     │                      │
                  │• Waitlist│                     │                      │
                  │  promoted│                     │                      │
                  └──────────┘                     │                      │
                                                   │                      │
                                                   │                      │
          (When event at capacity)                  │                      │
                                                   │                      │
                              ┌───────────────┐    │                      │
             [register] ─────▶│  WAITLISTED   │────┼──────────────────────┘
                              │               │    │
                              │ • Position #  │    │
                              │ • Auto-promote│    │
                              │   when spot   │    │
                              │   opens       │    │
                              └───────┬───────┘    │
                                      │            │
                                      │ [cancel]   │
                                      ▼            │
                              ┌───────────────┐    │
                              │ CANCELLED     │    │
                              │ (from wait)   │    │
                              └───────────────┘    │


  TRANSITIONS:
  ──────────────────────────────────────────────────────────
  From        │ To          │ Trigger             │ Side Effect
  ────────────┼─────────────┼─────────────────────┼──────────────────
  (new)       │ REGISTERED  │ RSVP + capacity OK  │ Confirmation email
  (new)       │ WAITLISTED  │ RSVP + at capacity  │ Waitlist position email
  REGISTERED  │ CANCELLED   │ User/admin cancels  │ Promote waitlist #1
  WAITLISTED  │ REGISTERED  │ Spot opens          │ Promotion notification
  WAITLISTED  │ CANCELLED   │ User/admin cancels  │ Reorder queue
  REGISTERED  │ ATTENDED    │ Check-in at event   │ Attendance logged
  REGISTERED  │ NO_SHOW     │ Event ends, no check│ Analytics recorded
  ──────────────────────────────────────────────────────────
```

---

### 2.3 Volunteer Assignment States

```
                    ┌───────────────────────────────────────────────┐
                    │     VOLUNTEER ASSIGNMENT STATE MACHINE         │
                    └───────────────────────────────────────────────┘

                              ┌───────────────┐
                              │   ASSIGNED    │
                              │               │
                              │ • Admin/auto  │
                              │   created     │
                              │ • Notification│
                              │   sent        │
                              └───────┬───────┘
                                      │
                     ┌────────────────┼────────────────┐
                     │                │                │
                     │ [confirm]      │ [decline]      │ [request_swap]
                     ▼                ▼                ▼
              ┌──────────┐    ┌──────────────┐   ┌──────────────┐
              │CONFIRMED │    │  DECLINED    │   │ SWAP_PENDING │
              │          │    │              │   │              │
              │• Locked  │    │• Gap created │   │• Target      │
              │• Reminder│    │• Notify admin│   │  notified    │
              │  24h     │    │• Post opening│   │• Original    │
              │  before  │    │              │   │  still active│
              └─────┬────┘    └──────────────┘   └──────┬───────┘
                    │                                     │
                    │                          ┌──────────┼──────────┐
                    │                          │                     │
                    │                          │ [swap_accepted]     │ [swap_rejected]
                    │                          ▼                     ▼
                    │                   ┌──────────────┐      ┌──────────────┐
                    │                   │   SWAPPED    │      │  CONFIRMED   │
                    │                   │              │      │  (remains    │
                    │                   │• Old: released│     │   assigned)  │
                    │                   │• New: assigned│      └──────────────┘
                    │                   └──────────────┘
                    │
                    │ [event starts]
                    ▼
              ┌──────────────┐
              │   SERVED     │
              │              │
              │ • Completed  │
              │ • Stats      │
              │   updated    │
              │ • Streak     │
              │   tracked    │
              └──────────────┘


  FULL TRANSITION TABLE:
  ──────────────────────────────────────────────────────────────────────────
  From          │ To            │ Trigger           │ Actor       │ Notify
  ──────────────┼───────────────┼───────────────────┼─────────────┼─────────
  (new)         │ ASSIGNED      │ Manual/auto/signup│ Admin/Self  │ Volunteer
  ASSIGNED      │ CONFIRMED     │ Volunteer accepts │ Volunteer   │ Admin
  ASSIGNED      │ DECLINED      │ Volunteer rejects │ Volunteer   │ Admin
  ASSIGNED      │ SWAP_PENDING  │ Swap requested    │ Volunteer   │ Target
  SWAP_PENDING  │ SWAPPED       │ Target accepts    │ Target Vol  │ Both+Admin
  SWAP_PENDING  │ CONFIRMED     │ Target rejects    │ Target Vol  │ Requester
  SWAP_PENDING  │ EXPIRED       │ 48h no response   │ System      │ Both+Admin
  CONFIRMED     │ SERVED        │ Event completes   │ System      │ —
  CONFIRMED     │ DECLINED      │ Late cancel       │ Volunteer   │ Admin
  ASSIGNED      │ RELEASED      │ Event cancelled   │ System      │ Volunteer
  ──────────────────────────────────────────────────────────────────────────
```

---

### 2.4 Member Account States

```
                    ┌───────────────────────────────────────────────┐
                    │          MEMBER ACCOUNT STATE MACHINE          │
                    └───────────────────────────────────────────────┘

       ┌────────────────┐         ┌────────────────┐
       │  REGISTRATION  │────────▶│    PENDING     │
       │  (form submit) │         │   APPROVAL     │
       └────────────────┘         └───────┬────────┘
                                          │
                             ┌────────────┼────────────┐
                             │ [approve]  │            │ [reject]
                             ▼            │            ▼
                      ┌──────────┐        │     ┌──────────┐
                      │  ACTIVE  │        │     │ REJECTED │
                      │          │        │     │          │
                      │• Full    │        │     │• Notified│
                      │  access  │        │     │• Can     │
                      │• Role    │        │     │  reapply │
                      │  assigned│        │     └──────────┘
                      └─────┬────┘        │
                            │             │
               ┌────────────┼─────────────┼──────────┐
               │            │             │          │
               │[deactivate]│[role_change] │          │[suspend]
               ▼            ▼             │          ▼
        ┌──────────┐ ┌──────────────┐     │   ┌──────────┐
        │ INACTIVE │ │ ACTIVE       │     │   │SUSPENDED │
        │          │ │ (new role)   │     │   │          │
        │• No login│ │              │     │   │• Temp    │
        │• Data    │ │• Permissions │     │   │  no login│
        │  retained│ │  updated     │     │   │• Review  │
        │• Can     │ │              │     │   │  period  │
        │  reactivt│ │              │     │   └─────┬────┘
        └──────────┘ └──────────────┘     │         │
                                          │         │ [reinstate]
                                          │         ▼
                                          │   ┌──────────┐
                                          │   │  ACTIVE  │
                                          │   └──────────┘
                                          │
                                          │ [auto_approve
                                          │  org setting]
                                          │
                                          └─────▶ ACTIVE (skip pending)


  ROLES (assignable in ACTIVE state):
  ──────────────────────────────────────────
  guest → member → volunteer → leader → admin → pastor
  (Each higher role inherits lower role permissions)
```

---

### 2.5 Notification Delivery States

```
                    ┌───────────────────────────────────────────────┐
                    │      NOTIFICATION DELIVERY STATE MACHINE       │
                    └───────────────────────────────────────────────┘

              ┌───────────────┐
              │   CREATED     │
              │               │
              │ • Payload set │
              │ • Audience    │
              │   determined  │
              └───────┬───────┘
                      │
           ┌──────────┼──────────┐
           │ [immediate]         │ [scheduled]
           ▼                     ▼
    ┌──────────────┐     ┌──────────────┐
    │   QUEUED     │     │  SCHEDULED   │
    │              │     │              │
    │ • In send    │     │ • Timer set  │
    │   pipeline   │     │ • Editable   │
    └──────┬───────┘     └──────┬───────┘
           │                    │
           │                    │ [send_time reached]
           │                    ▼
           │             ┌──────────────┐
           │             │   QUEUED     │
           │             └──────┬───────┘
           │                    │
           └────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │  DELIVERING   │
              │               │
              │ • Per-channel │
              │   processing: │
              │   - Push      │
              │   - Email     │
              │   - In-app    │
              └───────┬───────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
         ▼            ▼            ▼
  ┌──────────┐ ┌──────────┐ ┌──────────────┐
  │DELIVERED │ │ PARTIAL  │ │   FAILED     │
  │          │ │          │ │              │
  │• All     │ │• Some    │ │• All channels│
  │  channels│ │  channels│ │  failed      │
  │  success │ │  failed  │ │• Retry queue │
  └─────┬────┘ └──────────┘ └──────┬───────┘
        │                          │
        │                          │ [retry (3x max)]
        │                          ▼
        │                   ┌──────────────┐
        │                   │ PERMANENTLY  │
        │                   │ FAILED       │
        │                   │              │
        │                   │ • Logged     │
        │                   │ • Admin alert│
        │                   └──────────────┘
        │
        ▼
  ┌──────────────────────────────┐
  │  USER INTERACTION STATES     │
  │                              │
  │  UNREAD ──[open]──▶ READ    │
  │    │                  │      │
  │    │ [dismiss]        │      │
  │    ▼                  ▼      │
  │  DISMISSED          ACTIONED │
  │                     (tapped  │
  │                      CTA)    │
  └──────────────────────────────┘
```

---

### 2.6 Liturgical Season States (Annual Cycle)

```
                    ┌───────────────────────────────────────────────┐
                    │    LITURGICAL YEAR STATE MACHINE               │
                    │    (Western/Catholic tradition example)        │
                    └───────────────────────────────────────────────┘

    ┌────────────────────────────────────────────────────────────────────┐
    │                                                                    │
    │  ┌──────┐    ┌──────────┐    ┌──────────┐    ┌──────┐            │
    │  │ADVENT│───▶│CHRISTMAS │───▶│ ORDINARY │───▶│ LENT │            │
    │  │      │    │  TIDE    │    │ TIME (1) │    │      │            │
    │  │Purple│    │White/Gold│    │  Green   │    │Purple│            │
    │  │4 wks │    │ 12 days  │    │ ~4-9 wks │    │40 day│            │
    │  └──────┘    └──────────┘    └──────────┘    └──┬───┘            │
    │                                                  │                │
    │                                                  ▼                │
    │  ┌──────────┐    ┌──────────┐    ┌──────────────────┐            │
    │  │ ORDINARY │◀───│PENTECOST │◀───│   EASTER TIDE    │◀───────────┤
    │  │ TIME (2) │    │          │    │                  │   HOLY     │
    │  │  Green   │    │  Red     │    │  White/Gold      │   WEEK     │
    │  │ ~25-29wk │    │  1 day   │    │  50 days         │   Red      │
    │  └────┬─────┘    └──────────┘    └──────────────────┘            │
    │       │                                                          │
    │       │ [First Sunday of Advent]                                  │
    │       └──────────────────────────────────────────────────────────┘
    │                         (cycle repeats)
    └────────────────────────────────────────────────────────────────────┘

    STATE PROPERTIES:
    ─────────────────────────────────────────────────────────────────
    Each season state carries:
    • name: Display name
    • color_hex: Liturgical color for theming
    • start_date: Computed per year (some moveable)
    • end_date: Computed per year
    • week_number: Current week within season
    • readings_cycle: A, B, or C (3-year rotation)
    • special_days: Array of holy days within season
    ─────────────────────────────────────────────────────────────────

    TRANSITIONS are date-driven (computed annually):
    • Advent: 4th Sunday before Christmas
    • Christmas: December 25
    • Ordinary Time 1: Day after Epiphany (Jan 6)
    • Lent: Ash Wednesday (46 days before Easter)
    • Holy Week: Palm Sunday
    • Easter: First Sunday after Paschal Full Moon
    • Pentecost: 50 days after Easter
    • Ordinary Time 2: Day after Pentecost

    SYSTEM BEHAVIOR ON TRANSITION:
    1. Update app theme colors (gradient morph)
    2. Update dashboard liturgical banner
    3. Load new season's default scripture cycle
    4. Update widget displays
    5. Fire webhook: season.changed
```

---

### 2.7 Auto-Scheduler States

```
                    ┌───────────────────────────────────────────────┐
                    │     AUTO-SCHEDULER WORKFLOW STATES             │
                    └───────────────────────────────────────────────┘

              ┌───────────────┐
              │  CONFIGURED   │
              │               │
              │ • Date range  │
              │ • Roles       │
              │ • Strategy    │
              │ • Constraints │
              └───────┬───────┘
                      │
                      │ [run]
                      ▼
              ┌───────────────┐
              │  PROCESSING   │
              │               │
              │ • Evaluating  │
              │   availability│
              │ • Checking    │
              │   history     │
              │ • Balancing   │
              │   fairness    │
              │ • Avoiding    │
              │   conflicts   │
              └───────┬───────┘
                      │
           ┌──────────┼──────────────┐
           │          │              │
           ▼          ▼              ▼
    ┌──────────┐ ┌──────────┐ ┌──────────────┐
    │  DRAFT   │ │ PARTIAL  │ │   FAILED     │
    │ COMPLETE │ │ (gaps    │ │              │
    │          │ │  remain) │ │ • Not enough │
    │ All slots│ │          │ │   volunteers │
    │ filled   │ │ Some gaps│ │ • Constraint │
    │          │ │ flagged  │ │   conflict   │
    └─────┬────┘ └─────┬────┘ └──────────────┘
          │            │
          └──────┬─────┘
                 │
                 ▼
         ┌──────────────┐
         │ ADMIN REVIEW │
         │              │
         │ • View grid  │
         │ • Swap people│
         │ • Fill gaps  │
         │ • Add notes  │
         └───────┬──────┘
                 │
        ┌────────┼────────┐
        │        │        │
        ▼        ▼        ▼
 ┌─────────┐┌────────┐┌─────────┐
 │ APPROVE ││ MODIFY ││ REJECT  │
 │ & SEND  ││& RESEND││ & RERUN │
 └────┬────┘└────┬───┘└────┬────┘
      │          │          │
      └──────────┘          │
           │                │
           ▼                └──────▶ (back to CONFIGURED)
    ┌──────────────┐
    │  PUBLISHED   │
    │              │
    │ • Assignments│
    │   created    │
    │ • Volunteers │
    │   notified   │
    │ • Gaps posted│
    │   to board   │
    └──────────────┘
```

---

## 3. Error & Edge Case Flows

### 3.1 Conflict Resolution Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CONFLICT SCENARIOS                                │
├──────────────────────┬──────────────────────┬───────────────────────┤
│ Scenario             │ Detection Point      │ Resolution            │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Double-booked room   │ Event creation       │ Show alternatives,    │
│                      │ (Step 2)             │ suggest open rooms    │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Volunteer assigned   │ Assignment creation  │ Show existing shift,  │
│ to overlapping event │                      │ offer swap or decline │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Over-capacity RSVP   │ Registration submit  │ Auto-waitlist with    │
│                      │                      │ queue position        │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Past-date event      │ Event creation       │ Block creation,       │
│ creation             │ (Step 2)             │ "Date is in the past" │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Concurrent edit      │ Save action          │ Optimistic lock:      │
│ (two admins editing  │                      │ "Updated since you    │
│  same event)         │                      │  opened. Merge?"      │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Offline action       │ Sync on reconnect    │ Queue locally, apply  │
│ conflicts with       │                      │ on sync, show "could  │
│ server state         │                      │ not apply" if stale   │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ Expired swap request │ 48h timeout          │ Auto-expire, notify   │
│                      │                      │ both parties, revert  │
├──────────────────────┼──────────────────────┼───────────────────────┤
│ All volunteers       │ Gap detection        │ Escalate: push to all │
│ decline              │ (post-decline)       │ eligible, email admin │
└──────────────────────┴──────────────────────┴───────────────────────┘
```

---

### 3.2 Offline Sync State Diagram

```
                    ┌───────────────────────────────────────────────┐
                    │        OFFLINE SYNC STATE MACHINE              │
                    └───────────────────────────────────────────────┘

              ┌───────────────┐
              │    ONLINE     │◀──────────────────────────────────┐
              │               │                                    │
              │ • Real-time   │                                    │
              │ • All actions │                                    │
              │   immediate   │                                    │
              └───────┬───────┘                                    │
                      │                                            │
                      │ [connectivity lost]                         │
                      ▼                                            │
              ┌───────────────┐                                    │
              │   OFFLINE     │                                    │
              │               │                                    │
              │ • Banner shown│                                    │
              │ • Read: cached│                                    │
              │ • Write: queue│                                    │
              └───────┬───────┘                                    │
                      │                                            │
                      │ [user performs action]                      │
                      ▼                                            │
              ┌───────────────┐                                    │
              │ ACTION QUEUED │                                    │
              │               │                                    │
              │ • Stored in   │                                    │
              │   local DB    │                                    │
              │ • Timestamped │                                    │
              │ • Retry count │                                    │
              │   = 0         │                                    │
              └───────┬───────┘                                    │
                      │                                            │
                      │ [connectivity restored]                     │
                      ▼                                            │
              ┌───────────────┐                                    │
              │   SYNCING     │                                    │
              │               │                                    │
              │ • Process     │                                    │
              │   queue FIFO  │                                    │
              │ • Conflict    │                                    │
              │   detection   │                                    │
              └───────┬───────┘                                    │
                      │                                            │
           ┌──────────┼──────────┐                                 │
           │          │          │                                 │
           ▼          ▼          ▼                                 │
    ┌──────────┐┌──────────┐┌──────────────┐                      │
    │ SUCCESS  ││ CONFLICT ││   FAILED     │                      │
    │          ││          ││              │                      │
    │• Applied ││• Show to ││• Retry (3x)  │                      │
    │• Queue   ││  user    ││• Then notify │                      │
    │  cleared ││• Offer   ││  user: "could│                      │
    │          ││  merge/  ││  not save"   │                      │
    │          ││  overwrite│              │                      │
    └────┬─────┘└──────────┘└──────────────┘                      │
         │                                                         │
         └─────────────────────────────────────────────────────────┘
```

---

## 4. Complete Screen Flow Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FULL APP NAVIGATION MAP                                │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │   SPLASH    │
                              └──────┬──────┘
                                     │
                        ┌────────────┼────────────┐
                        │ [logged in]│            │ [no session]
                        ▼            │            ▼
                 ┌──────────┐        │     ┌──────────────┐
                 │DASHBOARD │        │     │    LOGIN     │
                 └──────────┘        │     └──────┬───────┘
                                     │            │
                                     │     ┌──────┼───────────┐
                                     │     │      │           │
                                     │     ▼      ▼           ▼
                                     │  Register  Forgot    Social
                                     │            Password   Login
                                     │
┌────────────────────────────────────┼────────────────────────────────────────┐
│                                    │                                        │
│  TAB: HOME ─────────────────────── │ ─────────────── TAB: CALENDAR         │
│  ┌──────────────────────┐          │          ┌──────────────────────┐     │
│  │ Liturgical Banner    │          │          │ Month/Week/Day/List  │     │
│  │ Scripture Card ──────┼──── (tap reading) ──┼─▶ Event Detail       │     │
│  │ Upcoming Events ─────┼──── (tap event) ────┼─▶ Event Detail       │     │
│  │ My Serving ──────────┼──── (tap) ──────────┼─▶ Serve: My Schedule │     │
│  │ Prayer Focus         │          │          │ Filter Panel         │     │
│  │ Alerts ──────────────┼──── (tap alert) ────┼─▶ Notifications      │     │
│  └──────────────────────┘          │          └──────────────────────┘     │
│                                    │                                        │
│  TAB: QUICK ADD (+) ───────────────│──────── TAB: SERVE                    │
│  ┌──────────────────────┐          │          ┌──────────────────────┐     │
│  │ Bottom Sheet:        │          │          │ Segment: My Schedule │     │
│  │ • Create Event ──────┼──────────┼─────────▶│ • Assignment Cards   │     │
│  │ • RSVP ──────────────┼──── (→ event list) ─┼ • Confirm/Decline    │     │
│  │ • Prayer Request     │          │          │                      │     │
│  │ • Sign Up to Serve ──┼──────────┼─────────▶│ Segment: Openings    │     │
│  └──────────────────────┘          │          │ • Gap Cards          │     │
│                                    │          │ • Sign-Up Action     │     │
│  TAB: MORE ────────────────────────│          │                      │     │
│  ┌──────────────────────┐          │          │ Segment: Swaps       │     │
│  │ My Groups ───────────┼──── (tap) ──────────┼▶ Group Detail        │     │
│  │ Directory ───────────┼──── (tap) ──────────┼▶ Member Profile      │     │
│  │ Notifications ───────┼──── (tap) ──────────┼▶ Notification Detail │     │
│  │ Settings             │          │          │                      │     │
│  │ • Profile            │          │          └──────────────────────┘     │
│  │ • Notification Prefs │          │                                        │
│  │ • Campus Selection   │          │                                        │
│  │ • Calendar Sync      │          │                                        │
│  │ • Privacy            │          │                                        │
│  │ • Appearance         │          │                                        │
│  └──────────────────────┘          │                                        │
│                                    │                                        │
└────────────────────────────────────┴────────────────────────────────────────┘


SHARED OVERLAYS & MODALS:
──────────────────────────────────────────────
• Event Detail (full screen, from any event tap)
• Event Creation Wizard (4-step modal)
• RSVP Confirmation Sheet
• Swap Request Sheet
• Filter Panel (bottom sheet)
• Search (overlay with results)
• Share Sheet (native iOS/Android)
```

---

## 5. Session & Authentication Flow

```
┌────────────────────────────────────────────────────────────────────────────┐
│                    SESSION & TOKEN LIFECYCLE                                │
└────────────────────────────────────────────────────────────────────────────┘

  APP LAUNCH
      │
      ▼
┌──────────────┐     ┌──────────────┐
│ Check stored │────▶│ Valid refresh │──── YES ──▶ Silent refresh ──▶ DASHBOARD
│ refresh token│     │ token?       │                                    │
└──────────────┘     └──────┬───────┘                                    │
                            │ NO                                          │
                            ▼                                            │
                     ┌──────────────┐                                    │
                     │ LOGIN SCREEN │                                    │
                     └──────┬───────┘                                    │
                            │                                            │
                            ▼                                            │
                     ┌──────────────┐                                    │
                     │  BIOMETRIC?  │── YES ──▶ Face/Touch ID ──────────┘
                     └──────┬───────┘                    │
                            │ NO                         │ FAIL
                            ▼                            ▼
                     ┌──────────────┐            ┌──────────────┐
                     │  Email +     │            │ Fallback to  │
                     │  Password    │            │ Email + Pass │
                     └──────┬───────┘            └──────────────┘
                            │
                            ▼
                     ┌──────────────────────────────────┐
                     │  TOKEN PAIR RECEIVED:             │
                     │  • Access token (15 min TTL)     │
                     │  • Refresh token (7 day TTL)     │
                     │  • Stored in Secure Enclave/     │
                     │    Keystore                      │
                     └──────────────────────────────────┘

  DURING SESSION:
  ─────────────────────────────────────────────────────────
  API Call ──▶ Access token valid? ── YES ──▶ Proceed
                       │
                       │ NO (401)
                       ▼
              Refresh token ──▶ New access token ──▶ Retry original call
                       │
                       │ FAIL (refresh expired)
                       ▼
              Force logout ──▶ LOGIN SCREEN
                       │
                       └──▶ "Session expired. Please sign in again."
```
