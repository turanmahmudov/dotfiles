import QtQuick

SessionAction {
  iconName: "log-out"
  label: "Log out"
  command: "hyprctl dispatch \"hl.dsp.exit()\""
  confirmMessage: "Do you want to log out of the session?"
}
