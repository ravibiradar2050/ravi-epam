param
(   
    [string] [Parameter(Mandatory=$true)] $SubscriptionID, 
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $Location,
    [string] $PublicAddressName = "PublicIP",
    $PrivateSubnetVmsPublicIp = "PrivateVMsPublicIP"
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


$publicIp = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PublicAddressName 

$feip = New-AzureRmLoadBalancerFrontendIpConfig -Name 'FrontEndPool' -PublicIpAddress $publicIp

$bepool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name 'BackEndPool'

$probe = New-AzureRmLoadBalancerProbeConfig -Name 'HealthProbe' -Protocol Http -Port 80 -RequestPath / -IntervalInSeconds 360 -ProbeCount 5

$rule = New-AzureRmLoadBalancerRuleConfig -Name 'LoadBalancerRuleWeb' -Protocol Tcp -Probe $probe -FrontendPort 80 -BackendPort 80 -FrontendIpConfiguration $feip -BackendAddressPool $bePool

# Create three NAT rules for port 3389.
$natrule = New-AzureRmLoadBalancerInboundNatRuleConfig -Name 'LoadBalancerRDP' -FrontendIpConfiguration $feip -Protocol tcp -FrontendPort 55877 -BackendPort 3389

# Create a load balancer.
$lb = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name 'PublicLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feip -BackendAddressPool $bepool `
  -Probe $probe -LoadBalancingRule $rule -InboundNatRule $natrule

$publicIp = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PrivateSubnetVmsPublicIp 

$feip = New-AzureRmLoadBalancerFrontendIpConfig -Name 'FrontEndPool' -PublicIpAddress $publicIp

$bepool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name 'BackEndPool'

$probe = New-AzureRmLoadBalancerProbeConfig -Name 'HealthProbe' -Protocol Http -Port 80 -RequestPath / -IntervalInSeconds 360 -ProbeCount 5

$rule = New-AzureRmLoadBalancerRuleConfig -Name 'LoadBalancerRuleWeb' -Protocol Tcp -Probe $probe -FrontendPort 80 -BackendPort 80 -FrontendIpConfiguration $feip -BackendAddressPool $bePool

# Create three NAT rules for port 3389.
$natrule = New-AzureRmLoadBalancerInboundNatRuleConfig -Name 'LoadBalancerRDP' -FrontendIpConfiguration $feip -Protocol tcp -FrontendPort 55877 -BackendPort 3389

# Create a load balancer.
$lb = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name 'PrivateVMLoadBalancer' -Location $location `
  -FrontendIpConfiguration $feip -BackendAddressPool $bepool `
  -Probe $probe -LoadBalancingRule $rule -InboundNatRule $natrule



