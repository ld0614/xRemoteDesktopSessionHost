function Test-xRemoteDesktopSessionHostOsRequirement
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param
    ()
    return (Get-OsVersion) -ge [Version]::new(6,2,9200,0)
}

function Get-OsVersion
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    ()
    return [Environment]::OSVersion.Version 
}

Function Import-RDModule
{
    [CmdletBinding()]
    [OutputType([Void])]
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
    [CmdletBinding()]
    [OutputType([String])]
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
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [parameter()]
        [String]
        $ConnectionBroker
    )
    $localhost = Get-Localhost
    if (-not $ConnectionBroker)
    {
        #If not specified use the localhost as the connection Broker
        $ConnectionBroker = $localhost
    } 

    $ConnectionBroker = Get-ActiveConnectionBroker -ConnectionBroker $ConnectionBroker

    return $ConnectionBroker
}

Function Get-Localhost
{
    [CmdletBinding()]
    [OutputType([String])]
    Param
    ()

    return [System.Net.Dns]::GetHostByName((hostname)).HostName
}

Export-ModuleMember -Function @(
    'Test-xRemoteDesktopSessionHostOsRequirement',
    'Get-Localhost',
    'Get-ConnectionBroker',
    'Import-RDModule'
)
