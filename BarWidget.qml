import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "alturatechnology.pandora"

  property bool opened: false
  property bool popoutSwitchClosing: false

  readonly property var sharedService: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property var service: sharedService || localService
  readonly property bool playing: !!(service && service.playing)
  // Not "needs login" while the engine is still signing in on startup.
  readonly property bool needsLogin: !!(service && (service.status === "needs_login"
    || (!service.authenticated && service.status !== "loading")))
  readonly property string tooltip: {
    if (!service) return "Pandora"
    if (service.track && service.track.title)
      return service.track.title + (service.track.artist ? " — " + service.track.artist : "")
    if (service.station && service.station.name) return service.station.name
    if (needsLogin) return "Pandora — sign in"
    return "Pandora"
  }

  function open() {
    popoutSwitchClosing = false
    opened = true
  }

  function close() {
    opened = false
  }

  function toggle() {
    if (opened) close()
    else open()
  }

  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Service {
    id: localService
    visible: false
    active: sharedService === null
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: root.tooltip
    useActiveColor: false
    active: root.opened
    iconComponent: Component {
      Item {
        PandoraIcon {
          anchors.centerIn: parent
          color: button.foreground
          markOpacity: root.playing ? 1 : 0.7
        }
        Rectangle {
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          width: 5
          height: 5
          radius: 3
          color: root.playing ? Color.accent : (root.needsLogin ? Color.urgent : "transparent")
          visible: root.playing || root.needsLogin
        }
      }
    }
    onPressed: function(b) {
      if (b === Qt.LeftButton) root.toggle()
      else if (b === Qt.MiddleButton && root.service) root.service.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.opened
    padding: 12
    borderSpec: Border.flat(Color.accent, 2)
    contentWidth: 336
    contentHeight: popup.fittedContentHeight(content.item ? content.item.implicitHeight : 280)
    // Recreate popover content when the card opens.
    focusTarget: content.item
    Loader {
      id: content
      anchors.fill: parent
      active: root.opened
      sourceComponent: Popover {
        service: root.service
        foreground: root.bar ? root.bar.foreground : Color.foreground
        onCloseRequested: root.close()
      }
    }
  }

  IpcHandler {
    target: "alturatechnology.pandora"
    function toggle(): void { root.toggle() }
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function play(): void { if (root.service) root.service.play() }
    function pause(): void { if (root.service) root.service.pause() }
    function skip(): void { if (root.service) root.service.skip() }
    function thumbUp(): void { if (root.service) root.service.thumb("up") }
    function thumbDown(): void { if (root.service) root.service.thumb("down") }
  }
}
