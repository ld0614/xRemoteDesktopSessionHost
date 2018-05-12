function Test-xRemoteDesktopSessionHostOsRequirement
{
    return (Get-OsVersion) -ge (new-object 'Version' 6,2,9200,0)
}

function Get-OsVersion
{
    return [Environment]::OSVersion.Version 
}

Function Import-RDModule
{
    $Module = Get-Module -ListAvailable RemoteDesktop
    if ($null -eq $Module)
    {
        Throw "Unable to locate the RemoteDesktop Module"
    }
    else
    {
        Import-Module RemoteDesktop
    }

    $RDServerCommand = Get-Command Get-RDServer

    if ($null -eq $RDServerCommand)
    {
        Get-Module
        Get-Command -Module RemoteDesktop
        Throw "RemoteDesktop Module did not load correctly"
    }
    else
    {
        Write-Verbose "Found Command: $($RDServerCommand.Name)"
    }
}

function Get-ActiveConnectionBroker
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $ConnectionBroker
    )
    Import-RDModule

    $CurrentHAConfig = Get-RDConnectionBrokerHighAvailability -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue
    if ($null -eq $CurrentHAConfig)
    {
        #Connection Broker HA is not configured
        $CurrentConnectionBroker = $ConnectionBroker
    }
    else
    {
        $CurrentConnectionBroker = $CurrentHAConfig.ActiveManagementServer
    }

    return $CurrentConnectionBroker
}

Function Get-ConnectionBroker
{
    Param
    (
        [parameter()]
        [String]
        $ConnectionBroker
    )
    $localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName
    if (-not $ConnectionBroker)  { $ConnectionBroker =  $localhost } #If not specified use the localhost as the connection Broker

    $ConnectionBroker = Get-ActiveConnectionBroker -ConnectionBroker $ConnectionBroker

    return $ConnectionBroker
}

Export-ModuleMember -Function @(
    'Test-xRemoteDesktopSessionHostOsRequirement',
    'Get-ConnectionBroker',
    'Import-RDModule'
)
