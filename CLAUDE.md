# VeroPlugins - working notes

Context for continuing work on this repository. It is a catalog, not a plugin: the one
Claude Code marketplace every Vero plugin is installed from. The plugins' code lives in
their own repositories; the only code here is the canonical source check they all carry.

## Working rules

- **A question gets an answer, nothing else.** When the owner asks for information -
  "how does X work", "what about Y", "why is Z" - reply with the information and change
  no files. Do not edit, stage, create or delete anything as a side effect of answering.
- **Ask before changing anything that was not asked for.** If you spot something worth
  changing - wrong documentation, a bug, a stale reference, an obvious improvement - say
  what it is and why it should change, then wait for a yes. Noticing a problem while
  doing something else is a reason to report it, not a licence to fix it. Approval for
  one change never extends to the next thing you notice.
- **Never commit.** Do not run `git commit`, `git push`, `git tag`, `git rebase` or
  anything else that writes history - not even when the work is finished, the tree is
  clean and the change is obviously correct. Editing files and staging them is fine;
  creating a commit is the repo owner's call, always.
- **Finish with a really short commit description.** When an implementation is done, hand
  back a one-line commit message for the owner to use. One line, no body, no explanation
  wrapped around it.
- **Documentation describes things as they are, not their history.** No "was decided",
  "replaced", "earlier design" or similar in any published file; a section that moves a
  user from an older release is the one exception.

## What this is

**VeroPlugins is the only supported way to install a Vero plugin.** The catalog
(`.claude-plugin/marketplace.json`, marketplace name `vero-plugins`, repository
`GomelHawk/VeroPlugins`) lists every plugin; each entry points at the plugin's own
repository and the folder inside it that holds the plugin (`git-subdir`). No plugin
repository publishes a marketplace of its own. A plugin installed from anywhere else
stops working and shows the person the commands to move - how, is `shared/`'s job and
`PLAN-unify-sources.md` (the owner's working file, untracked).

Plugins listed: VeroDiff (`vero-diff`), VeroDotto (`vero-dotto`), VeroRunto
(`vero-runto`), VeroInserto (`vero-inserto`). Every plugin here carries the Vero name:
`vero-<name>`, display `Vero<Name>`. English only, MIT.

## Repository layout

```
VeroPlugins/
├── .claude-plugin/marketplace.json     the catalog - the only file Claude Code reads
├── .github/workflows/ci.yml            catalog, entries, install for real, shell, endings;
│                                       runs on push, PR, by hand, and when a plugin releases
├── .github/dependabot.yml              watches the CI actions; there are no deps
├── .gitattributes                      * text=auto eol=lf; png binary
├── .gitignore                          .idea, PLAN-*.md, the engine's files under shared/
├── assets/                             banner.png, social-preview.png, vero-<name>.png (the horizontal logo, 520 px)
├── shared/hooks/source-check.ts        the canonical source check every plugin carries
├── shared/hooks/hooks.json             test harness only: names harness.ts for `claude plugin test`
├── shared/hooks/harness.ts             an empty module; shared/ is never an installable plugin
├── shared/tests/source-check.test.ts   the canonical test table (copied into each plugin)
├── scripts/check-entries.sh            the per-entry checks CI runs (+ --local DIR NAME for a clone)
├── scripts/new-plugin.sh               stamps template/ into a new plugin repository
├── scripts/logos.py                    normalises a plugin's two logos to the standard sizes
├── scripts/assets.py                   rebuilds banner, social preview and table icons from the logos
├── template/                           a complete plugin repository with placeholders (the standard as files)
├── .claude/skills/new-vero-plugin/     the skill that walks through making a new plugin
├── STANDARD.md                         the rules every Vero plugin follows
├── CLAUDE.md                           this file
├── LICENSE                             MIT
└── README.md                           the catalog for people
```

`shared/` mirrors a plugin's `hooks/` + `tests/` layout on purpose: a plugin's copies are
then byte-identical to the canonical files, import paths included.

## How it works

**The catalog.** One entry per plugin:

```json
{
  "name": "vero-diff",
  "source": { "source": "git-subdir", "url": "https://github.com/GomelHawk/VeroDiff.git", "path": "plugins/vero-diff" },
  "description": "...", "category": "productivity", "tags": ["..."]
}
```

Rules for every entry, each checked by `scripts/check-entries.sh`:

- `name` equals the plugin's own `plugin.json` `name`: it is half of the person's install
  key (`vero-diff@vero-plugins`).
- Never a `version`. The plugin's `plugin.json` wins silently; two values only mislead.
- No `ref` / `sha` by default: the entry follows the plugin repository's `main`, so a
  release there (a `version` bump) reaches users at once. Pin only to hold a plugin back
  deliberately, and then remember the pin exists (the script prints a note).
- This catalog is the only place `description`, `category` and `tags` live. Keep
  `description` in step with the plugin's `plugin.json` one in meaning; the script prints
  both side by side.
- The plugin repository has no `.claude-plugin/marketplace.json` and carries
  `hooks/source-check.ts` identical to `shared/hooks/source-check.ts`. One temporary
  exception, listed in the script's `legacy_marketplace()`: VeroDiff keeps its old
  `verodiff-marketplace` file for the two releases after 1.3.0, so copies installed from
  it still update to a version that shows the move (see "Gotchas": one module per name).
  The file lists only `vero-diff`, its description points at VeroPlugins, and the name
  appears in no README or module. The release after those two deletes the file and the
  exception together, or the script fails.

**What an install does.** `claude plugin marketplace add GomelHawk/VeroPlugins` clones
this repository into `~/.claude/plugins/marketplaces/vero-plugins/`. `claude plugin
install vero-diff@vero-plugins` then clones the plugin repository, copies the `path`
folder to `~/.claude/plugins/cache/vero-plugins/vero-diff/<version>/`, and enables
`vero-diff@vero-plugins` in `~/.claude/settings.json`'s `enabledPlugins`. Checked
locally (Claude Code 2.1.303, 2026-10-19) with the catalog added as a directory: no
account needed, the cache holds `plugin.json`, `claude plugin list` shows the version.

**The source check** (`shared/hooks/source-check.ts`, pure TypeScript, no `$`): a plugin
calls `sourceOf($.plugin.root)` and gets `home` (installed from `vero-plugins`), `dev`
(`--plugin-dir`, `CLAUDE_CODE_PLUGIN_DIRS`, `claude plugin test`) or `foreign` with the
marketplace's name. The root of an installed copy is
`<config dir>/plugins/cache/<marketplace>/<plugin>/<version>`; only the `plugins/cache`
segment pair is matched, with either separator, so Windows and `CLAUDE_CONFIG_DIR` work.
The engine gives a plugin no provenance of its own (`<name>@<marketplace>` exists only as
the `plugin.register` event's input, which a plugin cannot hook for itself), so the path
is the source of truth; `sourceOf(root, provenance?)` still takes one, should the API grow
it. A home copy then reads `$.settings.read({ source })` for `user`, `project` and
`local` and passes the objects to `legacyCopies(plugin, sources)`, which finds an older
copy of the same plugin still enabled under another marketplace, with its scope. The
texts - `stoppedBand`, `stoppedToast`, `stoppedMarkdown`, `moveSteps` (four commands:
add VeroPlugins, install from it, remove this copy, remove its marketplace),
`MOVE_LABELS`, `legacyBand`, `legacyToast`, `legacyMarkdown`, `removeSteps` (remove the
old copy, then its marketplace), `REMOVE_LABELS`, `RESTART_NOTE`, `REPLACE_QUESTION`,
`fillRefusedToast` - are the one wording every plugin shows. The check runs at `session.start` and on `turn.start`: every turn while stopped, so the
old copy's removal is seen at the next Enter, and at most every 10 seconds while working.
What a plugin does while stopped is each plugin's own `register.tsx` and its
CLAUDE.md: every hook's first line is the engine's own behaviour, the command and the
tool answer the message, the band above the prompt holds the buttons that fill the move
commands into the prompt box (one Enter each), and nothing of the person's data is
touched.

**The test seam.** Under `claude plugin test` a plugin's root is its folder on disk, never
under `plugins/cache/`. So a module that finds itself `dev` reads `$.env.get('VERO_TEST_ROOT')`
and, when set, takes the source from that path instead; a test sets it with `mock.env`.
Only a `dev` copy consults it, so no installed copy can opt out through it.

## Adding a plugin

`STANDARD.md` is the rule book and `template/` the same rules as files; the skill
`new-vero-plugin` walks through it. In short:

0. `scripts/new-plugin.sh vero-<word> Vero<Word> "<Slogan.>" "<one line>"` makes the
   repository; logos through `scripts/logos.py`; the README's TODOs; the hooks.
1. Its repository is public, has no `.claude-plugin/marketplace.json`, carries
   `hooks/source-check.ts` identical to `shared/hooks/source-check.ts` and
   `tests/source-check.test.ts` identical to `shared/tests/source-check.test.ts`, has a
   `.github/workflows/release.yml` that sends `plugin-released` here on a `v*` tag (see
   "How a release reaches this repo"), and its `plugin.json` has a released `version` on
   `main`.
2. Add the entry to `marketplace.json` (the shape above; no `version`, no `ref`).
3. `claude plugin validate .` and `claude plugin validate . --strict`.
4. `scripts/check-entries.sh <name>` (before the push: `--local <clone> <name>`); it also
   checks the standard's machine-checkable rules (STANDARD.md, section 11).
5. In a scratch `HOME`: `claude plugin marketplace add "$PWD"`, then
   `claude plugin install <name>@vero-plugins`; check the cache folder.
6. README table row (the horizontal logo linked to the repository) + `scripts/assets.py`
   for the table logo, the banner and the social preview.
7. CI green, including the install job. Hand back the commit message.

## How a release reaches this repo

A plugin release is a `version` bump pushed to the plugin repository's `main` plus a
`v<version>` tag. The tag push runs that repository's `release.yml`, which sends
`repository_dispatch` (`event_type: plugin-released`, payload `plugin` and `version`) to
`GomelHawk/VeroPlugins` through `gh api repos/GomelHawk/VeroPlugins/dispatches`; CI here
then runs every job, so a release that breaks an entry is seen the same day. The call
needs a token: one fine-grained personal access token for the GomelHawk account with
**Contents: read and write** on the VeroPlugins repository only, stored as the secret
`VEROPLUGINS_DISPATCH_TOKEN` in each plugin repository (Settings → Secrets and variables
→ Actions). GitHub's own `GITHUB_TOKEN` cannot reach another repository, which is why.
A missing secret fails that one job in the plugin repository and nothing else; CI here
can always be run by hand (Actions → CI → Run workflow).

## Changing the standard

Edit `STANDARD.md` and `template/` in the same change, then `scripts/check-entries.sh`
against every plugin: a rule the script checks must hold in all of them before it is
merged, or the next CI run is red for every entry. Wording that reaches a person (the
README's Install and Updating text, the band's texts) is changed in the template, in
`required_lines()` of the check script, and in every plugin, in that order.

## Changing the source check

Edit `shared/hooks/source-check.ts` and its table first, run `claude plugin test shared`,
then copy both files to every plugin and release each. CI's entries job fails until every
copy matches. Never change `HOME_MARKETPLACE`: the catalog's name is permanent.

## Testing

```bash
claude plugin validate .            # the catalog
claude plugin validate . --strict   # for CI
claude plugin test shared           # the source check's table
scripts/check-entries.sh            # every entry against its repository (clones, needs network)
```

The real install, in a scratch `HOME`:

```bash
H="$(mktemp -d)"
HOME="$H" claude plugin marketplace add "$PWD"
HOME="$H" claude plugin install vero-diff@vero-plugins
ls "$H"/.claude/plugins/cache/vero-plugins/vero-diff/*/.claude-plugin/plugin.json
```

Then start `claude` with `HOME="$H"` in a scratch git repository, run `/vero-diff`, make
one edit, see a step.

## Gotchas

- **The catalog name `vero-plugins` is permanent.** It is part of every install key and
  hard-coded in every plugin's source check (`HOME_MARKETPLACE`). Reserved names
  (`claude-plugins-official`, `anthropic-plugins`, and similar) are refused by Claude
  Code anyway.
- **Never `version` in an entry.** `plugin.json` silently wins, and the entry would lie.
- **`name` is the user-visible key** in `enabledPlugins`. Renaming a plugin without a
  `renames` entry here breaks every existing install.
- **`claude plugin marketplace add` has no ref option**: a person's marketplace tracks
  `main`, so `main` must always be releasable.
- **`claude plugin install` of a `git-subdir` entry clones the plugin repository fresh**
  and fails with `Subdirectory '<path>' not found` when the repository is empty or the
  path is wrong - which is what an entry for an unpushed plugin looks like.
- **`--scope project|local` writes to the current directory's `.claude/`**, for both
  `marketplace add` and `plugin install`.
- **One hooks module per plugin name.** Two enabled copies of `vero-diff` do not both
  run: the engine loads the one whose `enabledPlugins` key comes first in the settings (a
  managed scope before all) and logs `hooks module vero-diff@vero-plugins not loaded:
  another plugin of that name loads first`. A person who installed from an old
  marketplace has the old key first, so the VeroPlugins copy never runs while the old
  one is enabled, and only the old copy can show the move. That is why an old
  marketplace must keep delivering releases until its installs have moved (the temporary
  exception in "How it works"), and why `legacyCopies` covers only the other order.
  Verified with Claude Code 2.1.303 (2026-10-20): reversing the two keys in settings.json
  reversed which copy loaded.
- **A plugin cannot read its own provenance.** `$.plugin` has `name` and `root` only;
  `provenance` is on the `plugin.register` event, raised for the modules loading after
  the hooking one. The path is the check.
- **`$.settings.read({ source: 'user' | 'project' | 'local' })`** returns that one file's
  object, `enabledPlugins` included, with no permission prompt; a source with no file
  answers `{}`. The key shape is `<plugin>@<marketplace>: true`.
- **`claude plugin test` needs a hooks module to load**, even for a table of pure
  functions; hence `shared/hooks/hooks.json` + `harness.ts`. Loading `shared/` once with
  `--plugin-dir` would make the engine write `shared/.claude-plugin/types/` and
  `shared/tsconfig.json`; both are in `.gitignore`.
- **The plugin API is early access.** CI installs the newest Claude Code on purpose, so a
  change in it fails here before it reaches a user.
