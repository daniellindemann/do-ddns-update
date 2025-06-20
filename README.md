# Domain Offensive FlexDNS Updater

This is a script to update the FlexDNS configuration for your domain hosted at [Domain Offensive](https://do.de).  
See detailed instructions on Domain Offensive's website: https://www.do.de/wiki/flexdns-einrichtung/

## Run

### Run via script:

- Download script file [`flexdns_update.sh`](flexdns_update.sh)
- Set execution level for for the script file

```bash
chmod +x ./flexdns_update.sh
```

- Set environment variables

```bash
export DDNS_USERNAME="DDNS-K00000-00000"
export DDNS_PASSWORD="passw0rd"
export DDNS_HOSTNAME="my-ddns-sub-domain.mydomain.de"
```

- Run the script

```bash
./flexdns_update.sh
```

Run via Docker:

```bash
docker run -d --name do-ddns-update --restart unless-stopped -e DDNS_USERNAME="DDNS-K00000-00000" -e DDNS_PASSWORD="passw0rd" -e DDNS_HOSTNAME="my-ddns-sub-domain.mydomain.de" do-ddns-update
```

Run via Docker Compose:

```yaml
services:
  do-ddns-update:
    image: daniellindemann/do-ddns-update
    container_name: do-ddns-update
    restart: unless-stopped
    environment:
      - DDNS_USERNAME=DDNS-K00000-00000
      - DDNS_PASSWORD=passw0rd
      - DDNS_HOSTNAME=my-ddns-sub-domain.mydomain.de
```

## Environment variables

| Name | Required? | Description |
| ---- | --------- | ----------- |
| DDNS_USERNAME | `true` | Username to authenticate on Domain Offensive's FlexDNS service. |
| DDNS_PASSWORD | `true` | Password to authenticate on Domain Offensive's FlexDNS service. |
| DDNS_HOSTNAME | `true` | Domain URI to update. |
| DDNS_CHECK_INTERVAL | `false` | Interval to check and update for IP changes. Default: `10m` |
| DDNS_CHECK_PUBLIC_IP_URL | `false` | API Url of IP-Adresse service. Defaults: `https://ifconfig.io/ip` |
| DDNS_CHECK_DNS_SERVER | `false` | DNS Server to check Domain entries. Default: `8.8.8.8` (Google's DNS) |

## Related Links

- https://www.do.de/wiki/flexdns-einrichtung/
- https://www.do.de/wiki/flexdns-entwickler/

## Thanks

- [ifconfig.io](https://ifconfig.io) for their IP address service
