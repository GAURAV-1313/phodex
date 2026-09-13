# Phodex Mobile — UI Design Spec (v2.0)

**Status:** Source of truth for the Flutter app in `mobile/`. Supersedes v1.2, which described a black-and-blue palette, Inter, and a menu-sheet navigation that the shipped app never used. Everything in this document is implemented; when the app changes direction, update this file first.

**Last updated:** 2026-09-11

---

## 1. Principles

1. **One system, every screen.** Screens are assembled from the shared kit (`lib/shared/widgets/stitch_ui.dart`) and tokens (`lib/shared/theme/`). `mobile/tool/check_design_tokens.sh` fails CI when a screen uses a raw color, a literal font size, a literal radius, a bare `TextStyle(`, or a `styleFrom(` override.
2. **The mascot is the brand.** The robin (an original character, `PhodexMascot`) replaces spinners, empty-state icons, and completion icons. Its mood tracks task state (`moodForTaskStatus`).
3. **Warm cream, vivid indigo.** A characterful serif (Fraunces) for hero moments, IBM Plex Sans for UI, IBM Plex Mono for anything terminal-like.
4. **Safety is visible.** Approval gates, runtime status, and reconnection are always shown inline, never hidden behind a toast.
5. **Two runtimes, one app.** Whether tasks run on a paired laptop or on Phodex Cloud is a one-tap choice in onboarding and changeable from Account; every other screen is identical.

## 2. Tokens (`lib/shared/theme/`)

### 2.1 Color — `AppColors` (ThemeExtension, `context.colors`)

| Token | Light | Dark | Use |
|---|---|---|---|
| bgPrimary | `#FBF9F7` | `#17151C` | screen ground |
| bgSurface | `#FFFFFF` | `#1D1B24` | sheets, dock, dialogs |
| bgCard | `#FFFFFF` | `#221F2A` | cards, composer |
| bgInput | `#F5F3EF` | `#28242F` | inputs, pills, skeletons |
| textPrimary / textSecondary / textMuted | `#1D1A22` / `#67616F` / `#96909C` | `#F5F3F7` / `#A79FB0` / `#716A7D` | text ladder |
| borderSubtle | `#EAE6E9` | `#322D3B` | hairlines |
| accentPrimary / Deep / Soft | `#5B4FE8` / `#433AC4` / `#EEECFC` | `#8B7FFF` / `#6C5FE0` / `#2C2650` | actions, selection, tints |
| accentSuccess / Warning / Error | `#16A34A` / `#D97706` / `#DC2626` | `#34D399` / `#F3A73F` / `#F16565` | status |
| mascot* | robin palette (theme-independent) | | `PhodexMascot` only |

Derived getters: `isDark`, `onAccent` (always white), `shadow` / `shadowStrong` (stronger alpha in dark so shadows stay visible), `scrim`, and the always-dark `terminalBg` / `terminalText` / `terminalMuted` for logs and command output.

The Material `ColorScheme` is built **entirely** from these tokens in `app_theme.dart`, and every component the app uses is themed there (buttons, chips, dividers, inputs, dialogs, sheets, snackbars, switches, list tiles, progress, badges, tooltips). Screens never call `styleFrom`.

### 2.2 Type — `AppTypeScale` and `context.text`

One ladder: micro 11 · caption 13 · bodySmall 15 · body 17 · subhead 20 · title 24 · headline 28 · displaySmall 34 · displayLarge 40. The Material `TextTheme` is derived from it:

| Slot | Face | Size | Weight |
|---|---|---|---|
| displayLarge / displayMedium / displaySmall | Fraunces | 40 / 34 / 34 | 600 |
| headlineLarge / headlineMedium | Fraunces | 28 | 600 (screen titles) |
| headlineSmall | Plex Sans | 24 | 600 (card headlines, sheet titles) |
| titleLarge / titleMedium / titleSmall | Plex Sans | 20 / 17 / 15 | 600 |
| bodyLarge / bodyMedium / bodySmall | Plex Sans | 17 / 15 / 13 | 400 (bodyMedium & bodySmall are textSecondary) |
| labelLarge / labelMedium / labelSmall | Plex Sans | 15 / 13 / 11 | 600 / 500 / 700 (labelSmall is uppercase eyebrow) |

Use `context.text.<slot>?.copyWith(...)`; `AppTypography.display()` for custom hero sizes; `AppTypography.code()` for mono.

### 2.3 Spacing — `AppSpacing`

s2 · s4 · s8 · s12 · s16 · s20 · s24 · s32 · s40 · s48, plus `screen` (24, horizontal inset) and `screenTop` (16). Use `stitchScreenPadding` / `stitchScreenPaddingNoDock` for a screen's scroll content.

### 2.4 Radii — `AppRadii`

chip 12 · button 18 · global 20 · card 24 · input 24 · sheet 28 · pill 999. Cards, the composer, and inputs share the same generous rounding.

## 3. Navigation

- **Dock** (`StitchDock`): four tabs — Agents (home, mascot glyph), Tasks (activity), Repos, Account — switched with `context.go`. Tab screens use `StitchScaffold` (safe area, bottom fade, dock).
- **Detail screens** (Session, Repo detail, Approvals, Account sub-pages, onboarding steps) are **pushed** (`context.push`) and exit with the one back affordance, `StitchBackButton` (pops, or falls back to Home when there is no stack). No screen may hardcode a different exit.
- **Transitions:** tab siblings fade-through; pushed screens slide up (`page_transitions.dart`).
- **Guards:** `app_router.dart` has a splash route at `/` and a `redirect` driven by auth, runtime, and onboarding state (see §5). Deep links never bypass onboarding.

## 4. Shared kit (`lib/shared/widgets/`)

| Component | Purpose |
|---|---|
| `StitchScaffold` | Shell for every screen: background, safe area, dock (`showDock`) or a pinned `bottom` widget (composer) |
| `StitchHeader` | Top row: mascot (tab screens) or `StitchBackButton` + title (detail screens); bell with `bellBadge` only when approvals are pending; optional `trailing` action |
| `StitchCard` | Elevated card on `bgCard`, `AppRadii.card`, theme shadow, optional tap |
| `StitchPrimaryButton` / `StitchSecondaryButton` | Full-width 58dp filled / outlined actions; `loading` state |
| `TaskStatusChip` | The status pill (`queued`, `running`, `waiting_approval` → "Needs approval", `completed`, `failed`, `cancelled`), pulsing dot while live; carries a Semantics label |
| `ContextPill` | Repository · branch the task or composer targets; `emphasized` when it is a call to action |
| `ComposerBar` | The single text-entry surface: context pill above, send button that becomes a stop button while running, disabled until a repository is chosen |
| `StatusBanner` | Inline condition banner (info / success / warning / error, optional action, `busy` spinner) — used for reconnecting, offline runtime, form errors |
| `StitchEmptyState` | Mascot empty state with title, message, and up to two actions |
| `StitchErrorState` | Mascot error state with retry; never shows raw exception text |
| `StitchAsyncView<T>` | Renders loading / error / empty / data for an `AsyncValue` identically everywhere; keeps stale data on refresh |
| `PhodexLoading` | Mascot loading state (thinking) |
| `StitchTerminalBlock` | Monospaced output on the always-dark terminal surface (git status, payloads, logs) |
| `TraceCard` | One timeline entry in a session: type icon, header, timestamp, expandable details (tool calls, file changes, usage) |
| `StitchSectionLabel` | Uppercase eyebrow label |
| `showStitchSheet` | Modal bottom sheet with the app's chrome (rounded top, handle, keyboard inset) |
| `showRejectReasonDialog` | Optional reason before rejecting an approval |

## 5. Onboarding

Persisted in SharedPreferences (`phodex_onboarding_version`, repo step, notifications prompted) by `OnboardingController`; sign-out resets it.

1. **Splash** (`/`) — mascot while sessions and preferences restore. Redirects, never renders content.
2. **Welcome** (`/welcome`) — hero mascot, "Your AI engineer, in your pocket.", three value bullets, **Get started**.
3. **Runtime** (`/runtime`) — two cards: **Phodex Cloud** (recommended; probes `/runtime/public`, stores the cloud URL) and **My desktop** (→ Connect desktop). Reused from Account with `?from=account`.
4. **Connect desktop** (`/connect-desktop`) — QR scan (`/scan`, with camera-denied and manual-entry fallbacks, payload validated as an http(s) URL) or manual address; success shows the mascot and continues; "Forget this desktop" when one is stored.
5. **Sign in** (`/sign-in`) — runtime summary with "Change", **Continue with Google**, **Try the demo** when the runtime exposes a demo account. Errors are specific: cancelled, no network, unsupported platform, runtime unreachable (with a "Change runtime" action). The Google button is gated until a runtime is chosen.
6. **First repo** (`/setup/repo`) — cloud: GitHub URL, optional branch and token; desktop: pick a synced repo, or an empty state pointing back to pairing. Skippable.
7. **Notifications** (`/setup/notifications`) — explains approval and completion pushes; **Enable** or **Not now**. Push registration also runs silently at startup once signed in.
8. **Home first run** — mascot empty state with starter suggestions; the composer stays disabled with a "Pick a repository" pill until a repository is selected.

## 6. Screens

| Screen | Shell | States | Notes |
|---|---|---|---|
| Home | dock | loading · empty · error · reconnecting banner | ComposerBar + ContextPill, recent tasks with TaskStatusChip, bell badge = pending approvals |
| Tasks (Recents) | dock | loading · empty (CTA "Create your first coding task") · filtered-empty · error | search + themed filter chips |
| Session | no dock, ComposerBar pinned | skeleton loading · error · reconnecting banner | header status chip (pulsing while running) + ContextPill, TraceCard timeline, terminal blocks, approval card slides in, mascot completion card, stop button while running |
| Approvals | no dock | loading · empty · error · action failure snackbar with retry | summary card (pending count, "gated on your phone"), payload preview in a terminal block |
| Repos | dock | loading · empty (desktop: connect desktop; cloud: add GitHub repo) · error | overview card (runner, synced/active counts, "Metadata sync"), required copy: desktop "Repo sync is metadata-only — no shell, file, or search access from your phone." / cloud "Cloud workspaces are cloned on Phodex Cloud and run there.", "Add GitHub repository" sheet |
| Repo detail | no dock | loading · not found · error | never a bare scaffold; "Set as default" pops with a snackbar |
| Account | dock | loading · error | profile, usage, Runtime card (runner status, URL, change/connect/forget desktop, GitHub token on cloud), appearance, AI engine, sessions, notifications, sign out |
| Sessions | no dock | loading · empty · error | |
| Notifications | no dock | unavailable (mascot resting) · denied (mascot error) · enabled | |
| AI engine | no dock | loading · error | |

## 7. Motion

- Cards and list items enter with `StaggerIn` (fade + 5% slide, 35 ms stagger).
- Tab switches fade-through (260 ms); pushes slide up (320 ms).
- `TaskStatusChip` pulses its dot while live events arrive.
- The approval card slides in from the bottom of the session timeline.
- The mascot animates continuously; tests use bounded pumps, never `pumpAndSettle`.

## 8. Accessibility

- Every interactive control has a ≥ 48 dp target (theme `minimumSize`).
- `Semantics` labels on status chips, context pills, dock tabs, approval buttons, trace sections, banners (live regions), loading states, and the composer stop/send buttons.
- Text sizes come from the type ladder, so the system text scaler applies everywhere.
- Contrast: all text tokens meet WCAG AA on their grounds in both themes.

## 9. Dark mode

Both palettes are first-class. Nothing in `lib/features` may reference a hex color; the only deliberately fixed colors are the terminal surface tokens and the mascot palette.

## 10. Review checklist (per screen)

1. Built on `StitchScaffold`/`StitchHeader`; back is `StitchBackButton`.
2. Has loading, empty (where a list exists), and error states via `StitchAsyncView` or the kit widgets.
3. Zero violations from `tool/check_design_tokens.sh`.
4. Reads correctly in dark mode.
5. Pushed screens are entered with `context.push`.
6. Status and actions carry Semantics labels.
7. Has a widget test covering the happy path and the empty/error state.

## 11. Changelog

- **2.0 (2026-09-11)** — Rewritten to match the shipped app: cream/indigo palette, Fraunces + IBM Plex, dock navigation, onboarding flow with runtime chooser, cloud runtime, shared kit inventory, lint guard.
- 1.2 (2026-04-29) — original draft (Inter, black/blue, menu sheet). Superseded.
