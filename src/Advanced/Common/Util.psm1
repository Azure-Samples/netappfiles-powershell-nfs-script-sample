function DisplayScriptHeader
{
    <#
    .SYNOPSIS
        Display script header text
    #>
    OutputMessage -Message "-----------------------------------------------------------------------------------------------------------------------------------" -MessageType Info
    OutputMessage -Message "Azure NetAppFiles PowerShell NFS SDK Sample - Sample project that creates Azure NetApp Files Volume uses NFSv3 or NFSv4.1 protocol|" -MessageType Info
    OutputMessage -Message "-----------------------------------------------------------------------------------------------------------------------------------" -MessageType Info
}


function DisplayCleanupHeader
{
    <#
    .SYNOPSIS
        Display Clean up text
    #>
    OutputMessage -Message "-----------------------------------------" -MessageType Info
    OutputMessage -Message "Cleaning up Azure NetApp Files resources|" -MessageType Info
    OutputMessage -Message "-----------------------------------------" -MessageType Info
}


function OutputMessage
{
    <#
    .SYNOPSIS
        Output message with the corresponding message type and color
    .DESCRIPTION
        This methods output messages based on the type {Info, Error, Warning, Success} with the corresponding color
    .PARAMETER Message
        Message Text
    .PARAMETER MessageType 
        Message Type: Info, Success, Warning or Error
    .EXAMPLE
        OutputMessage -Message "Example Message" -MessageType Info
    #>
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