import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.omakitsx.blink1"
  ipcTarget: ""
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property string page: "control"
  property int patternRepeats: 0
  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { root.opened ? root.close() : root.open() }
  function closeForPopoutSwitch() {
    root.popoutSwitchClosing = true
    root.close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  function color(value) { if (hostWidget) hostWidget.applyColor(value) }
  function off() { if (hostWidget) hostWidget.turnOff() }
  function random() { if (hostWidget) hostWidget.randomColor() }
  function blink() { if (hostWidget) hostWidget.blink() }
  function mode(value) {
    if (!hostWidget) return
    if (value === "cycle") hostWidget.colorCycle()
    else if (value === "mood") hostWidget.moodLight()
    else if (value === "strobe") hostWidget.strobe()
    else if (value === "white") hostWidget.applyColor("#FFFFFF")
    else if (value === "off") hostWidget.turnOff()
  }
  function pattern(value) { if (hostWidget) hostWidget.playPattern(value) }
  function playOfficialPattern(value) {
    var parts = String(value).split(",")
    if (parts.length < 3) return
    parts[0] = String(Math.max(0, root.patternRepeats))
    root.pattern(parts.join(","))
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(pageLoader.item ? pageLoader.item.implicitHeight + Style.space(54) : Style.space(200))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(text) {
        if (text === "1") root.page = "control"
        else if (text === "2") root.page = "colors"
        else if (text === "3") root.page = "patterns"
        else if (text === "4") root.page = "advanced"
        else if (text === "r") root.color("#FF3B30")
        else if (text === "g") root.color("#34C759")
        else if (text === "b") root.color("#0A84FF")
        else if (text === "o") root.off()
        else if (text === "n") root.random()
        else if (text === "x") root.blink()
      }

      Column {
        anchors.fill: parent
        spacing: Style.space(12)

        Row {
          id: navigation
          width: parent.width
          spacing: Style.space(6)
          Repeater {
            model: [
              { label: "CONTROL", value: "control" },
              { label: "COLORS", value: "colors" },
              { label: "PATTERNS", value: "patterns" },
              { label: "ADVANCED", value: "advanced" }
            ]
            Button {
              required property var modelData
              text: modelData.label
              foreground: root.contentForeground
              bordered: true
              selected: root.page === modelData.value
              onClicked: root.page = modelData.value
            }
          }
        }

        Flickable {
          id: pageScroll
          width: parent.width
          height: parent.height - navigation.height - Style.space(12)
          contentWidth: width
          contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : 0
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          interactive: contentHeight > height

          Loader {
            id: pageLoader
            width: pageScroll.width
            sourceComponent: root.page === "control"
              ? controlPage
              : (root.page === "colors" ? colorsPage
                : (root.page === "patterns" ? patternsPage : advancedPage))
          }
        }
      }
    }
  }

  Component {
    id: controlPage
    Column {
      width: pageLoader.width
      spacing: Style.space(14)

      Column {
        id: implicitColumn
        width: parent.width
        spacing: Style.space(8)

        Row {
          spacing: Style.space(12)
          BorderSurface {
            width: Style.space(42)
            height: width
            radius: Style.cornerRadius
            color: hostWidget ? hostWidget.currentColor : Color.accent
            borderSpec: Border.flat(root.contentForeground, Math.max(1, Style.space(1)))
            Rectangle {
              width: Style.space(12)
              height: width
              radius: width / 2
              color: root.contentForeground
              anchors.centerIn: parent
            }
          }
          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)
            Text {
              text: "blink(1)"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Text {
              text: hostWidget ? hostWidget.statusText : "Ready"
              color: hostWidget && !hostWidget.deviceAvailable ? Color.urgent : Qt.darker(root.contentForeground, 1.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        Row {
          spacing: Style.space(6)
          Button {
            text: "ALL DEVICES"
            foreground: root.contentForeground
            bordered: true
            selected: hostWidget && hostWidget.selectedDevice === "all"
            onClicked: if (hostWidget) hostWidget.selectDevice("all")
          }
          Repeater {
            model: hostWidget ? hostWidget.devices : []
            Button {
              required property var modelData
              text: "DEVICE " + modelData.id + (modelData.serial ? " · " + String(modelData.serial).slice(-4) : "")
              foreground: root.contentForeground
              bordered: true
              selected: hostWidget && hostWidget.selectedDevice === String(modelData.id)
              tooltipText: modelData.serial ? "Serial " + modelData.serial : "Device " + modelData.id
              onClicked: if (hostWidget) hostWidget.selectDevice(modelData.id)
            }
          }
        }

        Text {
          text: hostWidget && hostWidget.devices.length > 0
            ? hostWidget.devices.length + " connected"
            : "No device detected"
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }

        PanelSectionHeader {
          text: "MODES"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Grid {
          columns: 5
          rowSpacing: Style.space(6)
          columnSpacing: Style.space(6)
          Repeater {
            model: [
              { label: "COLOR CYCLE", mode: "cycle" },
              { label: "MOOD LIGHT", mode: "mood" },
              { label: "STROBE LIGHT", mode: "strobe" },
              { label: "WHITE", mode: "white" },
              { label: "OFF", mode: "off" }
            ]
            Button {
              required property var modelData
              text: modelData.label
              foreground: root.contentForeground
              bordered: true
              selected: hostWidget && hostWidget.effectMode === modelData.mode
              onClicked: root.mode(modelData.mode)
            }
          }
        }

        Row {
          spacing: Style.space(8)
          Button {
            text: "RANDOM"
            foreground: root.contentForeground
            bordered: true
            selected: hostWidget && hostWidget.effectMode === "random"
            onClicked: root.random()
          }
          Button {
            text: "BLINK"
            foreground: root.contentForeground
            bordered: true
            selected: hostWidget && hostWidget.effectMode === "blink"
            onClicked: root.blink()
          }
        }

        Row {
          spacing: Style.space(10)
          Text {
            text: "BRIGHTNESS"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
          PanelSlider {
            width: Math.max(Style.space(160), parent.width - Style.space(110))
            bar: root.bar
            minimum: 1
            maximum: 255
            integer: true
            value: hostWidget ? hostWidget.brightness : 180
            onReleased: if (hostWidget) hostWidget.setBrightness(value)
          }
        }
      }
    }
  }

  Component {
    id: colorsPage
    Column {
      width: pageLoader.width
      spacing: Style.space(14)
      Column {
        id: colorColumn
        width: parent.width
        spacing: Style.space(12)
        PanelSectionHeader {
          text: "PRESETS"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Grid {
          columns: 4
          rowSpacing: Style.space(6)
          columnSpacing: Style.space(6)
          Repeater {
            model: [
              { label: "RED", value: "#FF3B30" }, { label: "GREEN", value: "#34C759" },
              { label: "BLUE", value: "#0A84FF" }, { label: "WHITE", value: "#FFFFFF" },
              { label: "ORANGE", value: "#FF9500" }, { label: "PURPLE", value: "#AF52DE" },
              { label: "TEAL", value: "#30D5C8" }, { label: "PINK", value: "#FF375F" }
            ]
            Button {
              required property var modelData
              iconText: "●"
              text: modelData.label
              foreground: modelData.value
              accent: modelData.value
              selected: hostWidget && String(hostWidget.currentColor).toUpperCase() === modelData.value
              onClicked: root.color(modelData.value)
            }
          }
        }
        PanelSectionHeader {
          text: "COLOR PICKER"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Grid {
          columns: 12
          rowSpacing: Style.space(4)
          columnSpacing: Style.space(4)
          Repeater {
            model: ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#30D5C8", "#0A84FF", "#5856D6", "#AF52DE", "#FF2D55", "#FFFFFF", "#A0A0A0", "#000000", "#8B1E1E", "#9A5700", "#8A7200", "#176B32", "#167A73", "#07539E", "#34328A", "#713594", "#9E1C3E", "#D8D8D8", "#555555", "#171717"]
            Button {
              required property string modelData
              width: Style.space(24)
              height: width
              background: modelData
              foreground: "#FFFFFF"
              accent: modelData
              bordered: true
              selected: hostWidget && String(hostWidget.currentColor).toUpperCase() === modelData
              tooltipText: modelData
              onClicked: root.color(modelData)
            }
          }
        }
        Row {
          spacing: Style.space(8)
          Text {
            text: "HEX"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
          TextField {
            id: hexField
            width: Style.space(145)
            text: hostWidget ? hostWidget.currentColor : "#32D583"
            placeholderText: "#RRGGBB"
            validator: RegularExpressionValidator { regularExpression: /^#?[0-9a-fA-F]{6}$/ }
            onAccepted: root.color(text)
          }
        }
        Row {
          spacing: Style.space(6)
          TextField {
            id: hueField
            width: Style.space(58)
            placeholderText: "H"
            inputMethodHints: Qt.ImhDigitsOnly
          }
          TextField {
            id: saturationField
            width: Style.space(58)
            placeholderText: "S"
            inputMethodHints: Qt.ImhDigitsOnly
          }
          TextField {
            id: hsbField
            width: Style.space(58)
            placeholderText: "B"
            inputMethodHints: Qt.ImhDigitsOnly
          }
          Button {
            text: "APPLY HSB"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.runHsb(hueField.text || 0, saturationField.text || 100, hsbField.text || 100)
          }
        }
      }
    }
  }

  Component {
    id: patternsPage
    Column {
      width: pageLoader.width
      spacing: Style.space(12)
      Column {
        id: patternColumn
        width: parent.width
        spacing: Style.space(8)
        PanelSectionHeader {
          text: "OFFICIAL PATTERNS"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Row {
          spacing: Style.space(8)
          Text {
            text: "REPEATS"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
          TextField {
            id: repeatsField
            width: Style.space(70)
            text: "0"
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 9999 }
            onTextChanged: root.patternRepeats = Math.max(0, Number(text || 0))
          }
          Text {
            text: "0 = loop forever"
            color: Qt.darker(root.contentForeground, 1.5)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            anchors.verticalCenter: parent.verticalCenter
          }
        }
        Grid {
          columns: 3
          rowSpacing: Style.space(6)
          columnSpacing: Style.space(6)
          Repeater {
            model: [
              { label: "RED FLASH", value: "3,#ff0000,0.5,0,#000000,0.5," },
              { label: "GREEN FLASH", value: "3,#00ff00,0.5,0,#000000,0.5," },
              { label: "BLUE FLASH", value: "3,#0000ff,0.5,0,#000000,0.5," },
              { label: "WHITE FLASH", value: "3,#ffffff,0.5,0,#000000,0.5," },
              { label: "YELLOW FLASH", value: "3,#ffff00,0.5,0,#000000,0.5," },
              { label: "PURPLE FLASH", value: "3,#ff00ff,0.5,0,#000000,0.5," },
              { label: "GROOVY", value: "3,#ff4cff,1.0,0,#630000,0.2,0,#0000ff,0.1,0" },
              { label: "POLICE CAR", value: "6,#ff0000,0.3,1,#0000ff,0.3,2,#000000,0.1,0,#ff0000,0.3,2,#0000ff,0.3,1,#000000,0.1,0" },
              { label: "FIRE ENGINE", value: "6,#ff0000,0.3,1,#ff0000,0.3,2,#000000,0.1,0,#ff0000,0.3,2,#ff0000,0.3,1,#000000,0.1,0" }
            ]
            Button {
              required property var modelData
              text: modelData.label
              foreground: root.contentForeground
              bordered: true
              onClicked: root.playOfficialPattern(modelData.value)
            }
          }
        }
        PanelSectionHeader {
          text: "CUSTOM PATTERN"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Text {
          text: "Pattern format: repeats,#RRGGBB,time,led,..."
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.space(6)
          TextField {
            id: patternField
            width: Style.space(300)
            placeholderText: "0,#ff0000,0.5,0,#0000ff,0.5,0"
          }
          Button {
            text: "PLAY"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.playPattern(patternField.text)
          }
          Button {
            text: "WRITE"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.writePattern(patternField.text)
          }
        }
      }
    }
  }

  Component {
    id: advancedPage
    Column {
      width: pageLoader.width
      spacing: Style.space(12)
      Column {
        id: advancedColumn
        width: parent.width
        spacing: Style.space(8)
        PanelSectionHeader {
          text: "DEVICE / FIRMWARE"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Row {
          spacing: Style.space(6)
          Button {
            text: "FW VERSION"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.firmwareVersion()
          }
          Button {
            text: "TOOL VERSION"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.toolVersion()
          }
          Button {
            text: "DEVICE ID"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.deviceId()
          }
        }
        Row {
          spacing: Style.space(6)
          Button {
            text: "STARTUP"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.getStartup()
          }
          Button {
            text: "TICKLE ON"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.serverTickle("1")
          }
          Button {
            text: "TICKLE OFF"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.serverTickle("0")
          }
        }
        PanelSectionHeader {
          text: "RAW ARGUMENTS"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
        }
        Text {
          text: "Runs any blink1-tool option without a shell."
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.space(6)
          TextField {
            id: advancedField
            width: Style.space(320)
            placeholderText: "--rgb FF9900 --blink 3"
          }
          Button {
            text: "RUN"
            foreground: root.contentForeground
            bordered: true
            onClicked: if (hostWidget) hostWidget.runAdvanced(advancedField.text)
          }
        }
        Text {
          visible: hostWidget && hostWidget.lastOutput !== ""
          text: hostWidget ? hostWidget.lastOutput : ""
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.Wrap
          width: parent.width
        }
      }
    }
  }
}
