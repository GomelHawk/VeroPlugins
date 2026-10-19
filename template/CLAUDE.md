# VeroX - working notes

Context for continuing work on this repository. The current version is whatever
`plugins/vero-x/.claude-plugin/plugin.json` says; no other file states one. The
plugin's name is always written **VeroX** (display) or `vero-x` (key); the slogan
is *SLOGAN_X*

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
- **Documentation describes the plugin as it is, not its history.** No "was decided",
  "replaced", "earlier design" or similar in any published file; a section that moves a
  user from an older release is the one exception.

## What this is

A Claude Code plugin - a **mod**: one TypeScript hooks module - that ONE_LINE_X

<!-- TODO: one paragraph on what it does and the main rule it keeps (what it never
     does), as the other Vero plugins' notes open. -->

Repository `GomelHawk/VeroX`, plugin `vero-x`, display name `VeroX`, command
`/vero-x`, MIT. English only, by the owner's decision. Installed only from
[VeroPlugins](https://github.com/GomelHawk/VeroPlugins) (marketplace `vero-plugins`), the
one catalog for every Vero plugin; that repository's CLAUDE.md has the catalog rules and
the canonical source check, and its STANDARD.md the rules every Vero plugin follows.

## Repository layout

```
VeroX/                                      the plugin's repository (the catalog is VeroPlugins)
├── .gitattributes                          * text=auto eol=lf
├── .github/workflows/ci.yml                manifests + plugin test, shell lint, smoke, endings
├── .github/workflows/release.yml           a v* tag tells VeroPlugins' CI to re-check the entry
├── .github/dependabot.yml                  watches the CI actions; there are no deps
├── assets/                                 logo.png (1024×1024), horizontal-logo.png (1024×368)
├── tests/smoke.sh                          repo invariants: bash + grep + python3
├── install.sh / uninstall.sh               (--scope project|local DIR for a project)
├── CLAUDE.md                               this file
├── CONTRIBUTING.md                         testing, CI, publishing: for maintainers
├── README.md                               user-facing docs; byte-identical copy in the plugin
└── plugins/vero-x/                         the plugin, name "vero-x"
    ├── .claude-plugin/plugin.json          manifest: version, userConfig, "types" contract
    ├── hooks/hooks.json                    { "modules": ["./register.tsx"] }, nothing else
    ├── hooks/register.tsx                  the mod: the source check, /vero-x, the band, your hooks
    ├── hooks/source-check.ts               the shared source check: a byte-identical copy of VeroPlugins/shared/hooks/
    ├── types/index.d.ts                    $.state contract: PluginState['vero-x']
    ├── tests/stopped.test.tsx              `claude plugin test`: stopped mode on both surfaces
    └── tests/source-check.test.ts          the source check's table: a copy of VeroPlugins/shared/tests/
```

## How it works

<!-- TODO: how the plugin does what it does: the hooks it takes, the state it keeps, the
     rules it follows, in the order a reader needs them. Bold lead-ins per topic. -->

**The command.** `/vero-x`, registered in `session.start`, answers `command.run` with
`{ text }`: the name, the slogan, what the plugin does, its state and its options' values.

**Source check.** VeroX works only when installed from VeroPlugins or loaded as a
development copy. `refreshSource()` runs first in `session.start` and again on
`turn.start` - every turn while stopped, at most every 10 s (`RECHECK_MS`,
`$.clock.now()`) while working: `sourceOf($.plugin.root)` reads the marketplace off the
root (`<config dir>/plugins/cache/<marketplace>/<plugin>/<version>`; no such segment means
`dev`), and a `home` copy then reads `$.settings.read({ source })` for `user`, `project`
and `local` and asks `legacyCopies()` whether an older copy of `vero-x` is still enabled
under another marketplace. `foreign`, or a legacy copy, means **stopped** (`view.source`,
`view.legacy`): every hook's first line is the engine's own behaviour; `session.start`
registers the command and shows one toast; `/vero-x` answers `stoppedMarkdown()` /
`legacyMarkdown()`; and the `AbovePrompt` hook, otherwise `next(e)`, draws the stopped
row - `stoppedBand()` with the three `MOVE_LABELS` buttons (`vero-x-move:1..3`), or
`legacyBand()` with `REMOVE_LABEL` (`vero-x-move:remove`), then `RESTART_NOTE`, then what
`next(e)` drew beneath - with no ×. A button puts its command (`moveSteps()` /
`removeStep()`) into the prompt box with `$.prompt.fill({ mode: 'replace' })` for the
person to press Enter on. A draft in the box (`$.prompt.read()`) is asked about first
(`view.confirmingFill`, `REPLACE_QUESTION`, `vero-x-move:replace` / `vero-x-move:cancel`);
a refused fill toasts `fillRefusedToast()`. All texts, keys and rules come from
`hooks/source-check.ts`, the byte-identical copy of VeroPlugins' canonical file; its table
is `tests/source-check.test.ts`. The test seam: a `dev` copy reads
`$.env.get('VERO_TEST_ROOT')` and, when set, takes its source from that path; only a dev
copy consults it, so no installed copy can opt out.

## Gotchas discovered the hard way

- **Never declare `hooks` in `plugin.json`.** `hooks/hooks.json` is auto-discovered;
  naming it in the manifest loads it twice and the plugin fails to load.
- **`hooks.json` names the module and nothing else.** `tests/smoke.sh` asserts the content.
- **Never add a top-level `bin/`.** claude.ai organization distribution rejects it.
- **`version` in `plugin.json` pins the plugin.** The catalog is VeroPlugins; never put
  `version` in its entry.
- **`name` is the user-visible key** in `enabledPlugins`. Renaming needs `renames` in
  VeroPlugins' catalog.
- **`$.plugin` has `name` and `root` only, no provenance.** `<name>@<marketplace>` exists
  on the `plugin.register` event, which a plugin cannot hook for itself; the path is the
  source check.
- **`$.settings.read({ source: 'user' | 'project' | 'local' })`** returns that one file's
  object, `enabledPlugins` included, with no permission prompt; a scope with no file is
  `{}`. In a test it is an op answered with `{ value }`.
- **`$.env.get` takes a string literal**; `claude plugin validate` lists the names read.
  `mock.env` answers it in a test from a fixed set; a test that changes the environment
  between turns answers `env.get` itself.
- **The command name must be a literal** in both `$.command.register` and the
  `command.run` matcher. Through a `const`, `claude plugin validate` lists the hook as a
  gate without `.catch` instead of "answers its own command".
- **Give a gating hook a `.catch`.** `claude plugin validate` flags `ui.close`, `tool.call`
  and a render that replaces the engine's drawing without one: a hook that throws there
  would keep a pane open, fail the model's call or leave a blank reply.
- **A test answers every event the plugin's hooks call `next` on** - `ui.render`,
  `turn.start`, `session.end` - or the kit fails with "no implementation".
- **`$.fs` has no delete.** Anything written to disk stays.
- **The mod API is early access.** Re-run `claude plugin validate` and `claude plugin test`
  against each new Claude Code release before cutting one of ours.

## Testing

```bash
tests/smoke.sh                                   # repo invariants
claude plugin test ./plugins/vero-x              # stopped mode, the source check's table, your tests

claude plugin validate ./plugins/vero-x          # manifest, hooks module, state contract
claude plugin validate ./plugins/vero-x --strict # for CI
```

Loading the plugin once with `--plugin-dir` makes the engine write its declarations into
`plugins/vero-x/.claude-plugin/types/` (self-ignored) and a `tsconfig.json` beside
`plugin.json` (in `.gitignore`); after that, `npx -p typescript tsc -p plugins/vero-x`
type-checks the module and the tests.

Live, in a scratch repository:

```bash
claude --plugin-dir /path/to/VeroX/plugins/vero-x
```

<!-- TODO: what to try by hand in that session. -->

Add a case to the tests for anything you fix in the module, and to `smoke.sh` for
anything in the scripts.

## Cutting a release

**Trigger.** The owner says "update version", "bump the version", "prepare a release" or
anything equivalent. Run the whole procedure; do not start it unprompted, and do not skip
steps because the change looks small.

### 1. Collect every change since the last release

```bash
# tags are plain `v<version>`, e.g. v1.0.0. A pattern that matches nothing fails silently
# and rebuilds a changelog for work already shipped, so keep these two in step.
LAST="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null)"
[ -n "$LAST" ] || LAST="$(git log -1 --format=%H \
    -S'"version"' -- plugins/vero-x/.claude-plugin/plugin.json)"

git log --no-merges --format='%h %s' "$LAST..HEAD"
git diff --stat "$LAST..HEAD"
git diff "$LAST..HEAD" -- plugins/vero-x
```

Read the diff, not only the subjects. Keep CI, tests and internal refactors out of the
user-facing notes.

### 2. Propose a number

| What changed | Bump |
| :-- | :-- |
| a command, option or key removed or renamed | major - `2.0.0` |
| a new option, button or capability | minor - `1.1.0` |
| fixes, wording, docs, CI, tests only | patch - `1.0.1` |

### 3. Ask before editing anything

Put it to the owner with `AskUserQuestion`: the computed number first, the neighbouring
ones as alternatives, each labelled with why it fits. Their answer wins. Never bump
without a reply.

### 4. Make the edits

- **`plugins/vero-x/.claude-plugin/plugin.json`** - `version`. The only place a
  version has any effect. Never also in the marketplace entry.
- **`plugins/vero-x/CHANGELOG.md`** - a new `## <version> - <YYYY-MM-DD>` at the top,
  user-facing, grouped, never raw commit subjects.
- Anything the release makes untrue in `README.md`, `plugins/vero-x/README.md` (keep
  them byte-identical) or this file.
- Run `tests/smoke.sh`, `claude plugin test ./plugins/vero-x` and both
  `claude plugin validate` commands, and report the result.

### 5. Hand back - never execute

No commit, no push, no tag. Stage the edits and hand the owner:

1. The one-line commit message.
2. **Release notes** for the GitHub Release body: the changelog entry as a standalone
   note, opening with one sentence on why anyone should care.
3. The commands:

```bash
git add -A && git commit -m "VeroX <version>" && git push
git tag v<version> && git push origin v<version>
gh release create v<version> --title "VeroX <version>" --notes-file notes.md
```

### What a release actually is

Users' marketplace is VeroPlugins, whose `vero-x` entry follows this repository's
**`main`** (a `git-subdir` source, no ref), so pushing a bumped `version` to `main` **is**
the release; the tag and the GitHub Release announce it. The `v<version>` tag also runs
`.github/workflows/release.yml`, which sends `plugin-released` to VeroPlugins (secret
`VEROPLUGINS_DISPATCH_TOKEN`), whose CI then re-checks the entry against this repository.
A fix pushed without a version bump reaches nobody (the cache is keyed by version, at
`~/.claude/plugins/cache/vero-plugins/vero-x/<version>/`), and unfinished work on
`main` ships the moment the version changes - keep it on a branch. Users update with
`/plugin marketplace update vero-plugins`, then `/plugin update vero-x@vero-plugins`,
and a restart.

## Open ideas, not implemented

None yet.
