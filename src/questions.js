const fs = require("fs");
const path = require("path");

function findQuestionsFile() {
  // Search order: beside executable, repo root, HOME/.grim, cwd
  const candidates = [
    path.join(__dirname, "..", "questions.md"),
    path.join(__dirname, "..", "questions.txt"),
    path.join(process.cwd(), "questions.md"),
    path.join(process.cwd(), "questions.txt"),
    path.join(__dirname, "questions.md"),
  ];

  // Also check relative to GRIM_DIR if set via env or home
  const home = process.env.HOME || process.env.USERPROFILE || "";
  if (home) {
    candidates.push(path.join(home, ".grim", "questions.md"));
    candidates.push(path.join(home, ".grim", "questions.txt"));
  }

  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }
  // Default to repo root questions.md (even if missing, caller will handle)
  return path.join(__dirname, "..", "questions.md");
}

function parseQuestions(content) {
  // Supports markdown with ## Title delimiters.
  // Also supports plain text with === or Title: separators? Keep simple: ## only.
  // If no ## found, treat whole file as single question.
  const lines = content.split(/\r?\n/);
  const questions = [];
  let currentTitle = null;
  let currentBody = [];

  function flush() {
    if (currentTitle !== null) {
      const body = currentBody.join("\n").trim();
      if (body.length > 0) {
        questions.push({ title: currentTitle.trim(), body, raw: `## ${currentTitle}\n\n${body}` });
      } else {
        questions.push({ title: currentTitle.trim(), body: "", raw: `## ${currentTitle}` });
      }
    }
  }

  for (const line of lines) {
    const m = line.match(/^##\s+(.+)$/);
    if (m) {
      flush();
      currentTitle = m[1];
      currentBody = [];
    } else {
      if (currentTitle !== null) {
        currentBody.push(line);
      } else {
        // content before first ## — ignore unless no ## at all
        // If file has no ##, we'll handle fallback after loop
      }
    }
  }
  flush();

  // Fallback: no ## headings found
  if (questions.length === 0) {
    const trimmed = content.trim();
    if (trimmed.length > 0) {
      // Try to split by double newlines with title-like first line
      questions.push({ title: "Untitled Problem", body: trimmed, raw: trimmed });
    }
  }

  return questions;
}

function loadQuestions(filePath) {
  const target = filePath || findQuestionsFile();
  if (!fs.existsSync(target)) {
    return { filePath: target, questions: [], error: `Questions file not found: ${target}` };
  }
  try {
    const content = fs.readFileSync(target, "utf8");
    const questions = parseQuestions(content);
    return { filePath: target, questions, error: null };
  } catch (e) {
    return { filePath: target, questions: [], error: e.message };
  }
}

module.exports = { findQuestionsFile, parseQuestions, loadQuestions };
