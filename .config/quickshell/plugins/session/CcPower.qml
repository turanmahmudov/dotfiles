import QtQuick

SessionAction {
  iconName: "power"
  label: "Power"
  command: "systemctl poweroff"
  danger: true
  confirmMessage: "Do you want to power off the system?"
}
