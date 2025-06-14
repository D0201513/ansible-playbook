#!/bin/bash

# File: /path/to/notify.sh

LOG_FILE="/tmp/notify_helper.log"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# Logging function
log() {
    echo "[$CURRENT_DATE] $1" >> "$LOG_FILE"
}

# Start logging
log "🔁 notify.sh executed on $HOSTNAME"

# System info log (customize if needed)
OS_INFO=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
log "🖥️  System Info: $OS_INFO"
log "🕒 Timestamp: $CURRENT_DATE"
log "✅ This script is only for helper logging. No mail is sent."
