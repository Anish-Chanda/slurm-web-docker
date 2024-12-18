FROM almalinux:minimal

RUN microdnf install -y epel-release

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose ports for Slurm-web
EXPOSE 5011 5012

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/start.sh"]