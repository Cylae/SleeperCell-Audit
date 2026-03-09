# ==============================================================================
#  Connectivity & Power Management Audit  -  Windows (PowerShell)
#  Target : Debian Server (WireGuard Web UI)
#  Features : Bilingual UI, Persistent Config, Auto-Remediation Playbook
# ==============================================================================
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] [string]$ServerIP,
    [Parameter(Mandatory=$false)] [int]$TargetPort,
    [Parameter(Mandatory=$false)] [int]$PingCount,
    [Parameter(Mandatory=$false)] [switch]$Configure,
    [Parameter(Mandatory=$false)] [switch]$ResetConfig,
    [Parameter(Mandatory=$false)] [switch]$Help,
    [Parameter(Mandatory=$false)] [switch]$NoLog,
    [Parameter(Mandatory=$false)] [switch]$ExportJson,
    [Parameter(Mandatory=$false)] [ValidateSet("fr","en")] [string]$Lang
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) { try { $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction Stop } catch { $ScriptRoot = $PWD.Path } }
$ConfigPath = Join-Path $ScriptRoot "audit_config.json"
$LogDir     = Join-Path $ScriptRoot "logs"

$Defaults = [ordered]@{ Language="en"; ServerIP="192.168.1.254"; TargetPort=51821; PingCount=5 }

function Copy-Defaults { return [ordered]@{ Language=$Defaults.Language; ServerIP=$Defaults.ServerIP; TargetPort=$Defaults.TargetPort; PingCount=$Defaults.PingCount } }

function Load-Config {
    if (Test-Path $ConfigPath) {
        try {
            $raw = Get-Content $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $lang = if ($raw.PSObject.Properties["Language"]   -and $raw.Language)   { $raw.Language }   else { $Defaults.Language }
            $ip   = if ($raw.PSObject.Properties["ServerIP"]   -and $raw.ServerIP)   { $raw.ServerIP }   else { $Defaults.ServerIP }
            $port = if ($raw.PSObject.Properties["TargetPort"] -and $raw.TargetPort) { [int]$raw.TargetPort } else { $Defaults.TargetPort }
            $ping = if ($raw.PSObject.Properties["PingCount"]  -and $raw.PingCount)  { [int]$raw.PingCount  } else { $Defaults.PingCount }
            if ($lang -notin @("en","fr"))                    { $lang = $Defaults.Language }
            if ($ip   -notmatch '^\d{1,3}(\.\d{1,3}){3}$')  { $ip   = $Defaults.ServerIP }
            if ($port -lt 1 -or $port -gt 65535)             { $port = $Defaults.TargetPort }
            if ($ping -lt 1 -or $ping -gt 20)                { $ping = $Defaults.PingCount }
            return [ordered]@{ Language=$lang; ServerIP=$ip; TargetPort=$port; PingCount=$ping }
        } catch { return Copy-Defaults }
    }
    return Copy-Defaults
}
function Save-Config ($cfg) { try { $cfg | ConvertTo-Json | Set-Content $ConfigPath -Encoding UTF8 } catch {} }

$S = @{
    en = @{
        title="CONNECTIVITY & POWER MANAGEMENT AUDIT"; target="Target"; port="Port"; step="STEP"; adminOk="Running as Administrator"; adminWarn="Not Administrator - Mitigation restricted"; arpSection="ARP Resolution"; arpFlushed="Cache flushed for"; arpSkip="Skipping cache flush - requires elevation"; arpOk="ARP Resolved"; arpFail="ARP Failed"; routeSection="Routing Topology"; latSection="Latency Profile"; pings="pings"; firstPkt="First packet"; timeout="Timeout"; avgRest="Avg (rest)"; minMax="Min / Max"; spikeDelta="Spike delta"; spikeWarn="NIC likely power-saving"; latStable="Latency stable"; latFail="Insufficient replies"; tcpSection="TCP Port Probe"; portOpen="OPEN"; portClosed="CLOSED or Filtered"; httpSection="HTTP Reachability"; httpOk="HTTP responded"; httpFail="HTTP unreachable"; traceSection="Traceroute (first 5 hops)"; traceNoCmd="tracert not available"; dnsSection="DNS Resolution Check"; dnsOk="DNS resolved"; dnsFail="DNS resolution failed"; nicSection="Local NIC Power Management"; allowOff="Allow PC to turn off"; wakeMagic="Wake on Magic Packet"; wakePattern="Wake on Pattern Match"; summaryTitle="AUDIT SUMMARY"; allOk="All checks passed."; someWarn="check(s) require attention."; remTitle="REMEDIATION PLAYBOOK (RUN AS ADMIN)"; remNone="SYSTEM FULLY OPTIMIZED - ZERO ANOMALIES DETECTED"; runRemediation="Would you like to automatically apply these fixes now? [y/N]"; remApplied="Fixes applied successfully."; jsonExported="JSON Export saved to"; lossAndJitter="Loss / Jitter"
    }
    fr = @{
        title="AUDIT CONNECTIVITE & GESTION ENERGIE"; target="Cible"; port="Port"; step="ETAPE"; adminOk="Execution Administrateur"; adminWarn="Pas Administrateur - Mitigation restreinte"; arpSection="Resolution ARP"; arpFlushed="Cache vide pour"; arpSkip="Flush ignore - elevation requise"; arpOk="ARP Resolu"; arpFail="ARP Echoue"; routeSection="Topologie de Routage"; latSection="Profil de Latence"; pings="pings"; firstPkt="Premier paquet"; timeout="Expiration"; avgRest="Moy (reste)"; minMax="Min / Max"; spikeDelta="Delta pic"; spikeWarn="NIC en economie d'energie"; latStable="Latence stable"; latFail="Reponses insuffisantes"; tcpSection="Sonde Port TCP"; portOpen="OUVERT"; portClosed="FERME ou Filtre"; httpSection="Accessibilite HTTP"; httpOk="HTTP a repondu"; httpFail="HTTP inaccessible"; traceSection="Traceroute (5 premiers sauts)"; traceNoCmd="tracert non disponible"; dnsSection="Verification Resolution DNS"; dnsOk="DNS resolu"; dnsFail="Resolution DNS echouee"; nicSection="Gestion Energie NIC Local"; allowOff="Autoriser extinction PC"; wakeMagic="Reveil Magic Packet"; wakePattern="Reveil sur Motif"; summaryTitle="RESUME DE L'AUDIT"; allOk="Tous les tests passes."; someWarn="test(s) necessitent attention."; remTitle="PLAYBOOK DE REMEDIATION (ADMIN REQUIS)"; remNone="SYSTEME OPTIMISE - ZERO ANOMALIE"; runRemediation="Voulez-vous appliquer ces correctifs automatiquement maintenant ? [y/N]"; remApplied="Correctifs appliques avec succes."; jsonExported="Export JSON enregistre sous"; lossAndJitter="Perte / Jitter"
    }
}
$C = @{ Title="White"; Head="Cyan"; OK="Green"; Warn="Yellow"; Err="Red"; Dim="DarkGray"; Accent="DarkCyan"; Reset="Gray" }

$cfg = Load-Config
if ($PSBoundParameters.ContainsKey("Lang"))       { $cfg.Language   = $Lang }
if ($PSBoundParameters.ContainsKey("ServerIP"))   { $cfg.ServerIP   = $ServerIP }
if ($PSBoundParameters.ContainsKey("TargetPort")) { $cfg.TargetPort = $TargetPort }
if ($PSBoundParameters.ContainsKey("PingCount"))  { $cfg.PingCount  = $PingCount }
$L = $S[$cfg.Language]; $ServerIP = $cfg.ServerIP; $TargetPort = $cfg.TargetPort; $PingCount = $cfg.PingCount

$LogFile = $null; $LogBuffer = [System.Text.StringBuilder]::new()
function wh { param([string]$msg, [string]$fg="Gray", [switch]$nonl) if ($nonl) { Write-Host $msg -NoNewline -ForegroundColor $fg } else { Write-Host $msg -ForegroundColor $fg }; if ($LogFile) { $null = $LogBuffer.AppendLine($msg) } }
function Write-Banner { $w=62; $line='='*$w; wh ""; wh "  +$line+" $C.Accent; wh "  |$(' '*$w)|" $C.Accent; wh "  |$("  $($L.title)".PadRight($w))|" $C.Title; wh "  |$("  $($L.target): $ServerIP   $($L.port): $TargetPort".PadRight($w))|" $C.Head; wh "  |$(' '*$w)|" $C.Accent; wh "  +$line+" $C.Accent; wh "" }
function Write-Section { param([string]$Title, [int]$Step) wh "`n  +--[ $($L.step) $Step ]------------------------------" $C.Accent; wh "  |  >> $Title" $C.Title; wh "  +--------------------------------------------------" $C.Accent }
function Write-StatusLine { param([string]$L, [string]$V, [string]$S) $ic=switch($S){"ok"{"[OK]"} "warn"{"[!!]"} "err"{"[XX]"} default{"[..]"}}; $cl=switch($S){"ok"{$C.OK} "warn"{$C.Warn} "err"{$C.Err} default{$C.Reset}}; wh "     $ic " $cl -nonl; wh $L $C.Reset -nonl; if($V){wh " -> " $C.Dim -nonl; wh $V $cl} else{wh ""} }

if ($Help) {
    $helpText = @"
USAGE:  .\audit_windows.ps1 [options]
OPTIONS:
  -ServerIP   <ip>      Override target IP for this run
  -TargetPort <port>    Override target port for this run
  -PingCount  <n>       Override ping count for this run
  -Lang       <en|fr>   Override language for this run
  -Configure            Launch interactive configuration UI
  -ResetConfig          Reset config file to defaults
  -NoLog                Disable log file generation
  -ExportJson           Export audit results as JSON
  -Help                 Show this help
"@
    wh $helpText $C.Reset
    exit 0
}

if ($ResetConfig) {
    Save-Config $Defaults
    wh "  [OK] Configuration reset to defaults." $C.OK
    exit 0
}

if ($Configure) {
    wh "`n  +$('=' * 58)+" $C.Accent
    wh "  |$("  CONFIGURATION".PadRight(58))|" $C.Title
    wh "  +$('=' * 58)+`n" $C.Accent

    wh "  Current settings:" $C.Head
    wh "    Language   : $($cfg.Language)" $C.Reset
    wh "    IP         : $($cfg.ServerIP)" $C.Reset
    wh "    Port       : $($cfg.TargetPort)" $C.Reset
    wh "    Ping count : $($cfg.PingCount)`n" $C.Reset

    do {
        wh "  >> Choose language [en/fr] [$($cfg.Language)] : " $C.Head -nonl
        $input = Read-Host
        if ([string]::IsNullOrWhiteSpace($input)) { $input = $cfg.Language }
        $input = $input.ToLower().Trim()
    } while ($input -notin @("en","fr"))
    $cfg.Language = $input

    do {
        wh "  >> Enter server IP address [$($cfg.ServerIP)] : " $C.Head -nonl
        $input = Read-Host
        if ([string]::IsNullOrWhiteSpace($input)) { $input = $cfg.ServerIP }
        $input = $input.Trim()
    } while ($input -notmatch '^\d{1,3}(\.\d{1,3}){3}$')
    $cfg.ServerIP = $input

    do {
        wh "  >> Enter target TCP port [$($cfg.TargetPort)] : " $C.Head -nonl
        $input = Read-Host
        if ([string]::IsNullOrWhiteSpace($input)) { $portVal = $cfg.TargetPort; break }
        $portVal = 0
        if ([int]::TryParse($input, [ref]$portVal) -and $portVal -ge 1 -and $portVal -le 65535) { break }
        $portVal = 0
    } while ($portVal -eq 0)
    $cfg.TargetPort = $portVal

    do {
        wh "  >> Enter number of ping probes [$($cfg.PingCount)] : " $C.Head -nonl
        $input = Read-Host
        if ([string]::IsNullOrWhiteSpace($input)) { $pingVal = $cfg.PingCount; break }
        $pingVal = 0
        if ([int]::TryParse($input, [ref]$pingVal) -and $pingVal -ge 1 -and $pingVal -le 20) { break }
        $pingVal = 0
    } while ($pingVal -eq 0)
    $cfg.PingCount = $pingVal

    Save-Config $cfg
    wh "`n  [OK] Configuration saved.`n" $C.OK
    exit 0
}

if (-not $NoLog) { if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }; $LogFile = Join-Path $LogDir ("audit_{0}_{1}.log" -f $ServerIP, (Get-Date -Format "yyyyMMdd_HHmmss")) }

$report = [ordered]@{}; $remediation = @()
Write-Banner

$isWinEnv = ($null -eq $IsWindows -and $PSVersionTable.PSVersion.Major -lt 6) -or ($IsWindows -eq $true)
if ($isWinEnv) {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    try { $isAdmin = ((& id -u) -eq "0") } catch { $isAdmin = $false }
}

if ($isAdmin) { wh "  [OK] $($L.adminOk)" $C.OK } else { wh "  [!!] $($L.adminWarn)" $C.Warn }

# [1] ARP & ROUTING
Write-Section $L.arpSection 1

try {
    $route = Get-NetRoute -DestinationPrefix "$ServerIP/32" -ErrorAction SilentlyContinue
    if (-not $route) { $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1 }
    $iface = Get-NetAdapter -InterfaceIndex $route.InterfaceIndex -ErrorAction SilentlyContinue
    Write-StatusLine "Interface" "$($iface.Name) (Metric: $($route.RouteMetric))" "ok"
    $report["Routing"] = "IF: $($iface.Name)"
} catch { Write-StatusLine "Route" "Not Found" "err"; $report["Routing"] = "FAILED" }

if ($isAdmin) { try { arp -d $ServerIP 2>$null } catch {}; wh "       $($L.arpFlushed) $ServerIP" $C.Dim } else { wh "       $($L.arpSkip)" $C.Dim }
$null = Test-Connection -ComputerName $ServerIP -Count 1 -Quiet -ErrorAction SilentlyContinue
try { $arpEntry = arp -a | Select-String "\b$([regex]::Escape($ServerIP))\b" } catch { $arpEntry = $null }
if ($arpEntry) { Write-StatusLine $L.arpOk $arpEntry.ToString().Trim() "ok"; $report["ARP"] = "Resolved" }
else { Write-StatusLine $L.arpFail "" "err"; $report["ARP"] = "FAILED"; $remediation += "Clear-NetNeighbor -IPAddress $ServerIP -ErrorAction SilentlyContinue" }

# [2] LATENCY
Write-Section "$($L.latSection) ($PingCount $($L.pings))" 2

function Get-PingLatency {
    param($R)
    if ($null -eq $R) { return $null }
    if ($R.PSObject.Properties["ResponseTime"]) { return [int]$R.ResponseTime }
    if ($R.PSObject.Properties["Latency"]) {
        if ($R.Latency -is [TimeSpan]) { return [int]$R.Latency.TotalMilliseconds }
        else { return [int]$R.Latency }
    }
    return $null
}

function Write-LatencyBar {
    param([int]$ms, [int]$Max = 300, [int]$W = 28)
    $fill  = [math]::Min([math]::Round(($ms / $Max) * $W), $W)
    $empty = $W - $fill
    $color = if ($ms -lt 20) { $C.OK } elseif ($ms -lt 80) { $C.Warn } else { $C.Err }
    wh "          [" $C.Dim -nonl
    wh ("#" * $fill) $color -nonl
    wh ("." * $empty) $C.Dim -nonl
    wh ("] {0,4}ms" -f $ms) $color
}

$lats = @(); $timeouts = 0
for ($i=1; $i -le $PingCount; $i++) {
    $p = Test-Connection -ComputerName $ServerIP -Count 1 -ErrorAction SilentlyContinue
    $latency = Get-PingLatency $p
    if ($null -ne $latency) {
        $tag = if ($i -eq 1) { "  <- $($L.firstPkt)" } else { "" }
        wh ("     Ping [{0}/{1}]{2}" -f $i, $PingCount, $tag) $C.Dim
        Write-LatencyBar -ms $latency
        $lats += $latency
    } else {
        $timeouts++
        wh ("     Ping [{0}/{1}] " -f $i, $PingCount) $C.Dim -nonl
        wh $L.timeout $C.Err
    }
}

if ($lats.Count -ge 1) {
    $firstPacket = $lats[0]
    $minLat = ($lats | Measure-Object -Minimum).Minimum
    $maxLat = ($lats | Measure-Object -Maximum).Maximum

    $jitter = 0
    if ($lats.Count -gt 1) {
        $restAvg = [math]::Round(($lats[1..($lats.Count-1)] | Measure-Object -Average).Average, 1)
        $spike   = $firstPacket - $restAvg
        if ($lats.Count -gt 2) {
            $jitterSum = 0
            for ($j=2; $j -lt $lats.Count; $j++) {
                $jitterSum += [math]::Abs($lats[$j] - $lats[$j-1])
            }
            $jitter = [math]::Round($jitterSum / ($lats.Count - 2))
        }
    } else {
        $restAvg = $firstPacket
        $spike   = 0
    }

    $lossPct = [math]::Round(($timeouts / $PingCount) * 100)

    wh "     +------------------------------------+" $C.Accent
    wh ("     |  $($L.firstPkt.PadRight(16)): {0,6}ms           |" -f $firstPacket) $C.Reset
    wh ("     |  $($L.avgRest.PadRight(16)): {0,6}ms           |" -f $restAvg) $C.Reset
    wh ("     |  $($L.minMax.PadRight(16)): {0,4}ms / {1,4}ms    |" -f $minLat, $maxLat) $C.Reset

    $spikeColor = if ($spike -gt 50) { $C.Warn } else { $C.OK }
    wh ("     |  $($L.spikeDelta.PadRight(16)): {0,6}ms           |" -f $spike) $spikeColor
    wh ("     |  $($L.lossAndJitter.PadRight(16)): {0,5}% / {1,4}ms    |" -f $lossPct, $jitter) $C.Reset
    wh "     +------------------------------------+" $C.Accent

    if ($spike -gt 50) { Write-StatusLine "Spike" "+${spike}ms" "warn"; $report["Latency"] = "Spike: ${spike}ms"; $remediation += "Disable-NetAdapterPowerManagement -Name '*' -ErrorAction SilentlyContinue" }
    else { Write-StatusLine $L.latStable "" "ok"; $report["Latency"] = "Stable" }

    if ($lossPct -gt 0) { $report["Packet Loss"] = "${lossPct}%" }
} else { Write-StatusLine $L.latFail "" "err"; $report["Latency"] = "FAILED"; $remediation += "Test-NetConnection -ComputerName $ServerIP -DiagnoseRouting" }

# [3] TCP & HTTP
Write-Section $L.tcpSection 3
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $connectTask = $tcpClient.ConnectAsync($ServerIP, $TargetPort)
    $success = $connectTask.Wait(2000)
    if ($success -and $tcpClient.Connected) { Write-StatusLine "$($L.port) $TargetPort" $L.portOpen "ok"; $report["TCP"] = "Open"; $tcpClient.Close() }
    else { Write-StatusLine "$($L.port) $TargetPort" $L.portClosed "err"; $report["TCP"] = "Closed/Filtered"; $remediation += "New-NetFirewallRule -DisplayName 'WireGuard UI' -Direction Outbound -LocalPort $TargetPort -Protocol TCP -Action Allow" }
} catch {
    Write-StatusLine "$($L.port) $TargetPort" $L.portClosed "err"
    $report["TCP"] = "Closed/Filtered"
    if ($tcpClient) { try { $tcpClient.Close() } catch {} }
    $remediation += "New-NetFirewallRule -DisplayName 'WireGuard UI' -Direction Outbound -LocalPort $TargetPort -Protocol TCP -Action Allow"
}

Write-Section $L.httpSection 4
try { $req = [System.Net.HttpWebRequest]::Create("http://${ServerIP}:${TargetPort}"); $req.Timeout = 2000; Write-StatusLine $L.httpOk "HTTP $([int]$req.GetResponse().StatusCode)" "ok"; $report["HTTP"] = "OK" }
catch { Write-StatusLine $L.httpFail "" "err"; $report["HTTP"] = "FAILED" }

# [5] TRACEROUTE  (first 5 hops)
Write-Section $L.traceSection 5

if (-not (Get-Command "tracert" -ErrorAction SilentlyContinue)) {
    Write-StatusLine $L.notSupported $L.traceNoCmd "warn"
} else {
    try {
        $traceLines = & tracert -h 5 -w 1000 $ServerIP 2>&1 |
                      Where-Object { $_ -match '^\s+\d+' } |
                      Select-Object -First 5
        if ($traceLines) {
            foreach ($tl in $traceLines) {
                wh "     $($tl.ToString().Trim())" $C.Dim
            }
            $report["Traceroute"] = "Completed"
        } else {
            wh "     (no hops captured)" $C.Dim
            $report["Traceroute"] = "No hops"
        }
    } catch {
        Write-StatusLine "Traceroute" $_.Exception.Message "warn"
        $report["Traceroute"] = "Error"
    }
}

# [6] DNS RESOLUTION
Write-Section $L.dnsSection 6

try {
    $dns = [System.Net.Dns]::GetHostEntry($ServerIP)
    Write-StatusLine $L.dnsOk $dns.HostName "ok"
    $report["DNS"] = "Resolved"
} catch {
    Write-StatusLine $L.dnsFail "no PTR record / host unreachable" "warn"
    $report["DNS"] = "No PTR"
}

# [7] POWER MANAGEMENT
Write-Section $L.nicSection 7
if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
    Write-StatusLine "Not supported" "Get-NetAdapter cmdlets unavailable on this OS" "warn"
} else {
    $nics = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq "Up"
    if (-not $nics) { Write-StatusLine "No active NICs found" "" "err" }
    else {
        foreach ($nic in $nics) {
            $pm = $nic | Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue
            if (-not $pm) { continue }

            wh ""
            wh "     +-- Adapter: " $C.Accent -nonl
            wh $nic.InterfaceDescription $C.Title
            wh "     |" $C.Accent

            $fields = [ordered]@{
                "$($L.allowOff)  " = $pm.AllowComputerToTurnOffDevice
                "$($L.wakeMagic)  " = $pm.WakeOnMagicPacket
                "$($L.wakePattern) " = $pm.WakeOnPattern
            }
            foreach ($kv in $fields.GetEnumerator()) {
                $st    = if ($kv.Value -match "Enabled|True") { "warn" } else { "ok" }
                $icon  = if ($st -eq "warn") { "[!!]" } else { "[OK]" }
                $color = if ($st -eq "warn") { $C.Warn } else { $C.OK }
                wh "     |  $icon " $color -nonl
                wh "$($kv.Key): " $C.Reset -nonl
                wh $kv.Value $color
            }
            wh "     +$("-" * 46)" $C.Accent

            if ($pm.AllowComputerToTurnOffDevice -match "True|Enabled") {
                $report["NIC: $($nic.Name)"] = "PowerSave"
                $remediation += "Disable-NetAdapterPowerManagement -Name '$($nic.Name)' -ErrorAction SilentlyContinue"
            } else {
                $report["NIC: $($nic.Name)"] = "Optimized"
            }
        }
    }
}
$plan = try { powercfg /getactivescheme 2>&1 } catch { "" }
if ($plan -notmatch "High performance|Performances optimales" -and $plan -ne "") { $report["OS Power"] = "Not Optimal"; $remediation += "powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" } else { $report["OS Power"] = "High Perf" }

# SUMMARY & PLAYBOOK
wh "`n  +$('=' * 58)+" $C.Accent; wh "  |$("  $($L.summaryTitle)".PadRight(58))|" $C.Title; wh "  +$('=' * 58)+" $C.Accent
foreach ($kv in $report.GetEnumerator()) {
    $st = if ($kv.Value -match "FAILED|Closed|Spike") {"err"} elseif ($kv.Value -match "Stable|Open|Resolved|Optimized|High") {"ok"} else {"warn"}
    $ic = switch ($st) {"ok"{"[OK]"} "warn"{"[!!]"} "err"{"[XX]"}}; $cl = switch ($st) {"ok"{$C.OK} "warn"{$C.Warn} "err"{$C.Err}}
    wh "  |  $ic  $($kv.Key.PadRight(20)) $($kv.Value.ToString().PadRight(28)) |" $cl
}
wh "  +$('=' * 58)+" $C.Accent

if ($remediation.Count -gt 0) {
    wh "`n  +$('=' * 58)+" $C.Err; wh "  |$("  $($L.remTitle)".PadRight(58))|" $C.Title; wh "  +$('=' * 58)+" $C.Err
    $uniqueRemediation = $remediation | Select-Object -Unique
    $uniqueRemediation | ForEach-Object { wh "  > $_" $C.Warn }
    wh "  +$('-' * 58)+" $C.Err

    if ($isAdmin) {
        if ([Environment]::UserInteractive) {
            wh "`n  [?] $($L.runRemediation) " $C.Warn -nonl
            $applyFixes = Read-Host
            if ($applyFixes -match '^(y|yes)$') {
                wh ""
                foreach ($cmd in $uniqueRemediation) {
                    wh "      Executing: $cmd" $C.Dim
                    try { Invoke-Expression $cmd } catch { wh "      -> Failed: $_" $C.Err }
                }
                wh "  [OK] $($L.remApplied)" $C.OK
            }
        } else {
            wh "`n  [i] Non-interactive environment detected. Skipping auto-remediation prompt." $C.Dim
        }
    }
} else { wh "`n  [OK] $($L.remNone)" $C.OK }

if ($ExportJson) {
    $outDir = if ($LogDir) { $LogDir } else { $ScriptRoot }
    $jsonPath = Join-Path $outDir ("audit_{0}_{1}.json" -f $ServerIP, (Get-Date -Format "yyyyMMdd_HHmmss"))
    try {
        $report | ConvertTo-Json | Set-Content $jsonPath -Encoding UTF8
        wh "  [OK] $($L.jsonExported) $jsonPath" $C.Dim
    } catch {
        wh "  [XX] Failed to export JSON." $C.Warn
    }
}

if ($LogFile) { try { $LogBuffer.ToString() | Set-Content $LogFile -Encoding UTF8 } catch {} }