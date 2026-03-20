'use strict';
/**
 * 0r-drugbusiness Resource Tests
 *
 * Validates the integrity of the 0r-drugbusiness resource:
 *   resources/[gameplay]/0r-drugbusiness/
 *
 * Checks performed:
 *  • Core files exist: fxmanifest.lua, config.lua, client.lua, server.lua, database.sql
 *  • fxmanifest declares cerulean, gta5, ui_page, ox_lib + oxmysql deps
 *  • Config.BusinessTypes has weed, cocaine, meth entries with label, price, requiredLevel
 *  • Config.PackagedProduct.maxStock is a positive integer
 *  • Packaged item names defined for weed, cocaine, meth
 *  • Config.RawMaterials.vehicleUpgrades has at least one entry
 *  • Config.Labs defines weed, cocaine, meth lab configs
 *  • Config.MoneyWashing.upgrades defines at least one upgrade tier
 *  • database.sql contains at least one CREATE TABLE statement
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT  = path.resolve(__dirname, '..');
const RES_DIR    = path.join(REPO_ROOT, 'resources', '[gameplay]', '0r-drugbusiness');
const MANIFEST   = path.join(RES_DIR, 'fxmanifest.lua');
const CONFIG_LUA = path.join(RES_DIR, 'config.lua');
const CLIENT_LUA = path.join(RES_DIR, 'client.lua');
const SERVER_LUA = path.join(RES_DIR, 'server.lua');
const DB_SQL     = path.join(RES_DIR, 'database.sql');

/**
 * Parse Config.BusinessTypes entries from config.lua.
 * Returns an array of { key, label, level, price }.
 */
function extractBusinessTypes(source) {
  const match = source.match(/Config\.BusinessTypes\s*=\s*\{([\s\S]+?)\n\}/);
  if (!match) return null;

  const businesses = [];
  const entryRe = /\{[^}]+\}/g;
  for (const entry of match[1].matchAll(entryRe)) {
    const block = entry[0];
    const key   = (block.match(/key\s*=\s*['"]([^'"]+)['"]/)           || [])[1];
    const label = (block.match(/label\s*=\s*['"]([^'"]+)['"]/)         || [])[1];
    const level = (block.match(/requiredLevel\s*=\s*(\d+)/)            || [])[1];
    const price = (block.match(/price\s*=\s*(\d+)/)                    || [])[1];
    if (key) {
      businesses.push({
        key,
        label,
        level: level ? parseInt(level, 10) : undefined,
        price: price ? parseInt(price, 10) : undefined,
      });
    }
  }
  return businesses.length > 0 ? businesses : null;
}

// ── Tests ────────────────────────────────────────────────────────────────────

describe('0r-drugbusiness', () => {

  // ── File existence ──────────────────────────────────────────────────────

  test('fxmanifest.lua exists', () => {
    assert.ok(fs.existsSync(MANIFEST), `Missing: ${path.relative(REPO_ROOT, MANIFEST)}`);
  });

  test('config.lua exists', () => {
    assert.ok(fs.existsSync(CONFIG_LUA), `Missing: ${path.relative(REPO_ROOT, CONFIG_LUA)}`);
  });

  test('client.lua exists', () => {
    assert.ok(fs.existsSync(CLIENT_LUA), `Missing: ${path.relative(REPO_ROOT, CLIENT_LUA)}`);
  });

  test('server.lua exists', () => {
    assert.ok(fs.existsSync(SERVER_LUA), `Missing: ${path.relative(REPO_ROOT, SERVER_LUA)}`);
  });

  test('database.sql exists', () => {
    assert.ok(fs.existsSync(DB_SQL), `Missing: ${path.relative(REPO_ROOT, DB_SQL)}`);
  });

  // ── fxmanifest.lua declarations ─────────────────────────────────────────

  describe('fxmanifest.lua declarations', () => {
    const source = fs.readFileSync(MANIFEST, 'utf8');

    test('fx_version is cerulean', () => {
      assert.match(source, /fx_version\s+'cerulean'/, 'fx_version must be cerulean');
    });

    test('game is gta5', () => {
      assert.match(source, /game\s+'gta5'/, 'game must be gta5');
    });

    test('ui_page points to ui/build/index.html', () => {
      assert.match(source, /ui_page\s+'ui\/build\/index\.html'/, "ui_page must be 'ui/build/index.html'");
    });

    test('ox_lib is declared as a dependency', () => {
      assert.ok(
        source.includes("'ox_lib'") || source.includes('"ox_lib"'),
        'ox_lib must be listed in dependencies'
      );
    });

    test('oxmysql is declared as a dependency', () => {
      assert.ok(
        source.includes("'oxmysql'") || source.includes('"oxmysql"'),
        'oxmysql must be listed in dependencies'
      );
    });
  });

  // ── Config.BusinessTypes ────────────────────────────────────────────────

  describe('Config.BusinessTypes', () => {
    const source     = fs.readFileSync(CONFIG_LUA, 'utf8');
    const businesses = extractBusinessTypes(source);

    test('Config.BusinessTypes table is present', () => {
      assert.ok(businesses !== null, 'Config.BusinessTypes table not found in config.lua');
    });

    test('contains weed, cocaine, and meth entries', () => {
      const keys = businesses.map(b => b.key);
      assert.ok(keys.includes('weed'),    "BusinessTypes must include 'weed'");
      assert.ok(keys.includes('cocaine'), "BusinessTypes must include 'cocaine'");
      assert.ok(keys.includes('meth'),    "BusinessTypes must include 'meth'");
    });

    test('every entry has a non-empty label', () => {
      const invalid = businesses.filter(b => !b.label || b.label.trim() === '');
      assert.deepEqual(
        invalid.map(b => b.key),
        [],
        `Businesses with empty label: ${invalid.map(b => b.key).join(', ')}`
      );
    });

    test('every entry has a positive price', () => {
      const invalid = businesses.filter(b => !b.price || b.price <= 0);
      assert.deepEqual(
        invalid.map(b => b.key),
        [],
        `Businesses with invalid price: ${invalid.map(b => b.key).join(', ')}`
      );
    });

    test('every entry has a positive requiredLevel', () => {
      const invalid = businesses.filter(b => b.level === undefined || b.level < 1);
      assert.deepEqual(
        invalid.map(b => b.key),
        [],
        `Businesses with invalid requiredLevel: ${invalid.map(b => b.key).join(', ')}`
      );
    });
  });

  // ── Config.PackagedProduct ──────────────────────────────────────────────

  describe('Config.PackagedProduct', () => {
    const source = fs.readFileSync(CONFIG_LUA, 'utf8');

    test('maxStock is a positive integer', () => {
      const match = source.match(/maxStock\s*=\s*(\d+)/);
      assert.ok(match, 'maxStock must be defined in Config.PackagedProduct');
      assert.ok(parseInt(match[1], 10) > 0, `maxStock must be > 0, got ${match[1]}`);
    });

    test('packaged_weed item name is defined', () => {
      assert.ok(
        source.includes("'packaged_weed'") || source.includes('"packaged_weed"'),
        'packaged_weed item name must be defined'
      );
    });

    test('packaged_cocaine item name is defined', () => {
      assert.ok(
        source.includes("'packaged_cocaine'") || source.includes('"packaged_cocaine"'),
        'packaged_cocaine item name must be defined'
      );
    });

    test('packaged_meth item name is defined', () => {
      assert.ok(
        source.includes("'packaged_meth'") || source.includes('"packaged_meth"'),
        'packaged_meth item name must be defined'
      );
    });
  });

  // ── Config.RawMaterials ─────────────────────────────────────────────────

  describe('Config.RawMaterials', () => {
    const source = fs.readFileSync(CONFIG_LUA, 'utf8');

    test('vehicleUpgrades is defined', () => {
      assert.match(source, /vehicleUpgrades\s*=/, 'vehicleUpgrades must be defined in Config.RawMaterials');
    });

    test('vehicleUpgrades references at least one vehicle model', () => {
      assert.ok(
        source.includes("'speedo'") || source.includes('"speedo"') ||
        source.includes("'burrito'") || source.includes('"burrito"'),
        'vehicleUpgrades must reference at least one vehicle model'
      );
    });

    test('quantityRawMaterialsInPackage is a positive number', () => {
      const match = source.match(/quantityRawMaterialsInPackage\s*=\s*(\d+)/);
      assert.ok(match, 'quantityRawMaterialsInPackage must be defined');
      assert.ok(parseInt(match[1], 10) > 0, `quantityRawMaterialsInPackage must be > 0, got ${match[1]}`);
    });
  });

  // ── Config.Labs ─────────────────────────────────────────────────────────

  describe('Config.Labs', () => {
    const source = fs.readFileSync(CONFIG_LUA, 'utf8');

    test('Config.Labs is defined', () => {
      assert.match(source, /Config\.Labs\s*=/, 'Config.Labs must be defined');
    });

    test("weed lab is configured", () => {
      assert.ok(source.includes("['weed']"), "Config.Labs must include a 'weed' entry");
    });

    test("cocaine lab is configured", () => {
      assert.ok(source.includes("['cocaine']"), "Config.Labs must include a 'cocaine' entry");
    });

    test("meth lab is configured", () => {
      assert.ok(source.includes("['meth']"), "Config.Labs must include a 'meth' entry");
    });
  });

  // ── Config.MoneyWashing ─────────────────────────────────────────────────

  describe('Config.MoneyWashing', () => {
    const source = fs.readFileSync(CONFIG_LUA, 'utf8');

    test('Config.MoneyWashing is defined', () => {
      assert.match(source, /Config\.MoneyWashing\s*=/, 'Config.MoneyWashing must be defined');
    });

    test('upgrades specify productionPerMin', () => {
      assert.ok(
        source.includes('productionPerMin'),
        'MoneyWashing upgrades must specify productionPerMin'
      );
    });
  });

  // ── database.sql ────────────────────────────────────────────────────────

  describe('database.sql', () => {
    const source = fs.readFileSync(DB_SQL, 'utf8');

    test('contains at least one CREATE TABLE statement', () => {
      assert.match(source, /CREATE\s+TABLE/i, 'database.sql must contain at least one CREATE TABLE statement');
    });
  });
});
