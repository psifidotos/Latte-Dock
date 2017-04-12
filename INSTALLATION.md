Installation
============

## Requirements

We recommend that you use at least **Plasma 5.8.0**

**development packages for:**
```bash
 Qt5Core >= 5.6.0
 Qt5Gui >= 5.6.0
 Qt5Dbus >= 5.6.0

 KF5Plasma >= 5.26.0
 KF5PlasmaQuick >= 5.26.0
 KF5Activities >= 5.26.0
 KF5CoreAddons >= 5.26.0
 KF5DBusAddons >= 5.26.0
 KF5Declarative >= 5.26.0
 KF5Wayland >= 5.26.0
 KF5Package >= 5.26.0
 KF5XmlGui >= 5.26.0
 KF5IconThemes >= 5.26.0
 KF5I18n >= 5.26.0
 KF5Notifications >= 5.26.0
 KF5Archive >= 5.26.0

 For X11 support:
    KF5WindowSystem >= 5.26.0
    Qt5X11Extras >= 5.6.0
    libxcb
```

## From repositories

### Ubuntu/Debian

- [Ubuntu Deb Packages](https://github.com/ubuntuvibes/Debs)

### openSUSE

- [openSUSE OBS](https://software.opensuse.org//download.html?project=home%3Aaudoban&package=latte-dock)

### ArchLinux

```
sudo pacman -Sy latte-dock
```

## Using installation script

**Before running the installation script you have to install the dependencies needed for compiling.**


### Debian 9.0 (Stretch)

```
sudo apt install g++ cmake extra-cmake-modules qtdeclarative5-dev libqt5x11extras5-dev libkf5iconthemes-dev libkf5plasma-dev libkf5windowsystem-dev libkf5declarative-dev libkf5xmlgui-dev libkf5activities-dev gettext libkf5wayland-dev libxcb-util0-dev
```

### Kubuntu only

```
sudo add-apt-repository ppa:kubuntu-ppa/backports
sudo apt update 
sudo apt dist-upgrade 
```

### Kubuntu and KDE Neon

```
sudo apt install cmake extra-cmake-modules qtdeclarative5-dev libqt5x11extras5-dev libkf5iconthemes-dev libkf5plasma-dev libkf5windowsystem-dev libkf5declarative-dev libkf5xmlgui-dev libkf5activities-dev build-essential libxcb-util-dev libkf5wayland-dev git gettext libkf5archive-dev libkf5notifications-dev libxcb-util0-dev
```

### Arch Linux

```
sudo pacman -Syy
sudo pacman -S cmake extra-cmake-modules
sudo pacman -S qt5-base qt5-declarative qt5-x11extras
sudo pacman -S kiconthemes kdbusaddons kxmlgui kdeclarative plasma-framework plasma-desktop
```

### Building and Installing

**Now you can run the installation script.**

```
sh install.sh
```

## Run Latte-Dock

Latte is now ready to be used by executing  ```latte-dock``` or _Latte Dock_ in applications menu.
