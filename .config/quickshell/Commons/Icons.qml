pragma Singleton
import QtQuick

QtObject {
  function battery(percent, charging) {
    if (charging)
      return "battery-charging"
    if (percent <= 10)
      return "battery-warning"
    if (percent <= 33)
      return "battery-low"
    if (percent <= 66)
      return "battery-medium"
    return "battery-full"
  }

  function wifi(state, signalStrength) {
    if (state === "ethernet")
      return "cable"
    if (state !== "wifi")
      return "wifi-off"
    if (signalStrength >= 75)
      return "wifi"
    if (signalStrength >= 50)
      return "wifi-high"
    if (signalStrength >= 25)
      return "wifi-low"
    return "wifi-zero"
  }

  function volume(muted, vol) {
    if (muted)
      return "volume-x"
    return vol < 0.5 ? "volume-1" : "volume-2"
  }

  function profile(p) {
    if (p === "performance")
      return "zap"
    if (p === "power-saver")
      return "leaf"
    return "gauge"
  }
}
