#!/bin/bash

# Exit script on any error
set -e

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. Force Unlocking APT & Disabling Firewalls"
echo "=================================================="
# Stop background update services
systemctl stop unattended-upgrades.service 2>/dev/null || true
killall -9 apt apt-get dpkg 2>/dev/null || true

# Remove all package manager locks
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*
dpkg --configure -a

# Disable Firewalls
(ufw disable || true)
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo "=================================================="
echo "2. Cleaning Up Previous X11/VNC Sessions"
echo "=================================================="
killall -9 xvfb x11vnc websockify fluxbox wine sde64 2>/dev/null || true
rm -f /tmp/.X0-lock
rm -rf /tmp/.X11-unix/X0

echo "=================================================="
echo "3. Installing Minimal Dependencies"
echo "=================================================="
dpkg --add-architecture i386
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc novnc websockify fluxbox \
    wine64 wine32 libwine libwine:i386

echo "=================================================="
echo "4. Downloading SDE & MetaTester"
echo "=================================================="
SDE_TAR="sde-external.tar.xz"
if [ ! -f "$SDE_TAR" ]; then
    wget -q --show-progress -O "$SDE_TAR" "$SDE_URL"
fi

mkdir -p sde_folder
tar -xf "$SDE_TAR" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

APP_EXE="metatester64.exe"
if [ ! -f "$APP_EXE" ]; then
    wget -q --show-progress -O "$APP_EXE" "$APP_URL"
fi

echo "=================================================="
echo "5. Starting Virtual Display & noVNC"
echo "=================================================="
# Start Xvfb on Display :0
Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0
sleep 3

# Start Window Manager
fluxbox &
sleep 2

# Start VNC Server
x11vnc -display :0 -nopw -listen localhost -forever -quiet &
sleep 2

# Configure noVNC
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
websockify --web /usr/share/novnc/ 8080 localhost:5900 > /dev/null 2>&1 &

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://YOUR_SERVER_IP:8080/"
echo "========================================================="

echo "=================================================="
echo "6. Launching MetaTester via SDE (AVX Emulation)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEDEBUG=-all
export DISPLAY=:0

# Pre-initialize Wine environment
wineboot -u
sleep 5

# Run with Intel Haswell Emulation (AVX/AVX2 support)
"$SDE_BIN" -hsw -- wine "$APP_EXE"
