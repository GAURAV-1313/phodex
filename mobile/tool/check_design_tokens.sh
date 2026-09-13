#!/usr/bin/env bash
# Design-token lint guard.
#
# Feature screens must build on the shared kit (lib/shared/widgets) and the
# tokens in lib/shared/theme instead of hand-picking colors, font sizes, and
# corner radii. This fails CI when a screen bypasses them so the design
# system cannot silently drift again.
#
# Allowed escape hatch for a genuine exception: append `// token-ok` to the
# line with a short reason.
set -euo pipefail
cd "$(dirname "$0")/.."

targets=(lib/features lib/app)
violations=0

check() {
  local pattern="$1" label="$2" exclude="${3:-__none__}"
  local hits
  hits="$(grep -rnE "$pattern" "${targets[@]}" | grep -v 'token-ok' | grep -vE "$exclude" || true)"
  if [[ -n "$hits" ]]; then
    echo "== $label"
    echo "$hits"
    echo
    violations=$((violations + $(echo "$hits" | wc -l | tr -d ' ')))
  fi
}

check 'Color\(0x'                       'Raw hex colors — use context.colors.*'
check 'Colors\.[a-zA-Z]+'               'Material Colors.* — use context.colors.*' 'Colors\.transparent'
check 'fontSize: *[0-9]'                'Literal font sizes — use context.text.* or AppTypeScale.*'
check 'Radius\.circular\( *[0-9]'       'Literal corner radii — use AppRadii.*'
check 'TextStyle\(\s*$'                 'Bare TextStyle(...) blocks — start from context.text.* and copyWith'
check 'styleFrom\('                     'Inline *.styleFrom overrides — theme the component in app_theme.dart instead'

if (( violations > 0 )); then
  echo "Design-token check failed: $violations violation(s) in ${targets[*]}."
  exit 1
fi
echo "Design-token check passed."
