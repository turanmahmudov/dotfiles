import QtQuick
import qs.Commons
import qs.Services
import qs.Ui

// Settings of one plugin. The manifest names the fields, and the values live under
// `plugins` in shell.json, so they hold for every placement of that plugin.
PanelPage {
  id: page

  readonly property string targetPlugin: (payload && payload.plugin) ? String(payload.plugin) : ""
  readonly property var plugin: PluginRegistry.findPlugin(targetPlugin)
  readonly property var fields: plugin ? (plugin.settings || []) : []
  readonly property var values: ConfigStore.readPluginSettings(targetPlugin)

  title: plugin ? plugin.name : targetPlugin

  function readValue(field) {
    if (page.values[field.key] !== undefined)
      return page.values[field.key]
    return field.default
  }

  Text {
    width: parent.width
    wrapMode: Text.WordWrap
    visible: page.fields.length === 0
    text: "This plugin has no settings."
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontCaption
  }

  Repeater {
    model: page.fields

    SettingsField {
      required property var modelData
      width: parent.width
      field: modelData
      value: page.readValue(modelData)
      onEdited: (value) => ConfigStore.writePluginSetting(page.targetPlugin, modelData.key, value)
    }
  }

  ConfirmAction {
    visible: page.fields.length > 0 && Object.keys(page.values).length > 0
    danger: false
    label: "Restore the defaults"
    onConfirmed: ConfigStore.clearPluginSettings(page.targetPlugin)
  }
}
