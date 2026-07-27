import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Notifications"
  hasSwitch: true
  switchOn: !Notifications.dnd
  onSwitchToggled: Notifications.toggleDnd()

  property var expandedKeys: ({})

  function isExpanded(key) {
    return expandedKeys[key] === true
  }

  function toggleExpanded(key) {
    var next = Object.assign({}, expandedKeys)
    next[key] = !isExpanded(key)
    expandedKeys = next
  }

  Text {
    visible: Notifications.groups.length === 0
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    topPadding: 10
    bottomPadding: 10
    text: Notifications.dnd ? "Do not disturb" : "No notifications"
    color: Theme.fgDim
    font.family: Style.fontFamily
    font.pixelSize: Style.fontSize - 1
  }

  Column {
    id: contentCol
    visible: Notifications.groups.length > 0
    width: parent.width
    spacing: 8

    Repeater {
      model: Notifications.groups

      delegate: Column {
        id: groupCol
        required property var modelData
        width: contentCol.width
        spacing: 6

        readonly property string groupKey: modelData.key
        readonly property bool collapsible: modelData.count > 1
        readonly property bool expanded: collapsible && panel.isExpanded(groupKey)
        readonly property int hiddenCount: modelData.count - 1
        readonly property var older: {
          var arr = modelData.notifications || []
          return arr.slice(0, Math.max(0, arr.length - 1)).reverse()
        }

        Item {
          width: parent.width
          height: 18

          MouseArea {
            id: headerArea
            anchors.fill: parent
            anchors.rightMargin: 22
            enabled: groupCol.collapsible
            hoverEnabled: true
            cursorShape: groupCol.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: panel.toggleExpanded(groupCol.groupKey)
          }

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            z: 1

            Icon {
              visible: groupCol.collapsible
              anchors.verticalCenter: parent.verticalCenter
              size: 12
              name: "chevron-right"
              color: headerArea.containsMouse ? Theme.fg : Theme.fgDim
              transform: Rotation {
                origin.x: 6
                origin.y: 6
                angle: groupCol.expanded ? 90 : 0
                Behavior on angle {
                  NumberAnimation {
                    duration: Style.animFast
                    easing.type: Easing.OutCubic
                  }
                }
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: groupCol.modelData.appName + (groupCol.collapsible ? (" · " + groupCol.modelData.count) : "")
              color: headerArea.containsMouse ? Theme.fg : Theme.fgDim
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize - 2
              font.bold: true
            }
          }

          Icon {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            z: 1
            size: 14
            name: "trash-2"
            color: groupClear.containsMouse ? Theme.urgent : Theme.fgDim
            MouseArea {
              id: groupClear
              anchors.fill: parent
              anchors.margins: -4
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Notifications.dismissGroup(groupCol.modelData)
            }
          }
        }

        NotificationCard {
          notif: groupCol.modelData.latest
          cardWidth: groupCol.width
          showAppName: false
        }

        Item {
          id: stackPeek
          width: parent.width
          height: 13
          z: -1
          visible: groupCol.collapsible && !groupCol.expanded

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width - 22
            height: parent.height + Style.radius + groupCol.spacing
            radius: Style.radius
            color: peekArea.containsMouse ? Theme.alpha(Theme.bgAlt2, Style.surfaceAlpha) : Theme.alpha(Theme.bgAlt, Style.surfaceAlpha)
            border.color: Theme.alpha(Theme.fg, 0.12)
            border.width: 1
          }

          Text {
            anchors.centerIn: parent
            text: groupCol.hiddenCount + " more"
            color: peekArea.containsMouse ? Theme.fg : Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 4
          }

          MouseArea {
            id: peekArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: panel.toggleExpanded(groupCol.groupKey)
          }
        }

        Column {
          width: parent.width
          visible: groupCol.expanded
          spacing: 6

          Repeater {
            model: groupCol.older

            NotificationCard {
              required property var modelData
              notif: modelData
              cardWidth: groupCol.width
              showAppName: false
            }
          }
        }
      }
    }
  }

  WideButton {
    visible: Notifications.list.length > 0
    label: "Clear all"
    onClicked: Notifications.clearAll()
  }
}
