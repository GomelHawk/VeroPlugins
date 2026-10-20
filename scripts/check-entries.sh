#!/usr/bin/env bash
# The per-entry checks VeroPlugins' CI runs over .claude-plugin/marketplace.json, and the
# standard's machine-checkable rules (STANDARD.md, section 11).
#   scripts/check-entries.sh                    every entry, each cloned from its repository
#   scripts/check-entries.sh vero-diff          one entry
#   scripts/check-entries.sh --local DIR NAME   one entry, checked in a local clone instead
#
# Every problem is printed; the exit code is 1 when there was at least one. Needs git, jq,
# python3 and the claude CLI; no account.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT/.claude-plugin/marketplace.json"
SHARED_CHECK="$ROOT/shared/hooks/source-check.ts"
SHARED_TABLE="$ROOT/shared/tests/source-check.test.ts"
TEMPLATE_NOTES="$ROOT/template/CLAUDE.md"

ONLY=""
LOCAL=""
if [ "${1:-}" = "--local" ]; then
  LOCAL="${2:-}"; ONLY="${3:-}"
  [ -d "$LOCAL" ] && [ -n "$ONLY" ] || { echo "usage: $0 --local DIR NAME"; exit 1; }
else
  ONLY="${1:-}"
fi

for tool in git jq python3 claude; do
  command -v "$tool" >/dev/null 2>&1 || { echo "$tool not found on PATH"; exit 1; }
done
[ -f "$CATALOG" ] || { echo "no catalog at $CATALOG"; exit 1; }
[ -f "$SHARED_CHECK" ] && [ -f "$SHARED_TABLE" ] || { echo "no canonical source check under $ROOT/shared"; exit 1; }

WORK="$(mktemp -d 2>/dev/null || mktemp -d -t veroplugins)"
trap 'rm -rf "$WORK"' EXIT

fail=0
ok()      { printf '  \033[32mok\033[0m    %s\n' "$1"; }
problem() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=1; }
note()    { printf '  note  %s\n' "$1"; }

# The lines of the README's canonical Install and Updating sections (STANDARD.md, section
# 3; the text is template/README.md's), with the plugin's key and display name filled in.
# Each must appear as a whole line.
required_lines() {
  local key="$1" display="$2"
  sed "s/vero-x/$key/g; s/VeroX/$display/g" <<'LINES'
Two commands, typed inside Claude Code. Type the first, press Enter and wait for
`✔ Successfully added marketplace: vero-plugins`, then type the second:
/plugin marketplace add GomelHawk/VeroPlugins
/plugin install vero-x@vero-plugins
Then restart Claude Code. If you already added VeroPlugins for another Vero plugin, only
> Type each line on its own. If a panel appears asking for a `marketplace source`, it
Prefer a terminal? The same two commands work there, back to back:
claude plugin marketplace add GomelHawk/VeroPlugins
claude plugin install vero-x@vero-plugins
In the desktop app, where `/plugin` does not run: click **+** next to the prompt box, then
**Only from VeroPlugins.** VeroX works only when installed from VeroPlugins. A copy
Nothing updates by itself, and Claude Code will not tell you a new version exists. New
/plugin marketplace update vero-plugins
/plugin update vero-x@vero-plugins
claude plugin marketplace update vero-plugins
claude plugin update vero-x@vero-plugins
`claude plugin list` shows which version you have.
LINES
}

# The old marketplace a plugin repository keeps for a while after moving here (STANDARD.md,
# section 2): the engine loads one hooks module per plugin name, the earliest-enabled
# copy, so only a release through the old marketplace can show its installs the move.
# Temporary: the plugin leaves this list in the release that deletes its file.
legacy_marketplace() {
  case "$1" in
    vero-diff) echo "verodiff-marketplace" ;;
  esac
}

# The `## Working rules` section of a CLAUDE.md, up to the next `## ` heading.
working_rules() { awk '/^## Working rules/{p=1;next} /^## /{p=0} p' "$1"; }

# A PNG's width and height, from its header.
png_size() { python3 -c 'import struct,sys; d=open(sys.argv[1],"rb").read(24); print("%dx%d" % struct.unpack(">II", d[16:24]))' "$1" 2>/dev/null; }

check_repo() {
  local name="$1" clone="$2" path="$3" entry="$4"
  local plugin="$clone/$path" manifest="$clone/$path/.claude-plugin/plugin.json" readme_root="$clone/README.md"
  if [ ! -f "$manifest" ]; then
    problem "$path holds no .claude-plugin/plugin.json"
    return
  fi
  ok "$path holds a plugin manifest"

  local plugin_name display slogan
  plugin_name="$(jq -r '.name' "$manifest")"
  [ "$plugin_name" = "$name" ] && ok "plugin.json name matches the entry" \
    || problem "plugin.json names '$plugin_name', the entry '$name' - the install key would lie"

  display="$(jq -r '.displayName // ""' "$manifest")"
  case "$display" in
    Vero*) ok "display name $display" ;;
    *) problem "displayName '$display' does not start with Vero" ;;
  esac

  echo "  info  version $(jq -r '.version // "(none)"' "$manifest")"
  echo "  info  entry:       $(jq -r '.description' <<<"$entry")"
  echo "  info  plugin.json: $(jq -r '.description // ""' "$manifest")"

  # No plugin repository publishes a marketplace of its own - except, for a while, the old
  # one a plugin had before VeroPlugins, which must still deliver the move to its installs.
  local legacy legacy_file="$clone/.claude-plugin/marketplace.json"
  legacy="$(legacy_marketplace "$name")"
  if [ ! -e "$legacy_file" ]; then
    if [ -z "$legacy" ]; then
      ok "no marketplace.json in the plugin repository"
    else
      problem "the temporary exception for $legacy is stale: the file is gone, remove $name from legacy_marketplace()"
    fi
  elif [ -z "$legacy" ]; then
    problem "the plugin repository still has .claude-plugin/marketplace.json - VeroPlugins is the only marketplace"
  else
    local legacy_name legacy_entries legacy_source
    legacy_name="$(jq -r '.name // ""' "$legacy_file")"
    legacy_entries="$(jq -r '[.plugins[]?.name] | join(",")' "$legacy_file")"
    legacy_source="$(jq -r '.plugins[0].source // ""' "$legacy_file")"
    if [ "$legacy_name" != "$legacy" ]; then
      problem "the temporary marketplace.json is named '$legacy_name', not $legacy - old installs would not update from it"
    elif [ "$legacy_entries" != "$name" ] || [ "$legacy_source" != "./$path" ]; then
      problem "the temporary marketplace.json must list $name alone, with source ./$path (has: $legacy_entries, $legacy_source)"
    else
      note "temporary: the old marketplace $legacy still delivers the move to its installs; delete the file and the exception two releases after the move"
    fi
    if grep -rqF -- "$legacy" "$readme_root" "$plugin/README.md" "$plugin/hooks" 2>/dev/null; then
      problem "the old marketplace's name '$legacy' appears in a README or a module - nothing visible may say how to install from it"
    else
      ok "the old marketplace's name appears in no README and no module"
    fi
  fi

  # Every plugin carries the same source check and its table, byte for byte.
  local copy="$plugin/hooks/source-check.ts" table="$plugin/tests/source-check.test.ts"
  if [ ! -f "$copy" ]; then
    problem "no hooks/source-check.ts in the plugin"
  elif cmp -s "$SHARED_CHECK" "$copy"; then
    ok "hooks/source-check.ts is the canonical one"
  else
    problem "hooks/source-check.ts differs from shared/hooks/source-check.ts:"
    diff -u "$SHARED_CHECK" "$copy" | head -40 | sed 's/^/        /'
  fi
  if [ ! -f "$table" ]; then
    problem "no tests/source-check.test.ts in the plugin"
  elif cmp -s "$SHARED_TABLE" "$table"; then
    ok "tests/source-check.test.ts is the canonical table"
  else
    problem "tests/source-check.test.ts differs from shared/tests/source-check.test.ts"
  fi

  # The release workflow that tells this catalog about a release.
  local release="$clone/.github/workflows/release.yml"
  if [ ! -f "$release" ]; then
    problem "no .github/workflows/release.yml (the v* tag must send plugin-released here)"
  elif grep -q "client_payload\[plugin\]=$name" "$release" && grep -q "GomelHawk/VeroPlugins/dispatches" "$release"; then
    ok "release.yml sends plugin-released for $name"
  else
    problem "release.yml does not send plugin-released for $name to GomelHawk/VeroPlugins"
  fi

  # The scripts install from here.
  if [ -f "$clone/install.sh" ] && grep -q 'GomelHawk/VeroPlugins' "$clone/install.sh" && grep -q '"vero-plugins"' "$clone/install.sh" && grep -q "\"$name\"" "$clone/install.sh"; then
    ok "install.sh installs $name from GomelHawk/VeroPlugins (vero-plugins)"
  else
    problem "install.sh does not name GomelHawk/VeroPlugins, \"vero-plugins\" and \"$name\""
  fi
  [ -x "$clone/tests/smoke.sh" ] && ok "tests/smoke.sh is there and executable" || problem "tests/smoke.sh missing or not executable"

  # The README: two identical copies, the horizontal logo first, the slogan in its alt.
  local readme="$clone/README.md"
  if [ ! -f "$readme" ]; then
    problem "no README.md"
  else
    cmp -s "$readme" "$plugin/README.md" && ok "README.md is the same in the plugin" \
      || problem "README.md and $path/README.md differ"
    if head -n 5 "$readme" | grep -q "assets/horizontal-logo.png"; then
      ok "README opens with the horizontal logo"
    else
      problem "README does not open with assets/horizontal-logo.png"
    fi
    slogan="$(grep -o "alt=\"$display - [^\"]*\"" "$readme" | head -n 1 | sed "s/^alt=\"$display - //; s/\"$//")"
    if [ -z "$slogan" ]; then
      problem "the logo's alt is not 'alt=\"$display - <slogan>\"'"
    else
      echo "  info  slogan: $slogan"
      case "$(jq -r '.description // ""' "$manifest")" in
        "$slogan"*) ok "plugin.json description opens with the slogan" ;;
        *) problem "plugin.json description does not open with the slogan '$slogan'" ;;
      esac
      case "$(jq -r '.description' <<<"$entry")" in
        "$slogan"*) ok "catalog description opens with the slogan" ;;
        *) problem "catalog description does not open with the slogan '$slogan'" ;;
      esac
    fi
    local missing=0 line
    while IFS= read -r line; do
      if ! grep -qxF -- "$line" "$readme"; then
        [ "$missing" = 0 ] && problem "README is missing canonical Install/Updating lines:"
        printf '        %s\n' "$line"; missing=1
      fi
    done < <(required_lines "$name" "$display")
    [ "$missing" = 0 ] && ok "README carries the canonical Install and Updating text"
  fi

  # CLAUDE.md: the working rules, word for word.
  if [ ! -f "$TEMPLATE_NOTES" ]; then
    note "no template/CLAUDE.md here: Working rules not compared"
  elif [ ! -f "$clone/CLAUDE.md" ]; then
    problem "no CLAUDE.md"
  elif cmp -s <(working_rules "$TEMPLATE_NOTES") <(working_rules "$clone/CLAUDE.md"); then
    ok "CLAUDE.md Working rules are the standard ones"
  else
    problem "CLAUDE.md Working rules differ from template/CLAUDE.md's"
  fi

  # The logos at their standard sizes.
  local size
  size="$(png_size "$clone/assets/horizontal-logo.png")"
  [ "$size" = "1024x368" ] && ok "horizontal-logo.png is 1024x368" || problem "assets/horizontal-logo.png is ${size:-missing}, not 1024x368 (scripts/logos.py)"
  size="$(png_size "$clone/assets/logo.png")"
  [ "$size" = "1024x1024" ] && ok "logo.png is 1024x1024" || problem "assets/logo.png is ${size:-missing}, not 1024x1024 (scripts/logos.py)"

  # The plugin itself, as the engine will see it.
  if claude plugin validate "$plugin" >"$WORK/$name.validate" 2>&1; then
    ok "claude plugin validate"
  else
    problem "claude plugin validate failed:"
    sed 's/^/        /' "$WORK/$name.validate" | tail -20
  fi
  if claude plugin validate "$plugin" --strict >"$WORK/$name.strict" 2>&1; then
    ok "claude plugin validate --strict"
  else
    problem "claude plugin validate --strict failed:"
    sed 's/^/        /' "$WORK/$name.strict" | tail -20
  fi
  if claude plugin test "$plugin" >"$WORK/$name.test" 2>&1; then
    ok "claude plugin test ($(grep -E '^ *[0-9]+ pass' "$WORK/$name.test" | tr -d ' ' | head -1))"
  else
    problem "claude plugin test failed:"
    grep -E '\(fail\)|error|Error|fail$' "$WORK/$name.test" | head -20 | sed 's/^/        /'
  fi
}

catalog_name="$(jq -r '.name' "$CATALOG")"
[ "$catalog_name" = "vero-plugins" ] && ok "catalog is named vero-plugins (permanent: every plugin's source check compares against it)" \
  || problem "catalog name is '$catalog_name', not vero-plugins - the name is part of every install key and hard-coded in every plugin"

names="$(jq -r '.plugins[].name' "$CATALOG")"
[ -n "$names" ] || problem "the catalog lists no plugins"

for name in $names; do
  [ -z "$ONLY" ] || [ "$ONLY" = "$name" ] || continue
  echo
  echo "== $name =="
  entry="$(jq -c --arg n "$name" '.plugins[] | select(.name == $n)' "$CATALOG")"

  # The family rule: every plugin here is vero-<word>.
  case "$name" in
    vero-*) ok "name carries the Vero prefix" ;;
    *) problem "name '$name' is not vero-<word>; a plugin outside the family belongs in another catalog" ;;
  esac

  # Never a version in an entry: plugin.json's wins silently, and two values only mislead.
  if [ "$(jq -r 'has("version")' <<<"$entry")" = "true" ]; then
    problem "entry carries a version ($(jq -r '.version' <<<"$entry")); the plugin's plugin.json is the only place for one"
  else
    ok "no version in the entry"
  fi

  # The source shape this catalog uses: the plugin's own repository, a folder inside it.
  kind="$(jq -r '.source | if type == "object" then .source else "string" end' <<<"$entry")"
  if [ "$kind" != "git-subdir" ]; then
    problem "source is '$kind', not git-subdir (the plugin's repository + path)"
    continue
  fi
  url="$(jq -r '.source.url' <<<"$entry")"
  path="$(jq -r '.source.path' <<<"$entry")"
  ref="$(jq -r '.source.ref // .source.sha // empty' <<<"$entry")"
  [ -z "$ref" ] && ok "follows the plugin repository's default branch (no ref, no sha)" \
    || note "pinned to '$ref' - a release on the plugin's main does not reach users until the pin moves"

  if [ -n "$LOCAL" ]; then
    clone="$LOCAL"
    note "checking the local folder $LOCAL instead of cloning $url"
  else
    clone="$WORK/$name"
    if [ -n "$ref" ]; then
      git clone -q --depth 1 --branch "$ref" "$url" "$clone" 2>"$WORK/$name.clone" \
        || { git clone -q "$url" "$clone" 2>>"$WORK/$name.clone" && git -C "$clone" checkout -q "$ref" 2>>"$WORK/$name.clone"; }
    else
      git clone -q --depth 1 "$url" "$clone" 2>"$WORK/$name.clone"
    fi
    if [ ! -d "$clone/.git" ]; then
      problem "could not clone $url: $(tr '\n' ' ' < "$WORK/$name.clone")"
      continue
    fi
    ok "cloned $url"
  fi

  check_repo "$name" "$clone" "$path" "$entry"
done

echo
if [ "$fail" = 0 ]; then
  echo "Every entry checks out."
else
  echo "There were problems; see FAIL above."
fi
exit "$fail"
