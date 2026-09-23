# Pandora plugin: development notes

Bar widget + popover card for Pandora station radio. Plugin id `mebazin.pandora`.
The live install and the git checkout are the same directory:
`~/.config/omarchy/plugins/mebazin.pandora`. Edit in place, then restart the
shell to test.

## Architecture

- `bin/pandora-engine` (Python 3, stdlib + `requests`): long-running daemon.
  Talks to Pandora's unofficial web API (`https://www.pandora.com/api/v1`),
  plays audio through `mpv --input-ipc-server`, stores the password with
  `secret-tool`, and serves newline-delimited JSON over a Unix socket at
  `$XDG_RUNTIME_DIR/mebazin.pandora/engine.sock`. State (`state.json`) and
  `engine.log` live in `~/.local/state/mebazin.pandora/`.
- `Service.qml`: the shell mounts this once as a service. It owns the socket
  client, relaunches the engine when it is down (capped at 5 spawns per
  outage), and exposes `state`, `stations`, and command functions.
- `BarWidget.qml`: the bar icon. Gets the shared service through
  `bar.shell.serviceFor(moduleName)`, falls back to a local `Service`.
  Hosts the `KeyboardPanel` popover and the `IpcHandler` target.
- `Popover.qml`: the card. Sign-in form, now playing, transport, station list.
- `PandoraIcon.qml` + `pandora.svg`: the colourised P mark.

### Engine threading model

Every Pandora HTTP call runs on the single `Worker` thread; results come back
to the main `select()` loop through a pipe and run in `done(result, exc)`
callbacks. Never call `self.api.*` directly from a command handler. Two
counters invalidate stale results: `session` (bumped on sign-out) and
`playback` (bumped on station change). `fetching` / `want_next` coordinate
the one in-flight fragment request. `_play_next` never blocks.

### Protocol

Client → engine: `{"type": "login"|"logout"|"play"|"pause"|"toggle"|"skip"|
"thumb"|"tired"|"select_station"|"refresh_stations"|"takeover", ...}`.
Engine → client: a full `{"type":"state", ...}` snapshot on connect, after
every change, and once a second while playing. `Service.qml` only replaces
its `stations` property when the list actually changes, so views bound to it
do not reset on progress ticks. Keep that property when adding fields.

## Non-obvious facts

- `secret-tool search` prints the item attributes on **stderr**. Parse
  `stdout + stderr` or autologin silently fails with `needs_login`.
- `Quickshell.execDetached` gives the engine its own session; it survives
  `omarchy restart shell`, which is what keeps audio going across restarts.
- Text colours come from `bar.foreground` (passed into `Popover.foreground`),
  matching the first-party Wi-Fi and Clockwork panels. Do not hardcode
  colours or use `Color.popups.text`; the theme's bar text is what panels use.
- There is one bar per monitor, so two widget copies exist and only one owns
  the `mebazin.pandora` IPC target. Hotkeys must use
  `omarchy-shell shell toggle mebazin.pandora` (routed to the focused monitor).
  `omarchy-shell mebazin.pandora play|pause|skip|thumbUp|thumbDown` are fine
  because they do not care which copy answers.
- The hotkey binding lives in the user's Hyprland config,
  outside this repo.

## Verifying changes

- Lint: `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml -I /usr/share/omarchy/shell -I . File.qml`
  (grep for `^Error`; unresolved `qs.*` import warnings are noise).
- Engine: `python3 -m py_compile bin/pandora-engine && bin/pandora-engine --self-test`.
- Reload: `omarchy restart shell`. Never `omarchy refresh shell` (resets shell.json).
- Restart the engine: `pkill -TERM -f 'pandora-eng[i]ne$'` — the bracket keeps
  `pkill -f` from matching the command line that runs it. The shell respawns
  the engine within ~2 s.
- Inspect state: connect to the socket and read one line of JSON, or
  `tail ~/.local/state/mebazin.pandora/engine.log`.
- Screenshot the card: `omarchy-shell shell toggle mebazin.pandora`, then
  `grim -o <monitor>`; the card is on the focused monitor.
- Shell source for reference APIs: `/usr/share/omarchy/shell` (`Ui/`,
  `Commons/`, `plugins/panels/network/Panel.qml` is a good model).
