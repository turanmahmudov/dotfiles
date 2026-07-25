pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  property bool connected: false
  readonly property string state: connected ? "connected" : "off"

  function toggle() {
    Quickshell.execDetached([root.home + "/.local/bin/gp-vpn-toggle"])
    root.watchClosely()
  }

  function disconnect() {
    Quickshell.execDetached([root.home + "/.local/bin/gp-vpn", "disconnect"])
    root.watchClosely()
  }

  function refresh() {
    checkProc.running = true
  }

  // gp-vpn takes a while to bring the tunnel up or down, so poll quickly for a
  // window after a user action instead of polling quickly forever.
  function watchClosely() {
    burst.remaining = 20
    burst.restart()
  }

  property Process checkProc: Process {
    command: ["pgrep", "-x", "openconnect"]
    onExited: (code) => root.connected = (code === 0)
  }

  property Timer burst: Timer {
    property int remaining: 0
    interval: 1500
    repeat: true
    onTriggered: {
      root.refresh()
      remaining = remaining - 1
      if (remaining <= 0)
        stop()
    }
  }

  property Timer poll: Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  property FileView pidWatch: FileView {
    path: "/tmp/gp-vpn.pid"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
    onLoaded: root.refresh()
    onLoadFailed: root.refresh()
  }

  property IpcHandler ipc: IpcHandler {
    target: "vpn"
    function toggle(): string {
      root.toggle()
      return "ok"
    }
    function disconnect(): string {
      root.disconnect()
      return "ok"
    }
    function status(): string {
      return root.state
    }
  }

  Component.onCompleted: root.refresh()
}
