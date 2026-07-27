# Plugins

Each plugin is a directory under `~/.config/quickshell/plugins/<name>/`. The directory name gives the plugin id `shell.<name>`. A `manifest.json` in that directory declares what the plugin exposes, and `PluginRegistry` reads it at start and on `rescanPlugins`. A directory without a manifest is not loaded.

A plugin declares what it has. `shell.json` decides where those parts go.

Plugin-local singletons are registered in a `qmldir` in the plugin directory. Shared shell state stays in `Services/` (`ConfigStore`, `PluginRegistry`, `StateStore`). Domain state lives in the owning plugin.

## Manifest

```json
{
  "name": "Sound",
  "widgets": {
    "bar": { "surface": "bar", "file": "Widget.qml" },
    "volume": { "surface": "cc", "file": "CcVolume.qml" }
  },
  "page": { "mode": "cc", "file": "Page.qml" },
  "overlay": { "file": "Overlay.qml" }
}
```

| Field     | Meaning                                                                     |
|-----------|-----------------------------------------------------------------------------|
| `name`    | Label of the plugin.                                                        |
| `settings`| Fields the plugin reads, edited from the shell settings page.                |
| `widgets` | Map of widget name to declaration. `surface` is `bar` or `cc`.               |
| `page`    | The panel of the plugin. `mode` is `cc` or `standalone`.                     |
| `overlay` | Surface that mounts while the shell runs.                                    |

Every field is optional. Each `file` is relative to the plugin directory. An overlay-only plugin declares `overlay` alone.

### Placement

The registry calculates the placement from the surfaces of the declared widgets:

- `bar`: every widget is on the bar (tray, clock, workspaces).
- `cc`: every widget is in the Control Center (session, screenshot).
- `bar-and-cc`: widgets on both surfaces (network, bluetooth, audio, display).

A plugin with no widget, for example an overlay-only plugin, has the placement `none`.

### Page modes

- `cc`: the page opens in the Control Center corner and gets a back arrow to the home page. Example: the Wi-Fi page.
- `standalone`: the page opens under the widget that summoned it and has no back arrow. Example: the clock calendar.

## Widget references

The config points at a widget with `shell.<name>` or `shell.<name>:<widget>`. The short form resolves while the plugin has one widget on that surface. The clock has one bar widget, so `shell.clock` is enough. The display has three cc widgets, so each reference names one: `shell.display:brightness`.

## Bar widget contract

The host assigns on the root item:

- `settings` - layout entry from `shell.json`
- `controller` - `PanelController`
- `screen` - the `ShellScreen` of this bar instance
- `pluginId` - `shell.<name>`

Prefer `Ui.BarItem`. Open the page of the plugin with `openPanel()`. Set `shown` to false to collapse the widget.

```qml
import qs.Commons
import qs.Ui

BarItem {
  onClicked: openPanel()
  Icon { name: "clock"; color: hovered ? Theme.fgDim : Theme.fg }
}
```

## CC widget contract

The host assigns `settings`, `controller`, `pluginId` and `compact`, but only the ones the widget declares. The section owns the width. The widget declares `implicitHeight`, and `shown: false` collapses its cell. Open the page of the plugin with `controller.go(pluginId)`.

These root types from `qs.Ui` fit the section types:

| Type        | Use                                                   | Section         |
|-------------|-------------------------------------------------------|-----------------|
| `Tile`      | Labelled control, big or small                        | `grid`          |
| `SliderRow` | One slider with an icon                               | `stack`         |
| `InfoRow`   | Row of a bordered list                                | `list`          |

A `Tile` renders big or small from the `compact` flag of its section, so one widget covers both. Big shows the sublabel and, with `hasDetail`, an arrow to the page of the plugin. Small is a labelled icon that reacts to one click. A widget may read its own `compact` value when the two sizes need different text.

```qml
import qs.Ui

Tile {
  id: root
  property var controller: null
  property string pluginId: ""

  iconName: Vpn.connected ? "shield-check" : "shield"
  label: "VPN"
  sublabel: Vpn.connected ? "Connected" : "Off"
  active: Vpn.connected
  hasDetail: true
  onTriggered: Vpn.toggle()
  onDetailRequested: if (root.controller) root.controller.go(root.pluginId)
}
```

## Page contract

A page is a `Ui.PanelPage`. The host assigns `controller`, `anchorItem`, `payload` and `pluginId`, and it draws the header from `title`. A page that is a feature you can turn off as a whole sets `hasSwitch`, `switchOn` and handles `switchToggled`.

```qml
import qs.Commons
import qs.Ui

PanelPage {
  title: "Sound"
  Text { text: "page body"; color: Theme.fg }
}
```

## Layout

`~/.config/quickshell/shell.json` holds `bar.position`, `bar.layout` and `cc.layout`.

A bar section entry is a widget or a group:

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

`cc.layout` is a list of sections, from the top of the Control Center to the bottom:

```json
"cc": {
  "layout": [
    { "title": "Toggles", "type": "grid", "columns": 3, "compact": true, "items": [{ "id": "shell.vpn:tile" }] },
    { "title": "Sliders", "type": "stack", "items": [{ "id": "shell.audio:volume" }] },
    { "title": "Info", "type": "list", "items": [{ "id": "shell.power:info" }] }
  ]
}
```

| Section key | Meaning                                                            |
|-------------|--------------------------------------------------------------------|
| `type`      | `grid` for equal cells, `stack` for one full width item per row, `list` for rows in one bordered card. |
| `columns`   | Cells per row of a grid. Items past the last cell wrap to a new row. |
| `compact`   | Renders the tiles of this section small.                            |
| `spacing`   | Overrides the gap between the items.                                |
| `title`     | Optional name, shown while the layout is edited. Normally left off: any widget can be dropped in any section, so a name goes stale. The trays use it. |
| `hint`      | Text shown while the layout is edited and the section is empty.     |

A section with no visible item collapses, except while the layout is edited.

## Plugin settings

A plugin declares the fields it reads at the top level of its manifest, and the shell builds the form. The values belong to the plugin, so they hold for every placement of it:

```json
{
  "name": "Clock",
  "settings": [
    { "key": "format", "type": "text", "label": "Time format", "hint": "Qt date format", "default": "ddd, MMM d  HH:mm" }
  ],
  "widgets": { "bar": { "surface": "bar", "file": "Widget.qml" } }
}
```

They are edited in one place, the Plugins list of the shell settings page, and stored under `plugins` in `shell.json` keyed by plugin id. Nothing about them lives on a widget, so no badge appears on a widget while the layout is edited.

A widget still reads them from its `settings` property. `ConfigStore.resolveSettings` builds that: a key the plugin declares always comes from the plugin block, never from the layout entry, so an old entry key cannot mask the value just set. The entry still carries whatever no schema declares, which is how the workspaces `persistent` map keeps working.

`key` names the field on the entry, and `label`, `hint` and `default` are optional. A field of an unknown type says so instead of guessing an editor.

| `type`   | Editor                | Extra keys                                  |
|----------|-----------------------|---------------------------------------------|
| `text`   | One line of text      |                                             |
| `bool`   | Switch beside a label |                                             |
| `number` | Slider with the value | `min`, `max`, `step`                        |
| `choice` | List of options       | `options`, each `{ "value", "label" }`      |

A widget reads its own field with a fallback, so an entry that never had the key keeps working:

```qml
readonly property string metric: (settings && settings.metric) ? String(settings.metric) : "mem"
```

While the layout is edited, a widget with declared fields gets a second badge in its other corner. It opens the form, which writes the value onto that one entry and leaves every other key alone. So the workspaces `persistent` map keeps working while it has no editor.

## Shell settings

The settings of the shell itself belong to core, not to a plugin. `PanelController.corePages` lists the pages core owns and resolves them before the registry, so `shell.settings` is reachable by id but is not a plugin: it cannot be placed in a layout, it never appears in a tray, and `listPlugins` does not report it.

`Core/SettingsPage.qml` holds them in groups that expand where they stand: Bar, Panel, and Text and shape. Their fields are dotted keys rather than layout entries, and `ConfigStore.readPath` and `writePath` reach them. `Style.applyConfig` follows the `style` block as it changes, so every size is live with no restart.

The same page lists every plugin that declares settings, and each opens `Core/PluginSettingsPage.qml` for that plugin.

Three ways in: the sliders button beside the pencil at the foot of the Control Center, the same button on the bar's edit row, and `qs ipc call shell settings` for a keybind.

## Going back

`PanelController` keeps the trail of pages it opened, so the back arrow returns to where the page was opened from rather than always to the home page: a plugin's settings go back to the settings page, and that goes back to the Control Center. Closing the panel clears the trail.

## Restoring defaults

A field whose value differs from the one its schema declares grows a small reset button beside its label. There are two wider resets. "Restore the default settings" drops the `style` and `plugins` blocks and the bar position, so every setting on the page and in every plugin falls back to what its schema and `Style` declare, and the layout is left alone. A plugin page also restores just its own block.

The layout has the same escape. `defaults/layout.json` holds the bar and panel arrangement the shell ships with, and the settings page writes it back over the current one. Both actions ask twice, since neither can be undone.

## Write safety

The shell writes `shell.json`, so it protects a hand edit. A save is refused while the copy on disk does not parse, which leaves a broken edit in place to be fixed rather than overwritten from memory. The first save of a session also copies the last text that parsed to `shell.json.bak`.

## Editing the layout

The pencil at the foot of the Control Center turns on edit mode, for the bar and the panel together. Items can then be dragged: within their container to reorder, or into another one to move. A dotted frame marks every container, the frame and a line mark where the item lands, and a container that gives up its last item stays open as a target. A widget that draws nothing right now, such as the recorder when nothing records, holds a named placeholder so it stays reachable.

The frames carry no names. Any widget can go in any container, so a name could not stay true, and the shape of a container already shows what it does to what lands in it.

Each surface has a "Not shown" tray holding the widgets its layout leaves out. A tray is one more container, so the same drag adds and removes: out of the tray to place a widget, into the tray to take one away. The cross in the corner of an item is the short way to send it to the tray. A tray is derived from the registry, never stored.

The panel keeps its tray below the last section. The bar grows a second row while editing, which carries its tray and the button that ends edit mode, so the bar can be arranged whether or not the panel is open. The three bar zones share the width equally while editing, to make the boundary between left, center and right unmistakable.

A change rewrites `bar.layout` and `cc.layout` in `shell.json` in one write, so the surfaces and the file never drift apart. `LayoutEditor` holds the working copies while editing, and `ConfigStore.saveLayouts` writes them back.

Sizes follow the container, not the item. Dragging a small toggle into a section of big tiles renders it big, and the other way round, so the same widget fits either place.

A group entry moves as one piece. Reordering inside a group is still a hand edit.
