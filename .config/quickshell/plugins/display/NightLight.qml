pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

QtObject {
  id: root

  property bool enabled: false
  property int temperature: 4000
  readonly property int minTemp: 2500
  readonly property int maxTemp: 6000

  property IpcHandler ipc: IpcHandler {
    target: "nightlight"
    function toggle(): string {
      root.toggle()
      return root.enabled ? "on" : "off"
    }
    function setTemp(kelvin: int): string {
      root.setTemperature(kelvin)
      return String(root.temperature)
    }
  }

  function apply() {
    if (enabled)
      Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(temperature)])
    else
      Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"])
  }

  function toggle() {
    enabled = !enabled
    apply()
  }

  function setTemperature(t) {
    var snapped = Math.max(minTemp, Math.min(maxTemp, Math.round(t / 100) * 100))
    if (snapped === temperature)
      return
    temperature = snapped
    if (enabled)
      apply()
  }

  function restore() {
    root.temperature = StateStore.get("nightLight.temperature", root.temperature)
    root.enabled = StateStore.get("nightLight.enabled", false)
    root.apply()
  }

  onEnabledChanged: StateStore.set("nightLight.enabled", root.enabled)
  onTemperatureChanged: StateStore.set("nightLight.temperature", root.temperature)

  property Connections stateConn: Connections {
    target: StateStore
    function onRestored() {
      root.restore()
    }
  }

  Component.onCompleted: {
    if (StateStore.ready)
      root.restore()
  }
}
