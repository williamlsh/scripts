#!/usr/bin/env bash

PRIVOXY="http://localhost:8118"

if ! command -v aria2c &>/dev/null; then
    echo "aria2c not found"
    exit 1
fi

if ! lsof -Pi "${PRIVOXY#*http://localhost}" -sTCP:LISTEN -t >/dev/null; then
    echo "Proxy is down"
    exit 1
fi

if [ -z "$1" ]; then
    echo "No input url specified"
    exit 1
fi

aria2c \
    --log-level=debug \
    --no-conf=true \
    --dir=. \
    --continue=true \
    --max-connection-per-server=16 \
    --min-split-size=5M \
    --on-download-complete=exit \
    --all-proxy="${PRIVOXY}" \
    "$1"
