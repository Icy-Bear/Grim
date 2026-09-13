const { spawn, spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function isOpencodeAvailable() {
  // Cross-platform check: try --version with spawnSync; also handle .cmd on Windows
  // spawnSync respects PATHEXT on Windows when shell:false? Use shell:true fallback for Windows
  try {
    const result = spawnSync("opencode", ["--version"], { stdio: "ignore", shell: process.platform === "win32" });
    if (result.status === 0) return true;
    // Some installations may require opencode.cmd on Windows
    if (process.platform === "win32") {
      const r2 = spawnSync("opencode.cmd", ["--version"], { stdio: "ignore", shell: true });
      if (r2.status === 0) return true;
    }
    return false;
  } catch (_) {
    return false;
  }
}

function findSystemPrompt() {
  const candidates = [
    path.join(__dirname, "..", "system-prompt.txt"),
    path.join(process.cwd(), "system-prompt.txt"),
    path.join(__dirname, "system-prompt.txt"),
  ];
  const home = process.env.HOME || process.env.USERPROFILE || "";
  if (home) {
    candidates.push(path.join(home, ".grim", "system-prompt.txt"));
  }
  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  return path.join(__dirname, "..", "system-prompt.txt");
}

function loadSystemPrompt(filePath) {
  const target = filePath || findSystemPrompt();
  if (!fs.existsSync(target)) {
    return { filePath: target, content: null, error: `system-prompt.txt not found at ${target}` };
  }
  try {
    const content = fs.readFileSync(target, "utf8");
    return { filePath: target, content, error: null };
  } catch (e) {
    return { filePath: target, content: null, error: e.message };
  }
}

function buildCombinedPrompt(systemPrompt, question) {
  // Combine system prompt + selected problem. This is what we pass via --prompt.
  // The model should start assessment with this problem.
  return `${systemPrompt.trim()}

---

# ASSESSMENT PROBLEM

You are now starting a Vibe Coding Assessment. The candidate has selected the following coding problem. Begin immediately with PHASE 1 — ask them to describe the problem in their own words. Do not solve it.

## ${question.title}

${question.body.trim()}
`;
}

function launchOpenCode(combinedPrompt) {
  // Use spawn with inherit to give opencode full terminal control.
  // Cross-platform: use shell on Windows so PATHEXT resolves opencode.cmd
  const useShell = process.platform === "win32";
  const child = spawn("opencode", ["--prompt", combinedPrompt], {
    stdio: "inherit",
    shell: useShell,
  });

  child.on("error", (err) => {
    console.error("\nFailed to launch OpenCode:", err.message);
    console.error("Ensure OpenCode is installed: https://opencode.ai");
    process.exit(1);
  });

  child.on("exit", (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
    } else {
      process.exit(code || 0);
    }
  });
}

module.exports = { isOpencodeAvailable, findSystemPrompt, loadSystemPrompt, buildCombinedPrompt, launchOpenCode };
