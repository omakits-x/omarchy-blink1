import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.omakitsx.blink1"

  property color currentColor: setting("color", "#32d583")
  property int brightness: Number(setting("brightness", 180))
  property string selectedDevice: String(setting("device", "all"))
  property var devices: []
  property bool deviceAvailable: false
  property string statusText: "Checking blink(1)…"
  property string lastOutput: ""
  property string effectName: "idle"
  property string effectMode: "idle"
  property bool randomMode: false
  property int cycleStep: 0
  property bool strobeOn: false
  property bool effectActive: false
  property real pulseOpacity: 1.0
  property string deviceOutputText: ""
  property string actionOutputText: ""
  property var pendingDevices: []
  property var actionCommand: []

  readonly property bool panelOpen: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property string selectedDeviceLabel: selectedDevice === "all"
    ? "ALL DEVICES"
    : "DEVICE " + selectedDevice

  function normalizedHex(value) {
    var candidate = String(value || "").trim()
    if (candidate.charAt(0) !== "#") candidate = "#" + candidate
    return /^#[0-9a-fA-F]{6}$/.test(candidate) ? candidate.toUpperCase() : ""
  }

  function persist(values) {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]
    for (var next in values) entry[next] = values[next]
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function refreshDevice() {
    if (!deviceCheck.running) {
      root.deviceOutputText = ""
      root.pendingDevices = []
      deviceCheck.running = true
    }
  }

  function parseDeviceLine(line) {
    var match = String(line || "").match(/\bid\s*:\s*(\d+)/i)
    if (!match) return
    var id = String(match[1])
    var next = root.pendingDevices.slice()
    for (var i = 0; i < next.length; i++) if (String(next[i].id) === id) return
    next.push({ id: id, label: String(line).trim() })
    root.pendingDevices = next
  }

  function deviceArguments() {
    return root.selectedDevice === "all" ? [] : ["--id", root.selectedDevice]
  }

  function cycleDevice() {
    var options = ["all"]
    for (var i = 0; i < root.devices.length; i++) options.push(String(root.devices[i].id))
    var current = options.indexOf(root.selectedDevice)
    root.selectDevice(options[(current + 1 + options.length) % options.length])
  }

  function selectDevice(value) {
    var next = String(value || "all")
    root.selectedDevice = next
    persist({ device: next })
    root.statusText = next === "all" ? "All blink(1) devices" : "Device " + next + " selected"
  }

  function send(args, description, mode) {
    if (actionProcess.running) return
    root.randomMode = mode === "random"
    root.statusText = description
    root.effectName = description
    root.effectMode = mode || "effect"
    root.effectActive = true
    effectTimer.restart()
    root.actionCommand = ["blink1-tool"].concat(root.deviceArguments()).concat(args)
    actionProcess.running = true
  }

  function applyColor(value) {
    var hex = normalizedHex(value)
    if (!hex) return false
    root.currentColor = hex
    persist({ color: hex })
    send(["--brightness", String(root.brightness), "--millis", "180", "--rgb", hex], "Setting " + hex)
    root.effectMode = "color"
    return true
  }

  function setBrightness(value) {
    var next = Math.max(1, Math.min(255, Math.round(Number(value))))
    root.brightness = next
    persist({ brightness: next })
    send(["--brightness", String(next), "--millis", "120", "--rgb", root.currentColor], "Brightness " + next)
    root.effectMode = "color"
  }

  function turnOff() {
    send(["--off"], "Turning off", "off")
  }

  function randomColor() {
    send(["--random"], "Random color", "random")
  }

  function blink() {
    send(["--millis", "100", "--delay", "180", "--rgb", root.currentColor, "--blink", "3"], "Blinking", "blink")
  }

  function colorCycle() {
    root.cycleStep = 0
    send(["--millis", "180", "--rgb", String(Qt.hsla(0, 1, 0.5, 1))], "Color cycle", "cycle")
  }

  function moodLight() {
    send(["--random"], "Mood light", "mood")
  }

  function strobe() {
    root.strobeOn = true
    send(["--millis", "10", "--white"], "Strobe light", "strobe")
  }

  function runSpecialStep() {
    if (root.effectMode === "cycle") {
      root.cycleStep = (root.cycleStep + 15) % 360
      send(["--millis", "180", "--rgb", String(Qt.hsla(root.cycleStep / 360, 1, 0.5, 1))], "Color cycle", "cycle")
    } else if (root.effectMode === "strobe") {
      root.strobeOn = !root.strobeOn
      send(["--millis", "10", root.strobeOn ? "--white" : "--off"], "Strobe light", "strobe")
    }
  }

  function runHsb(hue, saturation, value) {
    send(["--hsb", String(hue) + "," + String(saturation) + "," + String(value)], "Setting HSB")
  }

  function readLastColor() { send(["--rgbread"], "Reading last color") }
  function firmwareVersion() { send(["--fwversion"], "Reading firmware") }
  function toolVersion() { send(["--version"], "Reading tool version") }
  function deviceId() { send(["--getid"], "Reading device ID") }
  function getStartup() { send(["--getstartup"], "Reading startup settings") }
  function setStartup(value) { send(["--setstartup", String(value)], "Writing startup settings") }
  function bootloaderEnter() { send(["--gobootload"], "Entering bootloader") }
  function bootloaderLock() { send(["--lockbootload"], "Locking bootloader") }
  function savePattern() { send(["--savepattern"], "Saving pattern") }
  function clearPattern() { send(["--clearpattern"], "Clearing pattern") }
  function playState() { send(["--playstate"], "Reading pattern state") }
  function playPattern(value) { send(["--playpattern", String(value)], "Playing pattern") }
  function writePattern(value) { send(["--writepattern", String(value)], "Writing pattern") }
  function readPattern() { send(["--readpattern"], "Reading pattern") }
  function setPatternLine(position, value) {
    var hex = normalizedHex(value)
    if (!hex) return
    send(["--rgb", hex, "--setpattline", String(position)], "Writing pattern line " + position)
  }
  function getPatternLine(position) { send(["--getpattline", String(position)], "Reading pattern line " + position) }
  function serverTickle(value) { send(["--servertickle", String(value)], "Setting server tickle") }
  function chase(value) { send(["--chase", String(value)], "Running chase") }
  function glimmer() { send(["--rgb", root.currentColor, "--glimmer", "3"], "Glimmering") }
  function flash() { send(["--millis", "100", "--delay", "180", "--rgb", root.currentColor, "--flash", "3"], "Flashing") }
  function runAdvanced(text) {
    var source = String(text || "").trim()
    if (!source || /[\\r\\n;|&`$<>]/.test(source)) return
    var args = source.split(/\\s+/)
    send(args, "Running blink1-tool")
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Process {
    id: deviceCheck
    command: ["blink1-tool", "--list"]
    running: false
    stdout: SplitParser { onRead: function(line) { root.parseDeviceLine(line) } }
    stderr: SplitParser { onRead: function(line) { root.parseDeviceLine(line) } }
    onExited: function(exitCode) {
      root.devices = root.pendingDevices
      root.deviceAvailable = exitCode === 0 && root.devices.length > 0
      var validSelection = root.selectedDevice === "all"
      for (var j = 0; j < root.devices.length; j++) if (String(root.devices[j].id) === root.selectedDevice) validSelection = true
      if (!validSelection) {
        root.selectedDevice = "all"
        root.persist({ device: "all" })
      }
      if (root.deviceAvailable && (root.statusText === "Checking blink(1)…" || root.statusText.indexOf("No blink") === 0))
        root.statusText = "blink(1) ready"
      else if (!root.deviceAvailable) root.statusText = "No blink(1) detected — install blink1-tool-bin"
    }
  }

  Process {
    id: actionProcess
    command: root.actionCommand
    running: false
    stdout: StdioCollector {
      id: actionOutput
      waitForEnd: true
      onStreamFinished: root.actionOutputText = text
    }
    stderr: StdioCollector {
      id: actionError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.lastOutput = String(root.actionOutputText || actionOutput.text || "").trim()
      if (exitCode === 0) {
        root.deviceAvailable = true
        root.statusText = root.lastOutput !== "" ? root.lastOutput : "blink(1) ready"
      } else {
        root.deviceAvailable = false
        root.lastOutput = String(actionError.text || root.lastOutput || "").trim()
        root.statusText = "blink1-tool failed"
      }
      root.actionCommand = []
    }
  }

  Timer {
    id: effectTimer
    interval: 3200
    repeat: false
    onTriggered: {
      if (root.randomMode) {
        root.effectActive = true
        restart()
        return
      }
      root.effectActive = false
      root.effectName = "idle"
      if (root.effectMode !== "off") root.effectMode = "idle"
      root.pulseOpacity = 1.0
    }
  }

  Timer {
    id: randomTimer
    interval: 1200
    repeat: true
    running: root.randomMode
    onTriggered: root.send(["--random"], "Random color", "random")
  }

  Timer {
    id: moodTimer
    interval: 2000
    repeat: true
    running: root.effectMode === "mood"
    onTriggered: root.send(["--random"], "Mood light", "mood")
  }

  Timer {
    id: specialTimer
    interval: 200
    repeat: true
    running: root.effectMode === "cycle" || root.effectMode === "strobe"
    onTriggered: root.runSpecialStep()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        anchors.fill: parent

        Image {
          anchors.fill: parent
          visible: !root.effectActive
          source: Qt.resolvedUrl("thingm.png")
          fillMode: Image.PreserveAspectFit
          smooth: true
          opacity: root.deviceAvailable ? 1.0 : 0.45
        }

        Rectangle {
          id: effectTile
          visible: root.effectActive
          width: Math.max(8, Math.round(parent.width * 0.62))
          height: width
          anchors.centerIn: parent
          radius: width / 2
          color: root.currentColor
          opacity: root.deviceAvailable ? 1.0 : 0.45
          border.width: Math.max(1, Math.round(width * 0.08))
          border.color: Qt.rgba(1, 1, 1, 0.25)
          scale: pulseScale
          property real pulseScale: 1.0

          SequentialAnimation on pulseScale {
            running: root.effectActive
            loops: Animation.Infinite
            NumberAnimation { to: 0.82; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutCubic }
          }
        }
      }
    }
    foreground: root.deviceAvailable ? root.currentColor : (root.bar ? root.bar.barForeground : Color.foreground)
    tooltipText: root.deviceAvailable
      ? "blink(1) · " + root.currentColor + " · " + root.effectName
      : "blink(1) unavailable"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.randomColor()
      else if (b === Qt.MiddleButton) root.turnOff()
      else root.toggle()
    }
  }

  Component.onCompleted: root.refreshDevice()
}
