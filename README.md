# nic-ps-audit

**FR :** Diagnostic de précision pour détecter les "serveurs dormants". Identifie si une latence ou un échec de connexion est dû à une gestion d'énergie agressive (802.11 Power Save). Fournit désormais un playbook d'auto-remédiation et des utilitaires pour Linux & Windows.
**EN :** Precision diagnostic for "Sleeper Servers". Identifies if connection timeouts are caused by aggressive power management (802.11 Power Save). Now provides an auto-remediation playbook and utilities for both Linux & Windows.

---

## Technical Context
Le **First Packet Penalty** survient lorsque l'interface réseau du serveur entre en état **Doze** (Veille). Elle ignore les requêtes **ARP** (Address Resolution Protocol) envoyées par le client tant qu'elle n'est pas réveillée par un événement interne ou un paquet sortant. Ce script automatise le cycle `Flush -> Probe -> Measure` pour isoler ce comportement et propose les commandes exactes pour corriger les anomalies (Auto-Remediation Playbook).

## Features
* **Bilingual UI :** Menus and outputs in both English and French (configurable via `--lang` or the interactive menu).
* **Persistent Config :** Use `--configure` to set and save your target IP, Port, and Ping count so you don't have to type them every time.
* **Auto-Remediation Playbook :** If an anomaly is detected (e.g., Latency Spike, Port Closed, ARP failure, OS Sleep Targets enabled), the scripts will generate a list of copy-pasteable commands to fix the issues permanently.
* **ARP Flush & Probe :** Force une résolution de couche 2 pour tester la réactivité réelle du matériel.
* **Latency Profiling :** Calcule le delta entre le premier paquet (Cold Start) et les suivants (Steady State).
* **NIC Power Audit :** Vérifie si le système d'exploitation autorise l'extinction de sa propre carte (ethtool sur Linux, Get-NetAdapter sur Windows).

## Scripts

### 1. Linux / Debian (`audit_linux.sh`)
Built for Linux servers. Requires `bash` and standard networking utilities (`ip`, `ping`).
* Optional dependencies for full diagnostics: `ethtool`, `curl`.

### 2. Windows (`audit_windows.ps1`)
Built for Windows environments. Cross-platform compatible with both Windows PowerShell 5.1 and PowerShell 7.

---

## Usage
Run the scripts via your terminal of choice. Running as Administrator / root is highly recommended to allow the script to flush the ARP cache and inspect low-level NIC power management settings.

### Basic Run
```bash
# Linux
sudo ./audit_linux.sh

# Windows
.\audit_windows.ps1
```

### Interactive Configuration
Save defaults to a persistent `audit_config.json` file.
```bash
# Linux
./audit_linux.sh --configure

# Windows
.\audit_windows.ps1 -Configure
```

### CLI Overrides
```bash
# Linux
sudo ./audit_linux.sh --server-ip 192.168.1.100 --port 80 --ping-count 10 --lang fr

# Windows
.\audit_windows.ps1 -ServerIP 192.168.1.100 -TargetPort 80 -PingCount 10 -Lang fr
```