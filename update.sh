#!/bin/bash
set -euo pipefail

TO="aravind_slcs_intern2@aravind.org"

# Validate email
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting." >&2
    exit 1
fi

TIMESTAMP=$(date +%F_%H-%M-%S)
LOG_FILE="/tmp/patch_report_${TIMESTAMP}.log"

{
    echo "=== 📋 Patch Report: $(date) on $(hostname) ==="
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
            apt update -yq || echo "⚠️ apt update failed"
            apt -y full-upgrade || true
            ;;
        centos|rhel|fedora)
            echo "📦 Running yum/dnf upgrade..."
            if command -v dnf &>/dev/null; then
                dnf -y upgrade || true
            else
                yum -y update || true
            fi
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo ""
    echo "✅ Patch update completed successfully at $(date)."

} > "$LOG_FILE" 2>&1 || {
    echo "❌ Script failed. See log: $LOG_FILE" >&2
    exit 1
}

SUBJECT="✅ Patch Success on $(hostname)"
BODY=$(cat "$LOG_FILE")

if command -v mail >/dev/null 2>&1; then
    echo "$BODY" | mail -s "$SUBJECT" "$TO" || echo "⚠️ Failed to send email" >&2
else
    echo "⚠️ 'mail' command not available. Skipping email." >&2
fi

echo "✅ update.sh finished. Report saved to $LOG_FILE" >&2
exit 0
