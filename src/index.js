#!/usr/bin/env node
const path = require("path");
const { loadQuestions } = require("./questions");
const { isOpencodeAvailable, loadSystemPrompt, buildCombinedPrompt, launchOpenCode } = require("./opencode");
const { runTui } = require("./tui");

const VERSION = "1.0.0";

function printHelp() {
  console.log(`
GRIM — Vibe Coding Assessment  v${VERSION}

Usage:
  grim              Launch TUI to select a problem and start assessment
  grim --help       Show this help
  grim --version    Show version
  grim --list       List available problems and exit
  grim --check      Check OpenCode installation

The problem is yours. The reasoning is yours. The code comes after.
`);
}

function printBannerText() {
  // Plain text fallback (no ANSI) for --list etc.
  console.log(`
 ██████╗ ██████╗ ██╗███╗   ███╗
██╔════╝ ██╔══██╗██║████╗ ████║
██║  ███╗██████╔╝██║██╔████╔██║
██║   ██║██╔══██╗██║██║╚██╔╝██║
╚██████╔╝██║  ██║██║██║ ╚═╝ ██║
 ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝

        V I B E   C O D I N G
`);
}

async function main() {
  const args = process.argv.slice(2);

  if (args.includes("--help") || args.includes("-h")) {
    printHelp();
    process.exit(0);
  }
  if (args.includes("--version") || args.includes("-v")) {
    console.log(VERSION);
    process.exit(0);
  }

  // Quick check for opencode availability (for --check)
  if (args.includes("--check")) {
    const ok = isOpencodeAvailable();
    if (ok) {
      console.log("✓ OpenCode is available");
      process.exit(0);
    } else {
      console.error("✗ OpenCode is not installed");
      console.error("Install from https://opencode.ai");
      process.exit(1);
    }
  }

  // Load questions
  const { filePath: qPath, questions, error: qErr } = loadQuestions();
  if (qErr && questions.length === 0) {
    console.error(`Warning: ${qErr}`);
    console.error("Create questions.md with ## Title sections.");
  }

  if (args.includes("--list")) {
    printBannerText();
    console.log(`Questions file: ${qPath}\n`);
    if (questions.length === 0) {
      console.log("No questions found.");
      process.exit(0);
    }
    questions.forEach((q, i) => {
      console.log(`${String(i + 1).padStart(2, " ")}. ${q.title}`);
    });
    process.exit(0);
  }

  // Check OpenCode before showing TUI
  if (!isOpencodeAvailable()) {
    console.error("");
    console.error("  ERROR: OpenCode is not installed.");
    console.error("");
    console.error("  GRIM requires OpenCode to run.");
    console.error("  Install OpenCode first: https://opencode.ai");
    console.error("");
    console.error("  After installing, run again:");
    console.error("    grim");
    console.error("");
    process.exit(1);
  }

  // Load system prompt
  const { content: sysPrompt, error: sysErr } = loadSystemPrompt();
  if (sysErr || !sysPrompt) {
    console.error(`\nERROR: ${sysErr || "system-prompt.txt not found"}`);
    console.error(`Looked for: ${require("./opencode").findSystemPrompt()}`);
    console.error("Reinstall GRIM or ensure system-prompt.txt is present.");
    process.exit(1);
  }

  if (questions.length === 0) {
    console.error("\nNo questions available.");
    console.error(`Add problems to: ${qPath}`);
    console.error("Each problem starts with: ## Title");
    process.exit(1);
  }

  // Run TUI
  const selected = await runTui(questions);

  if (!selected) {
    console.log("\nCancelled. No problem selected.\n");
    process.exit(0);
  }

  console.log(`\n  Selected: ${selected.title}`);
  console.log("  Launching assessment…\n");

  const combined = buildCombinedPrompt(sysPrompt, selected);
  launchOpenCode(combined);
}

main().catch((err) => {
  console.error("Unexpected error:", err);
  process.exit(1);
});
