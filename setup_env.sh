#!/bin/bash
# 1. SCORCHED EARTH - CLEANUP
echo "🧹 Wiping old files and processes..."
killall -9 qemu-x86_64 wine64 wineserver Xvfb x11vnc websockify 2>/dev/null || true
rm -rf /root/.wine /root/wine-dist /root/qemu* /root/metatester64.exe /root/*.log
rm -rf /tmp/.X* /tmp/.wine-* /tmp/.X11-unix/*
for i in {1..8}; do systemctl disable --now MetaTester-$i 2>/dev/null; rm -f /etc/systemd/system/MetaTester-$i.service; done
systemctl daemon-reload

# 2. FAST DEPENDENCY INSTALL (SSL & Graphics)
echo "📦 Installing essential networking and display tools..."
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q xvfb x11vnc python3-websockify libgnutls30:amd64 libgnutls30:i386 wget curl

# 3. DOWNLOAD PRE-COMPILED TOOLS
cd /root
echo "📥 Downloading Wine 9.0 and QEMU Static..."
wget -q https://github.com/Kron4ek/Wine-Builds/releases/download/9.0/wine-9.0-amd64-wow64.tar.xz
tar -xf wine-9.0-amd64-wow64.tar.xz
wget -q -O qemu-x86_64 https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-x86_64-static
chmod +x qemu-x86_64

# 4. INITIALIZE WINE AS WINDOWS 10 (Required for Cloud Tab)
export DISPLAY=:77
export WINEPREFIX="/root/.wine"
WINE_BIN="/root/wine-9.0-amd64-wow64/bin/wine64"
QEMU_BIN="/root/qemu-x86_64"

echo "⚙️ Setting up Windows 10 environment..."
Xvfb :77 -screen 0 1280x800x24 &
sleep 3
$QEMU_BIN -L / $WINE_BIN winecfg /v win10 > /dev/null 2>&1

# 5. START VNC AND WEBSOCKET
echo "🖥️ Starting VNC on port 8080..."
x11vnc -display :77 -nopw -listen localhost -forever -quiet &
/usr/bin/python3 /usr/bin/websockify --web /usr/share/novnc 8080 localhost:5900 &

# 6. DOWNLOAD AND LAUNCH METATESTER
echo "🚀 Launching MetaTester..."
wget -q https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/metatester64.exe
nohup $QEMU_BIN -L / -cpu Skylake-Client $WINE_BIN /root/metatester64.exe /portable > /root/mt5.log 2>&1 &

echo "✅ SETUP COMPLETE!"
echo "👉 Go to: http://$(curl -s ifconfig.me):8080/vnc_lite.html"
