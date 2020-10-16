Import-Module .\Common\Util.psm1

<#
.SYNOPSIS
    Clean-up Azure NetApp Files Resources
.DESCRIPTION
    This method will clean up all created Azure Netapp Files resources if the argument -CleanupResources is set to $true 
.INPUTS
    TargetResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    AzNetAppAccountName: Name of the Azure NetApp Files Account
    AzNetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    AzNetAppVolumeName: Name of the Azure NetApp Files Volume 
#>
function CleanUpResources
{
    param
    (
        [string]$TargetResourceGroupName,  
        [string]$AzNetAppAccountName,
        [string]$AzNetAppPoolName, 
        [string]$AzNetAppVolumeName
    )

    #Deleting ANF volume
    OutputMessage -Message "Deleting Azure NetApp Files Volume {$AzNetAppVolumeName}..." -MessageType Info
    try
    {
        Remove-AzNetAppFilesVolume -ResourceGroupName $TargetResourceGroupName -AccountName $AzNetAppAccountName -PoolName $AzNetAppPoolName -Name $AzNetAppVolumeName
        #Validating if the volume is completely deleted
        $DeletedVolume = Get-AzNetAppFilesVolume -ResourceGroupName $TargetResourceGroupName -AccountName $AzNetAppAccountName -PoolName $AzNetAppPoolName -Name $AzNetAppVolumeName -ErrorAction SilentlyContinue
        if($null -eq $DeletedVolume)
        {
            OutputMessage -Message "$AzNetAppVolumeName has been deleted successfully" -MessageType Success
        }
        else
        {
            OutputMessage -Message "Wasn't able to fully delete {$AzNetAppVolumeName}" -MessageType Error            
        }
    }
    catch
    {
        OutputMessage -Message "Failed to delete Volume!" -MessageType Error
    }   
      
    #Deleting ANF Capacity pool
    OutputMessage -Message "Deleting Azure NetApp Files Capacity Pool {$AzNetAppPoolName}..." -MessageType Info
    try
    {
        Remove-AzNetAppFilesPool -ResourceGroupName $TargetResourceGroupName -AccountName $AzNetAppAccountName -PoolName $AzNetAppPoolName
        #Validating if the pool is completely deleted
        $DeletedPool = Get-AzNetAppFilesPool -ResourceGroupName $TargetResourceGroupName -AccountName $AzNetAppAccountName -PoolName $AzNetAppPoolName -ErrorAction SilentlyContinue
        if($null -eq $DeletedPool)
        {
            OutputMessage -Message "$AzNetAppPoolName has been deleted successfully" -MessageType Success
        }
        else
        {
            OutputMessage -Message "Wasn't able to fully delete {$AzNetAppPoolName}" -MessageType Error            
        }       
    }
    catch
    {
        OutputMessage -Message "Failed to delete Capacity Pool!" -MessageType Error
    }
  
    #Deleting ANF Account
    OutputMessage -Message "Deleting Azure NetApp Files Account {$AzNetAppAccountName}..." -MessageType Info
    try
    {
        Remove-AzNetAppFilesAccount -ResourceGroupName $TargetResourceGroupName -Name $AzNetAppAccountName
        #Validating if the account is completely deleted
        $DeletedAccount = Get-AzNetAppFilesAccount -ResourceGroupName $TargetResourceGroupName -AccountName $AzNetAppAccountName -ErrorAction SilentlyContinue
        if($null -eq $DeletedAccount)
        {
            OutputMessage -Message "$AzNetAppAccountName has been deleted successfully" -MessageType Success
        }
        else
        {
            OutputMessage -Message "Wasn't able to fully delete {$AzNetAppAccountName}" -MessageType Error            
        }        
    }
    catch
    {
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
    TargetResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    AzureLocation: Azure Location
    AzNetAppAccountName: Name of the Azure NetApp Files Account
.OUTPUT
    ANF account object
#>
function CreateNewANFAccount
{    
    param
    (
        [string]$TargetResourceGroupName, 
        [string]$Azurelocation, 
        [string]$AzNetAppAccountName
    )

    try
    {
        $NewANFAccount = New-AzNetAppFilesAccount -ResourceGroupName $TargetResourceGroupName -Location $Azurelocation -Name $AzNetAppAccountName
    
        if($NewANFAccount.ProvisioningState -ne "Succeeded") 
        {
            OutputMessage -Message "Failed to create ANF Account {$AzNetAppAccountName}" -MessageType Error
        }
    }
    catch
    {
        OutputMessage -Message "Failed to create ANF Account" -MessageType Error
    }
    return $NewANFAccount
}

<#
.SYNOPSIS
    Creates new Azure NetApp Files capacity pool
.DESCRIPTION
    This method will create new Azure NetApp Files capacity pool within the specified account
.EXAMPLE
    CreateNewANFCapacityPool - resourceGroupName [Resource Group Name] -location [Azure Location] -netAppAccountName [NetApp Account Name] -netAppPoolName [NetApp Pool Name] -netAppPoolSize [Size of the Capacity Pool] -serviceLevel [service level (Ultra, Premium or Standard)]
.INPUTS   
    TargetResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    AzureLocation: Azure Location
    AzNetAppAccountName: Name of the Azure NetApp Files Account
    AzNetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    AzServiceLevel: Ultra, Premium or Standard
    AzNetAppPoolSize: Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
.OUTPUT
    ANF Capacity Pool object
#>
function CreateNewANFCapacityPool
{
    param
    (
        [string]$TargetResourceGroupName, 
        [string]$Azurelocation, 
        [string]$AzNetAppAccountName,
        [string]$AzNetAppPoolName, 
        [long]$AzNetAppPoolSize, 
        [string]$ServiceLevelTier
    )

    try
    {
        $NewANFPool= New-AzNetAppFilesPool -ResourceGroupName $TargetResourceGroupName -Location $Azurelocation -AccountName $AzNetAppAccountName -Name $AzNetAppPoolName -PoolSize $AzNetAppPoolSize -ServiceLevel $ServiceLevelTier

        if($NewANFPool.ProvisioningState -ne "Succeeded")
        {
           OutputMessage -Message "Failed to create ANF Capacity Pool {$AzNetAppPoolName}" -MessageType Error
        }
    }
    catch
    {
        OutputMessage -Message "Failed to create ANF Capacity Pool." -MessageType Error
    }

    return $NewANFPool
}


<#
.SYNOPSIS
    Creates new Azure NetApp Files NFS volume
.DESCRIPTION
    This method will create new Azure NetApp Files volume under the specified Capacity Pool
.EXAMPLE
    CreateNewANFVolume - resourceGroupName [Resource Group Name] -location [Azure Location] -netAppAccountName [NetApp Account Name] -netAppPoolName [NetApp Pool Name] -netAppPoolSize [Size of the Capacity Pool] -serviceLevel [service level (Ultra, Premium or Standard)] -netAppVolumeName [NetApp Volume Name] -netAppVolumeSize [Size of the Volume] -protocolType [NFSv3 or NFSv4.1] -subnetId [Subnet ID] -unixReadOnly [Read Permission flag] -unixReadWrite [Read/Write permission flag] -allowedClients [Allowed clients IP]
.INPUTS
    TargetResourceGroupName: Name of the Azure Resource Group where the ANF will be created
    AzureLocation: Azure Location
    AzNetAppAccountName: Name of the Azure NetApp Files Account
    AzNetAppPoolName: Name of the Azure NetApp Files Capacity Pool
    ServiceLevelTier: Ultra, Premium or Standard
    AzNetAppPoolSize: Size of the Azure NetApp Files Capacity Pool in Bytes. Range between 4398046511104 and 549755813888000
    AzNetAppVolumeName: Name of the Azure NetApp Files Volume
    VolumeProtocolType: NFSv4.1 or NFSv3
    AzNetAppVolumeSize: Size of the Azure NetApp Files volume in Bytes. Range between 107374182400 and 109951162777600
    VNETSubnetId: The Delegated subnet Id within the VNET
    EPUnixReadOnly: Export Policy UnixReadOnly property 
    EPUnixReadWrite: Export Policy UnixReadWrite property
    AllowedClientsIp: Client IP to access Azure NetApp files volume
#>
function CreateNewANFVolume
{
    param
    (
        [string]$TargetResourceGroupName, 
        [string]$AzureLocation, 
        [string]$AzNetAppAccountName,
        [string]$AzNetAppPoolName, 
        [long]$AzNetAppPoolSize, 
        [string]$AzNetAppVolumeName,
        [long]$AzNetAppVolumeSize,
        [string]$VolumeProtocolType,
        [string]$ServiceLevelTier, 
        [string]$VNETSubnetId,
        [bool]$EPUnixReadOnly,
        [bool]$EPunixReadWrite,
        [string]$AllowedClientIP
    )

    [bool]$NFSv3Protocol = $False
    [bool]$NFSv4Protocol = $False

    if($VolumeProtocolType -eq "NFSv3")
    {
        $NFSv3Protocol = $True
    }
    else
    {
        $NFSv4Protocol = $True
    }
      
    $ExportPolicy = [Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesExportPolicyRule]::new()
    $ExportPolicy.RuleIndex =1
    $ExportPolicy.UnixReadOnly =$EPUnixReadOnly
    $ExportPolicy.UnixReadWrite =$EPunixReadWrite
    $ExportPolicy.Cifs = $False
    $ExportPolicy.Nfsv3 = $NFSv3Protocol
    $ExportPolicy.Nfsv41 = $NFSv4Protocol
    $ExportPolicy.AllowedClients =$AllowedClientIP

    $VolumeExportPolicy = New-Object -TypeName Microsoft.Azure.Commands.NetAppFiles.Models.PSNetAppFilesVolumeExportPolicy -Property @{Rules = $ExportPolicy}
    
    try
    {
        $NewANFVolume = New-AzNetAppFilesVolume -ResourceGroupName $TargetResourceGroupName -Location $AzureLocation -AccountName $AzNetAppAccountName -PoolName $AzNetAppPoolName -Name $AzNetAppVolumeName -UsageThreshold $AzNetAppVolumeSize -SubnetId $VNETSubnetId -CreationToken $AzNetAppVolumeName -ServiceLevel $ServiceLevelTier -ProtocolType $VolumeProtocolType -ExportPolicy $VolumeExportPolicy
        if($NewANFVolume.ProvisioningState -ne "Succeeded")
        {
           OutputMessage -Message "Failed to create ANF Volume {$netAppPoolName}" -MessageType Error
        }
    }
    catch
    {
        OutputMessage -Message "Failed to create ANF Volume" -MessageType Error
    }
    
    return $NewANFVolume
}
