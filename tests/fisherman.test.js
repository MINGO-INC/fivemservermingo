'use strict';
/**
 * fisherman Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/fisherman/client.lua
 *   resources/[gameplay]/fisherman/server.lua
 *
 * Checks performed:
 *  • FISH_TYPES table is non-empty
 *  • Every fish entry has the required fields: name, label, value
 *  • All fish names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • All value fields are positive numbers
 *  • No duplicate fish names in FISH_TYPES
 *  • FISH_TYPE_BY_NAME lookup map is built from FISH_TYPES
 *  • FISH_SPOTS table is non-empty and each entry has a label
 *  • fishermanOnDuty flag is defined and defaults to false
 *  • fishInventory is defined and defaults to 0
 *  • The /fisherduty, /fish, and /sellfish commands are registered
 *  • server.lua registers fisherman:dutyChange, fisherman:logFish, fisherman:logSell events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'fisherman', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'fisherman', 'server.lua');

/**
 * Parse the FISH_TYPES table from client.lua.
 * Returns an array of objects: { name, label, value }
 */
function extractFishTypes(source) {
  const tableMatch = source.match(/local\s+FISH_TYPES\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const types   = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name  = (block.match(/name\s*=\s*["']([^"']+)["']/)  || [])[1];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    const value = (block.match(/value\s*=\s*([\d.]+)/)         || [])[1];

    if (name || label || value) {
      types.push({
        name,
        label,
        value: value ? parseFloat(value) : undefined,
      });
    }
  }
  return types.length > 0 ? types : null;
}

/**
 * Parse the FISH_SPOTS table from client.lua.
 * Returns an array of objects: { label }
 */
function extractFishSpots(source) {
  const tableMatch = source.match(/local\s+FISH_SPOTS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const spots   = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    if (label) spots.push({ label });
  }
  return spots.length > 0 ? spots : null;
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

describe('fisherman', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── FISH_TYPES data table ─────────────────────────────────────────────────

  describe('FISH_TYPES data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const types  = extractFishTypes(source);

    test('FISH_TYPES table is present in client.lua', () => {
      assert.ok(types !== null, 'FISH_TYPES table not found in client.lua');
    });

    test('FISH_TYPES contains at least one entry', () => {
      assert.ok(types.length > 0, 'FISH_TYPES list must not be empty');
    });

    test('every entry has a non-empty lowercase name', () => {
      const invalid = types.filter(t => !t.name || !/^[a-z0-9_]+$/.test(t.name));
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Fish types with invalid name: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every entry has a non-empty label', () => {
      const invalid = types.filter(t => !t.label || t.label.trim() === '');
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Fish types with empty label: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every entry has a positive value', () => {
      const invalid = types.filter(t => t.value === undefined || t.value <= 0);
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Fish types with invalid value: ${invalid.map(t => `${t.name}(${t.value})`).join(', ')}`
      );
    });

    test('no duplicate fish names in FISH_TYPES', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const t of types) {
        if (seen.has(t.name)) duplicates.push(t.name);
        else seen.add(t.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate fish names: ${duplicates.join(', ')}`);
    });

    test('FISH_TYPE_BY_NAME lookup is built from FISH_TYPES', () => {
      assert.match(
        source,
        /FISH_TYPE_BY_NAME\s*\[\s*f\.name\s*\]\s*=\s*f/,
        'FISH_TYPE_BY_NAME should index each fish type by its name field'
      );
    });
  });

  // ── FISH_SPOTS data table ─────────────────────────────────────────────────

  describe('FISH_SPOTS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const spots  = extractFishSpots(source);

    test('FISH_SPOTS table is present in client.lua', () => {
      assert.ok(spots !== null, 'FISH_SPOTS table not found in client.lua');
    });

    test('FISH_SPOTS contains at least one entry', () => {
      assert.ok(spots.length > 0, 'FISH_SPOTS list must not be empty');
    });

    test('every spot entry has a non-empty label', () => {
      const invalid = spots.filter(s => !s.label || s.label.trim() === '');
      assert.deepEqual(invalid, [], 'Spots with empty label found');
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('fishermanOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+fishermanOnDuty\s*=\s*false/,
        'fishermanOnDuty should be defined and default to false'
      );
    });

    test('fishInventory is defined and defaults to 0', () => {
      assert.match(
        source,
        /local\s+fishInventory\s*=\s*0/,
        'fishInventory should be defined and default to 0'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/fisherduty command is registered', () => {
      assert.ok(commands.has('fisherduty'), 'RegisterCommand("fisherduty", ...) not found');
    });

    test('/fish command is registered', () => {
      assert.ok(commands.has('fish'), 'RegisterCommand("fish", ...) not found');
    });

    test('/sellfish command is registered', () => {
      assert.ok(commands.has('sellfish'), 'RegisterCommand("sellfish", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('fisherman:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'fisherman:dutyChange'") || source.includes('"fisherman:dutyChange"'),
        "RegisterNetEvent('fisherman:dutyChange') not found in server.lua"
      );
    });

    test('fisherman:logFish event is registered', () => {
      assert.ok(
        source.includes("'fisherman:logFish'") || source.includes('"fisherman:logFish"'),
        "RegisterNetEvent('fisherman:logFish') not found in server.lua"
      );
    });

    test('fisherman:logSell event is registered', () => {
      assert.ok(
        source.includes("'fisherman:logSell'") || source.includes('"fisherman:logSell"'),
        "RegisterNetEvent('fisherman:logSell') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the fisherman'
      );
    });
  });
});
