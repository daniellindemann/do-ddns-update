FROM alpine:3

# default env variables
# Optional, default is 10 minutes
ENV DDNS_CHECK_INTERVAL="10m"
# Optional, default is https://ifconfig.io/ip
ENV DDNS_CHECK_PUBLIC_IP_URL="https://ifconfig.io/ip"
# Optional, default is 8.8.8.8, Google's public DNS server
ENV DDNS_CHECK_DNS_SERVER="8.8.8.8"

# install apps
# dig
RUN apk add bind-tools

# copy script
COPY flexdns_update.sh /opt/do-ddns-update/flexdns_update.sh
RUN chmod +x /opt/do-ddns-update/flexdns_update.sh

# create user to run the script
RUN adduser -S do-ddns-agent
USER do-ddns-agent

CMD ["sh", "-c", "/opt/do-ddns-update/flexdns_update.sh"]
