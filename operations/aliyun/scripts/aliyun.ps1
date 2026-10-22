#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',

    [Parameter(Position = 1)]
    [string]$Target,

    [string]$RR,
    [string]$Type,
    [string]$Value,
    [int]$TTL = 0,
    [string]$Line,
    [int]$Priority = 0,
    [string]$RecordId,
    [string]$Status,
    [int]$PageSize = 100,
    [string]$CliProfile = 'default',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Extra
)

$ErrorActionPreference = 'Stop'

function Get-AliyunExe {
    $fromPath = $null
    $cmd = Get-Command aliyun -ErrorAction SilentlyContinue
    if ($cmd) { $fromPath = $cmd.Source }
    $candidates = @(
        @(
            $fromPath,
            (Join-Path $env:LOCALAPPDATA 'AliyunCLI\aliyun.exe'),
            'C:\AliyunCLI\aliyun.exe'
        ) | Where-Object { $_ -and (Test-Path $_) }
    )
    if ($candidates.Count -eq 0) {
        throw "aliyun.exe not found. Expected $env:LOCALAPPDATA\AliyunCLI\aliyun.exe"
    }
    return [string]$candidates[0]
}

function Invoke-Aliyun {
    param([Parameter(Mandatory = $true)][string[]]$AliyunArgs)
    $exe = Get-AliyunExe
    $output = & $exe --profile $CliProfile @AliyunArgs 2>&1
    $text = ($output | ForEach-Object { "$_" }) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw "aliyun exit $LASTEXITCODE`n$text"
    }
    return $text
}

function ConvertFrom-AliyunJson {
    param([string]$Text)
    $trim = $Text.Trim()
    if (-not $trim) { return $null }
    return ($trim | ConvertFrom-Json)
}

function Show-Records {
    param($Payload)
    $rows = @()
    if ($Payload.DomainRecords -and $Payload.DomainRecords.Record) {
        $rows = @($Payload.DomainRecords.Record)
    }
    if ($rows.Count -eq 0) {
        Write-Output '(no records)'
        return
    }
    $rows |
        Sort-Object RR, Type |
        Select-Object RR, Type, Value, Line, TTL, Status, RecordId |
        Format-Table -AutoSize |
        Out-String |
        Write-Output
    Write-Output ("TotalCount={0}" -f $Payload.TotalCount)
}

function Require-Param {
    param([string]$Name, $Val)
    if ([string]::IsNullOrWhiteSpace([string]$Val)) {
        throw "missing required -$Name"
    }
}

function Add-Opt {
    param([System.Collections.Generic.List[string]]$List, [string]$Flag, $Val)
    if ($null -eq $Val) { return }
    $s = [string]$Val
    if ([string]::IsNullOrWhiteSpace($s)) { return }
    if ($Val -is [int] -and [int]$Val -le 0) { return }
    $List.Add($Flag) | Out-Null
    $List.Add($s) | Out-Null
}

switch ($Command.ToLowerInvariant()) {
    'help' {
        @'
usage:
  aliyun.ps1 whoami
  aliyun.ps1 domains
  aliyun.ps1 records <domain> [-RR www] [-Type A] [-Value 1.2.3.4]
  aliyun.ps1 subdomain <fqdn> [-Type A]
  aliyun.ps1 info -RecordId <id>
  aliyun.ps1 ns <domain>
  aliyun.ps1 logs <domain>
  aliyun.ps1 add <domain> -RR www -Type A -Value 1.2.3.4 [-TTL 600] [-Line default] [-Priority 1]
  aliyun.ps1 update -RecordId <id> -RR www -Type A -Value 1.2.3.4 [-TTL 600] [-Line default] [-Priority 1]
  aliyun.ps1 delete -RecordId <id>
  aliyun.ps1 status -RecordId <id> -Status Enable|Disable
  aliyun.ps1 run <product> <Action> [--Param value ...]
'@ | Write-Output
    }
    'whoami' {
        Invoke-Aliyun -AliyunArgs @('sts', 'GetCallerIdentity')
    }
    'domains' {
        $argsList = [System.Collections.Generic.List[string]]@('alidns', 'DescribeDomains', '--PageSize', [string]$PageSize)
        Invoke-Aliyun -AliyunArgs $argsList.ToArray()
    }
    'records' {
        Require-Param 'Target(domain)' $Target
        $argsList = [System.Collections.Generic.List[string]]@('alidns', 'DescribeDomainRecords', '--DomainName', $Target, '--PageSize', [string]$PageSize)
        Add-Opt $argsList '--RRKeyWord' $RR
        Add-Opt $argsList '--Type' $Type
        Add-Opt $argsList '--ValueKeyWord' $Value
        $json = Invoke-Aliyun -AliyunArgs $argsList.ToArray()
        Write-Output $json
        Show-Records (ConvertFrom-AliyunJson $json)
    }
    'subdomain' {
        Require-Param 'Target(fqdn)' $Target
        $argsList = [System.Collections.Generic.List[string]]@('alidns', 'DescribeSubDomainRecords', '--SubDomain', $Target, '--PageSize', [string]$PageSize)
        Add-Opt $argsList '--Type' $Type
        Add-Opt $argsList '--Line' $Line
        $json = Invoke-Aliyun -AliyunArgs $argsList.ToArray()
        Write-Output $json
        Show-Records (ConvertFrom-AliyunJson $json)
    }
    'info' {
        Require-Param 'RecordId' $RecordId
        Invoke-Aliyun -AliyunArgs @('alidns', 'DescribeDomainRecordInfo', '--RecordId', $RecordId)
    }
    'ns' {
        Require-Param 'Target(domain)' $Target
        Invoke-Aliyun -AliyunArgs @('alidns', 'DescribeDomainNs', '--DomainName', $Target)
    }
    'logs' {
        Require-Param 'Target(domain)' $Target
        Invoke-Aliyun -AliyunArgs @('alidns', 'DescribeRecordLogs', '--DomainName', $Target, '--PageSize', [string]$PageSize)
    }
    'add' {
        Require-Param 'Target(domain)' $Target
        Require-Param 'RR' $RR
        Require-Param 'Type' $Type
        Require-Param 'Value' $Value
        $argsList = [System.Collections.Generic.List[string]]@(
            'alidns', 'AddDomainRecord',
            '--DomainName', $Target,
            '--RR', $RR,
            '--Type', $Type,
            '--Value', $Value
        )
        if ($TTL -gt 0) { Add-Opt $argsList '--TTL' $TTL } else { Add-Opt $argsList '--TTL' 600 }
        Add-Opt $argsList '--Line' $(if ($Line) { $Line } else { 'default' })
        if ($Type -eq 'MX') { Require-Param 'Priority' $Priority }
        Add-Opt $argsList '--Priority' $Priority
        Invoke-Aliyun -AliyunArgs $argsList.ToArray()
    }
    'update' {
        Require-Param 'RecordId' $RecordId
        Require-Param 'RR' $RR
        Require-Param 'Type' $Type
        Require-Param 'Value' $Value
        $argsList = [System.Collections.Generic.List[string]]@(
            'alidns', 'UpdateDomainRecord',
            '--RecordId', $RecordId,
            '--RR', $RR,
            '--Type', $Type,
            '--Value', $Value
        )
        if ($TTL -gt 0) { Add-Opt $argsList '--TTL' $TTL }
        Add-Opt $argsList '--Line' $Line
        if ($Type -eq 'MX') { Require-Param 'Priority' $Priority }
        Add-Opt $argsList '--Priority' $Priority
        Invoke-Aliyun -AliyunArgs $argsList.ToArray()
    }
    'delete' {
        Require-Param 'RecordId' $RecordId
        Invoke-Aliyun -AliyunArgs @('alidns', 'DeleteDomainRecord', '--RecordId', $RecordId)
    }
    'status' {
        Require-Param 'RecordId' $RecordId
        Require-Param 'Status' $Status
        $norm = $Status
        if ($Status -match '^(?i)enable$') { $norm = 'Enable' }
        elseif ($Status -match '^(?i)disable$') { $norm = 'Disable' }
        else { throw "Status must be Enable or Disable, got $Status" }
        Invoke-Aliyun -AliyunArgs @('alidns', 'SetDomainRecordStatus', '--RecordId', $RecordId, '--Status', $norm)
    }
    'run' {
        if ([string]::IsNullOrWhiteSpace($Target)) {
            throw 'run requires product name, e.g. aliyun.ps1 run ecs DescribeInstances'
        }
        $argsList = [System.Collections.Generic.List[string]]@($Target)
        if ($Extra) { foreach ($e in $Extra) { $argsList.Add($e) | Out-Null } }
        if ($argsList.Count -lt 2) {
            throw 'run requires <product> <Action>'
        }
        Invoke-Aliyun -AliyunArgs $argsList.ToArray()
    }
    default {
        throw "unknown command: $Command (try help)"
    }
}
