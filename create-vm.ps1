param(
  [string]$RgName = "rg-pwsh-demo",
  [string]$Location = "canadacentral",
  [string]$VmName = "demo-vm-from-ps"
)

# Create RG if needed
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location
}

# Simple VM (Ubuntu 22.04, Standard_B1s)
$cred = Get-Credential -Message "Local VM admin"
New-AzVM -ResourceGroupName $RgName `
         -Name $VmName `
         -Location $Location `
         -Size "Standard_B1s" `
         -Image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest" `
         -Credential $cred
