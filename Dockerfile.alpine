FROM alpine:latest

# Install wireguard packges
RUN apk --no-cache add wireguard-tools iptables ip6tables inotify-tools

# Add main work dir to PATH
WORKDIR /scripts
ENV PATH="/scripts:${PATH}"

# Use iptables masquerade NAT rule
ENV IPTABLES_MASQ=1

# Watch for changes to interface conf files (default off)
ENV WATCH_CHANGES=0

# Copy scripts to containers
COPY run /scripts
COPY genkeys /scripts
RUN chmod 755 /scripts/*

# Wirguard interface configs go in /etc/wireguard
VOLUME /etc/wireguard

# Normal behavior is just to run wireguard with existing configs
CMD ["run"]