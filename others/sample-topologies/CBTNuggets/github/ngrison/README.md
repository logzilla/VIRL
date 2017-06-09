# VIRL


Default Passwords:

SSH access to the VIRL VM: username=virl, password=VIRL
Window login: username=virl, password=VIRL
VM Maestro default user: username=guest, password=guest
User Workspace management administrator: username=uwmadmin, password=password
Linux VM jumphost: username=your project username, typically guest, password=your project password, typically guest
Linux Servers default user (If using 'Build Initial Configurations'): username=cisco, password=cisco
Cisco VMs (If using 'Build Initial Configurations'): username=cisco, password=cisco
If you do NOT use 'Build Initial Configuration', the following apply:

ASAV - no default password, no default enable password, default configuration present
CSR1000v - no default password, no default enable password, default configuration present
IOSv - no default password, no default enable password, no default configuration present
IOSvL2 - no default password, no default enable password, no default configuration present
IOS XRv - default username/password = admin/admin, cisco/cisco, lab/lab, no default configuration present
NXOSv - default username/password = admin/admin, default configuration present
Linux/Cloud-init - requires cloud-init configuration injection, no default username/password present - inaccessible



Self-service download
Existing VIRL users are able to download the new OVA or ISO images themselves NOW using the following command.
THE ISO IMAGE IS NOT YET AVAILABLE!!!

US Servers

sudo salt-call --master us-virl-image-server.virl.info state.sls virl.ova.esxi
sudo salt-call --master us-virl-image-server.virl.info state.sls virl.ova.pc
sudo salt-call --master us-virl-image-server.virl.info state.sls virl.iso <<< NOT WORKING YET

EU Servers

sudo salt-call --master eu-virl-image-server.virl.info state.sls virl.ova.esxi
sudo salt-call --master eu-virl-image-server.virl.info state.sls virl.ova.pc
sudo salt-call --master eu-virl-image-server.virl.info state.sls virl.iso <<< NOT WORKING YET

The command will pull down the virl image and place it in /home/virl from where you can then sftp the image out.
NOTE - this is will download the full image that you've chosen (~4Gb) - this may well take a few hours to complete,
so please be patient. You can check the progress of the download by periodically issuing the command
'sudo ls -lh /var/cache/salt/minion/files/base/images/[ova|iso]'.