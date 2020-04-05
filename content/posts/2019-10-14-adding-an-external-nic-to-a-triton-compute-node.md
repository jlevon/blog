+++
author = "John Levon"
published = 2019-10-14T15:21:00+01:00
slug = "2019-10-14-adding-an-external-nic-to-a-triton-compute-node"
tags = []
title = "Adding an external NIC to a Triton compute node"
+++
I found it a little bit non-obvious how to use
[NAPI](%20https://github.com/joyent/sdc-napi/) to add an external NIC to
a compute node so it can reach the external network rather than just the
internal `admin` one.

We need to first tag the underlying physical NIC on the compute node
with the `external`NIC tag. We need to look up the MAC of the physical
NIC:

    computenode# # dladm show-phys -m ixgbe0
    LINK         SLOT     ADDRESS            INUSE CLIENT
    ixgbe0       primary  e4:11:5b:97:83:49  yes  ixgbe0

then tell NAPI (from the headnode) that this NIC is going to provide the
`external` tag:

    sdc-napic /nics/e4:11:5b:97:83:49 -X PUT -d '{ "nic_tags_provided" : "external" }'

We now need to actually add the `external` VNIC in NAPI:

    cn=*your compute node UUID from `sdc-server list`*
    ip=*IP address to use on external network*
    vlan_id=*vlan id if any*

    owner=$(sdc-useradm get admin | json uuid)

    sdc-napi /nics -X POST -d @- <<EOF
    {
     "owner_uuid": "$owner",
     "belongs_to_type": "server",
     "belongs_to_uuid": "$cn",
     "cn_uuid": "$cn",
     "ip": "$ip",
     "vlan_id": "$vlan_id",
     "nic_tag": "external"
    }
    EOF

After a while, we should find that the DHCPD server has updated the
networking config file for the CN:

    # cat /zones/$(vmadm list -Ho uuid alias=dhcpd0)/root/tftpboot/bootfs/e4115b978348/networking.json
    ...
      "nictags": [
        {
          "mtu": 1500,
          "name": "external",
          "uuid": "86b73953-488a-4041-bd7a-83aa51c4ca22"
    ...
      "vnics": [
    ...
          "belongs_to_type": "server",
          "nic_tag": "external",
    ...

And on rebooting the CN, we can find our interface up, and reachable
externally:

    # ipadm show-addr external0/_a
    ADDROBJ           TYPE     STATE        ADDR
    external0/_a      static   ok           192.168.0.44/24
