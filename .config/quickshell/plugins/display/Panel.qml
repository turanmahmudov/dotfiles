import QtQuick
import qs.Commons
import qs.Ui

Popup {
  id: panel
  pluginId: "shell.display"
  title: "Display"
  cardWidth: 340

  readonly property var scalePresets: [1, 1.25, 1.5, 2]
  property string scaleEditMon: ""

  onVisibleChanged: if (visible) {
    Monitors.refresh()
    Monitors.detectDdc()
    scaleEditMon = ""
  }

  function scaleLabel(s) {
    return (s % 1 === 0 ? s.toFixed(0) : (Math.round(s * 100) / 100)) + "x"
  }

  function scaleNumber(s) {
    return (Math.round(s * 10000) / 10000).toString()
  }

  function isPresetScale(s) {
    for (var i = 0; i < scalePresets.length; i++)
      if (Math.abs(s - scalePresets[i]) < 0.01)
        return true
    return false
  }

  function applyCustomScale(name, text) {
    var v = parseFloat(text)
    if (isNaN(v) || v <= 0)
      return
    Monitors.setScale(name, v)
    scaleEditMon = ""
  }

  Rectangle {
    width: parent.width
    height: 34
    radius: Style.radiusSmall
    color: NightLight.enabled ? Theme.alpha(Theme.accent, nlArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, nlArea.containsMouse ? 0.12 : 0.06)

    Row {
      anchors.centerIn: parent
      spacing: 6

      Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: NightLight.enabled ? "moon" : "sun"
        color: NightLight.enabled ? Theme.accent : Theme.fg
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: NightLight.enabled ? ("Night Light  ·  " + NightLight.temperature + "K") : "Night Light"
        color: NightLight.enabled ? Theme.accent : Theme.fg
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize - 1
      }
    }

    MouseArea {
      id: nlArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: NightLight.toggle()
    }
  }

  Item {
    width: parent.width
    height: 24
    visible: NightLight.enabled

    Icon {
      id: nlWarm
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      name: "sun"
      color: Theme.warning
      size: 16
    }

    Slider {
      anchors.left: nlWarm.right
      anchors.right: parent.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      stepSize: 100 / (NightLight.maxTemp - NightLight.minTemp)
      value: (NightLight.temperature - NightLight.minTemp) / (NightLight.maxTemp - NightLight.minTemp)
      onMoved: (v) => NightLight.setTemperature(NightLight.minTemp + v * (NightLight.maxTemp - NightLight.minTemp))
    }
  }

  Column {
    width: parent.width
    spacing: 12

    Repeater {
      model: Monitors.list

      delegate: Column {
        id: monBlock
        required property var modelData
        width: parent.width
        spacing: 6

        Item {
          width: parent.width
          height: nameCol.implicitHeight

          Column {
            id: nameCol
            anchors.left: parent.left
            anchors.right: toggle.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
              text: monBlock.modelData.name
              color: monBlock.modelData.focused ? Theme.accentActive : Theme.fg
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize
              font.bold: true
            }

            Text {
              width: parent.width
              elide: Text.ElideRight
              text: {
                var m = monBlock.modelData
                if (m.disabled)
                  return (m.internal ? "Internal display" : (m.description || "External display")) + " · off"
                return m.width + "×" + m.height + " @ " + m.refreshRate + "Hz · scale " + panel.scaleLabel(m.scale)
              }
              color: Theme.fgDim
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize - 2
            }
          }

          Rectangle {
            id: toggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 52
            height: 26
            radius: Style.radiusSmall
            readonly property bool on: !monBlock.modelData.disabled
            color: on ? Theme.alpha(Theme.accent, toggleArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, toggleArea.containsMouse ? 0.12 : 0.06)

            Text {
              anchors.centerIn: parent
              text: toggle.on ? "On" : "Off"
              color: toggle.on ? Theme.accent : Theme.fgDim
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize - 1
            }

            MouseArea {
              id: toggleArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Monitors.setEnabled(monBlock.modelData.name, !toggle.on)
            }
          }
        }

        Item {
          id: monBright
          width: parent.width
          height: 24
          readonly property bool ddc: !monBlock.modelData.internal && Monitors.hasDdc(monBlock.modelData.name)
          visible: !monBlock.modelData.disabled && ((monBlock.modelData.internal && Brightness.available) || ddc)
          property real ddcValue: 0
          property int ddcApplied: -1
          readonly property int level: ddc ? Math.round(ddcValue * 100) : Brightness.value

          Connections {
            target: Monitors
            function onDdcByNameChanged() {
              if (monBright.ddc && !ddcDebounce.running) {
                var b = Monitors.ddcBrightness(monBlock.modelData.name)
                if (b >= 0) {
                  monBright.ddcValue = b / 100
                  monBright.ddcApplied = b
                }
              }
            }
          }

          Timer {
            id: ddcDebounce
            interval: 250
            onTriggered: {
              var t = Math.round(monBright.ddcValue * 100)
              if (t !== monBright.ddcApplied) {
                monBright.ddcApplied = t
                Monitors.setDdcBrightness(monBlock.modelData.name, t)
              }
            }
          }

          Icon {
            id: monBrightIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            name: "sun"
            color: Theme.fg
            size: 16
          }

          Text {
            id: monBrightPct
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: monBright.level + "%"
            color: Theme.fgDim
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 2
          }

          Slider {
            anchors.left: monBrightIcon.right
            anchors.right: monBrightPct.left
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            value: monBright.ddc ? monBright.ddcValue : (Brightness.value / 100)
            onMoved: (v) => {
              if (monBright.ddc) {
                monBright.ddcValue = v
                ddcDebounce.restart()
              } else {
                Brightness.setPercent(Math.round(v * 100))
              }
            }
          }
        }

        Row {
          visible: !monBlock.modelData.disabled
          spacing: 6

          Repeater {
            model: panel.scalePresets

            delegate: Rectangle {
              id: preset
              required property var modelData
              readonly property bool active: Math.abs(monBlock.modelData.scale - modelData) < 0.01
              width: 52
              height: 28
              radius: Style.radiusSmall
              color: active ? Theme.alpha(Theme.accent, presetArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, presetArea.containsMouse ? 0.12 : 0.06)

              Text {
                anchors.centerIn: parent
                text: panel.scaleLabel(preset.modelData)
                color: preset.active ? Theme.accent : Theme.fg
                font.family: Style.fontFamily
                font.pixelSize: Style.fontSize - 1
              }

              MouseArea {
                id: presetArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Monitors.setScale(monBlock.modelData.name, preset.modelData)
              }
            }
          }

          Rectangle {
            id: customPill
            readonly property bool isCustom: !panel.isPresetScale(monBlock.modelData.scale)
            readonly property bool editing: panel.scaleEditMon === monBlock.modelData.name
            implicitWidth: customLabel.implicitWidth + 20
            height: 28
            radius: Style.radiusSmall
            color: (isCustom || editing) ? Theme.alpha(Theme.accent, customArea.containsMouse ? 0.28 : 0.2) : Theme.alpha(Theme.fg, customArea.containsMouse ? 0.12 : 0.06)

            Text {
              id: customLabel
              anchors.centerIn: parent
              text: customPill.isCustom ? panel.scaleLabel(monBlock.modelData.scale) : "Custom"
              color: (customPill.isCustom || customPill.editing) ? Theme.accent : Theme.fg
              font.family: Style.fontFamily
              font.pixelSize: Style.fontSize - 1
            }

            MouseArea {
              id: customArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.scaleEditMon = customPill.editing ? "" : monBlock.modelData.name
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 34
          radius: Style.radiusSmall
          color: Theme.alpha(Theme.fg, 0.06)
          visible: !monBlock.modelData.disabled && panel.scaleEditMon === monBlock.modelData.name

          TextInput {
            id: scaleInput
            anchors.left: parent.left
            anchors.right: applyBtn.left
            anchors.leftMargin: 10
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize - 1
            clip: true
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator {
              bottom: 0.5
              top: 3.0
              decimals: 4
              notation: DoubleValidator.StandardNotation
            }
            focus: parent.visible
            onVisibleChanged: if (visible) {
              text = panel.scaleNumber(monBlock.modelData.scale)
              forceActiveFocus()
              selectAll()
            }
            onAccepted: panel.applyCustomScale(monBlock.modelData.name, text)

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              visible: scaleInput.text.length === 0
              text: "Scale e.g. 1.2"
              color: Theme.fgDim
              font: scaleInput.font
            }
          }

          Icon {
            id: applyBtn
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 16
            name: "check-check"
            color: Theme.accent

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.applyCustomScale(monBlock.modelData.name, scaleInput.text)
            }
          }
        }
      }
    }
  }
}
