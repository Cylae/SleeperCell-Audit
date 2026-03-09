# nic-ps-audit

**FR :** Diagnostic de précision pour détecter les "serveurs dormants". Identifie si une latence ou un échec de connexion est dû à une gestion d'énergie agressive (802.11 Power Save).
**EN :** Precision diagnostic for "Sleeper Servers". Identifies if connection timeouts are caused by aggressive power management (802.11 Power Save).

---

## Technical Context
Le **First Packet Penalty** survient lorsque l'interface WiFi du serveur entre en état **Doze**. Elle ignore les requêtes **ARP** (Address Resolution Protocol) envoyées par le client tant qu'elle n'est pas réveillée par un événement interne ou un paquet sortant. Ce script automatise le cycle `Flush -> Probe -> Measure` pour isoler ce comportement.



## Features
* **ARP Flush & Probe :** Force une résolution de couche 2 pour tester la réactivité réelle du matériel.
* **Latency Profiling :** Calcule le delta entre le premier paquet (Cold Start) et les suivants (Steady State).
* **NIC Power Audit :** Vérifie si l'hôte Windows autorise l'extinction de sa propre carte, ce qui aggrave les délais de synchronisation.

## Usage
Exécuter dans un terminal PowerShell en tant qu'administrateur :

```powershell
.\nic-ps-audit.ps1 -ServerIP "192.168.x.x" -TargetPort 51821
```
