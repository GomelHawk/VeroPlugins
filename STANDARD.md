# The Vero plugin standard

Every Vero plugin for Claude Code is built the same way, so a person who learned one can
use the next, and so one catalog, one CI and one set of scripts serve them all. This file
is the standard; `template/` is the same standard as files, `scripts/new-plugin.sh` stamps
it into a new repository, and `scripts/check-entries.sh` checks the parts a machine can
check on every CI run. When this file and a plugin disagree, this file wins; when this
file and `template/` disagree, fix both in the same change.

## 1. Names and words

- **Key**: `vero-<word>`, lowercase, one word (`vero-diff`). It is the folder
  `plugins/vero-<word>`, the `name` in `plugin.json`, half of the install key
  (`vero-diff@vero-plugins`), the command `/vero-<word>`, and the prefix of every UI key
  the module draws (`vero-diff-move:1`).
- **Display name**: `Vero<Word>` (`VeroDiff`): GitHub repository `GomelHawk/Vero<Word>`,
  `displayName` in `plugin.json`, every toast and band row, every README sentence.
- **Slogan**: three or four words, each sentence ending with a period, the second word
  coloured in the logo (`One turn, one diff.`, `Read true. Spend less.`,
  `Click. Run. Done.`). It appears in exactly these places: the horizontal logo; the
  README's logo `alt` as `Vero<Word> - <slogan>`; the first sentence of `description` in
  `plugin.json`; the first sentence of the catalog entry's `description`; the catalog
  README's table, through the horizontal logo and its `alt`; the first line
  of the plugin's `/vero-<word>` answer (`**Vero<Word>** - *<slogan>*`); the intro of
  CLAUDE.md; the GitHub About text.
- **One line**: one plain sentence that says what the plugin does for the person, no
  jargon. It follows the slogan in `plugin.json` and in the GitHub About text.
- Everything the person reads is English, by the owner's decision.

## 2. Repository

```
Vero<Word>/
├── .gitattributes                 * text=auto eol=lf; *.png binary
├── .github/dependabot.yml         github-actions only, weekly, prefix ci
├── .github/workflows/ci.yml       validate (+ --strict) the plugin folder, test, shell, smoke, endings
├── .github/workflows/release.yml  on a v* tag: repository_dispatch plugin-released to VeroPlugins
├── .gitignore                     .DS_Store, *.swp, .idea, the engine's tsconfig beside the plugin
├── assets/logo.png                1024×1024 (section 5)
├── assets/horizontal-logo.png     1024×368 (section 5)
├── tests/smoke.sh                 repository invariants, bash only, no account, no network
├── install.sh / uninstall.sh      VeroPlugins commands (+ --scope project|local DIR)
├── CLAUDE.md                      working notes, the skeleton of section 4
├── CONTRIBUTING.md                how to test, what CI checks, how a release reaches users
├── LICENSE                        MIT, Dmitry Koshelenko
├── README.md                      the person's page, section 3
└── plugins/vero-<word>/
    ├── .claude-plugin/plugin.json name, displayName, description, version, author, homepage,
    │                              repository, license, keywords, types, userConfig
    ├── CHANGELOG.md               ## <version> - <date>, user-facing, newest first
    ├── LICENSE, README.md         byte-identical copies of the root ones (a marketplace install sees only this folder)
    ├── hooks/hooks.json           { "modules": ["./register.tsx"] } and nothing else
    ├── hooks/register.tsx         the module
    ├── hooks/source-check.ts      byte-identical copy of VeroPlugins/shared/hooks/source-check.ts
    ├── hooks/<pure>.ts            pure rules and parsing, no `$`, table-tested
    ├── types/index.d.ts           the $.state contract: PluginState['vero-<word>']
    ├── tests/source-check.test.ts byte-identical copy of VeroPlugins/shared/tests/source-check.test.ts
    └── tests/*.test.ts(x)         the pure tables and the engine tests, both surfaces
```

Never: a `.claude-plugin/marketplace.json` anywhere (VeroPlugins is the only
marketplace), a top-level `bin/` in the plugin (organization distribution rejects it), a
`version` anywhere but `plugin.json`, the name of any other marketplace in any file.

One temporary exception, for a plugin that had a marketplace of its own before
VeroPlugins: Claude Code loads one hooks module per plugin name, the copy whose
`enabledPlugins` key comes first, so while the old copy is enabled the copy from
VeroPlugins never runs and only the old copy can show the move. The old marketplace file
therefore stays in that repository for two releases after the move, so the old copy
updates to a version that stops and shows the move row; its description points at
VeroPlugins, no README or message names it, and the release after those two deletes it.
`scripts/check-entries.sh` lists the exception (`legacy_marketplace()`) and fails once
the file is gone but the exception is not. Today: VeroDiff, `verodiff-marketplace`,
kept through the two releases after 1.3.0.

## 3. README

Both copies identical. Written for a person who is not a programmer: short sentences,
no jargon without a plain explanation, the facts a person needs (commands, paths, what is
stored where) said simply. It describes the current version only: no "since 1.x", no
"replaced", no upgrade sections, no Claude Code version numbers. Structure, in this order:

1. The horizontal logo, centred, `width="600"`, `alt="Vero<Word> - <slogan>"`, from
   `https://raw.githubusercontent.com/GomelHawk/Vero<Word>/main/assets/horizontal-logo.png`.
2. The badges: CI, MIT, `Claude Code plugin`, and a `requires` badge when something must
   be installed.
3. Two to four sentences: the problem the person has, and what the plugin does about it.
4. `## What you get`: three to five bullets, or one tiny before/after example.
5. `## Install`: the canonical text (`template/README.md`), word for word, with the
   plugin's own three slots: the line after "only the second command is needed", the
   "To check it took" line, and the data sentence in the "Only from VeroPlugins" paragraph.
6. The plugin's own sections: `## Using it`, `## Options` (a table, when `userConfig`
   exists), `## Commands` (a table, when there are subcommands), and what else it needs.
7. `## Updating`: the canonical text, word for word.
8. `## Turning it off and uninstalling` (or `## Uninstalling` when there is nothing to turn
   off): `/plugin uninstall vero-<word>@vero-plugins`, `./uninstall.sh`, what data stays
   and how to remove it. The VeroPlugins marketplace is never removed: other Vero
   plugins use it.
9. `## Good to know` / `## Troubleshooting` when the plugin has limits worth a table.
10. `## Requirements`: "Claude Code with plugin support" plus the plugin's own, no
    version numbers. `## Contributing`. `## License`.

## 4. CLAUDE.md

The skeleton, in this order, with `## ` headings exactly so: intro paragraph (where the
version is, how the name is written, the slogan); `## Working rules` (byte-identical to
`template/CLAUDE.md`, CI compares); `## What this is` (ending with the distribution
paragraph: repository, plugin, display name, command, MIT, English, installed only from
VeroPlugins, pointer to the catalog's CLAUDE.md and this file); `## Repository layout`;
`## How it works` (one bold-led paragraph per mechanism; the **Source check** paragraph
is the same in every plugin); `## Gotchas discovered the hard way`; `## Testing` (the
commands block: smoke, `claude plugin test`, `claude plugin validate` and `--strict` on
the plugin folder; type-check; live with `--plugin-dir`); `## Cutting a release` (the
numbered `###` steps and the semver table, then `### What a release actually is`);
`## Open ideas, not implemented`.

## 5. Logos and pictures

Two files per plugin, made from the author's drafts with `scripts/logos.py <assets dir>`,
which recomposes them without redrawing:

| File | Canvas | Icon height | Wordmark cap height | Gap | Background |
| :-- | :-- | :-- | :-- | :-- | :-- |
| `assets/horizontal-logo.png` | 1024×368 | 232 | 88 (slogan below it, in the draft's proportion) | 52 between icon and text | `#030409` |
| `assets/logo.png` | 1024×1024 | 352 | 84 | 40 between icon and wordmark | `#030409` |

The content is centred. The icon is a flat, rounded line drawing on the dark background
with one accent colour; the wordmark is `Vero` in white and `<Word>` in the accent
colour; the slogan under the wordmark, grey with the key words in the accent colour. A
draft can be any size: the script measures the icon and the text and scales each to the
table.

The catalog then needs, from `scripts/assets.py` run in VeroPlugins: `assets/vero-<word>.png`,
a 520 px wide copy of the horizontal logo that the README's table shows (so the table
never depends on the plugin repository), and a rebuilt `banner.png` and
`social-preview.png` (1280×640) that show every plugin's horizontal logo. A plugin
repository's own social preview is its `horizontal-logo.png`.

## 6. Descriptions

- `plugin.json` `description`: `<slogan> <one line>`, then at most one more sentence.
- Catalog entry `description` (VeroPlugins): `<slogan> <short form of the one line>`.
  `category` `productivity`; `tags` three to six lowercase words.
- GitHub About, all four repositories alike, under 350 characters:
  `Vero<Word> - <slogan> <one line, one or two sentences> Claude Code plugin · installed from VeroPlugins.`
  For VeroPlugins: `VeroPlugins: one marketplace for every Vero plugin for Claude Code. <one clause per plugin>. Add it once, install what you need.`
- GitHub Website: `https://github.com/GomelHawk/VeroPlugins` on every plugin.
- GitHub Topics: `claude-code`, `claude-code-plugin`, `vero-plugins`, plus three to five of
  the plugin's own.

## 7. The module

- One hooks module, `hooks/register.tsx`, function hooks; pure rules and parsing in a
  separate `hooks/<pure>.ts` with no `$`, table-tested.
- `hooks/source-check.ts` is never edited in a plugin. The module carries the stopped
  mode exactly as `template/plugins/vero-x/hooks/register.tsx` has it: `PLUGIN`,
  `DISPLAY`, `KEEPS`; `checkSource()` (path, `VERO_TEST_ROOT` for a dev copy,
  `$.settings.read` per scope, `legacyCopies`); `refreshSource()` at `session.start`
  and on `turn.start` (every turn while stopped, at most every 10 s while working);
  `view.source`, `view.legacy`, `view.confirmingFill` in `types/index.d.ts`; every hook's
  first line returns the engine's behaviour while stopped; the command answers the
  message; the band row with the `vero-<word>-move:*` buttons that fill and never run.
- Every gating hook has a `.catch` that falls back to `next(e)`; the command name and
  every `tool.call` matcher are literals; `$.env.get` takes a literal name.
- Keys the module draws start with the plugin's key, so two plugins never clash in the
  shared band.
- Nothing is written into the person's project unless they press a button that says so.
  Data lives under `~/.cache/vero<word>` (or `$XDG_CACHE_HOME`, or `VERO<WORD>_DIR`),
  never under the plugin's own folder, so it survives a move between marketplaces.

## 8. Tests

- `tests/source-check.test.ts`: the canonical table, byte-identical, never edited.
- Pure tables for every rule in `hooks/<pure>.ts`; add a case for anything you fix.
- Engine tests on `terminal` and `desktop`, with `fakeWorld()` answering everything
  beneath the plugin, including `env.get`, `settings.read`, `prompt.read`,
  `prompt.fill` and the engine's own `AbovePrompt`; the stopped-mode cases of
  `template/plugins/vero-x/tests/stopped.test.tsx` adapted to the plugin.
- `tests/smoke.sh`: the repository invariants of `template/tests/smoke.sh` plus the
  plugin's own shell promises; bash 3.2 and coreutils only.

## 9. Scripts, CI, release

- `install.sh`: validate the plugin folder → `claude plugin marketplace add GomelHawk/VeroPlugins`
  → `claude plugin install vero-<word>@vero-plugins`; `--scope project|local DIR` runs in
  DIR. `uninstall.sh`: `claude plugin uninstall vero-<word>@vero-plugins`, never removes
  the marketplace, `--purge` for the plugin's data when it has any.
- `ci.yml`: `claude plugin validate ./plugins/vero-<word>`, the same with `--strict`,
  `claude plugin test`, `bash -n` + bash 3.2 parse + ShellCheck over every script, the
  smoke test on Linux and macOS, the Windows-style checkout for line endings. The newest
  Claude Code, on purpose.
- `release.yml`: on a `v*` tag, `repository_dispatch` `plugin-released` to
  `GomelHawk/VeroPlugins` with `VEROPLUGINS_DISPATCH_TOKEN` (fine-grained PAT, Contents
  read/write on VeroPlugins, stored as a secret in the plugin repository).
- A release: bump `version` in `plugin.json`, a `CHANGELOG.md` entry in user-facing
  words, push `main` (VeroPlugins follows `main`, so this is the release), tag
  `v<version>`, GitHub Release with the entry as notes. The procedure is in each
  CLAUDE.md under "Cutting a release".

## 10. Adding the plugin to VeroPlugins

1. The repository is public on `main` with everything above.
2. The catalog entry in `.claude-plugin/marketplace.json` (`git-subdir`, no `version`).
3. The README table row (the horizontal logo linked to the repository), then
   `scripts/assets.py` for `assets/vero-<word>.png`, the banner and the preview.
4. `claude plugin validate . --strict`, `scripts/check-entries.sh vero-<word>`, a scratch
   `HOME` install (`CLAUDE.md`, "Testing").
5. CI green here, then the GitHub About, Website, Topics and social preview on the new
   repository.

## 11. What CI checks, and what you check

`scripts/check-entries.sh` checks, for every entry: the name and prefix, no `version`,
`git-subdir`, no `marketplace.json` (or the temporary one of section 2, listing only
this plugin, and its name in no README or module), both shared files byte-identical,
`release.yml` present and naming the plugin, `install.sh` naming VeroPlugins, both README copies
identical, the README opening with the horizontal logo and its `alt` carrying the slogan,
the slogan opening both descriptions, the canonical Install and Updating lines present,
the Working rules identical to the template's, both logos at their sizes, `validate` and
`test` passing. By hand: the tone of the README, the slogan's wording, the logo's look,
the GitHub About/Topics/preview, and a live run in a scratch `HOME`.
