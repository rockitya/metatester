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
echo "⚡ 2. INSTALLING TOOLS (ADDING UNZIP)"
echo "=================================================="
apt-get update -y -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
    xvfb x11vnc websockify curl tar xz-utils unzip

echo "=================================================="
echo "⚡ 3. DOWNLOADING PURE 64-BIT WINE"
echo "=================================================="
if [ ! -d "wine-dist" ]; then
    echo "Downloading Wine 9.0 (Pure 64-bit)..."
    mkdir -p wine-dist
    # Direct stream download
    curl -L "https://archive.org/download/wine-9.0-amd64.tar/wine-9.0-amd64.tar.xz" | tar xJ -C wine-dist --strip-components=1
fi
WINE_BIN="$(pwd)/wine-dist/bin/wine64"

echo "=================================================="
echo "⚡ 4. DOWNLOADING SDE & METATESTER (ZIP)"
echo "=================================================="
# Download Intel SDE
if [ ! -d "sde_folder" ]; then
    mkdir -p sde_folder
    curl -L "https://archive.org/download/sde-external-tar/sde-external-tar.xz" | tar xJ -C sde_folder --strip-components=1
fi

# Download and Unzip MetaTester
echo "Fetching 10MB MetaTester Zip..."
curl -L -o metatester.zip "https://archive.org/compress/metatester64"
unzip -o metatester.zip
# Ensure the file is named correctly for the launch command
mv metatester64.exe metatester_final.exe 2>/dev/null || mv *.exe metatester_final.exe

echo "=================================================="
echo "⚡ 5. SETTING UP NOVNC"
echo "=================================================="
if [ ! -d "noVNC" ]; then
    curl -L -s https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz | tar xz
    mv noVNC-1.4.0 noVNC
fi

echo "=================================================="
echo "⚡ 6. STARTING VIRTUAL DISPLAY (:77)"
echo "=================================================="
Xvfb :77 -screen 0 1024x768x16 &
sleep 3
x11vnc -display :77 -nopw -listen localhost -forever -quiet &
./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

echo "=================================================="
echo "⚡ 7. LAUNCHING VIA SDE (SKYLAKE FLAG)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"

# Pre-boot Wine
$WINE_BIN wineboot -u
sleep 5

# Launch the REAL 10MB binary using the stable Skylake flag
nohup ./sde_folder/sde64 -skx -- $WINE_BIN metatester_final.exe > debug.log 2>&1 &

echo "========================================================="
echo "✅ SUCCESS! "
echo "🌐 BROWSER: http://$(curl -s ifconfig.me):8080/vnc_lite.html"
echo "========================================================="
