---
name: new-vero-plugin
description: Create a new Vero plugin for Claude Code from VeroPlugins' template and standard; use when the owner asks for a new Vero plugin, "new plugin", "scaffold a plugin", "add a plugin to VeroPlugins".
---

# A new Vero plugin

Every Vero plugin is built the same way: one repository per plugin, laid out like the
others, installed only from VeroPlugins, with the shared source check, the same README
shape, the same CLAUDE.md skeleton, the same logos sizes. `STANDARD.md` in this
repository is the rule book; `template/` is its executable form; `scripts/new-plugin.sh`
stamps it. Follow the owner's working rules in CLAUDE.md throughout: never commit, never
push, ask before anything the owner did not ask for.

## 1. Ask for the five things the template cannot invent

Use `AskUserQuestion` for what is missing; do not guess:

- the key, `vero-<word>` (lowercase, one word): `vero-note`
- the display name, `Vero<Word>`: `VeroNote` (the same word, capitalised)
- the slogan: three or four words ending in a period, the second accent word is the one
  the logo colours: `Write it down.`
- one plain-language sentence: what it does for the person, no jargon
- what the plugin keeps on the person's machine, if anything (a cache, a history): the
  sentence for the README and the phrase for the stopped message

## 2. Stamp the repository

```bash
scripts/new-plugin.sh vero-note VeroNote "Write it down." "Keeps a note of what Claude did in each session." \
  --keeps "Your notes stay where they are." --dir ../VeroNote
```

It copies `template/`, substitutes the placeholders, re-copies the canonical
`shared/hooks/source-check.ts` and `shared/tests/source-check.test.ts`, initialises git on
`main` with the GitHub remote, stages everything, and runs `tests/smoke.sh`,
`claude plugin validate` (plain and `--strict`) and `claude plugin test`. All four must
pass before anything else is done.

## 3. Read STANDARD.md and work through its checklist

In the new repository, in this order:

1. `plugins/<key>/hooks/register.tsx`: the plugin's own hooks below the marked line, every
   one starting with `if (isStopped(v)) return next(e)`; `KEEPS` set when the plugin keeps
   data; `statusText()` extended with its state and options. Its tests beside
   `tests/stopped.test.tsx`, both surfaces. `types/index.d.ts` for the state.
2. `README.md`: fill every TODO comment in plain language, no history, no version
   numbers; then `cp README.md plugins/<key>/README.md`.
3. `CLAUDE.md`: the TODO comments (What this is, How it works, the live check); keep the
   Working rules byte for byte.
4. `tests/smoke.sh`: a footprint rule of the plugin's own, if it has a promise to keep.
5. Logos: the owner supplies two drafts (square icon over wordmark; horizontal icon,
   wordmark and slogan); `python3 scripts/logos.py <square> <horizontal> <repo>/assets`
   in VeroPlugins puts them on the standard canvas. Look at the results.
6. `CHANGELOG.md`: the first entry, user-facing.

Run the four checks again after each step that touches the module or the scripts.

## 4. List it in VeroPlugins

1. `.claude-plugin/marketplace.json`: the entry (`git-subdir`, the repository URL, the
   plugin path, a description opening with the slogan, tags; never a `version`).
2. `README.md`: the table row (name and slogan on two lines, the one-sentence summary,
   the install command) and a line under "Which one do I need?".
3. `python3 scripts/assets.py`: the table icon, the banner and the social preview from
   the new logos.
4. `claude plugin validate . --strict`, `scripts/check-entries.sh <key>` once the
   repository is on GitHub, and a scratch-`HOME` install.

## 5. Hand back

Stage both repositories. Report the four checks' results verbatim, what is left for the
owner (the GitHub repository, the `VEROPLUGINS_DISPATCH_TOKEN` secret, About and topics,
the social preview, the first release), and a one-line commit message for each
repository. Never commit.
