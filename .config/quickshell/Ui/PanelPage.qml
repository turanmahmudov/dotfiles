import QtQuick
import qs.Commons

// Content of one panel page. The host owns the window, the header and the
// width; a page only declares its title and its body.
Item {
  id: page

  property var controller: null
  property Item anchorItem: null
  property var payload: ({})
  property string pluginId: ""

  property string title: ""

  // Optional toggle rendered in the host header, for pages that are a feature
  // you can turn off as a whole.
  property bool hasSwitch: false
  property bool switchOn: false
  signal switchToggled()

  default property alias content: col.data

  implicitHeight: col.implicitHeight

  function requestClose() {
    if (controller)
      controller.close()
  }

  function goToPage(id) {
    if (controller)
      controller.go(id)
  }

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: Style.panelSpacing
  }
}
