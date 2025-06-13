param(
  [string]$RgName = "rg-pwsh-demo",
  [string]$Location = "canadacentral",
  [string]$VmName = "demo-vm-from-ps",
  [string]$AdminUsername = "azureuser",
  [string]$AdminPassword = "P@ssw0rd123!"  # use a strong one in real use
)

# Convert password to secure string
$securePassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($AdminUsername, $securePassword)

# Create RG if it doesn't exist
if (-not (Get-AzResourceGroup -Name $RgName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $RgName -Location $Location
}

# Create VM
New-AzVM -ResourceGroupName $RgName `
         -Name $VmName `
         -Location $Location `
         -Size "Standard_B1s" `
         -Image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest" `
         -Credential $cred
