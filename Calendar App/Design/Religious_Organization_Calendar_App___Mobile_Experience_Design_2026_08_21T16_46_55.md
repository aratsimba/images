
# Mobile Experience Design — Religious Organization Calendar App
## React Native · iOS & Android

---

## 1. Design Philosophy

| Principle | Rationale |
|-----------|-----------|
| **Thumb-zone first** | Primary actions within natural thumb reach (bottom 60% of screen) |
| **Liturgical immersion** | Season colors and imagery subtly theme the entire app |
| **Glanceable** | Key info visible without scrolling or tapping |
| **Offline-capable** | Cached schedule viewable without connectivity (syncs when online) |
| **Inclusive** | Dynamic type, VoiceOver/TalkBack, high-contrast mode, RTL support |
| **Notification-led** | Push notifications drive engagement with deep-links to relevant screens |

---

## 2. Information Architecture & Navigation

```
┌─────────────────────────────────────────────┐
│            BOTTOM TAB BAR (5 tabs)          │
├──────┬──────┬──────┬──────┬──────┬─────────┤
│ Home │ Cal  │  +   │ Vol  │ More │         │
│  🏠  │  📅  │  ➕  │  🤝  │  ≡   │         │
└──────┴──────┴──────┴──────┴──────┘         │
                                              │
Tab Structure:                                │
                                              │
🏠 HOME (Dashboard)                           │
   ├── Liturgical Banner                      │
   ├── Today's Scripture Card                 │
   ├── Upcoming Events (scrollable)           │
   ├── Prayer Focus Card                      │
   └── My Assignments (volunteer)             │
                                              │
📅 CALENDAR                                   │
   ├── Month View (swipeable)                 │
   ├── Week View                              │
   ├── Day View                               │
   ├── List View                              │
   └── Filters (campus, category)             │
                                              │
➕ QUICK ADD (center FAB)                     │
   ├── New Event                              │
   ├── New RSVP                               │
   └── New Prayer Request                     │
                                              │
🤝 SERVE (Volunteer Hub)                      │
   ├── My Schedule                            │
   ├── Available Openings                     │
   ├── Swap Requests                          │
   └── History                                │
                                              │
≡ MORE                                        │
   ├── My Groups                              │
   ├── Member Directory                       │
   ├── Notifications                          │
   ├── Giving (external link)                 │
   ├── Settings & Preferences                 │
   └── About / Help                           │
└─────────────────────────────────────────────┘
```

---

## 3. Screen Wireframes

### 3.1 Home / Dashboard (Default Landing)

```
┌──────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ ← Status bar
├──────────────────────────────────┤
│  Grace Community     [🔔 2] [👤] │ ← Header
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │  🟢 ORDINARY TIME · Week 21  │ │ ← Liturgical banner
│ │  ───────────────────────────  │ │   (tinted background)
│ │  📖 Matthew 16:13-20         │ │
│ │  "Who do you say that I am?" │ │
│ └──────────────────────────────┘ │
│                                  │
│  UPCOMING ─────────── See All >  │
│ ┌──────────────────────────────┐ │
│ │ 🟣 TODAY 7:00 PM             │ │ ← Event card
│ │ Women's Bible Study          │ │
│ │ Fellowship Hall · 🧒 · 12/20 │ │
│ │           [RSVP] │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 🔵 SUN 9:00 AM              │ │
│ │ Sunday Worship (Traditional) │ │
│ │ Sanctuary · 📺 · ♿          │ │
│ └──────────────────────────────┘ │
│ ┌──────────────────────────────┐ │
│ │ 🟠 SUN 5:00 PM              │ │
│ │ Youth Group Kickoff          │ │
│ │ Youth Center · RSVP Required │ │
│ └──────────────────────────────┘ │
│                                  │
│  MY SERVING ──────── Schedule >  │
│ ┌──────────────────────────────┐ │
│ │ ⚡ SUN 9 AM · Greeter        │ │ ← Assignment chip
│ │ ⚡ SUN 11 AM · Greeter       │ │
│ └──────────────────────────────┘ │
│                                  │
│  THIS WEEK'S PRAYER              │
│ ┌──────────────────────────────┐ │
│ │ 🙏 Pray for our mission     │ │
│ │    team in Guatemala         │ │
│ └──────────────────────────────┘ │
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │ ← Bottom nav
└──────────────────────────────────┘
```

---

### 3.2 Calendar — Month View

```
┌──────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────────────────┤
│  ◀  August 2026  ▶    [🔍] [⚙] │
├──────────────────────────────────┤
│  Campus: [Main ▾]  [All Cats ▾] │ ← Filter chips
├──────────────────────────────────┤
│  SU  MO  TU  WE  TH  FR  SA    │
│  ──  ──  ──  ──  ──  ──  ──    │
│                           1     │
│   2   3   4   5   6   7   8    │
│   🔵     🟢  🟣          🟠    │
│   9  10  11  12  13  14  15    │
│   🔵     🟢  🟣      🔴        │
│  16  17  18  19  20 ●21  22    │
│   🔵     🟢  🟣          🟡    │
│  23  24  25  26  27  28  29    │
│   🔵     🟢  🟣                 │
│  30  31                         │
│   🔵                            │
├──────────────────────────────────┤
│                                  │
│  AUGUST 21 (TODAY) ──────────    │ ← Day detail
│                                  │ (slides up on
│  ┌────────────────────────────┐  │  date tap or
│  │  No events today           │  │  swipe up)
│  │                            │  │
│  │  Tomorrow:                 │  │
│  │  🟣 7:00 PM Women's Study │  │
│  └────────────────────────────┘  │
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

**Interactions:**
- Swipe left/right → next/previous month
- Tap date → bottom sheet slides up with that day's events
- Pinch → toggle between month and week view
- Long-press date → quick-add event on that date

---

### 3.3 Calendar — Week View (Horizontal scroll)

```
┌──────────────────────────────────┐
│  ◀  Aug 17-23, 2026  ▶          │
├──────────────────────────────────┤
│  SU 17 │ MO 18 │ TU 19 │ WE 20 │ ← Swipeable
├─────────┼────────┼────────┼──────┤
│         │        │        │      │
│ 9:00 AM │        │        │      │
│ ┌─────┐ │        │        │      │
│ │🔵   │ │        │  7PM   │ 7PM  │
│ │Worsh│ │        │ ┌────┐ │┌───┐ │
│ │     │ │        │ │🟢  │ ││🟣 │ │
│ └─────┘ │        │ │Men │ ││Wom│ │
│         │        │ └────┘ │└───┘ │
│ 11:00AM │        │        │      │
│ ┌─────┐ │        │        │      │
│ │🔵   │ │        │        │      │
│ │Cont.│ │        │        │      │
│ └─────┘ │        │        │      │
│         │        │        │      │
│ 5:00 PM │        │        │      │
│ ┌─────┐ │        │        │      │
│ │🟠   │ │        │        │      │
│ │Youth│ │        │        │      │
│ └─────┘ │        │        │      │
│         │        │        │      │
├─────────┴────────┴────────┴──────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

### 3.4 Event Detail (Full Screen)

```
┌──────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────────────────┤
│  [← Back]              [⋮ Menu] │
├──────────────────────────────────┤
│                                  │
│  ┌──────────────────────────┐    │
│  │    🔵 WORSHIP SERVICE    │    │ ← Category badge
│  └──────────────────────────┘    │
│                                  │
│  Sunday Worship                  │
│  (Traditional)                   │
│                                  │
│  ─────────────────────────────   │
│                                  │
│  📅  Sunday, August 24, 2026    │
│  ⏰  9:00 AM – 10:15 AM         │
│  📍  Sanctuary · Main Campus    │
│  🔄  Repeats weekly             │
│                                  │
│  ─────────────────────────────   │
│                                  │
│  Traditional worship featuring   │
│  hymns, choir anthems, and a     │
│  message from Pastor Davis.      │
│                                  │
│  ─── AMENITIES ───────────────   │
│                                  │
│  📺 Livestream   ♿ Accessible   │
│  🧒 Childcare    🅿 Parking     │
│                                  │
│  ─── THIS WEEK'S READINGS ────   │
│                                  │
│  📖 First: Isaiah 51:1-6        │
│  📖 Psalm: Psalm 138            │
│  📖 Gospel: Matthew 16:13-20    │
│                                  │
│  ─── SERVING THIS SUNDAY ─────   │
│                                  │
│  👋 Greeter     J. Lee ✓        │
│  🎵 Worship     Choir ✓         │
│  🔊 Sound       M. Park ✓       │
│  👶 Nursery     ⚠️ OPEN         │
│       [Volunteer for Nursery →]  │
│                                  │
│  ─── CONTACT ─────────────────   │
│                                  │
│  👤 Pastor Kim · 📧 · 📱       │
│                                  │
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │ [📺 Watch Live] [📅 Add Cal] │ │ ← Sticky actions
│ └──────────────────────────────┘ │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

### 3.5 Serve / Volunteer Hub

```
┌──────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────────────────┤
│  MY SERVING                 [⚙] │
├──────────────────────────────────┤
│  [My Schedule] [Openings] [Swap] │ ← Segment control
├──────────────────────────────────┤
│                                  │
│  THIS WEEK ──────────────────    │
│                                  │
│  ┌──────────────────────────────┐│
│  │  SUN AUG 24 · 9:00 AM       ││
│  │  ──────────────────────────  ││
│  │  👋 Greeter · Traditional    ││
│  │  Sanctuary · Main Campus     ││
│  │                              ││
│  │  [✓ Confirm]  [✕ Decline]   ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  SUN AUG 24 · 11:00 AM      ││
│  │  ──────────────────────────  ││
│  │  👋 Greeter · Contemporary   ││
│  │  Sanctuary · Main Campus     ││
│  │                              ││
│  │  [✓ Confirmed ✓]            ││
│  └──────────────────────────────┘│
│                                  │
│  NEXT WEEK ──────────────────    │
│                                  │
│  ┌──────────────────────────────┐│
│  │  SUN AUG 31 · 9:00 AM       ││
│  │  ──────────────────────────  ││
│  │  👋 Greeter · Traditional    ││
│  │  [✓ Confirm]  [🔄 Swap]     ││
│  └──────────────────────────────┘│
│                                  │
│  ─── STATS ──────────────────    │
│  Served: 12 times this quarter   │
│  Streak: 4 weeks 🔥              │
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

### 3.6 Serve — Available Openings

```
┌──────────────────────────────────┐
│  MY SERVING                      │
├──────────────────────────────────┤
│  [My Schedule] [Openings] [Swap] │
├──────────────────────────────────┤
│                                  │
│  ⚠️ 3 ROLES NEED VOLUNTEERS     │
│                                  │
│  ┌──────────────────────────────┐│
│  │  👶 NURSERY                  ││
│  │  Sun Aug 24 · 9:00 AM       ││
│  │  Sunday Worship (Trad.)      ││
│  │  Main Campus                 ││
│  │                              ││
│  │  [Sign Me Up →]             ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  🚪 USHER                   ││
│  │  Sun Aug 24 · 11:00 AM      ││
│  │  Sunday Worship (Contemp.)   ││
│  │  Main Campus                 ││
│  │                              ││
│  │  [Sign Me Up →]             ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  🔊 SOUND TECH              ││
│  │  Wed Aug 27 · 7:00 PM       ││
│  │  Mid-Week Service            ││
│  │  North Campus                ││
│  │                              ││
│  │  [Sign Me Up →]             ││
│  └──────────────────────────────┘│
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

### 3.7 Quick Add (Bottom Sheet from FAB)

```
┌──────────────────────────────────┐
│                                  │
│  (Dimmed background)             │
│                                  │
│                                  │
│                                  │
├──────────────────────────────────┤
│  ┌──────────────────────────────┐│
│  │  ─── (drag handle) ───      ││
│  │                              ││
│  │  WHAT WOULD YOU LIKE TO DO?  ││
│  │                              ││
│  │  ┌────────────────────────┐  ││
│  │  │ 📅  Create Event       │  ││
│  │  │     Add a new event    │  ││
│  │  └────────────────────────┘  ││
│  │                              ││
│  │  ┌────────────────────────┐  ││
│  │  │ ✋  RSVP to Event      │  ││
│  │  │     Register for event │  ││
│  │  └────────────────────────┘  ││
│  │                              ││
│  │  ┌────────────────────────┐  ││
│  │  │ 🙏  Share Prayer       │  ││
│  │  │     Submit a request   │  ││
│  │  └────────────────────────┘  ││
│  │                              ││
│  │  ┌────────────────────────┐  ││
│  │  │ 🤝  Sign Up to Serve   │  ││
│  │  │     Pick an opening    │  ││
│  │  └────────────────────────┘  ││
│  │                              ││
│  └──────────────────────────────┘│
└──────────────────────────────────┘
```

---

### 3.8 Event Creation (Multi-step flow)

```
STEP 1/4 — BASICS                    STEP 2/4 — WHEN & WHERE
┌────────────────────────────┐       ┌────────────────────────────┐
│  [✕ Cancel]    [Next →]    │       │  [← Back]     [Next →]    │
├────────────────────────────┤       ├────────────────────────────┤
│                            │       │                            │
│  Event Title *             │       │  Start *                   │
│  ┌────────────────────┐    │       │  ┌────────────────────┐    │
│  │ Fall Festival       │    │       │  │ Sep 28  ·  4:00 PM │    │
│  └────────────────────┘    │       │  └────────────────────┘    │
│                            │       │                            │
│  Category *                │       │  End *                     │
│  ┌────────────────────┐    │       │  ┌────────────────────┐    │
│  │ 🟡 All-Church    ▾ │    │       │  │ Sep 28  ·  8:00 PM │    │
│  └────────────────────┘    │       │  └────────────────────┘    │
│                            │       │                            │
│  Event Type *              │       │  ☐ All Day   ☐ Recurring  │
│  ┌────────────────────┐    │       │                            │
│  │ Social            ▾ │    │       │  Campus *                  │
│  └────────────────────┘    │       │  ┌────────────────────┐    │
│                            │       │  │ Main Campus      ▾ │    │
│  Description               │       │  └────────────────────┘    │
│  ┌────────────────────┐    │       │                            │
│  │ Annual fall cele-   │    │       │  Room                      │
│  │ bration with food,  │    │       │  ┌────────────────────┐    │
│  │ games, and activ-   │    │       │  │ Fellowship Hall  ▾ │    │
│  │ ities for all ages. │    │       │  └────────────────────┘    │
│  └────────────────────┘    │       │                            │
│                            │       │  ℹ️ Capacity: 200          │
│  ● ○ ○ ○  (progress)      │       │  ● ● ○ ○  (progress)      │
└────────────────────────────┘       └────────────────────────────┘

STEP 3/4 — OPTIONS                   STEP 4/4 — REVIEW
┌────────────────────────────┐       ┌────────────────────────────┐
│  [← Back]     [Next →]    │       │  [← Back]    [Publish ✓]  │
├────────────────────────────┤       ├────────────────────────────┤
│                            │       │                            │
│  Requires RSVP?           │       │  ┌────────────────────────┐│
│  [ON 🟢──────]            │       │  │  🟡 ALL-CHURCH         ││
│                            │       │  │                        ││
│  Max Capacity              │       │  │  Fall Festival         ││
│  ┌────────────────────┐    │       │  │  & Potluck             ││
│  │ 200                │    │       │  │                        ││
│  └────────────────────┘    │       │  │  📅 Sep 28, 2026      ││
│                            │       │  │  ⏰ 4:00 - 8:00 PM    ││
│  Childcare?               │       │  │  📍 Fellowship Hall    ││
│  [ON 🟢──────]            │       │  │     Main Campus        ││
│                            │       │  │                        ││
│  Livestream?              │       │  │  🧒 Childcare ✓        ││
│  [── OFF ───]             │       │  │  ✋ RSVP Required ✓    ││
│                            │       │  │  👁 Public             ││
│  Visibility               │       │  │                        ││
│  ● Public                 │       │  │  📞 Pastor Kim         ││
│  ○ Members Only           │       │  └────────────────────────┘│
│  ○ Leaders Only           │       │                            │
│                            │       │  [Save Draft]  [Publish ✓]│
│  Contact Person            │       │                            │
│  ┌────────────────────┐    │       │  ● ● ● ●  (progress)      │
│  │ Pastor Kim       ▾ │    │       └────────────────────────────┘
│  └────────────────────┘    │
│                            │
│  ● ● ● ○  (progress)      │
└────────────────────────────┘
```

---

### 3.9 Notifications Center

```
┌──────────────────────────────────┐
│  [← Back]   NOTIFICATIONS       │
├──────────────────────────────────┤
│  [All] [Reminders] [Alerts] [Vol]│ ← Filter chips
├──────────────────────────────────┤
│                                  │
│  TODAY ──────────────────────    │
│                                  │
│  ┌──────────────────────────────┐│
│  │ 🔔 Reminder · 2h ago        ││ ← Unread (bold)
│  │ Women's Bible Study tonight  ││
│  │ at 7:00 PM · Fellowship Hall ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │ ⚠️ Volunteer · 5h ago       ││
│  │ Nursery volunteer needed for ││
│  │ Sunday 9 AM service          ││
│  │ [Sign Up →]                  ││
│  └──────────────────────────────┘│
│                                  │
│  YESTERDAY ──────────────────    │
│                                  │
│  ┌──────────────────────────────┐│
│  │ 📢 Update · 1d ago          ││ ← Read (dimmed)
│  │ Fall Festival planning       ││
│  │ meeting moved to Sept 3      ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │ ✓ Confirmed · 1d ago        ││
│  │ Your volunteer shift for     ││
│  │ Greeter (Sun 11AM) confirmed ││
│  └──────────────────────────────┘│
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

### 3.10 My Groups

```
┌──────────────────────────────────┐
│  [← Back]      MY GROUPS        │
├──────────────────────────────────┤
│                                  │
│  ┌──────────────────────────────┐│
│  │  📖 Women's Bible Study     ││
│  │  Thursdays · 7:00 PM        ││
│  │  Fellowship Hall · 14 members││
│  │  Leader: Sarah Johnson       ││
│  │                     [View →] ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  🎵 Worship Team            ││
│  │  Sundays · 8:00 AM (warmup) ││
│  │  Sanctuary · 8 members      ││
│  │  Leader: Mike Rivera         ││
│  │                     [View →] ││
│  └──────────────────────────────┘│
│                                  │
│  ┌──────────────────────────────┐│
│  │  🌎 Missions Committee      ││
│  │  1st Monday · 6:30 PM       ││
│  │  Room 204 · 6 members       ││
│  │  Leader: Pastor Davis        ││
│  │                     [View →] ││
│  └──────────────────────────────┘│
│                                  │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐│
│  │  Browse All Groups →         ││
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘│
│                                  │
├──────────────────────────────────┤
│  🏠    📅    [➕]    🤝    ≡    │
└──────────────────────────────────┘
```

---

## 4. Gesture & Interaction Patterns

| Gesture | Context | Action |
|---------|---------|--------|
| Swipe left/right | Calendar month | Navigate months |
| Swipe left on event card | Event list | Quick RSVP or dismiss |
| Swipe right on assignment | Volunteer list | Confirm shift |
| Pull down | Any list | Refresh data |
| Long press on date | Calendar | Quick-add event |
| Pinch in/out | Calendar | Toggle month ↔ week view |
| Tap + hold event | Calendar | Drag to reschedule (leaders+) |
| 3D Touch / Haptic | Event card | Peek at event detail |

---

## 5. Push Notification Strategy

| Notification Type | Timing | Deep Link |
|-------------------|--------|-----------|
| Event reminder | 1 hour before (configurable) | Event detail screen |
| Volunteer reminder | 24h before assigned shift | Serve → My Schedule |
| Volunteer gap alert | When opening posted | Serve → Openings |
| Event cancellation | Immediately | Event detail (shows cancelled) |
| RSVP confirmation | On registration | Event detail |
| Swap request | When someone requests swap | Serve → Swap Requests |
| New event (subscribed category) | On publish | Event detail |
| Weekly digest | Sunday 7 AM | Home dashboard |
| Scripture of the day | 6 AM daily (opt-in) | Home → Scripture card |

---

## 6. Offline Mode

| Feature | Offline Behavior |
|---------|-----------------|
| Calendar view | Shows cached events (synced within last 24h) |
| Event details | Cached details available |
| RSVP | Queued locally; syncs when online |
| Volunteer confirm/decline | Queued locally; syncs when online |
| Event creation | Saved as draft; publishes when online |
| Scripture readings | Cached for current week |
| Push notifications | Received when back online |
| Visual indicator | Subtle banner: "Offline · Changes will sync" |

---

## 7. Accessibility Features

| Feature | Implementation |
|---------|---------------|
| Dynamic Type | All text respects iOS/Android font scaling |
| VoiceOver / TalkBack | Full semantic labels on all interactive elements |
| Color contrast | WCAG 2.1 AA minimum (4.5:1 text, 3:1 UI) |
| Color-blind safe | Category dots include unique shapes as secondary indicator |
| Reduce Motion | Respects system setting; disables parallax/animations |
| High Contrast Mode | Bolder borders, no translucency |
| RTL Support | Full mirror layout for Arabic, Hebrew |
| Haptic feedback | Confirmation taps on actions (iOS Taptic Engine) |
| Focus management | Logical tab order in forms |

---

## 8. Theming — Liturgical Seasons

| Season | Primary Color | Accent | Background Tint |
|--------|--------------|--------|-----------------|
| Advent | Deep Purple | Gold | #F3E8FF |
| Christmas | White/Gold | Red | #FFFBEB |
| Epiphany | Green | Gold | #F0FFF4 |
| Lent | Purple | Grey | #FAF5FF |
| Holy Week | Red/Black | Gold | #FFF5F5 |
| Easter | White/Gold | Green | #FFFFF0 |
| Pentecost | Red | Orange | #FFF5F5 |
| Ordinary Time | Green | Brown | #F0FFF4 |

The app subtly adapts its header gradient, liturgical banner, and accent colors to reflect the current season — creating a sense of rhythm and sacred time.

---

## 9. Widget Support

### iOS Widgets (WidgetKit)

| Size | Content |
|------|---------|
| Small (2×2) | Today's scripture reference + liturgical color |
| Medium (4×2) | Next 2 upcoming events with time & location |
| Large (4×4) | Week-at-a-glance mini calendar + today's events |
| Lock Screen | Next event countdown + scripture verse |

### Android Widgets (Glance)

| Size | Content |
|------|---------|
| 2×1 | Next event with countdown |
| 3×2 | Today's events list (scrollable) |
| 4×3 | Week calendar with event indicators |
| 4×1 | Scripture of the day banner |

---

## 10. Key Animations & Transitions

| Transition | Type | Duration |
|-----------|------|----------|
| Tab switch | Cross-fade | 200ms |
| Event card → Detail | Shared element (card expands) | 350ms |
| Bottom sheet (Quick Add) | Spring slide-up | 300ms |
| Calendar month change | Horizontal slide | 250ms |
| Confirm/decline | Checkmark/X lottie animation | 400ms |
| Pull-to-refresh | Custom spinner (cross rotation) | Continuous |
| Liturgical season change | Gradient morph over 2 days | 1000ms |

---

## 11. Platform-Specific Considerations

| Aspect | iOS | Android |
|--------|-----|---------|
| Navigation | Bottom tabs + swipe back | Bottom nav + system back |
| Notifications | APNs + Notification Extensions | FCM + Notification Channels |
| Widgets | WidgetKit (SwiftUI) | Glance (Jetpack Compose) |
| Biometrics | Face ID / Touch ID | Fingerprint / Face Unlock |
| Calendar sync | EventKit integration | CalendarProvider |
| Sharing | UIActivityViewController | Share Intent |
| Deep links | Universal Links | App Links |
| Offline storage | Core Data / Realm | Room DB |
