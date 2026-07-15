#!/bin/bash

# ==============================================================================
# LINUX EXAM INTEGRITY AUDIT SCRIPT
# This script checks for Virtual Machines, active hypervisors, streaming software,
# virtual camera drivers, communication apps, remote access tools, containers,
# input automation, VPNs, AI/LLM tools, screen recorders, browser automation,
# clipboard managers, cloud sync services, and suspicious network listeners.
# Works across Debian/Ubuntu, RHEL/Fedora, and Arch Linux.
#
# Initial framework created with Google Gemini, additional checks,
# tweaks, and coding by @davebdb
#
# The intent on this script is to help online VEs in detecting cheating methods
# used by test takers.  This shouldn't be the only method, but a start
# on a way to check for common cheating methods.  Please feel free to submit
# additional checks, or notes on other things to look at.
# ==============================================================================

# Clear the terminal screen for a clean starting point on the Zoom share
clear

# ---------------------------------------------------------------------------
# Result storage — each check writes to these arrays, table prints at end
# ---------------------------------------------------------------------------
declare -a CHECK_NAME
declare -a CHECK_STATUS
declare -a CHECK_DETAIL

TOTAL_CHECKS=21

# Helper: record a result for check $1
record() {
    local n="$1" status="$2" detail="$3"
    CHECK_STATUS[$n]="$status"
    CHECK_DETAIL[$n]="$detail"
    # Progress bar
    local filled=$(( n * 30 / TOTAL_CHECKS ))
    local empty=$(( 30 - filled ))
    local bar=$(printf '%*s' "$filled" '' | tr ' ' '#')
    local bar_empty=$(printf '%*s' "$empty" '' | tr ' ' '-')
    printf "\r  [%s%s] %d/%d" "$bar" "$bar_empty" "$n" "$TOTAL_CHECKS"
}

# Colors (degrade gracefully if terminal doesn't support)
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null)" -ge 8 ] 2>/dev/null; then
    GREEN=$'\033[0;32m'
    RED=$'\033[0;31m'
    CYAN=$'\033[0;36m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
else
    GREEN=""
    RED=""
    CYAN=""
    BOLD=""
    RESET=""
fi

echo "======================================================================"
echo "                   SYSTEM INTEGRITY AUDIT RUNNING                     "
echo "======================================================================"
echo "Proctor Instructions: Review the summary table and warnings below."
echo "----------------------------------------------------------------------"
echo ""

# ===========================================================================
# CHECK 1: Guest Virtualization Status
# ===========================================================================
CHECK_NAME[1]="Guest Virtualization"

if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT_RESULT=$(systemd-detect-virt)
else
    VIRT_RESULT=$(hostnamectl | grep -i "Virtualization" | awk '{print $2}')
    if [ -z "$VIRT_RESULT" ]; then
        VIRT_RESULT="none (Physical Hardware)"
    fi
fi

if [ "$VIRT_RESULT" = "none" ]; then
    record 1 "PASS" "none (Physical Hardware)"
else
    record 1 "WARNING" "Running inside: $VIRT_RESULT"
fi

# ===========================================================================
# CHECK 2: Background Virtual Machines
# ===========================================================================
CHECK_NAME[2]="Background VMs"

VM_PROCESSES=$(ps aux | grep -E "virtualbox|qemu|kvm|vmware" | grep -v grep)

if [ -z "$VM_PROCESSES" ]; then
    record 2 "PASS" "No hypervisor processes"
else
    VM_LIST=$(echo "$VM_PROCESSES" | awk '{print $11}' | tr '\n' ', ' | sed 's/,$//')
    record 2 "WARNING" "Found: $VM_LIST"
fi

# ===========================================================================
# CHECK 3: Streaming / Capture Software (OBS)
# ===========================================================================
CHECK_NAME[3]="Streaming/Capture (OBS)"

OBS_CHECK=$(pgrep -fl obs 2>/dev/null)

if [ -z "$OBS_CHECK" ]; then
    record 3 "PASS" "OBS not running"
else
    OBS_NAME=$(echo "$OBS_CHECK" | awk '{print $2}' | head -1)
    record 3 "WARNING" "OBS process active: $OBS_NAME"
fi

# ===========================================================================
# CHECK 4: Virtual Webcam Drivers
# ===========================================================================
CHECK_NAME[4]="Virtual Webcam Drivers"

if lsmod | grep -q "v4l2loopback"; then
    record 4 "WARNING" "v4l2loopback module LOADED"
else
    record 4 "PASS" "No loopback driver"
fi

# ===========================================================================
# CHECK 5: Communication Apps
# ===========================================================================
CHECK_NAME[5]="Communication Apps"

CHAT_PROCESSES=$(ps aux | grep -iE "discord|slack|telegram|stoat|teams" | grep -v grep)

if [ -z "$CHAT_PROCESSES" ]; then
    record 5 "PASS" "None detected"
else
    CHAT_LIST=$(echo "$CHAT_PROCESSES" | awk '{print $11}' | tr '\n' ', ' | sed 's/,$//')
    record 5 "WARNING" "Found: $CHAT_LIST"
fi

# ===========================================================================
# CHECK 6: Display Environment
# ===========================================================================
CHECK_NAME[6]="Display Environment"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    record 6 "INFO" "Wayland — some screen capture may be limited"
elif [ "$XDG_SESSION_TYPE" = "x11" ]; then
    record 6 "PASS" "X11"
else
    record 6 "INFO" "$XDG_SESSION_TYPE (unknown type)"
fi

# ===========================================================================
# CHECK 7: Connected Monitors
# ===========================================================================
CHECK_NAME[7]="Connected Monitors"

if command -v xrandr >/dev/null 2>&1; then
    MONITOR_COUNT=$(xrandr --listmonitors | grep "Monitors:" | awk '{print $2}')
    if [ -n "$MONITOR_COUNT" ]; then
        if [ "$MONITOR_COUNT" -eq 1 ]; then
            record 7 "PASS" "1 monitor"
        else
            MONITOR_DETAILS=$(xrandr --listmonitors | grep -E "^ [0-9]:" | awk '{print $4}' | tr '\n' ', ' | sed 's/,$//')
            record 7 "WARNING" "$MONITOR_COUNT monitors: $MONITOR_DETAILS"
        fi
    else
        record 7 "INFO" "xrandr returned no count"
    fi
else
    SYS_MONITORS=$(grep -v "^disconnected$" /sys/class/drm/card*-*/status 2>/dev/null | wc -l)
    if [ "$SYS_MONITORS" -eq 1 ]; then
        record 7 "PASS" "1 display (sysfs)"
    else
        record 7 "WARNING" "$SYS_MONITORS displays (sysfs)"
    fi
fi

# ===========================================================================
# CHECK 8: Remote Access Tools
# ===========================================================================
CHECK_NAME[8]="Remote Access Tools"

REMOTE_ACCESS=$(pgrep -fl "vnc|xrdp|remmina|teamviewer|anydesk|rustdesk|novnc|tigervnc|x11vnc" 2>/dev/null)

if [ -z "$REMOTE_ACCESS" ]; then
    record 8 "PASS" "None detected"
else
    RA_LIST=$(echo "$REMOTE_ACCESS" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 8 "WARNING" "Found: $RA_LIST"
fi

# ===========================================================================
# CHECK 9: Screen Recording Tools
# ===========================================================================
CHECK_NAME[9]="Screen Recorders"

SCREEN_RECORDERS=$(pgrep -fl "kazam|simple-screencast|vokoscreen|peek|wf-recorder|spectacle|gnome-screenshot|obs" 2>/dev/null)

if [ -z "$SCREEN_RECORDERS" ]; then
    record 9 "PASS" "None detected"
else
    SR_LIST=$(echo "$SCREEN_RECORDERS" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 9 "WARNING" "Found: $SR_LIST"
fi

# ===========================================================================
# CHECK 10: Container Runtimes
# ===========================================================================
CHECK_NAME[10]="Container Runtimes"

CONTAINER_CHECK=$(pgrep -fl "dockerd|containerd|podman" 2>/dev/null)
CONTAINER_DETAIL=""

if [ -n "$CONTAINER_CHECK" ]; then
    CR_LIST=$(echo "$CONTAINER_CHECK" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    CONTAINER_DETAIL="Runtime: $CR_LIST"
fi

if command -v docker >/dev/null 2>&1; then
    DOCKER_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null)
    if [ -n "$DOCKER_CONTAINERS" ]; then
        DC_LIST=$(echo "$DOCKER_CONTAINERS" | tr '\n' ', ' | sed 's/,$//')
        if [ -n "$CONTAINER_DETAIL" ]; then
            CONTAINER_DETAIL="$CONTAINER_DETAIL; Containers: $DC_LIST"
        else
            CONTAINER_DETAIL="Containers: $DC_LIST"
        fi
    fi
fi

if [ -z "$CONTAINER_DETAIL" ]; then
    record 10 "PASS" "None detected"
else
    record 10 "WARNING" "$CONTAINER_DETAIL"
fi

# ===========================================================================
# CHECK 11: Input Automation Tools
# ===========================================================================
CHECK_NAME[11]="Input Automation"

INPUT_AUTO=$(pgrep -fl "xdotool|ydotool|autokey|python.*pyautogui|python.*pywinauto" 2>/dev/null)

if [ -z "$INPUT_AUTO" ]; then
    record 11 "PASS" "None detected"
else
    IA_LIST=$(echo "$INPUT_AUTO" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 11 "WARNING" "Found: $IA_LIST"
fi

# ===========================================================================
# CHECK 12: VPN / Tunnels
# ===========================================================================
CHECK_NAME[12]="VPN / Tunnels"

VPN_CHECK=$(pgrep -fl "openvpn|wireguard|wg-quick|ssh.*-L|ssh.*-D|ssh.*-R" 2>/dev/null)
VPN_DETAIL=""

if [ -n "$VPN_CHECK" ]; then
    VP_LIST=$(echo "$VPN_CHECK" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    VPN_DETAIL="Processes: $VP_LIST"
fi

if ls /sys/class/net/ 2>/dev/null | grep -q "^wg"; then
    WG_IFS=$(ls /sys/class/net/ | grep "^wg" | tr '\n' ', ' | sed 's/,$//')
    if [ -n "$VPN_DETAIL" ]; then
        VPN_DETAIL="$VPN_DETAIL; Interfaces: $WG_IFS"
    else
        VPN_DETAIL="Interfaces: $WG_IFS"
    fi
fi

if [ -z "$VPN_DETAIL" ]; then
    record 12 "PASS" "None detected"
else
    record 12 "WARNING" "$VPN_DETAIL"
fi

# ===========================================================================
# CHECK 13: Clipboard Managers
# ===========================================================================
CHECK_NAME[13]="Clipboard Managers"

CLIPBOARD=$(pgrep -fl "clipit|parcellite|copyq|xclip|wl-clip|clipman|grim" 2>/dev/null)

if [ -z "$CLIPBOARD" ]; then
    record 13 "PASS" "None detected"
else
    CB_LIST=$(echo "$CLIPBOARD" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 13 "WARNING" "Found: $CB_LIST"
fi

# ===========================================================================
# CHECK 14: Local AI / LLM Tools
# ===========================================================================
CHECK_NAME[14]="Local AI / LLM Tools"

AI_TOOLS=$(pgrep -fl "ollama|llama.cpp|text-generation-webui|langchain|lmstudio|jan.ai|gorilla" 2>/dev/null)

if [ -z "$AI_TOOLS" ]; then
    record 14 "PASS" "None detected"
else
    AI_LIST=$(echo "$AI_TOOLS" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 14 "WARNING" "Found: $AI_LIST"
fi

# ===========================================================================
# CHECK 15: Browser Automation
# ===========================================================================
CHECK_NAME[15]="Browser Automation"

BROWSER_AUTO=$(pgrep -fl "selenium|chromedriver|geckodriver|playwright|puppeteer|firefox.*-marionette" 2>/dev/null)

if [ -z "$BROWSER_AUTO" ]; then
    record 15 "PASS" "None detected"
else
    BA_LIST=$(echo "$BROWSER_AUTO" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 15 "WARNING" "Found: $BA_LIST"
fi

# ===========================================================================
# CHECK 16: Cloud Sync Services
# ===========================================================================
CHECK_NAME[16]="Cloud Sync Services"

CLOUD_SYNC=$(pgrep -fl "dropbox|insync|rclone|onedrive|nextcloud|syncthing|seafile|cyberduck" 2>/dev/null)

if [ -z "$CLOUD_SYNC" ]; then
    record 16 "PASS" "None detected"
else
    CS_LIST=$(echo "$CLOUD_SYNC" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    record 16 "WARNING" "Found: $CS_LIST"
fi

# ===========================================================================
# CHECK 17: Process Hiding Potential
# ===========================================================================
CHECK_NAME[17]="Process Hiding (ptrace)"

if [ -f /proc/sys/kernel/yama/ptrace_scope ]; then
    PTRACE_VAL=$(cat /proc/sys/kernel/yama/ptrace_scope)
    if [ "$PTRACE_VAL" -eq 0 ]; then
        record 17 "WARNING" "ptrace_scope=0 (unrestricted)"
    else
        record 17 "PASS" "ptrace_scope=$PTRACE_VAL (restricted)"
    fi
else
    record 17 "INFO" "Yama LSM not available"
fi

# ===========================================================================
# CHECK 18: Suspicious Network Listeners
# ===========================================================================
CHECK_NAME[18]="Network Listeners"

LISTENER_DETAIL=""

if command -v ss >/dev/null 2>&1; then
    LISTENERS=$(ss -tlnp 2>/dev/null | grep -v "^State\|^Netid" | grep -v ":\(22\|6010\|6011\|631\|177\)" | grep -v "127.0.0.1:" | grep -v "localhost")
    if [ -n "$LISTENERS" ]; then
        LISTENER_DETAIL=$(echo "$LISTENERS" | awk '{print $4}' | tr '\n' ', ' | sed 's/,$//')
    fi
elif command -v netstat >/dev/null 2>&1; then
    LISTENERS=$(netstat -tlnp 2>/dev/null | grep "LISTEN" | grep -v ":\(22\|6010\|6011\|631\|177\)" | grep -v "127.0.0.1:" | grep -v "localhost")
    if [ -n "$LISTENERS" ]; then
        LISTENER_DETAIL=$(echo "$LISTENERS" | awk '{print $4}' | tr '\n' ', ' | sed 's/,$//')
    fi
else
    LISTENER_DETAIL="ss/netstat not available"
fi

if [ -z "$LISTENER_DETAIL" ]; then
    record 18 "PASS" "No suspicious listeners"
elif [ "$LISTENER_DETAIL" = "ss/netstat not available" ]; then
    record 18 "INFO" "$LISTENER_DETAIL"
else
    record 18 "WARNING" "External ports: $LISTENER_DETAIL"
fi

# ===========================================================================
# CHECK 19: Active TTY Sessions
# ===========================================================================
CHECK_NAME[19]="Active TTY Sessions"

TTY_COUNT=$(who 2>/dev/null | wc -l)
if [ "$TTY_COUNT" -le 1 ]; then
    record 19 "PASS" "$TTY_COUNT session(s)"
else
    TTY_LIST=$(who 2>/dev/null | awk '{print $1 "("$tty")"}' | tr '\n' ', ' | sed 's/,$//')
    record 19 "WARNING" "$TTY_COUNT sessions: $TTY_LIST"
fi

# ===========================================================================
# CHECK 20: Script Self-Integrity (SHA256)
# ===========================================================================
CHECK_NAME[20]="Script Integrity (SHA256)"

SCRIPT_PATH="$(readlink -f "$0")"
if command -v sha256sum >/dev/null 2>&1; then
    SCRIPT_HASH=$(sha256sum "$SCRIPT_PATH" | awk '{print $1}')
    record 20 "INFO" "$SCRIPT_HASH"
elif command -v shasum >/dev/null 2>&1; then
    SCRIPT_HASH=$(shasum -a 256 "$SCRIPT_PATH" | awk '{print $1}')
    record 20 "INFO" "$SCRIPT_HASH"
else
    record 20 "INFO" "sha256sum not available"
fi

# ===========================================================================
# CHECK 21: Browser Windows / Tabs
# ===========================================================================
CHECK_NAME[21]="Browser Windows"

BROWSER_DETAIL=""

if command -v xdotool >/dev/null 2>&1; then
    CHROME_WIN=$(xdotool search --class "chrome" | wc -l)
    CHROMIUM_WIN=$(xdotool search --class "chromium" | wc -l)
    BRAVE_WIN=$(xdotool search --class "brave" | wc -l)
    EDGE_WIN=$(xdotool search --class "microsoft-edge" | wc -l)
    FIREFOX_WIN=$(xdotool search --class "firefox" | wc -l)

    TOTAL_BW=$((CHROME_WIN + CHROMIUM_WIN + BRAVE_WIN + EDGE_WIN + FIREFOX_WIN))

    if [ "$TOTAL_BW" -eq 0 ]; then
        BROWSER_DETAIL="No browser windows"
        BROWSER_STATUS="INFO"
    else
        BW_PARTS=""
        [ "$CHROME_WIN" -gt 0 ] && BW_PARTS="${BW_PARTS:+$BW_PARTS; }Chrome:$CHROME_WIN"
        [ "$CHROMIUM_WIN" -gt 0 ] && BW_PARTS="${BW_PARTS:+$BW_PARTS; }Chromium:$CHROMIUM_WIN"
        [ "$BRAVE_WIN" -gt 0 ] && BW_PARTS="${BW_PARTS:+$BW_PARTS; }Brave:$BRAVE_WIN"
        [ "$EDGE_WIN" -gt 0 ] && BW_PARTS="${BW_PARTS:+$BW_PARTS; }Edge:$EDGE_WIN"
        [ "$FIREFOX_WIN" -gt 0 ] && BW_PARTS="${BW_PARTS:+$BW_PARTS; }Firefox:$FIREFOX_WIN"
        BROWSER_DETAIL="$TOTAL_BW windows — $BW_PARTS"
        BROWSER_STATUS="WARNING"
    fi
elif command -v wmctrl >/dev/null 2>&1; then
    BROWSER_LIST=$(wmctrl -l -x 2>/dev/null | grep -iE "chrome|chromium|firefox|brave|edge" | wc -l)
    if [ "$BROWSER_LIST" -eq 0 ]; then
        BROWSER_DETAIL="No browser windows"
        BROWSER_STATUS="INFO"
    else
        BROWSER_DETAIL="$BROWSER_LIST browser window(s)"
        BROWSER_STATUS="WARNING"
    fi
else
    BROWSER_PROCS=$(pgrep -fl "chrome|chromium|firefox|brave|edge" 2>/dev/null)
    if [ -z "$BROWSER_PROCS" ]; then
        BROWSER_DETAIL="No browser processes"
        BROWSER_STATUS="INFO"
    else
        BP_LIST=$(echo "$BROWSER_PROCS" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
        BROWSER_DETAIL="Running: $BP_LIST"
        BROWSER_STATUS="WARNING"
    fi
fi

# Check for browser automation flags
AUTO_FLAGS=$(ps aux | grep -E "chrome.*(--remote-debugging|--headless).*--user-data-dir|firefox.*-marionette" | grep -v grep)
if [ -n "$AUTO_FLAGS" ]; then
    BROWSER_DETAIL="$BROWSER_DETAIL; automation flags detected"
    BROWSER_STATUS="WARNING"
fi

record 21 "$BROWSER_STATUS" "$BROWSER_DETAIL"

# ===========================================================================
# PRINT SUMMARY TABLE
# ===========================================================================
echo ""  # finish progress bar line

echo ""
echo "======================================================================"
echo "                        INTEGRITY AUDIT RESULTS                       "
echo "======================================================================"
echo ""

# Column widths
CW_NUM=4
CW_NAME=30
CW_STATUS=10
CW_DETAIL=58

# Box drawing chars
TL="┌"; TR="┐"; BL="└"; BR="┘"
CRSS="┼"; V="│"

# Horizontal rule — leading space matches data row format
hline() {
    local c1="$TL" c2="$TR"
    [ "${1:-top}" = "bottom" ] && c1="$BL" && c2="$BR"
    printf ' %s%s%s%s%s%s%s%s%s\n' \
        "$c1" "$(printf '%*s' $((CW_NUM+2)) '' | tr ' ' '─')" \
        "$CRSS" "$(printf '%*s' $((CW_NAME+2)) '' | tr ' ' '─')" \
        "$CRSS" "$(printf '%*s' $((CW_STATUS+2)) '' | tr ' ' '─')" \
        "$CRSS" "$(printf '%*s' $((CW_DETAIL+2)) '' | tr ' ' '─')" \
        "$c2"
}

# Fit string to column width; handles ANSI color codes correctly.
# Strips codes for visible-length calc, then re-applies with padding inside color.
fit() {
    local raw="$1" w="$2"
    # Strip ANSI escape codes to get visible text
    local vis=$(printf '%s' "$raw" | sed 's/\x1b\[[0-9;]*m//g')
    local pad=$(( w - ${#vis} ))
    if [ "$pad" -lt 0 ]; then
        # Truncate visible text, return plain (no color on truncated strings)
        printf '%.*s' "$w" "$vis"
    elif [ "$pad" -eq 0 ]; then
        printf '%s' "$raw"
    else
        # Check if input has color codes
        local prefix="" suffix=""
        if [ "$raw" != "$vis" ]; then
            # Extract prefix (everything up to first visible char) and suffix (last reset code)
            prefix=$(printf '%s' "$raw" | sed 's/\(.*\)\x1b\[[0-9;]*m.*/\1/' | head -c20)
            # Simpler: just grab leading and trailing escape sequences
            prefix="${raw%%"$vis"*}"
            suffix="${raw##*"$vis"}"
            local spaces=$(printf '%*s' "$pad")
            printf '%s%s%s%s' "$prefix" "$vis" "$spaces" "$suffix"
        else
            printf '%s' "$raw"
            printf '%*s' "$pad" ''
        fi
    fi
}

# Single format string for ALL rows (header + data)
FMT=" ${V} %-${CW_NUM}s ${V} %-${CW_NAME}s ${V} %-${CW_STATUS}s ${V} %-${CW_DETAIL}s ${V}"

# Table header
hline
printf "${FMT}\n" "#" "CHECK" "STATUS" "DETAILS"
hline

# Count results
PASS_COUNT=0
WARN_COUNT=0
INFO_COUNT=0
WARN_LIST=""

for i in $(seq 1 $TOTAL_CHECKS); do
    s="${CHECK_STATUS[$i]}"
    d="${CHECK_DETAIL[$i]}"
    n="${CHECK_NAME[$i]}"

    # Color the status
    local_s="$s"
    case "$s" in
        PASS)    local_s="${GREEN}${s}${RESET}" ; PASS_COUNT=$((PASS_COUNT+1)) ;;
        WARNING) local_s="${RED}${s}${RESET}"   ; WARN_COUNT=$((WARN_COUNT+1))
                 WARN_LIST="${WARN_LIST}  ${RED}[${i}]${RESET} ${CHECK_NAME[$i]}: ${d}\n"
                 ;;
        INFO)    local_s="${CYAN}${s}${RESET}"  ; INFO_COUNT=$((INFO_COUNT+1)) ;;
    esac

    printf "${FMT}\n" "$i" "$(fit "$n" $CW_NAME)" "$(fit "$local_s" $CW_STATUS)" "$(fit "$d" $CW_DETAIL)"
done

hline bottom

# Summary
echo ""
printf "Summary: ${GREEN}%d PASS${RESET}, ${RED}%d WARNING${RESET}, ${CYAN}%d INFO${RESET}\n" \
    "$PASS_COUNT" "$WARN_COUNT" "$INFO_COUNT"

# Warning details
if [ "$WARN_COUNT" -gt 0 ]; then
    echo ""
    echo "${RED}${BOLD}⚠ WARNINGS — Proctor should investigate:${RESET}"
    echo -e "$WARN_LIST"
fi

# Script integrity note
echo ""
echo "Script: $SCRIPT_PATH"
if [ -n "$SCRIPT_HASH" ]; then
    echo "SHA256: $SCRIPT_HASH"
    echo "PROCTOR: Verify hash matches published value for your exam."
fi

echo ""
echo "======================================================================"
echo "                        END OF INTEGRITY AUDIT                        "
echo "======================================================================"

echo ""
echo ""

# ------------------------------------------------------------------------------
# MISC : PATH verification & command locations
# ------------------------------------------------------------------------------

echo "--- [MISC] PATH & COMMAND VERIFICATION ---"
echo ""
echo "The \$PATH variable contains the execution path of commands."
echo "If /home/ or /local/ appears before /usr/bin, /bin, /usr/sbin —"
echo "custom binaries may run before system defaults."
echo ""
echo "\$PATH = $PATH"
echo ""
echo "Command locations (look for /local/ or /home/ paths):"
printf "  %-22s %s\n" "awk" "$(which awk 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "echo" "$(which echo 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "grep" "$(which grep 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "hostnamectl" "$(which hostnamectl 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "lsmod" "$(which lsmod 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "ps" "$(which ps 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "systemd-detect-virt" "$(which systemd-detect-virt 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "which" "$(which which 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "who" "$(which who 2>/dev/null || echo 'not found')"
printf "  %-22s %s\n" "xrandr" "$(which xrandr 2>/dev/null || echo 'not found')"
echo ""
