# EZ Rustdesk server Install Script
Easy install Script for Rustdesk on linux, should work on any 64bit (some 32bit arm) debian or centos based system supporting systemd.<br>

<br>
<br>

# How to Install the server

Please setup your firewall on your server prior to running the script.<br>
If you use UFW, allow port 21115-21119 TCP and 21116 UDP or use the following commands:
```
ufw allow 21115:21119/tcp
ufw allow 21116/udp
```

****

Run the following commands:
```
wget -qO- https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/install.sh | bash
```
or

```
wget -qO install.sh https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/install.sh && chmod +x install.sh && ./install.sh
```

You choose your preferences sudo or no sudo. For no sudo do: ./install.sh --no-sudo 

No sudo/root fails most of the times. **ALWAYS USE ROOT OR SUDO**
<br>
<br>
<br>

# How to update the server (Manual)

Run the following commands:
```
wget -qO- https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/update.sh | bash
```

or

```
wget -qO update.sh https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/update.sh && chmod +x update.sh && ./update.sh
```
<br>
<br>
<br>

# How to auto update the server (on timer)

Run the following commands:
```
sudo wget -qO- https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/auto-update.sh | bash
```

***It checks for update every Sunday at 2 AM***

**You need ROOT OR SUDO for auto-update to work**
<br>
<br>
<br>

# How to uninstall the server

```
wget -qO- https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/uninstall.sh | bash
```

or

```
wget -qO uninstall.sh https://raw.githubusercontent.com/adayatechh/rustdeskinstall/main/uninstall.sh && chmod +x uninstall.sh && ./uninstall.sh
```
<br>
<br>
<br>

# Tips

If you want to restart the services use the following commands:
```
sudo systemctl restart rustdesksignal
sudo systemctl restart rustdeskrelay
```

<br>

If you want to check the status of the server use the following commands:

```
sudo systemctl status rustdesksignal
sudo systemctl status rustdeskrelay
```

<br>

If you want to check the status of the Auto Update Timer use the following commands:

```
systemctl list-timers | grep rustdesk
```

<br>

If you want to check the logs for Auto Update use the following commands:

<br>

```
journalctl -u rustdesk-update.service
```

<br>

****

**Credit:**

Based on the original project by @techahold
