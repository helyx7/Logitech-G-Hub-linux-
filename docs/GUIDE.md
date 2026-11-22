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

This builds the app from this repository, so you get its fixes (Bluetooth, device pictures)
on top of the original OpenGHub.

```sh
# 1. Tools needed to build (one time)
sudo pacman -S --needed git base-devel rust nodejs npm

# 2. Download this repository (skip if you already have it)
git clone https://github.com/helyx7/Logitech-G-Hub-linux-.git ~/work/Logitech-G-Hub-linux-

# 3. Add the "logitech" terminal command
ln -sf ~/work/Logitech-G-Hub-linux-/scripts/logitech ~/.local/bin/logitech

# 4. Build and install (takes a few minutes, asks for your password)
logitech update
```

`logitech update` builds an Arch package called `openghub-local` and installs it with
`pacman`, so you can remove it cleanly later. If you installed `openghub-bin` before,
pacman offers to replace it: answer **y**.

The package also installs a *udev rule* (`/usr/lib/udev/rules.d/70-openghub.rules`). It
lets the person sitting at the computer use Logitech devices without root. It does not open
them to other users.

Optional extras for screen-reactive and music-reactive lighting:

```sh
sudo pacman -S --needed gstreamer gst-plugin-pipewire libpulse
```

<details>
<summary>Prefer the unmodified official release?</summary>

`cd packaging/arch && makepkg -si` installs `openghub-bin`, built from the original
project's release. It does not have this repository's fixes.
</details>

## 3. Open the app

| Where | What to do |
| --- | --- |
| App launcher | Search **logitech**, **g hub**, **mouse** or **OpenGHub** |
| Terminal | Type `logitech`: it opens the app and gives your terminal back |

All `logitech` commands:

| Command | What it does |
| --- | --- |
| `logitech` | Opens the app |
| `logitech --wait` | Opens it in the terminal and shows its messages (for errors) |
| `logitech update` | Updates everything and reinstalls (see [Update](#7-update)) |
| `logitech images` | Downloads pictures for the connected devices |

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

```sh
logitech update
```

That one command:

1. gets the newest version of this repository from GitHub,
2. merges in new work from the [original OpenGHub](https://github.com/Slyvan25/OpenGHub),
3. pushes the result back to this repository on GitHub,
4. rebuilds the app and reinstalls it (asks for your password).

If nothing changed, it says so and stops. It also stops, changing nothing, if you have
unsaved edits in the repository or if the original project's changes clash with this
repository's. The message tells you what to do.

Options: `logitech update --no-upstream` skips step 2, `--no-push` skips step 3.

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

**No picture for my device.** Run `logitech images`. It lists the devices it has no picture
for. Save the product image from logitechg.com or logitech.com as
`~/.local/share/openghub/devices/<product-id>.png`, and add a line to
[`src-tauri/data/artwork-sources.tsv`](../src-tauri/data/artwork-sources.tsv) so it works for
everyone after the next update.

**Bluetooth device missing.** First pair it in your desktop's Bluetooth settings and check
it types or moves normally. Then restart OpenGHub. Check the system sees it:
`bluetoothctl devices Connected`.

**The app won't open.** Run `logitech --wait` (or `openghub`) in a terminal and read the
error. Include it when you ask for help.

**A feature is missing for my device.** Open *Device settings → HID++ features* and include
that list in an issue on [the original project](https://github.com/Slyvan25/OpenGHub/issues).

More detail: [permissions.md](permissions.md), [hidpp.md](hidpp.md),
[lighting.md](lighting.md), [profiles.md](profiles.md).

## 9. Uninstall

```sh
sudo pacman -R openghub-local    # removes the app and its udev rule (openghub-bin if you used that)
rm -f ~/.local/bin/logitech      # removes the terminal shortcut
```

Your profiles stay in `~/.config/openghub/` and `~/.local/share/openghub/`. Delete those
folders too if you want a completely clean removal.
