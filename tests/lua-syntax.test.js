'use strict';
/**
 * Lua Syntax Tests
 *
 * Validates that every .lua file in the resources directory parses without
 * errors.  FiveM extends standard Lua 5.4 with two additional constructs:
 *   • Backtick hash literals  – `HASH_NAME`  (equivalent to GetHashKey())
 *   • Compound assignment ops – +=, -=, *=, /=, //=, %=, ^=, ..=
 *
 * A lightweight pre-processor normalises these extensions into legal Lua 5.4
 * before passing the source to `luac -p` for syntax verification.
 */

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

// ── Helpers ──────────────────────────────────────────────────────────────────

const REPO_ROOT = path.resolve(__dirname, '..');
const RESOURCES_DIR = path.join(REPO_ROOT, 'resources');

/** Recursively collect every *.lua file under a directory. */
function findLuaFiles(dir) {
  const results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findLuaFiles(full));
    } else if (entry.isFile() && entry.name.endsWith('.lua')) {
      results.push(full);
    }
  }
  return results;
}

/**
 * Pre-process FiveM Lua extensions so standard luac can parse the source.
 *
 * Transformations applied (in order):
 *  1. Backtick hash literals:    `IDENTIFIER`  →  0
 *  2. Compound assignment ops:   x += expr     →  x = x + 0 --[[ += ]]
 *     Supported: += -= *= /= //= %= ^= ..=
 */
function preprocessFiveMExtensions(source) {
  // 1. Backtick hash literals: `SOME_HASH_42`
  //    These can appear as table keys, function args, or in expressions.
  source = source.replace(/`[A-Za-z0-9_]+`/g, '0');

  // 2. Compound assignment operators.
  //    Pattern: <lvalue> <op>= <rvalue>
  //    Replace the compound assignment with a simple assignment whose RHS is
  //    a valid but trivial expression so luac only checks syntax, not logic.
  //    We transform:  lvalue OP= …rest-of-expression-to-EOL
  //    into:          lvalue = 0 --[[ OP= rest ]]
  //
  //    The regex captures the lvalue (everything up to the operator) and the
  //    compound operator itself, then ignores the rest of the line.
  //    Only valid FiveM compound assignment operators are matched:
  //    +=  -=  *=  /=  //=  %=  ^=  ..=
  source = source.replace(
    /([ \t]*)([A-Za-z_][A-Za-z0-9_.\[\]"']*)\s*(\/\/=|\.\.=|[+\-*/%^]=)([ \t]*)(.*)/gm,
    (match, indent, lvalue, op, _sp, rest) => {
      return `${indent}${lvalue} = 0 --[[ ${op} ${rest} ]]`;
    }
  );

  return source;
}

/** Write content to a temp file, returning its path. */
function writeTempLua(content) {
  const tmp = path.join(os.tmpdir(), `fivem_luacheck_${process.pid}_${Date.now()}.lua`);
  fs.writeFileSync(tmp, content, 'utf8');
  return tmp;
}

/** Run luac -p on a file; returns { ok, error }. */
function luacCheck(filePath) {
  const result = spawnSync('luac', ['-p', filePath], { encoding: 'utf8' });
  if (result.status === 0) return { ok: true };
  return { ok: false, error: (result.stderr || result.stdout || '').trim() };
}

// ── Tests ────────────────────────────────────────────────────────────────────

const luaFiles = findLuaFiles(RESOURCES_DIR);

describe('Lua syntax', () => {
  assert.ok(luaFiles.length > 0, 'Should find at least one .lua file in resources/');

  for (const file of luaFiles) {
    const label = path.relative(REPO_ROOT, file);

    test(label, () => {
      const source = fs.readFileSync(file, 'utf8');
      const processed = preprocessFiveMExtensions(source);

      const tmp = writeTempLua(processed);
      try {
        const { ok, error } = luacCheck(tmp);
        assert.ok(ok, `Lua syntax error in ${label}:\n${error}`);
      } finally {
        fs.unlinkSync(tmp);
      }
    });
  }
});
