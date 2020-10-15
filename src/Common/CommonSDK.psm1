Import-Module .\Common\Util.psm1

<#
.SYNOPSIS
    Clean-up Azure NetApp Files Resources
.DESCRIPTION
    This method will clean up all created Azure Netapp Files resources if the argument -CleanupResources is set to $true 
.INPUTS
    $ResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    $NetAppAccountName: Name of the Azure NetApp Files Account
    $NetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    $NetAppVolumeName: Name of the Azure NetApp Files Volume 
#>
function CleanUpResources{
param(
[string]$resourceGroupName,  
[string]$netAppAccountName,
[string]$netAppPoolName, 
[string]$netAppVolumeName
)
    #Deleting ANF volume
    OutputMessage -Message "Deleting Azure NetApp Files Volume {$netAppVolumeName}..." -MessageType Info
    try{
        Remove-AzNetAppFilesVolume -ResourceGroupName $resourceGroupName -AccountName $netAppAccountName -PoolName $netAppPoolName -Name $netAppVolumeName
        OutputMessage -Message "$netAppVolumeName has been deleted successfully" -MessageType Success
    }
    catch{
        OutputMessage -Message "Failed to delete Volume!" -MessageType Error
    }   
      

    #Deleting ANF Capacity pool
    OutputMessage -Message "Deleting Azure NetApp Files Capacity Pool {$netAppPoolName}..." -MessageType Info
    try{
        Remove-AzNetAppFilesPool -ResourceGroupName $resourceGroupName -AccountName $netAppAccountName -PoolName $netAppPoolName
        OutputMessage -Message "$netAppPoolName has been deleted successfully" -MessageType Success
    }
    catch{
        OutputMessage -Message "Failed to delete Capacity Pool!" -MessageType Error
    }
  

    #Deleting ANF Account
    OutputMessage -Message "Deleting Azure NetApp Files Account {$netAppAccountName}..." -MessageType Info
    try{
        Remove-AzNetAppFilesAccount -ResourceGroupName $resourceGroupName -Name $netAppAccountName
        OutputMessage -Message "$netAppAccountName has been deleted successfully" -MessageType Success
    }
    catch{
        OutputMessage -Message "Failed to delete Account!" -MessageType Error
    }    
}


<#
.SYNOPSIS
    Creates new Azure NetApp Files account
.DESCRIPTION
    This method will create new Azure NetApp Files account under the specified Resource Group
.EXAMPLE
    CreateNewANFAccount - resourceGroupName [Resource Group Name] -location [Azure Location] -netAppAccountName [NetApp Account Name]
.INPUTS
    $ResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    $Location: Azure Location
    $NetAppAccountName: Name of the Azure NetApp Files Account
.OUTPUT
    ANF account object
#>
function CreateNewANFAccount{
param(
[string]$resourceGroupName, 
[string]$location, 
[string]$netAppAccountName
)

 $newANFAccount = New-AzNetAppFilesAccount -ResourceGroupName $resourceGroupName -Location $location -Name $netAppAccountName
 
 if($newANFAccount.ProvisioningState -ne "Succeeded") {
    OutputMessage -Message "Failed to provision ANF Account {$netAppAccountName}" -MessageType Error
 }

 return $newANFAccount
}

<#
.SYNOPSIS
    Creates new Azure NetApp Files capacity pool
.DESCRIPTION
    This method will create new Azure NetApp Files capacity pool within the specified account
.EXAMPLE
    CreateNewANFCapacityPool - resourceGroupName [Resource Group Name] -location [Azure Location] -netAppAccountName [NetApp Account Name] -netAppPoolName [NetApp Pool Name] -netAppPoolSize [Size of the Capacity Pool] -serviceLevel [service level (Ultra, Premium or Standard)]
.INPUTS   
    $ResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    $Location: Azure Location
    $NetAppAccountName: Name of the Azure NetApp Files Account
    $NetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    $ServiceLevel: Ultra, Premium or Standard
    $NetAppPoolSize: Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
.OUTPUT
    ANF Capacity Pool object
#>
function CreateNewANFCapacityPool{
param(
[string]$resourceGroupName, 
[string]$location, 
[string]$netAppAccountName,
[string]$netAppPoolName, 
[long]$netAppPoolSize, 
[string]$serviceLevel)

    $newANFPool= New-AzNetAppFilesPool -ResourceGroupName $resourceGroupName -Location $location -AccountName $netAppAccountName -Name $netAppPoolName -PoolSize $netAppPoolSize -ServiceLevel $serviceLevel
    if($newANFPool.ProvisioningState -ne "Succeeded")
    {
       OutputMessage -Message "Failed to provision ANF Capacity Pool {$netAppPoolName}" -MessageType Error
    }
    return $newANFPool
}


<#
.SYNOPSIS
    Creates new Azure NetApp Files NFS volume
.DESCRIPTION
    This method will create new Azure NetApp Files volume under the specified Capacity Pool
.EXAMPLE
    CreateNewANFVolume - resourceGroupName [Resource Group Name] -location [Azure Location] -netAppAccountName [NetApp Account Name] -netAppPoolName [NetApp Pool Name] -netAppPoolSize [Size of the Capacity Pool] -serviceLevel [service level (Ultra, Premium or Standard)] -netAppVolumeName [NetApp Volume Name] -netAppVolumeSize [Size of the Volume] -protocolType [NFSv3 or NFSv4.1] -subnetId [Subnet ID] -unixReadOnly [Read Permission flag] -unixReadWrite [Read/Write permission flag] -allowedClients [Allowed clients IP]
.INPUTS
    $ResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    $Location: Azure Location
    $NetAppAccountName: Name of the Azure NetApp Files Account
    $NetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    $ServiceLevel: Ultra, Premium or Standard
    $NetAppPoolSize: Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
    $NetAppVolumeName: Name of the Azure NetApp Files Volume
    $ProtocolType: NFSv4.1 or NFSv3
    $NetAppVolumeSize: Size of the Azure NetApp Files volume in Bytes. Range between 107374182400 and 109951162777600
    $SubnetId: The Delegated subnet Id within the VNET
    $EPUnixReadOnly: Export Policy UnixReadOnly property 
    $EPUnixReadWrite: Export Policy UnixReadWrite property
    $AllowedClientsIp: Client IP to access Azure NetApp files volume
#>
function CreateNewANFVolume{
param(
[string]$resourceGroupName, 
[string]$location, 
[string]$netAppAccountName,
[string]$netAppPoolName, 
[long]$netAppPoolSize, 
[string]$netAppVolumeName,
[long]$netAppVolumeSize,
[string]$protocolType,
[string]$serviceLevel, 
[string]$subnetId,
[bool]$unixReadOnly,
[bool]$unixReadWrite,
[string]$allowedClient
)

    [bool]$nfsv3 = $False
    [bool]$nfsv4 = $False
    if($protocolType -eq "NFSv3"){
    $nfsv3 = $True
    }
    else
    {
    $nfsv4 = $True
    }
      
    $exportPolicy = [Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesExportPolicyRule]::new()
    $exportPolicy.RuleIndex =1
    $exportPolicy.UnixReadOnly =$unixReadOnly
    $exportPolicy.UnixReadWrite =$unixReadWrite
    $exportPolicy.Cifs = $False
    $exportPolicy.Nfsv3 = $nfsv3
    $exportPolicy.Nfsv41 = $nfsv4
    $exportPolicy.AllowedClients =$allowedClient

    $volumeExportPolicy = New-Object -TypeName Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesVolumeExportPolicy -Property @{Rules = $exportPolicy}
    
    $newANFVolume = New-AzNetAppFilesVolume -ResourceGroupName $resourceGroupName -Location $location -AccountName $netAppAccountName -PoolName $netAppPoolName -Name $netAppVolumeName -UsageThreshold $netAppVolumeSize -SubnetId $subnetId -CreationToken $netAppVolumeName -ServiceLevel $serviceLevel -ProtocolType $protocolType -ExportPolicy $volumeExportPolicy
    if($newANFVolume.ProvisioningState -ne "Succeeded")
    {
       OutputMessage -Message "Failed to provision ANF Volume {$netAppPoolName}" -MessageType Error
    }
    
    return $newANFVolume
}
