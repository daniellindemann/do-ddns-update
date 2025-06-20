#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

sudo apt-get update -y && \
sudo apt-get install -y \
    dnsutils
