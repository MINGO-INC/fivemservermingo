'use strict';
/**
 * trucker Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/trucker/client.lua
 *   resources/[gameplay]/trucker/server.lua
 *
 * Checks performed:
 *  • TRUCKER_VEHICLES table is non-empty
 *  • Every vehicle entry has the required fields: model, label
 *  • All model names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • No duplicate model names in TRUCKER_VEHICLES
 *  • TRUCKER_VEHICLE_BY_MODEL lookup map is built from TRUCKER_VEHICLES
 *  • TRUCKER_SITES table is non-empty and each entry has a label
 *  • truckerOnDuty flag is defined and defaults to false
 *  • The /truckerduty, /truckerveh, /loadcargo, and /delivercargo commands are registered
 *  • server.lua registers trucker:dutyChange, trucker:logLoadCargo, trucker:logDeliverCargo, trucker:logVehicle events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'trucker', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'trucker', 'server.lua');

/**
 * Parse the TRUCKER_VEHICLES table from client.lua.
 * Returns an array of objects: { model, label }
 */
function extractTruckerVehicles(source) {
  const tableMatch = source.match(/local\s+TRUCKER_VEHICLES\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const vehicles = [];
  const entryRe  = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const model = (block.match(/model\s*=\s*["']([^"']+)["']/) || [])[1];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];

    if (model || label) {
      vehicles.push({ model, label });
    }
  }
  return vehicles.length > 0 ? vehicles : null;
}

/**
 * Parse the TRUCKER_SITES table from client.lua.
 * Returns an array of objects: { label }
 */
function extractTruckerSites(source) {
  const tableMatch = source.match(/local\s+TRUCKER_SITES\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const sites   = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const label = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    if (label) sites.push({ label });
  }
  return sites.length > 0 ? sites : null;
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

describe('trucker', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── TRUCKER_VEHICLES data table ──────────────────────────────────────────

  describe('TRUCKER_VEHICLES data table', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const vehicles = extractTruckerVehicles(source);

    test('TRUCKER_VEHICLES table is present in client.lua', () => {
      assert.ok(vehicles !== null, 'TRUCKER_VEHICLES table not found in client.lua');
    });

    test('TRUCKER_VEHICLES contains at least one entry', () => {
      assert.ok(vehicles.length > 0, 'TRUCKER_VEHICLES list must not be empty');
    });

    test('every entry has a non-empty lowercase model name', () => {
      const invalid = vehicles.filter(v => !v.model || !/^[a-z0-9_]+$/.test(v.model));
      assert.deepEqual(
        invalid.map(v => v.model),
        [],
        `Vehicles with invalid model name: ${invalid.map(v => v.model).join(', ')}`
      );
    });

    test('every entry has a non-empty label', () => {
      const invalid = vehicles.filter(v => !v.label || v.label.trim() === '');
      assert.deepEqual(
        invalid.map(v => v.model),
        [],
        `Vehicles with empty label: ${invalid.map(v => v.model).join(', ')}`
      );
    });

    test('no duplicate model names in TRUCKER_VEHICLES', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const v of vehicles) {
        if (seen.has(v.model)) duplicates.push(v.model);
        else seen.add(v.model);
      }
      assert.deepEqual(duplicates, [], `Duplicate model names: ${duplicates.join(', ')}`);
    });

    test('TRUCKER_VEHICLE_BY_MODEL lookup is built from TRUCKER_VEHICLES', () => {
      assert.match(
        source,
        /TRUCKER_VEHICLE_BY_MODEL\s*\[\s*v\.model\s*\]\s*=\s*v/,
        'TRUCKER_VEHICLE_BY_MODEL should index each vehicle by its model field'
      );
    });
  });

  // ── TRUCKER_SITES data table ──────────────────────────────────────────────

  describe('TRUCKER_SITES data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const sites  = extractTruckerSites(source);

    test('TRUCKER_SITES table is present in client.lua', () => {
      assert.ok(sites !== null, 'TRUCKER_SITES table not found in client.lua');
    });

    test('TRUCKER_SITES contains at least one entry', () => {
      assert.ok(sites.length > 0, 'TRUCKER_SITES list must not be empty');
    });

    test('every site entry has a non-empty label', () => {
      const invalid = sites.filter(s => !s.label || s.label.trim() === '');
      assert.deepEqual(invalid, [], 'Sites with empty label found');
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('truckerOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+truckerOnDuty\s*=\s*false/,
        'truckerOnDuty should be defined and default to false'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/truckerduty command is registered', () => {
      assert.ok(commands.has('truckerduty'), 'RegisterCommand("truckerduty", ...) not found');
    });

    test('/truckerveh command is registered', () => {
      assert.ok(commands.has('truckerveh'), 'RegisterCommand("truckerveh", ...) not found');
    });

    test('/loadcargo command is registered', () => {
      assert.ok(commands.has('loadcargo'), 'RegisterCommand("loadcargo", ...) not found');
    });

    test('/delivercargo command is registered', () => {
      assert.ok(commands.has('delivercargo'), 'RegisterCommand("delivercargo", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('trucker:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'trucker:dutyChange'") || source.includes('"trucker:dutyChange"'),
        "RegisterNetEvent('trucker:dutyChange') not found in server.lua"
      );
    });

    test('trucker:logLoadCargo event is registered', () => {
      assert.ok(
        source.includes("'trucker:logLoadCargo'") || source.includes('"trucker:logLoadCargo"'),
        "RegisterNetEvent('trucker:logLoadCargo') not found in server.lua"
      );
    });

    test('trucker:logDeliverCargo event is registered', () => {
      assert.ok(
        source.includes("'trucker:logDeliverCargo'") || source.includes('"trucker:logDeliverCargo"'),
        "RegisterNetEvent('trucker:logDeliverCargo') not found in server.lua"
      );
    });

    test('trucker:logVehicle event is registered', () => {
      assert.ok(
        source.includes("'trucker:logVehicle'") || source.includes('"trucker:logVehicle"'),
        "RegisterNetEvent('trucker:logVehicle') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the trucker'
      );
    });
  });
});
