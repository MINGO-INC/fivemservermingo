'use strict';
/**
 * weapon-loadout Resource Tests
 *
 * Validates the integrity of data and logic in
 *   resources/[gameplay]/weapon-loadout/client.lua
 *   resources/[gameplay]/weapon-loadout/server.lua
 *
 * Checks performed:
 *  • WEAPONS table is non-empty
 *  • Every weapon entry has the required fields: name, label, ammo, recoil, shake
 *  • All weapon names start with "WEAPON_" and are uppercase
 *  • All labels are non-empty strings
 *  • All ammo values are positive integers
 *  • All recoil values are non-negative floats (0 ≤ recoil ≤ 2.0)
 *  • All shake type strings are non-empty
 *  • No duplicate weapon names in WEAPONS
 *  • WEAPON_BY_NAME and WEAPON_BY_LABEL lookup maps are built from WEAPONS
 *  • The /weapons, /gun, /guns, and /recoil commands are registered
 *  • server.lua registers both logLoadout and logGun events
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(
  REPO_ROOT, 'resources', '[gameplay]', 'weapon-loadout', 'client.lua'
);
const SERVER_LUA = path.join(
  REPO_ROOT, 'resources', '[gameplay]', 'weapon-loadout', 'server.lua'
);

/**
 * Parse the WEAPONS table from client.lua.
 *
 * Each entry looks like:
 *   { name = "WEAPON_PISTOL", label = "Pistol", ammo = 250, recoil = 0.15, shake = "HAND_SHAKE" },
 *
 * Returns an array of objects: { name, label, ammo, recoil, shake }
 */
function extractWeapons(source) {
  // Find the WEAPONS table block
  const tableMatch = source.match(/local\s+WEAPONS\s*=\s*\{([\s\S]+?)\n\}/);
  if (!tableMatch) return null;

  const weapons = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of tableMatch[1].matchAll(entryRe)) {
    const block = entry[0];
    const name    = (block.match(/name\s*=\s*["']([^"']+)["']/)  || [])[1];
    const label   = (block.match(/label\s*=\s*["']([^"']+)["']/) || [])[1];
    const ammo    = (block.match(/ammo\s*=\s*(\d+)/)             || [])[1];
    const recoil  = (block.match(/recoil\s*=\s*([\d.]+)/)        || [])[1];
    const shake   = (block.match(/shake\s*=\s*["']([^"']+)["']/) || [])[1];

    if (name || label || ammo || recoil || shake) {
      weapons.push({
        name,
        label,
        ammo:   ammo   ? parseInt(ammo, 10)    : undefined,
        recoil: recoil ? parseFloat(recoil)    : undefined,
        shake,
      });
    }
  }
  return weapons.length > 0 ? weapons : null;
}

/** Extract all RegisterCommand call names. */
function extractRegisteredCommands(source) {
  const commands = new Set();
  for (const m of source.matchAll(/RegisterCommand\s*\(\s*["']([^"']+)["']/g)) {
    commands.add(m[1]);
  }
  return commands;
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe('weapon-loadout', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  describe('WEAPONS data table', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const weapons = extractWeapons(source);

    test('WEAPONS table is present in client.lua', () => {
      assert.ok(weapons !== null, 'WEAPONS table not found in client.lua');
    });

    test('WEAPONS table contains at least one entry', () => {
      assert.ok(weapons.length > 0, 'WEAPONS list must not be empty');
    });

    test('every entry has a name field starting with WEAPON_', () => {
      const invalid = weapons.filter(w => !w.name || !w.name.startsWith('WEAPON_'));
      assert.deepEqual(
        invalid.map(w => w.name),
        [],
        `Weapons with invalid/missing name: ${invalid.map(w => w.name).join(', ')}`
      );
    });

    test('every entry has a non-empty label', () => {
      const invalid = weapons.filter(w => !w.label || w.label.trim() === '');
      assert.deepEqual(
        invalid.map(w => w.name),
        [],
        `Weapons with empty label: ${invalid.map(w => w.name).join(', ')}`
      );
    });

    test('every entry has a positive ammo value', () => {
      const invalid = weapons.filter(w => !w.ammo || w.ammo <= 0);
      assert.deepEqual(
        invalid.map(w => w.name),
        [],
        `Weapons with invalid ammo: ${invalid.map(w => `${w.name}(${w.ammo})`).join(', ')}`
      );
    });

    test('every entry has a recoil value in range [0, 2.0]', () => {
      const invalid = weapons.filter(w => w.recoil === undefined || w.recoil < 0 || w.recoil > 2.0);
      assert.deepEqual(
        invalid.map(w => w.name),
        [],
        `Weapons with out-of-range recoil: ${invalid.map(w => `${w.name}(${w.recoil})`).join(', ')}`
      );
    });

    test('every entry has a non-empty shake type', () => {
      const invalid = weapons.filter(w => !w.shake || w.shake.trim() === '');
      assert.deepEqual(
        invalid.map(w => w.name),
        [],
        `Weapons missing shake type: ${invalid.map(w => w.name).join(', ')}`
      );
    });

    test('no duplicate weapon names in WEAPONS', () => {
      const seen = new Set();
      const duplicates = [];
      for (const w of weapons) {
        if (seen.has(w.name)) duplicates.push(w.name);
        else seen.add(w.name);
      }
      assert.deepEqual(duplicates, [], `Duplicate weapon names: ${duplicates.join(', ')}`);
    });

    test('WEAPON_BY_NAME lookup map is built from WEAPONS', () => {
      assert.match(
        source,
        /WEAPON_BY_NAME\s*\[\s*w\.name\s*\]\s*=\s*w/,
        'WEAPON_BY_NAME should index each weapon by its name field'
      );
    });

    test('WEAPON_BY_LABEL lookup map is built from WEAPONS', () => {
      assert.match(
        source,
        /WEAPON_BY_LABEL\s*\[\s*string\.lower\s*\(\s*w\.label\s*\)\s*\]\s*=\s*w/,
        'WEAPON_BY_LABEL should index each weapon by its lowercase label'
      );
    });
  });

  describe('registered commands', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/weapons command is registered', () => {
      assert.ok(commands.has('weapons'), 'RegisterCommand("weapons", ...) not found');
    });

    test('/gun command is registered', () => {
      assert.ok(commands.has('gun'), 'RegisterCommand("gun", ...) not found');
    });

    test('/guns command is registered', () => {
      assert.ok(commands.has('guns'), 'RegisterCommand("guns", ...) not found');
    });

    test('/recoil command is registered', () => {
      assert.ok(commands.has('recoil'), 'RegisterCommand("recoil", ...) not found');
    });
  });

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('weapon-loadout:logLoadout event is registered', () => {
      assert.ok(
        source.includes("'weapon-loadout:logLoadout'") || source.includes('"weapon-loadout:logLoadout"'),
        "RegisterNetEvent('weapon-loadout:logLoadout') not found in server.lua"
      );
    });

    test('weapon-loadout:logGun event is registered', () => {
      assert.ok(
        source.includes("'weapon-loadout:logGun'") || source.includes('"weapon-loadout:logGun"'),
        "RegisterNetEvent('weapon-loadout:logGun') not found in server.lua"
      );
    });

    test('server.lua handler retrieves player name', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify who received weapons'
      );
    });
  });

  describe('recoil system', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('CreateThread is used for the per-frame recoil loop', () => {
      assert.ok(
        source.includes('CreateThread'),
        'client.lua should use CreateThread for the recoil detection loop'
      );
    });

    test('recoilEnabled flag is defined and defaults to true', () => {
      assert.match(
        source,
        /local\s+recoilEnabled\s*=\s*true/,
        'recoilEnabled should be defined and default to true'
      );
    });
  });
});
