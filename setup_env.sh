#!/bin/bash

# Exit script on any error
set -e

# Hardcoded Links
SDE_URL="https://archive.org/download/sde-external-tar/sde-external-tar.xz"
APP_URL="https://archive.org/download/metatester64/metatester64.exe"

echo "=================================================="
echo "1. Disabling Firewalls & Clearing Locks"
echo "=================================================="
(sudo ufw disable || true)
sudo iptables -F
sudo killall apt apt-get dpkg 2>/dev/null || true
sudo rm -f /var/lib/apt/lists/lock /var/lib/dpkg/lock*

echo "=================================================="
echo "2. Installing Minimal Dependencies"
echo "=================================================="
sudo dpkg --add-architecture i386
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget curl tar xz-utils xvfb x11vnc novnc websockify fluxbox \
    wine64 wine32 libwine libwine:i386

echo "=================================================="
echo "3. Downloading & Extracting Intel SDE"
echo "=================================================="
SDE_TAR="sde-external.tar.xz"
if [ ! -f "$SDE_TAR" ]; then
    wget -q --show-progress -O "$SDE_TAR" "$SDE_URL"
fi

mkdir -p sde_folder
tar -xf "$SDE_TAR" -C sde_folder --strip-components=1
SDE_BIN="$(pwd)/sde_folder/sde64"

echo "=================================================="
echo "4. Downloading MetaTester64"
echo "=================================================="
APP_EXE="metatester64.exe"
wget -q --show-progress -O "$APP_EXE" "$APP_URL"

echo "=================================================="
echo "5. Starting Virtual Display & noVNC"
echo "=================================================="
killall -9 xvfb x11vnc websockify fluxbox wine 2>/dev/null || true

# Initialize Virtual Display
Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0
sleep 3

# Start Window Manager
fluxbox &
sleep 2

# Start VNC Server (Passwordless)
x11vnc -display :0 -nopw -listen localhost -forever -quiet &
sleep 2

# Link noVNC for easy access
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
websockify --D --web /usr/share/novnc/ 8080 localhost:5900

echo "========================================================="
echo "✅ SETUP COMPLETE!"
echo "🌐 BROWSER LINK: http://YOUR_SERVER_IP:8080/"
echo "========================================================="

echo "=================================================="
echo "6. Launching MetaTester via SDE (AVX Emulation)"
echo "=================================================="
export WINEPREFIX="$(pwd)/.wine"
export WINEDEBUG=-all
export DISPLAY=:0

# Disable Wine's crash dialogs and auto-installers to prevent blank screens
wine reg add "HKEY_CURRENT_USER\Software\Wine\WineDbg" /v ShowCrashDialog /t REG_DWORD /d 0 /f || true

# Launch with Haswell (AVX/AVX2) emulation
# Using 'sde' to run 'wine' ensures the app sees AVX support
"$SDE_BIN" -hsw -- wine "$APP_EXE"
