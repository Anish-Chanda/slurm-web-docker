#!/bin/bash


echo "Starting Startup Script"
# Download the GPG key
curl https://pkgs.rackslab.io/keyring.asc --output /etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab
if [ $? -ne 0 ]; then
  echo "Failed to download GPG key"
  exit 1
fi

echo "Installing slurm web agent and gateway"
cat <<EOF > /etc/yum.repos.d/rackslab.repo
[rackslab]
name=Rackslab
baseurl=https://pkgs.rackslab.io/rpm/el9/main/\$basearch/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab
EOF

# Import the GPG key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab
if [ $? -ne 0 ]; then
  echo "Failed to import GPG key"
  exit 1
fi

microdnf update -y
microdnf install -y slurm-web-agent slurm-web-gateway racksdb

/usr/libexec/slurm-web/slurm-web-gen-jwt-key

# check racks db configs
racksdb datacenters

# verify the cluster = hpc in agent ini
echo "check cluster name in agent ini"
cat /etc/slurm-web/agent.ini | grep cluster

# Start Slurm-web gateway as slurm-web user
echo "Starting slurm-web-gateway service"
/usr/libexec/slurm-web/slurm-web-gateway &

# Start Slurm-web agent
echo "Starting slurm-web-agent service"
/usr/libexec/slurm-web/slurm-web-agent