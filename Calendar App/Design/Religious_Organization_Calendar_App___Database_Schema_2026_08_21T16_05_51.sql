
-- =============================================
-- Religious Organization Calendar App - Database Schema
-- =============================================

-- ===================
-- CORE TABLES
-- ===================

-- Organizations (multi-church/mosque/synagogue support)
CREATE TABLE organizations (
    org_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(255) NOT NULL,
    denomination        VARCHAR(100),
    address             TEXT,
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip                 VARCHAR(20),
    phone               VARCHAR(20),
    email               VARCHAR(255),
    website             VARCHAR(255),
    timezone            VARCHAR(50) NOT NULL DEFAULT 'America/New_York',
    logo_url            VARCHAR(500),
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- Campuses/Locations (multi-site support)
CREATE TABLE campuses (
    campus_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    name                VARCHAR(255) NOT NULL,
    address             TEXT,
    city                VARCHAR(100),
    state               VARCHAR(50),
    zip                 VARCHAR(20),
    is_primary          BOOLEAN DEFAULT FALSE,
    accessibility_notes TEXT,
    parking_info        TEXT,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- Rooms/Facilities within each campus
CREATE TABLE rooms (
    room_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campus_id           UUID NOT NULL REFERENCES campuses(campus_id),
    name                VARCHAR(100) NOT NULL,
    capacity            INTEGER,
    has_av_equipment    BOOLEAN DEFAULT FALSE,
    is_wheelchair_accessible BOOLEAN DEFAULT TRUE,
    has_childcare_nearby BOOLEAN DEFAULT FALSE,
    notes               TEXT
);

-- ===================
-- PEOPLE & ROLES
-- ===================

CREATE TABLE members (
    member_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255),
    phone               VARCHAR(20),
    role                VARCHAR(50) DEFAULT 'member',  -- pastor, admin, leader, volunteer, member
    avatar_url          VARCHAR(500),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ===================
-- CALENDAR & EVENTS
-- ===================

-- Liturgical Seasons
CREATE TABLE liturgical_seasons (
    season_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    name                VARCHAR(100) NOT NULL,       -- Advent, Lent, Ordinary Time, etc.
    color_hex           VARCHAR(7),                  -- liturgical color
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    description         TEXT,
    year                INTEGER NOT NULL
);

-- Event Categories
CREATE TABLE event_categories (
    category_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    name                VARCHAR(100) NOT NULL,       -- Worship, Youth, Outreach, Admin, etc.
    color_hex           VARCHAR(7) NOT NULL,
    icon                VARCHAR(50),
    sort_order          INTEGER DEFAULT 0
);

-- Events (core table)
CREATE TABLE events (
    event_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    category_id         UUID REFERENCES event_categories(category_id),
    campus_id           UUID REFERENCES campuses(campus_id),
    room_id             UUID REFERENCES rooms(room_id),
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    event_type          VARCHAR(50) NOT NULL,        -- service, study, meeting, outreach, social, sacrament
    start_datetime      TIMESTAMP NOT NULL,
    end_datetime        TIMESTAMP NOT NULL,
    is_all_day          BOOLEAN DEFAULT FALSE,
    is_recurring        BOOLEAN DEFAULT FALSE,
    recurrence_rule     VARCHAR(255),                -- RRULE format (RFC 5545)
    recurrence_end_date DATE,
    max_capacity        INTEGER,
    requires_rsvp       BOOLEAN DEFAULT FALSE,
    registration_url    VARCHAR(500),
    livestream_url      VARCHAR(500),
    childcare_available BOOLEAN DEFAULT FALSE,
    contact_member_id   UUID REFERENCES members(member_id),
    visibility          VARCHAR(20) DEFAULT 'public', -- public, members_only, leaders_only
    status              VARCHAR(20) DEFAULT 'active', -- active, cancelled, postponed
    cancellation_reason TEXT,
    created_by          UUID REFERENCES members(member_id),
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- Event RSVPs/Registrations
CREATE TABLE event_registrations (
    registration_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id            UUID NOT NULL REFERENCES events(event_id),
    member_id           UUID REFERENCES members(member_id),
    guest_name          VARCHAR(200),
    guest_email         VARCHAR(255),
    party_size          INTEGER DEFAULT 1,
    status              VARCHAR(20) DEFAULT 'registered', -- registered, waitlisted, cancelled
    notes               TEXT,
    registered_at       TIMESTAMP DEFAULT NOW()
);

-- ===================
-- MINISTRY & GROUPS
-- ===================

CREATE TABLE ministry_groups (
    group_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    name                VARCHAR(255) NOT NULL,
    description         TEXT,
    group_type          VARCHAR(50),                 -- small_group, ministry, committee, choir, class
    leader_member_id    UUID REFERENCES members(member_id),
    meeting_day         VARCHAR(10),
    meeting_time        TIME,
    campus_id           UUID REFERENCES campuses(campus_id),
    is_active           BOOLEAN DEFAULT TRUE
);

CREATE TABLE group_members (
    group_id            UUID NOT NULL REFERENCES ministry_groups(group_id),
    member_id           UUID NOT NULL REFERENCES members(member_id),
    role                VARCHAR(50) DEFAULT 'member', -- leader, co-leader, member
    joined_at           TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (group_id, member_id)
);

-- ===================
-- SPIRITUAL CONTENT
-- ===================

CREATE TABLE scripture_readings (
    reading_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    event_id            UUID REFERENCES events(event_id),
    reading_date        DATE NOT NULL,
    reading_type        VARCHAR(50),                 -- first_reading, psalm, gospel, epistle
    reference           VARCHAR(100) NOT NULL,       -- e.g., "John 3:16-21"
    text_content        TEXT,
    sort_order          INTEGER DEFAULT 0
);

CREATE TABLE prayer_focuses (
    prayer_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    title               VARCHAR(255) NOT NULL,
    description         TEXT,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    prayer_type         VARCHAR(50)                  -- weekly, daily, special
);

-- ===================
-- VOLUNTEER SCHEDULING
-- ===================

CREATE TABLE volunteer_roles (
    role_id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    name                VARCHAR(100) NOT NULL,       -- Greeter, Usher, Sound Tech, Nursery, etc.
    description         TEXT,
    min_volunteers      INTEGER DEFAULT 1,
    max_volunteers      INTEGER
);

CREATE TABLE volunteer_assignments (
    assignment_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id            UUID NOT NULL REFERENCES events(event_id),
    role_id             UUID NOT NULL REFERENCES volunteer_roles(role_id),
    member_id           UUID NOT NULL REFERENCES members(member_id),
    status              VARCHAR(20) DEFAULT 'assigned', -- assigned, confirmed, declined, swapped
    notes               TEXT,
    assigned_at         TIMESTAMP DEFAULT NOW()
);

-- ===================
-- NOTIFICATIONS & ALERTS
-- ===================

CREATE TABLE notifications (
    notification_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id              UUID NOT NULL REFERENCES organizations(org_id),
    event_id            UUID REFERENCES events(event_id),
    title               VARCHAR(255) NOT NULL,
    message             TEXT NOT NULL,
    notification_type   VARCHAR(50),                 -- reminder, cancellation, update, weather_alert
    send_at             TIMESTAMP,
    sent                BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- ===================
-- INDEXES
-- ===================

CREATE INDEX idx_events_org_date ON events(org_id, start_datetime);
CREATE INDEX idx_events_category ON events(category_id);
CREATE INDEX idx_events_campus ON events(campus_id);
CREATE INDEX idx_events_recurring ON events(is_recurring) WHERE is_recurring = TRUE;
CREATE INDEX idx_registrations_event ON event_registrations(event_id);
CREATE INDEX idx_liturgical_season_dates ON liturgical_seasons(org_id, start_date, end_date);
CREATE INDEX idx_volunteer_event ON volunteer_assignments(event_id);
CREATE INDEX idx_scripture_date ON scripture_readings(org_id, reading_date);

