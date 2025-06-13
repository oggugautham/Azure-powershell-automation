<#
  Idempotent, non-interactive VM deploy script.
  Assumes the caller is already authenticated (handled by Azure/login).
#>

param(
    [string]$RgName    = 'rg-pwsh-demo',
    [string]$Location  = 'westus2',
    [string]$VmName    = 'demo-vm-ci'
)

Import-Module Az.Resources, Az.Compute -ErrorAction Stop

# Create RG if absent
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group $RgName in $Location"
    New-AzResourceGroup -Name $RgName -Location $Location | Out-Null
}

# Skip if VM already exists
if (Get-AzVM -ResourceGroupName $RgName -Name $VmName -ErrorAction SilentlyContinue) {
    Write-Host "VM $VmName already exists — nothing to do."
    return
}

# Quick-and-dirty local admin (OK for a demo; use secrets in prod)
$sec  = ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force
$cred = [PSCredential]::new('azureuser', $sec)

Write-Host "Creating VM $VmName ..."
New-AzVM -ResourceGroupName $RgName `
         -Name              $VmName `
         -Location          $Location `
         -Size              'Standard_D2s_v3' `
         -Image             'Ubuntu2204' `
         -Credential        $cred `
         | Out-Null

Write-Host "✅  VM $VmName created (or already present)."
