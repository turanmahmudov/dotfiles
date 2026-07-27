import QtQuick

SessionAction {
  iconName: "lock"
  label: "Lock"
  command: "loginctl lock-session $XDG_SESSION_ID"
}
