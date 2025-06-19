#!/bin/bash
set -euo pipefail

TO="aravind_slcs_intern2@aravind.org"

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting." >&2
    exit 1
fi

TIMESTAMP=$(date +%F_%H-%M-%S)
LOG_FILE="/tmp/patch_report_${TIMESTAMP}.log"
HOSTNAME=$(hostname)

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
            echo "📦 Running apt update and upgrade..."
            apt update -yq 2>&1 | grep -vE '^(W:|WARNING:)' || echo "⚠️ apt update failed"
            apt -y full-upgrade 2>&1 | grep -vE '^(W:|WARNING:)' || true
            ;;
        centos|rhel|fedora)
            echo "📦 Running yum/dnf upgrade..."
            if command -v dnf &>/dev/null; then
                dnf -y upgrade 2>&1 | grep -vE '^(W:|WARNING:)' || true
            else
                yum -y update 2>&1 | grep -vE '^(W:|WARNING:)' || true
            fi
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo ""
    echo "✅ Patch update completed successfully at $(date)."

    if [ -x /tmp/notify.sh ]; then
        echo ""
        echo "🔔 Running notify.sh helper script..."
        /tmp/notify.sh
    else
        echo "⚠️ notify.sh script not found or not executable."
    fi

} | tee "$LOG_FILE"

# Compose & send email
SUBJECT="✅ Patch Success on $HOSTNAME"
BODY=$(grep -vE '^(W:|WARNING:)' "$LOG_FILE")

if command -v mail >/dev/null 2>&1; then
    echo "$BODY" | mail -s "$SUBJECT" "$TO" || echo "⚠️ Failed to send email" >&2
else
    echo "⚠️ 'mail' command not available. Skipping email." >&2
fi

echo "✅ update.sh finished. Report saved to $LOG_FILE"
exit 0
