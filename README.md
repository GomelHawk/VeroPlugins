<p align="center">
  <img src="https://raw.githubusercontent.com/GomelHawk/VeroPlugins/main/assets/banner.png"
       alt="VeroPlugins: VeroDiff, VeroDotto and VeroRunto - one marketplace for every Vero plugin for Claude Code"
       width="900">
</p>

<p align="center">
  <a href="https://github.com/GomelHawk/VeroPlugins/actions/workflows/ci.yml"><img src="https://github.com/GomelHawk/VeroPlugins/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="https://github.com/GomelHawk/VeroPlugins/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT licence"></a>
  <img src="https://img.shields.io/badge/Claude%20Code-marketplace-8a63d2.svg" alt="Claude Code marketplace">
</p>

Three small add-ons for Claude Code, made by one author. Each does one thing well: one
shows you what Claude changed, one lets Claude read your office documents, one turns the
commands Claude asks you to run into buttons. Add VeroPlugins once, then install whichever
you need.

## Add VeroPlugins

Inside Claude Code, type this on its own line and press Enter:

```
/plugin marketplace add GomelHawk/VeroPlugins
```

Wait for `✔ Successfully added marketplace: vero-plugins`. This is done once; every
plugin below installs from it. In the desktop app, where `/plugin` does not run: click
**+** next to the prompt box, then **Plugins**, **Add marketplace**, and enter
`GomelHawk/VeroPlugins`. From a terminal, `claude plugin marketplace add GomelHawk/VeroPlugins`
does the same.

## The plugins

| | Plugin | What it does | Install |
| :-- | :-- | :-- | :-- |
| <img src="https://raw.githubusercontent.com/GomelHawk/VeroPlugins/main/assets/vero-diff.png" width="48" alt=""> | **[VeroDiff](https://github.com/GomelHawk/VeroDiff)**<br>*One turn, one diff.* | See exactly what Claude changed on each turn, as a real diff in a side pane, and undo it. | `/plugin install vero-diff@vero-plugins` |
| <img src="https://raw.githubusercontent.com/GomelHawk/VeroPlugins/main/assets/vero-dotto.png" width="48" alt=""> | **[VeroDotto](https://github.com/GomelHawk/VeroDotto)**<br>*Read true. Spend less.* | Claude reads docx, pdf, spreadsheets and OpenDocument files as clean markdown, with fewer tokens. | `/plugin install vero-dotto@vero-plugins` |
| <img src="https://raw.githubusercontent.com/GomelHawk/VeroPlugins/main/assets/vero-runto.png" width="48" alt=""> | **[VeroRunto](https://github.com/GomelHawk/VeroRunto)**<br>*Click. Run. Done.* | **Copy** and **Run** buttons after every `!` command Claude suggests; Run goes through Claude Code's own Bash tool, under your permission rules. | `/plugin install vero-runto@vero-plugins` |

Type the install command on its own line, press Enter, then restart Claude Code. In the
desktop app, pick the plugin under **Plugins** → **Add plugin** instead. Each plugin's own
page explains what it does in detail, with its options and answers to common questions.

## Which one do I need?

- Claude edited files and you want to review or undo a turn → **VeroDiff**
- You give Claude Word, Excel, PowerPoint or PDF files → **VeroDotto**
- Claude keeps asking you to run commands like `! gh auth login` → **VeroRunto**

They are independent: install one, two or all three.

## Installed one of these some other way?

Every Vero plugin installs from VeroPlugins only. A copy that came from anywhere else
pauses and shows, above the prompt, three buttons with the exact commands that move it
here. Press them one after another, pressing Enter after each, then restart Claude Code.
Nothing you made is lost: VeroDiff keeps its history of changes, VeroDotto keeps its
converted documents.

## Updating

```
/plugin marketplace update vero-plugins
/plugin update <plugin>@vero-plugins
```

Then restart Claude Code. Updates do not happen by themselves, and Claude Code does not
tell you a new version exists; each plugin's GitHub Releases page says what changed.

## Why only here?

Each plugin checks where it was installed from. A copy from anywhere else pauses and
shows the commands to move it here, so everyone runs the version that is tested and
updated in one place. A plugin removed from this list keeps working as installed; it
just gets no more updates.

## Requirements

Claude Code with plugin support, in the terminal or the desktop app. Each plugin's own
page lists anything else it needs.

## License

MIT, every plugin.
