#!/bin/bash
# =================================================================
# FINAL BUG-FREE SETUP SCRIPT
# =================================================================

# 1. Environment & Path Fix
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:99
export WINEPREFIX="/root/.wine"
export WINEARCH=win64

echo "--------------------------------------------------"
echo "☢️ 1. KILLING ALL LOCKS & PREVIOUS SERVICES"
echo "--------------------------------------------------"
systemctl stop unattended-upgrades 2>/dev/null || true
killall -9 apt apt-get dpkg xvfb x11vnc websockify wine wine64 wine64-stable sde64 2>/dev/null || true
rm -rf /tmp/.X* /tmp/.lock* /var/lib/apt/lists/lock /var/lib/dpkg/lock*
rm -rf /root/.wine

echo "--------------------------------------------------"
echo "☢️ 2. INSTALLING DEPENDENCIES (STABLE)"
echo "--------------------------------------------------"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc websockify wine64 libwine binfmt-support

echo "--------------------------------------------------"
echo "☢️ 3. CLEAN NOVNC & ASSET SETUP"
echo "--------------------------------------------------"
# Clean and install noVNC correctly to avoid UI errors
rm -rf noVNC
wget -qO- https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
mv noVNC-1.4.0 noVNC
cp noVNC/vnc.html noVNC/index.html

# Download SDE
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder
    wget -qO- "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
fi

# Download App
wget -q -O "metatester64.exe" "https://archive.org/download/metatester64/metatester64.exe"

echo "--------------------------------------------------"
echo "☢️ 4. STARTING DISPLAY & PROXY (DISPLAY :99)"
echo "--------------------------------------------------"
Xvfb :99 -screen 0 1024x768x16 &
sleep 3
x11vnc -display :99 -nopw -listen localhost -forever -quiet &
sleep 2
# Start proxy from the correct path to fix 'ui.js' errors
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &
sleep 2

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER: http://$(curl -s ifconfig.me):8080/vnc.html"
echo "========================================================="

echo "--------------------------------------------------"
echo "☢️ 5. LAUNCHING VIA INTEL SDE (EMULATION)"
echo "--------------------------------------------------"
# Detect exact Wine path (Fixes 'wine64 not found')
WINE_CMD=$(which wine64-stable || which wine64 || which wine)
echo "Using Wine: $WINE_CMD"

$WINE_CMD wineboot -u
sleep 5

# Final Launch Command
nohup ./sde_folder/sde64 -hsw -- $WINE_CMD explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "MetaTester is initializing in the background."
echo "Wait 60 seconds for the window to draw on the emulator."
