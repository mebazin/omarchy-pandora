# Pandora

Station radio in the Omarchy bar. Click the P to open a card: now playing,
play/pause, skip, thumbs, and your stations. Audio keeps going after the
card closes.

This talks to Pandora's unofficial web API. The dedicated Pandora window
(Super + Space → Pandora) is still there for the full site. Only one of
them can stream at a time.

## Use

- Click the bar icon, or Super + Shift + M. Bind the key to
  `omarchy-shell shell toggle mark.pandora` so the card opens on the
  focused monitor; the plugin's own IPC target only reaches one bar copy
- Middle-click the icon to play/pause
- Sign in once; the password goes in the system keyring

## Files

- `bin/pandora-engine` — login, stations, mpv playback
- `Service.qml` — socket client the bar reads
- `BarWidget.qml` / `Popover.qml` — icon and card
