#!/bin/bash

set -e

URL="https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/update.sh"
TARGET_DIR="/opt/rustdesk"
TARGET_FILE="$TARGET_DIR/update.sh"

SERVICE_FILE="/etc/systemd/system/rustdesk-update.service"
TIMER_FILE="/etc/systemd/system/rustdesk-update.timer"

# -----------------------------
# Require root
# -----------------------------
if [ "$EUID" -ne 0 ]; then
    echo "Error: run as root or sudo."
    exit 1
fi

# -----------------------------
# Check install exists
# -----------------------------
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: RustDesk not installed."
    echo "Please run install.sh first."
    exit 1
fi

# -----------------------------
# Download update script
# -----------------------------
echo "Downloading update.sh..."
curl -fsSL "$URL" -o "$TARGET_FILE"
chmod +x "$TARGET_FILE"

# -----------------------------
# Create systemd service
# -----------------------------
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=RustDesk Weekly Update Script

[Service]
Type=oneshot
ExecStart=$TARGET_FILE
EOF

# -----------------------------
# Create systemd timer
# -----------------------------
cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Run RustDesk update every Sunday at 2 AM

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# -----------------------------
# Enable timer
# -----------------------------
systemctl daemon-reload
systemctl enable --now rustdesk-update.timer
echo "---------------------------------------------------------"
echo "Check for update every Sunday at 2 AM"
echo "RustDesk auto update installed successfully."
echo
