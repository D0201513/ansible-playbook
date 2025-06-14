#!/bin/bash

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="/tmp/notify.log"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

log() {
    echo "[$CURRENT_DATE] $1" >> "$LOG_FILE"
}

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log "❌ Invalid email address format: $TO. Skipping email."
    exit 1
fi

log "🔁 Starting notify script on $HOSTNAME"

# Run apt update & upgrade with timeout (avoid hanging indefinitely)
UPDATE_OUTPUT=$(timeout 300 bash -c 'apt update && apt -y upgrade' 2>&1)
STATUS=$?

# Limit apt output to last 100 lines to prevent email overflow
TRIMMED_OUTPUT=$(echo "$UPDATE_OUTPUT" | tail -n 100)

SUBJECT="✅ System Patch Complete on $HOSTNAME"
BODY="🕒 Date: $CURRENT_DATE
📍 Host: $HOSTNAME

📦 APT Update Result (last 100 lines):
---------------------------------------
$TRIMMED_OUTPUT
"

# Send mail
if echo "$BODY" | mail -s "$SUBJECT" "$TO"; then
    log "✅ Patch notification sent to $TO from $HOSTNAME."
else
    log "❌ Failed to send patch notification email to $TO."
fi

# Log status of apt upgrade
if [[ $STATUS -ne 0 ]]; then
    log "⚠️ APT update/upgrade exited with non-zero status $STATUS."
else
    log "✅ APT update/upgrade completed successfully."
fi
