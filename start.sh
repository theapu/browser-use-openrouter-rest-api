#!/bin/bash

# CLEANUP: Remove lock files if Xvfb crashed or container was stopped abruptly
# This fixes the "(EE) Server is already active for display 99" error
rm -f /tmp/.X99-lock
rm -f /tmp/.X11-unix/X99

# 1. Start Xvfb (Virtual Framebuffer) - This mimics a monitor
# Screen 0 with resolution 1920x1080 and 24-bit color
Xvfb :99 -screen 0 1920x1080x24 &

# Wait a split second to ensure Xvfb is up before starting managers
sleep 1

# 2. Start Fluxbox (Window Manager)
# Redirect stderr to /dev/null to silence "Failed to read" warnings
fluxbox >/dev/null 2>&1 &

# 3. Start x11vnc - Exposes the display :99 on port 5900
# -forever: Keep listening after disconnect
# -nopw: No password required (for simplicity)
x11vnc -display :99 -forever -nopw -listen 0.0.0.0 -xkb &

# 4. Set the DISPLAY environment variable so applications know where to draw
export DISPLAY=:99

# 5. Start the Python Application
exec uvicorn main:app --host 0.0.0.0 --port 8000
