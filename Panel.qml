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
  property bool advancedOpen: false
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

  function color(hex) {
    if (hostWidget) hostWidget.applyColor(hex)
  }

  function off() { if (hostWidget) hostWidget.turnOff() }
  function random() { if (hostWidget) hostWidget.randomColor() }
  function blink() { if (hostWidget) hostWidget.blink() }
  function flash() { if (hostWidget) hostWidget.flash() }
  function glimmer() { if (hostWidget) hostWidget.glimmer() }
  function chase(value) { if (hostWidget) hostWidget.chase(value) }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(text) {
        if (text === "r" || text === "R") root.color("#FF3B30")
        else if (text === "g" || text === "G") root.color("#34C759")
        else if (text === "b" || text === "B") root.color("#0A84FF")
        else if (text === "w" || text === "W") root.color("#FFFFFF")
        else if (text === "o" || text === "O") root.off()
        else if (text === "n" || text === "N") root.random()
        else if (text === "x" || text === "X") root.blink()
      }

      Flickable {
        anchors.fill: parent
        contentWidth: contentColumn.width
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
        id: contentColumn
          width: parent.width
        spacing: Style.space(14)

        Row {
          spacing: Style.space(12)
          Text {
            text: "●"
            color: hostWidget ? hostWidget.currentColor : contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.display
            anchors.verticalCenter: parent.verticalCenter
          }
          Column {
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
              color: Qt.darker(root.contentForeground, 1.5)
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
              font.letterSpacing: 1
            }
          }
        }

        Text {
          text: "COLORS"
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.2
        }

        Grid {
          columns: 4
          rowSpacing: Style.space(8)
          columnSpacing: Style.space(8)
          Repeater {
            model: [
              { label: "RED", value: "#FF3B30" },
              { label: "GREEN", value: "#34C759" },
              { label: "BLUE", value: "#0A84FF" },
              { label: "WHITE", value: "#FFFFFF" },
              { label: "ORANGE", value: "#FF9500" },
              { label: "PURPLE", value: "#AF52DE" },
              { label: "TEAL", value: "#30D5C8" },
              { label: "PINK", value: "#FF375F" }
            ]
            Button {
              required property var modelData
              text: modelData.label
              foreground: root.contentForeground
              accent: modelData.value
              onClicked: root.color(modelData.value)
            }
          }
        }

        Row {
          spacing: Style.space(8)
          Button { text: "OFF"; foreground: root.contentForeground; onClicked: root.off() }
          Button { text: "RANDOM"; foreground: root.contentForeground; onClicked: root.random() }
          Button { text: "BLINK"; foreground: root.contentForeground; onClicked: root.blink() }
        }

        Row {
          spacing: Style.space(8)
          Button {
            text: hostWidget ? hostWidget.selectedDeviceLabel : "ALL DEVICES"
            foreground: root.contentForeground
            onClicked: if (hostWidget) hostWidget.cycleDevice()
          }
          Text {
            text: hostWidget && hostWidget.devices.length > 0
              ? hostWidget.devices.length + " connected"
              : "No device detected"
            color: Qt.darker(root.contentForeground, 1.5)
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.bodySmall
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Row {
          spacing: Style.space(10)
          Text {
            text: "HEX"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
          TextField {
            id: hexField
            width: Style.space(130)
            text: hostWidget ? hostWidget.currentColor : "#32D583"
            placeholderText: "#RRGGBB"
            validator: RegularExpressionValidator { regularExpression: /^#?[0-9a-fA-F]{6}$/ }
            onAccepted: root.color(text)
          }
        }

        Row {
          spacing: Style.space(12)
        Text {
          text: "BRIGHTNESS"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
          PanelSlider {
            id: brightnessSlider
            width: Style.space(190)
            bar: root.bar
            minimum: 1
            maximum: 255
            integer: true
            value: hostWidget ? hostWidget.brightness : 180
            onReleased: if (hostWidget) hostWidget.setBrightness(value)
          }
        }

        Button {
          width: parent.width
          text: root.advancedOpen ? "HIDE ADVANCED" : "SHOW ADVANCED"
          foreground: root.contentForeground
          onClicked: root.advancedOpen = !root.advancedOpen
        }

        Text {
          text: "COLOR MODES"
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.2
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          TextField { id: hueField; width: Style.space(55); placeholderText: "H"; inputMethodHints: Qt.ImhDigitsOnly }
          TextField { id: saturationField; width: Style.space(55); placeholderText: "S"; inputMethodHints: Qt.ImhDigitsOnly }
          TextField { id: hsbBrightnessField; width: Style.space(55); placeholderText: "B"; inputMethodHints: Qt.ImhDigitsOnly }
          Button {
            text: "APPLY HSB"
            foreground: root.contentForeground
            onClicked: if (hostWidget) hostWidget.runHsb(hueField.text || 0, saturationField.text || 100, hsbBrightnessField.text || 100)
          }
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          Button { text: "FLASH"; foreground: root.contentForeground; onClicked: root.flash() }
          Button { text: "GLIMMER"; foreground: root.contentForeground; onClicked: root.glimmer() }
          Button { text: "CHASE"; foreground: root.contentForeground; onClicked: root.chase("5,1,2") }
          Button { text: "READ RGB"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.readLastColor() }
        }

        Text {
          text: "PATTERNS"
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.2
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          Button { text: "SAVE"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.savePattern() }
          Button { text: "CLEAR"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.clearPattern() }
          Button { text: "PLAY STATE"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.playState() }
          Button { text: "READ"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.readPattern() }
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          TextField { id: patternField; width: Style.space(235); placeholderText: "Pattern string" }
          Button { text: "PLAY"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.playPattern(patternField.text) }
          Button { text: "WRITE"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.writePattern(patternField.text) }
        }

        Text {
          text: "DEVICE / FIRMWARE"
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.2
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          Button { text: "FW VERSION"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.firmwareVersion() }
          Button { text: "TOOL VERSION"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.toolVersion() }
          Button { text: "DEVICE ID"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.deviceId() }
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          Button { text: "STARTUP"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.getStartup() }
          Button { text: "SERVER TICKLE ON"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.serverTickle("1") }
          Button { text: "SERVER TICKLE OFF"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.serverTickle("0") }
        }

        Text {
          text: "ADVANCED ARGUMENTS"
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          font.letterSpacing: 1.2
        }

        Row {
          visible: root.advancedOpen
          height: visible ? implicitHeight : 0
          spacing: Style.space(8)
          TextField { id: advancedField; width: Style.space(270); placeholderText: "e.g. --rgb FF9900 --blink 3" }
          Button { text: "RUN"; foreground: root.contentForeground; onClicked: if (hostWidget) hostWidget.runAdvanced(advancedField.text) }
        }

        Text {
          visible: hostWidget && hostWidget.lastOutput !== ""
          height: visible ? implicitHeight : 0
          text: hostWidget ? hostWidget.lastOutput : ""
          color: root.contentForeground
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.Wrap
          width: parent.width
        }

        Text {
          text: "R/G/B/W · O off · N random · X blink · Esc close"
          color: Qt.darker(root.contentForeground, 1.5)
          font.family: root.contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }
        }
      }
    }
  }
}
