'use strict';
/**
 * server.cfg Tests
 *
 * Validates that every `ensure <resource>` directive in server.cfg references
 * a resource directory that actually exists somewhere in the resources tree,
 * and that the named resource contains an fxmanifest.lua file.
 *
 * Also checks basic server.cfg formatting rules:
 *  • sv_maxclients must be a positive integer.
 *  • endpoint_add_tcp / endpoint_add_udp must specify a valid port (1–65535).
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT = path.resolve(__dirname, '..');
const CFG_PATH = path.join(REPO_ROOT, 'server.cfg');
const RESOURCES_DIR = path.join(REPO_ROOT, 'resources');

/** Read server.cfg, stripping inline comments and blank lines. */
function loadCfg() {
  return fs.readFileSync(CFG_PATH, 'utf8')
    .split('\n')
    .map(l => l.replace(/#.*$/, '').trim())
    .filter(Boolean);
}

/** Recursively build a map of  resourceName → directory path. */
function buildResourceIndex(dir) {
  const index = {};
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const full = path.join(dir, entry.name);
    // Category folders like [gameplay] are not resources themselves
    if (entry.name.startsWith('[') && entry.name.endsWith(']')) {
      Object.assign(index, buildResourceIndex(full));
    } else {
      index[entry.name] = full;
    }
  }
  return index;
}

// ── Tests ────────────────────────────────────────────────────────────────────

const cfgLines = loadCfg();
const resourceIndex = buildResourceIndex(RESOURCES_DIR);

describe('server.cfg', () => {

  test('server.cfg file exists', () => {
    assert.ok(fs.existsSync(CFG_PATH), 'server.cfg must exist at repo root');
  });

  test('server.cfg is not empty', () => {
    assert.ok(cfgLines.length > 0, 'server.cfg should have at least one directive');
  });

  // ── sv_maxclients ─────────────────────────────────────────────────────────

  test('sv_maxclients is a positive integer', () => {
    const line = cfgLines.find(l => /^sv_maxclients\s/.test(l));
    assert.ok(line, 'server.cfg must contain sv_maxclients');
    const match = line.match(/^sv_maxclients\s+(\d+)/);
    assert.ok(match, `sv_maxclients value must be a positive integer, got: ${line}`);
    const value = parseInt(match[1], 10);
    assert.ok(value > 0, `sv_maxclients must be > 0, got ${value}`);
  });

  // ── Network endpoints ─────────────────────────────────────────────────────

  test('endpoint_add_tcp specifies a valid host:port', () => {
    const line = cfgLines.find(l => /^endpoint_add_tcp\s/.test(l));
    assert.ok(line, 'server.cfg must contain endpoint_add_tcp');
    const match = line.match(/^endpoint_add_tcp\s+"([^"]+)"/);
    assert.ok(match, `endpoint_add_tcp must have a quoted address, got: ${line}`);
    const portMatch = match[1].match(/:(\d+)$/);
    assert.ok(portMatch, `endpoint_add_tcp address must include a port: ${match[1]}`);
    const port = parseInt(portMatch[1], 10);
    assert.ok(port >= 1 && port <= 65535, `Port ${port} is out of range (1–65535)`);
  });

  test('endpoint_add_udp specifies a valid host:port', () => {
    const line = cfgLines.find(l => /^endpoint_add_udp\s/.test(l));
    assert.ok(line, 'server.cfg must contain endpoint_add_udp');
    const match = line.match(/^endpoint_add_udp\s+"([^"]+)"/);
    assert.ok(match, `endpoint_add_udp must have a quoted address, got: ${line}`);
    const portMatch = match[1].match(/:(\d+)$/);
    assert.ok(portMatch, `endpoint_add_udp address must include a port: ${match[1]}`);
    const port = parseInt(portMatch[1], 10);
    assert.ok(port >= 1 && port <= 65535, `Port ${port} is out of range (1–65535)`);
  });

  // ── ensure directives ─────────────────────────────────────────────────────

  describe('ensure directives', () => {
    const ensureLines = cfgLines.filter(l => /^ensure\s+\S/.test(l));

    test('at least one ensure directive is present', () => {
      assert.ok(ensureLines.length > 0, 'server.cfg should contain at least one ensure directive');
    });

    for (const line of ensureLines) {
      const resourceName = line.replace(/^ensure\s+/, '').trim();

      test(`ensure ${resourceName} → resource directory exists`, () => {
        assert.ok(
          resourceName in resourceIndex,
          `Resource '${resourceName}' (from server.cfg) was not found in the resources directory tree`
        );
      });

      test(`ensure ${resourceName} → fxmanifest.lua present`, () => {
        if (!(resourceName in resourceIndex)) return; // already failed above
        const manifestPath = path.join(resourceIndex[resourceName], 'fxmanifest.lua');
        assert.ok(
          fs.existsSync(manifestPath),
          `Resource '${resourceName}' is missing fxmanifest.lua at ${path.relative(REPO_ROOT, manifestPath)}`
        );
      });
    }
  });
});
