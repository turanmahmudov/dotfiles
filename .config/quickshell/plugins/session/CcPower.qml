import QtQuick

SessionAction {
  iconName: "power"
  label: "Power"
  command: "systemctl poweroff"
  danger: true
}
