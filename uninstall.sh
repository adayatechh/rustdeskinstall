#!/bin/bash

echo "Stopping and disabling RustDesk services..."

# Stop and disable services
sudo systemctl stop rustdesksignal.service 2>/dev/null
sudo systemctl stop rustdeskrelay.service 2>/dev/null
sudo systemctl stop rustdesk-update.service 2>/dev/null
sudo systemctl stop rustdesk-update.timer 2>/dev/null

sudo systemctl disable rustdesksignal.service 2>/dev/null
sudo systemctl disable rustdeskrelay.service 2>/dev/null
sudo systemctl disable rustdesk-update.service 2>/dev/null
sudo systemctl disable rustdesk-update.timer 2>/dev/null

# Remove service files
sudo rm -f /etc/systemd/system/rustdesksignal.service
sudo rm -f /etc/systemd/system/rustdeskrelay.service
sudo rm -f /etc/systemd/system/rustdesk-update.service
sudo rm -f /etc/systemd/system/rustdesk-update.timer

# Reload systemd
sudo systemctl daemon-reload

echo "Removing RustDesk binaries and logs..."

# Remove binaries and logs
sudo rm -rf /opt/rustdesk
sudo rm -rf /var/log/rustdesk

echo
echo "-------------------------"
echo "RustDesk server has been completely unistalled."
echo "-------------------------"
echo "Don't forget to clean up any firewall/NAT rules if needed."
