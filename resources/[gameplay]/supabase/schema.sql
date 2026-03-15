-- Supabase schema for fivemservermingo
-- Run this SQL in the Supabase SQL editor (https://app.supabase.com → SQL editor)
-- to create all required tables before starting the FiveM server.

-- ── Players ───────────────────────────────────────────────────────────────────
-- One row per unique player account, keyed by the database ID that the
-- player-data resource assigns.  The `identifiers` column is a JSON array of
-- all known FiveM identifier strings (steam:..., discord:..., license:...).
CREATE TABLE IF NOT EXISTS players (
    id          BIGINT       PRIMARY KEY,
    identifiers JSONB        NOT NULL DEFAULT '[]',
    first_seen  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_seen   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── Activity Logs ─────────────────────────────────────────────────────────────
-- Append-only event log for every notable player action across all job/crime
-- resources.  The `event_type` field identifies the resource and action
-- (e.g. 'bank-heist:started', 'taxi:logFare'), and `data` carries any
-- additional payload as JSON.
CREATE TABLE IF NOT EXISTS activity_logs (
    id          BIGSERIAL    PRIMARY KEY,
    player_id   BIGINT       REFERENCES players(id) ON DELETE SET NULL,
    player_name TEXT         NOT NULL,
    event_type  TEXT         NOT NULL,
    data        JSONB        NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indexes for common queries (filter by player, event type, or recency)
CREATE INDEX IF NOT EXISTS idx_activity_logs_player_id  ON activity_logs (player_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_event_type ON activity_logs (event_type);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs (created_at DESC);
