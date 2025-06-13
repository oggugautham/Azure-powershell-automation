<#
    Simple, non-interactive VM deploy script
    Assumes the caller is already authenticated (GitHub OIDC workflow does that)
#>

param(
    [string]$RgName     = "rg-pwsh-demo",
    [string]$Location   = "westus2",
    [string]$VmName     = "demo-vm-ci",
    [string]$AdminUser  = "azureuser",
    [string]$AdminPass  = "P@ssw0rd123!"      # USE A SECRET IN REAL PROJECTS
)

# Make sure Az.Resources & Az.Compute are loaded
Import-Module Az.Resources,Az.Compute -ErrorAction Stop

# 1. Create RG if missing
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group $RgName in $Location"
    New-AzResourceGroup -Name $RgName -Location $Location | Out-Null
}

# 2. Skip if VM already exists
if (Get-AzVM -ResourceGroupName $RgName -Name $VmName -ErrorAction SilentlyContinue) {
    Write-Host "VM $VmName already exists — skipping creation."
    return
}

# 3. Convert creds and build VM
$sec  = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$cred = [PSCredential]::new($AdminUser, $sec)

Write-Host "Creating VM $VmName ..."
New-AzVM -ResourceGroupName $RgName `
         -Name              $VmName `
         -Location          $Location `
         -Size              "Standard_D2s_v3" `
         -Image             "Ubuntu2204" `
         -Credential        $cred `
         -PublicIpAddressName "${VmName}-ip" `
         -VirtualNetworkName "${VmName}-vnet" `
         -SubnetName        "default" `
         -SecurityGroupName "${VmName}-nsg" `
         | Out-Null

Write-Host "✅ VM $VmName created."
