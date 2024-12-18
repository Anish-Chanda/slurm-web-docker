#!/bin/bash

podman run \
  --name sweb \
  --network podman \
  -p 5011:5011 \
  -p 5012:5012 \
  -v ./racksdb:/var/lib/racksdb:Z \
  -v ./agent.ini:/etc/slurm-web/agent.ini:Z \
  -v ./gateway.ini:/etc/slurm-web/gateway.ini:Z \
  -v /run/slurmrestd/slurmrestd.socket:/run/slurmrestd/slurmrestd.socket \
  --restart unless-stopped \
  localhost/sweb:latest