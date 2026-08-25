# Omarchy blink(1) Control

An Omarchy `bar-widget` for ThingM blink(1) USB status lights. It uses the
official Omarchy shell plugin contract and invokes `blink1-tool` directly.

## Features

- Bar indicator colored with the last selected RGB value.
- Popup controls for red, green, blue, white, off, random, and blink.
- Additional presets for orange, purple, teal, and pink.
- Custom `#RRGGBB` colors and brightness control.
- Multi-device support: target all connected devices or cycle through each device.
- Every current `blink1-tool` option remains available in the Advanced Arguments
  field, including HSB, pattern memory, server tickle, chase, firmware/startup
  commands, bootloader commands, and notes.
- Right-click the bar indicator for a random color; middle-click turns it off.
- Keyboard shortcuts in the popup: `R/G/B/W`, `O`, `N`, `X`, and `Esc`.

## Install on Arch / Omarchy

Install the AUR package that provides the CLI:

```bash
paru -S blink1-tool-bin
```

Then install and enable this plugin:

```bash
omarchy plugin add https://github.com/omakits-x/omarchy-blink1.git --enable --yes
```

The plugin does not silently invoke `paru` or `pacman`; package installation is
an explicit user action. If `blink1-tool --list` cannot access the device, install the udev rule as
described by the package/upstream, then unplug and reconnect the blink(1).
The upstream Linux rule is available in the [blink1 repository](https://github.com/todbot/blink1/blob/main/linux/51-blink1.rules).

## Development

```bash
PLUGIN_ID="io.github.omakitsx.blink1"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
omarchy plugin validate "$PLUGIN_DIR"
qmllint -I "$OMARCHY_PATH/shell" "$PLUGIN_DIR/BarWidget.qml" "$PLUGIN_DIR/Panel.qml"
omarchy-shell shell rescanPlugins
omarchy plugin list --json
```

The plugin runs inside the existing `omarchy-shell` process. It does not start
a second Quickshell instance or a resident daemon.

## License

MIT. See [LICENSE](LICENSE).
