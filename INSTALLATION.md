Installation
============

## Using installation script

**Before running the installation script you have to install the dependencies needed for compiling.**

**If you want to use git to download what you need or in order to update from github please also install git.**


### Kubuntu only

```
sudo add-apt-repository ppa:kubuntu-ppa/backports
sudo apt update
sudo apt dist-upgrade
```

### Kubuntu and KDE Neon

```
sudo apt install cmake extra-cmake-modules qtdeclarative5-dev libqt5x11extras5-dev libkf5iconthemes-dev libkf5plasma-dev libkf5windowsystem-dev libkf5declarative-dev libkf5xmlgui-dev libkf5activities-dev build-essential libxcb-util-dev libkf5wayland-dev git gettext libkf5archive-dev libkf5notifications-dev libxcb-util0-dev libsm-dev libkf5crash-dev libkf5newstuff-dev
```

### Arch Linux

```
sudo pacman -Syu
sudo pacman -S cmake extra-cmake-modules python plasma-framework plasma-desktop
```

### Building and Installing

To use git to download what you need:
```
git clone https://github.com/psifidotos/Latte-Dock.git
```

**Now you can run the installation script.**

```
sh install.sh
```

### Updating
You can have a script in your `~/bin` folder with this code. It simply uses git to check for changes then rebuilds the application. Please do not remove the `Latte-Dock` folder that you downloaded with `git clone`.
```
#!/bin/bash

# Ending process
killall latte-dock

# Updating from github
cd ~/Latte-Dock
git pull https://github.com/psifidotos/Latte-Dock.git

# Build
./install.sh

sleep 1s
echo "Done. Now starting latte."
latte-dock &
```
