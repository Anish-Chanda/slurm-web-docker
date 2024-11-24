# slurm-web-docker

## Prerequisites

Before building the container, you need to:

1. Copy your munge.key to the current directory:
```bash
cp /etc/munge/munge.key ./
```
2. Update the SlurmctldHost IP address (default: 192.168.0.98) in slurm.conf to match your actual Slurm controller node:
```bash
SlurmctldHost=login(YOUR_SLURM_CONTROLLER_IP)
```
3. Update the corresponding entry in start.sh file line 11:
```bash
(YOUR_SLURM_CONTROLLER_IP) login
```

## Building and Running
1. Build the container:
```bash
docker-compose build
```
2. Run the conatiner
```bash
docker compose up -d
```

Slurm web should now be reachable at `localhost:5011`.

Note: if you want the url of the slurm web dashboard to be different then update the ui host in slurm web `gateway.ini`
