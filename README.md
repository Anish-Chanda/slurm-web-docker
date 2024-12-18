# slurm-web-docker

## Prerequisites

Before building the container, you need to:

1. Update the socket location in the run container configuration.

2. Create a drop-in configuration override for the slurmrestd daemon: at `/etc/systemd/system/slurmrestd.service.d/slurm-web.conf`
```bash
[Service]
# Unset vendor unit ExecStart to avoid cumulative definition
ExecStart=
Environment=
# Disable slurm user security check
Environment=SLURMRESTD_SECURITY=disable_user_check
ExecStart=/usr/sbin/slurmrestd $SLURMRESTD_OPTIONS unix:/run/slurmrestd/slurmrestd.socket
RuntimeDirectory=slurmrestd
RuntimeDirectoryMode=0755
User=slurm
Group=slurm
```

## Building and Running
1. Build the container:
```bash
podman-compose build
```
2. Run the container
```bash
podman-compose up -d
```

Slurm web should now be reachable at `localhost:5011` or `[gateway.ini-UI ip]:5011`.

Note: if you want the url of the slurm web dashboard to be different then update the ui host in slurm web `gateway.ini`
