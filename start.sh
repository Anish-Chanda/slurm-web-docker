#!/bin/bash


echo "Starting Startup Script"

# figure out the login host
if [ -f "/etc/slurm/slurm.conf" ]; then
    # Extract the IP and hostname from SlurmctldHost line
    SLURM_HOST_LINE=$(grep "^SlurmctldHost=" /etc/slurm/slurm.conf)
    if [ ! -z "$SLURM_HOST_LINE" ]; then
        # Extract hostname and IP using regex
        SLURM_HOSTNAME=$(echo "$SLURM_HOST_LINE" | sed -n 's/SlurmctldHost=\([^(]*\)(.*/\1/p')
        SLURM_IP=$(echo "$SLURM_HOST_LINE" | sed -n 's/.*(\([^)]*\)).*/\1/p')
        
        # Create hosts file with extracted values
        echo "Creating hosts file with Slurm controller info..."
        cat > /etc/hosts.new << EOF
127.0.0.1 localhost
$SLURM_IP $SLURM_HOSTNAME
::1 localhost
EOF
        echo "Hosts file created successfully with $SLURM_HOSTNAME ($SLURM_IP)"
    else
        echo "ERROR: No SlurmctldHost found in slurm.conf"
        exit 1
    fi
else
    echo "ERROR: slurm.conf not found at /etc/slurm/slurm.conf"
    exit 1
fi

# Try to update actual hosts file
if [ -w "/etc/hosts" ]; then
    cat /etc/hosts.new > /etc/hosts
    echo "Hosts file updated successfully"
else
    echo "WARNING: Cannot write to /etc/hosts - may need to mount as writable"
fi

# Verify hosts configuration
echo "Verifying hosts configuration:"
cat /etc/hosts || echo "ERROR: Could not read hosts file"
echo "Checking login entry:"
grep login /etc/hosts || echo "WARNING: login entry not found in hosts file"

echo "Check if hosts file is created"
cat /etc/hosts | grep login

# SETUP MUNGE
# groupmod -g 1000 munge
# usermod -u 1000 -g munge -s /sbin/nologin munge
# cp /tmp/munge/munge.key /etc/munge/munge.key
mkdir -p /etc/munge \
         /var/run/munge \
         /var/log/munge \
         /run/munge \
         /var/lib/munge
chown -R munge:munge /etc/munge /var/run/munge /var/log/munge
chown root:munge /run/munge
chmod 0700 /etc/munge
chmod 0711 /var/run/munge
chmod 0755 /run/munge
chmod 0700 /var/log/munge
chmod 0700 /var/lib/munge
chown munge:munge /etc/munge/munge.key
chown -R munge:munge /etc/munge /var/run/munge /var/log/munge /var/lib/munge /run/munge
id munge
ls -l /etc/munge/munge.key
chmod 0400 /etc/munge/munge.key

# Start munged service as munge user
echo "Starting munged service"
runuser -u munge -- /usr/sbin/munged --force

echo "Installing slurm web agent and agetaway"
cat <<EOF > /etc/yum.repos.d/rackslab.repo
[rackslab]
name=Rackslab
baseurl=https://pkgs.rackslab.io/rpm/el9/main/\$basearch/
gpgcheck=1
enabled=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab
EOF
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab

microdnf update -y
microdnf install -y slurm-web-agent slurm-web-gateway racksdb
/usr/libexec/slurm-web/slurm-web-gen-jwt-key




# Create and set permissions for munge directories
# mkdir -p /var/run/munge /run/munge /var/log/munge
# chown -R munge:munge /var/run/munge /run/munge /var/log/munge
# chmod 0711 /var/run/munge
# chmod 0755 /run/munge
# chmod 0700 /var/log/munge


# Test munge
echo "Testing munge"
su -s /bin/bash munge -c "munge -n | unmunge"

# ping slurmctl node
echo "Pinging slurmctl node"
ping -c 2 login

# Start slurmrestd service as slurm user
echo "Starting slurmrestd service"
mkdir -p /run/slurmrestd
chown -R slurm:slurm /run/slurmrestd
export SLURMRESTD_SECURITY=disable_user_check
su -s /bin/bash slurm -c "/usr/sbin/slurmrestd unix:/run/slurmrestd/slurmrestd.socket &"

# Check slurmrestd status
echo "Checking slurmrestd status"
sleep 5
response=$(curl --unix-socket /run/slurmrestd/slurmrestd.socket http://localhost/slurm/v0.0.39/diag)

if echo "$response" | grep -q '"type": "openapi\\/v0.0.39"'; then
    echo "slurmrestd is running successfully"
else
    echo "Failed to start slurmrestd"
    echo "$response"
    exit 1
fi




# check racks db configs
racksdb datacenters

# verify the cluster = hpc in agent ini
echo "checckkkkk cluster name in agent ini"
cat /etc/slurm-web/agent.ini | grep cluster

# Start Slurm-web gateway as slurm-web user
echo "Starting slurm-web-gateway service"
/usr/libexec/slurm-web/slurm-web-gateway &

# Start Slurm-web agent
echo "Starting slurm-web-agent service"
/usr/libexec/slurm-web/slurm-web-agent