#!/bin/bash
set -e

# 0. Set System PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "☢️ 1. CLEARING LOCKS & OLD SOCKETS"
echo "=================================================="
killall -9 xvfb x11vnc websockify wine wine64 sde64 2>/dev/null || true
rm -rf /tmp/.X11-unix/X* /tmp/.X*-lock
rm -rf .wine

echo "=================================================="
echo "☢️ 2. INSTALLING ALL WINE64 DEPENDENCIES"
echo "=================================================="
apt-get update
# Installing the full wine64 suite + development tools ensures all shared libraries (.so files) are present
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget curl tar xz-utils xvfb x11vnc websockify \
    wine64 libwine wine-preloader binfmt-support

echo "=================================================="
echo "3. SETTING UP ASSETS"
echo "=================================================="
# noVNC setup
if [ ! -d "noVNC" ]; then
    wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
    ln -sf vnc.html noVNC/index.html
fi

# Intel SDE
[ ! -f "sde-external.tar.xz" ] && wget -q --show-progress -O "sde-external.tar.xz" "$SDE_URL"
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder && tar -xf "sde-external.tar.xz" -C sde_folder --strip-components=1
fi

# MetaTester64
[ ! -f "metatester64.exe" ] && wget -q --show-progress -O "metatester64.exe" "$APP_URL"

echo "=================================================="
echo "4. STARTING DISPLAY SERVICES (DISPLAY :1)"
echo "=================================================="
Xvfb :1 -screen 0 1024x768x16 &
export DISPLAY=:1
sleep 3

x11vnc -display :1 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &
sleep 2

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://$(curl -s ifconfig.me):8080/vnc.html"
echo "========================================================="

echo "=================================================="
echo "5. LAUNCHING APP VIA SDE"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64
export DISPLAY=:1

# Force Wine to initialize
wine64 wineboot -u
sleep 5

# Launch using the SDE emulator in a Virtual Desktop for maximum compatibility
nohup ./sde_folder/sde64 -hsw -- wine64 explorer /desktop=MetaTester,1024x768 metatester64.exe > debug.log 2>&1 &

echo "Process started. Check your browser in 30-60 seconds."
