#!/bin/bash
set -euo pipefail

LOG_FILE="/tmp/patch_report.log"
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
    echo "=== 📋 Patch Report: $TIMESTAMP on $HOSTNAME ==="
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
            timeout 300 bash -c 'apt update -yq 2>&1 | grep -vE "^W:|^WARNING:"'
            timeout 600 bash -c 'apt -y full-upgrade 2>&1 | grep -vE "^W:|^WARNING:"'
            ;;
        centos|rhel|fedora)
            echo "📦 Running yum/dnf upgrade..."
            if command -v dnf &>/dev/null; then
                dnf -y upgrade | grep -vE "^Warning:"
            else
                yum -y update | grep -vE "^Warning:"
            fi
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo ""
    echo "✅ Patch update completed successfully at $(date)."

} > "$LOG_FILE" 2>&1
