# A Collection of scripts to improve and speedup the setup of user workstations

Out of the box WSL has some odd network setup. If you cannot `ping github.com` you'll need to update your `/etc/resolv.conf` prior to being able to download and run this script via curl.

`sudo su`

`echo nameserver 8.8.8.8 >> /etc/resolv.conf`

`exit`

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/alanrainford/scripts/develop/setup-az-tunnels.sh)"`

| Script      | Description |
| ----------- | ----------- |
| setup4all.sh | All users start here |
| setup4backend.sh | Tools used primarily by Backend developers |
| setup4frontend.sh | Tools used primarily by Frontend developers |
| setup4devops.sh | Tools used primarily by DevOps developers |
