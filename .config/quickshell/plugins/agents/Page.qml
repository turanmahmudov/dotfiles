import QtQuick
import qs.Commons
import qs.Ui

PanelPage {
  id: panel
  title: "Agents"

  readonly property var stateLabel: ({
    "blocked": "waiting",
    "working": "working",
    "done": "done"
  })

  readonly property var agentIcon: ({
    "claude": "agent-claude",
    "opencode": "agent-opencode"
  })

  Placeholder {
    visible: Agents.list.length === 0
    text: "No agents"
  }

  Column {
    width: parent.width
    spacing: Style.spaceTight

    Repeater {
      model: Agents.list

      delegate: ListRow {
        required property var modelData

        iconName: panel.agentIcon[modelData.agent] || "bot"
        label: modelData.agent + "  ·  " + modelData.title
        sublabel: modelData.place === "-" ? "" : modelData.place
        value: Agents.isSilent(modelData)
          ? "no report " + Agents.ago(modelData.since)
          : (panel.stateLabel[modelData.state] || modelData.state) + " " + Agents.ago(modelData.since)
        active: modelData.state === "blocked"

        onClicked: {
          Agents.focus(modelData.key)
          panel.requestClose()
        }
      }
    }
  }
}
