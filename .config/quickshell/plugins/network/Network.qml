pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Networking

QtObject {
  id: root

  readonly property var deviceList: Networking.devices ? Networking.devices.values : []

  readonly property var wifiDevice: findDevice(DeviceType.Wifi)
  readonly property var wiredDevice: findDevice(DeviceType.Wired)

  readonly property bool wifiConnected: !!wifiDevice && wifiDevice.connected
  readonly property bool wiredConnected: !!wiredDevice && wiredDevice.connected
  readonly property string state: wiredConnected ? "ethernet" : (wifiConnected ? "wifi" : "disconnected")

  readonly property var activeNetwork: findActiveNetwork()
  readonly property string ssid: activeNetwork ? String(activeNetwork.name || "") : ""
  readonly property int signalStrength: activeNetwork ? Math.round(activeNetwork.signalStrength * 100) : 0

  readonly property bool wifiEnabled: Networking.wifiEnabled

  // The scanner stays on for as long as a panel is open, so it cannot drive the
  // spinner; this tracks a manual rescan request instead.
  property bool scanning: false

  readonly property var networks: buildNetworks()

  property string ipAddress: ""

  function findDevice(type) {
    for (var i = 0; i < deviceList.length; i++)
      if (deviceList[i] && deviceList[i].type === type)
        return deviceList[i]
    return null
  }

  function findActiveNetwork() {
    if (!wifiDevice || !wifiDevice.networks)
      return null
    var aps = wifiDevice.networks.values
    for (var i = 0; i < aps.length; i++)
      if (aps[i] && aps[i].connected)
        return aps[i]
    return null
  }

  function buildNetworks() {
    if (!wifiDevice || !wifiDevice.networks)
      return []
    var aps = wifiDevice.networks.values
    var out = []
    for (var i = 0; i < aps.length; i++)
      if (aps[i] && String(aps[i].name || "").length > 0)
        out.push(aps[i])
    out.sort(function (a, b) {
      if (a.connected !== b.connected)
        return a.connected ? -1 : 1
      if (a.known !== b.known)
        return a.known ? -1 : 1
      return b.signalStrength - a.signalStrength
    })
    return out
  }

  function isSecured(network) {
    return !!network && network.security !== WifiSecurityType.Open
  }

  function toggleWifi() {
    Networking.wifiEnabled = !Networking.wifiEnabled
  }

  function setScannerEnabled(on) {
    if (wifiDevice)
      wifiDevice.scannerEnabled = on
    if (!on)
      root.scanning = false
  }

  function requestScan() {
    root.setScannerEnabled(true)
    root.scanning = true
    scanIndicator.restart()
  }

  property Timer scanIndicator: Timer {
    interval: 4000
    onTriggered: root.scanning = false
  }

  function connectKnown(network) {
    if (network)
      network.connect()
  }

  function connectWithPassword(network, password) {
    if (network)
      network.connectWithPsk(password)
  }

  function forget(network) {
    if (network)
      network.forget()
  }

  function disconnectWifi() {
    if (wifiDevice)
      wifiDevice.disconnect()
  }

  // NetworkDevice.address is the hardware address; the IPv4 lease needs a
  // lookup, done on connection change rather than on a timer.
  function refreshAddress() {
    var dev = wiredConnected ? wiredDevice : (wifiConnected ? wifiDevice : null)
    if (!dev) {
      ipAddress = ""
      return
    }
    addressProc.command = ["sh", "-c",
      "ip -4 -o addr show \"$1\" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1",
      "sh", String(dev.name)]
    addressProc.running = true
  }

  onStateChanged: root.refreshAddress()
  onActiveNetworkChanged: root.refreshAddress()

  property Process addressProc: Process {
    stdout: StdioCollector {
      onStreamFinished: root.ipAddress = text.trim()
    }
  }

  Component.onCompleted: root.refreshAddress()
}
