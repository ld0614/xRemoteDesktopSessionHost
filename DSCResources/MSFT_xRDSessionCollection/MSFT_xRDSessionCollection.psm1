Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}
Import-Module RemoteDesktop

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
        [ValidateLength(1,15)]
        [string] 
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [string[]] 
        $SessionHosts,

        [Parameter()]
        [string] 
        $CollectionDescription,

        [Parameter()]
        [string] 
        $ConnectionBroker
    )

    $result = $null

    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    Write-Verbose "Getting information about RD Session collection '$CollectionName' at RD Connection Broker '$ConnectionBroker'..."
     
    $collection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue

    if ($collection)
    {
        Write-Verbose "found the collection, now getting list of RD Session Host servers..."

        $SessionHosts = Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker | ForEach-Object {$_.SessionHost}
        Write-Verbose "found $($SessionHosts.Count) host servers assigned to the collection."

        $result = 
        @{
            "ConnectionBroker" = $ConnectionBroker

            "CollectionName"   = $collection.CollectionName
            "CollectionDescription" = $collection.CollectionDescription

            "SessionHosts" = $SessionHosts
        }

        Write-Verbose ">> Collection name:  $($result.CollectionName)"
        Write-Verbose ">> Collection description:  $($result.CollectionDescription)"
        Write-Verbose ">> RD Connection Broker:  $($result.ConnectionBroker.ToLower())"
        Write-Verbose ">> RD Session Host servers:  $($result.SessionHosts.ToLower() -join '; ')"
    }
    else
    {
        Write-Verbose "RD Session collection '$CollectionName' not found."
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
        [ValidateLength(1,15)]
        [string] 
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [string[]]
        $SessionHosts,

        [Parameter()]
        [string] 
        $CollectionDescription,

        [Parameter()]
        [string] 
        $ConnectionBroker
    )

    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    $PSBoundParameters.Remove("ConnectionBroker")

    Write-Verbose "Creating a new RD Session collection '$CollectionName' at the RD Connection Broker '$ConnectionBroker'..."

    if ($CollectionDescription)  
    {
        write-verbose "Description: '$CollectionDescription'"
    }
    else
    { 
        $PSBoundParameters.Remove("CollectionDescription") 
    }
    
    if ($SessionHosts) 
    {
        Write-Verbose ">> RD Session Host servers:  $($SessionHosts.ToLower() -join '; ')"
    }
    else 
    { 
        $SessionHosts = @( $localhost ) 
    }

    
    $PSBoundParameters.Remove("SessionHosts")
    Write-Verbose "calling New-RdSessionCollection cmdlet..."
    New-RDSessionCollection @PSBoundParameters -ConnectionBroker $ConnectionBroker -SessionHost $SessionHosts

    #    Add-RDSessionHost @PSBoundParameters  # that's if the Session host is not in the collection
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
        [ValidateLength(1,15)]
        [string] 
        $CollectionName,

        [Parameter(Mandatory = $true)]
        [String[]]
        $SessionHosts,

        [Parameter()]
        [string]
        $CollectionDescription,

        [Parameter()]
        [string] 
        $ConnectionBroker
    )

    write-verbose "Checking for existence of RD Session collection named '$CollectionName'..."
    
    $collection = Get-TargetResource @PSBoundParameters
    
    if ($collection)
    {
        write-verbose "verifying RD Session collection name and parameters..."
        $result =  ($collection.CollectionName -ieq $CollectionName)
    }
    else
    {
        write-verbose "RD Session collection named '$CollectionName' not found."
        $result = $false
    }

    write-verbose "Test-TargetResource returning:  $result"
    return $result
}

Export-ModuleMember -Function *-TargetResource
