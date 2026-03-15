'use strict';
/**
 * supabase Resource Tests
 *
 * Validates the integrity of the Supabase integration across:
 *   resources/[gameplay]/supabase/server.lua
 *   resources/[gameplay]/supabase/schema.sql
 *   server.cfg (convars and ensure directive)
 *   resources/[gameplay]/player-data/server.lua  (Supabase sync)
 *   resources/[gameplay]/bank-heist/server.lua   (activity logging)
 *   resources/[gameplay]/store-robbery/server.lua
 *   resources/[gameplay]/taxi/server.lua
 *   resources/[gameplay]/mechanic/server.lua
 *   resources/[gameplay]/police/server.lua
 *   resources/[gameplay]/ems/server.lua
 *   resources/[gameplay]/car-spawner/server.lua
 *
 * Checks performed:
 *  • supabase resource files exist (fxmanifest.lua, server.lua, schema.sql)
 *  • server.lua reads supabase_url and supabase_key convars
 *  • server.lua exports Insert, Select, Upsert, Update, isConfigured
 *  • server.lua uses PerformHttpRequest for HTTP calls
 *  • schema.sql defines a players table
 *  • schema.sql defines an activity_logs table
 *  • schema.sql defines indexes on activity_logs
 *  • server.cfg includes supabase_url and supabase_key set directives
 *  • server.cfg includes ensure supabase before gameplay resources
 *  • player-data/server.lua syncs to Supabase on player setup
 *  • All activity server.lua files call exports['supabase']:Insert
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT     = path.resolve(__dirname, '..');
const SUPABASE_DIR  = path.join(REPO_ROOT, 'resources', '[gameplay]', 'supabase');
const SERVER_LUA    = path.join(SUPABASE_DIR, 'server.lua');
const MANIFEST_LUA  = path.join(SUPABASE_DIR, 'fxmanifest.lua');
const SCHEMA_SQL    = path.join(SUPABASE_DIR, 'schema.sql');
const CFG_PATH      = path.join(REPO_ROOT, 'server.cfg');

const GAMEPLAY_DIR  = path.join(REPO_ROOT, 'resources', '[gameplay]');

/** Read a file, returning its content, or null if it does not exist. */
function readSafe(filePath) {
  try { return fs.readFileSync(filePath, 'utf8'); } catch { return null; }
}

/** Returns true if the source contains a Supabase Insert call */
function hasSupabaseInsert(source) {
  // Pattern 1: direct call  exports['supabase']:Insert(...)
  // Pattern 2: via local variable after pcall guard – file must reference
  //   exports['supabase'] AND call supabase:Insert(
  if (source.includes("exports['supabase']:Insert") ||
      source.includes('exports["supabase"]:Insert')) {
    return true;
  }
  const hasExportsRef = source.includes("exports['supabase']") ||
                        source.includes('exports["supabase"]');
  return hasExportsRef && source.includes('supabase:Insert(');
}

// ── supabase resource files ──────────────────────────────────────────────────

describe('supabase resource', () => {

  test('fxmanifest.lua exists', () => {
    assert.ok(fs.existsSync(MANIFEST_LUA), 'Missing: resources/[gameplay]/supabase/fxmanifest.lua');
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), 'Missing: resources/[gameplay]/supabase/server.lua');
  });

  test('schema.sql exists', () => {
    assert.ok(fs.existsSync(SCHEMA_SQL), 'Missing: resources/[gameplay]/supabase/schema.sql');
  });

  // ── Convar configuration ─────────────────────────────────────────────────

  describe('convar configuration', () => {
    const source = readSafe(SERVER_LUA) || '';

    test('reads supabase_url convar', () => {
      assert.ok(source.includes('supabase_url'), "server.lua must read the 'supabase_url' convar");
    });

    test('reads supabase_key convar', () => {
      assert.ok(source.includes('supabase_key'), "server.lua must read the 'supabase_key' convar");
    });

    test('warns when convars are not set', () => {
      assert.ok(
        source.includes('WARNING') || source.includes('disabled'),
        'server.lua should warn when supabase_url or supabase_key is not configured'
      );
    });
  });

  // ── Exported functions ───────────────────────────────────────────────────

  describe('exported functions', () => {
    const source = readSafe(SERVER_LUA) || '';

    test("exports 'Insert'", () => {
      assert.ok(
        source.includes("exports('Insert'") || source.includes('exports("Insert"'),
        "server.lua must export 'Insert'"
      );
    });

    test("exports 'Select'", () => {
      assert.ok(
        source.includes("exports('Select'") || source.includes('exports("Select"'),
        "server.lua must export 'Select'"
      );
    });

    test("exports 'Upsert'", () => {
      assert.ok(
        source.includes("exports('Upsert'") || source.includes('exports("Upsert"'),
        "server.lua must export 'Upsert'"
      );
    });

    test("exports 'Update'", () => {
      assert.ok(
        source.includes("exports('Update'") || source.includes('exports("Update"'),
        "server.lua must export 'Update'"
      );
    });

    test("exports 'isConfigured'", () => {
      assert.ok(
        source.includes("exports('isConfigured'") || source.includes('exports("isConfigured"'),
        "server.lua must export 'isConfigured'"
      );
    });
  });

  // ── HTTP implementation ──────────────────────────────────────────────────

  describe('HTTP implementation', () => {
    const source = readSafe(SERVER_LUA) || '';

    test('uses PerformHttpRequest for API calls', () => {
      assert.ok(source.includes('PerformHttpRequest'), 'server.lua must use PerformHttpRequest');
    });

    test('sets apikey header', () => {
      assert.ok(source.includes("'apikey'") || source.includes('"apikey"'), 'server.lua must set the apikey header');
    });

    test('sets Authorization header', () => {
      assert.ok(
        source.includes("'Authorization'") || source.includes('"Authorization"'),
        'server.lua must set the Authorization header'
      );
    });

    test('sets Content-Type application/json header', () => {
      assert.ok(
        source.includes('application/json'),
        'server.lua must set Content-Type: application/json'
      );
    });
  });

  // ── schema.sql ───────────────────────────────────────────────────────────

  describe('schema.sql', () => {
    const schema = readSafe(SCHEMA_SQL) || '';

    test('defines a players table', () => {
      assert.ok(
        schema.includes('CREATE TABLE') && schema.includes('players'),
        'schema.sql must define a players table'
      );
    });

    test('players table has an id column', () => {
      // Find the CREATE TABLE players block, then check it contains an id column
      const tableMatch = schema.match(/CREATE TABLE[^(]*players\s*\([\s\S]+?\);/i);
      assert.ok(tableMatch, 'Could not find CREATE TABLE players block in schema.sql');
      assert.ok(/\bid\s+BIGINT/i.test(tableMatch[0]), 'players table must have an id BIGINT column');
    });

    test('players table has an identifiers column', () => {
      assert.ok(schema.includes('identifiers'), 'players table must have an identifiers column');
    });

    test('defines an activity_logs table', () => {
      assert.ok(schema.includes('activity_logs'), 'schema.sql must define an activity_logs table');
    });

    test('activity_logs table has a player_id column', () => {
      assert.ok(schema.includes('player_id'), 'activity_logs must have a player_id column');
    });

    test('activity_logs table has an event_type column', () => {
      assert.ok(schema.includes('event_type'), 'activity_logs must have an event_type column');
    });

    test('activity_logs table has a data column', () => {
      assert.ok(schema.includes('data'), 'activity_logs must have a data column');
    });

    test('creates indexes on activity_logs', () => {
      assert.ok(schema.includes('CREATE INDEX'), 'schema.sql must create indexes on activity_logs');
    });
  });
});

// ── server.cfg ───────────────────────────────────────────────────────────────

describe('server.cfg Supabase configuration', () => {
  const cfg = readSafe(CFG_PATH) || '';

  test('sets supabase_url', () => {
    assert.ok(
      /^\s*set\s+supabase_url\s+/m.test(cfg),
      'server.cfg must contain a `set supabase_url` directive'
    );
  });

  test('sets supabase_key', () => {
    assert.ok(
      /^\s*set\s+supabase_key\s+/m.test(cfg),
      'server.cfg must contain a `set supabase_key` directive'
    );
  });

  test('ensures supabase resource', () => {
    assert.ok(
      /^\s*ensure\s+supabase\s*$/m.test(cfg),
      'server.cfg must contain `ensure supabase`'
    );
  });

  test('ensures player-data resource', () => {
    assert.ok(
      /^\s*ensure\s+player-data\s*$/m.test(cfg),
      'server.cfg must contain `ensure player-data`'
    );
  });

  test('ensure supabase appears before gameplay resources', () => {
    const supabasePos   = cfg.indexOf('ensure supabase');
    const bankHeistPos  = cfg.indexOf('ensure bank-heist');
    assert.ok(supabasePos !== -1, '`ensure supabase` not found in server.cfg');
    assert.ok(bankHeistPos !== -1, '`ensure bank-heist` not found in server.cfg');
    assert.ok(
      supabasePos < bankHeistPos,
      '`ensure supabase` must appear before gameplay resources in server.cfg'
    );
  });
});

// ── player-data Supabase sync ─────────────────────────────────────────────────

describe('player-data Supabase sync', () => {
  const source = readSafe(
    path.join(GAMEPLAY_DIR, 'player-data', 'server.lua')
  ) || '';

  test('upserts player record to Supabase', () => {
    assert.ok(
      source.includes("exports['supabase']:Upsert") ||
      source.includes('exports["supabase"]:Upsert') ||
      source.includes('supabase:Upsert('),
      'player-data/server.lua must call Upsert to persist player records to Supabase'
    );
  });

  test('includes player identifiers in the upsert payload', () => {
    assert.ok(source.includes('identifiers'), 'player-data sync must include identifiers');
  });

  test('includes last_seen timestamp in the upsert payload', () => {
    assert.ok(source.includes('last_seen'), 'player-data sync must include a last_seen timestamp');
  });

  test('uses pcall to guard supabase export access', () => {
    assert.ok(
      source.includes('pcall'),
      'player-data/server.lua must use pcall when accessing supabase exports (graceful degradation)'
    );
  });
});

// ── Activity logging in gameplay resources ────────────────────────────────────

const ACTIVITY_RESOURCES = [
  'bank-heist',
  'store-robbery',
  'taxi',
  'mechanic',
  'police',
  'ems',
  'car-spawner',
];

describe('activity logging', () => {
  for (const resourceName of ACTIVITY_RESOURCES) {
    const serverLua = path.join(GAMEPLAY_DIR, resourceName, 'server.lua');
    const source    = readSafe(serverLua) || '';

    test(`${resourceName}/server.lua logs to Supabase`, () => {
      assert.ok(
        hasSupabaseInsert(source),
        `${resourceName}/server.lua must call exports['supabase']:Insert to log activities`
      );
    });

    test(`${resourceName}/server.lua uses pcall to guard supabase export access`, () => {
      assert.ok(
        source.includes('pcall'),
        `${resourceName}/server.lua must use pcall when accessing supabase exports`
      );
    });
  }
});
