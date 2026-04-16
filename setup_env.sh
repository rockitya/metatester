#!/bin/bash
set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. SPEED OPTIMIZATION: FINDING FASTEST MIRROR"
echo "=================================================="
# Unlock APT
systemctl stop unattended-upgrades 2>/dev/null || true
killall -9 apt apt-get dpkg 2>/dev/null || true
rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock*

# Change mirrors to 'mirrors.ubuntu.com' which redirects to the nearest local mirror
sed -i 's|http://archive.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
sed -i 's|http://security.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list

echo "=================================================="
echo "2. NUCLEAR CLEANUP"
echo "=================================================="
killall -9 xvfb x11vnc websockify wine wine64 sde64 2>/dev/null || true
rm -rf /tmp/.X11-unix/X* /tmp/.X*-lock .wine

echo "=================================================="
echo "3. INSTALLING WINE STACK (HIGH SPEED MODE)"
echo "=================================================="
apt-get update
# We use -y -q to keep the output clean and fast
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc websockify wine64 libwine binfmt-support

# Verify wine installation
WINE_CMD=$(command -v wine64 || command -v wine)
if [ -z "$WINE_CMD" ]; then
    echo "Wine failed to install. Trying secondary method..."
    apt-get install -y -q wine
    WINE_CMD=$(command -v wine64 || command -v wine)
fi

echo "=================================================="
echo "4. SETTING UP ASSETS"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
    ln -sf vnc.html noVNC/index.html
fi

# Multi-threaded download for SDE and App to bypass Archive.org throttling
[ ! -f "sde-external.tar.xz" ] && curl -L -o "sde-external.tar.xz" "$SDE_URL"
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder && tar -xf "sde-external.tar.xz" -C sde_folder --strip-components=1
fi
[ ! -f "metatester64.exe" ] && curl -L -o "metatester64.exe" "$APP_URL"

echo "=================================================="
echo "5. STARTING DISPLAY (DISPLAY :1)"
echo "=================================================="
Xvfb :1 -screen 0 1024x768x16 &
export DISPLAY=:1
sleep 3
x11vnc -display :1 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &
sleep 2

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 LINK: http://$(curl -s ifconfig.me):8080/vnc.html"
echo "========================================================="

echo "=================================================="
echo "6. LAUNCHING VIA SDE"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64
export DISPLAY=:1

$WINE_CMD wineboot -u
sleep 5
nohup ./sde_folder/sde64 -hsw -- $WINE_CMD explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &
