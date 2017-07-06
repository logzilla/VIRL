# CiscoLive! NetOps Lab
# Table Of contents
1. [Lab Setup](#lab)
2. [CiscoLive! Scenarios](#scenarios)
3. [Duplex Mismatch](#duplex)
4. [VLAN Mismatch](#vlanmismatch)
5. [Port Channel Up w/ Member Down](#pchan)

# Lab Setup <a name="lab"></a>

This VIRL lab setup will be available from our [Github repo](https://github.com/logzilla/VIRL) after the show.

>Note: I've done my best to document everything I set up, but please go easy on me if I forgot something :)

Some essential config commands are needed for tracking various events such as spanning tree. These commands must specifically be enabled even if syslog is enabled already on the device.

## Hosts
Edit the `/etc/hosts` file and replace the IP's for each of the devices in the lab with the assigned IP's for your lab. The current hosts file contains the following:

The first two devices below are **physical** devices that connect the lab to the outside world.

```
172.16.1.1   lab-router
172.16.1.253 lab-switch
172.16.1.249 sw-dc
172.16.1.245 rtr-dc
172.16.1.244 rtr-campus
172.16.1.248 sw-campus
172.16.1.246 srv-campus
172.16.1.243 rtr-branch
172.16.1.247 sw-branch
172.16.1.250 sw2-branch
172.16.1.242 ids-branch
172.16.1.251 lxc-branch
```

## Physical lab connectivity
The two devices named `lab-router` and `lab-switch` are used to provide internet access.

### Physical Router Config
> Only the relevant config items are shown


```
! This is the "Outside" interface
! Even though it has an internal IP, this router is only being used as a NAT gateway for the lab.
interface GigabitEthernet0/0
 description RTR-Outside
 no ip dhcp client request netbios-nameserver
 no ip dhcp client request domain-name
 no ip dhcp client request dns-nameserver
 ip address 192.168.28.253 255.255.255.0
 ip access-group INTERNET-IN in
 no ip redirects
 no ip unreachables
 ip nat outside
 no ip virtual-reassembly in
 no cdp enable
 !
interface GigabitEthernet0/1
 description RTR-Inside
 ip address 172.16.1.1 255.255.255.0
 ip nat inside
 ip virtual-reassembly in max-reassemblies 512
 vlan-range dot1q 1 4094
 exit-vlan-config
!
 
ip nat inside source list 100 interface GigabitEthernet0/0 overload
ip route 0.0.0.0 0.0.0.0 192.168.28.1
ip route 172.16.0.0 255.255.0.0 GigabitEthernet0/1
ip route 192.168.28.0 255.255.255.0 GigabitEthernet0/0
!
ip access-list extended INTERNET-IN
 permit tcp any any established
 permit ip any any
 permit gre any any log
ip access-list extended INTERNET-OUT
 permit ip any any
!
```

### Physical Switch Config
> Only the relevant config items are shown

```
!
vlan 161
 name CML_172.16.1.0-24
!
vlan 162
 name CML_172.16.2.0-24
!
vlan 163
 name CML_172.16.3.0-24
!
vlan 1610
 name CML_172.16.10.0-24
!
interface GigabitEthernet1/0/1
 description RTR
 switchport access vlan 161
 switchport mode access
 duplex full
!
interface Vlan161
 ip address 172.16.1.253 255.255.255.0
!
interface Vlan162
 ip address 172.16.2.253 255.255.255.0
!
interface Vlan163
 ip address 172.16.3.253 255.255.255.0
!
interface Vlan1610
 ip address 172.16.10.253 255.255.255.0
!
ip route 172.16.1.0 255.255.255.0 Vlan161
ip route 172.16.2.0 255.255.255.0 Vlan162
ip route 172.16.3.0 255.255.255.0 Vlan163
ip route 172.16.10.0 255.255.255.0 Vlan1610
ip route 192.168.28.0 255.255.255.0 Vlan1

```
## SSH Setup
You will need to set up SSH on each device using the following commands:

```
conf t
aaa new-model
aaa authentication login default local
aaa authorization exec default local
aaa accounting commands 15 default
username cisco privilege 15 secret 0 cisco
! replace logzilla.net below if you prefer
ip domain-name logzilla.net
crypto key generate rsa modulus 1024
ip ssh version 2
line vty 0 4
transport input telnet ssh
transport output telnet ssh
end
write mem
```

## Audit Trail
This logs all commands entered on the device. 70% of all outages are due to change. Thus, it's a very good idea to track them!

```
config term
archive
 log config
  record rc
  logging enable
  notify syslog contenttype plaintext
  hidekeys
end
wr
```

## Spanning Tree Events
By default, there are no log events generated for spanning tree. This options must be specifically enabled on switches. To enable:
```
config terminal
spanning-tree logging
```

## Trunk Port Events

In order to receive `dtp-5-trunkport*` events, you must set `logging event trunk-status` **on the physical interfaces**. Without this, no trunking events are generated when the ports go down.


```
config terminal
int range gi0/1-2
logging event trunk-status
end
wr

```


# Scenarios <a name="scenarios"></a>


## Duplex Mismatch <a name="duplex"></a>
One of the most common problems in networks is `duplex mismatch`. Sadly, these events get ignored all to often and can cause degradation.
Interestingly, it is also simple to fix but requires a tedious amount of time when done manually.

### Sample Message

```
*Jun 26 02:02:36.346: %CDP-4-DUPLEX_MISMATCH: duplex mismatch discovered on GigabitEthernet0/1 (not full duplex), with sw2-branch.lzil.la GigabitEthernet0/1 (full duplex).
```

### Device Config Steps
```
conf t
int gi0/1
duplex half
end
write mem
```
### Script
Rather than manually ssh'ing, the following script is used to set the duplex to half in order to cause the problem.

```perl
#!/usr/bin/env perl
use Net::SSH2::Cisco;
my $ciscoUsername = "cisco";
my $ciscoPassword = "cisco";
my $hostname = "sw2-branch";
my $command = "conf t\nint gi0/1\nduplex half";
printf "Connecting to %s\n", $hostname;
my $session = Net::SSH2::Cisco->new(host => $hostname);
$session->login($ciscoUsername, $ciscoPassword);
my @output = $session->cmd("$command");
my $results = join("", @output);
chomp($results);
print @output;
$session->close;
```
This will output the following:

```sh
root@LogZilla [scripts]: # ./duplex
Connecting to sw2-branch
conf t
Enter configuration commands, one per line.  End with CNTL/Z.
sw2-branch(config)#int gi0/1
sw2-branch(config-if)#duplex half
root@LogZilla [scripts]: #
```

### Remediation Steps
1. Extract the offending port # from the incoming alert
2. SSH to affected device and check the duplex setting
3. Change to duplex full instead of auto.
4. Report both the original config and the fixed config via Slack.


## VLAN Mismatch <a name="vlanmismatch"></a>

### Sample Messages

```
*Jun 26 02:22:13.761: %SPANTREE-5-TOPOTRAP: Topology Change Trap for vlan 15
*Jun 26 02:22:13.761: %SPANTREE-5-ROOTCHANGE: Root Changed for vlan 15: New Root Port is Port-channel23. New Root Mac Address is fa16.3e9e.4407
```


### Steps To Reproduce

1. Remove the allowed vlan from the trunk in order to cause a problem

```
ssh cisco@sw-branch
conf t
int po23
switchport trunk allowed vlan remove 15
```
2. Fix it!

```
ssh cisco@sw-branch
conf t
int po23
switchport trunk allowed vlan add 15
```
### Scripted
The duplex mismatch script above will cause the problem, but for completeness, we'll also do this by removing vlan 15 from the allowed vlans list.

```perl
#!/usr/bin/env perl
use Net::SSH2::Cisco;
my $ciscoUsername = "cisco";
my $ciscoPassword = "cisco";
my $hostname = "sw-branch";
my $command = "conf t\nint po23\nswitchport trunk allowed vlan remove 15\nswitchport trunk allowed vlan add 15";
printf "Connecting to %s\n", $hostname;
my $session = Net::SSH2::Cisco->new(host => $hostname);
$session->login($ciscoUsername, $ciscoPassword);
my @output = $session->cmd("$command");
my $results = join("", @output);
chomp($results);
print @output;
$session->close;
```

## Port Channel Up With Member Interface Down <a name="pchan"></a>

**The most common cause of these errors is simply someone accidentally pulling a cable.**

The problem tends to go unnoticed in many environments because there is a backup link in the trunk. In this example, we will show the ability to not just alert on the error, but to access the affected device and collect enough information to enable engineers to make intelligent decisions as to why it may have occurred.


### Sample Messages
```
*Jun 26 01:56:34.730: %DTP-5-TRUNKPORTON: Port Gi0/1 has become dot1q trunk
*Jun 26 01:57:08.490: %DTP-5-NONTRUNKPORTON: Port Gi0/1 has become non-trunk
```

### Device Config Steps

1. Detect `%DTP-5-NONTRUNKPORTON:` *or* `%DTP-5-TRUNKPORTON:`
2. SSH to the affected device and perform the commands below.
3. Report the collected information back to Slack along with reference links to Cisco.com

```
show interfaces gi0/1 etherchannel
show interface gi0/1
```

# VPN
I used [Hamachi](http://vpn.net) to access the LogZilla server from outside. It's quite easy. I have removed this instance from our VPN but left hamachi installed. To join a new VPN (your own), issue the following commands:

```
hamachi login
hamachi set-nick LogZilla-ViRL
hamachi attach-net your@email.address.for-hamachi
```
Replace `your@email.address.for-hamachi` with your registered Hamachi email account.

