#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export DISPLAY=:77

echo "=================================================="
echo "⚡ 1. CLEANING LOCKS & ZOMBIE PROCESSES"
echo "=================================================="
systemctl stop unattended-upgrades 2>/dev/null || true
pkill -9 Xvfb
killall -9 Xvfb xvfb x11vnc websockify wine wine64 sde64 apt apt-get dpkg 2>/dev/null || true
rm -rf /tmp/.X* /tmp/.lock* /var/lib/apt/lists/lock /var/lib/dpkg/lock*
rm -rf /root/.wine /root/wine-dist

echo "=================================================="
echo "⚡ 2. INSTALLING DEPENDENCIES (INCLUDING UNZIP)"
echo "=================================================="
apt-get update -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    xvfb x11vnc websockify curl tar xz-utils unzip

echo "=================================================="
echo "⚡ 3. WINE 9.0 PURE 64-BIT (NO 32-BIT TRAPS)"
echo "=================================================="
if [ ! -d "wine-dist" ]; then
    echo "Downloading Wine..."
    curl -L "https://archive.org/download/wine-9.0-amd64.tar/wine-9.0-amd64.tar.xz" | tar xJ -C . 
    mv wine-9.0-amd64 wine-dist
fi
WINE_BIN="$(pwd)/wine-dist/bin/wine64"

echo "=================================================="
echo "⚡ 4. UNZIPPING METATESTER (10MB ZIP)"
echo "=================================================="
# Download and unzip the Archive.org zip
curl -L -o metatester.zip "https://archive.org/compress/metatester64"
unzip -o metatester.zip
# Move the exe to root in case it's in a subfolder
find . -name "metatester64.exe" -exec mv {} . \;

echo "=================================================="
echo "⚡ 5. PRE-INSTALLING WINE MONO (SILENT)"
echo "=================================================="
export WINEPREFIX="/root/.wine"
# Pre-create the wine prefix
$WINE_BIN wineboot -u
sleep 5
# Download and install Mono so the popup doesn't block the emulator
curl -L -o wine-mono.msi "https://dl.winehq.org/wine/wine-mono/8.1.0/wine-mono-8.1.0-x86.msi"
$WINE_BIN msiexec /i wine-mono.msi /qn
sleep 5

echo "=================================================="
echo "⚡ 6. STARTING DISPLAY & NOVNC"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    curl -L -s https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
fi

Xvfb :77 -screen 0 1024x768x16 &
sleep 3
x11vnc -display :77 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "=================================================="
echo "⚡ 7. LAUNCHING METATESTER VIA SDE (SKYLAKE)"
echo "=================================================="
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder
    curl -L "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
fi

# Final Launch Command using Skylake (-skx) for best compatibility
nohup /root/sde_folder/sde64 -skx -- $WINE_BIN explorer /desktop=Meta,1024x768 metatester64.exe > debug.log 2>&1 &

echo "========================================================="
echo "✅ ALL-IN-ONE SETUP COMPLETE!"
echo "🌐 BROWSER: http://$(curl -s ifconfig.me):8080/vnc_lite.html"
echo "========================================================="
