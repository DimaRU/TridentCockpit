set -e
# Setup vars
GATEWAYIF=wlan0
EXPOSEIF=eth0
GATEWAYIP=$(ip address show dev $GATEWAYIF | grep "inet " | awk '{print $2}' | cut -d/ -f1)
TARGETIP=$(ip route ls | grep default | awk '{print $3}')

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
sudo ip addr del $EXPOSEIP/24 dev $EXPOSEIF || true

# Provision
sudo iptables -t nat -A trident_cockpit_pre -d $EXPOSEIP -j DNAT --to-destination $TARGETIP
sudo iptables -t nat -A trident_cockpit_post -d $TARGETIP -j SNAT --to-source $GATEWAYIP

sudo iptables -t nat -A trident_cockpit_pre -d $GATEWAYIP -j DNAT --to-destination $SOURCEIP
sudo iptables -t nat -A trident_cockpit_post -d $SOURCEIP -j SNAT --to-source $EXPOSEIP

sudo iptables -A trident_cockpit_out -s $EXPOSEIP -j DROP
sudo iptables -A trident_cockpit_out -s $GATEWAYIP -j DROP

sudo iptables -t nat -I PREROUTING -j trident_cockpit_pre
sudo iptables -t nat -I POSTROUTING -j trident_cockpit_post
sudo iptables -I OUTPUT -j trident_cockpit_out

sudo ip addr add $EXPOSEIP/24 dev $EXPOSEIF

echo "OK-SCRIPT"
