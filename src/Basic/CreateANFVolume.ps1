<#
.SYNOPSIS
    This script creates Azure Netapp files resources with NFS volume type
.DESCRIPTION
    The script Authenticate with Azure and select the targeted subscription first, then created ANF account, capacity pool and NFS Volume
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
    [string]$ResourceGroupName = 'adghabboPrim-rg',

    #Azure location 
    [string]$Location ='WestUS',

    #Azure NetApp Files account name
    [string]$NetAppAccountName = 'anfaccount',

    #Azure NetApp Files capacity pool name
    [string]$NetAppPoolName = 'pool1' ,

    # Service Level can be {Ultra, Premium or Standard}
    [ValidateSet("Ultra","Premium","Standard")]
    [string]$ServiceLevel = 'Standard',

    #Azure NetApp Files capacity pool size
    [ValidateRange(4398046511104,549755813888000)]
    [long]$NetAppPoolSize = 4398046511104,

    #Azure NetApp Files volume name
    [string]$NetAppVolumeName = 'vol1',

    #Azure NetApp Files volume protocol type {NFSv4.1 , NFSv3}
    [ValidateSet("NFSv3","NFSv4.1")]
    [string]$ProtocolType = 'NFSv4.1',

    #Azure NetApp Files volume size
    [ValidateRange(107374182400,109951162777600)]
    [long]$NetAppVolumeSize = 107374182400,

    #Subnet Id 
    [string]$SubnetId = '/subscriptions/f557b96d-2308-4a18-aae1-b8f7e7e70cc7/resourceGroups/adghabboPrim-rg/providers/Microsoft.Network/virtualNetworks/adghabboPrim-rg-vnet/subnets/primsubnet',

    #UnixReadOnly property
    [bool]$EPUnixReadOnly = $false,

    #UnixReadWrite property
    [bool]$EPUnixReadWrite = $true,

    #UnixReadOnly property
    [string]$AllowedClientsIp = "0.0.0.0/0",

    #Clean Up resources
    [bool]$CleanupResources = $true
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Authorizing and connecting to Azure
Write-Verbose -Message "Authorizing with Azure Account..." -Verbose
Add-AzAccount

# Create Azure NetApp Files Account
Write-Verbose -Message "Creating Azure NetApp Files Account" -Verbose
$NewAccount = New-AzNetAppFilesAccount -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -Name $NetAppAccountName `
    -ErrorAction Stop
Write-Verbose -Message "Azure NetApp Account has been created successfully: $($NewAccount.Id)" -Verbose


# Create Azure NetApp Files Capacity Pool
Write-Verbose -Message "Creating Azure NetApp Files Capacity Pool" -Verbose
$NewPool = New-AzNetAppFilesPool -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AccountName $NetAppAccountName `
    -Name $NetAppPoolName `
    -PoolSize $NetAppPoolSize `
    -ServiceLevel $ServiceLevel `
    -ErrorAction Stop
Write-Verbose -Message "Azure NetApp Capacity Pool has been created successfully: $($NewPool.Id)" -Verbose


#Create Azure NetApp Files NFS Volume
Write-Verbose -Message "Creating Azure NetApp Files Volume" -Verbose

[bool]$NFSv3Protocol = $False
[bool]$NFSv4Protocol = $False

if($ProtocolType -eq "NFSv3")
{
    $NFSv3Protocol = $True
}
else
{
    $NFSv4Protocol = $True
}

$ExportPolicyRule = New-Object -TypeName Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesExportPolicyRule
    $ExportPolicyRule.RuleIndex =1
    $ExportPolicyRule.UnixReadOnly =$EPUnixReadOnly
    $ExportPolicyRule.UnixReadWrite =$EPUnixReadWrite
    $ExportPolicyRule.Cifs = $False
    $ExportPolicyRule.Nfsv3 = $NFSv3Protocol
    $ExportPolicyRule.Nfsv41 = $NFSv4Protocol
    $ExportPolicyRule.AllowedClients =$AllowedClientsIp

$ExportPolicy = New-Object -TypeName Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesVolumeExportPolicy -Property @{Rules = $ExportPolicyRule}

$NewVolume = New-AzNetAppFilesVolume -ResourceGroupName $ResourceGroupName `
    -Location $Location `
    -AccountName $NetAppAccountName `
    -PoolName $NetAppPoolName `
    -Name $NetAppVolumeName `
    -UsageThreshold $NetAppVolumeSize `
    -ProtocolType $ProtocolType `
    -ServiceLevel $ServiceLevel `
    -SubnetId $SubnetId `
    -CreationToken $NetAppVolumeName `
    -ExportPolicy $ExportPolicy `
    -ErrorAction Stop

Write-Verbose -Message "Azure NetApp Files has been created successfully." -Verbose

if($CleanupResources)
{
    
    Write-Verbose -Message "Cleaning up Azure NetApp Files resources..." -Verbose

    #Deleting NetApp Files Volume
    Write-Verbose -Message "Deleting Azure NetApp Files Volume: $NetAppVolumeName" -Verbose
    Remove-AzNetAppFilesVolume -ResourceGroupName $ResourceGroupName `
            -AccountName $NetAppAccountName `
            -PoolName $NetAppPoolName `
            -Name $NetAppVolumeName `
            -ErrorAction Stop

    #Deleting NetApp Files Pool
    Write-Verbose -Message "Deleting Azure NetApp Files pool: $NetAppPoolName" -Verbose
    Remove-AzNetAppFilesPool -ResourceGroupName $ResourceGroupName `
        -AccountName $NetAppAccountName `
        -PoolName $NetAppPoolName `
        -ErrorAction Stop

    #Deleting NetApp Files account
    Write-Verbose -Message "Deleting Azure NetApp Files Volume: $NetAppVolumeName" -Verbose
    Remove-AzNetAppFilesAccount -ResourceGroupName $ResourceGroupName -Name $NetAppAccountName -ErrorAction Stop

    Write-Verbose -Message "All Azure NetApp Files resources have been deleted successfully." -Verbose    
}