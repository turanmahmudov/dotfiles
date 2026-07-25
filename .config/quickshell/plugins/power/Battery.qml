pragma Singleton
import QtQuick
import Quickshell.Services.UPower

QtObject {
  id: root

  readonly property var dev: UPower.displayDevice
  readonly property bool present: !!dev && dev.isLaptopBattery
  readonly property int percent: dev ? Math.max(0, Math.min(100, Math.round(dev.percentage <= 1.0 ? dev.percentage * 100 : dev.percentage))) : 0
  readonly property int state: dev ? dev.state : 0
  readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
  readonly property bool full: state === UPowerDeviceState.FullyCharged

  readonly property real timeToEmpty: dev ? dev.timeToEmpty : 0
  readonly property real timeToFull: dev ? dev.timeToFull : 0

  // UPower reports 0 when it has no estimate yet, or when there is nothing to
  // estimate because the battery is full.
  readonly property string timeSummary: {
    if (!present || full)
      return ""
    var seconds = charging ? timeToFull : timeToEmpty
    if (!(seconds > 0))
      return ""
    return root.formatDuration(seconds) + (charging ? " until full" : " remaining")
  }

  function formatDuration(seconds) {
    var total = Math.round(seconds / 60)
    var hours = Math.floor(total / 60)
    var minutes = total % 60
    if (hours > 0)
      return minutes > 0 ? (hours + "h " + minutes + "m") : (hours + "h")
    return minutes + "m"
  }

  readonly property string profile: resolveProfileName(PowerProfiles.profile)
  readonly property var profiles: PowerProfiles.hasPerformanceProfile
    ? ["power-saver", "balanced", "performance"]
    : ["power-saver", "balanced"]

  function resolveProfileName(p) {
    if (p === PowerProfile.PowerSaver)
      return "power-saver"
    if (p === PowerProfile.Performance)
      return "performance"
    return "balanced"
  }

  function resolveProfileValue(name) {
    if (name === "power-saver")
      return PowerProfile.PowerSaver
    if (name === "performance")
      return PowerProfile.Performance
    return PowerProfile.Balanced
  }

  function setProfile(name) {
    PowerProfiles.profile = root.resolveProfileValue(name)
  }
}
