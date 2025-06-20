#!/bin/sh

# Default values for variables
DDNS_CHECK_INTERVAL="${DDNS_CHECK_INTERVAL:-10m}"
DDNS_CHECK_PUBLIC_IP_URL="${DDNS_CHECK_PUBLIC_IP_URL:-https://ifconfig.io/ip}"
DDNS_CHECK_DNS_SERVER="${DDNS_CHECK_DNS_SERVER:-8.8.8.8}"   # Google Public DNS
DDNS_UPDATE_URL="https://ddns.do.de/?hostname=%h&myip=%i"
DDNS_USERNAME="${DDNS_USERNAME}"
DDNS_PASSWORD="${DDNS_PASSWORD}"
DDNS_HOSTNAME="${DDNS_HOSTNAME}"

# Exit immediately if a command exits with a non-zero status
set -e

# Check if essential environment variables are set
if [ -z "$DDNS_USERNAME" ] || [ -z "$DDNS_PASSWORD" ] || [ -z "$DDNS_HOSTNAME" ]; then
  echo "Error: DDNS_USERNAME, DDNS_PASSWORD, and DDNS_HOSTNAME must be set as environment variables."
  exit 1
fi

# Function to get public IP using wget
get_public_ip() {
  wget -qO- "$DDNS_CHECK_PUBLIC_IP_URL"
}

get_dns_lookup_ip() {
  # Use dig to get the IP address for the DDNS hostname
  dig +short "$DDNS_HOSTNAME" @"$DDNS_CHECK_DNS_SERVER"
}

# Function to handle specific HTTP errors
handle_http_errors() {
  status_code="$1"
  response="$2"

  if [ "$status_code" -eq 400 ]; then
    if echo "$response" | grep -q "numhost"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Error 400: No resource record assigned to this DDNS/FlexDNS user in the domain zone."
    else
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Error 400: $response"
    fi
  elif [ "$status_code" -eq 401 ]; then
    if echo "$response" | grep -q "badauth"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Error 401: Authorization failed. Incorrect username or password."
    fi
  elif [ "$status_code" -eq 429 ]; then
    if echo "$response" | grep -q "toomanyrequests"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Error 429: Too many requests sent from your public IP or user account."
    fi
  elif [ "$status_code" -eq 500 ]; then
    if echo "$response" | grep -q "911"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Error 500: Fatal server error (911). Please contact support if this persists."
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Detailed response: $response"
      # exit 1
    fi
  else
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Unexpected HTTP status code: $status_code"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Response: $response"
  fi
}

# Function to update DDNS
update_ddns() {
  public_ip=$(get_public_ip)

  if [ -z "$public_ip" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error: Could not retrieve public IP address."
    return 1
  fi

  dns_lookup_ip=$(get_dns_lookup_ip)

  if [ -z "$dns_lookup_ip" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Error: Could not resolve DDNS hostname $DDNS_HOSTNAME via DNS server $DDNS_CHECK_DNS_SERVER."
    return 1
  fi

  if [ "$public_ip" = "$dns_lookup_ip" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S") - No update needed: Public IP ($public_ip) matches DNS lookup IP ($dns_lookup_ip)."
    return 0
  fi

  # Replace placeholders with hostname and IP
  url=$(echo "$DDNS_UPDATE_URL" | sed "s/%h/$DDNS_HOSTNAME/" | sed "s/%i/$public_ip/")

  # Perform the request and capture the response and HTTP status code
  # response=$(wget --user="$DDNS_USERNAME" --password="$DDNS_PASSWORD" --server-response -qO- "$url" 2>&1)
  authValue="$(echo -n "$DDNS_USERNAME:$DDNS_PASSWORD" | base64)"
  authorizationHeader="Authorization: Basic $authValue"
  response=$(wget --server-response --header "$authorizationHeader" -qO- "$url" 2>&1)
  # status_code=$(echo "$response" | grep -oP '(?<=HTTP/1.1 )\d+' | tail -n 1)
  status_code=$(echo "$response" | awk '/HTTP\/1\.1/ {print $2}')

  # Check for status code 200 and expected responses
  if [ "$status_code" == "200" ]; then
    if echo "$response" | grep -q "^good"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - DDNS update successful: $response"
    elif echo "$response" | grep -q "^nochg"; then
      echo "$(date +"%Y-%m-%d %H:%M:%S") - No change in IP address: $response"
    else
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Unexpected response: $response"
    fi
  else
    # Handle known HTTP errors
    handle_http_errors "$status_code" "$response"
  fi
}

# Main loop to run update every DDNS_CHECK_INTERVAL
while true; do
  update_ddns
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Next update in $DDNS_CHECK_INTERVAL"
  sleep "$DDNS_CHECK_INTERVAL"
done
