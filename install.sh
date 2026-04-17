#!/bin/bash

# Get user options
help=""
usesudo="true"

for arg in "$@"; do
    case "$arg" in
        --help)   help="true" ;;
        --no-sudo) usesudo="false" ;;
    esac
done

function displayhelp() {
    if [[ -n "$help" ]]; then
        echo 'usage: install.sh [--no-sudo]'
        echo "options:"
        echo "--no-sudo    Do not use sudo for commands."
        exit 0
    fi
}
displayhelp

# Default: use sudo unless --no-sudo is specified
usesudo="${usesudo:-true}"

# Check if sudo is available and wanted
if [[ "$usesudo" == "true" ]]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
        echo "sudo detected and will be used."
    else
        echo "sudo not found. Switching to no-sudo mode."
        SUDO=""
        echo "Some installation steps may fail if run without root privileges."
    fi
else
    SUDO=""
    echo "Running in no-sudo mode."
    echo "Some installation steps may fail if run without root privileges."
fi

# Get Username
uname=$(whoami)
gname=$(id -gn ${uname})
admintoken=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)

ARCH=$(uname -m)

# identify OS
if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID

    UPSTREAM_ID=${ID_LIKE,,}

    # Fallback to ID_LIKE if ID was not 'ubuntu' or 'debian'
    if [ "${UPSTREAM_ID}" != "debian" ] && [ "${UPSTREAM_ID}" != "ubuntu" ]; then
        UPSTREAM_ID="$(echo "${ID_LIKE,,}" | sed 's/"//g' | cut -d' ' -f1)"
    fi


elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    OS=SuSE
    VER=$(cat /etc/SuSe-release)
elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    OS=RedHat
    VER=$(cat /etc/redhat-release)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
fi


# output debugging info if $DEBUG set
if [ "$DEBUG" = "true" ]; then
    echo "OS: $OS"
    echo "VER: $VER"
    echo "UPSTREAM_ID: $UPSTREAM_ID"
    exit 0
fi

# Setup prereqs for server
# common named prereqs
PREREQ="curl wget unzip tar"
PREREQDEB="dnsutils"
PREREQRPM="bind-utils"
PREREQARCH="bind"

echo "Installing prerequisites"
if [ "${ID}" = "debian" ] || [ "$OS" = "Ubuntu" ] || [ "$OS" = "Debian" ]  || [ "${UPSTREAM_ID}" = "ubuntu" ] || [ "${UPSTREAM_ID}" = "debian" ]; then
    $SUDO apt-get update
    $SUDO apt-get install -y  ${PREREQ} ${PREREQDEB} # git
elif [ "$OS" = "CentOS" ] || [ "$OS" = "RedHat" ]   || [ "${UPSTREAM_ID}" = "rhel" ] ; then
# opensuse 15.4 fails to run the relay service and hangs waiting for it
# needs more work before it can be enabled
# || [ "${UPSTREAM_ID}" = "suse" ]
    $SUDO yum update -y
    $SUDO yum install -y  ${PREREQ} ${PREREQRPM} # git
elif [ "${ID}" = "arch" ] || [ "${UPSTREAM_ID}" = "arch" ]; then
    $SUDO pacman -Syu
    $SUDO pacman -S ${PREREQ} ${PREREQARCH}
else
    echo "Unsupported OS"
    # give them the option to continue
    echo -n "Would you like to continue? Dependencies may not be satisfied... [y/n] "
    read continue_no_dependencies
    if [ $continue_no_dependencies == "y" ]; then
        echo "Continuing..."
    elif [ $continue_no_dependencies != "n" ]; then
        echo "Invalid answer, exiting."
	exit 1
    else
        exit 1
    fi
fi

# Make Folder /opt/rustdesk/
if [ ! -d "/opt/rustdesk" ]; then
    echo "Creating /opt/rustdesk"
    $SUDO mkdir -p /opt/rustdesk/
fi
$SUDO chown "${uname}" -R /opt/rustdesk
cd /opt/rustdesk/ || exit 1


#Download latest version of Rustdesk
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name" | awk -F'"' '{print $4}')

echo "Installing Rustdesk Server"
if [ "${ARCH}" = "x86_64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip"
unzip rustdesk-server-linux-amd64.zip
mv amd64/* /opt/rustdesk/
elif [ "${ARCH}" = "armv7l" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip"
unzip rustdesk-server-linux-armv7.zip
mv armv7/* /opt/rustdesk/
elif [ "${ARCH}" = "aarch64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip"
unzip rustdesk-server-linux-arm64v8.zip
mv arm64v8/* /opt/rustdesk/
fi

chmod +x /opt/rustdesk/hbbs
chmod +x /opt/rustdesk/hbbr

# Make Folder /var/log/rustdesk/
if [ ! -d "/var/log/rustdesk" ]; then
    echo "Creating /var/log/rustdesk"
    $SUDO mkdir -p /var/log/rustdesk/
fi
$SUDO chown "${uname}" -R /var/log/rustdesk/

# Setup Systemd to launch hbbs
rustdesksignal="$(cat << EOF
[Unit]
Description=Rustdesk Signal Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/rustdesk/hbbs
WorkingDirectory=/opt/rustdesk/
User=${uname}
Group=${gname}
Restart=always
StandardOutput=append:/var/log/rustdesk/signalserver.log
StandardError=append:/var/log/rustdesk/signalserver.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdesksignal}" | $SUDO tee /etc/systemd/system/rustdesksignal.service > /dev/null
$SUDO systemctl daemon-reload
$SUDO systemctl enable rustdesksignal.service
$SUDO systemctl start rustdesksignal.service

# Setup Systemd to launch hbbr
rustdeskrelay="$(cat << EOF
[Unit]
Description=Rustdesk Relay Server
[Service]
Type=simple
LimitNOFILE=1000000
ExecStart=/opt/rustdesk/hbbr
WorkingDirectory=/opt/rustdesk/
User=${uname}
Group=${gname}
Restart=always
StandardOutput=append:/var/log/rustdesk/relayserver.log
StandardError=append:/var/log/rustdesk/relayserver.error
# Restart service after 10 seconds if node service crashes
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
)"
echo "${rustdeskrelay}" | $SUDO tee /etc/systemd/system/rustdeskrelay.service > /dev/null
$SUDO systemctl daemon-reload
$SUDO systemctl enable rustdeskrelay.service
$SUDO systemctl start rustdeskrelay.service

while ! [[ $CHECK_RUSTDESK_READY ]]; do
  CHECK_RUSTDESK_READY=$($SUDO systemctl status rustdeskrelay.service | grep "Active: active (running)")
  echo "Rustdesk Relay not ready yet..."
  sleep 3
done

pubname=$(find /opt/rustdesk -name "*.pub")
key=$(cat "${pubname}")

echo "Tidying up install"
if [ "${ARCH}" = "x86_64" ] ; then
rm rustdesk-server-linux-amd64.zip
rm -rf amd64
elif [ "${ARCH}" = "armv7l" ] ; then
rm rustdesk-server-linux-armv7.zip
rm -rf armv7
elif [ "${ARCH}" = "aarch64" ] ; then
rm rustdesk-server-linux-arm64v8.zip
rm -rf arm64v8
fi

echo
echo "Your public key is:"
echo "---------------------------------------------------------"
echo "${key}"
echo "---------------------------------------------------------"
echo
echo "RustDesk Server has been installed, Enjoy!"
echo
