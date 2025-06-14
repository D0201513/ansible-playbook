#!/bin/bash
set -euo pipefail

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="${1:-/tmp/patch_report_default.log}"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# Validate email
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting." >&2
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found: $LOG_FILE" >&2
    exit 1
fi

SUBJECT="✅ Patch Completed on $HOSTNAME"
BODY=$(grep -vE '^W:|^WARNING:' "$LOG_FILE" | tail -n 100)

if echo "$BODY" | mail -s "$SUBJECT" "$TO"; then
    echo "✅ Patch notification sent to $TO."
else
    echo "❌ Failed to send patch notification to $TO." >&2
fi
