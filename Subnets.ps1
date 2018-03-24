param
(   
    [string] [Parameter(Mandatory=$true)] $SubscriptionID, 
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $Location,
    [string] $VirtualNetworkName = "ravi-vnet",
    [string] $AddressPrefix = "10.0.0.0/16"
)

$ErrorActionPreference = 'Stop'

#Ensure we are logged into Azure RM
try
{
    $login = Set-AzureRmContext -SubscriptionId $SubscriptionId 
}

catch [System.Exception]
{
    $login  = Login-AzureRmAccount
    if ($login -eq $null){ 
        return
    }
    #Set-AzureRmContext cmdlet to set authentication information for cmdlets that we run in this PS session.
    $login = Set-AzureRmContext -SubscriptionId $SubscriptionId 
}

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VirtualNetworkName

# Create a network security group rule for port 3389.
$rule = New-AzureRmNetworkSecurityRuleConfig -Name 'NetworkSecurityGroupRuleRDP' -Description 'Block RDP' `
  -Access Deny -Protocol Tcp -Direction Inbound -Priority 1000 `
  -SourceAddressPrefix Internet -SourcePortRange * `
  -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $location `
-Name 'NetworkSecurityGroup' -SecurityRules $rule

#Private Subnet
Add-AzureRmVirtualNetworkSubnetConfig -Name "private-subnet" -AddressPrefix "10.0.0.0/24" -VirtualNetwork $vnet -NetworkSecurityGroup $nsg

#Public Subnet
Add-AzureRmVirtualNetworkSubnetConfig -Name "public-subnet" -AddressPrefix "10.0.1.0/24" -VirtualNetwork $vnet 
$vnet | Set-AzureRmVirtualNetwork