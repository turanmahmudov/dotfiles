import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.notifications"
  cardWidth: 380

  property var expandedKeys: ({})

  function isExpanded(key) {
    return expandedKeys[key] === true
  }

  function toggleExpanded(key) {
    var next = Object.assign({}, expandedKeys)
    next[key] = !isExpanded(key)
    expandedKeys = next
  }

  Item {
    id: headerBar
    width: parent.width
    height: 22

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: "Notifications"
      color: Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize + 1
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 14

      Icon {
        size: 16
        name: Notifications.dnd ? "bell-off" : "bell"
        color: (dndArea.containsMouse || Notifications.dnd) ? Theme.accent : Theme.fgDim
        MouseArea {
          id: dndArea
          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Notifications.toggleDnd()
        }
      }

      Icon {
        size: 16
        visible: Notifications.list.length > 0
        name: "trash-2"
        color: clearArea.containsMouse ? Theme.urgent : Theme.fgDim
        MouseArea {
          id: clearArea
          anchors.fill: parent
          anchors.margins: -6
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Notifications.clearAll()
        }
      }
    }
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

  Flickable {
    id: listFlick
    visible: Notifications.groups.length > 0
    width: parent.width
    height: Math.min(contentCol.implicitHeight, panel.maxContentHeight - headerBar.height - panel.innerSpacing)
    contentWidth: width
    contentHeight: contentCol.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    maximumFlickVelocity: 4000
    flickDeceleration: 2500
    pixelAligned: true
    interactive: contentHeight > height

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: (event) => {
        var step = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 1.2
        listFlick.contentY = Math.max(0, Math.min(listFlick.contentHeight - listFlick.height, listFlick.contentY - step))
        event.accepted = true
      }
    }

    Column {
      id: contentCol
      width: listFlick.width
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
  }
}
