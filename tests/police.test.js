'use strict';
/**
 * police Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/police/client.lua
 *   resources/[gameplay]/police/server.lua
 *
 * Checks performed:
 *  • POLICE_VEHICLES table is non-empty
 *  • Every vehicle entry has the required fields: model, label
 *  • All model names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • No duplicate model names in POLICE_VEHICLES
 *  • POLICE_VEHICLE_BY_MODEL lookup map is built from POLICE_VEHICLES
 *  • policeOnDuty flag is defined and defaults to false
 *  • The /policeduty, /cuff, /uncuff, /patrolcar, and /spike commands are registered
 *  • server.lua registers police:dutyChange, police:logCuff, police:logPatrolCar, police:logSpike events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'police', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'police', 'server.lua');

/**
 * Parse the POLICE_VEHICLES table from client.lua.
 * Returns an array of objects: { model, label }
 */
function extractPoliceVehicles(source) {
  const tableMatch = source.match(/local\s+POLICE_VEHICLES\s*=\s*\{([\s\S]+?)\n\}/);
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

/** Extract all RegisterCommand call names from a Lua source string. */
function extractRegisteredCommands(source) {
  const commands = new Set();
  for (const m of source.matchAll(/RegisterCommand\s*\(\s*["']([^"']+)["']/g)) {
    commands.add(m[1]);
  }
  return commands;
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe('police', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── POLICE_VEHICLES data table ───────────────────────────────────────────

  describe('POLICE_VEHICLES data table', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const vehicles = extractPoliceVehicles(source);

    test('POLICE_VEHICLES table is present in client.lua', () => {
      assert.ok(vehicles !== null, 'POLICE_VEHICLES table not found in client.lua');
    });

    test('POLICE_VEHICLES contains at least one entry', () => {
      assert.ok(vehicles.length > 0, 'POLICE_VEHICLES list must not be empty');
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

    test('no duplicate model names in POLICE_VEHICLES', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const v of vehicles) {
        if (seen.has(v.model)) duplicates.push(v.model);
        else seen.add(v.model);
      }
      assert.deepEqual(duplicates, [], `Duplicate model names: ${duplicates.join(', ')}`);
    });

    test('POLICE_VEHICLE_BY_MODEL lookup is built from POLICE_VEHICLES', () => {
      assert.match(
        source,
        /POLICE_VEHICLE_BY_MODEL\s*\[\s*v\.model\s*\]\s*=\s*v/,
        'POLICE_VEHICLE_BY_MODEL should index each vehicle by its model field'
      );
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('policeOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+policeOnDuty\s*=\s*false/,
        'policeOnDuty should be defined and default to false'
      );
    });

    test('cuffedPlayers table is defined', () => {
      assert.match(
        source,
        /local\s+cuffedPlayers\s*=\s*\{\}/,
        'cuffedPlayers should be defined as an empty table'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/policeduty command is registered', () => {
      assert.ok(commands.has('policeduty'), 'RegisterCommand("policeduty", ...) not found');
    });

    test('/cuff command is registered', () => {
      assert.ok(commands.has('cuff'), 'RegisterCommand("cuff", ...) not found');
    });

    test('/uncuff command is registered', () => {
      assert.ok(commands.has('uncuff'), 'RegisterCommand("uncuff", ...) not found');
    });

    test('/patrolcar command is registered', () => {
      assert.ok(commands.has('patrolcar'), 'RegisterCommand("patrolcar", ...) not found');
    });

    test('/spike command is registered', () => {
      assert.ok(commands.has('spike'), 'RegisterCommand("spike", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('police:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'police:dutyChange'") || source.includes('"police:dutyChange"'),
        "RegisterNetEvent('police:dutyChange') not found in server.lua"
      );
    });

    test('police:logCuff event is registered', () => {
      assert.ok(
        source.includes("'police:logCuff'") || source.includes('"police:logCuff"'),
        "RegisterNetEvent('police:logCuff') not found in server.lua"
      );
    });

    test('police:logPatrolCar event is registered', () => {
      assert.ok(
        source.includes("'police:logPatrolCar'") || source.includes('"police:logPatrolCar"'),
        "RegisterNetEvent('police:logPatrolCar') not found in server.lua"
      );
    });

    test('police:logSpike event is registered', () => {
      assert.ok(
        source.includes("'police:logSpike'") || source.includes('"police:logSpike"'),
        "RegisterNetEvent('police:logSpike') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the officer'
      );
    });
  });
});
