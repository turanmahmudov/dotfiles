pragma Singleton
import QtQuick
import Quickshell.Io
import qs.Services

QtObject {
  id: root

  property bool active: true

  function toggle() {
    active = !active
  }

  onActiveChanged: StateStore.set("keepAwake.active", root.active)

  property IpcHandler ipc: IpcHandler {
    target: "keepawake"
    function toggle(): string {
      root.toggle()
      return root.active ? "on" : "off"
    }
    function status(): string {
      return root.active ? "on" : "off"
    }
  }

  property Connections stateConn: Connections {
    target: StateStore
    function onRestored() {
      root.active = StateStore.get("keepAwake.active", root.active)
    }
  }

  // hypridle pauses its timers for a logind idle inhibitor; the Wayland
  // protocol inhibitor only counts while an inhibiting surface is alive.
  property Process inhibitProc: Process {
    running: root.active
    command: ["systemd-inhibit", "--what=idle", "--who=Quickshell",
              "--why=Keep awake", "--mode=block", "sleep", "infinity"]
  }

  Component.onCompleted: {
    if (StateStore.ready)
      root.active = StateStore.get("keepAwake.active", root.active)
  }
}
