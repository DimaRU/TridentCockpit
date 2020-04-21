#
# PayloadCleanup.sh
# Copyright (c) 2020 Dmitriy Borovikov. All rights reserved.
#
set -e
# Cleanup
sudo iptables-legacy -t nat -N trident_cockpit_pre || true
sudo iptables-legacy -t nat -N trident_cockpit_post || true
sudo iptables-legacy -N trident_cockpit_out || true
sudo iptables-legacy -t nat -F trident_cockpit_pre
sudo iptables-legacy -t nat -F trident_cockpit_post
sudo iptables-legacy -F trident_cockpit_out
sudo iptables-legacy -t nat -D PREROUTING -j trident_cockpit_pre || true
sudo iptables-legacy -t nat -D POSTROUTING -j trident_cockpit_post || true
sudo iptables-legacy -D OUTPUT -j trident_cockpit_out || true

echo "OK-SCRIPT"
