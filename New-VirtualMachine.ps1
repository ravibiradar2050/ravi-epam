param
(   
    [string] [Parameter(Mandatory=$true)] $SubscriptionID, 
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $Location,
    [string] $VirtualNetworkName = "ravi-vnet",
    [string] $AddressPrefix = "10.0.0.0/16",
    [string] $PrivateVmName = "private-vm",
    [string] $PublicVmName = "public-vm",
    [string] $PrivateSubnetName = "private-subnet",
    [string] $PublicSubnetName = "public-subnet",
    [int] $NumberOfVmsInPrivate = 2,
    [int] $NumberOfVmsInPublic = 2,
    [string] $PrivateSubnetLB = "PrivateVMsPublicIP",
    [string] $PublicSubnetLB = "PublicIp"
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

$cred = New-Object System.Management.Automation.PSCredential ("Ravi", (ConvertTo-SecureString -String "P@ssword@123" -AsPlainText -Force))

$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VirtualNetworkName
$PrivateAvailset = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name "PrivateAvailset" -Location $Location 
$PublicAvailset = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name "PublicAvailset" -Location $Location 

$PrivateVMloadBalancer = Get-AzureRmLoadBalancer -Name $PrivateSubnetLB -ResourceGroupName $ResourceGroupName
$PublicVMloadBalancer = Get-AzureRmLoadBalancer -Name $PublicSubnetLB -ResourceGroupName $ResourceGroupName

$flag = 1
while($flag -le $NumberOfVmsInPrivate){

$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location `
  -Name 'Nic1' -LoadBalancerBackendAddressPool $PrivateVMloadBalancer.BackendAddressPools[0] -LoadBalancerInboundNatRule $PrivateVMloadBalancer.InboundNatPools[0] -Subnet $vnet.Subnets[0]
# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $($PrivateVmName + $flag) -VMSize Standard_DS2 -AvailabilitySetId $PrivateAvailset.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName $($PrivateVmName + $flag) -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id

# Create a virtual machine
$vm1 = New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig
}

$flag = 1
while($flag -le $NumberOfVmsInPublic){

$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName -Location $location `
  -Name 'Nic1' -LoadBalancerBackendAddressPool $PublicVMloadBalancer.BackendAddressPools[0] -LoadBalancerInboundNatRule $PublicVMloadBalancer.InboundNatPools[0] -Subnet $vnet.Subnets[1]

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig -VMName $($PublicVmName + $flag) -VMSize Standard_DS2 -AvailabilitySetId $PublicAvailset.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName $($PrivateVmName + $flag) -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
  -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id

# Create a virtual machine
$vm1 = New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig
}