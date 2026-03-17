'use strict';
/**
 * house-robbery Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/house-robbery/client.lua
 *   resources/[gameplay]/house-robbery/server.lua
 *
 * Checks performed:
 *  • HOUSE_LOCATIONS table is non-empty with name/x/y/z/loot fields
 *  • Every house has a positive loot value
 *  • houseRobberyActive flag is defined and defaults to false
 *  • The /caseHouse, /breakIn, and /lootHouse commands are registered
 *  • server.lua registers house-robbery:casing, house-robbery:breakInComplete,
 *    and house-robbery:complete events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'house-robbery', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'house-robbery', 'server.lua');

/**
 * Parse the HOUSE_LOCATIONS table from client.lua.
 * Returns an array of objects: { name, x, y, z, loot }
 */
function extractHouseLocations(source) {
  const tableMatch = source.match(/local\s+HOUSE_LOCATIONS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const houses  = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name  = (block.match(/name\s*=\s*["']([^"']+)["']/) || [])[1];
    const x     = (block.match(/x\s*=\s*(-?[\d.]+)/)         || [])[1];
    const y     = (block.match(/y\s*=\s*(-?[\d.]+)/)         || [])[1];
    const z     = (block.match(/z\s*=\s*(-?[\d.]+)/)         || [])[1];
    const loot  = (block.match(/loot\s*=\s*(\d+)/)           || [])[1];

    if (name) {
      houses.push({
        name,
        x:    x    ? parseFloat(x)       : undefined,
        y:    y    ? parseFloat(y)       : undefined,
        z:    z    ? parseFloat(z)       : undefined,
        loot: loot ? parseInt(loot, 10)  : undefined,
      });
    }
  }
  return houses.length > 0 ? houses : null;
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

describe('house-robbery', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── HOUSE_LOCATIONS data table ────────────────────────────────────────────

  describe('HOUSE_LOCATIONS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const houses = extractHouseLocations(source);

    test('HOUSE_LOCATIONS table is present in client.lua', () => {
      assert.ok(houses !== null, 'HOUSE_LOCATIONS table not found in client.lua');
    });

    test('HOUSE_LOCATIONS contains at least one entry', () => {
      assert.ok(houses.length > 0, 'HOUSE_LOCATIONS list must not be empty');
    });

    test('every house has a non-empty name', () => {
      const invalid = houses.filter(h => !h.name || h.name.trim() === '');
      assert.deepEqual(invalid, [], 'Houses with empty name found');
    });

    test('every house has numeric x, y, z coordinates', () => {
      const invalid = houses.filter(h => h.x === undefined || h.y === undefined || h.z === undefined);
      assert.deepEqual(
        invalid.map(h => h.name),
        [],
        `Houses missing coordinates: ${invalid.map(h => h.name).join(', ')}`
      );
    });

    test('every house has a positive loot value', () => {
      const invalid = houses.filter(h => h.loot === undefined || h.loot <= 0);
      assert.deepEqual(
        invalid.map(h => h.name),
        [],
        `Houses with invalid loot: ${invalid.map(h => `${h.name}(${h.loot})`).join(', ')}`
      );
    });
  });

  // ── Robbery state ─────────────────────────────────────────────────────────

  describe('robbery state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('houseRobberyActive flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+houseRobberyActive\s*=\s*false/,
        'houseRobberyActive should be defined and default to false'
      );
    });

    test('houseRobberyStage is initialized to 0', () => {
      assert.match(
        source,
        /local\s+houseRobberyStage\s*=\s*0/,
        'houseRobberyStage should be defined and initialized to 0'
      );
    });
  });

  // ── Registered commands ───────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/caseHouse command is registered', () => {
      assert.ok(commands.has('caseHouse'), 'RegisterCommand("caseHouse", ...) not found');
    });

    test('/breakIn command is registered', () => {
      assert.ok(commands.has('breakIn'), 'RegisterCommand("breakIn", ...) not found');
    });

    test('/lootHouse command is registered', () => {
      assert.ok(commands.has('lootHouse'), 'RegisterCommand("lootHouse", ...) not found');
    });
  });

  // ── Server-side event handling ────────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('house-robbery:casing event is registered', () => {
      assert.ok(
        source.includes("'house-robbery:casing'") || source.includes('"house-robbery:casing"'),
        "RegisterNetEvent('house-robbery:casing') not found in server.lua"
      );
    });

    test('house-robbery:breakInComplete event is registered', () => {
      assert.ok(
        source.includes("'house-robbery:breakInComplete'") || source.includes('"house-robbery:breakInComplete"'),
        "RegisterNetEvent('house-robbery:breakInComplete') not found in server.lua"
      );
    });

    test('house-robbery:complete event is registered', () => {
      assert.ok(
        source.includes("'house-robbery:complete'") || source.includes('"house-robbery:complete"'),
        "RegisterNetEvent('house-robbery:complete') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the burglar'
      );
    });
  });
});
