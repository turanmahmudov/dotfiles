import QtQuick
import qs.Commons
import qs.Services
import qs.Ui

// Size and shape of the shell's own surfaces. Every field names a key in
// shell.json, and Style applies the whole block as it changes, so there is nothing
// to restart.
PanelPage {
  id: page
  title: "Settings"

  readonly property var groups: [
    {
      "title": "Bar",
      "fields": [
        {
          "path": "bar.position",
          "type": "choice",
          "label": "Position",
          "default": "top",
          "options": [
            { "value": "top", "label": "Top of the screen" },
            { "value": "bottom", "label": "Bottom of the screen" }
          ]
        },
        { "path": "style.barHeight", "type": "number", "label": "Height", "default": 35, "min": 24, "max": 60, "step": 1 },
        { "path": "style.barMargin", "type": "number", "label": "Margin from the edge", "default": 0, "min": 0, "max": 20, "step": 1 },
        { "path": "style.sideMargin", "type": "number", "label": "Margin at the sides", "default": 10, "min": 0, "max": 30, "step": 1 },
        { "path": "style.spacing", "type": "number", "label": "Gap between widgets", "default": 7, "min": 0, "max": 20, "step": 1 },
        { "path": "style.paddingH", "type": "number", "label": "Padding inside a widget", "default": 6, "min": 2, "max": 14, "step": 1 },
        {
          "path": "style.barBackgroundAlpha",
          "type": "number",
          "label": "Background opacity",
          "hint": "Zero leaves the bar transparent",
          "default": 0,
          "min": 0,
          "max": 1,
          "step": 0.05
        }
      ]
    },
    {
      "title": "Panel",
      "fields": [
        { "path": "style.panelWidth", "type": "number", "label": "Width", "default": 380, "min": 300, "max": 600, "step": 10 },
        { "path": "style.panelPadding", "type": "number", "label": "Padding", "default": 14, "min": 6, "max": 24, "step": 1 },
        { "path": "style.panelSpacing", "type": "number", "label": "Gap between sections", "default": 10, "min": 4, "max": 20, "step": 1 },
        { "path": "style.ccSpacing", "type": "number", "label": "Gap inside a section", "default": 7, "min": 4, "max": 16, "step": 1 },
        { "path": "style.surfaceAlpha", "type": "number", "label": "Background opacity", "default": 0.9, "min": 0.5, "max": 1, "step": 0.05 }
      ]
    },
    {
      "title": "Text and shape",
      "fields": [
        { "path": "style.fontFamily", "type": "text", "label": "Font", "default": "JetBrainsMono Nerd Font" },
        { "path": "style.fontSize", "type": "number", "label": "Font size", "default": 14, "min": 10, "max": 20, "step": 1 },
        { "path": "style.iconSize", "type": "number", "label": "Icon size", "default": 15, "min": 10, "max": 24, "step": 1 },
        { "path": "style.radius", "type": "number", "label": "Corner radius", "default": 10, "min": 0, "max": 20, "step": 1 }
      ]
    }
  ]

  readonly property var configurablePlugins: {
    PluginRegistry.revision
    var out = []
    var plugins = PluginRegistry.listPlugins()
    for (var i = 0; i < plugins.length; i++)
      if ((plugins[i].settings || []).length > 0)
        out.push(plugins[i])
    return out
  }

  Repeater {
    model: page.groups

    Column {
      id: group
      required property var modelData
      property bool expanded: false

      width: parent.width
      spacing: Style.space

      ListRow {
        iconName: group.expanded ? "chevron-down" : "chevron-right"
        label: group.modelData.title
        active: group.expanded
        value: group.modelData.fields.length + " settings"
        onClicked: group.expanded = !group.expanded
      }

      Column {
        width: parent.width
        spacing: Style.space
        visible: group.expanded

        Repeater {
          model: group.expanded ? group.modelData.fields : []

          SettingsField {
            required property var modelData
            width: parent.width
            field: modelData
            value: ConfigStore.readPath(modelData.path, modelData.default)
            onEdited: (value) => ConfigStore.writePath(modelData.path, value)
          }
        }
      }
    }
  }

  Text {
    text: "Plugins"
    color: Theme.accent
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
    font.bold: true
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: page.configurablePlugins.length === 0
    text: "No plugin declares settings."
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontMicro
  }

  InfoList {
    Repeater {
      model: page.configurablePlugins

      InfoRow {
        required property var modelData
        required property int index
        isFirst: index === 0
        isLast: index === page.configurablePlugins.length - 1
        iconName: "sliders-horizontal"
        label: modelData.name
        sublabel: modelData.id
        value: (modelData.settings || []).length + (modelData.settings.length === 1 ? " setting" : " settings")
        onClicked: if (page.controller)
          page.controller.summon("shell.settings.plugin", JSON.stringify({ "plugin": modelData.id }))
      }
    }
  }

  ConfirmAction {
    danger: false
    label: "Restore the default settings"
    onConfirmed: ConfigStore.clearAllSettings()
  }

  ConfirmAction {
    label: "Restore the default layout"
    onConfirmed: ConfigStore.restoreDefaultLayout()
  }
}
