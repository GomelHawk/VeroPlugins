<p align="center">
  <img src="https://raw.githubusercontent.com/GomelHawk/VeroX/main/assets/horizontal-logo.png"
       alt="VeroX - SLOGAN_X"
       width="600">
</p>

<p align="center">
  <a href="https://github.com/GomelHawk/VeroX/actions/workflows/ci.yml"><img src="https://github.com/GomelHawk/VeroX/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/GomelHawk/VeroX/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT licence"></a>
  <img src="https://img.shields.io/badge/Claude%20Code-plugin-8a63d2.svg" alt="Claude Code plugin">
</p>

ONE_LINE_X

<!-- TODO: two to four sentences in plain words. First the problem a person has, then
     what VeroX does about it. No jargon; say it the way you would to a colleague who
     does not program. -->

## What you get

<!-- TODO: three to five short bullets, or one small before/after example. -->

- ONE_LINE_X

## Install

Two commands, typed inside Claude Code. Type the first, press Enter and wait for
`✔ Successfully added marketplace: vero-plugins`, then type the second:

```
/plugin marketplace add GomelHawk/VeroPlugins
```

```
/plugin install vero-x@vero-plugins
```

Then restart Claude Code. If you already added VeroPlugins for another Vero plugin, only
the second command is needed. There is nothing to configure and no API key involved.

> Type each line on its own. If a panel appears asking for a `marketplace source`, it
> wants only `GomelHawk/VeroPlugins` and nothing else on the line.

Prefer a terminal? The same two commands work there, back to back:

```bash
claude plugin marketplace add GomelHawk/VeroPlugins
claude plugin install vero-x@vero-plugins
```

In the desktop app, where `/plugin` does not run: click **+** next to the prompt box, then
**Plugins**, **Add marketplace** with `GomelHawk/VeroPlugins`, then **Add plugin**.

To check it took, type `/vero-x`: it describes the plugin.

**Only from VeroPlugins.** VeroX works only when installed from VeroPlugins. A copy
installed from anywhere else pauses and shows, above the prompt, four buttons that move
it here: press them one after another, pressing Enter after each, then restart Claude
Code. KEEPS_X

<details>
<summary>Installing from a copy of this repository</summary>

```bash
git clone https://github.com/GomelHawk/VeroX
cd VeroX
./install.sh                                    # for you, in every project
./install.sh --scope project ~/work/our-app     # for everyone who works in our-app
```

`install.sh` checks the plugin and installs it from VeroPlugins. `--scope project DIR`
writes VeroX into `DIR/.claude/settings.json` - VeroPlugins and the plugin, never the
path of your copy - so once that file is committed, everyone who trusts the folder gets
VeroX without installing anything themselves. `--scope local DIR` does the same in
`DIR/.claude/settings.local.json`, for you alone. Without a copy of the repository, the
same team install is two commands run inside that project:

```bash
claude plugin marketplace add GomelHawk/VeroPlugins --scope project
claude plugin install vero-x@vero-plugins --scope project
```
</details>

## Using it

<!-- TODO: what the person sees and does, in the order they meet it, with short examples
     drawn the way Claude Code draws them. Tables for commands, buttons and keys. -->

## Options

<!-- TODO: the `userConfig` table: option, default, what it changes. Delete this section
     if the plugin has no options. -->

| Option | Default | What it does |
| :-- | :-- | :-- |

## Updating

Nothing updates by itself, and Claude Code will not tell you a new version exists. New
versions are announced at
[github.com/GomelHawk/VeroX/releases](https://github.com/GomelHawk/VeroX/releases);
watch the repository if you want an email.

Inside Claude Code, one command at a time, same as installing:

```
/plugin marketplace update vero-plugins
```

```
/plugin update vero-x@vero-plugins
```

Then restart Claude Code. From a terminal, where you can run them back to back:

```bash
claude plugin marketplace update vero-plugins
claude plugin update vero-x@vero-plugins
```

`claude plugin list` shows which version you have.

## Uninstalling

Inside Claude Code:

```
/plugin uninstall vero-x@vero-plugins
```

or, from a clone, `./uninstall.sh` (`./uninstall.sh --scope project ~/work/our-app` for a
project install). The VeroPlugins marketplace stays registered for your other Vero
plugins.

<!-- TODO: say what the plugin leaves behind (a cache, a folder) and how to remove it, or
     that nothing is left behind. -->

## Requirements

Claude Code with plugin support, in the terminal or the desktop app. REQUIRES_X

## Contributing

How to test changes, what CI checks and how releases reach users are in
[CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT
