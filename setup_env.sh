#!/bin/bash
set -e

# 0. Set System PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "☢️ 1. NUCLEAR WIPE: Killing Processes & Deleting Data"
echo "=================================================="
# Kill every possible related process
killall -9 apt apt-get dpkg xvfb x11vnc websockify wine wine64 sde64 fluxbox 2>/dev/null || true

# Stop background services
systemctl stop unattended-upgrades 2>/dev/null || true

# Remove all locks and caches
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*
rm -f /var/lib/dpkg/lock* /var/lib/apt/lists/lock /tmp/.X0-lock /tmp/.X11-unix/X0

# Delete previous installation data
rm -rf noVNC sde_folder .wine setup.sh debug.log sde-external.tar.xz metatester64.exe

echo "=================================================="
echo "☢️ 2. UNINSTALLING & PURGING EXISTING MODULES"
echo "=================================================="
# Force remove wine and display modules to ensure clean versions
apt-get purge -y wine* xvfb x11vnc novnc websockify fluxbox libwine* 2>/dev/null || true
apt-get autoremove -y && apt-get autoclean -y

echo "=================================================="
echo "3. FRESH INSTALLATION"
echo "=================================================="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc wine64 libwine websockify binfmt-support

echo "=================================================="
echo "4. CLEAN SETUP: noVNC, SDE & MetaTester"
echo "=================================================="
# Setup noVNC manually
wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
mv noVNC-1.4.0 noVNC
ln -sf vnc.html noVNC/index.html

# Download SDE
wget -q --show-progress -O "sde-external.tar.xz" "$SDE_URL"
mkdir -p sde_folder && tar -xf "sde-external.tar.xz" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

# Download App
wget -q --show-progress -O "metatester64.exe" "$APP_URL"

echo "=================================================="
echo "5. STARTING VIRTUAL DISPLAY"
echo "=================================================="
Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0
sleep 3
x11vnc -display :0 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &
sleep 2

echo "========================================================="
echo "✅ NUCLEAR SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://$(curl -s ifconfig.me):8080/vnc.html"
echo "========================================================="

echo "=================================================="
echo "6. LAUNCHING APP (AVX EMULATION)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64
export DISPLAY=:0

# Clean Wine Boot
wine64 wineboot -u
sleep 5

# Launch inside a Virtual Desktop to guarantee visibility
nohup "$SDE_BIN" -hsw -- wine64 explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "App is launching..."
echo "If the screen is black after 60s, check logs with: cat debug.log"
