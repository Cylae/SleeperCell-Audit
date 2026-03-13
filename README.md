<h1 align="center">🕵️‍♂️ Sleeper Server Audit</h1>

<p align="center">
  <b>Precision diagnostics & auto-remediation for aggressive power management</b><br>
  <i>Diagnostic de précision & auto-remédiation pour gestion d'énergie agressive</i>
</p>

<p align="center">
  <img alt="OS Support: Linux" src="https://img.shields.io/badge/Linux-Bash-FCC624?style=flat-square&logo=linux&logoColor=black" />
  <img alt="OS Support: Windows" src="https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square&logo=windows&logoColor=white" />
  <img alt="Languages: EN / FR" src="https://img.shields.io/badge/i18n-EN%20%7C%20FR-4CAF50?style=flat-square&logo=translate" />
</p>

---

## 📖 The Problem: First Packet Penalty
Is your server experiencing intermittent timeouts, randomly closing ports, or dropping the very first ping request?

This is often caused by the **First Packet Penalty**. When a server's network interface card (NIC) enters a deep sleep or power-saving state (like 802.11 Power Save or D3/Modern Standby), it drops incoming **ARP** requests until awoken by internal events or outbound traffic.

These scripts automate a full `Flush -> Probe -> Measure` lifecycle to diagnose exactly where the failure occurs and generate an **Auto-Remediation Playbook** to fix it. We have subjected these scripts to a gigantic battery of extreme tests ensuring their reliability in real world scenarios.

---

## ✨ Features

- 🌐 **Bilingual UI**: Full support for both English and French outputs (`--lang fr`).
- 💾 **Persistent Config**: Save your target IP and ports via an interactive menu (`--configure`) to a local JSON file so you don't have to retype them.
- 🛠️ **Interactive Auto-Remediation**: Generates a safe playbook of commands specific to your anomalies. If run as Administrator/root, the scripts will prompt you `[y/N]` to safely apply the fixes automatically (safely bypassed in non-interactive/cron environments).
- 📈 **Deep Network Profiling**: Beautiful CLI progress bars mapping latency spikes, **Packet Loss %**, and **Jitter** on the very first "cold start" packet. Also conducts Layer 3 **DNS Resolution** checks and **Traceroutes**.
- ⚡ **OS Power Telemetry**: Inspects the deepest layers of your OS power management, reading `cpufreq` governors, systemd sleep targets, and `powercfg` active schemes.
- 📤 **Machine-Readable Exports**: Use the `--export-json` / `-ExportJson` flag to dump the final audit summary to a JSON file for monitoring integrations. Log and JSON exports are automatically tagged with the target IP (e.g. `audit_192.168.1.254_20260309.log`).
- 🌍 **Cross-Platform**: Two perfectly synchronized scripts. Native `Bash` for Linux, native `.NET/PowerShell` for Windows. Both follow a strict 8-step execution parity including live Dependency Checks.

---

## 🚀 Usage

Execute the scripts via your terminal of choice. Running as **Administrator / root** is highly recommended to allow the script to flush the ARP cache, inspect low-level NIC power management settings, and execute the interactive Auto-Remediation playbook.

### 🐧 Linux (`audit_linux.sh`)
```bash
# Basic run (will use defaults or audit_config.json if it exists)
sudo ./audit_linux.sh

# Interactive setup to save configuration
./audit_linux.sh --configure

# CLI overrides for a quick one-off check with JSON export
sudo ./audit_linux.sh --server-ip 192.168.1.100 --port 51821 --lang fr --export-json
```

### 🪟 Windows (`audit_windows.ps1`)
*Supports Windows PowerShell 5.1 & PowerShell Core 7+*
```powershell
# Basic run
.\audit_windows.ps1

# Interactive setup to save configuration
.\audit_windows.ps1 -Configure

# CLI overrides for a quick one-off check with JSON export
.\audit_windows.ps1 -ServerIP 192.168.1.100 -TargetPort 51821 -Lang fr -ExportJson
```

### 🤖 Hand-Free / Automation (Cron & Task Scheduler)
If the scripts detect that they are running without an active terminal (e.g., via a CRON job or Windows Task Scheduler), they will automatically skip the `[y/N]` interactive remediation prompt to ensure the job completes gracefully. Use the JSON export flags to funnel the results into your monitoring systems.

---

## 📦 Dependencies
Upon execution, both scripts will perform a live **Dependency Check** to let you know what features are available.

**Linux (`audit_linux.sh`)**
* **Core**: `bash`, `ping`, `ip`, `awk`
* **Optional**:
  * `ethtool` (Required to detect NIC Wake-on-LAN and Power Save states)
  * `curl` (Required for HTTP reachability tests)
  * `traceroute` (Required for Layer 3 route pathing)

**Windows (`audit_windows.ps1`)**
* **Core**: Windows PowerShell 5.1+ or PowerShell Core 7+
* **Optional**: `tracert`, `powercfg`

---
<p align="center"><i>Diagnose smarter, stay connected longer. ⚡</i></p>