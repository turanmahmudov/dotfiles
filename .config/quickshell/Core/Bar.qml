import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services
import qs.Ui

PanelWindow {
  id: bar
  property var modelData
  property var controller: null
  screen: modelData

  anchors {
    top: Style.barAtTop
    bottom: !Style.barAtTop
    left: true
    right: true
  }
  implicitHeight: Style.barHeight
  color: "transparent"
  WlrLayershell.namespace: "quickshell-bar"
  exclusiveZone: Style.barHeight

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: if (bar.controller) bar.controller.hideAll()
  }

  // One layout entry: either a widget {id} or a group {group:[...]}.
  // Size slots from child.width (Loader), never child.implicitWidth (always 0 on Loader).
  component Slot: Item {
    id: slot
    required property var modelData

    readonly property bool isGroup: !!(modelData && modelData.group !== undefined)

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: isGroup ? group.width : widget.width
    height: Style.barHeight
    visible: width > 0

    BarWidget {
      id: widget
      anchors.verticalCenter: parent.verticalCenter
      entry: slot.isGroup ? null : slot.modelData
      controller: bar.controller
      hostScreen: bar.modelData
      visible: !slot.isGroup
      active: !slot.isGroup && !!(slot.modelData && slot.modelData.id)
    }

    BarGroup {
      id: group
      anchors.verticalCenter: parent.verticalCenter
      entries: slot.isGroup ? (slot.modelData.group || []) : []
      controller: bar.controller
      hostScreen: bar.modelData
      visible: slot.isGroup
    }
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: Style.sideMargin
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing
    Repeater {
      model: ConfigStore.leftWidgets
      Slot {}
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing
    Repeater {
      model: ConfigStore.centerWidgets
      Slot {}
    }
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: Style.sideMargin
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing
    Repeater {
      model: ConfigStore.rightWidgets
      Slot {}
    }
  }
}
