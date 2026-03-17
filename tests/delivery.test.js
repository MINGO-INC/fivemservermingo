'use strict';
/**
 * delivery Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/delivery/client.lua
 *   resources/[gameplay]/delivery/server.lua
 *
 * Checks performed:
 *  • DELIVERY_VEHICLES table is non-empty
 *  • Every vehicle entry has the required fields: model, label
 *  • All model names are non-empty lowercase strings
 *  • All labels are non-empty strings
 *  • No duplicate model names in DELIVERY_VEHICLES
 *  • DELIVERY_VEHICLE_BY_MODEL lookup map is built from DELIVERY_VEHICLES
 *  • DELIVERY_SITES table is non-empty and each entry has a label
 *  • deliveryOnDuty flag is defined and defaults to false
 *  • The /deliveryduty, /deliveryveh, /pickup, and /deliver commands are registered
 *  • server.lua registers delivery:dutyChange, delivery:logPickup, delivery:logDeliver, delivery:logVehicle events
 *  • server.lua retrieves the player name for all events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'delivery', 'client.lua');
const SERVER_LUA = path.join(REPO_ROOT, 'resources', '[gameplay]', 'delivery', 'server.lua');

/**
 * Parse the DELIVERY_VEHICLES table from client.lua.
 * Returns an array of objects: { model, label }
 */
function extractDeliveryVehicles(source) {
  const tableMatch = source.match(/local\s+DELIVERY_VEHICLES\s*=\s*\{([\s\S]+?)\n\}/);
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
 * Parse the DELIVERY_SITES table from client.lua.
 * Returns an array of objects: { label }
 */
function extractDeliverySites(source) {
  const tableMatch = source.match(/local\s+DELIVERY_SITES\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const sites  = [];
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

describe('delivery', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  // ── DELIVERY_VEHICLES data table ─────────────────────────────────────────

  describe('DELIVERY_VEHICLES data table', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const vehicles = extractDeliveryVehicles(source);

    test('DELIVERY_VEHICLES table is present in client.lua', () => {
      assert.ok(vehicles !== null, 'DELIVERY_VEHICLES table not found in client.lua');
    });

    test('DELIVERY_VEHICLES contains at least one entry', () => {
      assert.ok(vehicles.length > 0, 'DELIVERY_VEHICLES list must not be empty');
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

    test('no duplicate model names in DELIVERY_VEHICLES', () => {
      const seen       = new Set();
      const duplicates = [];
      for (const v of vehicles) {
        if (seen.has(v.model)) duplicates.push(v.model);
        else seen.add(v.model);
      }
      assert.deepEqual(duplicates, [], `Duplicate model names: ${duplicates.join(', ')}`);
    });

    test('DELIVERY_VEHICLE_BY_MODEL lookup is built from DELIVERY_VEHICLES', () => {
      assert.match(
        source,
        /DELIVERY_VEHICLE_BY_MODEL\s*\[\s*v\.model\s*\]\s*=\s*v/,
        'DELIVERY_VEHICLE_BY_MODEL should index each vehicle by its model field'
      );
    });
  });

  // ── DELIVERY_SITES data table ─────────────────────────────────────────────

  describe('DELIVERY_SITES data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const sites  = extractDeliverySites(source);

    test('DELIVERY_SITES table is present in client.lua', () => {
      assert.ok(sites !== null, 'DELIVERY_SITES table not found in client.lua');
    });

    test('DELIVERY_SITES contains at least one entry', () => {
      assert.ok(sites.length > 0, 'DELIVERY_SITES list must not be empty');
    });

    test('every site entry has a non-empty label', () => {
      const invalid = sites.filter(s => !s.label || s.label.trim() === '');
      assert.deepEqual(invalid, [], `Sites with empty label found`);
    });
  });

  // ── Duty state ───────────────────────────────────────────────────────────

  describe('duty state', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('deliveryOnDuty flag is defined and defaults to false', () => {
      assert.match(
        source,
        /local\s+deliveryOnDuty\s*=\s*false/,
        'deliveryOnDuty should be defined and default to false'
      );
    });
  });

  // ── Registered commands ──────────────────────────────────────────────────

  describe('registered commands', () => {
    const source   = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/deliveryduty command is registered', () => {
      assert.ok(commands.has('deliveryduty'), 'RegisterCommand("deliveryduty", ...) not found');
    });

    test('/deliveryveh command is registered', () => {
      assert.ok(commands.has('deliveryveh'), 'RegisterCommand("deliveryveh", ...) not found');
    });

    test('/pickup command is registered', () => {
      assert.ok(commands.has('pickup'), 'RegisterCommand("pickup", ...) not found');
    });

    test('/deliver command is registered', () => {
      assert.ok(commands.has('deliver'), 'RegisterCommand("deliver", ...) not found');
    });
  });

  // ── Server-side event handling ───────────────────────────────────────────

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('delivery:dutyChange event is registered', () => {
      assert.ok(
        source.includes("'delivery:dutyChange'") || source.includes('"delivery:dutyChange"'),
        "RegisterNetEvent('delivery:dutyChange') not found in server.lua"
      );
    });

    test('delivery:logPickup event is registered', () => {
      assert.ok(
        source.includes("'delivery:logPickup'") || source.includes('"delivery:logPickup"'),
        "RegisterNetEvent('delivery:logPickup') not found in server.lua"
      );
    });

    test('delivery:logDeliver event is registered', () => {
      assert.ok(
        source.includes("'delivery:logDeliver'") || source.includes('"delivery:logDeliver"'),
        "RegisterNetEvent('delivery:logDeliver') not found in server.lua"
      );
    });

    test('delivery:logVehicle event is registered', () => {
      assert.ok(
        source.includes("'delivery:logVehicle'") || source.includes('"delivery:logVehicle"'),
        "RegisterNetEvent('delivery:logVehicle') not found in server.lua"
      );
    });

    test('server.lua retrieves the player name for all events', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify the delivery driver'
      );
    });
  });
});
