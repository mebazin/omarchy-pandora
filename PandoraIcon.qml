import QtQuick
import QtQuick.Effects
import qs.Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property real markOpacity: 1

  implicitWidth: iconSize
  implicitHeight: iconSize
  width: iconSize
  height: iconSize

  Image {
    id: sourceImage
    anchors.fill: parent
    source: Qt.resolvedUrl("pandora.svg")
    sourceSize.width: Math.round(root.iconSize * Screen.devicePixelRatio)
    sourceSize.height: Math.round(root.iconSize * Screen.devicePixelRatio)
    fillMode: Image.PreserveAspectFit
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: sourceImage
    source: sourceImage
    opacity: root.markOpacity
    colorization: 1.0
    colorizationColor: root.color
  }
}
