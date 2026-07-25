import QtQuick
import Quickshell.Services.SystemTray
import qs.Commons

Item {
  id: root
  property var settings: ({})
  property var controller: null
  property var screen: null
  property string pluginId: ""

  readonly property var trayItems: SystemTray.items ? SystemTray.items.values : []
  readonly property bool shown: trayItems.length > 0

  implicitWidth: shown ? (row.implicitWidth + 2 * Style.paddingH) : 0
  implicitHeight: Style.barHeight - 10
  width: implicitWidth
  height: implicitHeight
  visible: shown

  TrayMenu {
    id: trayMenu
  }

  Connections {
    target: root.controller
    ignoreUnknownSignals: true
    function onOverlaysShouldClose() {
      trayMenu.close()
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 10

    Repeater {
      model: root.trayItems

      delegate: Item {
        id: trayItem
        required property var modelData
        width: 20
        height: 20

        function openMenu() {
          if (!trayItem.modelData || !trayItem.modelData.hasMenu)
            return
          if (root.controller)
            root.controller.hidePanels()
          trayMenu.openAt(trayItem.modelData, trayItem)
        }

        Image {
          anchors.centerIn: parent
          width: 16
          height: 16
          sourceSize.width: 32
          sourceSize.height: 32
          fillMode: Image.PreserveAspectFit
          asynchronous: true
          source: trayItem.modelData ? trayItem.modelData.icon : ""
          smooth: true
          mipmap: true
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: (m) => {
            if (!trayItem.modelData)
              return
            if (m.button === Qt.MiddleButton)
              trayItem.modelData.secondaryActivate()
            else if (m.button === Qt.RightButton || trayItem.modelData.onlyMenu)
              trayItem.openMenu()
            else
              trayItem.modelData.activate()
          }
        }
      }
    }
  }
}
