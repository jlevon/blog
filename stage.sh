#!/bin/bash

ip=$(curl ifconfig.me)

# baseUrl in config file is ignored!
hugo --config stage.toml --bind $ip --baseUrl http://ssh.movementarian.org:1313/blog/ server
