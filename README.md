# 🕵️‍♂️ Sleeper Server Audit

<p align="center">
  <img alt="OS Support: Linux" src="https://img.shields.io/badge/Linux-Bash-FCC624?style=flat-square&logo=linux&logoColor=black" />
  <img alt="OS Support: Windows" src="https://img.shields.io/badge/Windows-PowerShell-0078D4?style=flat-square&logo=windows&logoColor=white" />
</p>

[English Version](#english-version) | [Version Française](#version-française)

---

<a id="english-version"></a>
# English Version

**Precision diagnostics & auto-remediation for aggressive power management.**

## 📖 The Problem: First Packet Penalty
Is your server experiencing intermittent timeouts, randomly closing ports, or dropping the very first ping request?

This is often caused by the **First Packet Penalty**. When a server's network interface card (NIC) enters a deep sleep or power-saving state (like 802.11 Power Save or D3/Modern Standby), it ignores incoming **ARP** (Address Resolution Protocol) requests until it is awoken by internal system events or outbound traffic.

When you try to connect to a sleeping server, your router asks "Who has this IP?" via an ARP broadcast. Because the server's NIC is asleep, it doesn't answer. The router drops your packet. Only after the server wakes up does the connection succeed.

These scripts automate a full `Flush -> Probe -> Measure` lifecycle to diagnose exactly where the failure occurs. They test the entire OSI stack (from Layer 2 ARP to Layer 7 HTTP) and generate an **Auto-Remediation Playbook** to fix aggressive power management.

## ✨ Features

- 🌐 **Bilingual UI**: Full support for both English and French outputs (`--lang fr` / `-Lang fr`).
- 💾 **Persistent Config**: Save your target IP and ports via an interactive menu (`--configure`) to a local JSON file.
- 🛠️ **Interactive Auto-Remediation**: Generates a safe playbook of commands specific to your anomalies. If run as Administrator/root, the scripts will prompt you `[y/N]` to safely apply the fixes automatically.
- 📈 **Deep Network Profiling**: CLI progress bars map latency spikes, **Packet Loss %**, and **Jitter** on the very first "cold start" packet. Also conducts Layer 3 **DNS Resolution** checks and **Traceroutes**.
- ⚡ **OS Power Telemetry**: Inspects the deepest layers of your OS power management, reading `cpufreq` governors, systemd sleep targets, and `powercfg` active schemes.
- 📤 **Machine-Readable Exports**: Use the `--export-json` / `-ExportJson` flag to dump the final audit summary to a JSON file.
- 🌍 **Cross-Platform**: Two perfectly synchronized scripts. Native `Bash` for Linux, native `.NET/PowerShell` for Windows. Both follow a strict 8-step execution parity including live Dependency Checks.

## 🚀 Usage

Execute the scripts via your terminal of choice. Running as **Administrator / root** is highly recommended.

### 🐧 Linux (`audit_linux.sh`)
```bash
# Basic run (will use defaults or audit_config.json)
sudo ./audit_linux.sh

# Interactive setup to save configuration
./audit_linux.sh --configure

# CLI overrides for a quick one-off check with JSON export
sudo ./audit_linux.sh --server-ip 192.168.1.100 --port 51821 --lang en --export-json
```

### 🪟 Windows (`audit_windows.ps1`)
*Supports Windows PowerShell 5.1 & PowerShell Core 7+*
```powershell
# Basic run
.\audit_windows.ps1

# Interactive setup to save configuration
.\audit_windows.ps1 -Configure

# CLI overrides for a quick one-off check with JSON export
.\audit_windows.ps1 -ServerIP 192.168.1.100 -TargetPort 51821 -Lang en -ExportJson
```

## 📦 Dependencies
Upon execution, both scripts will perform a live **Dependency Check**.
* **Linux**: `bash`, `ping`, `ip`, `awk` (Core). Optional: `ethtool`, `curl`, `traceroute`, `host`, `systemctl`.
* **Windows**: PowerShell 5.1+. Optional: `tracert`, `powercfg`.

---

<a id="version-française"></a>
# Version Française

**Diagnostic de précision & auto-remédiation pour gestion d'énergie agressive.**

## 📖 Le Problème : La Pénalité du Premier Paquet
Votre serveur subit-il des expirations de délai intermittentes, ferme-t-il des ports de façon aléatoire, ou perd-il la toute première requête ping ?

Ceci est souvent causé par la **Pénalité du Premier Paquet**. Lorsque la carte réseau (NIC) d'un serveur entre dans un état de veille profonde ou d'économie d'énergie (comme 802.11 Power Save ou D3/Modern Standby), elle ignore les requêtes **ARP** (Address Resolution Protocol) entrantes jusqu'à ce qu'elle soit réveillée par des événements système internes ou du trafic sortant.

Lorsque vous essayez de vous connecter à un serveur en veille, votre routeur demande "Qui a cette adresse IP ?" via une diffusion ARP. Comme la carte réseau du serveur est endormie, elle ne répond pas. Le routeur rejette alors votre paquet. Ce n'est qu'après le réveil du serveur que la connexion réussit.

Ces scripts automatisent un cycle complet `Vider -> Sonder -> Mesurer` pour diagnostiquer exactement où la défaillance se produit. Ils testent l'ensemble de la pile OSI (de la couche 2 ARP à la couche 7 HTTP) et génèrent un **Playbook d'Auto-Remédiation** pour corriger la gestion d'énergie agressive.

## ✨ Fonctionnalités

- 🌐 **Interface Bilingue** : Support complet des sorties en anglais et en français (`--lang fr` / `-Lang fr`).
- 💾 **Configuration Persistante** : Enregistrez votre IP cible et vos ports via un menu interactif (`--configure`) dans un fichier JSON local.
- 🛠️ **Auto-Remédiation Interactive** : Génère un playbook sûr de commandes spécifiques à vos anomalies. Si exécuté en tant qu'Administrateur/root, les scripts vous demanderont `[y/N]` pour appliquer automatiquement les correctifs.
- 📈 **Profilage Réseau Profond** : Des barres de progression en ligne de commande cartographient les pics de latence, le **% de Perte de Paquets**, et la **Gigue (Jitter)** sur le tout premier paquet "à froid". Effectue également des vérifications de **Résolution DNS** de couche 3 et des **Traceroutes**.
- ⚡ **Télémétrie d'Énergie de l'OS** : Inspecte les couches les plus profondes de la gestion de l'énergie de votre système d'exploitation, en lisant les gouverneurs `cpufreq`, les cibles de veille systemd et les schémas actifs `powercfg`.
- 📤 **Exports Lisibles par Machine** : Utilisez l'indicateur `--export-json` / `-ExportJson` pour exporter le résumé final de l'audit dans un fichier JSON.
- 🌍 **Multiplateforme** : Deux scripts parfaitement synchronisés. `Bash` natif pour Linux, `.NET/PowerShell` natif pour Windows. Les deux suivent une parité d'exécution stricte en 8 étapes, incluant des vérifications de dépendances en direct.

## 🚀 Utilisation

Exécutez les scripts via votre terminal préféré. Une exécution en tant qu'**Administrateur / root** est fortement recommandée.

### 🐧 Linux (`audit_linux.sh`)
```bash
# Exécution de base (utilisera les paramètres par défaut ou audit_config.json)
sudo ./audit_linux.sh

# Configuration interactive pour sauvegarder les paramètres
./audit_linux.sh --configure

# Remplacements en ligne de commande pour une vérification rapide avec export JSON
sudo ./audit_linux.sh --server-ip 192.168.1.100 --port 51821 --lang fr --export-json
```

### 🪟 Windows (`audit_windows.ps1`)
*Supporte Windows PowerShell 5.1 & PowerShell Core 7+*
```powershell
# Exécution de base
.\audit_windows.ps1

# Configuration interactive pour sauvegarder les paramètres
.\audit_windows.ps1 -Configure

# Remplacements en ligne de commande pour une vérification rapide avec export JSON
.\audit_windows.ps1 -ServerIP 192.168.1.100 -TargetPort 51821 -Lang fr -ExportJson
```

## 📦 Dépendances
Lors de l'exécution, les deux scripts effectueront une **Vérification des Dépendances** en direct.
* **Linux** : `bash`, `ping`, `ip`, `awk` (Core). Optionnel : `ethtool`, `curl`, `traceroute`, `host`, `systemctl`.
* **Windows** : PowerShell 5.1+. Optionnel : `tracert`, `powercfg`.
