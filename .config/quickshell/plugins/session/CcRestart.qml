import QtQuick

SessionAction {
  iconName: "rotate-cw"
  label: "Restart"
  command: "systemctl reboot"
  danger: true
  confirmMessage: "Do you want to restart the system?"
}
