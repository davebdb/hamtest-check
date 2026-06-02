#!/bin/bash

# ==============================================================================
# LINUX EXAM INTEGRITY AUDIT SCRIPT
# This script checks for Virtual Machines, active hypervisors, OBS Studio, 
# virtual camera drivers, and common chat applications.
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

echo "======================================================================"
echo "                   SYSTEM INTEGRITY AUDIT RUNNING                     "
echo "======================================================================"
echo "Proctor Instructions: Watch the output of each section carefully."
echo "----------------------------------------------------------------------"
echo ""

# ------------------------------------------------------------------------------
# CHECK 1: Is the test taker running the entire Linux OS inside a VM?
# ------------------------------------------------------------------------------
echo "--- [CHECK 1] GUEST VIRTUALIZATION STATUS ---"
echo "PROCTOR LOOK FOR: The word 'none'. Any other output means they are in a VM."
echo "Result:"

if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT_RESULT=$(systemd-detect-virt)
    echo "  Detected Environment: $VIRT_RESULT"
else
    # Fallback if systemd-detect-virt isn't available
    VIRT_RESULT=$(hostnamectl | grep -i "Virtualization" | awk '{print $2}')
    if [ -z "$VIRT_RESULT" ]; then
        echo "  Detected Environment: none (Physical Hardware)"
    else
        echo "  Detected Environment: $VIRT_RESULT"
    fi
fi
echo ""

# ------------------------------------------------------------------------------
# CHECK 2: Is the test taker HOSTING running VMs in the background?
# ------------------------------------------------------------------------------
echo "--- [CHECK 2] BACKGROUND VIRTUAL MACHINES ---"
echo "PROCTOR LOOK FOR: A blank result. Active lines mean a VM is running."
echo "Result:"

VM_PROCESSES=$(ps aux | grep -E "virtualbox|qemu|kvm|vmware" | grep -v grep)

if [ -z "$VM_PROCESSES" ]; then
    echo "  [PASS] No active background hypervisor processes detected."
else
    echo "  [WARNING] Active VM processes found!"
    echo "$VM_PROCESSES" | awk '{print "  -> Found active process: " $11}'
fi
echo ""

# ------------------------------------------------------------------------------
# CHECK 3: Is OBS Studio or video streaming software active?
# ------------------------------------------------------------------------------
echo "--- [CHECK 3] STREAMING / CAPTURE SOFTWARE ---"
echo "PROCTOR LOOK FOR: A blank result. If 'obs' shows up, they are running it."
echo "Result:"

OBS_CHECK=$(pgrep -fl obs)

if [ -z "$OBS_CHECK" ]; then
    echo "  [PASS] OBS Studio is not running."
else
    echo "  [WARNING] OBS Studio process detected!"
    echo "  -> $OBS_CHECK"
fi
echo ""

# ------------------------------------------------------------------------------
# CHECK 4: Are virtual/fake camera loopback modules loaded?
# ------------------------------------------------------------------------------
echo "--- [CHECK 4] VIRTUAL WEBCAM DRIVERS ---"
echo "PROCTOR LOOK FOR: 'No loopback driver loaded'. If 'v4l2loopback' appears,"
echo "                  they can feed pre-recorded video into Zoom."
echo "Result:"

if lsmod | grep -q "v4l2loopback"; then
    echo "  [WARNING] 'v4l2loopback' kernel module is LOADED."
    echo "            The student has the ability to spoof webcam footage."
else
    echo "  [PASS] No virtual camera loopback driver loaded."
fi
echo ""

# ------------------------------------------------------------------------------
# CHECK 5: Are external communication applications running?
# ------------------------------------------------------------------------------
echo "--- [CHECK 5] COMMUNICATION APPS ---"
echo "PROCTOR LOOK FOR: A blank result. Lines indicate active cheating pathways."
echo "Result:"

CHAT_PROCESSES=$(ps aux | grep -iE "discord|slack|telegram|stoat|teams" | grep -v grep)

if [ -z "$CHAT_PROCESSES" ]; then
    echo "  [PASS] Discord, Slack, Stoat, MS Teams and Telegram are closed."
else
    echo "  [WARNING] Communication apps are running in the background:"
    echo "$CHAT_PROCESSES" | awk '{print "  -> Active App: " $11}'
fi
echo ""

# ------------------------------------------------------------------------------
# CHECK 6: Display environment details
# ------------------------------------------------------------------------------
echo "--- [CHECK 6] DISPLAY ENVIRONMENT ---"
echo "PROCTOR LOOK FOR: Information only. If 'wayland' is shown, standard background"
echo "                  screen capture software might fail to capture hidden windows."
echo "Result:"
echo "  Session Type: $XDG_SESSION_TYPE"
echo ""

# ------------------------------------------------------------------------------
# CHECK 7: DISPLAY AND MONITOR COUNT
# ------------------------------------------------------------------------------
echo "--- [CHECK 7] CONNECTED MONITORS ---"
echo "PROCTOR LOOK FOR: 'Monitors: 1'. If it says 2 or more, an extra screen is active."
echo "Result:"

# Attempt to use xrandr first
if command -v xrandr >/dev/null 2>&1; then
    MONITOR_COUNT=$(xrandr --listmonitors | grep "Monitors:" | awk '{print $2}')
    if [ ! -z "$MONITOR_COUNT" ]; then
        if [ "$MONITOR_COUNT" -eq 1 ]; then
            echo "  [PASS] Only 1 active monitor detected via xrandr."
        else
            echo "  [WARNING] Multiple monitors detected ($MONITOR_COUNT active screens)!"
            xrandr --listmonitors | grep -E "^ [0-9]:" | awk '{print "  -> Screen Details: " $4}'
        fi
    fi
else
    # Sysfs fallback if xrandr is missing (common in minimal Wayland environments)
    SYS_MONITORS=$(grep -v "^disconnected$" /sys/class/drm/card*-*/status | wc -l)
    if [ "$SYS_MONITORS" -eq 1 ]; then
        echo "  [PASS] Only 1 hardware display connection detected."
    else
        echo "  [WARNING] Multiple hardware display connections found ($SYS_MONITORS detected)!"
    fi
fi
echo ""



echo "======================================================================"
echo "                        END OF INTEGRITY AUDIT                        "
echo "======================================================================"

echo ""
echo ""

# ------------------------------------------------------------------------------
# MISC : MISC commands not yet integrated for automated checks
# ------------------------------------------------------------------------------

echo "--- [MISC] MISC commands not yet integrated into the main script for checking ---"
echo "running:  'who' command"
who

