Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (    
        [Parameter(Mandatory = $true)]
        [string]
        $ConnectionBroker,

        [Parameter()]
        [string]
        $WebAccessServer,

        [Parameter()]
        [string[]] 
        $SessionHosts
    )

    #Must be manually loaded in every Function otherwise unexpected behavior occurs with missing commands
    Import-RDModule

    $result = $null

    # Start service RDMS is needed because otherwise a reboot loop could happen due to
    # the RDMS Service being on Delay-Start by default, and DSC kicks in too quickly after a reboot.
    Start-Service -Name RDMS -ErrorAction SilentlyContinue

    #In a HA deployment the correct connection broker is required
    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    
    Write-Verbose "Getting list of RD Server roles from '$ConnectionBroker'..."    

    $servers = Get-RDServer -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue


    if ($servers)
    {
        Write-Verbose "Found deployment consisting of $($servers.Count) servers:"
        Write-Debug ( $servers | out-string )

        $result = @{
            "SessionHosts" = $servers | Where-Object Roles -contains 'RDS-RD-SERVER' | ForEach-Object Server;
            "ConnectionBroker" = $servers | Where-Object Roles -contains 'RDS-CONNECTION-BROKER' | ForEach-Object Server;
            "WebAccessServer" = $servers | Where-Object Roles -contains 'RDS-WEB-ACCESS' | ForEach-Object Server;
            "LicenseServers" = $servers | Where-Object Roles -contains 'RDS-LICENSING' | ForEach-Object Server;
        }


        Write-Verbose ">> RD Connection Broker:     $($result.ConnectionBroker.ToLower())"
        
        if ($result.WebAccessServer)
        {
            Write-Verbose ">> RD Web Access server:     $($result.WebAccessServer.ToLower())"
        }
        
        Write-Verbose ">> RD Session Host servers:  $($result.SessionHosts.ToLower() -join '; ')"

        
        if ($result.LicenseServers)
        {
            Write-Verbose ">> RD License servers  :     $($result.LicenseServers.ToLower() -join '; ')"
        }
    }
    else
    {
        Write-Verbose "Remote Desktop deployment does not exist on server '$ConnectionBroker' (or Remote Desktop Management Service is not running)."
    }

    return $result
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [Parameter(Mandatory = $true)]
        [string]
        $ConnectionBroker,

        [Parameter()]
        [string]
        $WebAccessServer,

        [Parameter()]
        [string[]]
        $SessionHosts
    )

    #Must be manually loaded in every Function otherwise unexpected behavior occurs with missing commands
    Import-RDModule

    $DeploymentPrarms = @{}

    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker

    $DeploymentPrarms.Add("ConnectionBroker",$ConnectionBroker)

    #If SessionHosts aren't specified make the connection Broker a sessionHost
    if (-not $SessionHosts)  { $SessionHosts =  @( $ConnectionBroker ) }
    $DeploymentPrarms.Add("SessionHost",$SessionHosts)
    
    Write-Verbose "Initiating new RD Session-based deployment on '$ConnectionBroker'..."

    Write-Verbose ">> RD Connection Broker:     $($ConnectionBroker.ToLower())"

    Write-Verbose ">> RD Session Host servers:  $($SessionHosts.ToLower() -join '; ')"

    #If WebAccessServers aren't specified then remove them from the splat
    if ($WebAccessServer)
    {
        Write-Verbose ">> RD Web Access server:     $($WebAccessServer.ToLower())"
        $DeploymentPrarms.Add("WebAccessServer",$WebAccessServer)
    }

    Write-Verbose "calling New-RdSessionDeployment cmdlet..."

    New-RDSessionDeployment @DeploymentPrarms
    Write-Verbose "New-RdSessionDeployment done."
}


#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (    
        [Parameter(Mandatory = $true)]
        [string]
        $ConnectionBroker,

        [Parameter()]
        [string] 
        $WebAccessServer,

        [Parameter()]
        [string[]] 
        $SessionHosts
    )


    Write-Verbose "Checking whether Remote Desktop deployment exists on server '$ConnectionBroker'..."

    $rddeployment = Get-TargetResource @PSBoundParameters
    
    if ($rddeployment)
    {
        Write-Verbose "Verifying RD Connection broker name..."
        $result = ($rddeployment.ConnectionBroker -contains $ConnectionBroker)
    }
    else
    {
        Write-Verbose "RD deployment not found."
        $result = $false
    }

    Write-Verbose "Test-TargetResource returning: $result"
    return $result
}

Export-ModuleMember -Function *-TargetResource
