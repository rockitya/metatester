#!/bin/bash
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. Unlocking & Disabling Firewalls"
echo "=================================================="
systemctl stop unattended-upgrades 2>/dev/null || true
killall -9 apt apt-get dpkg 2>/dev/null || true
rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock

echo "=================================================="
echo "2. Ultra-Minimal Dependencies"
echo "=================================================="
apt-get update
# We only install the bare essentials: Xvfb, VNC, and core Wine
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc wine64 libwine websockify

echo "=================================================="
echo "3. Manual noVNC Setup (Bypasses 100+ packages)"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
    ln -s noVNC/vnc.html noVNC/index.html
fi

echo "=================================================="
echo "4. Downloading SDE & MetaTester"
echo "=================================================="
[ ! -f "sde-external.tar.xz" ] && wget -q --show-progress -O "sde-external.tar.xz" "$SDE_URL"
mkdir -p sde_folder && tar -xf "sde-external.tar.xz" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

[ ! -f "metatester64.exe" ] && wget -q --show-progress -O "metatester64.exe" "$APP_URL"

echo "=================================================="
echo "5. Starting Services"
echo "=================================================="
killall -9 xvfb x11vnc websockify wine sde64 2>/dev/null || true
rm -f /tmp/.X0-lock

Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0
sleep 2

# Start VNC and noVNC Proxy
x11vnc -display :0 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://$(curl -s ifconfig.me):8080/"
echo "========================================================="

echo "=================================================="
echo "6. Launching MetaTester (AVX)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64
export WINEDEBUG=-all
wineboot -u
sleep 5
"$SDE_BIN" -hsw -- wine metatester64.exe
