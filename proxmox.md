### Host System Details

Proxmox CE 4.2-18/158720b9

### ISO Creation

* Download OS X El Capitan or macOS Sierra installer from Apple App Store.

* Run the ISO creation script, making sure to use 'sudo'.

* Copy the ISO from your Mac to your proxmox machine in _/var/lib/vz/template/iso/_.

### Preparation

* Copy the files _enoch_rev2839_boot_ and _pve-osx.cfg_ on the proxmox server in _/opt_

* Run this command as root:
```
echo 1 > /sys/module/kvm/parameters/ignore_msrs
```
You may add it to /etc/rc.local for permanent configuration.

### Installation

* Create a new VM (KVM) give it a name and set the OS type to Other. Make sure the CPU is a core2duo. Do NOT use a CD-Drive. Keep the VM shutdown for now.

* On the VM's hardware set the Display driver to _VGA Standard_

* Edit the VM's config:
You will now need to SSH into the server running the hypervisor.
Make sure you know the ID of the VM in Proxmox (it's the number before the hostname in the VM list in the sidebar). Then open /etc/pve/qemu-server/VMID.conf in your favourite text editor (nano or vim for example).
And add the following at the end of the file:
```
args: -machine pc-q35-2.4 -smbios type=2 -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -kernel /opt/enoch_rev2839_boot -usb -device usb-kbd -device usb-mouse -readconfig /opt/pve-osx.cfg -device ide-drive,bus=ide.2,drive=MacDVD -drive id=MacDVD,if=none,snapshot=on,file=/var/lib/vz/template/iso/Install_OS_X_10.11.6_El_Capitan.iso
```

* Then start the machine as usual and hit return in the console window.

* After booting, the initial language selection should show up.
![screenshot_01](https://cloud.githubusercontent.com/assets/731252/17645877/5136b1ac-61b2-11e6-8d90-29f5cc11ae01.png)

* After selecting the language, fire-up the Disk Utility ...
![screenshot_02](https://cloud.githubusercontent.com/assets/731252/17645881/513b6918-61b2-11e6-91f2-026d953cbe0b.png)

* ... and initialize the new harddisk.
![screenshot_03](https://cloud.githubusercontent.com/assets/731252/17645878/51373d48-61b2-11e6-8740-69c86bf92d31.png)
![screenshot_04](https://cloud.githubusercontent.com/assets/731252/17645879/513ae704-61b2-11e6-9a54-109c37132783.png)

* After disk initialization, open a terminal window (in the Utilities menu) and recursively copy the /Extra folder
  to the newly initialized target volume using
  ```bash
   cp -av /Extra "/Volumes/NewVolumeName"
  ```
* When done, quit Terminal.
![screenshot_05](https://cloud.githubusercontent.com/assets/731252/17645876/5136ad6a-61b2-11e6-84cd-cb7851119292.png)

* Now, you can continue with the installation as usual
![screenshot_06](https://cloud.githubusercontent.com/assets/731252/17645880/513b2c3c-61b2-11e6-889c-3e4f5a0612ca.png)

* When finished, the VM will reboot automatically and the first time setup continues as usual.
![screenshot_07](https://cloud.githubusercontent.com/assets/731252/17645882/51517a50-61b2-11e6-8bb5-70c810d80b2b.png)

### References

* http://blog.will3942.com/virtualizing-osx-yosemite-proxmox
