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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionBroker,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("RDS-Connection-Broker","RDS-Virtualization","RDS-RD-Server","RDS-Web-Access","RDS-Gateway","RDS-Licensing")]
        [string]
        $Role,

        [Parameter()]
        [string]
        $GatewayExternalFqdn,   # only for RDS-Gateway

        [Parameter()]
        [string]
        $CBConnectionString,   # only for RDS-Connection-Broker

        [Parameter()]
        [string]
        $CBClientAccessName   # only for RDS-Connection-Broker
    )

    #Must be manually loaded in every Function otherwise unexpected behavior occurs with missing commands
    Import-RDModule

    $result = $null

    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker

    Write-Verbose "Getting list of servers of type '$Role' from '$ConnectionBroker'..."    
    $servers = Get-RDServer -ConnectionBroker $ConnectionBroker -Role $Role -ErrorAction SilentlyContinue

    if ($servers)
    {
        Write-Verbose "Found $($servers.Count) '$Role' servers in the deployment, now looking for server named '$Server'..."

        if ($Server -in $servers.Server)
        {
            write-verbose "The server '$Server' is in the RD deployment."

            $result = 
            @{
                "ConnectionBroker"    = $ConnectionBroker
                "Server"              = $Server
                "Role"                = $Role
                "GatewayExternalFqdn" = $null
                "CBConnectionString"  = $null
                "CBClientAccessName"  = $null
            }

            if ($Role -eq 'RDS-Gateway')
            {
                write-verbose "the role is '$Role', querying RDS Gateway configuration..."

                $config = Get-RDDeploymentGatewayConfiguration -ConnectionBroker $ConnectionBroker

                if ($config)
                {
                    write-verbose "RDS Gateway configuration retrieved successfully..."
                    $result.GatewayExternalFqdn = $config.GatewayExternalFqdn
                    Write-verbose ">> GatewayExternalFqdn: '$($result.GatewayExternalFqdn)'"
                } 
            }
        }
        else
        {
            write-verbose "The server '$Server' is not in the deployment as '$Role' yet."
        }

    }
    else
    {
        write-verbose "No '$Role' servers found in the deployment on '$ConnectionBroker'."
        # or, possibly, Remote Desktop Deployment doesn't exist/Remote Desktop Management Service not running
    }

    return $result
}

Function Add-RDServerFixed
{
    [CmdletBinding()]
    param
    (    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] 
        $ConnectionBroker,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Server,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("RDS-Connection-Broker","RDS-Virtualization","RDS-RD-Server","RDS-Web-Access","RDS-Gateway","RDS-Licensing")]
        [string] 
        $Role,

        [Parameter()]
        [string] 
        $GatewayExternalFqdn   # only for RDS-Gateway
    )
    # workaround for bug #3299246
    Add-RDServer @PSBoundParameters -ErrorAction SilentlyContinue -ErrorVariable e

    if ($e.count -eq 0) 
    {
        Write-Verbose "Add-RDServer completed without errors..."
        # continue
    }
    elseif ($e[0].FullyQualifiedErrorId -eq 'CommandNotFoundException')
    {
        Write-Verbose "Add-RDServer: trapped erroneous errors, that's ok, continuing..."
        # ignore & continue
    }
    else
    {
        Write-Error "Add-RDServer threw $($e.count) errors.  First Error: $e[0].FullyQualifiedErrorId"
    }
}

######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################

#TODO: Fix login and streamline
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] 
        $ConnectionBroker,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Server,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("RDS-Connection-Broker","RDS-Virtualization","RDS-RD-Server","RDS-Web-Access","RDS-Gateway","RDS-Licensing")]
        [string] 
        $Role,

        [Parameter()]
        [string] 
        $GatewayExternalFqdn,   # only for RDS-Gateway

        [Parameter()]
        [string] 
        $CBConnectionString,   # only for RDS-Connection-Broker

        [Parameter()]
        [string] 
        $CBClientAccessName,   # only for RDS-Connection-Broker

        [Parameter()]
        [string] 
        $CollectionName   # only for RDS-RD-Server, optional
    )

    #Must be manually loaded in every Function otherwise unexpected behavior occurs with missing commands
    Import-RDModule

    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    
    Write-Verbose "Adding server '$($Server.ToLower())' as $Role to the deployment on '$($ConnectionBroker.ToLower())'..."

    switch ($Role)
    {
        "RDS-Connection-Broker" {
            $CurrentHAConfig = Get-RDConnectionBrokerHighAvailability -ConnectionBroker $ConnectionBroker
            if ($null -eq $CurrentHAConfig)
            {
                #HA not configured
                Write-Verbose "Configuring Connection Broker High Availability"
                Set-RDConnectionBrokerHighAvailability -ConnectionBroker $ConnectionBroker -DatabaseConnectionString $CBConnectionString -ClientAccessName $CBClientAccessName
            }
            Write-Verbose "Installing Connection Broker Role"
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker
        }
        "RDS-Virtualization" {
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker
        }
        "RDS-RD-Server" {
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker

            if ($PSBoundParameters.ContainsKey('CollectionName'))
            {
                Write-Verbose "Adding $Server to $CollectionName"
                Add-RDSessionHost -CollectionName $CollectionName -SessionHost $Server -ConnectionBroker $ConnectionBroker
            }
        }
        "RDS-Web-Access" {
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker
        }
        "RDS-Gateway" {
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker -GatewayExternalFqdn $GatewayExternalFqdn
        }
        "RDS-Licensing" {
            Add-RDServerFixed -Server $Server -Role $Role -ConnectionBroker $ConnectionBroker
        }
        default {
            throw "Unknown Role: $Role"
        }
    }

    Write-Verbose "Add-RDServer done."
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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string] 
        $ConnectionBroker,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] 
        $Server,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("RDS-Connection-Broker","RDS-Virtualization","RDS-RD-Server","RDS-Web-Access","RDS-Gateway","RDS-Licensing")]
        [string] 
        $Role,

        [Parameter()]
        [string] 
        $GatewayExternalFqdn,   # only for RDS-Gateway

        [Parameter()]
        [string] 
        $CBConnectionString,   # only for RDS-Connection-Broker

        [Parameter()]
        [string] 
        $CBClientAccessName,   # only for RDS-Connection-Broker

        [Parameter()]
        [string] 
        $CollectionName   # only for RDS-RD-Server, optional
    )

    $target = Get-TargetResource @PSBoundParameters

    $result = $null -ne $target
    
    Write-Verbose "Test-TargetResource returning:  $result"
    return $result
}

Export-ModuleMember -Function *-TargetResource
