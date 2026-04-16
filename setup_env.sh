#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:99

echo "--- 1. CLEANING LOCKS ---"
killall -9 xvfb x11vnc websockify wine wine64 sde64 2>/dev/null || true
rm -rf /tmp/.X* /tmp/.lock*

echo "--- 2. INSTALLING X11 BASICS (FAST) ---"
apt-get update -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    xvfb x11vnc websockify curl tar xz-utils

echo "--- 3. DOWNLOADING PORTABLE WINE (KRON4EK BUILD) ---"
if [ ! -d "wine-dist" ]; then
    # Using the 9.0 WOW64 build which is very stable for 64-bit apps
    curl -L "https://github.com/Kron4ek/Wine-Builds/releases/download/9.0/wine-9.0-amd64-wow64.tar.xz" | tar xJ
    mv wine-9.0-amd64-wow64 wine-dist
fi
WINE_BIN="$(pwd)/wine-dist/bin/wine"

echo "--- 4. ASSETS (SDE & APP) ---"
[ ! -d "noVNC" ] && curl -L https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz && mv noVNC-1.4.0 noVNC
[ ! -d "sde_folder" ] && mkdir -p sde_folder && curl -L "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
[ ! -f "metatester64.exe" ] && curl -L -o "metatester64.exe" "https://archive.org/download/metatester64/metatester64.exe"

echo "--- 5. STARTING SERVICES ---"
Xvfb :99 -screen 0 1024x768x16 &
sleep 2
x11vnc -display :99 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "--- 6. LAUNCHING ---"
export WINEPREFIX="$(pwd)/.wine"
# Start the virtual desktop and app
nohup ./sde_folder/sde64 -hsw -- $WINE_BIN explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "✅ Running at http://$(curl -s ifconfig.me):8080/vnc.html"
