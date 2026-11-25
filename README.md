# Proxmox_With_Wifi
##Overview Create a Proxmox server with Wifi

In this guide we add wifi to to a Proxmox server. This guide uses regular linux routing rather than NAT. DHCP and SAMBA are supported. NFS works with no changes.


SAMBA is supported. This allows a VM to install Samba and shares are visible to windows machines. This does not replace WSDD or WSDD2; they needed like any regular Samba installation.


# Glossary

| Term | Meaning |
| --- | --- |
| NAT | Network Address Translation. Not used here. |
| SAMBA | Allows Linux to share files with Windows computers using the Server Message Block (SMB) protocol   |
| parprouted deamon |  transparent IPv4 (Layer 3) proxy ARP bridging across network interfaces  |
| dhcp-helper deamon | relays VM DHCP requests to the upstream router |
| udpbroadcastrelay deamon |  listens for UDP broadcast or multicast packets on a specified port and retransmits them across other network interfaces. Used to relays WS-Discovery so Windows can see Samba shares |
| Wifi router | upstream Wifi router from your Proxmox machine  |
| Wifi device | wifi device connected to Proxmox machine  |





# Presequisites

The basic requirements are a an x86 computer, Proxmox 9.2 or above, and a wifi adaptor, and a wifi router. 

##Recommended Wifi Devices

Proxmox VE 9.2 uses a  7.0 Linux kernel with in-tree Linux kernel drivers for modern wifi6 and wifi7 devices. An-tree Linux kernel driver and pre-installed firmware supports the following chipsets:


### Supported chipset families with Proxmox 9.2

Most modern PCIe, M.2, and USB wireless adapters are directly supported. Proxmox9.2 firmware for these devices is included in [pve-firmware](https://pve.proxmox.com/wiki/Firmware_Updates).

Intel (iwlwifi driver). Most Intel PCIe and M.2 cards work natively, including the AX200 , AX20, AX210, AX211, BE200, BE202, and older AC 7260/8260/9260 series.

MediaTek (mt76 / mt7921e / mt7921u / mt7925 driver). Wi-Fi 6, 6E, and 7 chipsets—such as the MT7921, MT7922, MT7925, and USB MT7612U—have mainline support and firmware included in the default pve-firmware bundle.
 
Qualcomm Atheros (ath9k / ath10k / ath11k / ath12k driver). Older 802.11n (ath9k, which requires no external firmware) and newer Wi-Fi 5/6/7 chipsets (QCA6174, QCA988x, WCN6855, WCN7850) work without extra driver compilation.

Realtek (rtw88 / rtw89 / rtl8xxxu driver )Chipsets like RTL8821CE, RTL8822CE, RTL8852AE/BE/CE, and RTL8922AE.



# Features
#









# Installation

## Install Proxmox 
9.2 and later

## Install WPA Supplicant

There is one piece of software we need that is not included in the standard Proxmox installation.

we Will install WPA supplicant using a temporary Ethernet vsblror USB tethering from your phone. Boot these methods give your tem[prary access voa DHCP.

The first method is easiest. Just connect an Ethernet cable from your router to your Proxmox machine. Your should obtain a et

Connect Proxmox using temporary Ethernet or USB tethering from your phone.


apt update && apt install -y wpasupplicant wireless-tools


## Optional SAMBA helpers

```
ip link show
```


```
sudo apt install -y git build-essential
git clone https://github.com/marjohn56/udpbroadcastrelay
cd udpbroadcastrelay
ls
make || gcc -O2 -o udpbroadcastrelay udpbroadcastrelay.c
sudo install -m 755 udpbroadcastrelay /usr/local/sbin/
```

# Install WIFI_Ethernet Bridge.sh service

curl -O https://raw.githubusercontent.com/gmtoomey/Proxmox_With_Wifi/refs/heads/main/proxmox-wifi-bridge.sh

# Post installation tests
