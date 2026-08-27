
# UI Wireframe — Religious Organization Calendar App

## Screen 1: Dashboard / Home

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Logo]  Grace Community Church           [🔔 3]  [👤 Pastor Davis ▾]      │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │                                                                  │
│  NAV     │  ┌─── LITURGICAL SEASON BANNER ──────────────────────────────┐  │
│          │  │  🟢 Ordinary Time  •  Week 21  •  Aug 21, 2026            │  │
│ 🏠 Home  │  └──────────────────────────────────────────────────────────────┘  │
│ 📅 Calendar│                                                                │
│ 👥 Groups │  ┌─── TODAY'S SCRIPTURE ────────────────────────────────────┐  │
│ 🙏 Devotional│ │  📖 Matthew 16:13-20  •  "Who do you say that I am?"    │  │
│ 🤝 Volunteer│ └──────────────────────────────────────────────────────────┘  │
│ 📋 Admin  │                                                                │
│           │  ┌─── UPCOMING EVENTS (Next 7 Days) ────────────────────────┐  │
│ ───────── │  │                                                            │  │
│ CAMPUSES  │  │  TODAY - Aug 21                                            │  │
│ ○ Main    │  │  ┌──────────────────────────────────────────────────────┐  │  │
│ ○ North   │  │  │ 🟣 7:00 PM  Women's Bible Study                     │  │  │
│ ○ Online  │  │  │     Fellowship Hall  •  🧒 Childcare  •  12/20 RSVP │  │  │
│           │  │  └──────────────────────────────────────────────────────┘  │  │
│ ───────── │  │                                                            │  │
│ CATEGORIES│  │  SUN - Aug 24                                              │  │
│ ☑ Worship │  │  ┌──────────────────────────────────────────────────────┐  │  │
│ ☑ Youth   │  │  │ 🔵 9:00 AM  Sunday Worship (Traditional)            │  │  │
│ ☑ Outreach│  │  │     Sanctuary  •  📺 Livestream  •  ♿ Accessible   │  │  │
│ ☑ Admin   │  │  ├──────────────────────────────────────────────────────┤  │  │
│ ☑ Social  │  │  │ 🔵 11:00 AM  Sunday Worship (Contemporary)          │  │  │
│           │  │  │     Sanctuary  •  📺 Livestream  •  🧒 Childcare    │  │  │
│           │  │  ├──────────────────────────────────────────────────────┤  │  │
│           │  │  │ 🟠 5:00 PM  Youth Group Kickoff                      │  │  │
│           │  │  │     Youth Center  •  RSVP Required  •  [Register →] │  │  │
│           │  │  └──────────────────────────────────────────────────────┘  │  │
│           │  │                                                            │  │
│           │  └────────────────────────────────────────────────────────────┘  │
│           │                                                                  │
│           │  ┌─── PRAYER FOCUS THIS WEEK ───────────────────────────────┐  │
│           │  │  🙏 "Pray for our mission team in Guatemala"              │  │
│           │  └──────────────────────────────────────────────────────────┘  │
│           │                                                                  │
│           │  ┌─── ALERTS ───────────────────────────────────────────────┐  │
│           │  │  ⚠️  Volunteer needed: Nursery - Sunday 9 AM service     │  │
│           │  │  📢  Fall Festival planning meeting moved to Sept 3      │  │
│           │  └──────────────────────────────────────────────────────────┘  │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

---

## Screen 2: Calendar View (Month)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Logo]  Grace Community Church           [🔔 3]  [👤 Pastor Davis ▾]      │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │                                                                  │
│  NAV     │  ◀  August 2026  ▶       [Month] [Week] [Day] [List]  [+ Event]│
│          │                                                                  │
│          │  Filter: [All Campuses ▾] [All Categories ▾] [Search... 🔍]    │
│          │                                                                  │
│          │  ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐                  │
│          │  │ SUN │ MON │ TUE │ WED │ THU │ FRI │ SAT │                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │     │     │     │     │     │     │  1  │                  │
│          │  │     │     │     │     │     │     │     │                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │                  │
│          │  │🔵9AM│     │🟢7PM│🟣7PM│     │     │🟠9AM│                  │
│          │  │Worsh│     │Men's│Women│     │     │Youth│                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │  9  │ 10  │ 11  │ 12  │ 13  │ 14  │ 15  │                  │
│          │  │🔵9AM│     │🟢7PM│🟣7PM│     │🔴6PM│     │                  │
│          │  │Worsh│     │Men's│Women│     │Board│     │                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │ 16  │ 17  │ 18  │ 19  │ 20  │ ●21 │ 22  │                  │
│          │  │🔵9AM│     │🟢7PM│🟣7PM│     │     │🟡ALL│                  │
│          │  │Worsh│     │Men's│Women│     │     │Retr.│                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │ 23  │ 24  │ 25  │ 26  │ 27  │ 28  │ 29  │                  │
│          │  │🔵9AM│     │🟢7PM│🟣7PM│     │     │     │                  │
│          │  │Worsh│     │Men's│Women│     │     │     │                  │
│          │  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┤                  │
│          │  │ 30  │ 31  │     │     │     │     │     │                  │
│          │  │🔵9AM│     │     │     │     │     │     │                  │
│          │  │Worsh│     │     │     │     │     │     │                  │
│          │  └─────┴─────┴─────┴─────┴─────┴─────┴─────┘                  │
│          │                                                                  │
│          │  LEGEND: 🔵 Worship  🟢 Men's  🟣 Women's  🟠 Youth            │
│          │          🔴 Admin    🟡 All-Church  ⚫ Outreach                  │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

---

## Screen 3: Event Detail / Flyout Panel

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                          ┌────────────────┐ │
│  (Calendar view in background, dimmed)                   │  EVENT DETAIL  │ │
│                                                          │                │ │
│                                                          │ 🔵 WORSHIP     │ │
│                                                          │                │ │
│                                                          │ Sunday Worship │ │
│                                                          │ (Traditional)  │ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ 📅 Sun Aug 24  │ │
│                                                          │ ⏰ 9:00-10:15  │ │
│                                                          │ 📍 Sanctuary   │ │
│                                                          │    Main Campus │ │
│                                                          │ 🔄 Weekly      │ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ DETAILS        │ │
│                                                          │ Traditional    │ │
│                                                          │ worship with   │ │
│                                                          │ hymns, choir,  │ │
│                                                          │ and sermon.    │ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ AMENITIES      │ │
│                                                          │ 📺 Livestream  │ │
│                                                          │ ♿ Accessible  │ │
│                                                          │ 🧒 Childcare  │ │
│                                                          │ 🅿 Parking     │ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ SCRIPTURE      │ │
│                                                          │ 📖 Matt 16:13  │ │
│                                                          │ 📖 Psalm 138   │ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ VOLUNTEERS     │ │
│                                                          │ Greeter: J.Lee │ │
│                                                          │ Sound: M.Park  │ │
│                                                          │ Nursery: OPEN⚠│ │
│                                                          │                │ │
│                                                          │ ─────────────  │ │
│                                                          │ CONTACT        │ │
│                                                          │ 👤 Pastor Kim  │ │
│                                                          │ 📧 kim@grace.. │ │
│                                                          │                │ │
│                                                          │ [Watch Live]   │ │
│                                                          │ [Add to Cal]   │ │
│                                                          │ [✏️ Edit]       │ │
│                                                          └────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Screen 4: Volunteer Schedule View

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [Logo]  Grace Community Church           [🔔 3]  [👤 Pastor Davis ▾]      │
├──────────┬──────────────────────────────────────────────────────────────────┤
│          │                                                                  │
│  NAV     │  VOLUNTEER SCHEDULE          Week of Aug 24, 2026    [+ Assign] │
│          │                                                                  │
│          │  ┌──────────┬──────────────┬──────────────┬──────────────────┐  │
│          │  │ ROLE     │ SUN 9:00 AM  │ SUN 11:00 AM │ WED 7:00 PM     │  │
│          │  ├──────────┼──────────────┼──────────────┼──────────────────┤  │
│          │  │ Greeter  │ J. Lee ✓     │ S. Kim ✓     │ T. Park ✓       │  │
│          │  │          │ R. Adams ✓   │ M. Chen ?    │                  │  │
│          │  ├──────────┼──────────────┼──────────────┼──────────────────┤  │
│          │  │ Usher    │ B. Wilson ✓  │ D. Brown ✓   │ —               │  │
│          │  │          │ K. Davis ✓   │ ⚠️ OPEN      │                  │  │
│          │  ├──────────┼──────────────┼──────────────┼──────────────────┤  │
│          │  │ Sound    │ M. Park ✓    │ J. Rivera ✓  │ M. Park ✓       │  │
│          │  ├──────────┼──────────────┼──────────────┼──────────────────┤  │
│          │  │ Nursery  │ ⚠️ OPEN      │ L. Thomas ✓  │ —               │  │
│          │  │          │ A. Garcia ✓  │ H. Scott ✓   │                  │  │
│          │  ├──────────┼──────────────┼──────────────┼──────────────────┤  │
│          │  │ Worship  │ Choir ✓      │ Band ✓       │ —               │  │
│          │  │ Music    │              │              │                  │  │
│          │  └──────────┴──────────────┴──────────────┴──────────────────┘  │
│          │                                                                  │
│          │  ✓ = Confirmed   ? = Pending   ⚠️ = Needs Volunteer             │
│          │                                                                  │
│          │  [📧 Send Reminders]  [🔄 Auto-Schedule]  [📋 Export]          │
└──────────┴──────────────────────────────────────────────────────────────────┘
```

---

## Screen 5: Create/Edit Event Modal

```
┌───────────────────────────────────────────────────────────┐
│  CREATE NEW EVENT                                    [✕]  │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  Event Title *                                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Fall Festival & Potluck                             │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  Category *              Event Type *                     │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │ 🟡 All-Church ▾ │    │ Social        ▾ │              │
│  └─────────────────┘    └─────────────────┘              │
│                                                           │
│  Start Date/Time *           End Date/Time *             │
│  ┌─────────────────────┐    ┌─────────────────────┐     │
│  │ Sep 28, 2026  4:00PM│    │ Sep 28, 2026  8:00PM│     │
│  └─────────────────────┘    └─────────────────────┘     │
│                                                           │
│  ☐ All Day Event    ☐ Recurring  [Set Recurrence...]     │
│                                                           │
│  Campus *                    Room                         │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │ Main Campus   ▾ │    │ Fellowship Hall▾│              │
│  └─────────────────┘    └─────────────────┘              │
│                                                           │
│  Description                                              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ Annual fall celebration with food, games, and       │  │
│  │ activities for all ages. Bring a dish to share!     │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                           │
│  ─── OPTIONS ───────────────────────────────────────────  │
│                                                           │
│  ☑ Requires RSVP        Max Capacity: [200]              │
│  ☑ Childcare Available  Registration URL: [______]       │
│  ☐ Livestream           Livestream URL:   [______]       │
│                                                           │
│  Visibility:  ● Public  ○ Members Only  ○ Leaders Only   │
│                                                           │
│  Contact Person:  [Pastor Kim          ▾]                │
│                                                           │
│  ─── ATTACHMENTS ───────────────────────────────────────  │
│                                                           │
│  [📎 Add Flyer/Image]                                    │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐  │
│  │       [Cancel]              [Save as Draft]  [Publish]│  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

---

## Key Design Principles

1. **Liturgical awareness** — Season banner + color always visible for context
2. **At-a-glance scanning** — Color-coded categories, icons for amenities
3. **Role-based views** — Admins see edit/assign; members see RSVP/join
4. **Multi-campus support** — Filter and toggle between locations
5. **Accessibility-first** — Icons indicate wheelchair, childcare, livestream
6. **Mobile-responsive** — Stacked layout for sidebar nav on smaller screens
7. **Volunteer gaps surfaced** — ⚠️ indicators proactively flag open needs
