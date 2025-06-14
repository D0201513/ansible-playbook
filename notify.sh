#!/bin/bash

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="${1:-}"

if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
    echo "❌ No valid log file provided to notify.sh. Aborting." >&2
    exit 1
fi

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting." >&2
    exit 1
fi

SUBJECT="✅ Patch Completed on $(hostname)"
BODY=$(cat "$LOG_FILE")

# Send email
if command -v mail >/dev/null 2>&1; then
    echo "$BODY" | mail -s "$SUBJECT" "$TO" || echo "⚠️ Failed to send email." >&2
else
    echo "⚠️ 'mail' command not available. Skipping email." >&2
fi
