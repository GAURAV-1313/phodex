# Design canvas (Claude Design)

The Phodex mobile design canvas lives as an Artifact (see the link in the
project notes) and is generated from the app's real tokens so it stays in step
with `mobile/lib/shared/theme` and `stitch_ui.dart`.

- `generate.py` — builds every artboard from the palette, type ladder, spacing
  and radii lifted from the Flutter theme files, plus `canvas.json` (three
  pages: Onboarding flow, Screens, Design system).
- `*.dc.html` — the artboards (Design Component format). Each phone artboard
  has a `theme` tweak (light / dark). `Main.dc.html` is Home (first run).
- `canvas.json` — layout, pages, sticky notes, launch view.

To change the design: edit `generate.py` (or an artboard directly), run
`python3 generate.py`, then re-seed and republish the canvas from a Claude Code
session with `/design` (the helper re-seeds from these working files).
