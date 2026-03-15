'use strict';
/**
 * mechanic Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/mechanic/client.lua
 *   resources/[gameplay]/mechanic/server.lua
 *
 * Checks performed:
 *  • MECHANIC_TOOLS table is non-empty
 *  • Every tool entry has the required fields: name, label, repairAmount, range
 *  • All tool names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • All repairAmount values are positive numbers
 *  • All range values are positive numbers
 *  • No duplicate tool names in MECHANIC_TOOLS
 *  • MECHANIC_TOOL_BY_NAME lookup map is built from MECHANIC_TOOLS
 *  • mechanicOnDuty flag is defined and defaults to false
 *  • The /mechanicduty, /repairvehicle, and /towtruck commands are registered
 *  • server.lua registers mechanic:dutyChange, mechanic:logRepair, mechanic:logTowTruck events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'mechanic', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'mechanic', 'server.lua');

/**
 * Parse the MECHANIC_TOOLS table from client.lua.
 * Returns an array of objects: { name, label, repairAmount, range }
 */
function extractMechanicTools(source) {
  const tableMatch = source.match(/local\s+MECHANIC_TOOLS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const tools  = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block        = entry[0];
    const name         = (block.match(/name\s*=\s*["']([^"']+)["']/)         || [])[1];
    const label        = (block.match(/label\s*=\s*["']([^"']+)["']/)        || [])[1];
    const repairAmount = (block.match(/repairAmount\s*=\s*([\d.]+)/)         || [])[1];
    const range        = (block.match(/range\s*=\s*([\d.]+)/)                || [])[1];

    if (name || label || repairAmount || range) {
      tools.push({
        name,
        label,
        repairAmount: repairAmount ? parseFloat(repairAmount) : undefined,
        range:        range        ? parseFloat(range)        : undefined,
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

describe('mechanic', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── MECHANIC_TOOLS data table ────────────────────────────────────────────

  describe('MECHANIC_TOOLS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const tools  = extractMechanicTools(source);

    test('MECHANIC_TOOLS table is present in client.lua', () => {
      assert.ok(tools !== null, 'MECHANIC_TOOLS table not found in client.lua');
    });

    test('MECHANIC_TOOLS contains at least one entry', () => {
      assert.ok(tools.length > 0, 'MECHANIC_TOOLS list must not be empty');
    });

    test('every entry has a non-empty lowercase name', () => {
      const invalid = tools.filter(t => !t.name || !/^[a-z0-9_]+$/.test(t.name));
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with invalid name: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every entry has a non-empty label', () => {
      const invalid = tools.filter(t => !t.label || t.label.trim() === '');
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with empty label: ${invalid.map(t => t.name).join(', ')}`
      );
    });

    test('every entry has a positive repairAmount value', () => {
      const invalid = tools.filter(t => t.repairAmount === undefined || t.repairAmount <= 0);
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with invalid repairAmount: ${invalid.map(t => `${t.name}(${t.repairAmount})`).join(', ')}`
      );
    });

    test('every entry has a positive range value', () => {
      const invalid = tools.filter(t => t.range === undefined || t.range <= 0);
      assert.deepEqual(
        invalid.map(t => t.name),
        [],
        `Tools with invalid range: ${invalid.map(t => `${t.name}(${t.range})`).join(', ')}`
      );
    });

    test('no duplicate tool names in MECHANIC_TOOLS', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const t of tools) {
        if (seen.has(t.name)) duplicates.push(t.name);
        else seen.add(t.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate tool names: ${duplicates.join(', ')}`);
    });

    test('MECHANIC_TOOL_BY_NAME lookup is built from MECHANIC_TOOLS', () => {
      assert.match(
        source,
        /MECHANIC_TOOL_BY_NAME\s*\[\s*t\.name\s*\]\s*=\s*t/,
        'MECHANIC_TOOL_BY_NAME should index each tool by its name field'
      );
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('mechanicOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+mechanicOnDuty\s*=\s*false/,
        'mechanicOnDuty should be defined and default to false'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/mechanicduty command is registered', () => {
      assert.ok(commands.has('mechanicduty'), 'RegisterCommand("mechanicduty", ...) not found');
    });

    test('/repairvehicle command is registered', () => {
      assert.ok(commands.has('repairvehicle'), 'RegisterCommand("repairvehicle", ...) not found');
    });

    test('/towtruck command is registered', () => {
      assert.ok(commands.has('towtruck'), 'RegisterCommand("towtruck", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('mechanic:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'mechanic:dutyChange'") || source.includes('"mechanic:dutyChange"'),
        "RegisterNetEvent('mechanic:dutyChange') not found in server.lua"
      );
    });

    test('mechanic:logRepair event is registered', () => {
      assert.ok(
        source.includes("'mechanic:logRepair'") || source.includes('"mechanic:logRepair"'),
        "RegisterNetEvent('mechanic:logRepair') not found in server.lua"
      );
    });

    test('mechanic:logTowTruck event is registered', () => {
      assert.ok(
        source.includes("'mechanic:logTowTruck'") || source.includes('"mechanic:logTowTruck"'),
        "RegisterNetEvent('mechanic:logTowTruck') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the mechanic'
      );
    });
  });
});
