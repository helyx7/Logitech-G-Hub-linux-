# OpenGHub on Arch / CachyOS: the beginner guide

This guide takes you from nothing to a working Logitech setup on Linux. No coding needed.
Each command has a short explanation. Copy them one at a time into a terminal.

- [1. Before you start](#1-before-you-start)
- [2. Install](#2-install)
- [3. Open the app](#3-open-the-app)
- [4. First launch: device access](#4-first-launch-device-access)
- [5. Everyday use](#5-everyday-use)
- [6. Keep it working without the app](#6-keep-it-working-without-the-app)
- [7. Update](#7-update)
- [8. Troubleshooting](#8-troubleshooting)
- [9. Uninstall](#9-uninstall)

---

## 1. Before you start

**What OpenGHub is.** An open-source replacement for Logitech G HUB that runs natively on
Linux. It talks to your devices the same way G HUB does on Windows (over HID++ 2.0).

**What works.** Logitech G gaming mice, keyboards, headsets and racing wheels, wired, over
Bluetooth, or through a LIGHTSPEED / Unifying / Bolt receiver. It was tested most on a
G502 LIGHTSPEED and a G923 wheel. Other HID++ 2.0 devices work for the features they report.

**What it is not.** It does not replace *Logi Options+* (MX Master, MX Keys, ...). For those,
use [Solaar](https://github.com/pwr-Solaar/Solaar): `sudo pacman -S solaar`.

**Close other tools first.** Solaar, Piper or `ratbagd` can talk to the same device at the
same time and fight with OpenGHub. Quit them while you use it.

## 2. Install

You need `git` and `base-devel` (already there on CachyOS).

```sh
# 1. Download this repository (skip if you already have it)
git clone https://github.com/helyx7/Logitech-G-Hub-linux-.git ~/work/Logitech-G-Hub-linux-

# 2. Go to the Arch packaging folder
cd ~/work/Logitech-G-Hub-linux-/packaging/arch

# 3. Build and install the package (asks for your password)
makepkg -si
```

What `makepkg -si` does: downloads the official OpenGHub release, checks its checksum,
turns it into an Arch package, and installs it with `pacman`. Pacman then knows about it,
so you can update or remove it cleanly later.

The package also installs a *udev rule* (`/usr/lib/udev/rules.d/70-openghub.rules`). It
lets the person sitting at the computer use Logitech devices without root. It does not open
them to other users.

Optional extras for screen-reactive and music-reactive lighting:

```sh
sudo pacman -S --needed gstreamer gst-plugin-pipewire libpulse
```

## 3. Open the app

Any of these works:

| Where | What to do |
| --- | --- |
| App launcher | Search **logitech**, **g hub**, **mouse** or **OpenGHub** |
| Terminal | Type `openghub` |
| Terminal (shortcut) | Type `logitech`: it opens the app and gives your terminal back. See below. |

To add the `logitech` command yourself, save this as `~/.local/bin/logitech` and run
`chmod +x ~/.local/bin/logitech`:

```bash
#!/usr/bin/env bash
# Open OpenGHub without tying up the terminal. "logitech --wait" shows its logs.
set -euo pipefail
command -v openghub >/dev/null || { echo "OpenGHub is not installed" >&2; exit 1; }
if [[ "${1:-}" == "--wait" ]]; then shift; exec openghub "$@"; fi
setsid -f openghub "$@" >/dev/null 2>&1 </dev/null
```

## 4. First launch: device access

1. **Unplug and plug back in** your device or its USB receiver once after installing. This
   lets the new udev rule apply.
2. Start OpenGHub. Your devices show up on the **Devices** page.
3. If the app says it needs device access and offers to install it, click **Install**.
   Your desktop asks for your password. This is safe: it is the same rule as the package.
4. Wireless device missing? Move the mouse or press a key. Asleep devices don't answer.

## 5. Everyday use

| I want to... | Go to |
| --- | --- |
| Change mouse speed | Device → **Sensitivity**: DPI stages, polling rate (up to 8 kHz) |
| Remap a button | Device → **Assignments**: drag a key, action or macro onto a button. G-Shift gives each button a second action. |
| Record a macro | Device → **Assignments** → **Macros** group |
| Change RGB | Device → **LIGHTSYNC**: fixed, breathing, colour cycle, screen or music sync |
| Use different settings per game | **Profiles**: link a profile to a game. It switches on its own when the game starts. |
| Bring my Windows settings | **Settings → Import profiles from settings.db**. Copy that file from `%LOCALAPPDATA%\LGHUB\` on your Windows PC first. |
| Set up a racing wheel | Device → **Steering Wheel** and **Pedals**: range, force feedback, curves. See [wheels.md](wheels.md). |
| Start with my PC | **Settings → Launch at startup** (starts hidden in the tray) |
| Update firmware | Device → **Settings** (gear icon) → firmware section |

## 6. Keep it working without the app

Open your device, click the **gear icon (Settings)**, and tick **On-board memory mode**.
Your DPI, report rate, lighting and buttons are then written *into the device*. They keep working with the app closed, after a reboot, in other
operating systems and on other PCs.

Software-only features need the app running in the tray: screen/music lighting, per-game
profile switching, and Lua scripts. In on-board mode, software lighting effects fall back to
a fixed colour on the device.

## 7. Update

Get the newest version of this repository, then rebuild:

```sh
cd ~/work/Logitech-G-Hub-linux-
git pull
cd packaging/arch && makepkg -si
```

When a new OpenGHub version comes out, the person who maintains this repository updates
`pkgver` and `sha256sums` in [`packaging/arch/PKGBUILD`](../packaging/arch/PKGBUILD).

## 8. Troubleshooting

**"No devices" or only demo devices.**
Run these, then unplug and replug the receiver:

```sh
sudo udevadm control --reload-rules
sudo udevadm trigger --action=add --subsystem-match=hidraw
```

Check access: `ls -l /dev/hidraw*`. A `+` at the end of the permissions (for example
`crw-rw----+`) means your user got access.

**Settings jump back or act strangely.** Another tool is talking to the device. Quit
Solaar, Piper and `ratbagd`: `systemctl stop ratbagd`.

**The app won't open.** Run `logitech --wait` (or `openghub`) in a terminal and read the
error. Include it when you ask for help.

**A feature is missing for my device.** Open *Device settings → HID++ features* and include
that list in an issue on [the original project](https://github.com/Slyvan25/OpenGHub/issues).

More detail: [permissions.md](permissions.md), [hidpp.md](hidpp.md),
[lighting.md](lighting.md), [profiles.md](profiles.md).

## 9. Uninstall

```sh
sudo pacman -R openghub-bin      # removes the app and its udev rule
rm -f ~/.local/bin/logitech      # removes the terminal shortcut, if you added it
```

Your profiles stay in `~/.config/openghub/` and `~/.local/share/openghub/`. Delete those
folders too if you want a completely clean removal.
