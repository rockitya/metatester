#!/bin/bash
set -e

# 0. Set System PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "☢️ 1. BREAKING APT LOCKS"
echo "=================================================="
# Stop the background service specifically
systemctl stop unattended-upgrades 2>/dev/null || true

# Kill any process holding the lock file
while fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    echo "Waiting for other software managers to finish..."
    fuser -k /var/lib/apt/lists/lock 2>/dev/null || true
    sleep 2
done

killall -9 apt apt-get dpkg 2>/dev/null || true
rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock* /var/cache/apt/archives/lock
dpkg --configure -a || true

echo "=================================================="
echo "☢️ 2. NUCLEAR CLEANUP"
echo "=================================================="
killall -9 xvfb x11vnc websockify wine wine64 sde64 2>/dev/null || true
rm -rf /tmp/.X11-unix/X* /tmp/.X*-lock
rm -rf .wine

echo "=================================================="
echo "☢️ 3. INSTALLING FULL WINE64 STACK"
echo "=================================================="
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc websockify \
    wine64 libwine binfmt-support

echo "=================================================="
echo "4. SETTING UP ASSETS"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
    ln -sf vnc.html noVNC/index.html
fi

[ ! -f "sde-external.tar.xz" ] && wget -q --show-progress -O "sde-external.tar.xz" "$SDE_URL"
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder && tar -xf "sde-external.tar.xz" -C sde_folder --strip-components=1
fi
[ ! -f "metatester64.exe" ] && wget -q --show-progress -O "metatester64.exe" "$APP_URL"

echo "=================================================="
echo "5. STARTING DISPLAY SERVICES (DISPLAY :1)"
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
echo "6. LAUNCHING APP VIA SDE"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64
export DISPLAY=:1
wine64 wineboot -u
sleep 5
nohup ./sde_folder/sde64 -hsw -- wine64 explorer /desktop=MetaTester,1024x768 metatester64.exe > debug.log 2>&1 &
