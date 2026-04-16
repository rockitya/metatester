#!/bin/bash

# Exit script on any error
set -e

# Hardcoded Links provided by the user
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. Installing Core Dependencies & Wine"
echo "=================================================="
sudo dpkg --add-architecture i386
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget curl tar unzip xvfb x11vnc novnc websockify \
    fluxbox wine64 wine32

echo "=================================================="
echo "2. Downloading & Extracting Intel SDE (AVX Support)"
echo "=================================================="
SDE_TAR="sde-external.tar.xz"
wget -O "$SDE_TAR" "$SDE_URL"

mkdir -p sde_folder
tar -xf "$SDE_TAR" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

echo "=================================================="
echo "3. Downloading MetaTester64 Application"
echo "=================================================="
APP_EXE="metatester64.exe"
wget -O "$APP_EXE" "$APP_URL"

echo "=================================================="
echo "4. Setting up Virtual Display & noVNC"
echo "=================================================="
# Clean up previous sessions
killall xvfb x11vnc websockify fluxbox 2>/dev/null || true

# Start Virtual Display (1280x720)
Xvfb :0 -screen 0 1280x720x24 &
export DISPLAY=:0
sleep 3

# Start Window Manager & VNC
fluxbox &
x11vnc -display :0 -nopw -listen localhost -xkb -forever &
sleep 3

# Start noVNC Bridge (Port 8080)
websockify --web /usr/share/novnc/ 8080 localhost:5900 &

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://localhost:8080/vnc.html"
echo "========================================================="

echo "=================================================="
echo "5. Launching MetaTester64 via SDE (Emulating AVX)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEARCH=win64

# Run with -hsw (Haswell) to ensure AVX/AVX2 instructions are available
"$SDE_BIN" -hsw -- wine "$APP_EXE"
