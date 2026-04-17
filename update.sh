#!/bin/bash

# Get current release version
RDLATEST=$(curl https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest -s | grep "tag_name" | awk -F'\"' '{print $4}') || exit 1
RDCURRENT=$(/opt/rustdesk/hbbr --version | sed -r 's/hbbr (.*)/\1/')

if [ "$RDLATEST" = "$RDCURRENT" ]; then
    echo "Same version no need to update."
    exit 0
fi

sudo systemctl stop rustdesksignal.service
sudo systemctl stop rustdeskrelay.service

ARCH=$(uname -m)

if ! [ -e /opt/rustdesk  ]; then
        echo "No directory /opt/rustdesk found. No update of rustdesk possible (used install.sh script ?) "
        exit 4
else
        :
fi

cd /opt/rustdesk/ || exit 1

# remove any previous zip files
rm -f *.zip

echo "Upgrading Rustdesk Server"
if [ "${ARCH}" = "x86_64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-amd64.zip" || exit 1
unzip -j -o  rustdesk-server-linux-amd64.zip  "amd64/*" -d "/opt/rustdesk/" || exit 1
elif [ "${ARCH}" = "armv7l" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-armv7.zip" || exit 1
unzip -j -o  rustdesk-server-linux-armv7.zip  "armv7/*" -d "/opt/rustdesk/" || exit 1
elif [ "${ARCH}" = "aarch64" ] ; then
wget "https://github.com/rustdesk/rustdesk-server/releases/download/${RDLATEST}/rustdesk-server-linux-arm64v8.zip" || exit 1
unzip -j -o  rustdesk-server-linux-arm64v8.zip  "arm64v8/*" -d "/opt/rustdesk/" || exit 1

else
  echo "Unsupported architecture: ${ARCH}"
  exit 1
fi

# Remove leftover zips
rm -f *.zip

sudo systemctl start rustdesksignal.service
sudo systemctl start rustdeskrelay.service

while ! systemctl is-active --quiet rustdeskrelay.service || \
      ! systemctl is-active --quiet rustdesksignal.service; do
  echo "Rustdesk services not ready yet..."
  sleep 3
done

echo "----------------------------"
echo "Updates are complete"
echo
