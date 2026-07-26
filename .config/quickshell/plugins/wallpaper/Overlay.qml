import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string generatedDir: home + "/.config/themes/_generated"
  readonly property int fadeDuration: 500

  // The generated wallpaper is a symlink whose path never changes, so it is
  // resolved to the concrete file: a stable source would leave Image showing
  // the previous image from cache.
  property string current: ""
  property string previous: ""

  function resolve() {
    resolveProc.running = true
  }

  function apply(path) {
    if (!path.length || path === root.current)
      return
    root.previous = root.current
    root.current = path
  }

  property Process resolveProc: Process {
    command: ["readlink", "-f", root.generatedDir + "/wallpaper"]
    stdout: StdioCollector {
      onStreamFinished: root.apply(text.trim())
    }
  }

  // system-theme relinks the wallpaper before writing this file, so a change
  // here means the new target is already in place.
  property FileView stateFile: FileView {
    path: root.generatedDir + "/state"
    watchChanges: true
    printErrors: false
    onLoaded: root.resolve()
    onFileChanged: reload()
  }

  Component.onCompleted: root.resolve()

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      screen: modelData
      color: "black"
      WlrLayershell.namespace: "quickshell-wallpaper"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Image {
        anchors.fill: parent
        visible: root.previous.length > 0
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        source: root.previous.length > 0 ? "file://" + root.previous : ""
      }

      Image {
        id: incoming
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        opacity: 0
        source: root.current.length > 0 ? "file://" + root.current : ""

        // Held transparent until the new image has decoded, so the outgoing one
        // stays visible instead of dropping to the black backing colour.
        onStatusChanged: if (status === Image.Ready) fadeIn.restart()

        NumberAnimation {
          id: fadeIn
          target: incoming
          property: "opacity"
          from: 0
          to: 1
          duration: root.fadeDuration
          easing.type: Easing.InOutQuad
        }
      }
    }
  }
}
