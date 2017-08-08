# Important!
You **must** edit any of the files located in `/var/lib/logzilla/scripts/` and change the slack webhooks to the correct URL for your slack token.

# Cause Duplex mismatch

```sh
./sw2-duplex-half
Connecting to sw2-branch
conf t
Enter configuration commands, one per line.  End with CNTL/Z.
sw2-branch(config)#int gi0/1
sw2-branch(config-if)#duplex half
```

Check the sw2-branch's console logs (or LogZilla of course!) :)

e.g.:

```
*Jul  6 18:50:35.353: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:interface GigabitEthernet0/1
*Jul  6 18:50:35.496: %SPANTREE-5-ROOTCHANGE: Root Changed for vlan 15: New Root Port is Port-channel23. New Root Mac Address is fa16.3e9c.fe46
*Jul  6 18:50:35.496: %EC-5-CANNOT_BUNDLE2: Gi0/1 is not compatible with Gi0/2 and will be suspended (duplex of Gi0/1 is half, Gi0/2 is full)
*Jul  6 18:50:35.496: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:duplex half
*Jul  6 18:50:35.539: %SYS-5-CONFIG_I: Configured from console by cisco on vty1 (172.16.1.241)
*Jul  6 18:50:51.917: %CDP-4-DUPLEX_MISMATCH: duplex mismatch discovered on GigabitEthernet0/1 (not full duplex), with sw-branch.lzil.la GigabitEthernet0/1 (full duplex).
*Jul  6 18:50:54.314: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:interface GigabitEthernet0/1
*Jul  6 18:50:54.332: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:no negotiation auto
*Jul  6 18:50:54.475: %EC-5-COMPATIBLE: Gi0/1 is compatible with port-channel members
*Jul  6 18:50:54.475: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:duplex full
*Jul  6 18:50:54.480: %SYS-5-CONFIG_I: Configured from console by cisco on vty1 (172.16.1.241)
*Jul  6 18:50:55.877: %SPANTREE-5-TOPOTRAP: Topology Change Trap for vlan 15
*Jul  6 18:50:55.877: %SPANTREE-5-ROOTCHANGE: Root Changed for vlan 15: New Root Port is Port-channel23. New Root Mac Address is fa16.3e9c.fe46
```

```
./sw-dtp-5-spantree-vlan15
Connecting to sw-branch
conf t
Enter configuration commands, one per line.  End with CNTL/Z.
sw-branch(config)#int po23
sw-branch(config-if)#switchport trunk allowed vlan remove 15
sw-branch(config-if)#switchport trunk allowed vlan add 15
```

```
sw-branch#ter mon
sw-branch#
*Jul  6 18:51:42.347: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:interface Port-channel23
*Jul  6 18:51:42.382: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:switchport trunk allowed vlan remove 15
*Jul  6 18:51:42.416: %PARSER-5-CFGLOG_LOGGEDCMD: User:cisco  logged command:switchport trunk allowed vlan add 15
*Jul  6 18:51:42.418: %SPANTREE-5-TOPOTRAP: Topology Change Trap for vlan 15
*Jul  6 18:51:42.538: %SYS-5-CONFIG_I: Configured from console by cisco on vty1 (172.16.1.241)
```

# Reset (kaboom!)
LogZilla can be wiped clean/reset using `./reset-lz-to-factory`. Use with caution!

