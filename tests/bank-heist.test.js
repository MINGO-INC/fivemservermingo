'use strict';
/**
 * bank-heist Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/bank-heist/client.lua
 *   resources/[gameplay]/bank-heist/server.lua
 *
 * Checks performed:
 *  • BANK_LOCATIONS table is non-empty with name/x/y/z fields
 *  • HEIST_ROLES table is non-empty
 *  • Every role entry has the required fields: name, label, bonus
 *  • All role names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • All bonus values are positive floats (> 1.0)
 *  • No duplicate role names in HEIST_ROLES
 *  • HEIST_ROLE_BY_NAME and HEIST_ROLE_BY_LABEL lookup maps are built from HEIST_ROLES
 *  • HEIST_LOOT_BASE is defined as a positive integer
 *  • heistActive flag is defined and defaults to false
 *  • The /startbankheist, /drillbank, /hackbank, and /grabcash commands are registered
 *  • CreateThread is used for the timed drilling and hacking stages
 *  • server.lua registers bank-heist:started, bank-heist:drillComplete,
 *    bank-heist:hackComplete, and bank-heist:complete events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'bank-heist', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'bank-heist', 'server.lua');

/**
 * Parse the HEIST_ROLES table from client.lua.
 * Returns an array of objects: { name, label, bonus }
 */
function extractHeistRoles(source) {
  const tableMatch = source.match(/local\s+HEIST_ROLES\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const roles   = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name  = (block.match(/name\s*=\s*["']([^"']+)["']/)  || [])[1];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    const bonus = (block.match(/bonus\s*=\s*([\d.]+)/)         || [])[1];

    if (name || label || bonus) {
      roles.push({
        name,
        label,
        bonus: bonus ? parseFloat(bonus) : undefined,
      });
    }
  }
  return roles.length > 0 ? roles : null;
}

/**
 * Parse the BANK_LOCATIONS table from client.lua.
 * Returns an array of objects: { name, x, y, z }
 */
function extractBankLocations(source) {
  const tableMatch = source.match(/local\s+BANK_LOCATIONS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const locations = [];
  const entryRe   = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name  = (block.match(/name\s*=\s*["']([^"']+)["']/) || [])[1];
    const x     = (block.match(/x\s*=\s*(-?[\d.]+)/)         || [])[1];
    const y     = (block.match(/y\s*=\s*(-?[\d.]+)/)         || [])[1];
    const z     = (block.match(/z\s*=\s*(-?[\d.]+)/)         || [])[1];

    if (name) {
      locations.push({ name, x: x ? parseFloat(x) : undefined, y: y ? parseFloat(y) : undefined, z: z ? parseFloat(z) : undefined });
    }
  }
  return locations.length > 0 ? locations : null;
}

/** Extract all RegisterCommand call names from a Lua source string. */
function extractRegisteredCommands(source) {
  const commands = new Set();
  for (const m of source.matchAll(/RegisterCommand\s*\(\s*["']([^"']+)["']/g)) {
    commands.add(m[1]);
  }
  return commands;
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe('bank-heist', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── BANK_LOCATIONS data table ─────────────────────────────────────────────

  describe('BANK_LOCATIONS data table', () => {
    const source    = fs.readFileSync(CLIENT_LUA, 'utf8');
    const locations = extractBankLocations(source);

    test('BANK_LOCATIONS table is present in client.lua', () => {
      assert.ok(locations !== null, 'BANK_LOCATIONS table not found in client.lua');
    });

    test('BANK_LOCATIONS contains at least one entry', () => {
      assert.ok(locations.length > 0, 'BANK_LOCATIONS list must not be empty');
    });

    test('every location has a non-empty name', () => {
      const invalid = locations.filter(l => !l.name || l.name.trim() === '');
      assert.deepEqual(invalid, [], `Locations with empty name: ${invalid.map(l => l.name).join(', ')}`);
    });

    test('every location has numeric x, y, z coordinates', () => {
      const invalid = locations.filter(l => l.x === undefined || l.y === undefined || l.z === undefined);
      assert.deepEqual(
        invalid.map(l => l.name),
        [],
        `Locations missing coordinates: ${invalid.map(l => l.name).join(', ')}`
      );
    });
  });

  // ── HEIST_ROLES data table ────────────────────────────────────────────────

  describe('HEIST_ROLES data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const roles  = extractHeistRoles(source);

    test('HEIST_ROLES table is present in client.lua', () => {
      assert.ok(roles !== null, 'HEIST_ROLES table not found in client.lua');
    });

    test('HEIST_ROLES contains at least one entry', () => {
      assert.ok(roles.length > 0, 'HEIST_ROLES list must not be empty');
    });

    test('every role has a non-empty lowercase name', () => {
      const invalid = roles.filter(r => !r.name || !/^[a-z0-9_]+$/.test(r.name));
      assert.deepEqual(
        invalid.map(r => r.name),
        [],
        `Roles with invalid name: ${invalid.map(r => r.name).join(', ')}`
      );
    });

    test('every role has a non-empty label', () => {
      const invalid = roles.filter(r => !r.label || r.label.trim() === '');
      assert.deepEqual(
        invalid.map(r => r.name),
        [],
        `Roles with empty label: ${invalid.map(r => r.name).join(', ')}`
      );
    });

    test('every role has a bonus value greater than 1.0', () => {
      const invalid = roles.filter(r => r.bonus === undefined || r.bonus <= 1.0);
      assert.deepEqual(
        invalid.map(r => r.name),
        [],
        `Roles with invalid bonus: ${invalid.map(r => `${r.name}(${r.bonus})`).join(', ')}`
      );
    });

    test('no duplicate role names in HEIST_ROLES', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const r of roles) {
        if (seen.has(r.name)) duplicates.push(r.name);
        else seen.add(r.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate role names: ${duplicates.join(', ')}`);
    });

    test('HEIST_ROLE_BY_NAME lookup is built from HEIST_ROLES', () => {
      assert.match(
        source,
        /HEIST_ROLE_BY_NAME\s*\[\s*role\.name\s*\]\s*=\s*role/,
        'HEIST_ROLE_BY_NAME should index each role by its name field'
      );
    });

    test('HEIST_ROLE_BY_LABEL lookup is built from HEIST_ROLES', () => {
      assert.match(
        source,
        /HEIST_ROLE_BY_LABEL\s*\[\s*string\.lower\s*\(\s*role\.label\s*\)\s*\]\s*=\s*role/,
        'HEIST_ROLE_BY_LABEL should index each role by its lowercase label'
      );
    });
  });

  // ── Loot and state ───────────────────────────────────────────────────────

  describe('loot and heist state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('HEIST_LOOT_BASE is defined as a positive integer', () => {
      const match = source.match(/local\s+HEIST_LOOT_BASE\s*=\s*(\d+)/);
      assert.ok(match, 'HEIST_LOOT_BASE not found in client.lua');
      assert.ok(parseInt(match[1], 10) > 0, `HEIST_LOOT_BASE must be > 0, got ${match[1]}`);
    });

    test('heistActive flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+heistActive\s*=\s*false/,
        'heistActive should be defined and default to false'
      );
    });

    test('CreateThread is used for timed drill/hack stages', () => {
      assert.ok(
        source.includes('CreateThread'),
        'client.lua should use CreateThread for timed heist stages'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/startbankheist command is registered', () => {
      assert.ok(commands.has('startbankheist'), 'RegisterCommand("startbankheist", ...) not found');
    });

    test('/drillbank command is registered', () => {
      assert.ok(commands.has('drillbank'), 'RegisterCommand("drillbank", ...) not found');
    });

    test('/hackbank command is registered', () => {
      assert.ok(commands.has('hackbank'), 'RegisterCommand("hackbank", ...) not found');
    });

    test('/grabcash command is registered', () => {
      assert.ok(commands.has('grabcash'), 'RegisterCommand("grabcash", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('bank-heist:started event is registered', () => {
      assert.ok(
        source.includes("'bank-heist:started'") || source.includes('"bank-heist:started"'),
        "RegisterNetEvent('bank-heist:started') not found in server.lua"
      );
    });

    test('bank-heist:drillComplete event is registered', () => {
      assert.ok(
        source.includes("'bank-heist:drillComplete'") || source.includes('"bank-heist:drillComplete"'),
        "RegisterNetEvent('bank-heist:drillComplete') not found in server.lua"
      );
    });

    test('bank-heist:hackComplete event is registered', () => {
      assert.ok(
        source.includes("'bank-heist:hackComplete'") || source.includes('"bank-heist:hackComplete"'),
        "RegisterNetEvent('bank-heist:hackComplete') not found in server.lua"
      );
    });

    test('bank-heist:complete event is registered', () => {
      assert.ok(
        source.includes("'bank-heist:complete'") || source.includes('"bank-heist:complete"'),
        "RegisterNetEvent('bank-heist:complete') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the heist participant'
      );
    });
  });
});
