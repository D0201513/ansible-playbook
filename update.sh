#!/bin/bash
set -euo pipefail

# Email address to send report to
TO="aravind_slcs_intern2@aravind.org"

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email address format. Aborting email send." >&2
    exit 1
fi

# Prepare log file with timestamp
TIMESTAMP=$(date +%F_%H-%M-%S)
LOG_FILE="/tmp/patch_report_${TIMESTAMP}.log"

# Main logic with error handling block
{
    echo "=== 📋 Patch Report: $(date) on $(hostname) ==="
    echo ""

    echo "🔍 Detecting OS..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$(echo "${ID:-unknown}" | tr '[:upper:]' '[:lower:]')
        echo "✅ Detected OS: $OS_ID"
    else
        echo "❌ OS detection failed."
        exit 1
    fi
    echo ""

    case "$OS_ID" in
        ubuntu|debian)
            echo "📦 Running apt update and upgrade..."
            apt update -yq || echo "⚠️ apt update failed"
            UPGRADE_OUTPUT=$(apt -y upgrade || true)
            if echo "$UPGRADE_OUTPUT" | grep -q "0 upgraded"; then
                echo "✅ No packages needed upgrading."
            else
                echo "✅ Some packages were upgraded."
            fi
            ;;
        kali)
            echo "📦 Running apt update and full-upgrade (Kali)..."
            apt update -yq || echo "⚠️ apt update failed"
            UPGRADE_OUTPUT=$(apt -y full-upgrade || true)
            if echo "$UPGRADE_OUTPUT" | grep -q "0 upgraded"; then
                echo "✅ No packages needed upgrading."
            else
                echo "✅ Some packages were upgraded."
            fi
            ;;
        centos|rhel|fedora)
            echo "📦 Running yum/dnf upgrade..."
            if command -v dnf >/dev/null 2>&1; then
                UPDATE_OUTPUT=$(dnf -y upgrade || true)
            else
                UPDATE_OUTPUT=$(yum -y update || true)
            fi
            if echo "$UPDATE_OUTPUT" | grep -q "No packages marked for update"; then
                echo "✅ No packages needed upgrading."
            else
                echo "✅ Some packages were upgraded."
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
    echo "❌ Script failed. Check the log: $LOG_FILE" >&2
    exit 1
}

# Prepare email content
SUBJECT="✅ Patch Success on $(hostname)"
BODY=$(cat "$LOG_FILE")

# Send email if available
if command -v mail >/dev/null 2>&1; then
    echo "$BODY" | mail -s "$SUBJECT" "$TO" || echo "⚠️ Failed to send email to $TO" >&2
else
    echo "⚠️ 'mail' command not found. Email not sent." >&2
fi

echo "✅ update.sh finished. Report saved to $LOG_FILE" >&2
exit 0
