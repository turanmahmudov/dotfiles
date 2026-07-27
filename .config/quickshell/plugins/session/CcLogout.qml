import QtQuick

SessionAction {
  iconName: "log-out"
  label: "Log out"
  command: "hyprctl dispatch \"hl.dsp.exit()\""
}
