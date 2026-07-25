import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Rectangle {
  id: card
  property var notif: null
  property int cardWidth: 360
  property bool showAppName: true

  function resolveIcon() {
    if (!notif)
      return ""
    if (notif.image && String(notif.image).length > 0)
      return String(notif.image)
    var a = notif.appIcon ? String(notif.appIcon) : ""
    if (!a.length)
      return ""
    if (a.charAt(0) === "/" || a.indexOf("file:") === 0 || a.indexOf("image:") === 0)
      return a
    return Quickshell.iconPath(a, "")
  }

  readonly property string iconSource: resolveIcon()
  readonly property bool hasImage: iconSource.length > 0
  readonly property bool critical: !!(notif && notif.urgency === 2)

  property bool bodyExpanded: false
  readonly property int bodyLineLimit: 4
  readonly property bool bodyOverflows: bodyExpanded ? bodyText.lineCount > bodyLineLimit : bodyText.truncated

  onNotifChanged: bodyExpanded = false

  readonly property var visibleActions: {
    var out = []
    if (notif && notif.actions) {
      for (var i = 0; i < notif.actions.length; i++) {
        var a = notif.actions[i]
        if (a && a.identifier !== "default" && String(a.text || "").length > 0)
          out.push(a)
      }
    }
    return out
  }

  function invokeDefault() {
    if (!notif || !notif.actions)
      return
    for (var i = 0; i < notif.actions.length; i++) {
      if (notif.actions[i] && notif.actions[i].identifier === "default") {
        notif.actions[i].invoke()
        return
      }
    }
  }

  function openHintTarget() {
    if (!notif || !notif.hints)
      return
    var target = notif.hints["x-quickshell-open"]
    if (target && String(target).length > 0)
      Quickshell.execDetached(["xdg-open", String(target)])
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      card.invokeDefault()
      card.openHintTarget()
      Notifications.dismiss(card.notif)
    }
  }

  HoverHandler {
    id: cardHover
  }

  width: cardWidth
  implicitHeight: Math.max(hasImage ? 60 : 0, col.implicitHeight + 20)
  radius: Style.radius
  color: cardHover.hovered ? Theme.alpha(Theme.bgAlt2, Style.surfaceAlpha) : Theme.alpha(Theme.bgAlt, Style.surfaceAlpha)
  border.color: critical ? Theme.urgent : Theme.alpha(Theme.fg, 0.12)
  border.width: 1

  Image {
    id: img
    visible: card.hasImage && status === Image.Ready
    width: visible ? 40 : 0
    height: 40
    anchors.left: parent.left
    anchors.leftMargin: visible ? 10 : 0
    anchors.verticalCenter: parent.verticalCenter
    fillMode: Image.PreserveAspectFit
    sourceSize.width: 80
    sourceSize.height: 80
    source: card.iconSource
  }

  Icon {
    id: closeBtn
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 8
    size: 14
    name: "x"
    color: closeArea.containsMouse ? Theme.fg : Theme.fgDim
    MouseArea {
      id: closeArea
      anchors.fill: parent
      anchors.margins: -6
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Notifications.dismiss(card.notif)
    }
  }

  Column {
    id: col
    anchors.left: img.visible ? img.right : parent.left
    anchors.leftMargin: img.visible ? 10 : 12
    anchors.right: closeBtn.left
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3

    Text {
      visible: card.showAppName && text.length > 0
      width: parent.width
      elide: Text.ElideRight
      text: card.notif ? (card.notif.appName || "") : ""
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 3
    }

    Item {
      width: parent.width
      height: summaryText.implicitHeight
      visible: summaryText.text.length > 0

      Text {
        id: summaryText
        anchors.left: parent.left
        anchors.right: ageText.visible ? ageText.left : parent.right
        anchors.rightMargin: ageText.visible ? 6 : 0
        elide: Text.ElideRight
        text: card.notif ? (card.notif.summary || "") : ""
        color: Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 1
        font.bold: true
      }

      Text {
        id: ageText
        anchors.right: parent.right
        anchors.baseline: summaryText.baseline
        visible: text.length > 0
        text: Notifications.formatAge(card.notif)
        color: Theme.fgDim
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 4
      }
    }

    Text {
      id: bodyText
      visible: text.length > 0
      width: parent.width
      wrapMode: Text.Wrap
      maximumLineCount: card.bodyExpanded ? 64 : card.bodyLineLimit
      elide: Text.ElideRight
      textFormat: Text.StyledText
      text: card.notif ? (card.notif.body || "") : ""
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 2
    }

    Text {
      id: bodyToggle
      visible: card.bodyOverflows
      topPadding: 2
      text: card.bodyExpanded ? "Show less" : "Show more"
      color: bodyToggleArea.containsMouse ? Theme.fg : Theme.accent
      font.family: Style.fontFamily
      font.pixelSize: Style.fontSize - 3

      MouseArea {
        id: bodyToggleArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.bodyExpanded = !card.bodyExpanded
      }
    }

    Row {
      visible: card.visibleActions.length > 0
      spacing: 6
      topPadding: 4

      Repeater {
        model: card.visibleActions

        delegate: Rectangle {
          id: actBtn
          required property var modelData
          implicitWidth: actLabel.implicitWidth + 20
          height: 26
          radius: Style.radiusSmall
          color: actArea.containsMouse ? Theme.alpha(Theme.fg, 0.15) : Theme.alpha(Theme.fg, 0.08)

          Text {
            id: actLabel
            anchors.centerIn: parent
            text: actBtn.modelData.text
            color: Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 2
          }

          MouseArea {
            id: actArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              actBtn.modelData.invoke()
              Notifications.dismiss(card.notif)
            }
          }
        }
      }
    }
  }
}
