# Run on Windows with PowerShell. Uses a fake VBoxManage; no VM is changed.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $root 'scripts\virtualbox-display-workaround.ps1'
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $mock = Join-Path $tmp 'VBoxManage.cmd'
    $env:BLACKCOMB_TEST_CHANGED = Join-Path $tmp 'changed'
    $env:BLACKCOMB_TEST_LOG = Join-Path $tmp 'calls'
    $env:BLACKCOMB_TEST_STATE = 'poweroff'
    @'
@echo off
if "%~1"=="showvminfo" (
  echo VMState="%BLACKCOMB_TEST_STATE%"
  if exist "%BLACKCOMB_TEST_CHANGED%" (
    echo graphicscontroller="vboxsvga"
    echo vram=128
    echo accelerate3d="off"
  ) else (
    echo graphicscontroller="vmsvga"
    echo vram=16
    echo accelerate3d="on"
  )
  exit /b 0
)
if "%~1"=="modifyvm" (
  echo %*>>"%BLACKCOMB_TEST_LOG%"
  type nul >"%BLACKCOMB_TEST_CHANGED%"
  exit /b 0
)
exit /b 1
'@ | Set-Content -Encoding Ascii $mock

    & $script -VMName blackcomb -VBoxManagePath $mock -WhatIf
    if (Test-Path $env:BLACKCOMB_TEST_CHANGED) { throw 'WhatIf changed the VM.' }
    & $script -VMName blackcomb -VBoxManagePath $mock
    if (-not (Test-Path $env:BLACKCOMB_TEST_CHANGED)) { throw 'Display settings were not applied.' }
    $log = Get-Content $env:BLACKCOMB_TEST_LOG -Raw
    if ($log -notmatch 'modifyvm blackcomb --graphicscontroller vboxsvga --vram 128 --accelerate3d off') {
        throw "Unexpected VBoxManage command: $log"
    }
    Remove-Item $env:BLACKCOMB_TEST_CHANGED, $env:BLACKCOMB_TEST_LOG
    $env:BLACKCOMB_TEST_STATE = 'saved'
    $rejected = $false
    try { & $script -VMName blackcomb -VBoxManagePath $mock } catch { $rejected = $true }
    if (-not $rejected -or (Test-Path $env:BLACKCOMB_TEST_CHANGED)) { throw 'Saved VM was not rejected.' }
    Write-Host 'VirtualBox display workaround tests passed.'
} finally {
    Remove-Item -Recurse -Force $tmp
    Remove-Item Env:BLACKCOMB_TEST_CHANGED, Env:BLACKCOMB_TEST_LOG, Env:BLACKCOMB_TEST_STATE -ErrorAction SilentlyContinue
}
