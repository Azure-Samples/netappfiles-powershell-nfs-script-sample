<#
.SYNOPSIS
    This script creates Azure Netapp files resources with NFS volume type
.DESCRIPTION
    Authenticates with Azure and select the targeted subscription first, then created ANF account, capacity pool and NFS Volume
.PARAMETER SubscriptionId
    Target Subscription
.PARAMETER ResourceGroupName
    Name of the Azure Resource Group where the ANF will be created
.PARAMETER Location
    Azure Location (e.g 'WestUS', 'EastUS')
.PARAMETER NetAppAccountName
    Name of the Azure NetApp Files Account
.PARAMETER NetAppPoolName
    Name of the Azure NetApp Files Capacity Pool
.PARAMETER ServiceLevel
    Service Level - Ultra, Premium or Standard
.PARAMETER NetAppPoolSize
    Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
.PARAMETER NetAppVolumeName\
    Name of the Azure NetApp Files Volume
.PARAMETER ProtocolType
    Protocol Type - NFSv4.1 or NFSv3
.PARAMETER NetAppVolumeSize
    Size of the Azure NetApp Files volume in Bytes. Range between 107374182400 and 109951162777600
.PARAMETER SubnetId
    The Delegated subnet Id within the VNET
.PARAMETER EPUnixReadOnly 
    Export Policy UnixReadOnly property 
.PARAMETER EPUnixReadWrite
    Export Policy UnixReadWrite property
.PARAMETER AllowedClientsIp 
    Client IP to access Azure NetApp files volume
.PARAMETER CleanupResources
    If the script should clean up the resources, $false by default
.EXAMPLE
    PS C:\\> CreateANFVolume.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000' -ResourceGroupName 'My-RG' -Location 'WestUS' -NetAppAccountName 'testaccount' -NetAppPoolName 'pool1' -ServiceLevel Standard -NetAppVolumeName 'vol1' -ProtocolType NFSv4.1 -SubnetId '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/My-RG/providers/Microsoft.Network/virtualNetworks/vnet1/subnets/subnet1'
#>
param
(
    # Name of the Azure Resource Group
    [Parameter(Mandatory)]
    [string]$SubscriptionId,

    # Name of the Azure Resource Group
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    #Azure location 
    [Parameter(Mandatory)]
    [string]$Location,

    #Azure NetApp Files account name
    [Parameter(Mandatory)]
    [string]$NetAppAccountName,

    #Azure NetApp Files capacity pool name
    [Parameter(Mandatory)]
    [string]$NetAppPoolName,

    # Service Level can be {Ultra, Premium or Standard}
    [Parameter(Mandatory)]
    [ValidateSet("Ultra","Premium","Standard")]
    [string]$ServiceLevel,

    #Azure NetApp Files capacity pool size
    [Parameter(Mandatory= $false)]
    [ValidateRange(4398046511104,549755813888000)]
    [long]$NetAppPoolSize = 4398046511104,

    #Azure NetApp Files volume name
    [Parameter(Mandatory)]
    [string]$NetAppVolumeName,

    #Azure NetApp Files volume protocol type {NFSv4.1 , NFSv3}
    [Parameter(Mandatory)]
    [ValidateSet("NFSv3","NFSv4.1")]
    [string]$ProtocolType,

    #Azure NetApp Files volume size
    [Parameter(Mandatory= $false)]
    [ValidateRange(107374182400,109951162777600)]
    [long]$NetAppVolumeSize=107374182400,

    #Subnet Id 
    [Parameter(Mandatory)]
    [string]$SubnetId,

    #UnixReadOnly property
    [Parameter(Mandatory = $false)]
    [bool]$EPUnixReadOnly = $false,

    #UnixReadWrite property
    [Parameter(Mandatory = $false)]
    [bool]$EPUnixReadWrite = $true,

    #UnixReadOnly property
    [Parameter(Mandatory = $false)]
    [string]$AllowedClientsIp = "0.0.0.0/0",

    #Clean Up resources
    [Parameter(Mandatory = $false)]
    [bool]$CleanupResources = $false
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module .\Common\AzureAuth.psm1
Import-Module .\Common\Util.psm1
Import-Module .\Common\CommonSDK.psm1


# Display script header text
DisplayScriptHeader

# Authorizing and connecting to Azure
OutputMessage -Message "Authorizing with Azure Account..." -MessageType Info 
$AzureAccount = ConnectToAzure
OutputMessage -Message "Successfully authorized user with your Azure account." -MessageType Success

#Validating if the target subscription Id is set to the current or default. Otherwise Azure NetApp files will be provisioned under the wrong subscription
if($AzureAccount.Context.Subscription.Id -ne $SubscriptionId.Trim())
{
    OutputMessage -Message "Provided subscription {$SubscriptionId} is not set to current or default subscription, Switching now!" -MessageType Warning
    # Choose the right subscription
    OutputMessage -Message "Switching the current Azure subscription to {$SubscriptionId}" -MessageType Info
    $currentSub = SwitchToTargetSubscription -TargetSubscriptionId $SubscriptionId
    OutputMessage -Message "{$SubscriptionId} is set to current" -MessageType Success    
}


# Create Azure NetApp Files Account
OutputMessage -Message "Creating Azure NetApp Files Account {$NetAppAccountName}" -MessageType Info
$NewAccount = CreateNewANFAccount -TargetResourceGroupName $ResourceGroupName -Azurelocation $Location -AzNetAppAccountName $NetAppAccountName
OutputMessage -Message "Azure NetApp Files Account {$NetAppAccountName} was successfully created: $($NewAccount.Id)" -MessageType Success

# Create Azure NetApp Files Capacity Pool
OutputMessage -Message "Creating Azure NetApp Files Capacity Pool {$NetAppPoolName}" -MessageType Info
$NewPool = CreateNewANFCapacityPool -TargetResourceGroupName $ResourceGroupName `
    -Azurelocation $Location `
    -AzNetAppAccountName $NetAppAccountName `
    -AzNetAppPoolName $NetAppPoolName `
    -AzNetAppPoolSize $NetAppPoolSize `
    -ServiceLevelTier $ServiceLevel

OutputMessage -Message "Azure NetApp Files Capacity Pool {$NetAppPoolName} was successfully created: $($NewPool.Id)" -MessageType Success

#Create Azure NetApp Files NFS Volume
OutputMessage -Message "Creating Azure NetApp Files $ProtocolType Volume {$NetAppVolumeName}" -MessageType Info
$NewVolume = CreateNewANFVolume -TargetResourceGroupName $ResourceGroupName `
    -Azurelocation $Location `
    -AzNetAppAccountName $NetAppAccountName `
    -AzNetAppPoolName $NetAppPoolName `
    -AzNetAppPoolSize $NetAppPoolSize `
    -AzNetAppVolumeName $NetAppVolumeName `
    -AzNetAppVolumeSize $NetAppVolumeSize `
    -VolumeProtocolType $ProtocolType `
    -ServiceLevelTier $ServiceLevel `
    -VNETSubnetId $SubnetId `
    -EPUnixReadOnly $EPUnixReadOnly `
    -EPunixReadWrite $EPUnixReadWrite `
    -AllowedClientIP $AllowedClientsIp

OutputMessage -Message "Azure NetApp Files Volume {$NetAppVolumeName} was successfully created: $($NewVolume.Id)" -MessageType Success

OutputMessage -Message "Azure NetApp Files has been created successfully." -MessageType Success

if($CleanupResources)
{
    DisplayCleanupHeader
    OutputMessage -Message "Cleaning up Azure NetApp Files resources..." -MessageType Info
    CleanUpResources -TargetResourceGroupName $ResourceGroupName `
        -AzNetAppAccountName $NetAppAccountName `
        -AzNetAppPoolName $NetAppPoolName `
        -AzNetAppVolumeName $NetAppVolumeName

    OutputMessage -Message "All Azure NetApp Files resources have been deleted successfully." -MessageType Success        
}