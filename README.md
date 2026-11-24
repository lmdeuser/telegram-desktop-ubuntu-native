# Telegram Desktop — Native Ubuntu 26.04 LTS Package

Native `.deb` packaging of [Telegram Desktop](https://github.com/telegramdesktop/tdesktop) for **Ubuntu 26.04 LTS (`resolute`, `amd64`)**, compiled from official upstream source releases against system libraries and distributed via a signed APT repository on [Open Build Service](https://build.opensuse.org/project/show/home:dwolfF:telegram).

> [!NOTE]
> This is an independent community packaging project and is not affiliated with or endorsed by Telegram Messenger Inc.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Updating and Uninstallation](#updating-and-uninstallation)
- [Packaging and Patches](#packaging-and-patches)
- [Repository Structure](#repository-structure)
- [License](#license)

## Overview

This project provides an APT-installable `telegram-desktop` Debian package built from upstream source archives in `3.0 (quilt)` format. Unlike static upstream tarballs or containerized packages, the binary links dynamically against Ubuntu 26.04 LTS system libraries (`Qt 6.10`, `FFmpeg 8`, `PipeWire`, `Wayland`, `OpenSSL 3`) and integrates directly with the host desktop environment.

The package installs `/usr/bin/Telegram` (with a `/usr/bin/telegram-desktop` symlink) along with upstream desktop launcher metadata, D-Bus activation files, AppStream metadata, and application icons.

## Features

- **System Qt 6.10 integration**: Built against Qt's public ABI using Ubuntu's system Qt 6 libraries, QPA and image plugins (`qt6-wayland`, `qt6-qpa-plugins`, `qt6-image-formats-plugins`), XDG Desktop Portals (`xdg-desktop-portal`), and Secret Service (`libsecret-1-0`).
- **Native Wayland and PipeWire support**: Runs natively on Wayland sessions with PipeWire screen and audio sharing via `tg_owt`.
- **Hardware-accelerated video decoding**: Linked against system FFmpeg 8 (`libavcodec62`, `libavformat62`, `libavfilter11`) with Linux hardware video decoding (VA-API, VDPAU, CUDA) enabled by default and automatic fallback to software decoding when GPU acceleration is unavailable. Saved user preferences in Telegram settings remain authoritative.
- **Signed APT updates**: Upstream's built-in binary self-updater and crash reporter are disabled at build time so updates are delivered exclusively through APT with OpenPGP repository verification.

## System Requirements

| Requirement | Supported Target |
| --- | --- |
| Operating System | Ubuntu 26.04 LTS (`resolute`) |
| Architecture | `amd64` (`x86_64`) |
| Package Format | Debian binary package (`.deb`) via DEB822 APT source |
| Optional GPU Drivers | `va-driver-all` (recommended automatically) or vendor VA-API / VDPAU / NVIDIA drivers |

## Installation

1. **Install prerequisites and import the repository signing key:**

   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gpg
   sudo install -d -m 0755 /usr/share/keyrings
   curl -fsSL https://download.opensuse.org/repositories/home:/dwolfF:/telegram/xUbuntu_26.04/Release.key \
     | sudo gpg --dearmor --yes -o /usr/share/keyrings/telegram-obs.gpg
   sudo chmod 0644 /usr/share/keyrings/telegram-obs.gpg
   ```

2. **(Optional) Verify the signing key fingerprint before enabling the repository:**

   ```bash
   gpg --show-keys --with-fingerprint /usr/share/keyrings/telegram-obs.gpg
   ```

   Expected key fingerprint (`home:dwolfF OBS Project <home:dwolfF@build.opensuse.org>`):

   ```text
   C106 E46D E757 8257 F4CD  62C9 6AE3 5907 289D 3BDC
   ```

3. **Configure the DEB822 APT repository and install `telegram-desktop`:**

   ```bash
   sudo tee /etc/apt/sources.list.d/telegram-obs.sources >/dev/null <<'EOF'
   Types: deb
   URIs: https://download.opensuse.org/repositories/home:/dwolfF:/telegram/xUbuntu_26.04/
   Suites: /
   Architectures: amd64
   Signed-By: /usr/share/keyrings/telegram-obs.gpg
   EOF
   sudo apt-get update
   sudo apt-get install -y telegram-desktop
   ```

## Updating and Uninstallation

### Updating

Once the APT repository is configured, `telegram-desktop` receives updates through standard system upgrades:

```bash
sudo apt-get update
sudo apt-get install --only-upgrade telegram-desktop
```

### Uninstallation

Remove the `telegram-desktop` package (existing user profile data under `~/.local/share/TelegramDesktop` is preserved):

```bash
sudo apt-get remove telegram-desktop
```

To also remove the APT repository configuration and signing key:

```bash
sudo rm -f /etc/apt/sources.list.d/telegram-obs.sources /usr/share/keyrings/telegram-obs.gpg
sudo apt-get update
```

## Packaging and Patches

Complete Debian `3.0 (quilt)` source packages (`.dsc`, upstream `orig` source archive, pinned build-time dependency archives, and `debian.tar.xz`) are published in the [OBS `telegram-desktop` package](https://build.opensuse.org/package/show/home:dwolfF:telegram/telegram-desktop).

Pinned upstream revisions and SHA-256 digests for build-time components (`tg_owt`, `tde2e`, `tlottie`, `wallet-engine`, `rnnoise`, and the Rust `1.96.1` toolchain) are recorded in [packaging/source/dependencies.lock.json](packaging/source/dependencies.lock.json).

The quilt patch series in [packaging/source/debian/patches/](packaging/source/debian/patches/) applies three targeted adjustments:

| Patch | Description |
| --- | --- |
| `enable-linux-hardware-video.patch` | Enables hardware-accelerated video decoding by default on Linux while preserving user preferences and software fallback. |
| `qt-6.10-accessible-orientation.patch` | Guards Qt 6.11 `QAccessible::Attribute::Orientation` usage when compiling against Ubuntu 26.04's system Qt 6.10. |
| `disable-private-qt-thanos.patch` | Guards `ThanosEffect` renderer checks when building with `DESKTOP_APP_DISABLE_PRIVATE_QT_API=ON`. |

## Repository Structure

```text
.
├── packaging/source/
│   ├── debian/                  # Debian 3.0 (quilt) packaging metadata, build rules, and patches
│   └── dependencies.lock.json   # Pinned upstream dependency revisions and SHA-256 checksums
├── LICENSE                      # GNU General Public License v3.0
└── README.md                    # Project overview and APT repository guide
```

## License

- Packaging recipes and patches in this repository are licensed under [GPL-3.0-or-later](LICENSE).
- Upstream Telegram Desktop is licensed under `GPL-3.0-or-later WITH OpenSSL-exception`. Upstream `LICENSE`, `LEGAL`, `SOURCE`, and third-party dependency notices are installed under `/usr/share/doc/telegram-desktop/`.
- Upstream source code: <https://github.com/telegramdesktop/tdesktop>
- Open Build Service project: <https://build.opensuse.org/project/show/home:dwolfF:telegram>
