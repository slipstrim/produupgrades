 
# spec for Proxmox
    "pve-kernel-*";
    "proxmox-ve*";
    "qemu-server";
    "libpve-*";
    "corosync";
    "cluster-glue";
    "pacemaker";
    "ceph-*";
    "lxc-*";
    
    # net components
    "openvswitch-*";
    "ifupdown2";
   
 "realtek-*";
    for kali
    # crit tools
    "metasploit-framework";
    "burpsuite";
    "aircrack-ng";
    "wireshark*";
    "john";
    "hashcat";
    "sqlmap";
    
    # spec drivers
    "kali-tools-802-11";
    "kali-tools-bluetooth";

VMs
# virt
    "virtualbox-*";
    "open-vm-tools*";
    "qemu-*";
    "libvirt-*";
# hypervisors
    "xen-*";
    "kvm-*";
# bridge
    "bridge-utils";


# service packs
"postgresql-*";
"mysql-*";
"apache2*";
"nginx-*";
"docker-*";
"kube*";

# hardw
"firmware-*";
"microcode-*";

# system progs
"systemd-*";
"grub-*";
"initramfs-*";

# sec
"openssh-*";
"openssl-*";

# auth
"pam-*";
"ldap-*";

# for Kali/Dev
"python3-*";
"nodejs-*";
"gcc-*";
"llvm-*";
# auto update
Unattended-Upgrade::Allowed-Origins {
    "kali-rolling:main";
    "kali-rolling:contrib";
};

# manual update
Unattended-Upgrade::Package-Blacklist {
    "kali-tools-*";
    "setoolkit";
};

#  Wi-Fi
"broadcom-*";
"ath9k-*";

# GPU
"amd-gpu-*";
"intel-gpu-*";

#cluster
    "corosync";
    "cluster-glue";
    "resource-agents";



**you can also add hypervisor check**
HYPERVISOR=$(systemd-detect-virt)
if [ "$HYPERVISOR" != "none" ]; then
    echo "Hypervisor detected: $HYPERVISOR"
    sudo sed -i "/Package-Blacklist {/a\ \ \ \ \"$HYPERVISOR-*\";" "$CONFIG_FILE"
fi
