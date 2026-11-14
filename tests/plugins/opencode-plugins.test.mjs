// Contract and behaviour tests for the OpenCode V2 plugins in .opencode/plugins/.
// OpenCode V2 loads a plugin through its default export — `{ id, setup }` — and
// rejects the V1 named-export factory before setup runs.
import test from "node:test";
import assert from "node:assert/strict";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

const plugin = (name) => new URL(`../../.opencode/plugins/${name}`, import.meta.url);

const PROTECTED = {
  protectedBasenamePatterns: ["^\\.env(\\.(?!example$).+)?$", "\\.pem$", "\\.key$", "^credentials(\\..+)?$"],
  protectedPathSegments: [".git"],
};

function fakeCtx(directory) {
  const toolHooks = {};
  const sessionHooks = {};
  return {
    toolHooks,
    sessionHooks,
    ctx: {
      location: { directory },
      tool: {
        hook: async (name, cb) => {
          toolHooks[name] = cb;
          return { dispose: async () => {} };
        },
      },
      session: {
        hook: async (name, cb) => {
          sessionHooks[name] = cb;
          return { dispose: async () => {} };
        },
        synthetic: async () => {},
        prompt: async () => {},
      },
      event: { subscribe: () => (async function* () {})() },
    },
  };
}

function project() {
  const dir = mkdtempSync(path.join(tmpdir(), "fawkes-oc-"));
  mkdirSync(path.join(dir, "scripts", "hooks"), { recursive: true });
  writeFileSync(path.join(dir, "scripts", "hooks", "protected-paths.json"), JSON.stringify(PROTECTED));
  writeFileSync(
    path.join(dir, "scripts", "hooks", "pre-commit-secret-scan.sh"),
    '#!/usr/bin/env bash\nroot="$(cd "$(dirname "$0")/.." && pwd)"\nexit "$(cat "$root/secret.rc" 2>/dev/null || echo 0)"\n',
  );
  chmodSync(path.join(dir, "scripts", "hooks", "pre-commit-secret-scan.sh"), 0o755);
  writeFileSync(path.join(dir, "scripts", "secret.rc"), "0");
  return dir;
}

function cleanup(dir) {
  rmSync(dir, { recursive: true, force: true });
}

test("all three plugins export the V2 contract", async () => {
  for (const [file, id] of [
    ["graphify.js", "graphify"],
    ["shift-left.js", "shift-left"],
    ["ai-sdlc-hooks.js", "ai-sdlc-hooks"],
  ]) {
    const mod = await import(plugin(file));
    assert.equal(mod.default?.id, id, `${file} id`);
    assert.equal(typeof mod.default.setup, "function", `${file} setup`);
  }
});

test("ai-sdlc-hooks refuses protected paths, including .env.example's siblings", async () => {
  const dir = project();
  try {
    const { ctx, toolHooks } = fakeCtx(dir);
    await (await import(plugin("ai-sdlc-hooks.js"))).default.setup(ctx);
    const before = toolHooks["execute.before"];
    assert.equal(typeof before, "function");

    assert.throws(() => before({ tool: "edit", input: { filePath: ".env" } }), /protected path/i);
    assert.throws(() => before({ tool: "write", input: { filePath: "certs/server.pem" } }), /protected path/i);
    assert.throws(() => before({ tool: "edit", input: { filePath: "deploy/credentials.json" } }), /protected path/i);
    assert.throws(() => before({ tool: "edit", input: { filePath: ".git/config" } }), /protected path/i);
    assert.doesNotThrow(() => before({ tool: "edit", input: { filePath: ".env.example" } }));
    assert.doesNotThrow(() => before({ tool: "edit", input: { filePath: "README.md" } }));
  } finally {
    cleanup(dir);
  }
});

test("ai-sdlc-hooks scans only a real git commit", async () => {
  const dir = project();
  try {
    const { ctx, toolHooks } = fakeCtx(dir);
    await (await import(plugin("ai-sdlc-hooks.js"))).default.setup(ctx);
    const before = toolHooks["execute.before"];

    assert.doesNotThrow(() => before({ tool: "bash", input: { command: "git commit -m ok" } }));

    writeFileSync(path.join(dir, "scripts", "secret.rc"), "1");
    assert.throws(() => before({ tool: "bash", input: { command: "git push && git commit -m leak" } }), /Secret scan failed/);

    assert.doesNotThrow(() => before({ tool: "bash", input: { command: "git commit-tree abc" } }));
    assert.doesNotThrow(() => before({ tool: "bash", input: { command: "echo 'never git commit secrets'" } }));
  } finally {
    cleanup(dir);
  }
});

test("graphify injects its reminder once per session", async () => {
  const dir = project();
  try {
    mkdirSync(path.join(dir, "graphify-out"), { recursive: true });
    writeFileSync(path.join(dir, "graphify-out", "graph.json"), "{}");
    const { ctx, sessionHooks } = fakeCtx(dir);
    await (await import(plugin("graphify.js"))).default.setup(ctx);

    const event = { sessionID: "s1", messages: [{ role: "user", content: [{ type: "text", text: "hi" }] }] };
    await sessionHooks.context(event);
    assert.match(event.messages[0].content[0].text, /\[graphify\]/);

    const count = event.messages[0].content.length;
    await sessionHooks.context(event);
    assert.equal(event.messages[0].content.length, count);
  } finally {
    cleanup(dir);
  }
});

test("shift-left blocks hook-skipping commits and is inert without its shim", async () => {
  const withShim = project();
  const withoutShim = mkdtempSync(path.join(tmpdir(), "fawkes-oc-"));
  try {
    writeFileSync(path.join(withShim, "scripts", "shift-left.sh"), "#!/usr/bin/env bash\nexit 0\n");
    chmodSync(path.join(withShim, "scripts", "shift-left.sh"), 0o755);

    const a = fakeCtx(withShim);
    await (await import(plugin("shift-left.js"))).default.setup(a.ctx);
    const before = a.toolHooks["execute.before"];
    assert.equal(typeof before, "function");
    assert.throws(() => before({ tool: "bash", input: { command: "git commit --no-verify -m x" } }), /Blocked/);
    assert.throws(() => before({ tool: "bash", input: { command: "git push --no-verify" } }), /Blocked/);
    assert.doesNotThrow(() => before({ tool: "bash", input: { command: "git commit -m x" } }));

    const b = fakeCtx(withoutShim);
    await (await import(plugin("shift-left.js"))).default.setup(b.ctx);
    assert.equal(b.toolHooks["execute.before"], undefined);
  } finally {
    cleanup(withShim);
    cleanup(withoutShim);
  }
});
