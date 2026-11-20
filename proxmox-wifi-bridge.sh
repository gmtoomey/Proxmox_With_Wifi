# Proxmox 9 host: share the host's Wi-Fi uplink (wlp2s0) to vmbr0 WITHOUT NAT.
#   - parprouted   : proxy-ARP routing between vmbr0 and Wi-Fi
#   - dhcp-helper  : relays VM DHCP requests to the upstream router (NF17ACV)
#   - udpbroadcastrelay : relays WS-Discovery so Windows can see Samba shares
#
# Run AFTER editing /etc/network/interfaces so vmbr0 has no IPv4 address
# (iface vmbr0 inet manual) and running `ifreload -a`.
#
# Usage:  sudo ./proxmox-wifi-bridge.sh
# Optional overrides: WIFI=wlp2s0 ETH=vmbr0

set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run as root."; exit 1; }

WIFI="${WIFI:-wlp2s0}"
ETH="${ETH:-vmbr0}"

[ -d "/sys/class/net/$WIFI" ] || { echo "Interface $WIFI not found."; exit 1; }
[ -d "/sys/class/net/$ETH" ]  || { echo "Interface $ETH not found."; exit 1; }

# vmbr0 must not keep its own address inside the Wi-Fi subnet (overlapping /16 routes).
if ip -4 -o addr show dev "$ETH" | awk '{print $4}' | grep -qv '/32$'; then
  echo "ERROR: $ETH still has an IPv4 address:"
  ip -4 -o addr show dev "$ETH"
  echo "Edit /etc/network/interfaces so vmbr0 is 'iface vmbr0 inet manual' (no address),"
  echo "run 'ifreload -a', then re-run this script."
  exit 1
fi

[ -x /usr/local/sbin/udpbroadcastrelay ] || { echo "/usr/local/sbin/udpbroadcastrelay not found."; exit 1; }
for p in parprouted dhcp-helper; do
  dpkg -s "$p" >/dev/null 2>&1 || { echo "Package $p not installed."; exit 1; }
done

# ---------- Forwarding (no NAT anywhere) ----------
cat > /etc/sysctl.d/99-wifi-eth-bridge.conf <<EOF
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=2
net.ipv4.conf.default.rp_filter=2
EOF
sysctl --system >/dev/null

# ---------- Proxy-ARP routing service ----------
cat > /etc/default/wifi-eth-bridge <<EOF
WIFI=$WIFI
ETH=$ETH
EOF

cat > /usr/local/sbin/wifi-eth-bridge.sh <<'EOF'
#!/bin/sh
# shellcheck disable=SC1091
. /etc/default/wifi-eth-bridge
IP=""
for i in $(seq 1 60); do
  IP=$(ip -4 -o addr show dev "$WIFI" | awk '{print $4}' | cut -d/ -f1 | head -n1)
  [ -n "$IP" ] && break
  sleep 1
done
[ -z "$IP" ] && exit 1
ip link set "$ETH" up
# Let multicast (WS-Discovery) reach every VM port on the bridge
[ -w "/sys/class/net/$ETH/bridge/multicast_snooping" ] && echo 0 > "/sys/class/net/$ETH/bridge/multicast_snooping"
# Per-interface forwarding on the bridge can be 0 even when ip_forward=1; without it the host drops VM traffic
echo 1 > "/proc/sys/net/ipv4/conf/$ETH/forwarding"
ip addr replace "$IP/32" dev "$ETH"
# Send dhcp-helper's replies to clients (UDP 67 -> 68) out the bridge, not the Wi-Fi
NET=$(ip -4 route show dev "$WIFI" proto kernel scope link | awk '{print $1}' | head -n1)
[ -z "$NET" ] && NET=192.168.0.0/16
ip route replace "$NET" dev "$ETH" table 100
while ip rule del pref 100 2>/dev/null; do :; done
ip rule add pref 100 ipproto udp sport 67 dport 68 lookup 100
exec /usr/sbin/parprouted "$ETH" "$WIFI"
EOF
chmod +x /usr/local/sbin/wifi-eth-bridge.sh

cat > /etc/systemd/system/wifi-eth-bridge.service <<'EOF'
[Unit]
Description=Proxy-ARP routing between vmbr0 and Wi-Fi (no NAT)
After=networking.service network-online.target
Wants=network-online.target

[Service]
Type=forking
GuessMainPID=yes
TimeoutStartSec=120
ExecStart=/usr/local/sbin/wifi-eth-bridge.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------- DHCP relay (VMs -> upstream router) ----------
cat > /etc/default/dhcp-helper <<EOF
DHCPHELPER_OPTS="-b $WIFI -i $ETH"
EOF

mkdir -p /etc/systemd/system/dhcp-helper.service.d
cat > /etc/systemd/system/dhcp-helper.service.d/override.conf <<'EOF'
[Unit]
After=wifi-eth-bridge.service
Wants=wifi-eth-bridge.service
StartLimitIntervalSec=0

[Service]
Restart=on-failure
RestartSec=5
EOF

# ---------- WS-Discovery relay ----------
cat > /etc/systemd/system/wsd-relay.service <<EOF
[Unit]
Description=Relay WS-Discovery multicast between $ETH and Wi-Fi
After=wifi-eth-bridge.service
Wants=wifi-eth-bridge.service

[Service]
ExecStart=/usr/local/sbin/udpbroadcastrelay --id 1 --port 3702 --dev $ETH --dev $WIFI --multicast 239.255.255.250
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------- LLMNR relay (lets Windows resolve \\HOSTNAME for VMs behind the bridge) ----------
cat > /etc/systemd/system/llmnr-relay.service <<EOF
[Unit]
Description=Relay LLMNR multicast between $ETH and Wi-Fi
After=wifi-eth-bridge.service
Wants=wifi-eth-bridge.service

[Service]
ExecStart=/usr/local/sbin/udpbroadcastrelay --id 2 --port 5355 --dev $ETH --dev $WIFI --multicast 224.0.0.252
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---------- mDNS relay (lets Avahi/Linux file managers see SMB hosts behind the bridge) ----------
cat > /etc/systemd/system/mdns-relay.service <<EOF
[Unit]
Description=Relay mDNS multicast between $ETH and Wi-Fi
After=wifi-eth-bridge.service
Wants=wifi-eth-bridge.service

[Service]
ExecStart=/usr/local/sbin/udpbroadcastrelay --id 3 --port 5353 --dev $ETH --dev $WIFI --multicast 224.0.0.251
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wifi-eth-bridge.service dhcp-helper.service wsd-relay.service llmnr-relay.service mdns-relay.service
systemctl restart wifi-eth-bridge.service
sleep 5
systemctl restart dhcp-helper.service
systemctl restart wsd-relay.service
systemctl restart llmnr-relay.service
systemctl restart mdns-relay.service
sleep 2

echo
echo "=== Status ==="
systemctl --no-pager --lines=3 status wifi-eth-bridge dhcp-helper wsd-relay llmnr-relay mdns-relay || true
echo
ip -4 addr show dev "$ETH"
echo
echo "Next: give the Wi-Fi MAC a DHCP reservation on the router, check the Proxmox"
echo "firewall is off for this bridge, start a VM on $ETH set to DHCP, and reboot once"
echo "to confirm everything comes up in order."
