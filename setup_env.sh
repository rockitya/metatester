#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:99

echo "=================================================="
echo "⚡ 1. CLEANING LOCKS & PREVIOUS SERVICES"
echo "=================================================="
systemctl stop unattended-upgrades 2>/dev/null || true
killall -9 xvfb x11vnc websockify wine wine64 sde64 apt apt-get dpkg 2>/dev/null || true
rm -rf /tmp/.X* /tmp/.lock* /var/lib/apt/lists/lock /var/lib/dpkg/lock*

echo "=================================================="
echo "⚡ 2. INSTALLING LIGHTWEIGHT DISPLAY TOOLS"
echo "=================================================="
apt-get update -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    xvfb x11vnc websockify curl tar xz-utils

echo "=================================================="
echo "⚡ 3. DOWNLOADING WINE 11.6 (ARCHIVE.ORG)"
echo "=================================================="
if [ ! -d "wine-dist" ]; then
    echo "Downloading and extracting Wine 11.6..."
    mkdir -p wine-dist
    # Using the direct download route for clean tar.xz streaming
    curl -L "https://archive.org/download/wine-11.6-amd64-wow64.tar/wine-11.6-amd64-wow64.tar.xz" | tar xJ -C wine-dist --strip-components=1
fi
WINE_BIN="$(pwd)/wine-dist/bin/wine"

echo "=================================================="
echo "⚡ 4. DOWNLOADING SDE & APP"
echo "=================================================="
if [ ! -d "sde_folder" ]; then
    echo "Downloading Intel SDE..."
    mkdir -p sde_folder
    curl -L "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
fi

if [ ! -f "metatester64.exe" ]; then
    echo "Downloading MetaTester..."
    curl -L -o "metatester64.exe" "https://archive.org/download/metatester64/metatester64.exe"
fi

echo "=================================================="
echo "⚡ 5. SETTING UP NOVNC"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    curl -L -s https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
fi

echo "=================================================="
echo "⚡ 6. STARTING VIRTUAL DISPLAY SERVICES"
echo "=================================================="
Xvfb :99 -screen 0 1024x768x16 &
sleep 2
x11vnc -display :99 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "=================================================="
echo "⚡ 7. LAUNCHING METATESTER VIA SDE"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"

# Pre-boot Wine environment
$WINE_BIN wineboot -u
sleep 5

# Launch app wrapped in SDE
nohup ./sde_folder/sde64 -hsw -- $WINE_BIN explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "========================================================="
echo "✅ SUCCESS! "
echo "🌐 BROWSER: http://$(curl -s ifconfig.me):8080/vnc.html"
echo "========================================================="
