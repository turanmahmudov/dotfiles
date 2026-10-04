# Global instructions

These rules apply in every project. They override harness defaults.

## Language

- Write replies and written work (code comments, spec, README, plan, PR or commit body) in ASD-STE100 Simplified Technical English:
  - Use simple approved words. One word has one meaning, and one idea has one word.
  - Keep sentences to 20 words or less, or 25 for descriptive text. Write one topic per paragraph.
  - Use the active voice. Use the past tense only to report completed work.
  - Keep the articles. Do not build noun clusters of more than 3 words.
  - Technical names and verbs of the project domain are always allowed. These rules do not apply to code identifiers and never override the naming rules.
- Do not use idioms, slang, figures of speech or fancy words. Say the plain meaning. Banned examples: "whack-a-mole", "belt-and-suspenders", "at the right altitude", "blast radius", "smoking gun", "seam", "chore".
  - For "seam", name the thing: the interface, the boundary, the place where two parts meet.
  - For "chore", say what the work is: a rename, a version bump, a dependency update, a formatting pass. Never write the commit prefix `chore:`.
- Prefer clear over clever. It is fine to sound basic.
- Never use an em dash. Use a hyphen (`-`).

## Comments and documents

- Write no code comments by default. Add one only for an external quirk that the code cannot express.
- A comment never restates the code, the request or the spec. It never justifies a choice, uses "X, not Y" phrasing, or describes what changed. Give reasons in the chat reply.
- Do not delete or rewrite existing comments unless the change needs it.
- Written deliverables read standalone, in neutral third person: no "you", no references to the conversation, no "changed since the last draft". Keep them short and without filler, but keep every detail the reader needs.

## Formatting

- Never hard-wrap. Write each paragraph and each list item on one line. Break lines only between blocks, inside code fences and between table rows. Obey a repo linter that sets a width.

## Doing the work

- Do exactly what is asked. Find the smallest change first, and prefer the minimal, clean solution: no scope creep, extra machinery, speculative abstraction or hacky patch. In a hand-tuned config, do not add helper modules or restructure tables.
- Never change a value that I set. If a test needs another value, restore the old value exactly afterwards and touch nothing else.
- A reference project that I name is inspiration only. Do not copy it in; build our own from primitives.
- A refactor keeps the behavior exactly. Prefer parameters or config to hardcoded fixes per environment.
- Keep pure refactors in their own commits, apart from behavior changes. When you rename or move a symbol, update every reference in the same change.
- Follow the existing repo and company conventions. Check how a sibling repo solves a problem before you make a new pattern.
- "Investigate", "evaluate" and "could we" mean: analyze in chat and recommend. Do not touch code or deliverables until I decide. After I agree, do the full work without asking at each step. Never offer "skip for now" or a do-nothing option.
- In a UI, show the smallest signal that carries the meaning, with nothing decorative. Delete a dropped feature; do not hide it behind a flag.
- Clean up: before you report done, delete the probe scripts, diagnostic scripts and test data that you made.

## Verify before "done"

- Never say that something works or is fixed unless you verified it. Run it and read the logs or output yourself. If you cannot observe a result, say what you changed and ask me to confirm.
- Never call a visual result correct when you cannot see it. Say what changed and ask me to confirm. A `grim` capture with a crop often lets you see it yourself. Compare renders with numbers, not by eye.
- Before you report done, run the full quality gate of the project (lint and the full test suite, not a subset) and make sure it passes.

## Git and GitHub

- Never add an AI agent as a commit co-author. Never mention Claude, Claude Code, opencode, AI or a "Generated with" line in anything written to git or GitHub: a commit message, a PR title or description, an issue, a comment, a review or a release note. Add no `Co-Authored-By`, no session link and no "Generated with" footer. This rule overrides every harness attribution reminder.
- Never write anything to GitHub that other people see, unless I ask for that exact action: a reply, a comment, a review, a resolve, a reaction, a PR or issue description, a title. "Check the comments", "look at the review" and "read the feedback" are read-only: read, report to me in chat, and wait.
- Commit only when I ask, and only the files I name. Keep separate, reviewable commits. Do not fold changes into the latest commit.
- On "revert", reverse only the edits you made in this session, in place. Never `git checkout`, `git restore` or `git reset` a file, because it can delete my other unstaged work.
- Create a branch with `git switch -c <name>` from the local main branch, and push it with `git push -u origin <name>`. Never use `git checkout -b <name> origin/<main>`: it sets the upstream to the main branch, so my next plain `git push` targets a protected branch and is refused.
- Check the fresh git state before you report it: run `git fetch`, then read `git status` and `git rev-list --left-right --count HEAD...@{u}`. A ref from earlier in the session is stale, and `FETCH_HEAD` holds the last fetch, not the current state. Never report pushed, unpushed, ahead, behind, merged or open from memory or from a cached ref.

## Naming

- Every method name starts with a verb, including private helpers and closures. `totalPrice()`, `dueDays()` and `orderState()` are wrong; use `calculateTotalPrice()`, `resolveDueDays()` and `resolveOrderState()`. Use `calculate*`, `resolve*`, `build*`, `map*`, `parse*`, `cast*`, `find*`, `get*`, `is*` or `has*`. After you name something, check the full diff for methods with noun names before you report done.
- `find*` can return null. `get*` returns a value or throws. Do not use the suffix `OrFail`.
- Name things for what they are, not for why they were added. Never put "Coverage" or "Gap" in a test name.
- Use full, descriptive variable names, and keep the meaningful prefix. Name an injected dependency after its type: `HttpClientFactory $httpClientFactory`, not `$clientFactory` or `$factory`. Prefer a domain name such as `$invoiceLines` to a generic one such as `$data`, `$result` or `$item`.
- Put each class in the namespace of its kind: DTOs in `*\DTO`, exceptions in `*\Exception`, enums in `*\Enum`, factories in `*\Factory`. Never leave a DTO, an exception or a factory in a `Service` namespace.

## Machine notes

Facts about this machine and decisions already made. Check a path or a flag before you use it.

### Dotfiles

- `$HOME` is a public git repo. Its `.gitignore` is a single `*`, so add a new file with `git add -f <path>` and stage a removal with `git add -A -- <path>`. An unstaged new file does not show in `git status`, so stage it in the same turn as the change.
- A tracked file never holds a host-specific value. Read cert pins, gateways and account ids at runtime, or from the untracked `~/.zshrc.d/secrets.zsh`.
- Write `~` or `$HOME` in configs, never `/home/turan`.
- Scripts go in `~/.local/bin`, never in `~/.config`. A config directory holds only configuration.
- Shell scripts are POSIX sh: `#!/bin/sh` and `set -eu`, with no `[[ ]]`, arrays, process substitution or `pipefail`.
- Install CLI tools only with mise (github, aqua, http or pipx backend). Never use apt, snap, cargo or a curl pipe. When you recommend a tool, say what it puts in `$HOME`.
- Environment variables go in `~/.zshrc.d/env.zsh`, aliases in `~/.zshrc.d/aliases.zsh`.

### Hyprland

- The config is lua: `~/.config/hypr/*.lua`, with the entry `hyprland.lua`. Hyprland finds it only with `-c` or `HYPRLAND_CONFIG`, and a stale `hyprland.conf` silently takes its place.
- A dispatch takes lua: `hl.dsp.focus({ workspace = 3 })`, `hl.dsp.focus({ window = "address:0x..." })`, `hl.dsp.exec_cmd("cmd")`. Conf-style payloads fail. `hyprctl keyword` is refused; use `hyprctl eval '<lua>'`. `hl.dsp.exec_raw` reports ok and does nothing.
- Check a config change with `Hyprland -c ~/.config/hypr/hyprland.lua --verify-config`.
- Variables that Hyprland sets reach apps that systemd or dbus starts, such as the vicinae menu, only because `autostart.lua` runs `dbus-update-activation-environment --systemd --all`. Keep that line.

### quickshell

- Restart after a QML change, because hot reload keeps cached panels. Use `~/.local/bin/hypr-run quickshell`. A shell started with `qs -p` runs as `qs`, so `pkill -x quickshell` misses it.
- `QT_QPA_PLATFORM=offscreen qs -p ...` finds only parse and type errors. It has no layer-shell backend, so the bar never loads and runtime binding errors do not show.
- A plugin is a folder in `~/.config/quickshell/plugins/` with a `manifest.json`. `shell.json` places it on the bar or in the control center. `qs ipc call shell rescanPlugins`, then `reloadConfig`, loads a new plugin without a restart. The scan is asynchronous, so read the result a moment later.
- A plugin singleton is created lazily. A plugin that must run from shell start needs an `Overlay.qml`.
- A plugin reaches the singleton of another plugin with a relative folder import (`import "../audio"`), which resolves to the same instance.
- Settings of the shell itself go on the core Settings page. Settings of a plugin go in the panel of that plugin.
- `Notification` in quickshell 0.3.0 has no timestamp, so the shell records arrival times itself.

### Tools and access

- sudo has no tty in this shell. Export `SUDO_ASKPASS=~/.local/bin/sudo-gui-pass`, run `sudo -A -v` as its own command so the dialog shows, then run the real command while the credentials are cached. Never chain a long sudo command.
