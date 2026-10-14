// scripts/shift-left/opencode-plugin.js — the shift-left doctor and agent gate
// inside OpenCode (uFawkes.dev docs/ai-sdlc/shift-left/spec.md R6, R9): the same
// two tools Claude Code runs from .claude/settings.json, through the same shim.
//
//   session.created     doctor --quiet; a problem goes into the session as context
//   session.idle        agent-gate; a failure is sent back so the agent keeps working
//   tool.execute.before refuses a commit or push that skips the git hooks
//
// OpenCode can't block a stop the way Claude Code's Stop hook does, so the gate
// answers an idle session with a prompt instead: the agent is told what fails and
// goes on. The loop guard is the gate's own: the second idle after the same prompt
// is reported to agent-gate as stop_hook_active, and it lets the agent stop and
// tells the person instead. There is no transcript here, so the gate covers
// tracked changes only, not new files the agent wrote.
//
// Everything is delegated to the repo's shim (scripts/shift-left.sh, or
// scripts/shift-left/shift-left.sh in uFawkesPipe), so this file changes rarely
// and needs no dependency. Without a shim it does nothing. To use it, copy it to
// .opencode/plugins/shift-left.js: that directory is the repo's agent framework
// (AI_STANCE.md), so the copy needs a person's sign-off.
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import path from "node:path";

const SHIMS = ["scripts/shift-left.sh", "scripts/shift-left/shift-left.sh"];

// A real `git commit` or `git push` that skips the hooks. Anchored at a command
// start, so prose that mentions the flag isn't blocked.
const SKIPS_HOOKS = /(^|[;&|]\s*)git\s+(-\S+\s+(\S+\s+)?)*(commit|push)\b[^;&|]*--no-verify/;

/** @type {import("@opencode-ai/plugin").Plugin} */
export const ShiftLeft = async ({ client, directory }) => {
  const shim = SHIMS.map((s) => path.join(directory, s)).find(existsSync);
  const run = (tool, args = [], input = "") =>
    spawnSync("bash", [shim, tool, ...args], { cwd: directory, input, encoding: "utf8", timeout: 120_000 });
  const lastSaid = new Map(); // session -> last message, so nothing is sent twice in a row
  const say = async (id, text, reply) => {
    if (lastSaid.get(id) === text) return;
    lastSaid.set(id, text);
    await client.session.prompt({
      path: { id },
      body: { ...(reply ? {} : { noReply: true }), parts: [{ type: "text", text }] },
    });
  };
  const blocked = new Set(); // sessions the gate already sent back once

  return {
    event: async ({ event }) => {
      if (!shim) return;
      if (event.type === "session.created") {
        const r = run("doctor", ["--quiet"]);
        const text = `${r.stdout ?? ""}${r.stderr ?? ""}`.trim();
        if (r.status !== 0 && text) await say(event.properties.info.id, `shift-left doctor:\n${text}`, false);
      } else if (event.type === "session.idle") {
        const id = event.properties.sessionID;
        const r = run("agent-gate", [], JSON.stringify({ stop_hook_active: blocked.has(id) }));
        if (r.status === 2) {
          blocked.add(id);
          await say(id, (r.stderr ?? "").trim(), true);
          return;
        }
        blocked.delete(id);
        try {
          const note = JSON.parse(r.stdout || "{}").systemMessage;
          if (note) await say(id, note, false);
        } catch {
          // Not JSON: nothing to relay.
        }
      }
    },

    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash" && SKIPS_HOOKS.test(output.args?.command ?? "")) {
        throw new Error(
          "Blocked: skipping the git hooks is not allowed here. Fix what the hook reports; if the hook is wrong, say so and ask a person.",
        );
      }
    },
  };
};
