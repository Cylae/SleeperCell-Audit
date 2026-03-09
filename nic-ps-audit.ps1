# ================================================================
#  Connectivity & Power Management Audit
#  Target : Debian Server (WireGuard Web UI)
# ================================================================
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage="Target server IP address")]
    [string]$ServerIP   = "192.168.1.254",
    [Parameter(Mandatory=$false, HelpMessage="Target TCP port for probe")]
    [int]   $TargetPort = 51821,
    [Parameter(Mandatory=$false, HelpMessage="Number of ping probes")]
    [int]   $PingCount  = 5
)

# ── Palette ──────────────────────────────────────────────────────
$C = @{
    Title  = "White"
    Head   = "Cyan"
    OK     = "Green"
    Warn   = "Yellow"
    Err    = "Red"
    Dim    = "DarkGray"
    Accent = "DarkCyan"
    Reset  = "Gray"
}

# ── Helpers ──────────────────────────────────────────────────────
function Write-Banner {
    $w    = 62
    $line = '=' * $w
    Write-Host ""
    Write-Host "  +$line+" -ForegroundColor $C.Accent
    Write-Host "  |$(' ' * $w)|" -ForegroundColor $C.Accent
    Write-Host "  |$("  CONNECTIVITY & POWER MANAGEMENT AUDIT".PadRight($w))|" -ForegroundColor $C.Title
    Write-Host "  |$("  Target: $ServerIP   Port: $TargetPort".PadRight($w))|" -ForegroundColor $C.Head
    Write-Host "  |$("  $(Get-Date -Format 'dddd dd MMMM yyyy  -  HH:mm:ss')".PadRight($w))|" -ForegroundColor $C.Dim
    Write-Host "  |$(' ' * $w)|" -ForegroundColor $C.Accent
    Write-Host "  +$line+" -ForegroundColor $C.Accent
    Write-Host ""
}

function Write-Section {
    param([string]$Title, [int]$Step)
    Write-Host ""
    Write-Host "  +--[ " -NoNewline -ForegroundColor $C.Accent
    Write-Host "STEP $Step" -NoNewline -ForegroundColor $C.Head
    Write-Host " ]" -NoNewline -ForegroundColor $C.Accent
    Write-Host ("-" * (44 - "STEP $Step".Length)) -ForegroundColor $C.Accent
    Write-Host "  |  >> $Title" -ForegroundColor $C.Title
    Write-Host "  +" -NoNewline -ForegroundColor $C.Accent
    Write-Host ("-" * 50) -ForegroundColor $C.Accent
}

function Write-StatusLine {
    param([string]$Label, [string]$Value, [string]$Status)
    $icon  = switch ($Status) { "ok" {"[OK]"} "warn" {"[!!]"} "err" {"[XX]"} default {"[..]"} }
    $color = switch ($Status) { "ok" {$C.OK}  "warn" {$C.Warn} "err" {$C.Err} default {$C.Reset} }
    Write-Host "     $icon " -NoNewline -ForegroundColor $color
    Write-Host $Label -NoNewline -ForegroundColor $C.Reset
    if ($Value) {
        Write-Host " -> " -NoNewline -ForegroundColor $C.Dim
        Write-Host $Value -ForegroundColor $color
    } else { Write-Host "" }
}

function Get-PingLatency {
    param($R)
    if ($null -eq $R) { return $null }

    if ($R.PSObject.Properties["ResponseTime"]) {
        return [int]$R.ResponseTime
    }

    if ($R.PSObject.Properties["Latency"]) {
        if ($R.Latency -is [TimeSpan]) {
            return [int]$R.Latency.TotalMilliseconds
        } else {
            return [int]$R.Latency
        }
    }
    return $null
}

function Write-LatencyBar {
    param([int]$ms, [int]$Max = 300, [int]$W = 28)
    $fill  = [math]::Min([math]::Round(($ms / $Max) * $W), $W)
    $empty = $W - $fill
    $color = if ($ms -lt 20) { $C.OK } elseif ($ms -lt 80) { $C.Warn } else { $C.Err }
    Write-Host "          [" -NoNewline -ForegroundColor $C.Dim
    Write-Host ("#" * $fill) -NoNewline -ForegroundColor $color
    Write-Host ("." * $empty) -NoNewline -ForegroundColor $C.Dim
    Write-Host ("] {0,4}ms" -f $ms) -ForegroundColor $color
}

function Write-SummaryTable {
    param([System.Collections.Specialized.OrderedDictionary]$Data)
    $w = 58
    Write-Host ""
    Write-Host "  +$('=' * $w)+" -ForegroundColor $C.Accent
    Write-Host "  |$("  AUDIT SUMMARY".PadRight($w))|" -ForegroundColor $C.Title
    Write-Host "  +$('=' * $w)+" -ForegroundColor $C.Accent

    foreach ($kv in $Data.GetEnumerator()) {
        $status = if   ($kv.Value -match "FAILED|Closed|Spike") { "err" }
                  elseif ($kv.Value -match "Stable|Open|Resolved|Disabled") { "ok" }
                  else { "warn" }
        $icon  = switch ($status) { "ok"{"[OK]"} "warn"{"[!!]"} "err"{"[XX]"} }
        $color = switch ($status) { "ok"{$C.OK}  "warn"{$C.Warn} "err"{$C.Err} }

        $keyPart = ("  |  $icon  " + $kv.Key)
        $valPart = if ($kv.Value -eq $null) { "" } else { $kv.Value.ToString() }

        $visibleKeyLen = $kv.Key.Length + 9
        $pad = $w - $visibleKeyLen - $valPart.Length - 2

        $row = "$keyPart$(' ' * [math]::Max($pad,1))$valPart  |"
        Write-Host $row -ForegroundColor $color
    }

    Write-Host "  +$('=' * $w)+" -ForegroundColor $C.Accent
}

# ================================================================
#  INIT
# ================================================================
$report = [ordered]@{}

Write-Banner

# Privilege check
$isWinEnvironment = ($null -eq $IsWindows -and $PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows
if ($isWinEnvironment) {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin     = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} else {
    $isAdmin = (id -u) -eq 0
}

if ($isAdmin) {
    Write-Host "  [OK] Running as Administrator / root" -ForegroundColor $C.OK
} else {
    Write-Host "  [!!] Not Administrator - ARP flush & NIC data may be limited" -ForegroundColor $C.Warn
}

# ================================================================
#  [1] ARP RESOLUTION
# ================================================================
Write-Section "ARP Resolution" 1

if ($isAdmin) {
    arp -d $ServerIP 2>$null
    Write-Host "       Cache flushed for $ServerIP" -ForegroundColor $C.Dim
} else {
    Write-Host "       Skipping flush - requires elevation" -ForegroundColor $C.Dim
}

$null     = Test-Connection -ComputerName $ServerIP -Count 1 -Quiet -ErrorAction SilentlyContinue
$arpEntry = arp -a | Select-String "\b$([regex]::Escape($ServerIP))\b"

if ($arpEntry) {
    Write-StatusLine "ARP Resolved" $arpEntry.ToString().Trim() "ok"
    $report["ARP"] = "Resolved"
} else {
    Write-StatusLine "ARP Failed" "server may be in deep sleep / power-save" "err"
    $report["ARP"] = "FAILED"
}

# ================================================================
#  [2] LATENCY PROFILE
# ================================================================
Write-Section "Latency Profile  ($PingCount pings)" 2

$latencies    = @()
$timeoutCount = 0

for ($i = 1; $i -le $PingCount; $i++) {
    $ping    = Test-Connection -ComputerName $ServerIP -Count 1 -ErrorAction SilentlyContinue
    $latency = Get-PingLatency $ping

    if ($null -ne $latency) {
        $tag = if ($i -eq 1) { "  <- first packet" } else { "" }
        Write-Host ("     Ping [{0}/{1}]{2}" -f $i, $PingCount, $tag) -ForegroundColor $C.Dim
        Write-LatencyBar -ms $latency
        $latencies += $latency
    } else {
        Write-Host ("     Ping [{0}/{1}] " -f $i, $PingCount) -NoNewline -ForegroundColor $C.Dim
        Write-Host "Timeout" -ForegroundColor $C.Err
        $timeoutCount++
    }
}

Write-Host ""

if ($latencies.Count -ge 1) {
    $firstPacket = $latencies[0]
    $minLat      = ($latencies | Measure-Object -Minimum).Minimum
    $maxLat      = ($latencies | Measure-Object -Maximum).Maximum

    if ($latencies.Count -ge 2) {
        $restAvg = [math]::Round(($latencies[1..($latencies.Count - 1)] | Measure-Object -Average).Average, 1)
        $spike   = $firstPacket - $restAvg
    } else {
        $restAvg = $firstPacket
        $spike   = 0
    }

    $spikeColor = if ($spike -gt 100) { $C.Warn } else { $C.OK }

    Write-Host "     +------------------------------------+" -ForegroundColor $C.Accent
    Write-Host ("     |  First packet  : {0,6}ms           |" -f $firstPacket) -ForegroundColor $C.Reset
    Write-Host ("     |  Avg (rest)    : {0,6}ms           |" -f $restAvg)     -ForegroundColor $C.Reset
    Write-Host ("     |  Min / Max     : {0,4}ms / {1,4}ms    |" -f $minLat, $maxLat) -ForegroundColor $C.Reset
    Write-Host ("     |  Spike delta   : {0,6}ms           |" -f $spike)       -ForegroundColor $spikeColor
    Write-Host "     +------------------------------------+" -ForegroundColor $C.Accent
    Write-Host ""

    if ($spike -gt 100) {
        Write-StatusLine "First-packet spike of ${spike}ms" "NIC likely power-saving" "warn"
        $report["Latency"] = "Spike: ${spike}ms"
    } else {
        Write-StatusLine "Latency stable" "spike ${spike}ms" "ok"
        $report["Latency"] = "Stable"
    }
} else {
    Write-StatusLine "Insufficient replies" "$timeoutCount timeouts" "err"
    $report["Latency"] = "FAILED ($timeoutCount timeouts)"
}

# ================================================================
#  [3] TCP PORT PROBE
# ================================================================
Write-Section "TCP Port $TargetPort Probe" 3

$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $connectTask = $tcpClient.ConnectAsync($ServerIP, $TargetPort)
    $success = $connectTask.Wait(2000)

    if ($success -and $tcpClient.Connected) {
        Write-StatusLine "Port $TargetPort" "OPEN" "ok"
        $report["Port $TargetPort"] = "Open"
        $tcpClient.Close()
    } else {
        Write-StatusLine "Port $TargetPort" "CLOSED or Filtered" "err"
        $report["Port $TargetPort"] = "Closed/Filtered"
        if ($tcpClient) { $tcpClient.Close() }
    }
} catch {
    Write-StatusLine "Port $TargetPort" "CLOSED or Filtered" "err"
    $report["Port $TargetPort"] = "Closed/Filtered"
    if ($tcpClient) { $tcpClient.Close() }
}

# ================================================================
#  [4] NIC POWER MANAGEMENT
# ================================================================
Write-Section "Local NIC Power Management" 4

if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
    Write-StatusLine "Not supported" "Get-NetAdapter cmdlets unavailable on this OS" "warn"
} else {
    $nics = Get-NetAdapter | Where-Object Status -eq "Up"

    if (-not $nics) {
        Write-StatusLine "No active NICs found" "" "err"
    } else {
    foreach ($nic in $nics) {
        $pm = $nic | Get-NetAdapterPowerManagement -ErrorAction SilentlyContinue
        if (-not $pm) { continue }

        Write-Host ""
        Write-Host "     +-- Adapter: " -NoNewline -ForegroundColor $C.Accent
        Write-Host $nic.InterfaceDescription -ForegroundColor $C.Title
        Write-Host "     |" -ForegroundColor $C.Accent

        $fields = [ordered]@{
            "Allow PC to turn off  " = $pm.AllowComputerToTurnOffDevice
            "Wake on Magic Packet  " = $pm.WakeOnMagicPacket
            "Wake on Pattern Match " = $pm.WakeOnPattern
        }
        foreach ($kv in $fields.GetEnumerator()) {
            $st    = if ($kv.Value -match "Enabled|True") { "warn" } else { "ok" }
            $icon  = if ($st -eq "warn") { "[!!]" } else { "[OK]" }
            $color = if ($st -eq "warn") { $C.Warn } else { $C.OK }
            Write-Host "     |  $icon " -NoNewline -ForegroundColor $color
            Write-Host "$($kv.Key): " -NoNewline -ForegroundColor $C.Reset
            Write-Host $kv.Value -ForegroundColor $color
        }
        Write-Host "     +$("-" * 46)" -ForegroundColor $C.Accent
        $report["NIC: $($nic.Name)"] = "AllowOff=$($pm.AllowComputerToTurnOffDevice)"
    }
    }
}

# ================================================================
#  SUMMARY
# ================================================================
Write-SummaryTable -Data $report

$failed = ($report.Values | Where-Object { $_ -match "FAILED|Closed|Spike" }).Count
Write-Host ""
if ($failed -eq 0) {
    Write-Host "  [OK] All checks passed - server looks healthy." -ForegroundColor $C.OK
} else {
    Write-Host "  [!!] $failed check(s) require attention." -ForegroundColor $C.Warn
}
Write-Host "  Completed at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor $C.Dim
Write-Host ""