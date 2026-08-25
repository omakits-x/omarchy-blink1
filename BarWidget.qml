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
  property bool effectActive: false
  property real pulseOpacity: 1.0
  property string deviceOutputText: ""
  property string actionOutputText: ""
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
      deviceCheck.running = true
    }
  }

  function deviceArguments() {
    return root.selectedDevice === "all" ? [] : ["--id", root.selectedDevice]
  }

  function cycleDevice() {
    var options = ["all"]
    for (var i = 0; i < root.devices.length; i++) options.push(String(root.devices[i].id))
    var current = options.indexOf(root.selectedDevice)
    var next = options[(current + 1 + options.length) % options.length]
    root.selectedDevice = next
    persist({ device: next })
    root.statusText = next === "all" ? "All blink(1) devices" : "Device " + next + " selected"
  }

  function send(args, description) {
    if (actionProcess.running) return
    root.statusText = description
    root.effectName = description
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
    return true
  }

  function setBrightness(value) {
    var next = Math.max(1, Math.min(255, Math.round(Number(value))))
    root.brightness = next
    persist({ brightness: next })
    send(["--brightness", String(next), "--millis", "120", "--rgb", root.currentColor], "Brightness " + next)
  }

  function turnOff() {
    send(["--off"], "Turning off")
  }

  function randomColor() {
    send(["--random"], "Random color")
  }

  function blink() {
    send(["--millis", "100", "--delay", "180", "--rgb", root.currentColor, "--blink", "3"], "Blinking")
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
    stdout: StdioCollector {
      id: deviceOutput
      waitForEnd: true
      onStreamFinished: root.deviceOutputText = text
    }
    onExited: function(exitCode) {
      var output = String(root.deviceOutputText || deviceOutput.text || "")
      var found = []
      var lines = output.split("\\n")
      for (var i = 0; i < lines.length; i++) {
        var match = lines[i].match(/\\bid\\s*:\\s*(\\d+)/i)
        if (match) found.push({ id: match[1], label: lines[i].trim() })
      }
      root.devices = found
      root.deviceAvailable = exitCode === 0 && found.length > 0
      var validSelection = root.selectedDevice === "all"
      for (var j = 0; j < found.length; j++) if (String(found[j].id) === root.selectedDevice) validSelection = true
      if (!validSelection) {
        root.selectedDevice = "all"
        root.persist({ device: "all" })
      }
      if (root.deviceAvailable) root.statusText = "blink(1) ready"
      else root.statusText = "No blink(1) detected — install blink1-tool-bin"
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
    onExited: function(exitCode) {
      root.lastOutput = String(root.actionOutputText || actionOutput.text || "").trim()
      if (exitCode === 0) {
        root.deviceAvailable = true
        root.statusText = root.lastOutput !== "" ? root.lastOutput : "blink(1) ready"
      } else {
        root.deviceAvailable = false
        root.statusText = "blink1-tool failed (check udev)"
      }
      root.actionCommand = []
      root.refreshDevice()
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refreshDevice()
  }

  Timer {
    id: effectTimer
    interval: 3200
    repeat: false
    onTriggered: {
      root.effectActive = false
      root.effectName = "idle"
      root.pulseOpacity = 1.0
    }
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
      Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(root.effectActive ? "thingm.svg" : "thingm.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.deviceAvailable ? 1.0 : 0.45
      }
      Rectangle {
        width: Math.max(5, Math.round(parent.width * 0.24))
        height: width
        radius: width / 2
        anchors.centerIn: parent
        color: root.currentColor
        opacity: root.deviceAvailable ? 1.0 : 0.45
        scale: pulseScale
        property real pulseScale: 1.0
        SequentialAnimation on pulseScale {
          running: root.effectActive
          loops: Animation.Infinite
          NumberAnimation { to: 0.78; duration: 220; easing.type: Easing.OutCubic }
          NumberAnimation { to: 1.0; duration: 420; easing.type: Easing.InOutCubic }
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
