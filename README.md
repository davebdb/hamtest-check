# hamtest-check

Linux Exam Integrity Audit scripts for ham radio license examinations.

These scripts help Volunteer Examiners (VEs) detect common cheating methods used by remote test takers during online exams. **This should not be the only method of verification** — it is a starting point for identifying potential integrity issues.

---

## Quick Start

```bash
chmod +x audit1.sh
./audit1.sh
```

The script clears the terminal, runs all 21 checks with a progress bar, then displays a **summary table** with color-coded results:

```
┌────┬────────────────────────────┬───────────┬──────────────────────────────────────┐
│ #  │ CHECK                      │ STATUS    │ DETAILS                              │
├────┼────────────────────────────┼───────────┼──────────────────────────────────────┤
│ 1  │ Guest Virtualization       │ PASS      │ none (Physical Hardware)             │
│ 2  │ Background VMs             │ PASS      │ No hypervisor processes              │
│ 5  │ Communication Apps         │ WARNING   │ Found: discord, teams                │
│... │ ...                        │ ...       │ ...                                  │
│21  │ Browser Windows            │ WARNING   │ 3 windows — Chrome:2, Firefox:1      │
└────┴────────────────────────────┴───────────┴──────────────────────────────────────┘

Summary: 17 PASS, 3 WARNING, 1 INFO

⚠ WARNINGS — Proctor should investigate:
  [5] Communication Apps: Found: discord, teams
  [21] Browser Windows: 3 windows — Chrome:2, Firefox:1
```

Results are **color-coded**: <span style="color:green">**PASS** (green)</span>, <span style="color:red">**WARNING** (red)</span>, <span style="color:cyan">**INFO** (cyan)</span>. Colors degrade gracefully in terminals that don't support them.

---

## Quick-Reference: How to Pass Each Check

| #  | Check | Action Required |
|----|-------|-----------------|
| 1  | Guest Virtualization | Run the exam on **physical hardware**, not a VM |
| 2  | Background VMs | **Stop** all hypervisor processes (VirtualBox, QEMU, KVM, VMware) |
| 3  | Streaming/Capture (OBS) | **Close** OBS Studio |
| 4  | Virtual Webcam Drivers | **Unload** v4l2loopback: `sudo rmmod v4l2loopback` |
| 5  | Communication Apps | **Close** Discord, Slack, Telegram, Stoat, MS Teams |
| 6  | Display Environment | Informational only — no action needed |
| 7  | Connected Monitors | **Disconnect** all but one monitor |
| 8  | Remote Access Tools | **Close** VNC, TeamViewer, AnyDesk, RustDesk, Remmina, xrdp |
| 9  | Screen Recorders | **Close** Kazam, Vokoscreen, Peek, wf-recorder, Spectacle, etc. |
| 10 | Container Runtimes | **Stop** containers: `docker stop $(docker ps -q)`, `podman stop -a`; **stop** daemons: `sudo systemctl stop docker podman containerd` |
| 11 | Input Automation | **Close** xdotool, ydotool, AutoKey, PyAutoGUI scripts |
| 12 | VPN / Tunnels | **Disconnect** VPNs: `sudo systemctl stop openvpn-client`, `sudo wg-quick down wg0`; **close** SSH tunnels (`Ctrl+C` on the ssh -L/-D/-R session) |
| 13 | Clipboard Managers | **Close** ClipIt, CopyQ, clipman, etc. |
| 14 | Local AI / LLM Tools | **Stop** Ollama, llama.cpp, LM Studio, Jan.ai, text-generation-webui |
| 15 | Browser Automation | **Close** Selenium, chromedriver, geckodriver, Playwright |
| 16 | Cloud Sync Services | **Close** Dropbox, rclone, OneDrive, Nextcloud, Syncthing |
| 17 | Process Hiding (ptrace) | Set restricted scope: `echo 1 | sudo tee /proc/sys/kernel/yama/ptrace_scope` |
| 18 | Network Listeners | **Stop** unexpected services listening on external interfaces |
| 19 | Active TTY Sessions | **Log out** of extra terminal sessions; only one session should be active |
| 20 | Script Integrity (SHA256) | **Do not modify** the script; verify hash matches the published value |
| 21 | Browser Windows | **Close** all browser windows except the exam; ensure no automation flags |

---

## Check Reference

### [CHECK 1] Guest Virtualization Status

**What it does:** Detects whether the Linux OS is running inside a virtual machine using `systemd-detect-virt` (with `hostnamectl` as a fallback).

**Why it matters:** A VM makes it trivial to snapshot/rollback the system, run hidden tools in separate partitions, or share the screen of a host machine while keeping the VM clean. A result of `none` means physical hardware; anything else indicates a VM.

**How to pass:** Run the exam on physical hardware. If a VM is detected, the proctor may require the exam to be restarted on bare metal.

---

### [CHECK 2] Background Virtual Machines

**What it does:** Scans running processes for hypervisor software (VirtualBox, QEMU, KVM, VMware).

**Why it matters:** Even on physical hardware, the test taker could run a VM in the background to host AI tools, reference materials, or communication apps — then relay answers back to the exam window.

**How to pass:**
```bash
# Stop VirtualBox VMs
VBoxManage controlvm <name> poweroff
# Stop QEMU/KVM
virsh shutdown <domain>
virsh destroy <domain>
# Stop VMware
vmrun stop <vm-path>
```

---

### [CHECK 3] Streaming / Capture Software (OBS)

**What it does:** Checks for OBS Studio processes via `pgrep`.

**Why it matters:** OBS can capture the exam screen for later review, or stream the exam content to another person who could provide answers. OBS is also commonly used with virtual scenes that could overlay hidden notes on-screen.

**How to pass:** Close OBS Studio completely (also check system tray for a minimized icon).

---

### [CHECK 4] Virtual Webcam Drivers

**What it does:** Checks if the `v4l2loopback` kernel module is loaded.

**Why it matters:** This driver allows feeding pre-recorded video into applications like Zoom. A test taker could play a pre-recorded video of themselves sitting at the desk while the real person is elsewhere or referencing materials off-camera.

**How to pass:**
```bash
sudo rmmod v4l2loopback
# To prevent it from loading on boot:
sudo rmmod v4l2loopback && echo "blacklist v4l2loopback" | sudo tee /etc/modprobe.d/blacklist-v4l2.conf
```

---

### [CHECK 5] Communication Apps

**What it does:** Scans for running processes matching Discord, Slack, Telegram, Stoat, and MS Teams.

**Why it matters:** These apps provide direct channels for real-time assistance — the test taker could receive answers from another person, a study group, or an AI service during the exam.

**How to pass:** Close all listed applications completely. Check system tray — many of these apps minimize to tray rather than fully exit.

---

### [CHECK 6] Display Environment

**What it does:** Reports the `$XDG_SESSION_TYPE` (X11 or Wayland).

**Why it matters:** On Wayland, standard screen capture software may fail to record all windows due to stricter security. This is informational — it alerts the proctor that certain monitoring assumptions may not hold.

**How to pass:** No action required — this is informational only. If running Wayland, the proctor should be aware that screen-sharing may not capture all windows.

---

### [CHECK 7] Connected Monitors

**What it does:** Counts active displays via `xrandr` (with sysfs fallback).

**Why it matters:** A second monitor could be used to display reference materials, cheat sheets, or AI tools while only the primary screen is shared on camera. The expected result is `1`.

**How to pass:** Disconnect all secondary monitors before the exam. To disable without unplugging:
```bash
# List monitors
xrandr --query
# Disable a secondary monitor (replace with actual name, e.g. HDMI-1)
xrandr --output HDMI-1 --off
```

---

### [CHECK 8] Remote Access Tools

**What it does:** Checks for VNC, xrdp, Remmina, TeamViewer, AnyDesk, RustDesk, noVNC, TigerVNC, and x11vnc processes.

**Why it matters:** Remote access tools allow someone else to control the machine entirely — effectively letting another person take the exam on the test taker's behalf.

**How to pass:**
```bash
# Close client apps
killall remmina teamviewer anydesk rustdesk x11vnc
# Stop server services
sudo systemctl stop --now vncserver-x11-serviced xrdp tigervncserver
```

---

### [CHECK 9] Screen Recording Tools

**What it does:** Checks for Kazam, SimpleScreenRecorder, Vokoscreen, Peek, wf-recorder, Spectacle, and GNOME Screenshot (in addition to OBS from Check 3).

**Why it matters:** Linux has many built-in and third-party screen recorders beyond OBS. Recording the exam could enable content exfiltration, later review with assistance, or replay of exam questions to an external source.

**How to pass:** Close all screen recording and screenshot tools. Note: `Spectacle` and `GNOME Screenshot` are default on KDE and GNOME — close them if running.

---

### [CHECK 10] Container Runtimes

**What it does:** Checks for Docker, containerd, and Podman daemons, then lists any running containers via `docker ps`.

**Why it matters:** Containers can run entire isolated environments hidden from standard process scans. A container could host AI tools, web servers with reference materials, or communication apps — all invisible to a casual `ps` check.

**How to pass:**
```bash
# Stop all running containers
docker stop $(docker ps -q)
podman stop -a
# Stop container runtimes
sudo systemctl stop --now docker containerd podman
```

---

### [CHECK 11] Input Automation Tools

**What it does:** Checks for xdotool, ydotool, AutoKey, PyAutoGUI, and Pywinauto processes.

**Why it matters:** These tools can programmatically simulate keystrokes and mouse clicks. A script could auto-type answers received from an external source, or an AI tool could inject answers directly into the exam window without human input.

**How to pass:**
```bash
# Close automation tools
killall xdotool ydotool autokey
# Stop any Python scripts using pyautogui/pywinauto
pkill -f pyautogui
pkill -f pywinauto
```

---

### [CHECK 12] VPN / Tunnels

**What it does:** Checks for OpenVPN, WireGuard, and SSH tunnel processes (`-L`, `-D`, `-R` flags), plus WireGuard network interfaces (`wg*`).

**Why it matters:** A VPN masks the test taker's true location and network, potentially bypassing geographic restrictions. SSH tunnels can forward traffic to a remote machine where AI tools or reference materials are accessed, making the traffic appear local.

**How to pass:**
```bash
# Disconnect OpenVPN
sudo systemctl stop --now openvpn-client
# Bring down WireGuard
sudo wg-quick down wg0
# Close SSH tunnels — find and terminate
ps aux | grep 'ssh.*-\(L\|D\|R\)'
# Then kill the tunnel process
```

---

### [CHECK 13] Clipboard Managers

**What it does:** Checks for ClipIt, Parcellite, CopyQ, xclip, wl-clip, clipman, and grim processes.

**Why it matters:** Clipboard managers persist and monitor clipboard content across applications. They could facilitate rapid copy-paste of answers from a hidden source into the exam window, or log all copied exam questions for external processing.

**How to pass:** Close clipboard managers. Many run in the system tray — right-click and quit, or:
```bash
killall clipit copyq clipman
```

---

### [CHECK 14] Local AI / LLM Tools

**What it does:** Checks for Ollama, llama.cpp, text-generation-webui, LangChain, LM Studio, Jan.ai, and Gorilla processes.

**Why it matters:** Locally running AI models can answer exam questions without any internet connection, making them invisible to network-based monitoring. The test taker could query an AI for answers in real-time during the exam.

**How to pass:**
```bash
# Stop Ollama
ollama stop <model>
# Close other AI tools
killall llama-server text-generation-webui lmstudio jan
# Stop any LangChain services
pkill -f langchain
```

---

### [CHECK 15] Browser Automation

**What it does:** Checks for Selenium, chromedriver, geckodriver, Playwright, Puppeteer, and Marionette (Firefox automation).

**Why it matters:** Browser automation tools can programmatically search the web for exam questions and answers, scrape reference materials, or interact with AI APIs — all without visible browser windows or human interaction.

**How to pass:**
```bash
killall chromedriver geckodriver
# Close any Playwright/Puppeteer scripts
pkill -f playwright
pkill -f puppeteer
```

---

### [CHECK 16] Cloud Sync Services

**What it does:** Checks for Dropbox, Insync, rclone, OneDrive, Nextcloud, Syncthing, Seafile, and Cyberduck processes.

**Why it matters:** Active sync services can exfiltrate exam content to the cloud (by syncing screenshots or saved files) or receive answers from an external source (by syncing a file updated by another person).

**How to pass:** Close all cloud sync clients. Many run in the system tray — right-click and quit, or:
```bash
killall dropbox onedrive syncthing rclone seafile
```

---

### [CHECK 17] Process Hiding Potential (ptrace)

**What it does:** Reads `/proc/sys/kernel/yama/ptrace_scope` to check if process tracing is unrestricted (value `0`).

**Why it matters:** A ptrace_scope of `0` allows any process to attach to and manipulate other processes — including hiding them from tools like `ps` and `pgrep`. A value of `1` or higher restricts this capability, making it harder to conceal cheating tools.

**How to pass:**
```bash
# Set restricted scope (requires Yama LSM)
echo 1 | sudo tee /proc/sys/kernel/yama/ptrace_scope
# Make persistent by adding to /etc/sysctl.conf:
# kernel.yama.ptrace_scope=1
```
Note: If Yama LSM is not available, this check reports INFO — no action needed.

---

### [CHECK 18] Suspicious Network Listeners

**What it does:** Uses `ss` (or `netstat`) to find externally listening TCP ports, excluding common expected services (SSH port 22, CUPS port 631, SSH-X11 ports 6010/6011) and localhost-only listeners.

**Why it matters:** Unexpected listening ports could indicate a backdoor, reverse shell, or unlisted remote access tool. Another person could connect to the machine and assist with the exam through these open ports.

**How to pass:**
```bash
# Identify what's listening
ss -tlnp | grep LISTEN
# Stop unexpected services — e.g.
sudo systemctl stop --now <service-name>
# Or kill the process on the port
sudo fuser -k <port>/tcp
```

---

### [CHECK 19] Active TTY Sessions

**What it does:** Counts active terminal sessions via `who`.

**Why it matters:** Multiple active sessions (TTYs) could hide windows with notes, AI tools, or communication apps on a virtual console not visible on the shared screen. The expected result is `1` or fewer.

**How to pass:** Log out of all extra terminal sessions. Check with `who` — each line is a session. Close extra terminals or run `logout` in each.

---

### [CHECK 20] Script Self-Integrity (SHA256)

**What it does:** Computes and displays the SHA256 hash of the running script file using `sha256sum` (with `shasum` as a macOS fallback), along with the script's resolved absolute path.

**Why it matters:** A test taker could modify the script to suppress warnings, remove checks, or always report clean results. By publishing the expected hash before the exam (e.g., in the exam instructions or on a verification page), the proctor can confirm the script has not been tampered with. A mismatch means the script was altered — either by the test taker or by accident.

**How to pass:** Do not modify the script. Download the latest version from the official repository and verify:
```bash
sha256sum audit1.sh
# Compare with the published hash for your exam
```

---

### [CHECK 21] Browser Windows / Tabs

**What it does:** Counts browser windows for Chrome, Chromium, Brave, Edge, and Firefox using `xdotool` (with `wmctrl` and `pgrep` as fallbacks). Also scans for browsers launched with automation/debugging flags (`--remote-debugging`, `--headless`, `--disable-infobars`, `-marionette`).

**Why it matters:** The exam likely runs in one browser tab. Extra windows or tabs could contain AI services (ChatGPT, Claude, Gemini), search engine results, reference materials, or web-based chat. Browsers launched with automation flags suggest headless browsing or programmatic control — useful for scraping answers without a visible window.

**How to pass:** Close all browser windows, then open only the exam. Do not launch browsers with `--remote-debugging`, `--headless`, or automation flags.

---

## Miscellaneous Checks

### PATH Verification

Verifies that common commands (`awk`, `grep`, `ps`, `lsmod`, etc.) are running from standard system paths (`/usr/bin`, `/bin`) rather than local directories (`/home/`, `/local/`). A replaced binary could report falsified results to this script.

**How to pass:** Ensure no custom binaries shadow system commands. If paths show `/home/` or `/local/`, remove or rename the custom binaries and re-run.

---

## For Proctors

- **[PASS]** — No issues detected for this check.
- **[WARNING]** — Potential issue found; investigate further.
- **[INFO]** — Informational; no pass/fail determination.

No single check is definitive proof of cheating. Use the results as a starting point for follow-up questions and observation.

---

## Contributing

Pull requests with additional checks, improved detection patterns, or documentation are welcome. When submitting a new check, include:

1. The cheating mechanism it addresses
2. The tools/processes it scans for
3. Any known false positives and how to handle them

---

## License

See [LICENSE](LICENSE).

---

*Initial framework created with Google Gemini, additional checks, tweaks, and coding by @davebdb.*
