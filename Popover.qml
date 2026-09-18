import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

FocusScope {
  id: card
  required property var service
  signal closeRequested()

  property string email: ""
  property string password: ""
  property bool showStations: false
  readonly property var track: service ? service.track : null
  readonly property var station: service ? service.station : null
  readonly property var stations: service ? service.stations : []
  readonly property bool signedIn: !!(service && service.authenticated)
  readonly property bool playing: !!(service && service.playing)
  readonly property string errorText: {
    if (!service || !service.error) return ""
    if (!signedIn && service.error.indexOf("No stations") !== -1) return ""
    return service.error
  }
  // First-party panels (Wi-Fi, Clockwork) draw their text in the bar's
  // foreground and dim it for secondary labels; follow the same convention.
  property color foreground: Color.foreground
  readonly property color fg: foreground
  readonly property color dim: Qt.alpha(fg, 0.7)
  readonly property color faint: Qt.alpha(fg, 0.55)

  implicitWidth: 308
  implicitHeight: body.implicitHeight
  focus: true
  Keys.priority: Keys.BeforeItem
  Keys.onEscapePressed: closeRequested()
  Keys.onSpacePressed: function(event) {
    if (!card.signedIn || card.showStations) return
    event.accepted = true
    if (service) service.toggle()
  }
  Keys.onPressed: function(event) {
    if (!card.signedIn || card.showStations) return
    if (event.key === Qt.Key_J) {
      event.accepted = true
      if (service) service.thumb("up")
    } else if (event.key === Qt.Key_K) {
      event.accepted = true
      if (service) service.thumb("down")
    }
  }

  function submitLogin() {
    if (!service) return
    service.login(email.trim(), password)
    password = ""
  }

  function formatTime(secs) {
    secs = Math.max(0, Math.floor(Number(secs) || 0))
    var m = Math.floor(secs / 60)
    var s = secs % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  ColumnLayout {
    id: body
    width: parent.width
    spacing: Style.spacing.md

    RowLayout {
      Layout.fillWidth: true
      spacing: 8
      PandoraIcon { iconSize: 16; color: card.fg }
      Text {
        text: "Pandora"
        textFormat: Text.PlainText
        color: card.fg
        font.family: Style.font.family
        font.pixelSize: 14
        font.bold: true
      }
      Item { Layout.fillWidth: true }
      Text {
        visible: card.errorText !== ""
        text: card.errorText
        textFormat: Text.PlainText
        color: Color.urgent
        font.family: Style.font.family
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.maximumWidth: 180
      }
    }

    ColumnLayout {
      visible: !card.signedIn
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Style.spacing.md

      Text {
        text: "Sign in with your Pandora account. Stations play from the bar after that."
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        color: card.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        Layout.fillWidth: true
      }
      TextField {
        id: emailField
        Layout.fillWidth: true
        foreground: card.fg
        placeholderText: "Email"
        text: card.email
        onTextChanged: card.email = text
        Keys.onReturnPressed: passwordField.forceActiveFocus()
      }
      TextField {
        id: passwordField
        Layout.fillWidth: true
        foreground: card.fg
        placeholderText: "Password"
        password: true
        text: card.password
        onTextChanged: card.password = text
        onAccepted: card.submitLogin()
      }
      Button {
        Layout.fillWidth: true
        foreground: card.fg
        text: service && service.status === "loading" ? "Signing in…" : "Sign in"
        bordered: true
        enabled: card.email.trim().length > 0 && card.password.length > 0
        onClicked: card.submitLogin()
      }
      Item { Layout.fillHeight: true }
    }

    ColumnLayout {
      visible: card.signedIn && !card.showStations
      Layout.fillWidth: true
      spacing: Style.spacing.md

      RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Rectangle {
          width: 96
          height: 96
          radius: Style.cornerRadius
          color: Qt.alpha(card.fg, 0.08)
          clip: true
          Image {
            anchors.fill: parent
            source: card.track && card.track.art ? card.track.art : ""
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
          }
          PandoraIcon {
            anchors.centerIn: parent
            iconSize: 28
            color: Qt.alpha(card.fg, 0.45)
            visible: !(card.track && card.track.art)
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: card.track && card.track.title ? card.track.title : "Nothing playing"
            textFormat: Text.PlainText
            color: card.fg
            font.family: Style.font.family
            font.pixelSize: 15
            font.bold: true
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
          Text {
            text: card.track && card.track.artist ? card.track.artist : ""
            textFormat: Text.PlainText
            color: card.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
          Text {
            text: card.track && card.track.album ? card.track.album : ""
            textFormat: Text.PlainText
            color: card.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 4
        radius: 2
        color: Qt.alpha(card.fg, 0.12)
        visible: !!(card.track && card.track.duration)
        Rectangle {
          height: parent.height
          radius: 2
          color: Color.accent
          width: {
            if (!card.track || !card.track.duration) return 0
            return parent.width * Math.max(0, Math.min(1, card.track.elapsed / card.track.duration))
          }
        }
      }

      Button {
        Layout.fillWidth: true
        foreground: card.fg
        text: station && station.name ? station.name : "Choose a station"
        bordered: true
        onClicked: card.showStations = true
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Button {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.minimumWidth: 0
          text: card.playing ? "Pause" : "Play"
          iconText: card.playing ? "Ⅱ" : "▶"
          foreground: card.fg
          fontFamily: Style.font.family
          bordered: true
          onClicked: if (service) service.toggle()
        }
        Button {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.minimumWidth: 0
          text: "Skip"
          iconText: "»"
          foreground: card.fg
          fontFamily: Style.font.family
          bordered: true
          enabled: !!(card.track || card.station)
          onClicked: if (service) service.skip()
        }
        Button {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.minimumWidth: 0
          text: "Thumb up"
          iconText: "\uf164"
          foreground: card.fg
          fontFamily: Style.font.family
          bordered: true
          selected: !!(card.track && card.track.rating === "up")
          enabled: !!(card.track && card.track.allowFeedback !== false)
          onClicked: if (service) service.thumb("up")
        }
        Button {
          Layout.fillWidth: true
          Layout.preferredWidth: 1
          Layout.minimumWidth: 0
          text: "Thumb down"
          iconText: "\uf165"
          foreground: card.fg
          fontFamily: Style.font.family
          bordered: true
          selected: !!(card.track && card.track.rating === "down")
          enabled: !!(card.track && card.track.allowFeedback !== false)
          onClicked: if (service) service.thumb("down")
        }
      }

      Button {
        Layout.fillWidth: true
        foreground: card.fg
        text: "Tired of this song"
        bordered: true
        enabled: !!card.track
        onClicked: if (service) service.tired()
      }

      Text {
        Layout.fillWidth: true
        Layout.topMargin: Style.space(4)
        text: "Space play/pause   ·   J thumb up   ·   K thumb down"
        textFormat: Text.PlainText
        color: card.faint
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignHCenter
      }
    }

    ColumnLayout {
      visible: card.signedIn && card.showStations
      Layout.fillWidth: true
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        Button {
          text: "Back"
          foreground: card.fg
          bordered: true
          onClicked: card.showStations = false
        }
        Text {
          text: "Stations"
          textFormat: Text.PlainText
          color: card.fg
          font.family: Style.font.family
          font.bold: true
          Layout.fillWidth: true
        }
      }

      ListView {
        id: stationList
        Layout.fillWidth: true
        Layout.preferredHeight: 220
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: card.stations
        spacing: 4
        delegate: Button {
          required property int index
          readonly property var stationItem: card.stations[index]
          width: stationList.width
          text: stationItem && stationItem.name ? stationItem.name : ""
          foreground: card.fg
          bordered: true
          selected: card.station && stationItem && card.station.id === stationItem.id
          leftAlign: true
          onClicked: {
            if (service) service.selectStation(stationItem.id)
            card.showStations = false
          }
        }
      }

      Button {
        Layout.fillWidth: true
        foreground: card.fg
        text: "Sign out"
        bordered: true
        onClicked: {
          if (service) service.logout()
          card.showStations = false
        }
      }
    }
  }
}
