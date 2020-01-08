set -e
# Cleanup
sudo iptables -t nat -N trident_cockpit_pre || true
sudo iptables -t nat -N trident_cockpit_post || true
sudo iptables -N trident_cockpit_out || true
sudo iptables -t nat -F trident_cockpit_pre
sudo iptables -t nat -F trident_cockpit_post
sudo iptables -F trident_cockpit_out
sudo iptables -t nat -D PREROUTING -j trident_cockpit_pre || true
sudo iptables -t nat -D POSTROUTING -j trident_cockpit_post || true
sudo iptables -D OUTPUT -j trident_cockpit_out || true

echo "OK-SCRIPT"
