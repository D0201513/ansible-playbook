#!/bin/bash
set -euo pipefail

TO="aravind_slcs_intern2@aravind.org"
TIMESTAMP=$(date +%F_%H-%M-%S)
LOG_FILE="/tmp/patch_report_${TIMESTAMP}.log"
HOSTNAME=$(hostname)

# Validate email
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting." >&2
    exit 1
fi

# APT lock wait protection
LOCK_TIMEOUT=60
WAIT_TIME=0
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    if [ "$WAIT_TIME" -ge "$LOCK_TIMEOUT" ]; then
        echo "❌ APT lock held too long. Aborting." >> "$LOG_FILE"
        exit 1
    fi
    echo "⏳ Waiting for APT lock... ($WAIT_TIME/$LOCK_TIMEOUT)" >> "$LOG_FILE"
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
done

{
    echo "=== 📋 Patch Report: $(date) on $HOSTNAME ==="
    echo ""

    echo "🔍 Detecting OS..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID,,}"
        echo "✅ Detected OS: $OS_ID"
    else
        echo "❌ OS detection failed."
        exit 1
    fi
    echo ""

    case "$OS_ID" in
        ubuntu|debian|kali)
            echo "📦 Running apt update and full-upgrade..."
            apt update 2>&1 | grep -vE "^W:|^WARNING:"
            apt -y full-upgrade 2>&1 | grep -vE "^W:|^WARNING:"
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo ""
    echo "✅ Patch update completed successfully at $(date)."
} >> "$LOG_FILE" 2>&1

# ✅ Call notify.sh to send report
bash /tmp/notify.sh "$LOG_FILE"
