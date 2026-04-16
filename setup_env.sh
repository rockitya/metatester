#!/bin/bash
set -e

# 0. Set System PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. Force Unlocking APT & Disabling Firewalls"
echo "=================================================="
systemctl stop unattended-upgrades 2>/dev/null || true
killall -9 apt apt-get dpkg 2>/dev/null || true
rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock
dpkg --configure -a || true

(ufw disable || true)
iptables -F && iptables -X
iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT

echo "=================================================="
echo "2. Installing Minimal Dependencies (Filtered Wine)"
echo "=================================================="
# We only install the core 64-bit wine binaries and X11 support
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc novnc websockify fluxbox \
    wine64 libwine

echo "=================================================="
echo "3. Downloading SDE & MetaTester"
echo "=================================================="
SDE_TAR="sde-external.tar.xz"
[ ! -f "$SDE_TAR" ] && wget -q --show-progress -O "$SDE_TAR" "$SDE_URL"

mkdir -p sde_folder
tar -xf "$SDE_TAR" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

APP_EXE="metatester64.exe"
[ ! -f "$APP_EXE" ] && wget -q --show-progress -O "$APP_EXE" "$APP_URL"

echo "=================================================="
echo "4. Starting Virtual Display & noVNC"
echo "=================================================="
killall -9 xvfb x11vnc websockify fluxbox wine sde64 2>/dev/null || true
rm -f /tmp/.X0-lock

Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0
sleep 3
fluxbox &
x11vnc -display :0 -nopw -listen localhost -forever -quiet &
sleep 2

ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
websockify --web /usr/share/novnc/ 8080 localhost:5900 > /dev/null 2>&1 &

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://$(curl -s ifconfig.me):8080/"
echo "========================================================="

echo "=================================================="
echo "5. Launching MetaTester via SDE (AVX)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEDEBUG=-all
export DISPLAY=:0

# Faster Wine boot by skipping the 32-bit search
export WINEARCH=win64
wineboot -u
sleep 5

# Launch with SDE
"$SDE_BIN" -hsw -- wine "$APP_EXE"
