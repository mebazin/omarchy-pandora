import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property bool active: true
  property var state: ({
    type: "state",
    v: 1,
    authenticated: false,
    email: "",
    status: "offline",
    error: "",
    playing: false,
    paused: false,
    station: null,
    stations: [],
    track: null
  })
  // Kept apart from `state` and only replaced when the list really changes,
  // so views bound to it do not reset on every one-second progress tick.
  property var stations: []
  property string stationsKey: ""
  property string transportError: ""
  readonly property string runtimeDir: {
    var dir = Quickshell.env("XDG_RUNTIME_DIR")
    return dir && dir.length ? dir : "/run/user/1000"
  }
  readonly property string socketPath: runtimeDir + "/alturatechnology.pandora/engine.sock"
  property var socket: null
  readonly property bool connected: !!(socket && socket.connected)
  readonly property bool authenticated: !!(state && state.authenticated)
  readonly property bool playing: !!(state && state.playing)
  readonly property bool paused: !!(state && state.paused)
  readonly property string status: state && state.status ? state.status : "offline"
  readonly property string error: transportError || (state && state.error ? state.error : "")
  readonly property var track: state && state.track ? state.track : null
  readonly property var station: state && state.station ? state.station : null

  // Relaunch budget. Without a cap a broken engine (missing python module,
  // syntax error) would be respawned every tick forever, filling the log.
  readonly property int maxSpawns: 5
  property int spawns: 0
  property int ticksSinceSpawn: 1

  function enginePath() {
    return Qt.resolvedUrl("bin/pandora-engine").toString().replace(/^file:\/\//, "")
  }

  function ensureEngine() {
    if (spawns >= maxSpawns) {
      transportError = "Pandora engine failed to start. See ~/.local/state/alturatechnology.pandora/engine.log"
      return
    }
    spawns++
    ticksSinceSpawn = 0
    Quickshell.execDetached([enginePath()])
  }

  function connectSocket() {
    var previous = socket
    socket = socketFactory.createObject(root)
    if (previous)
      previous.destroy()
  }

  function send(message) {
    if (!root.connected) {
      ensureEngine()
      if (spawns < maxSpawns) transportError = "Starting Pandora…"
      return
    }
    socket.write(JSON.stringify(message) + "\n")
  }

  function login(email, password) { send({ type: "login", email: email, password: password }) }
  function logout() { send({ type: "logout" }) }
  function play() { send({ type: "play" }) }
  function pause() { send({ type: "pause" }) }
  function toggle() { send({ type: "toggle" }) }
  function skip() { send({ type: "skip" }) }
  function thumb(value) { send({ type: "thumb", value: value }) }
  function tired() { send({ type: "tired" }) }
  function selectStation(id) { send({ type: "select_station", id: id }) }
  function refreshStations() { send({ type: "refresh_stations" }) }

  function receive(data) {
    try {
      var message = JSON.parse(data)
      if (message.type === "state") {
        var list = Array.isArray(message.stations) ? message.stations : []
        var key = JSON.stringify(list)
        if (key !== stationsKey) {
          stationsKey = key
          stations = list
        }
        state = message
        transportError = ""
      }
    } catch (e) {
      transportError = "Invalid engine message"
    }
  }

  Component.onCompleted: if (active) connectSocket()
  onActiveChanged: if (active && !socket) connectSocket()

  property Component socketFactory: Component {
    Socket {
      path: root.socketPath
      connected: true
      parser: SplitParser {
        onRead: data => root.receive(data)
      }
      onConnectedChanged: {
        if (connected) {
          root.spawns = 0
          root.transportError = ""
        } else {
          root.transportError = "Pandora engine disconnected. Reconnecting…"
        }
      }
      onError: root.transportError = "Pandora engine unavailable. Reconnecting…"
    }
  }

  // Reconnect every tick while down; launch the engine on every other tick
  // so a socket that is simply slow to come up is not met with a second
  // engine process that exits with "already running".
  Timer {
    interval: 1500
    repeat: true
    running: root.active && !root.connected
    onTriggered: {
      if (root.ticksSinceSpawn >= 1)
        root.ensureEngine()
      else
        root.ticksSinceSpawn++
      root.connectSocket()
    }
  }
}
