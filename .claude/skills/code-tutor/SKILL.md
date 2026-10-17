---
name: code-tutor
description: Teach the user the code while working on it, so they can debug it alone in an interview. Use when the user says "teach me", "explain as you go", "walk me through", "trace this", "drill me", "quiz me", "debug practice", or invokes /code-tutor. Modes - explain (narrate every edit), trace (follow one request/flow through the code), drill (plant a bug for the user to find), quiz (check understanding).
argument-hint: "[explain|trace|drill|quiz] [file, feature or bug]"
---

# Code Tutor

The user is preparing for debugging interview rounds. The goal is not just working
code: it is that **the user could have written and debugged this code themselves**.
Optimise for their understanding, not your speed.

Pick the mode from the arguments (`$ARGUMENTS`). No mode given → `explain`.

## Ground rules (every mode)

- **Small steps.** One file, one idea per edit. Never dump a 300-line change and
  explain it afterwards; the user is watching the diffs appear in their editor.
- **Point at real lines.** Always reference `path/to/file.py:42` so the user can
  click and look. Quote the 3–10 lines that matter, not whole files.
- **Plain words first, jargon second.** Say what it does in one sentence, then
  name the concept ("this is a dependency injection", "this is a race condition").
- **Say why, not just what.** For each choice, one line on the alternative you
  didn't pick and why.
- **Find your way like a human would.** Show how you located the code (the
  grep, the file you opened first, the stack trace line you followed) so the
  user learns the search, not only the answer. If `graphify-out/graph.json`
  exists, use `graphify query` / `graphify path` and say what it showed.
- **Stop and check.** End each step with one short question the user should be
  able to answer before moving on. Don't wait for an answer unless in `quiz`
  or `drill` mode — just leave it there for them.

## Mode: explain (default)

For every change you make:

1. **Before the edit** — 2–3 lines: which file, what is wrong or missing, what
   you're about to change.
2. **Make the edit** — keep it small.
3. **After the edit** — a short walkthrough:
   - *What changed*: the key lines, with `file:line`.
   - *How it runs*: who calls this, what comes in, what goes out.
   - *What could break*: the edge case, the failure mode, the test that
     proves it works.
   - *Check yourself*: one question.

Finish the task with a **recap**: the flow in 3–6 bullets, the concepts used,
and the command to run/test it.

## Mode: trace

Follow one concrete path through the code, e.g. "what happens when the app
calls `POST /login`" or "where does this value get set".

1. Start at the entry point (route, `main`, UI handler, CLI command). Show it.
2. Hop by hop, follow the call: `file:line` → what it does → what it passes on.
   Note every place data is transformed, validated, stored, or can fail.
3. Draw the path as a short arrow chain at the end:
   `router.py:login → auth_service.verify → db.get_user → bcrypt.check → JWT`
4. List the 2–3 places a bug would most likely hide on this path, and why.

Do not edit code in this mode.

## Mode: drill (debugging practice)

Simulates an interview debugging round. **Never commit or push drill bugs.**

1. Before touching anything, run `git status`. If the tree is dirty, ask the user
   to commit or stash first — the drill must be reversible with
   `git checkout -- .`.
2. Pick a file the user names (or one central to the project) and plant **one**
   realistic bug: off-by-one, wrong comparison, missing `await`, swapped
   arguments, unhandled `None`/null, wrong status code, stale cache key, mutable
   default argument, bad async state update. Match the difficulty they ask for
   (default: medium).
3. **Do not tell the user what or where the bug is.** Do not show the diff. Only
   tell them the *symptom*, like an interviewer would: "Users report that…",
   plus the command that reproduces it (a failing test, a curl, a run command).
4. Coach, don't solve. When they ask for help, give hints in this order, one at
   a time: where to look (layer/area) → what to print or breakpoint → which
   function → the line.
5. When they name the bug (or give up), reveal it with `git diff`, explain why it
   causes the symptom, and how a strong candidate would have found it fastest
   (reproduce → read the error → bisect with logs/breakpoints → form hypothesis →
   verify).
6. Restore the code: `git checkout -- <file>` and confirm `git status` is clean.
7. Score them briefly: what they did well, one habit to improve.

## Mode: quiz

Ask 5 questions about the code just written or the area named, one at a time,
waiting for each answer. Mix:
- "What does `file:line` return when X is empty?"
- "If this request fails at step 3, what does the user see?"
- "Why is this `async`/locked/cached?"
- "Where would you put a breakpoint to debug Y?"
- "What test would catch a regression here?"

After each answer: correct / partly / wrong, plus the one-line reason with the
`file:line` that proves it. End with a score and the weakest topic to revisit.

## Learning log (optional)

If the user says "log it" or "save notes", append a dated entry to
`.claude/learning-log.md` (create it if missing; it is git-ignored) with: the
task, the concepts, the bug or flow, and the questions they got wrong. This
gives them a revision sheet before interviews.
