import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Display"

  readonly property var scalePresets: [1, 1.25, 1.5, 2]
  readonly property var transforms: [
    { "key": 0, "label": "Normal" },
    { "key": 1, "label": "90°" },
    { "key": 2, "label": "180°" },
    { "key": 3, "label": "270°" }
  ]

  property string scaleEditMon: ""
  property string modeEditMon: ""
  property string advancedMon: ""

  Component.onCompleted: {
    Monitors.refresh()
    Monitors.detectDdc()
  }

  function buildModeOptions(monitor) {
    var out = []
    var seen = ({})
    var modes = monitor.availableModes || []
    for (var i = 0; i < modes.length; i++) {
      var parsed = MonitorLayout.parseMode(modes[i])
      if (!parsed)
        continue
      var value = parsed.width + "x" + parsed.height + "@" + parsed.refresh.toFixed(2)
      if (seen[value])
        continue
      seen[value] = true
      out.push({
        "value": value,
        "label": parsed.width + " × " + parsed.height + "   " + parsed.refresh.toFixed(2) + " Hz"
      })
    }
    if (out.length === 0)
      out.push({ "value": MonitorLayout.formatMode(monitor), "label": "Current mode" })
    return out
  }

  function formatScaleLabel(s) {
    return (s % 1 === 0 ? s.toFixed(0) : (Math.round(s * 100) / 100)) + "x"
  }

  function formatScaleNumber(s) {
    return (Math.round(s * 10000) / 10000).toString()
  }

  function isPresetScale(s) {
    for (var i = 0; i < scalePresets.length; i++)
      if (Math.abs(s - scalePresets[i]) < 0.01)
        return true
    return false
  }

  // The live scale carries floating point noise, so the pill row is told which
  // preset it matches rather than compared against the raw value.
  function resolveScaleKey(s) {
    for (var i = 0; i < scalePresets.length; i++)
      if (Math.abs(s - scalePresets[i]) < 0.01)
        return scalePresets[i]
    return "custom"
  }

  function buildScaleEntries(monitor) {
    var out = []
    for (var i = 0; i < scalePresets.length; i++)
      out.push({ "key": scalePresets[i], "label": panel.formatScaleLabel(scalePresets[i]) })
    out.push({
      "key": "custom",
      "label": panel.isPresetScale(monitor.scale) ? "Custom" : panel.formatScaleLabel(monitor.scale)
    })
    return out
  }

  function applyCustomScale(name, text) {
    var v = parseFloat(text)
    if (isNaN(v) || v <= 0)
      return
    MonitorLayout.setScale(name, v)
    scaleEditMon = ""
  }

  function toggleAdvanced(name) {
    panel.advancedMon = panel.advancedMon === name ? "" : name
    panel.modeEditMon = ""
  }

  PillRow {
    visible: DisplayModes.modes.length > 1
    entries: DisplayModes.modes
    current: DisplayModes.current
    onPicked: (key) => DisplayModes.applyMode(key)
  }

  Rectangle {
    width: parent.width
    height: Style.rowHeight
    radius: Style.radiusSmall
    color: Theme.alpha(Theme.fg, nlArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
    border.width: 1
    border.color: NightLight.enabled
      ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
      : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

    Behavior on color {
      ColorAnimation {
        duration: Style.animFast
      }
    }

    Icon {
      id: nlIcon
      anchors.left: parent.left
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      name: NightLight.enabled ? "moon" : "sun"
      color: NightLight.enabled ? Theme.accent : Theme.fg
      size: Style.iconSmall
    }

    Text {
      anchors.left: nlIcon.right
      anchors.leftMargin: Style.space
      anchors.right: nlValue.left
      anchors.rightMargin: Style.space
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: "Night Light"
      color: NightLight.enabled ? Theme.accent : Theme.fg
      font.family: Style.fontFamily
      font.pixelSize: Style.fontBody
    }

    Text {
      id: nlValue
      anchors.right: nlSwitch.left
      anchors.rightMargin: Style.space
      anchors.verticalCenter: parent.verticalCenter
      text: NightLight.temperature + "K"
      color: Theme.fgDim
      font.family: Style.fontFamily
      font.pixelSize: Style.fontCaption
      opacity: NightLight.enabled ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animFast
        }
      }
    }

    Switch {
      id: nlSwitch
      anchors.right: parent.right
      anchors.rightMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      checked: NightLight.enabled
      onToggled: NightLight.toggle()
    }

    MouseArea {
      id: nlArea
      anchors.fill: parent
      anchors.rightMargin: 46
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: NightLight.toggle()
    }
  }

  Reveal {
    open: NightLight.enabled

    Item {
      width: parent.width
      height: 24

      Icon {
        id: nlWarm
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        name: "sun"
        color: Theme.warning
        size: Style.iconSmall
      }

      Slider {
        anchors.left: nlWarm.right
        anchors.right: parent.right
        anchors.leftMargin: Style.space
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        stepSize: 100 / (NightLight.maxTemp - NightLight.minTemp)
        value: (NightLight.temperature - NightLight.minTemp) / (NightLight.maxTemp - NightLight.minTemp)
        onMoved: (v) => NightLight.setTemperature(NightLight.minTemp + v * (NightLight.maxTemp - NightLight.minTemp))
      }
    }
  }

  Column {
    width: parent.width
    spacing: Style.space

    Repeater {
      model: Monitors.list

      delegate: Rectangle {
        id: monBlock
        required property var modelData
        readonly property bool advancedOpen: panel.advancedMon === modelData.name

        width: parent.width
        implicitHeight: monContent.implicitHeight + 20
        height: implicitHeight
        radius: Style.radiusSmall
        color: Theme.alpha(Theme.fg, Style.cardAlpha)
        border.width: 1
        border.color: monBlock.advancedOpen
          ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
          : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

        Behavior on border.color {
          ColorAnimation {
            duration: Style.animFast
          }
        }

        Column {
          id: monContent
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 10
          spacing: Style.space

          Item {
            width: parent.width
            height: nameCol.implicitHeight

            Icon {
              id: monIcon
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              name: monBlock.modelData.internal ? "laptop-minimal" : "monitor"
              color: monBlock.modelData.disabled
                ? Theme.fgDim
                : (monBlock.modelData.focused ? Theme.accentActive : Theme.fg)
              size: Style.iconMedium
            }

            Column {
              id: nameCol
              anchors.left: monIcon.right
              anchors.leftMargin: 10
              anchors.right: toggle.left
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.spaceHair

              Text {
                text: monBlock.modelData.name
                color: monBlock.modelData.focused ? Theme.accentActive : Theme.fg
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
              }

              Text {
                width: parent.width
                elide: Text.ElideRight
                text: {
                  var m = monBlock.modelData
                  if (m.disabled)
                    return (m.internal ? "Internal display" : (m.description || "External display")) + "  ·  off"
                  return m.width + "×" + m.height + "  ·  " + m.refreshRate + "Hz  ·  "
                    + panel.formatScaleLabel(m.scale)
                }
                color: Theme.fgDim
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
              }
            }

            Switch {
              id: toggle
              anchors.right: advancedButton.left
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              checked: !monBlock.modelData.disabled
              onToggled: MonitorLayout.setEnabled(monBlock.modelData.name, !checked)
            }

            Item {
              id: advancedButton
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: 24
              height: 24
              visible: !monBlock.modelData.disabled

              Icon {
                anchors.centerIn: parent
                size: Style.iconTiny
                name: "chevron-right"
                color: (advancedArea.containsMouse || monBlock.advancedOpen) ? Theme.accent : Theme.fgDim
                rotation: monBlock.advancedOpen ? 90 : 0

                Behavior on rotation {
                  NumberAnimation {
                    duration: Style.anim
                    easing.type: Easing.OutCubic
                  }
                }
              }

              MouseArea {
                id: advancedArea
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.toggleAdvanced(monBlock.modelData.name)
              }
            }
          }

          Item {
            id: monBright
            width: parent.width
            height: 24
            readonly property bool ddc: !monBlock.modelData.internal && Monitors.hasDdc(monBlock.modelData.name)
            visible: !monBlock.modelData.disabled
              && ((monBlock.modelData.internal && Brightness.available) || ddc)
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
              size: Style.iconSmall
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
              font.pixelSize: Style.fontCaption
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



          Reveal {
            open: monBlock.advancedOpen && !monBlock.modelData.disabled
            bodySpacing: 6

            Rectangle {
              width: parent.width
              height: 1
              color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)
            }

            PillRow {
              width: parent.width
              rowHeight: 28
              entries: panel.buildScaleEntries(monBlock.modelData)
              current: panel.resolveScaleKey(monBlock.modelData.scale)
              onPicked: (key) => {
                if (key === "custom")
                  panel.scaleEditMon = panel.scaleEditMon === monBlock.modelData.name
                    ? "" : monBlock.modelData.name
                else
                  MonitorLayout.setScale(monBlock.modelData.name, key)
              }
          }

            Reveal {
              open: !monBlock.modelData.disabled && panel.scaleEditMon === monBlock.modelData.name

              Rectangle {
                width: parent.width
                height: 32
                radius: Style.radiusSmall
                color: Theme.alpha(Theme.fg, Style.cardAlpha)
                border.width: 1
                border.color: Theme.alpha(Theme.fg, Style.cardBorderAlpha)

                TextInput {
                  id: scaleInput
                  anchors.left: parent.left
                  anchors.right: applyBtn.left
                  anchors.leftMargin: 10
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  color: Theme.fg
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontBody
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
                    text = panel.formatScaleNumber(monBlock.modelData.scale)
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
                  size: Style.iconSmall
                  name: "check-check"
                  color: Theme.accent

                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.applyCustomScale(monBlock.modelData.name, scaleInput.text)
                  }
                }
              }
          }

            Rectangle {
              readonly property bool editing: panel.modeEditMon === monBlock.modelData.name
              width: parent.width
              height: Style.rowHeight
              radius: Style.radiusSmall
              color: editing
                ? Theme.alpha(Theme.accent, Style.cardActiveAlpha)
                : Theme.alpha(Theme.fg, modeArea.containsMouse ? Style.cardHoverAlpha : Style.cardAlpha)
              border.width: 1
              border.color: editing
                ? Theme.alpha(Theme.accent, Style.cardActiveBorderAlpha)
                : Theme.alpha(Theme.fg, Style.cardBorderAlpha)

              Behavior on color {
                ColorAnimation {
                  duration: Style.animFast
                }
              }

              Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Resolution"
                color: Theme.fg
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
              }

              Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: monBlock.modelData.width + " × " + monBlock.modelData.height
                  + "   " + monBlock.modelData.refreshRate + " Hz"
                color: Theme.fgDim
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
              }

              MouseArea {
                id: modeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.modeEditMon = panel.modeEditMon === monBlock.modelData.name
                  ? "" : monBlock.modelData.name
              }
            }

            ListView {
              readonly property var options: panel.buildModeOptions(monBlock.modelData)
              readonly property bool showing: panel.modeEditMon === monBlock.modelData.name
              width: parent.width
              height: showing ? Math.min(132, contentHeight) : 0
              visible: height > 0.5
              opacity: showing ? 1 : 0
              clip: true
              spacing: Style.spaceHair
              boundsBehavior: Flickable.StopAtBounds
              model: options

              Behavior on opacity {
                NumberAnimation {
                  duration: Style.animFast
                }
              }

              delegate: Rectangle {
                id: modeRow
                required property var modelData
                readonly property bool active: modelData.value === MonitorLayout.formatMode(monBlock.modelData)

                width: ListView.view.width
                height: 26
                radius: Style.radiusSmall
                color: modeRowArea.containsMouse
                  ? Theme.alpha(Theme.accent, Style.cardActiveHoverAlpha)
                  : (active ? Theme.alpha(Theme.fg, Style.cardHoverAlpha) : "transparent")

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: modeRow.modelData.label
                  color: modeRow.active ? Theme.accent : Theme.fg
                  font.family: Style.fontFamily
                  font.pixelSize: Style.fontCaption
                }

                MouseArea {
                  id: modeRowArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    MonitorLayout.setMode(monBlock.modelData.name, modeRow.modelData.value)
                    panel.modeEditMon = ""
                  }
                }
              }
            }

            PillRow {
              width: parent.width
              rowHeight: 28
              entries: panel.transforms
              current: monBlock.modelData.transform || 0
              onPicked: (key) => MonitorLayout.setTransform(monBlock.modelData.name, key)
            }
          }
        }
      }
    }
  }

  CollapsibleSection {
    title: "Advanced"
    visible: Monitors.activeCount > 1
    bodySpacing: 12

    MonitorCanvas {
      width: parent.width
    }
  }
}
