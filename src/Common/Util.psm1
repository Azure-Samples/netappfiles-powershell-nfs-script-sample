<#
.SYNOPSIS
    Display script header text
#>
function DisplayScriptHeader
{
    OutputMessage -Message "-----------------------------------------------------------------------------------------------------------------------------------" -MessageType Info
    OutputMessage -Message "Azure NetAppFiles PowerShell NFS SDK Sample - Sample project that creates Azure NetApp Files Volume uses NFSv3 or NFSv4.1 protocol|" -MessageType Info
    OutputMessage -Message "-----------------------------------------------------------------------------------------------------------------------------------" -MessageType Info
}

<#
.SYNOPSIS
    Display Clean up text
#>
function DisplayCleanupHeader
{
    OutputMessage -Message "-----------------------------------------" -MessageType Info
    OutputMessage -Message "Cleaning up Azure NetApp Files resources|" -MessageType Info
    OutputMessage -Message "-----------------------------------------" -MessageType Info
}

<#
.SYNOPSIS
    Output message with the corresponding message type and color
.DESCRIPTION
    This methods output messages based on the type {Info, Error, Warning, Success} with the corresponding color
.EXAMPLE
    OutputMessage -Message "Example Message" -MessageType Info
.INPUTS
    $Message = Message Text
    $MessageType = Message Type: Info, Success, Warning or Error
#>
function OutputMessage
{
    param
    (
        [string]$Message,
        [ValidateSet("Info","Success","Warning","Error")]
        [string]$MessageType
    )

    $datetime = Get-Date -Format T
    [string]$showMessage = $datetime +": "+ $message
    switch($MessageType)
    {
        Info {Write-Host -Object $showMessage -ForegroundColor White }
        Success {Write-Host -Object $showMessage -ForegroundColor Green }
        Warning {Write-Host -Object $showMessage -ForegroundColor Yellow }
        Error {Write-Error -Message $showMessage -ErrorAction Stop}
    }
}