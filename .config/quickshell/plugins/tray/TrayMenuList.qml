import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Column {
  id: list
  property var menuHandle: null
  property int depth: 0
  signal requestClose()

  spacing: 0

  QsMenuOpener {
    id: opener
    menu: list.menuHandle
  }

  Repeater {
    model: opener.children

    delegate: Column {
      id: entry
      required property var modelData
      width: list.width
      property bool expanded: false

      Item {
        width: parent.width
        height: entry.modelData.isSeparator ? 7 : 28

        Rectangle {
          visible: entry.modelData.isSeparator
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          height: 1
          color: Theme.alpha(Theme.fg, 0.15)
        }

        Rectangle {
          visible: !entry.modelData.isSeparator
          anchors.fill: parent
          radius: Style.radiusSmall
          color: (rowMouse.containsMouse && entry.modelData.enabled) ? Theme.alpha(Theme.fg, 0.12) : "transparent"

          Row {
            id: leftRow
            anchors.left: parent.left
            anchors.leftMargin: 8 + list.depth * 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Icon {
              visible: entry.modelData.buttonType !== QsMenuButtonType.None && entry.modelData.checkState === Qt.Checked
              anchors.verticalCenter: parent.verticalCenter
              name: "check-check"
              size: 13
              color: Theme.fg
            }

            Image {
              visible: entry.modelData.icon !== ""
              anchors.verticalCenter: parent.verticalCenter
              width: 16
              height: 16
              smooth: true
              source: entry.modelData.icon
              sourceSize.width: 16
              sourceSize.height: 16
            }
          }

          Text {
            anchors.left: leftRow.right
            anchors.leftMargin: leftRow.width > 0 ? 6 : 0
            anchors.right: arrow.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: entry.modelData.text
            color: entry.modelData.enabled ? Theme.fg : Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 1
          }

          Icon {
            id: arrow
            visible: entry.modelData.hasChildren
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            name: "chevron-right"
            size: 14
            color: Theme.fgDim
            rotation: entry.expanded ? 90 : 0
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: entry.modelData.enabled
            onClicked: {
              if (entry.modelData.hasChildren)
                entry.expanded = !entry.expanded
              else {
                entry.modelData.triggered()
                list.requestClose()
              }
            }
          }
        }
      }

      Loader {
        active: entry.expanded && entry.modelData.hasChildren
        visible: active
        width: list.width
        source: Qt.resolvedUrl("TrayMenuList.qml")
        onLoaded: {
          item.width = Qt.binding(function () {
            return list.width
          })
          item.menuHandle = entry.modelData
          item.depth = list.depth + 1
          item.requestClose.connect(list.requestClose)
        }
      }
    }
  }
}
