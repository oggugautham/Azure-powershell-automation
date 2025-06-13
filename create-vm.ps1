<#
Simple, non-interactive VM deploy.
Assumes Az.* modules and authentication are already in the session
(GitHub-Actions Azure/login with enable-AzPSSession:true does that).
#>

param(
    [string]$RgName      = 'rg-pwsh-demo',
    [string]$VmName      = 'demo-vm-ci',
    [string]$Location    = 'westus2',

    # Credentials – default to secrets passed by the workflow
    [string]$AdminUser   = ${env:VM_ADMIN_USER}  ? ${env:VM_ADMIN_USER} : 'azureuser',
    [SecureString]$AdminPassword = $(if ($env:VM_ADMIN_PWD)
                                       { ConvertTo-SecureString $env:VM_ADMIN_PWD -AsPlainText -Force }
                                       else { $null })
)

# ---------- 0. Modules present? (CI should have them already) ----------
if (-not (Get-Module -ListAvailable Az.Resources -ErrorAction SilentlyContinue)) {
    throw 'Az modules missing. Ensure Azure/login step uses enable-AzPSSession: true.'
}

# ---------- 1. Authenticate for local runs ----------
if (-not (Get-AzContext -ErrorAction SilentlyContinue)) { Connect-AzAccount | Out-Null }

# ---------- 2. Validate creds ----------
if (-not $AdminPassword) {
    throw 'Admin password missing. Add VM_ADMIN_PWD secret or pass -AdminPassword.'
}
$cred = [PSCredential]::new($AdminUser, $AdminPassword)

# ---------- 3. Resource group ----------
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location | Out-Null
}

# ---------- 4. Virtual machine ----------
if (Get-AzVM -ResourceGroupName $RgName -Name $VmName -ErrorAction SilentlyContinue) {
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
