#!/bin/bash

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="/tmp/notify.log"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

log() {
    echo "[$CURRENT_DATE] $1" >> "$LOG_FILE"
}

# Validate email
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    log "❌ Invalid email address format: $TO"
    exit 1
fi

log "🔁 Starting notify script on $HOSTNAME"

# Run apt update & upgrade with timeout and filter out warnings
UPDATE_OUTPUT=$(timeout 300 bash -c 'apt update 2>&1 | grep -vE "^W:|^WARNING:" && apt -y upgrade 2>&1 | grep -vE "^W:|^WARNING:"')
STATUS=$?

# Trim output to prevent large email
TRIMMED_OUTPUT=$(echo "$UPDATE_OUTPUT" | tail -n 100)

SUBJECT="✅ System Patch Complete on $HOSTNAME"
BODY="🕒 Date: $CURRENT_DATE
📍 Host: $HOSTNAME

📦 APT Update Result (last 100 lines):
---------------------------------------
$TRIMMED_OUTPUT
"

# Send email
if echo "$BODY" | mail -s "$SUBJECT" "$TO"; then
    log "✅ Patch notification sent to $TO."
else
    log "❌ Failed to send notification email to $TO."
fi

# Log exit status
if [[ $STATUS -ne 0 ]]; then
    log "⚠️ APT exited with non-zero status $STATUS"
else
    log "✅ APT update/upgrade completed successfully"
fi
