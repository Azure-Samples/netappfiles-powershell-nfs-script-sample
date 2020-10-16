<#
.SYNOPSIS
    This script creates Azure Netapp files resources with NFS volume type
.DESCRIPTION
    The script Authenticate with Azure and select the targeted subscription first, then created ANF account, capacity pool and NFS Volume
.EXAMPLE
    PS C:\\> CreateANFVolume.ps1 -SubscriptionId '[Target Subscription Id]' -ResourceGroupName '[Azure Resource Group Name]' -Location '[Azure Location]' -NetAppAccountName '[ANF Account Name]' -NetAppPoolName '[ANF Capacity Pool Name]' -ServiceLevel [Ultra,Premium, Standard] -NetAppVolumeName '[ANF Volume Name]' -ProtocolType [NFSv3,NFSv4.1] -SubnetId '[Subnet ID]'
.INPUTS
    SubscriptionId: Target Subscription
    ResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    Location: Azure Location
    NetAppAccountName: Name of the Azure NetApp Files Account
    NetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    ServiceLevel: Ultra, Premium or Standard
    NetAppPoolSize: Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
    NetAppVolumeName: Name of the Azure NetApp Files Volume
    ProtocolType: NFSv4.1 or NFSv3
    NetAppVolumeSize: Size of the Azure NetApp Files volume in Bytes. Range between 107374182400 and 109951162777600
    SubnetId: The Delegated subnet Id within the VNET
    EPUnixReadOnly: Export Policy UnixReadOnly property 
    EPUnixReadWrite: Export Policy UnixReadWrite property
    AllowedClientsIp: Client IP to access Azure NetApp files volume
    CleanupResources: If script should clean up the resources, $false by default
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
$SelectedSubId = $AzureAccount.Context.Subscription.Id
if($SelectedSubId -ne $SubscriptionId.Trim())
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
$NewAccountId = $NewAccount.Id
OutputMessage -Message "Azure NetApp Files Account {$NetAppAccountName} was successfully created: {$NewAccountId}" -MessageType Success

# Create Azure NetApp Files Capacity Pool
OutputMessage -Message "Creating Azure NetApp Files Capacity Pool {$NetAppPoolName}" -MessageType Info
$NewPool = CreateNewANFCapacityPool -TargetResourceGroupName $ResourceGroupName -Azurelocation $Location -AzNetAppAccountName $NetAppAccountName -AzNetAppPoolName $NetAppPoolName -AzNetAppPoolSize $NetAppPoolSize -ServiceLevelTier $ServiceLevel
$NewPoolId= $newPool.Id
OutputMessage -Message "Azure NetApp Files Capacity Pool {$NetAppPoolName} was successfully created: {$NewPoolId}" -MessageType Success

#Create Azure NetApp Files NFS Volume
OutputMessage -Message "Creating Azure NetApp Files $ProtocolType Volume {$NetAppVolumeName}" -MessageType Info
$NewVolume = CreateNewANFVolume -TargetResourceGroupName $ResourceGroupName -Azurelocation $Location -AzNetAppAccountName $NetAppAccountName -AzNetAppPoolName $NetAppPoolName -AzNetAppPoolSize $NetAppPoolSize -AzNetAppVolumeName $NetAppVolumeName -AzNetAppVolumeSize $NetAppVolumeSize -VolumeProtocolType $ProtocolType -ServiceLevelTier $ServiceLevel -VNETSubnetId $SubnetId -EPUnixReadOnly $EPUnixReadOnly -EPunixReadWrite $EPUnixReadWrite -AllowedClientIP $AllowedClientsIp
$NewVolumeId = $NewVolume.Id
OutputMessage -Message "Azure NetApp Files Volume {$NetAppVolumeName} was successfully created: {$NewVolumeId}" -MessageType Success

OutputMessage -Message "Azure NetApp Files has been created successfully." -MessageType Success

if($CleanupResources)
{
    DisplayCleanupHeader
    OutputMessage -Message "Cleaning up Azure NetApp Files resources..." -MessageType Info
    CleanUpResources -TargetResourceGroupName $ResourceGroupName -AzNetAppAccountName $NetAppAccountName -AzNetAppPoolName $NetAppPoolName -AzNetAppVolumeName $NetAppVolumeName
    OutputMessage -Message "All Azure NetApp Files resources have been deleted successfully." -MessageType Success        
}