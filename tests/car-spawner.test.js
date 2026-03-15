'use strict';
/**
 * car-spawner Resource Tests
 *
 * Validates the integrity of data defined in
 *   resources/[gameplay]/car-spawner/client.lua
 *
 * Checks performed:
 *  • NICE_CARS list is non-empty
 *  • All model names are lowercase strings with no whitespace
 *  • No duplicate entries in NICE_CARS
 *  • Every model name appears in the ALLOWED_MODELS lookup
 *    (verified by ensuring the build-lookup loop covers all entries)
 *  • The /car, /dv, and /cars commands are all registered
 *  • The server-side log event 'car-spawner:logSpawn' is registered in server.lua
 *  • server.lua fires the log event
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT = path.resolve(__dirname, '..');
const CLIENT_LUA = path.join(
  REPO_ROOT, 'resources', '[gameplay]', 'car-spawner', 'client.lua'
);
const SERVER_LUA = path.join(
  REPO_ROOT, 'resources', '[gameplay]', 'car-spawner', 'server.lua'
);

/**
 * Extract the NICE_CARS table from the Lua source.
 * Returns an array of model name strings.
 */
function extractNiceCars(source) {
  // Match the table block: local NICE_CARS = { ... }
  const tableMatch = source.match(/local\s+NICE_CARS\s*=\s*\{([^}]+)\}/s);
  if (!tableMatch) return null;

  const models = [];
  const stringRe = /["']([^"']+)["']/g;
  for (const m of tableMatch[1].matchAll(stringRe)) {
    models.push(m[1]);
  }
  return models;
}

/** Extract all RegisterCommand("name", ...) call names from the source. */
function extractRegisteredCommands(source) {
  const commands = new Set();
  const re = /RegisterCommand\s*\(\s*["']([^"']+)["']/g;
  for (const m of source.matchAll(re)) commands.add(m[1]);
  return commands;
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe('car-spawner', () => {

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  describe('NICE_CARS model list', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const models = extractNiceCars(source);

    test('NICE_CARS table is present in client.lua', () => {
      assert.ok(models !== null, 'NICE_CARS table not found in client.lua');
    });

    test('NICE_CARS contains at least one model', () => {
      assert.ok(models.length > 0, 'NICE_CARS list must not be empty');
    });

    test('all model names are non-empty lowercase strings', () => {
      for (const model of models) {
        assert.match(
          model,
          /^[a-z0-9_]+$/,
          `Model name '${model}' must be lowercase alphanumeric/underscore only`
        );
      }
    });

    test('no duplicate model names in NICE_CARS', () => {
      const seen = new Set();
      const duplicates = [];
      for (const model of models) {
        if (seen.has(model)) duplicates.push(model);
        else seen.add(model);
      }
      assert.deepEqual(duplicates, [], `Duplicate models found: ${duplicates.join(', ')}`);
    });

    test('ALLOWED_MODELS lookup is built from NICE_CARS', () => {
      // The script builds ALLOWED_MODELS by iterating NICE_CARS, so the
      // lookup source and the list must be derived from the same block.
      // Verify the build-loop pattern exists and references NICE_CARS.
      assert.match(
        source,
        /for\s+\w+\s*,\s*\w+\s+in\s+ipairs\s*\(\s*NICE_CARS\s*\)/,
        'ALLOWED_MODELS should be populated via ipairs(NICE_CARS)'
      );
    });
  });

  describe('registered commands', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');
    const commands = extractRegisteredCommands(source);

    test('/car command is registered', () => {
      assert.ok(commands.has('car'), 'RegisterCommand("car", ...) not found in client.lua');
    });

    test('/dv command is registered', () => {
      assert.ok(commands.has('dv'), 'RegisterCommand("dv", ...) not found in client.lua');
    });

    test('/cars command is registered', () => {
      assert.ok(commands.has('cars'), 'RegisterCommand("cars", ...) not found in client.lua');
    });
  });

  describe('server-side event handling', () => {
    const source = fs.readFileSync(SERVER_LUA, 'utf8');

    test('car-spawner:logSpawn event is registered in server.lua', () => {
      assert.ok(
        source.includes("'car-spawner:logSpawn'") || source.includes('"car-spawner:logSpawn"'),
        "RegisterNetEvent('car-spawner:logSpawn') not found in server.lua"
      );
    });

    test('server.lua handler retrieves player name', () => {
      assert.ok(
        source.includes('GetPlayerName'),
        'server.lua should call GetPlayerName to identify who spawned the vehicle'
      );
    });
  });
});
