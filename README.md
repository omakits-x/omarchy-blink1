# Omarchy blink(1) Control
<img width="425" height="266" alt="image" src="https://github.com/user-attachments/assets/0e2b0eed-66d9-41d7-9a1e-2cb639fe3a02" />

An Omarchy `bar-widget` for ThingM blink(1) USB status lights. It uses the
official Omarchy shell plugin contract and invokes `blink1-tool` directly.

## Features

- Bar indicator colored with the last selected RGB value.
- ThingM mark shown as the bar icon, with a muted state while disconnected.
- The supplied ThingM artwork is used while idle; active effects use a colored,
  gently pulsing status mark and return to the artwork when finished.
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

The plugin does not install packages automatically. Install the CLI explicitly,
verify the USB device, then install the Omarchy plugin.

### 1. Install the blink(1) CLI

Using `paru`:

```bash
paru -S --needed blink1-tool-bin
```

Using `yay`:

```bash
yay -S --needed blink1-tool-bin
```

Confirm that the command is available:

```bash
command -v blink1-tool
blink1-tool --version
```

### 2. Check USB access

Plug in the blink(1) and run:

```bash
blink1-tool --list
```

You should see one line per device, for example `id:0`. If the command cannot
access the device as your user, install or reload the upstream udev rule and
reconnect the blink(1):

```bash
blink1-tool --add_udev_rules
```

The rule source is also available in the [blink1 repository](https://github.com/todbot/blink1/blob/main/linux/51-blink1.rules).

### 3. Install and enable the plugin

```bash
omarchy plugin add https://github.com/omakits-x/omarchy-blink1.git --enable --yes
```

Omarchy chooses the initial bar section when no placement is supplied. Open the
widget with a left click.
Right-click sends a random color, and middle-click turns the selected device(s)
off. The panel's device button cycles through `ALL DEVICES` and every detected
device ID.

To choose the bar position explicitly, use one of:

```bash
omarchy plugin enable io.github.omakitsx.blink1 --section left
omarchy plugin enable io.github.omakitsx.blink1 --section center
omarchy plugin enable io.github.omakitsx.blink1 --section right
```

If the plugin is installed but not visible, rescan and enable it again:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.omakitsx.blink1
omarchy plugin list --json
```

### Update or remove

```bash
omarchy plugin update io.github.omakitsx.blink1 --yes
omarchy plugin remove io.github.omakitsx.blink1 --yes
```

Removing the plugin does not remove `blink1-tool-bin` or its udev rule.

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
