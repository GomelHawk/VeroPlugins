#!/usr/bin/env bash
# Stamp a new Vero plugin repository out of template/, the executable form of STANDARD.md.
#
#   scripts/new-plugin.sh <vero-x> <VeroX> "<Slogan.>" "<one-line description>" \
#       [--keeps "<sentence>"] [--requires "<sentence>"] [--dir <target>]
#
#   vero-x       the plugin key: lowercase, `vero-` and one word (vero-note)
#   VeroX        the display name: `Vero` and one capitalised word (VeroNote)
#   Slogan.      three or four words ending in a period ("Write it down.")
#   description  one plain-language sentence: what it does for the person
#   --keeps      what the move leaves in place, for the README's "Only from VeroPlugins"
#                paragraph (default: "VeroX keeps no data of its own, so nothing is lost
#                on the way.")
#   --requires   what else the plugin needs, for the README's Requirements (default:
#                "Nothing else to install.")
#   --dir        where to create it (default: ../<VeroX>, beside this repository)
#
# The new folder is a git repository on `main` with the GitHub remote set, every file
# staged, and the four checks already run. Nothing is committed and nothing is pushed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$HERE/template"

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

[ $# -ge 4 ] || usage
KEY="$1"; DISPLAY_NAME="$2"; SLOGAN="$3"; ONE_LINE="$4"; shift 4
KEEPS="$DISPLAY_NAME keeps no data of its own, so nothing is lost on the way."
REQUIRES="Nothing else to install."
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --keeps) KEEPS="${2:-}"; shift ;;
    --requires) REQUIRES="${2:-}"; shift ;;
    --dir) TARGET="${2:-}"; shift ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

case "$KEY" in
  vero-[a-z]*) [[ "$KEY" =~ ^vero-[a-z]+$ ]] || { echo "key must be vero-<word>, lowercase letters only: $KEY"; exit 1; } ;;
  *) echo "key must be vero-<word>, lowercase letters only: $KEY"; exit 1 ;;
esac
[[ "$DISPLAY_NAME" =~ ^Vero[A-Z][a-z]+$ ]] || { echo "display name must be Vero<Word>: $DISPLAY_NAME"; exit 1; }
[ "$(printf '%s' "$DISPLAY_NAME" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$KEY" | tr -d '-')" ] \
  || { echo "display name and key disagree: $DISPLAY_NAME vs $KEY (VeroNote <-> vero-note)"; exit 1; }
case "$SLOGAN" in
  *.) ;;
  *) echo "the slogan ends with a period: \"$SLOGAN\""; exit 1 ;;
esac
[ -n "$ONE_LINE" ] || { echo "the one-line description is empty"; exit 1; }
[ -d "$TEMPLATE/plugins/vero-x" ] || { echo "no template at $TEMPLATE"; exit 1; }
for tool in git python3 claude; do
  command -v "$tool" >/dev/null 2>&1 || { echo "$tool not found on PATH"; exit 1; }
done

[ -n "$TARGET" ] || TARGET="$HERE/../$DISPLAY_NAME"
if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  echo "refusing to write into a non-empty folder: $TARGET"; exit 1
fi
mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo "Creating $DISPLAY_NAME ($KEY) in $TARGET"
cp -R "$TEMPLATE/." "$TARGET/"
# what the engine writes beside a loaded module never travels with the template
rm -rf "$TARGET/plugins/vero-x/.claude-plugin/types" "$TARGET/plugins/vero-x/tsconfig.json"
mv "$TARGET/plugins/vero-x" "$TARGET/plugins/$KEY"

# The placeholders, in every text file. Binary files (the logos) are left alone.
export NP_KEY="$KEY" NP_DISPLAY="$DISPLAY_NAME" NP_SLOGAN="$SLOGAN" NP_ONE_LINE="$ONE_LINE" \
       NP_KEEPS="$KEEPS" NP_REQUIRES="$REQUIRES" NP_YEAR="$(date +%Y)" NP_TARGET="$TARGET"
python3 - <<'PY'
import os, pathlib
root = pathlib.Path(os.environ['NP_TARGET'])
pairs = [
    ('vero-x', os.environ['NP_KEY']),
    ('VeroX', os.environ['NP_DISPLAY']),
    ('SLOGAN_X', os.environ['NP_SLOGAN']),
    ('ONE_LINE_X', os.environ['NP_ONE_LINE']),
    ('KEEPS_X', os.environ['NP_KEEPS']),
    ('REQUIRES_X', os.environ['NP_REQUIRES']),
    ('YEAR_X', os.environ['NP_YEAR']),
]
changed = 0
for path in root.rglob('*'):
    if not path.is_file() or '.git' in path.parts:
        continue
    data = path.read_bytes()
    if b'\0' in data[:8192]:
        continue  # binary
    text = data.decode('utf-8')
    new = text
    for old, rep in pairs:
        new = new.replace(old, rep)
    if new != text:
        path.write_text(new, encoding='utf-8', newline='\n')
        changed += 1
print(f'  substituted the placeholders in {changed} files')
PY

# The shared files are the canonical ones, whatever the template holds.
cp "$HERE/shared/hooks/source-check.ts" "$TARGET/plugins/$KEY/hooks/source-check.ts"
cp "$HERE/shared/tests/source-check.test.ts" "$TARGET/plugins/$KEY/tests/source-check.test.ts"
# The plugin folder carries its own copies of the README and the LICENSE.
cp "$TARGET/README.md" "$TARGET/plugins/$KEY/README.md"
cp "$TARGET/LICENSE" "$TARGET/plugins/$KEY/LICENSE"
chmod +x "$TARGET/install.sh" "$TARGET/uninstall.sh" "$TARGET/tests/smoke.sh"

(
  cd "$TARGET"
  if ! git init -q -b main 2>/dev/null; then
    git init -q
    git symbolic-ref HEAD refs/heads/main
  fi
  git remote add origin "git@github.com:GomelHawk/$DISPLAY_NAME.git"
  git add -A
)

echo
echo "Checking the new repository..."
status=0
(cd "$TARGET" && tests/smoke.sh) || status=1
(cd "$TARGET" && claude plugin validate "plugins/$KEY") || status=1
(cd "$TARGET" && claude plugin validate "plugins/$KEY" --strict) || status=1
(cd "$TARGET" && claude plugin test "plugins/$KEY") || status=1

echo
if [ "$status" = 0 ]; then
  echo "$DISPLAY_NAME is in place: $TARGET (git on main, remote set, everything staged, nothing committed)."
else
  echo "$DISPLAY_NAME is in place at $TARGET, but a check failed: see above."
fi
cat <<TODO

Left to do by hand (STANDARD.md in VeroPlugins has the rules for each):
  1. Logos: draft a square icon-over-wordmark logo and a horizontal one with the slogan,
     then run VeroPlugins' scripts/logos.py on them; the results replace the placeholders
     in assets/.
  2. README.md: fill the TODO comments (intro, What you get, Using it, Options,
     Uninstalling), then copy it over plugins/$KEY/README.md (the smoke test checks).
  3. plugins/$KEY/hooks/register.tsx: the plugin's own hooks, each starting with the
     stopped check; its tests beside tests/stopped.test.tsx; CLAUDE.md's TODOs.
  4. In VeroPlugins: the catalog entry in .claude-plugin/marketplace.json (name $KEY,
     git-subdir https://github.com/GomelHawk/$DISPLAY_NAME.git, path plugins/$KEY, the
     description opening with the slogan, no version), the README table row, and
     scripts/assets.py for the icon, the banner and the social preview.
  5. On GitHub: create GomelHawk/$DISPLAY_NAME (public, MIT), push main, add the
     VEROPLUGINS_DISPATCH_TOKEN secret, set About and topics per STANDARD.md, upload the
     social preview.
  6. Release: bump version in plugin.json, tag v<version>, GitHub Release; CI green in
     both repositories.
TODO
exit "$status"
