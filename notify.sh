#!/bin/bash

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="/tmp/patch_report.log"
HOSTNAME=$(hostname)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Validate email
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format: $TO" >&2
    exit 1
fi

# Prepare email
SUBJECT="✅ System Patch Report from $HOSTNAME"
BODY=$(cat "$LOG_FILE")

# Send email
if command -v mail >/dev/null 2>&1; then
    echo "$BODY" | mail -s "$SUBJECT" "$TO"
else
    echo "⚠️ 'mail' command not available. Skipping email." >&2
    exit 1
fi
