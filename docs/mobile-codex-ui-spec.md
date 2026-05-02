# Phodex Android UI Design Spec

Status: Draft v1.2
Last updated: 2026-04-29
Owner: Gaurav + Codex

## 1. Purpose
This file is the long-run source of truth for the Phodex Android UI.
We will update this file as screens evolve so product, design, and engineering stay aligned.

## 2. Product Direction
- Base inspiration: ChatGPT mobile UI (dark, minimal, rounded, clean)
- Brand direction: Codex-style coding control surface
- Principle: Minimal by default, rich details on demand
- Primary use: Create coding tasks, monitor live progress, handle approvals, review final output

## 3. UX Principles
1. Clarity over decoration: every UI element should map to user action or task state.
2. Fast scanning: user should understand task status in <3 seconds.
3. Progressive disclosure: summary first, details expandable.
4. Trust and transparency: show operational traces (progress/log/tools), not hidden private reasoning.
5. One-thumb operation: key controls reachable in bottom area.

## 4. Information Architecture
Primary screens:
1. Home (recents + quick actions)
2. Session (interactive task screen)
3. Repos (synced repos + select context)
4. Approvals Inbox (pending approvals across tasks)
5. Account (profile, usage, limits)

Navigation model (V1 current):
- Chat-style Home as landing screen
- Menu sheet from Home routes to Recents, Repos, Approvals, Account
- Session opened as full-screen route

## 5. Visual System (V1)
### 5.1 Color tokens
- `bg.primary`: `#000000`
- `bg.surface`: `#121316`
- `bg.card`: `#1B1D22`
- `bg.input`: `#22252B`
- `text.primary`: `#FFFFFF`
- `text.secondary`: `#A6ABB4`
- `text.muted`: `#7A808A`
- `border.subtle`: `#2E323A`
- `accent.primary`: `#4DA3FF`
- `accent.success`: `#2FCB7A`
- `accent.warning`: `#F5B83D`
- `accent.error`: `#FF6B6B`

### 5.2 Typography
- Font family: Inter / system sans fallback
- Title XL: 34/40 semibold
- Title L: 28/34 semibold
- Heading: 22/28 semibold
- Body: 16/24 regular
- Body compact: 15/22 regular
- Caption: 13/18 medium
- Code/trace: JetBrains Mono 13/18

### 5.3 Shape + spacing
- Global corner radius: 20dp
- Pill radius: 999dp
- Card radius: 18dp
- Input bar radius: 24dp
- Base spacing scale: 4, 8, 12, 16, 20, 24, 32

## 6. Core Components
1. `ContextPill`
- Shows selected repo + branch (example: `phodex • main`)
- Optional device badge (example: `Macbook Pro`)

2. `TaskStatusChip`
- Values: queued, starting, running, waiting_approval, completed, failed, cancelled
- Color rules:
  - running: accent.primary
  - waiting_approval: accent.warning
  - completed: accent.success
  - failed/cancelled: accent.error

3. `TraceCard`
- Used for `task.progress`, `task.log`, and tool-like entries
- Header: event/tool type + timestamp
- Body: message + structured details
- Codex JSONL mapping:
  - `item.type=agent_message` renders as assistant timeline text
  - `item.type=command_execution` renders as a compact `ToolShell` card with command, output, status, and exit code
  - `usage` renders as a compact usage row for input/output/reasoning tokens
- Supports file-change rows when event data includes `file_changes` list:
  - row format: action label + path + `+added` / `-removed`
  - example item: `{ "action": "deleted", "path": "index.html", "added": 0, "removed": 255 }`

4. `ApprovalCard`
- Title, risk hint, action description, payload preview
- Actions: Approve / Reject
- Sticky bottom action bar on session when pending

5. `IssueCard`
- Shows errors with `error_code`, retryability, and message
- Driven by `/tasks/{task_id}/issues`

6. `ComposerBar`
- Bottom input with plus, text field, send/voice style CTA
- Placeholder: `Reply to this task...`

## 7. Screen Specs
## 7.1 Home
Goal: quick launch + task resume.

Layout:
1. Top bar: circular menu button, mode pill (`Thinking`/`Instant`), account/comment action pill
2. Center hero: `What can I help with?`
3. Quick pill actions:
   - Create image
   - Surprise me
   - Analyze data
   - Analyze images
4. Bottom translucent composer:
   - plus button
   - input placeholder `Ask Phodex`
   - microphone
   - waveform/send CTA

Primary actions:
- Tap task -> Session screen
- FAB/button -> New Task composer sheet

## 7.2 Session (Interactive)
Goal: live control of one task.

Top section:
- Back
- Task title/context
- `ContextPill` (repo/branch)
- `TaskStatusChip`

Main timeline:
- User prompt bubble
- Assistant/progress text as plain chat transcript rows, not heavy cards
- Muted Codex activity summaries:
  - `Ran 3 commands`
  - `Explored 17 files, 1 search, 1 list`
  - `Thinking`
- Git-style edit rows:
  - `Edited approvals_screen.dart +222 -33`
  - `Created index.html +326 -0`
- `TraceCard`/tool detail expansion remains available later for deeper payload inspection
- `ApprovalCard` when waiting approval
- `IssueCard` if failed/rejected/runtime issue

Bottom:
- translucent `ComposerBar` inspired by ChatGPT mobile
- active repo/branch label above input
- stop button while task is running

Realtime behavior:
- Subscribe SSE: `GET /tasks/{task_id}/stream`
- Replay missed events via `after_sequence`
- Keep local state by `sequence` order

## 7.3 Repos
Goal: select synced project context.

Layout:
- Chat-style black page with round back button and Mac companion status affordance
- Top metadata overview card:
  - synced repo count
  - active repo count
  - `metadata sync` badge
- Repo list cards with:
  - name
  - git root and local path (truncated, monospace shell block)
  - branch
  - active/inactive badge
  - selected state badge
- Action: `Use` / selected state `Active`
- V1 copy must be explicit that repo sync is metadata-only: no shell, file content, or search from phone.

API:
- `GET /repos`
- `POST /repos/{repo_id}/select`

## 7.4 Approvals Inbox
Goal: resolve pending approvals quickly.

Layout:
- Chat-style black page with round back + refresh actions
- Summary card with pending approval count and phone-gate hint
- Approval cards:
  - risk/kind pill
  - title and description
  - payload preview in dark monospace shell block
  - status label
- Actions: Approve / Reject as rounded bottom buttons

API:
- `GET /approvals/pending`
- `POST /approvals/{id}/approve`
- `POST /approvals/{id}/reject`

## 7.5 Account
Goal: account confidence + usage transparency.

Sections:
1. Profile
2. Usage + limits mini cards directly below profile
3. `My Phodex` settings group
4. Account details group
5. Sign-out and production auth controls (later)

API:
- `GET /account/me`
- `GET /account/usage`
- `GET /account/limits`

## 8. Event-to-UI Mapping (Important)
Backend event envelope:
- `event_id`
- `task_id`
- `sequence`
- `type`
- `timestamp`
- `data`

Mapping:
1. `task.created` -> timeline info row
2. `task.starting` -> status chip + trace card
3. `task.running` -> status chip + trace card
4. `task.progress` -> trace card (short message)
5. `task.log` -> trace card (monospace, expandable)
6. `approval.requested` -> approval card + sticky action bar
7. `approval.approved` -> success trace card
8. `approval.rejected` -> issue card
9. `task.completed` -> final summary section
10. `task.failed` -> issue card + retry affordance
11. `task.cancelled` -> muted issue/state row

## 9. Thinking Visibility Policy
What we show:
- operational progress
- action logs
- tool-like traces
- approval rationale
- final summary

What we do not show:
- raw private chain-of-thought/internal hidden reasoning

UI label guidance:
- Use `Thinking` as user-friendly label for progress mode
- In details, use wording like `Reasoning summary` and `Execution trace`

## 10. Empty / Loading / Error States
1. Empty recents: CTA `Create your first coding task`
2. Session loading: skeleton timeline blocks
3. SSE disconnected: top inline banner `Reconnecting...`
4. Approval action failed: inline toast + retry
5. Repo sync unavailable: hint `Open Mac companion and sync repos`

## 11. Motion and polish
- 180ms fade/slide for new timeline cards
- status chip color transition on lifecycle changes
- approval bar slide-in from bottom
- subtle pulse dot when live events are arriving

## 12. Accessibility
- minimum touch target 44dp
- text contrast >= WCAG AA
- semantic labels for status chips, approval buttons, and trace sections
- dynamic type compatibility for body and headings

## 13. V1 Scope Boundaries
In scope:
- task create/list/detail/reply/cancel
- SSE live events
- approvals
- repo visibility + context selection
- account usage/limits visibility

Out of scope:
- remote desktop
- browser automation UI
- local file content browsing/search on phone
- direct Mac command execution UI

## 14. Compose Implementation Notes (Next)
Recommended package structure:
- `ui/theme`
- `ui/components`
- `feature/home`
- `feature/session`
- `feature/repos`
- `feature/approvals`
- `feature/account`

State model recommendation:
- `UiState` + `UiEffect` + `UiAction` (MVI-ish)
- SSE as cold flow -> shared flow -> reducer by event sequence

## 15. Design Review Checklist
Before shipping each screen:
1. matches token/color system
2. supports loading/empty/error
3. supports dark mode readability
4. one-handed interaction validated
5. lifecycle states visible at a glance
6. API contract fields mapped fully

## 16. Changelog
- 2026-04-22: Initial V1 spec drafted from provided references and Codex task workflow.
- 2026-04-22: Flutter Phase 1 app scaffold implemented in `/Users/gaurav/phodex/mobile` (UI-first with contract-accurate mocks).
- 2026-04-22: Visual direction tightened to ChatGPT-like phone layout (home/recents/session/account), with chat-style navigation replacing bottom tabs.
- 2026-04-26: Session trace cards updated to render Git-style file change summaries (`Created/Deleted/Modified`, path, `+/-` stats) from event payload.
- 2026-04-29: Repos, Approvals, Recents, and Account refined toward the same black/glass ChatGPT-like visual system with Codex-specific metadata, approval, and usage surfaces.
- 2026-04-29: Session timeline direction updated to match Codex transcript style: narrative progress text, muted activity summaries, command exploration summaries, and inline file-change rows.

---

If we change any major layout direction, update this file first, then implement.
