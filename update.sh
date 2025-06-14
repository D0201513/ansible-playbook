#!/bin/bash
set -euo pipefail

TO="aravind_slcs_intern2@aravind.org"
TIMESTAMP=$(date +%F_%H-%M-%S)
LOG_FILE="/tmp/patch_report_${TIMESTAMP}.log"
MAX_RETRIES=30

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

    echo "⏳ Checking for APT lock..."
    for i in $(seq 1 $MAX_RETRIES); do
        if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            echo "⚠️ Waiting for APT lock (attempt $i)..."
            sleep 10
        else
            break
        fi
    done

    case "$OS_ID" in
        ubuntu|debian|kali)
            echo "📦 Running apt update and upgrade..."
            apt update -yq 2>&1 | grep -vE '^W:|^WARNING:' || echo "⚠️ apt update failed"
            apt -y full-upgrade 2>&1 | grep -vE '^W:|^WARNING:' || echo "⚠️ apt upgrade failed"
            ;;
        centos|rhel|fedora)
            echo "📦 Running yum/dnf upgrade..."
            if command -v dnf &>/dev/null; then
                dnf -y upgrade || echo "⚠️ dnf upgrade failed"
            else
                yum -y update || echo "⚠️ yum update failed"
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

# Call notify script after successful patch
bash /path/to/notify.sh "$LOG_FILE"
