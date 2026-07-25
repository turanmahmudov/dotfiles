# Plugins

Each module is a directory under `~/.config/quickshell/plugins/<name>/`.
`PluginRegistry` discovers plugins by convention: directory name becomes the
id `shell.<name>`, and entry files decide kinds.

| File          | Kind         |
|---------------|--------------|
| `Widget.qml`  | `bar-widget` |
| `Panel.qml`   | `panel`      |
| `Overlay.qml` | `overlay`    |


Plugin-local singletons (optional) are registered via a `qmldir` in the plugin
directory. Shared shell state stays in `Services/` (`ConfigStore`, `PluginRegistry`).
Domain state lives in the owning plugin (singleton via `qmldir`).

## Bar-widget contract

The host assigns on the root item:

- `settings` — layout entry from `shell.json`
- `controller` — `PanelController`
- `screen` — the `ShellScreen` this bar instance is on
- `pluginId` — `shell.<name>`

Prefer `Ui.BarItem`. Open the plugin's panel with `openPanel()` (uses `pluginId`).

```qml
import qs.Commons
import qs.Ui

BarItem {
  onClicked: openPanel()
  Icon { name: "clock"; color: hovered ? Theme.fgDim : Theme.fg }
}
```

## Panel contract

A panel is a `Ui.Popup`. The controller injects `controller`, `anchorItem`,
`payload`, and `pluginId`.

```qml
import qs.Commons
import qs.Ui

Popup {
  cardWidth: 300
  Text { text: "panel body"; color: Theme.fg }
}
```

## Layout

`~/.config/quickshell/shell.json` holds `bar.position` and
`bar.layout.{left,center,right}`. A section entry is a widget or a group:

```json
"right": [
  { "id": "shell.audio" },
  {
    "group": [
      { "id": "shell.network" },
      { "id": "shell.vpn" },
      { "id": "shell.bluetooth" }
    ]
  }
]
```

Widget-specific settings live on the layout entry (e.g. clock `format`,
workspaces `persistent`). Overlay plugins mount whenever `Overlay.qml` exists.
