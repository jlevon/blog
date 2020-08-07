#!/bin/bash

# baseUrl in config file is ignored!
hugo --config stage.toml --bind 0.0.0.0 --baseUrl http://ssh.movementarian.org:1313/blog/ server
