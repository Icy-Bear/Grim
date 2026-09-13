const readline = require("readline");

// Minimal ANSI helpers — no external deps, cross-platform
const ESC = "\x1b[";
const RESET = "\x1b[0m";
const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
// Colors tuned for dark/technical vibe
const FG_WHITE = "\x1b[37m";
const FG_CYAN = "\x1b[36m";
const FG_GRAY = "\x1b[90m";
const FG_RED = "\x1b[31m";
const FG_YELLOW = "\x1b[33m";
const BG_WHITE = "\x1b[47m";
const FG_BLACK = "\x1b[30m";
const BG_CYAN = "\x1b[46m";

const BANNER = [
  " ██████╗ ██████╗ ██╗███╗   ███╗",
  "██╔════╝ ██╔══██╗██║████╗ ████║",
  "██║  ███╗██████╔╝██║██╔████╔██║",
  "██║   ██║██╔══██╗██║██║╚██╔╝██║",
  "╚██████╔╝██║  ██║██║██║ ╚═╝ ██║",
  " ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝",
];

function clearScreen() {
  process.stdout.write("\x1b[2J\x1b[0;0H");
}

function stripAnsi(str) {
  return str.replace(/\x1b\[[0-9;]*m/g, "");
}

function truncate(str, max) {
  if (str.length <= max) return str;
  return str.slice(0, max - 1) + "…";
}

function wrapText(text, width) {
  const words = text.split(/\s+/);
  const lines = [];
  let cur = "";
  for (const w of words) {
    if ((cur + " " + w).trim().length > width) {
      if (cur) lines.push(cur);
      cur = w;
    } else {
      cur = (cur ? cur + " " : "") + w;
    }
  }
  if (cur) lines.push(cur);
  return lines;
}

function getTerminalSize() {
  return {
    cols: process.stdout.columns || 80,
    rows: process.stdout.rows || 24,
  };
}

function render(state) {
  const { cols, rows } = getTerminalSize();
  const { questions, selected, scrollOffset } = state;
  clearScreen();

  // Banner — centered, cyan/white on dark
  const bannerWidth = BANNER[0].length;
  const bannerPad = Math.max(0, Math.floor((cols - bannerWidth) / 2));
  const padStr = " ".repeat(bannerPad);
  for (const line of BANNER) {
    process.stdout.write(padStr + FG_WHITE + BOLD + line + RESET + "\n");
  }
  const vibe = "V I B E   C O D I N G";
  const vibePad = Math.max(0, Math.floor((cols - vibe.length) / 2));
  process.stdout.write(" ".repeat(vibePad) + FG_CYAN + DIM + vibe + RESET + "\n");

  // Subtitle
  const tagline1 = "The problem is yours.";
  const tagline2 = "The reasoning is yours.";
  const tagline3 = "The code comes after.";
  // centered
  process.stdout.write("\n");
  const grimLabel = "GRIM:";
  const grimPad = Math.max(0, Math.floor((cols - grimLabel.length) / 2));
  // Slight offset? keep centered
  process.stdout.write(" ".repeat(grimPad) + FG_WHITE + BOLD + grimLabel + RESET + "\n");
  process.stdout.write("\n");
  for (const t of [tagline1, tagline2, tagline3]) {
    const p = Math.max(0, Math.floor((cols - t.length) / 2));
    process.stdout.write(" ".repeat(p) + FG_GRAY + t + RESET + "\n");
  }

  // Divider
  const divChar = "─";
  const divLen = Math.min(cols - 4, 60);
  const divPad = Math.max(0, Math.floor((cols - divLen) / 2));
  process.stdout.write("\n" + " ".repeat(divPad) + FG_GRAY + DIM + divChar.repeat(divLen) + RESET + "\n\n");

  // Question list header
  const listTitle = `  SELECT A PROBLEM  —  ${questions.length} available  `;
  const titlePad = Math.max(0, Math.floor((cols - stripAnsi(listTitle).length) / 2));
  process.stdout.write(" ".repeat(titlePad) + FG_CYAN + DIM + listTitle + RESET + "\n\n");

  if (questions.length === 0) {
    const msg = "No questions found. Add problems to questions.md (## Title).";
    const p = Math.max(0, Math.floor((cols - msg.length) / 2));
    process.stdout.write(" ".repeat(p) + FG_YELLOW + msg + RESET + "\n");
    process.stdout.write("\n" + FG_GRAY + "  Press q to quit." + RESET + "\n");
    return;
  }

  // Determine visible window
  const availableRows = rows - 18; // approx header height
  const visibleCount = Math.max(3, Math.min(questions.length, availableRows - 6));
  const start = scrollOffset;
  const end = Math.min(questions.length, start + visibleCount);

  for (let i = start; i < end; i++) {
    const q = questions[i];
    const isSelected = i === selected;
    const idxStr = String(i + 1).padStart(2, " ");
    const title = truncate(q.title, Math.max(10, cols - 14));
    if (isSelected) {
      // Highlighted row: inverse-like with cyan border
      const prefix = " ❯ ";
      const line = `${prefix}${idxStr}. ${title}`;
      // Use bright white on dark with cyan prefix; pad to cols?
      const padded = line + " ".repeat(Math.max(0, cols - stripAnsi(line).length - 4));
      process.stdout.write(FG_BLACK + BG_WHITE + BOLD + " " + padded + " " + RESET + "\n");
      // Show preview snippet under selected (one line dim)
      const preview = q.body.split("\n").find((l) => l.trim().length > 10) || "";
      const snippet = truncate(preview.trim().replace(/\s+/g, " "), Math.max(10, cols - 10));
      if (snippet) {
        process.stdout.write("     " + FG_GRAY + DIM + truncate(snippet, cols - 8) + RESET + "\n");
      }
    } else {
      const prefix = "   ";
      process.stdout.write(FG_GRAY + `${prefix}${idxStr}. ${title}` + RESET + "\n");
    }
  }

  // Scroll indicators
  if (start > 0) {
    process.stdout.write(FG_GRAY + DIM + "     ▲ more above" + RESET + "\n");
  }
  if (end < questions.length) {
    process.stdout.write(FG_GRAY + DIM + "     ▼ more below" + RESET + "\n");
  }

  // Footer help
  process.stdout.write("\n");
  const help = " ↑/↓ navigate   Enter select   q quit ";
  const helpPad = Math.max(0, Math.floor((cols - help.length) / 2));
  process.stdout.write(" ".repeat(helpPad) + FG_GRAY + DIM + help + RESET + "\n");

  // If small terminal, hint
  if (cols < 50) {
    process.stdout.write(FG_YELLOW + DIM + "  (resize terminal for better view)" + RESET + "\n");
  }
}

function runTui(questions) {
  return new Promise((resolve) => {
    if (!process.stdin.isTTY || !process.stdout.isTTY) {
      // Fallback: non-interactive, just list and prompt via readline
      console.log("\nGRIM — Vibe Coding Assessment\n");
      questions.forEach((q, i) => console.log(`  ${i + 1}. ${q.title}`));
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      rl.question("\nEnter number to select (or q to quit): ", (ans) => {
        rl.close();
        if (ans.trim().toLowerCase() === "q" || ans.trim() === "") {
          resolve(null);
        } else {
          const n = parseInt(ans.trim(), 10);
          if (!isNaN(n) && n >= 1 && n <= questions.length) {
            resolve(questions[n - 1]);
          } else {
            console.log("Invalid selection.");
            resolve(null);
          }
        }
      });
      return;
    }

    let selected = 0;
    let scrollOffset = 0;

    function getVisibleCount() {
      const { rows } = getTerminalSize();
      const availableRows = rows - 18;
      return Math.max(3, Math.min(questions.length, availableRows - 6));
    }

    function adjustScroll() {
      const vis = getVisibleCount();
      if (selected < scrollOffset) scrollOffset = selected;
      if (selected >= scrollOffset + vis) scrollOffset = selected - vis + 1;
    }

    // Setup keypress
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) process.stdin.setRawMode(true);

    render({ questions, selected, scrollOffset });

    const onResize = () => {
      adjustScroll();
      render({ questions, selected, scrollOffset });
    };
    process.stdout.on("resize", onResize);

    const onKeypress = (str, key) => {
      if (!key) return;
      if (key.name === "up" || key.name === "k") {
        selected = (selected - 1 + questions.length) % questions.length;
        adjustScroll();
        render({ questions, selected, scrollOffset });
      } else if (key.name === "down" || key.name === "j") {
        selected = (selected + 1) % questions.length;
        adjustScroll();
        render({ questions, selected, scrollOffset });
      } else if (key.name === "return" || key.name === "enter") {
        cleanup();
        resolve(questions[selected]);
      } else if (key.name === "q" || key.name === "escape" || (key.ctrl && key.name === "c")) {
        cleanup();
        if (key.ctrl && key.name === "c") {
          // Ctrl+C should exit process
          process.stdout.write("\n");
          process.exit(0);
        }
        resolve(null);
      } else if (key.name === "g" && !key.ctrl) {
        // go to top
        selected = 0;
        adjustScroll();
        render({ questions, selected, scrollOffset });
      } else if (key.name === "G" || (key.name === "g" && key.shift)) {
        selected = questions.length - 1;
        adjustScroll();
        render({ questions, selected, scrollOffset });
      }
    };

    function cleanup() {
      process.stdout.removeListener("resize", onResize);
      process.stdin.removeListener("keypress", onKeypress);
      if (process.stdin.isTTY) process.stdin.setRawMode(false);
      process.stdin.pause();
      clearScreen();
    }

    process.stdin.on("keypress", onKeypress);
  });
}

module.exports = { runTui, render };
