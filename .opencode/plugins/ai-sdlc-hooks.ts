import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import path from "node:path";
import type { Plugin } from "@opencode-ai/plugin";

const PROTECTED_PATHS_CONFIG = JSON.parse(
  readFileSync(path.join(process.cwd(), "scripts/hooks/protected-paths.json"), "utf-8")
) as { protectedBasenamePatterns: string[]; protectedPathSegments?: string[] };
const PROTECTED_BASENAME = PROTECTED_PATHS_CONFIG.protectedBasenamePatterns.map((s) => new RegExp(s));
const PROTECTED_SEGMENTS = PROTECTED_PATHS_CONFIG.protectedPathSegments ?? [".git"];

// Use pinned prettier from local node_modules if available, fallback to npx with --yes removed
// ruff format is the standard formatter for Python
const FORMATTERS: Array<{ ext: string; cmd: string[] }> = [
  { ext: ".ts", cmd: ["prettier", "--write"] },
  { ext: ".js", cmd: ["prettier", "--write"] },
  { ext: ".py", cmd: ["ruff", "format"] },
  { ext: ".go", cmd: ["gofmt", "-w"] },
  { ext: ".rs", cmd: ["rustfmt"] }
];

function isProtected(targetPath: string): boolean {
  const normalized = path.normalize(targetPath).replace(/\\/g, "/");
  const segments = normalized.split("/").filter(Boolean);
  const basename = segments[segments.length - 1] ?? "";
  if (PROTECTED_SEGMENTS.some((seg) => segments.includes(seg))) return true;
  return PROTECTED_BASENAME.some((re) => re.test(basename));
}

// Gate real commits only: not `git commit-tree`, not prose containing "git commit".
const GIT_COMMIT = /(^|[;&|]\s*)git\s+(-\S+\s+)*commit(\s|$)/;

function runSecretScan(): { exitCode: number; message?: string } {
  const script = path.join(process.cwd(), "scripts/hooks/pre-commit-secret-scan.sh");
  try {
    execFileSync("bash", [script], { stdio: "inherit" });
    return { exitCode: 0 };
  } catch (error) {
    const status = (error as { status?: number }).status ?? 1;
    return {
      exitCode: status === 1 || status === 2 ? status : 1,
      message:
        status === 2
          ? "Secret scan could not run, so the commit was blocked rather than allowed through an unverified gate."
          : undefined
    };
  }
}

export const AiSdlcHooks: Plugin = async ({ $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Protected path guard
      if (input.tool === "edit" || input.tool === "write") {
        const filePath = output.args.filePath;
        if (filePath && isProtected(filePath)) {
          throw new Error(`Blocked edit to protected path: ${filePath}`);
        }
      }

      // Secret scan on git commit
      if (input.tool === "bash") {
        const command = output.args.command;
        if (command && GIT_COMMIT.test(command)) {
          const result = runSecretScan();
          if (result.exitCode !== 0) {
            throw new Error(result.message ?? "Secret scan failed");
          }
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      // Auto-format after edits
      if (input.tool === "edit" || input.tool === "write") {
        const args = input.args as { filePath?: string } | undefined;
        const filePath = args?.filePath;
        if (typeof filePath !== "string") return;
        const ext = path.extname(filePath);
        const formatter = FORMATTERS.find((f) => f.ext === ext);
        if (!formatter) return;
        const fp = filePath;
        const cmd = formatter.cmd[0] as string;
        const restArgs = formatter.cmd.slice(1) as string[];
        restArgs.push(fp);
        try {
          execFileSync(cmd, restArgs, { stdio: "inherit" });
        } catch (error) {
          throw new Error(`Formatter failed for ${fp}: ${String(error)}`);
        }
      }
    },

    "session.compacted": async () => {
      return {
        message: "Use the project's package manager. Run /verify before claiming completion. Never edit protected files."
      };
    }
  };
};
