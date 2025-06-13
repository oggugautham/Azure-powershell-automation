<#
Ultra-simple, idempotent VM deploy.
Runs in GitHub Actions **or** locally.
#>

param(
    [string]$RgName      = 'rg-pwsh-demo',
    [string]$VmName      = 'demo-vm-ci',
    [string]$Location    = 'westus2',

    [string]$AdminUser = ${env:VM_ADMIN_USER} ? ${env:VM_ADMIN_USER} : 'azureuser',
    [SecureString]$AdminPassword = $(if ($env:VM_ADMIN_PWD)
                                      { ConvertTo-SecureString $env:VM_ADMIN_PWD -AsPlainText -Force }
                                      else { $null })
)

# ---- 0. Ensure Az modules (installs once, takes 1–2 min) ----
$needed = 'Az.Accounts','Az.Resources','Az.Compute'
foreach ($m in $needed) {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        Write-Host "› Installing $m …"
        Install-Module $m -Scope CurrentUser -Force -Repository PSGallery
    }
    Import-Module $m -ErrorAction Stop
}

# ---- 1. Auth for local runs ----
if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount | Out-Null }

# ---- 2. Check credentials ----
if (-not $AdminPassword) { throw 'Missing VM admin password (VM_ADMIN_PWD).' }
$cred = [PSCredential]::new($AdminUser, $AdminPassword)

# ---- 3. RG ----
if (-not (Get-AzResourceGroup -Name $RgName -EA SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location | Out-Null
}

# ---- 4. VM ----
if (Get-AzVM -ResourceGroupName $RgName -Name $VmName -EA SilentlyContinue) {
    Write-Host "✔️  VM '$VmName' already exists."
    return
}
Write-Host "🚀  Creating VM '$VmName' …"
New-AzVM -ResourceGroupName $RgName `
         -Name              $VmName `
         -Location          $Location `
         -Image             'Ubuntu2204' `
         -Size              'Standard_B2s' `
         -Credential        $cred `
         -OpenPorts         22 | Out-Null
Write-Host "✅  VM '$VmName' created."
