#!/bin/bash
# Conduit Desktop — VNC entrypoint
# Demarre Xvfb (ecran virtuel) + openbox (window manager) + x11vnc + noVNC
# pour utiliser Conduit dans le navigateur.
set -e

export DISPLAY=:99
export HOME=/home/conduit
export CONDUIT_CONFIG_DIR=/home/conduit/.config/conduit
VNC_PASSWORD="${VNC_PASSWORD:-conduit123}"
DISPLAY_WIDTH="${DISPLAY_WIDTH:-1280}"
DISPLAY_HEIGHT="${DISPLAY_HEIGHT:-800}"

mkdir -p /home/conduit/.vnc /home/conduit/.config/conduit

# Set VNC password
mkdir -p /home/conduit/.vnc
echo "$VNC_PASSWORD" | x11vnc -storepasswd /dev/stdin /home/conduit/.vnc/passwd 2>/dev/null

echo "=== Conduit Desktop — demarrage ==="

# 1. Virtual display
Xvfb :99 -screen 0 "${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}x24" -ac &
sleep 1

# 2. Window manager (pour que les fenetres aient des decorations)
openbox --sm-disable &
sleep 1

# 3. Desktop app
/opt/conduit/conduit &
APP_PID=$!
sleep 2

# 4. VNC server (partage l'ecran)
x11vnc -display :99 \
    -forever -shared -repeat \
    -passwd "$VNC_PASSWORD" \
    -rfbauth /home/conduit/.vnc/passwd \
    -rfbport 5900 \
    -bg \
    -o /tmp/x11vnc.log 2>/dev/null

# 5. Web VNC client (noVNC sert le client HTML5 sur :6080)
novnc_proxy \
    --web /usr/share/novnc \
    --vnc 127.0.0.1:5900 \
    --listen 6080 \
    > /tmp/novnc.log 2>&1 &
sleep 1

echo ""
echo "=== Conduit Desktop pret ==="
echo "    Navigateur : http://localhost:6080/vnc.html"
echo "    Mot de passe VNC : $VNC_PASSWORD"
echo "    (ou http://localhost:6080/health pour le healthcheck)"
echo ""

# Wait for conduit process
wait $APP_PID