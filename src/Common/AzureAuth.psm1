Import-Module .\Common\Util.psm1

<#
.SYNOPSIS
    Connect and authenticate with Azure Account
.DESCRIPTION
    A login dialog will pop up to authenticate with Azure
.EXAMPLE
    $accountObj = ConnectToAzure
.OUTPUTS
    Returns Azure account object
#>
function ConnectToAzure
{
    try
    {
        $accountObject = Add-AzAccount
    }
    catch
    {
        OutputMessage -Message "Failed to connect to Azure. please try again!" -MessageType Error
    }
    return $accountObject
}

<#
.SYNOPSIS
    Selects an Azure subscription
.DESCRIPTION
    A helper method to switch to the targeted subscription
.EXAMPLE
    $currentSub = SwitchToTargetSubscription
.OUTPUTS
    Returns Azure subscription object
#>
function SwitchToTargetSubscription
{
    param
    (
        [string]$TargetSubscriptionId
    )

    #try to switch to the correct target subscription
    try
    {
        $currentSubscription = Select-AzSubscription -Subscription $SubscriptionId
    }
    catch
    {
        OutputMessage -Message "Invalid subsciption. Provide a valid subscription ID and try again!"
    }

    return $currentSubscription
}