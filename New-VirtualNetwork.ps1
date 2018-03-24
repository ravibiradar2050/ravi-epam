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

New-AzureRmVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix "10.0.0.0/16" -Verbose 