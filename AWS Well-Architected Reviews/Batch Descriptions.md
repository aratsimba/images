| Batch | Flow # | Flow Name | Theme | Review Status |
|-------|--------|-----------|-------|---------------|
| **Batch 1** | Flow 1 | New Member Onboarding | Identity, Auth, Data Onboarding | ✅ Complete |
| **Batch 2** | Flow 2 | Event Creation | Event Lifecycle, Payments (Stripe), RRULE | ✅ Complete |
| **Batch 2** | Flow 3 | Event Discovery & RSVP | Search, Capacity, Concurrency, Checkout | ✅ Complete |
| **Batch 3** | Flow 4 | Volunteer Assignment & Confirmation | Auto-Scheduling, Skill Matching, Swaps | ✅ Complete |
| **Batch 3** | Flow 5 | Event Cancellation & Notification | Saga Orchestration, Refunds, Cascades | ✅ Complete |
| **Batch 3** | Flow 6 | Recurring Event Management | RFC 5545 RRULE, Edit Scopes, Exceptions | ✅ Complete |
| **Batch 3** | Flow 7 | Push Notification Engagement | Multi-Channel Delivery, ML Timing, Bounce Handling | ✅ Complete |
| **Batch 4** | Flow 8 | Scripture & Lectionary Management | Bible APIs, Audio, Offline Sync, Search, Computus | ✅ Complete |

The batching strategy was designed around shared risk themes:

    Batch 1 — Standalone foundation: auth, state machine, PII handling
    Batch 2 — Paired because Event Creation and RSVP share payment security (PCI DSS), capacity management, and RRULE concerns
    Batch 3 — Grouped as "middle-tier orchestration" flows that all depend on reliable messaging, state machine coordination, and notification delivery
    Batch 4 — Scripture & Lectionary is architecturally distinct (third-party Bible APIs, audio streaming, offline sync, Computus algorithm) and also served as the cross-batch consolidation report

