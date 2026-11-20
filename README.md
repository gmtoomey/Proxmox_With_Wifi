# Proxmox_With_Wifi
##Create a Proxmox server with Wifi

In this guide we add wifi to to a Proxmox server. We guide uses linux routing rather than NAT to provide access to VMs . DHCP and SAMBA are supported.

# Terminology

NAT
SAMBA
Wifi router
Wifi drvice
VM

# Presequisites

The basic requirements are a an x86 computer, Proxmox 9.2 or above, and a wifi adaptor, and a router. The

##Recommended Wifi Devices

Proxmox VE 9.2 uses a  7.0 Linux kernel with in-tree Linux kernel drivers for modern wifi6 and wifi7 devies. -  kernel supports any WIFI chipset with an in-tree Linux kernel driver and pre-installed firmware.


### Supported chipset families with Proxmox 9.2

Most modern PCIe, M.2, and USB wireless adapters are directly supported. Proxmox9.2 firmware for these devices is included in pve-firmware.

Intel (iwlwifi driver). Most Intel PCIe and M.2 cards work natively, including the AX200 , AX20, AX210, AX211, BE200, BE202, and older AC 7260/8260/9260 series.

MediaTek (mt76 / mt7921e / mt7921u / mt7925 driver). Wi-Fi 6, 6E, and 7 chipsets—such as the MT7921, MT7922, MT7925, and USB MT7612U—have mainline support and firmware included in the default pve-firmware bundle.
 
Qualcomm Atheros (ath9k / ath10k / ath11k / ath12k driver). Older 802.11n (ath9k, which requires no external firmware) and newer Wi-Fi 5/6/7 chipsets (QCA6174, QCA988x, WCN6855, WCN7850) work without extra driver compilation.

Realtek (rtw88 / rtw89 / rtl8xxxu driver )Chipsets like RTL8821CE, RTL8822CE, RTL8852AE/BE/CE, and RTL8922AE.



# Features
#

This installation does not use NAT so Proxmox and the VMs can use DHCP to obtain IP addresses. With no NAT the VMs operate like a regular VM environment.

There is also (optional) support for SAMBA. This allows a VM to install Samba and shares are visible to windows machines. This does not replace WSDD or WSDD2; they needed like any regular Samba installation.

## How it works

A wifi adapter operates as a is a layer 2 device. We













# Installation

## Install Proxmox 
9.2 and later

## Optional SAMBA helpers

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
