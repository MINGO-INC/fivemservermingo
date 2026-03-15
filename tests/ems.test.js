'use strict';
/**
 * ems Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/ems/client.lua
 *   resources/[gameplay]/ems/server.lua
 *
 * Checks performed:
 *  • EMS_ITEMS table is non-empty
 *  • Every item entry has the required fields: name, label, heal, range
 *  • All item names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • All heal values are positive integers (1–100)
 *  • All range values are positive floats
 *  • No duplicate item names in EMS_ITEMS
 *  • EMS_ITEM_BY_NAME and EMS_ITEM_BY_LABEL lookup maps are built from EMS_ITEMS
 *  • emsOnDuty flag is defined and defaults to false
 *  • The /emsduty, /revive, /heal, and /ambulance commands are registered
 *  • server.lua registers ems:dutyChange, ems:logRevive, ems:logHeal, ems:logAmbulance events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'ems', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'ems', 'server.lua');

/**
 * Parse the EMS_ITEMS table from client.lua.
 * Returns an array of objects: { name, label, heal, range }
 */
function extractEmsItems(source) {
  const tableMatch = source.match(/local\s+EMS_ITEMS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const items = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name  = (block.match(/name\s*=\s*["']([^"']+)["']/)  || [])[1];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    const heal  = (block.match(/heal\s*=\s*(\d+)/)             || [])[1];
    const range = (block.match(/range\s*=\s*([\d.]+)/)         || [])[1];

    if (name || label || heal || range) {
      items.push({
        name,
        label,
        heal:  heal  ? parseInt(heal, 10)   : undefined,
        range: range ? parseFloat(range)    : undefined,
      });
    }
  }
  return items.length > 0 ? items : null;
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

describe('ems', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── EMS_ITEMS data table ─────────────────────────────────────────────────

  describe('EMS_ITEMS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const items  = extractEmsItems(source);

    test('EMS_ITEMS table is present in client.lua', () => {
      assert.ok(items !== null, 'EMS_ITEMS table not found in client.lua');
    });

    test('EMS_ITEMS contains at least one entry', () => {
      assert.ok(items.length > 0, 'EMS_ITEMS list must not be empty');
    });

    test('every entry has a non-empty lowercase name', () => {
      const invalid = items.filter(i => !i.name || !/^[a-z0-9_]+$/.test(i.name));
      assert.deepEqual(
        invalid.map(i => i.name),
        [],
        `Items with invalid name: ${invalid.map(i => i.name).join(', ')}`
      );
    });

    test('every entry has a non-empty label', () => {
      const invalid = items.filter(i => !i.label || i.label.trim() === '');
      assert.deepEqual(
        invalid.map(i => i.name),
        [],
        `Items with empty label: ${invalid.map(i => i.name).join(', ')}`
      );
    });

    test('every entry has a heal value in range [1, 100]', () => {
      const invalid = items.filter(i => i.heal === undefined || i.heal < 1 || i.heal > 100);
      assert.deepEqual(
        invalid.map(i => i.name),
        [],
        `Items with invalid heal: ${invalid.map(i => `${i.name}(${i.heal})`).join(', ')}`
      );
    });

    test('every entry has a positive range value', () => {
      const invalid = items.filter(i => i.range === undefined || i.range <= 0);
      assert.deepEqual(
        invalid.map(i => i.name),
        [],
        `Items with invalid range: ${invalid.map(i => `${i.name}(${i.range})`).join(', ')}`
      );
    });

    test('no duplicate item names in EMS_ITEMS', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const i of items) {
        if (seen.has(i.name)) duplicates.push(i.name);
        else seen.add(i.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate item names: ${duplicates.join(', ')}`);
    });

    test('EMS_ITEM_BY_NAME lookup is built from EMS_ITEMS', () => {
      assert.match(
        source,
        /EMS_ITEM_BY_NAME\s*\[\s*item\.name\s*\]\s*=\s*item/,
        'EMS_ITEM_BY_NAME should index each item by its name field'
      );
    });

    test('EMS_ITEM_BY_LABEL lookup is built from EMS_ITEMS', () => {
      assert.match(
        source,
        /EMS_ITEM_BY_LABEL\s*\[\s*string\.lower\s*\(\s*item\.label\s*\)\s*\]\s*=\s*item/,
        'EMS_ITEM_BY_LABEL should index each item by its lowercase label'
      );
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('emsOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+emsOnDuty\s*=\s*false/,
        'emsOnDuty should be defined and default to false'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/emsduty command is registered', () => {
      assert.ok(commands.has('emsduty'), 'RegisterCommand("emsduty", ...) not found');
    });

    test('/revive command is registered', () => {
      assert.ok(commands.has('revive'), 'RegisterCommand("revive", ...) not found');
    });

    test('/heal command is registered', () => {
      assert.ok(commands.has('heal'), 'RegisterCommand("heal", ...) not found');
    });

    test('/ambulance command is registered', () => {
      assert.ok(commands.has('ambulance'), 'RegisterCommand("ambulance", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('ems:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'ems:dutyChange'") || source.includes('"ems:dutyChange"'),
        "RegisterNetEvent('ems:dutyChange') not found in server.lua"
      );
    });

    test('ems:logRevive event is registered', () => {
      assert.ok(
        source.includes("'ems:logRevive'") || source.includes('"ems:logRevive"'),
        "RegisterNetEvent('ems:logRevive') not found in server.lua"
      );
    });

    test('ems:logHeal event is registered', () => {
      assert.ok(
        source.includes("'ems:logHeal'") || source.includes('"ems:logHeal"'),
        "RegisterNetEvent('ems:logHeal') not found in server.lua"
      );
    });

    test('ems:logAmbulance event is registered', () => {
      assert.ok(
        source.includes("'ems:logAmbulance'") || source.includes('"ems:logAmbulance"'),
        "RegisterNetEvent('ems:logAmbulance') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the EMS worker'
      );
    });
  });
});
