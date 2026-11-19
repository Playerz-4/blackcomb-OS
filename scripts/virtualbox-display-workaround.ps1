<#
.SYNOPSIS
    Try the VBoxSVGA workaround for a Fedora KDE black screen in VirtualBox.
.DESCRIPTION
    Run on the Windows host, not inside the guest. Changes only the selected
    powered-off VM's display controller, video memory, and 3D acceleration.
    This is a workaround, not a guaranteed fix. The previous settings and a
    command to restore them are printed before any change is made.
.EXAMPLE
    .\virtualbox-display-workaround.ps1 -VMName blackcomb
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VMName,
    [string] $VBoxManagePath
)

$ErrorActionPreference = 'Stop'
if (-not $VBoxManagePath) {
    $command = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($command) {
        $VBoxManagePath = $command.Source
    } elseif ($env:ProgramFiles) {
        $VBoxManagePath = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
    }
}
if (-not $VBoxManagePath -or -not (Test-Path -LiteralPath $VBoxManagePath -PathType Leaf)) {
    throw 'VBoxManage.exe not found. Run on the Windows host or specify -VBoxManagePath.'
}

function Read-VMInfo {
    $lines = & $VBoxManagePath showvminfo $VMName --machinereadable
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage could not read VM '$VMName'." }
    $info = @{}
    foreach ($line in $lines) {
        if ($line -match '^(VMState|graphicscontroller|vram|accelerate3d)="?([a-zA-Z0-9_-]+)"?$') {
            $info[$Matches[1]] = $Matches[2]
        }
    }
    foreach ($key in @('VMState', 'graphicscontroller', 'vram', 'accelerate3d')) {
        if (-not $info.ContainsKey($key)) { throw "Missing $key in VBoxManage output; no changes made." }
    }
    return $info
}

$before = Read-VMInfo
if ($before.VMState -ne 'poweroff') {
    throw "VM '$VMName' is $($before.VMState). Power it off completely (do not save state) before running this script."
}
if ($before.graphicscontroller -notin @('none', 'vboxvga', 'vboxsvga', 'vmsvga') -or
    $before.accelerate3d -notin @('on', 'off') -or $before.vram -notmatch '^\d+$') {
    throw 'Unexpected display settings; no changes made.'
}
$quotedName = $VMName.Replace("'", "''")
Write-Host "Current display: controller=$($before.graphicscontroller), video memory=$($before.vram) MB, 3D=$($before.accelerate3d)"
Write-Host "Restore later (in PowerShell, with VM powered off):"
Write-Host "& '$($VBoxManagePath.Replace("'", "''"))' modifyvm '$quotedName' --graphicscontroller $($before.graphicscontroller) --vram $($before.vram) --accelerate3d $($before.accelerate3d)"
if ($PSCmdlet.ShouldProcess($VMName, 'Set VBoxSVGA, 128 MB video memory, and 3D acceleration off')) {
    & $VBoxManagePath modifyvm $VMName --graphicscontroller vboxsvga --vram 128 --accelerate3d off
    if ($LASTEXITCODE -ne 0) { throw 'VBoxManage failed to change the VM settings.' }
    $after = Read-VMInfo
    if ($after.graphicscontroller -ne 'vboxsvga' -or $after.vram -ne '128' -or $after.accelerate3d -ne 'off') {
        throw 'VBoxManage did not report the requested display settings; check the VM settings.'
    }
    Write-Host 'Display workaround applied. Start the VM to test it.'
}
