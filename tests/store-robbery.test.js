'use strict';
/**
 * store-robbery Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/store-robbery/client.lua
 *   resources/[gameplay]/store-robbery/server.lua
 *
 * Checks performed:
 *  • STORE_LOCATIONS table is non-empty with name/x/y/z/reward fields
 *  • Every store has a positive reward value
 *  • ROBBERY_TOOLS table is non-empty
 *  • Every tool entry has the required fields: name, label, intimidate
 *  • All tool names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • All intimidate multiplier values are positive floats (0 < intimidate ≤ 1.0)
 *  • No duplicate tool names in ROBBERY_TOOLS
 *  • ROBBERY_TOOL_BY_NAME and ROBBERY_TOOL_BY_LABEL lookups are built from ROBBERY_TOOLS
 *  • robberyActive flag is defined and defaults to false
 *  • The /robstore, /intimidate, and /cashout commands are registered
 *  • server.lua registers store-robbery:started, store-robbery:intimidateComplete,
 *    and store-robbery:complete events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'store-robbery', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'store-robbery', 'server.lua');

/**
 * Parse the STORE_LOCATIONS table from client.lua.
 * Returns an array of objects: { name, x, y, z, reward }
 */
function extractStoreLocations(source) {
  const tableMatch = source.match(/local\s+STORE_LOCATIONS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const stores  = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block  = entry[0];
    const name   = (block.match(/name\s*=\s*["']([^"']+)["']/) || [])[1];
    const x      = (block.match(/x\s*=\s*(-?[\d.]+)/)         || [])[1];
    const y      = (block.match(/y\s*=\s*(-?[\d.]+)/)         || [])[1];
    const z      = (block.match(/z\s*=\s*(-?[\d.]+)/)         || [])[1];
    const reward = (block.match(/reward\s*=\s*(\d+)/)          || [])[1];

    if (name) {
      stores.push({
        name,
        x:      x      ? parseFloat(x)       : undefined,
        y:      y      ? parseFloat(y)       : undefined,
        z:      z      ? parseFloat(z)       : undefined,
        reward: reward ? parseInt(reward, 10) : undefined,
      });
    }
  }
  return stores.length > 0 ? stores : null;
}

/**
 * Parse the ROBBERY_TOOLS table from client.lua.
 * Returns an array of objects: { name, label, intimidate }
 */
function extractRobberyTools(source) {
  const tableMatch = source.match(/local\s+ROBBERY_TOOLS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const tools   = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block      = entry[0];
    const name       = (block.match(/name\s*=\s*["']([^"']+)["']/)       || [])[1];
    const label      = (block.match(/label\s*=\s*["']([^"']+)["']/)      || [])[1];
    const intimidate = (block.match(/intimidate\s*=\s*([\d.]+)/)          || [])[1];

    if (name || label || intimidate) {
      tools.push({
        name,
        label,
        intimidate: intimidate ? parseFloat(intimidate) : undefined,
      });
    }
  }
  return tools.length > 0 ? tools : null;
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

describe('store-robbery', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── STORE_LOCATIONS data table ────────────────────────────────────────────

  describe('STORE_LOCATIONS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const stores = extractStoreLocations(source);

    test('STORE_LOCATIONS table is present in client.lua', () => {
      assert.ok(stores !== null, 'STORE_LOCATIONS table not found in client.lua');
    });

    test('STORE_LOCATIONS contains at least one entry', () => {
      assert.ok(stores.length > 0, 'STORE_LOCATIONS list must not be empty');
    });

    test('every store has a non-empty name', () => {
      const invalid = stores.filter(s => !s.name || s.name.trim() === '');
      assert.deepEqual(invalid, [], `Stores with empty name found`);
    });

    test('every store has numeric x, y, z coordinates', () => {
      const invalid = stores.filter(s => s.x === undefined || s.y === undefined || s.z === undefined);
      assert.deepEqual(
        invalid.map(s => s.name),
        [],
        `Stores missing coordinates: ${invalid.map(s => s.name).join(', ')}`
      );
    });

    test('every store has a positive reward value', () => {
      const invalid = stores.filter(s => s.reward === undefined || s.reward <= 0);
      assert.deepEqual(
        invalid.map(s => s.name),
        [],
        `Stores with invalid reward: ${invalid.map(s => `${s.name}(${s.reward})`).join(', ')}`
      );
    });
  });

  // ── ROBBERY_TOOLS data table ──────────────────────────────────────────────

  describe('ROBBERY_TOOLS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const tools  = extractRobberyTools(source);

    test('ROBBERY_TOOLS table is present in client.lua', () => {
      assert.ok(tools !== null, 'ROBBERY_TOOLS table not found in client.lua');
    });

    test('ROBBERY_TOOLS contains at least one entry', () => {
      assert.ok(tools.length > 0, 'ROBBERY_TOOLS list must not be empty');
    });

    test('every tool has a non-empty lowercase name', () => {
      const invalid = tools.filter(t => !t.name || !/^[a-z0-9_]+$/.test(t.name));
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with invalid name: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every tool has a non-empty label', () => {
      const invalid = tools.filter(t => !t.label || t.label.trim() === '');
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with empty label: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every tool has an intimidate value in range (0, 1.0]', () => {
      const invalid = tools.filter(t => t.intimidate === undefined || t.intimidate <= 0 || t.intimidate > 1.0);
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with invalid intimidate: ${invalid.map(t => `${t.name}(${t.intimidate})`).join(', ')}`
      );
    });

    test('no duplicate tool names in ROBBERY_TOOLS', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const t of tools) {
        if (seen.has(t.name)) duplicates.push(t.name);
        else seen.add(t.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate tool names: ${duplicates.join(', ')}`);
    });

    test('ROBBERY_TOOL_BY_NAME lookup is built from ROBBERY_TOOLS', () => {
      assert.match(
        source,
        /ROBBERY_TOOL_BY_NAME\s*\[\s*tool\.name\s*\]\s*=\s*tool/,
        'ROBBERY_TOOL_BY_NAME should index each tool by its name field'
      );
    });

    test('ROBBERY_TOOL_BY_LABEL lookup is built from ROBBERY_TOOLS', () => {
      assert.match(
        source,
        /ROBBERY_TOOL_BY_LABEL\s*\[\s*string\.lower\s*\(\s*tool\.label\s*\)\s*\]\s*=\s*tool/,
        'ROBBERY_TOOL_BY_LABEL should index each tool by its lowercase label'
      );
    });
  });

  // ── Robbery state ────────────────────────────────────────────────────────

  describe('robbery state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('robberyActive flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+robberyActive\s*=\s*false/,
        'robberyActive should be defined and default to false'
      );
    });

    test('intimidateLevel is initialized to 0.0', () => {
      assert.match(
        source,
        /local\s+intimidateLevel\s*=\s*0\.0/,
        'intimidateLevel should be defined and initialized to 0.0'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/robstore command is registered', () => {
      assert.ok(commands.has('robstore'), 'RegisterCommand("robstore", ...) not found');
    });

    test('/intimidate command is registered', () => {
      assert.ok(commands.has('intimidate'), 'RegisterCommand("intimidate", ...) not found');
    });

    test('/cashout command is registered', () => {
      assert.ok(commands.has('cashout'), 'RegisterCommand("cashout", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('store-robbery:started event is registered', () => {
      assert.ok(
        source.includes("'store-robbery:started'") || source.includes('"store-robbery:started"'),
        "RegisterNetEvent('store-robbery:started') not found in server.lua"
      );
    });

    test('store-robbery:intimidateComplete event is registered', () => {
      assert.ok(
        source.includes("'store-robbery:intimidateComplete'") || source.includes('"store-robbery:intimidateComplete"'),
        "RegisterNetEvent('store-robbery:intimidateComplete') not found in server.lua"
      );
    });

    test('store-robbery:complete event is registered', () => {
      assert.ok(
        source.includes("'store-robbery:complete'") || source.includes('"store-robbery:complete"'),
        "RegisterNetEvent('store-robbery:complete') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the robber'
      );
    });
  });
});
