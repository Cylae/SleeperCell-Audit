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

These scripts automate a full `Flush -> Probe -> Measure` lifecycle to diagnose exactly where the failure occurs and generate an **Auto-Remediation Playbook** to fix it.

---

## ✨ Features

- 🌐 **Bilingual UI**: Full support for both English and French outputs (`--lang fr`).
- 💾 **Persistent Config**: Save your target IP and ports via an interactive menu (`--configure`) to a local JSON file so you don't have to retype them.
- 🛠️ **Auto-Remediation**: Generates a safe, copy-pasteable playbook of commands specific to your anomalies (e.g., disabling NIC power-save, adding firewall rules, fixing routing).
- 📈 **Visual Profiling**: Beautiful CLI progress bars mapping latency spikes on the very first "cold start" packet.
- 🌍 **Cross-Platform**: Two perfectly synchronized scripts. Native `Bash` for Linux, native `.NET/PowerShell` for Windows.

---

## 🚀 Usage

Execute the scripts via your terminal of choice. Running as **Administrator / root** is highly recommended to allow the script to flush the ARP cache and inspect low-level NIC power management settings.

### 🐧 Linux (`audit_linux.sh`)
```bash
# Basic run (will use defaults or audit_config.json if it exists)
sudo ./audit_linux.sh

# Interactive setup to save configuration
./audit_linux.sh --configure

# CLI overrides for a quick one-off check
sudo ./audit_linux.sh --server-ip 192.168.1.100 --port 51821 --lang fr
```

### 🪟 Windows (`audit_windows.ps1`)
*Supports Windows PowerShell 5.1 & PowerShell Core 7+*
```powershell
# Basic run
.\audit_windows.ps1

# Interactive setup to save configuration
.\audit_windows.ps1 -Configure

# CLI overrides for a quick one-off check
.\audit_windows.ps1 -ServerIP 192.168.1.100 -TargetPort 51821 -Lang fr
```

---

## 📦 Dependencies
**Linux:**
* Built-in: `bash`, `ping`, `ip`, `awk`
* Optional (for deeper diagnostics): `ethtool`, `curl`

**Windows:**
* Built-in: `PowerShell`

---
<p align="center"><i>Diagnose smarter, stay connected longer. ⚡</i></p>