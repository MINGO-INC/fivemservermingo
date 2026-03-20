'use strict';
/**
 * frkn-text Resource Tests
 *
 * Validates the integrity of the frkn-text interactive text UI resource:
 *   resources/[gameplay]/frkn-text/
 *
 * Checks performed:
 *  • Core files exist: fxmanifest.lua, config.lua, client/client.lua, html/index.html
 *  • FRKN config table defines vehicleControl, carDistance, and colorData themes
 *  • colorData has blue, white, and pink themes each with a background key
 *  • openTextUi and closeTextUi exports are defined
 *  • Vehicle events: useVehicle, lockVehicle, unlockVehicle, openvehicledoor, closevehicledoor
 *  • NUI callbacks: enter, exit
 *  • CreateThread and Vdist used for distance-based rendering
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const RES_DIR    = path.join(REPO_ROOT, 'resources', '[gameplay]', 'frkn-text');
const MANIFEST   = path.join(RES_DIR, 'fxmanifest.lua');
const CONFIG_LUA = path.join(RES_DIR, 'config.lua');
const CLIENT_LUA = path.join(RES_DIR, 'client', 'client.lua');
const UI_HTML    = path.join(RES_DIR, 'html', 'index.html');

// ── Tests ────────────────────────────────────────────────────────────────────

describe('frkn-text', () => {

  // ── File existence ──────────────────────────────────────────────────────

  test('fxmanifest.lua exists', () => {
    assert.ok(fs.existsSync(MANIFEST), `Missing: ${path.relative(REPO_ROOT, MANIFEST)}`);
  });

  test('config.lua exists', () => {
    assert.ok(fs.existsSync(CONFIG_LUA), `Missing: ${path.relative(REPO_ROOT, CONFIG_LUA)}`);
  });

  test('client/client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('html/index.html exists', () => {
    assert.ok(fs.existsSync(UI_HTML), `Missing: ${path.relative(REPO_ROOT, UI_HTML)}`);
  });

  // ── FRKN config table ───────────────────────────────────────────────────

  describe('FRKN config table', () => {
    const source = fs.readFileSync(CONFIG_LUA, 'utf8');

    test('FRKN table is defined', () => {
      assert.match(source, /FRKN\s*=\s*\{/, 'FRKN config table must be defined');
    });

    test('vehicleControl is defined', () => {
      assert.ok(source.includes('vehicleControl'), 'FRKN.vehicleControl must be defined');
    });

    test('carDistance is a positive number', () => {
      const match = source.match(/carDistance\s*=\s*([\d.]+)/);
      assert.ok(match, 'FRKN.carDistance must be defined');
      assert.ok(parseFloat(match[1]) > 0, `carDistance must be > 0, got ${match[1]}`);
    });

    test('colorData contains a blue theme', () => {
      assert.ok(source.includes('blue'), 'FRKN.colorData must include a blue theme');
    });

    test('colorData contains a white theme', () => {
      assert.ok(source.includes('white'), 'FRKN.colorData must include a white theme');
    });

    test('colorData contains a pink theme', () => {
      assert.ok(source.includes('pink'), 'FRKN.colorData must include a pink theme');
    });

    test('each color theme defines a background key', () => {
      const count = (source.match(/background\s*=/g) || []).length;
      assert.ok(count >= 3, `Expected at least 3 color themes with a background key, found ${count}`);
    });
  });

  // ── Exports ─────────────────────────────────────────────────────────────

  describe('exports', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('openTextUi export is defined', () => {
      assert.match(
        source,
        /exports\s*\(\s*["']openTextUi["']/,
        'openTextUi must be exported'
      );
    });

    test('closeTextUi export is defined', () => {
      assert.match(
        source,
        /exports\s*\(\s*["']closeTextUi["']/,
        'closeTextUi must be exported'
      );
    });
  });

  // ── Vehicle events ──────────────────────────────────────────────────────

  describe('vehicle events', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('useVehicle event is registered', () => {
      assert.ok(
        source.includes("'useVehicle'") || source.includes('"useVehicle"'),
        'useVehicle event must be registered'
      );
    });

    test('lockVehicle event is registered', () => {
      assert.ok(
        source.includes("'lockVehicle'") || source.includes('"lockVehicle"'),
        'lockVehicle event must be registered'
      );
    });

    test('unlockVehicle event is registered', () => {
      assert.ok(
        source.includes("'unlockVehicle'") || source.includes('"unlockVehicle"'),
        'unlockVehicle event must be registered'
      );
    });

    test('openvehicledoor event is registered', () => {
      assert.ok(
        source.includes("'openvehicledoor'") || source.includes('"openvehicledoor"'),
        'openvehicledoor event must be registered'
      );
    });

    test('closevehicledoor event is registered', () => {
      assert.ok(
        source.includes("'closevehicledoor'") || source.includes('"closevehicledoor"'),
        'closevehicledoor event must be registered'
      );
    });
  });

  // ── NUI callbacks ───────────────────────────────────────────────────────

  describe('NUI callbacks', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('enter NUI callback is registered', () => {
      assert.ok(
        source.includes('"enter"') || source.includes("'enter'"),
        'enter NUI callback must be registered'
      );
      assert.ok(source.includes('RegisterNUICallback'), 'RegisterNUICallback must be used');
    });

    test('exit NUI callback is registered', () => {
      assert.ok(
        source.includes('"exit"') || source.includes("'exit'"),
        'exit NUI callback must be registered'
      );
    });
  });

  // ── Distance-based rendering ────────────────────────────────────────────

  describe('distance-based rendering', () => {
    const source = fs.readFileSync(CLIENT_LUA, 'utf8');

    test('CreateThread is used for distance polling', () => {
      assert.ok(
        source.includes('Citizen.CreateThread') || source.includes('CreateThread'),
        'CreateThread must be used for distance-based proximity polling'
      );
    });

    test('Vdist is used to calculate distance to object', () => {
      assert.ok(source.includes('Vdist'), 'Vdist must be used for distance calculation');
    });
  });
});
