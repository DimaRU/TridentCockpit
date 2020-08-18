#
# PayloadPovision.sh
# Copyright (c) 2020 Dmitriy Borovikov. All rights reserved.
#
set -e
# Setup vars
GATEWAYIF=wlan0
EXPOSEIF=eth0
GATEWAYIP=$(ip address show dev $GATEWAYIF | grep "inet " | awk '{print $2}' | cut -d/ -f1)
TARGETIP=$(ip route ls | grep "default.*wlan0" | awk '{print $3}')

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

# Provision
for PORT in "${REDIRECTPORTS[@]}"
do
  echo "${PORT} $BASEPORT"
  sudo iptables-legacy -t nat -A trident_cockpit_pre -i $EXPOSEIF -p tcp --dport $BASEPORT -j DNAT --to-destination $TARGETIP:$PORT
  ((BASEPORT++))
done
sudo iptables-legacy -t nat -A trident_cockpit_post -d $TARGETIP -j SNAT --to-source $GATEWAYIP
sudo iptables-legacy -A trident_cockpit_out -p icmp -j ACCEPT
sudo iptables-legacy -A trident_cockpit_out -s $GATEWAYIP -j DROP

sudo iptables-legacy -t nat -I PREROUTING -j trident_cockpit_pre
sudo iptables-legacy -t nat -I POSTROUTING -j trident_cockpit_post
sudo iptables-legacy -I OUTPUT -j trident_cockpit_out

echo "OK-SCRIPT"
