<#
.SYNOPSIS
    Idempotent, non-interactive VM deployment script.

.DESCRIPTION
    • Creates the resource group if it does not exist.
    • Skips VM creation when the VM already exists.
    • Designed to run unattended in CI (GitHub Actions) *or* locally.
    • Installs required Az modules on the fly if they’re missing.
    • Uses environment variables (or parameters) for admin creds—no
      hard-coded passwords.

.PARAMETER RgName
    Name of the target resource group.

.PARAMETER VmName
    Name of the virtual machine to create or verify.

.PARAMETER Location
    Azure region.  Default: westus2.

.PARAMETER AdminUsername / AdminPassword
    Optional.  If omitted, script looks for VM_ADMIN_USER / VM_ADMIN_PWD
    environment variables.

.EXAMPLE
    ./create-vm.ps1 -RgName rg-demo -VmName demo-vm -Location eastus
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RgName,

    [Parameter(Mandatory=$true)]
    [string]$VmName,

    [string]$Location = 'westus2',

    [string]$AdminUsername = $env:VM_ADMIN_USER,
    [SecureString]$AdminPassword = $( if ($env:VM_ADMIN_PWD) {
                                         ConvertTo-SecureString $env:VM_ADMIN_PWD -AsPlainText -Force
                                     } else { $null } )
)

# -------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------
function Ensure-Module {
    param([string[]]$Name)
    foreach ($m in $Name) {
        if (-not (Get-Module -ListAvailable -Name $m)) {
            Write-Host "› Installing module '$m'…" -ForegroundColor Yellow
            Install-Module $m -Scope CurrentUser -Force -Repository PSGallery
        }
        Import-Module $m -ErrorAction Stop
    }
}

function Ensure-ResourceGroup {
    param([string]$Name, [string]$Location)
    if (-not (Get-AzResourceGroup -Name $Name -ErrorAction SilentlyContinue)) {
        Write-Host "› Creating resource group '$Name' in '$Location'…"
        New-AzResourceGroup -Name $Name -Location $Location | Out-Null
    }
}

function Ensure-VirtualMachine {
    param(
        [string]$ResourceGroup,
        [string]$Name,
        [string]$Location,
        [PSCredential]$Credential
    )

    if (Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host "✔️  VM '$Name' already exists — skipping."
        return
    }

    Write-Host "› Creating VM '$Name'…"
    New-AzVM -ResourceGroupName $ResourceGroup `
             -Name              $Name `
             -Location          $Location `
             -Size              'Standard_B2s' `
             -Image             'Ubuntu2204' `
             -Credential        $Credential `
             -OpenPorts         22 `
             | Out-Null
    Write-Host "✅  VM '$Name' created."
}

# -------------------------------------------------------------------
# Main script body
# -------------------------------------------------------------------

Ensure-Module -Name @('Az.Accounts','Az.Resources','Az.Compute')

# In CI jobs that used Azure/login (enable-AzPSSession) we’re already
# authenticated; locally we may need to sign in:
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }

if (-not $AdminUsername -or -not $AdminPassword) {
    throw "Admin credentials missing. Use parameters or set VM_ADMIN_USER / VM_ADMIN_PWD environment variables."
}
$cred = [PSCredential]::new($AdminUsername, $AdminPassword)

Ensure-ResourceGroup -Name $RgName -Location $Location
Ensure-VirtualMachine  -ResourceGroup $RgName `
                       -Name          $VmName `
                       -Location      $Location `
                       -Credential    $cred
