#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:99

echo "--------------------------------------------------"
echo "⚡ 1. CLEANING AND KILLING LOCKS"
echo "--------------------------------------------------"
killall -9 xvfb x11vnc websockify wine wine64 sde64 2>/dev/null || true
rm -rf /tmp/.X* /tmp/.lock*

echo "--------------------------------------------------"
echo "⚡ 2. INSTALLING MINIMAL X11 (FAST)"
echo "--------------------------------------------------"
# We still need Xvfb for the screen, but this is much smaller than Wine
apt-get update -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    xvfb x11vnc websockify curl tar xz-utils

echo "--------------------------------------------------"
echo "⚡ 3. DOWNLOADING PORTABLE WINE (CDN)"
echo "--------------------------------------------------"
# Downloading a portable Wine 64-bit build (Stable)
if [ ! -f "wine-portable.tar.gz" ]; then
    curl -L -o wine-portable.tar.gz "https://github.com/v_v_v/wine-portable/releases/download/7.0/wine-7.0-amd64.tar.gz" 
    mkdir -p wine-dist && tar -xzf wine-portable.tar.gz -C wine-dist --strip-components=1
fi
WINE_BIN="$(pwd)/wine-dist/bin/wine"

echo "--------------------------------------------------"
echo "⚡ 4. DOWNLOADING ASSETS (SDE & APP)"
echo "--------------------------------------------------"
[ ! -d "noVNC" ] && curl -L https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz && mv noVNC-1.4.0 noVNC
[ ! -d "sde_folder" ] && mkdir -p sde_folder && curl -L "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
[ ! -f "metatester64.exe" ] && curl -L -o "metatester64.exe" "https://archive.org/download/metatester64/metatester64.exe"

echo "--------------------------------------------------"
echo "⚡ 5. STARTING SERVICES"
echo "--------------------------------------------------"
Xvfb :99 -screen 0 1024x768x16 &
sleep 2
x11vnc -display :99 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "--------------------------------------------------"
echo "⚡ 6. LAUNCHING VIA SDE"
echo "--------------------------------------------------"
export WINEPREFIX="$(pwd)/.wine"
# Launch using the Portable Wine path
nohup ./sde_folder/sde64 -hsw -- $WINE_BIN explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "✅ ALL SET! Link: http://$(curl -s ifconfig.me):8080/vnc.html"
