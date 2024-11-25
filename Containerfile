FROM almalinux:minimal

# service override for restd
RUN mkdir -p /etc/systemd/system/slurmrestd.service.d/
RUN echo '[Service]\n\
ExecStart=\n\
Environment=\n\
Environment=SLURMRESTD_SECURITY=disable_user_check\n\
ExecStart=/usr/sbin/slurmrestd $SLURMRESTD_OPTIONS unix:/run/slurmrestd/slurmrestd.socket\n\
RuntimeDirectory=slurmrestd\n\
RuntimeDirectoryMode=0755\n\
User=slurm\n\
Group=slurm' > /etc/systemd/system/slurmrestd.service.d/slurm-web.conf
ENV SLURMRESTD_SECURITY=disable_user_check


# Install base dependencies and munge
RUN microdnf install -y epel-release && \
    microdnf install -y munge && \
    microdnf install -y hdf5 hwloc-libs libibmad libibumad freeipmi libjwt mariadb-connector-c numactl-libs http-parser && \
    microdnf clean all

# Setup munge directories and permissions
# RUN mkdir -p /etc/munge /var/run/munge /var/log/munge /run/munge && \
#     chown -R munge:munge /etc/munge /var/run/munge /var/log/munge && \
#     chown root:munge /run/munge && \
#     chmod 0700 /etc/munge && \
#     chmod 0711 /var/run/munge && \
#     chmod 0755 /run/munge && \
#     chmod 0700 /var/log/munge

# # Setup munge key
# COPY munge.key /etc/munge/munge.key
# RUN chown munge:munge /etc/munge/munge.key && \
#     chmod 0400 /etc/munge/munge.key

# Create slurm user with fixed UID/GID
RUN groupadd -g 1001 slurm && \
    useradd -u 1001 -g slurm -d /var/lib/slurm -s /sbin/nologin -c "Slurm Workload Manager" slurm && \
    mkdir -p /var/lib/slurm /etc/slurm /run/slurm && \
    chown -R slurm:slurm /var/lib/slurm /etc/slurm /run/slurm

# Install slurm packages
COPY slurm-24.05.2.rpm slurmrestd-24.05.2.rpm /tmp/slurm/
# COPY slurm.conf /etc/slurm/slurm.conf
RUN rpm -ivh /tmp/slurm/*.rpm && \
    rm -f /tmp/slurm/*.rpm

# Add Rackslab repository
RUN curl https://pkgs.rackslab.io/keyring.asc -o /etc/pki/rpm-gpg/RPM-GPG-KEY-Rackslab

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose ports for Slurm-web
EXPOSE 5011 5012

# Add to Dockerfile
RUN mkdir -p /var/lib/racksdb/{datacenters,infrastructure,types} && \
    chown -R slurm:slurm /var/lib/racksdb && \
    chmod -R 755 /var/lib/racksdb

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]