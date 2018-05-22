Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}
Import-RDModule

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

        [Parameter()]
        [uint32] 
        $ActiveSessionLimitMin,

        [Parameter()]
        [boolean] 
        $AuthenticateUsingNLA,

        [Parameter()]
        [boolean] 
        $AutomaticReconnectionEnabled,

        [Parameter()]
        [string] 
        $BrokenConnectionAction,

        [Parameter()]
        [string] 
        $ClientDeviceRedirectionOptions,

        [Parameter()]
        [boolean] 
        $ClientPrinterAsDefault,

        [Parameter()]
        [boolean] 
        $ClientPrinterRedirected,

        [Parameter()]
        [string] 
        $CollectionDescription,

        [Parameter()]
        [string] 
        $ConnectionBroker,

        [Parameter()]
        [string] 
        $CustomRdpProperty,

        [Parameter()]
        [uint32] 
        $DisconnectedSessionLimitMin,

        [Parameter()]
        [string] 
        $EncryptionLevel,

        [Parameter()]
        [uint32] 
        $IdleSessionLimitMin,

        [Parameter()]
        [uint32] 
        $MaxRedirectedMonitors,

        [Parameter()]
        [boolean] 
        $RDEasyPrintDriverEnabled,

        [Parameter()]
        [string] 
        $SecurityLayer,

        [Parameter()]
        [boolean] 
        $TemporaryFoldersDeletedOnExit,

        [Parameter()]
        [string] 
        $UserGroup
    )
        Write-Verbose "Getting currently configured RDSH Collection properties"
        $localhost = Get-Localhost
        $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
        $collectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker | 
            ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker } | 
            Where-Object {$_.SessionHost -ieq $localhost} | 
            ForEach-Object {$_.CollectionName}

        $collectionGeneral = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker 
        $collectionClient = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -Client
        $collectionConnection = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -Connection
        $collectionSecurity = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -Security
        $collectionUserGroup = Get-RDSessionCollectionConfiguration -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -UserGroup

        @{
            "CollectionName" = $collectionGeneral.CollectionName;
            "ActiveSessionLimitMin" = $collectionConnection.ActiveSessionLimitMin;
            "AuthenticateUsingNLA" = $collectionSecurity.AuthenticateUsingNLA;
            "AutomaticReconnectionEnabled" = $collectionConnection.AutomaticReconnectionEnabled;
            "BrokenConnectionAction" = $collectionConnection.BrokenConnectionAction;
            "ClientDeviceRedirectionOptions" = $collectionClient.ClientDeviceRedirectionOptions;
            "ClientPrinterAsDefault" = $collectionClient.ClientPrinterAsDefault;
            "ClientPrinterRedirected" = $collectionClient.ClientPrinterRedirected;
            "CollectionDescription" = $collectionGeneral.CollectionDescription;
            "CustomRdpProperty" = $collectionGeneral.CustomRdpProperty;
            "DisconnectedSessionLimitMin" = $collectionGeneral.DisconnectedSessionLimitMin;
            "EncryptionLevel" = $collectionSecurity.EncryptionLevel;
            "IdleSessionLimitMin" = $collectionConnection.IdleSessionLimitMin;
            "MaxRedirectedMonitors" = $collectionClient.MaxRedirectedMonitors;
            "RDEasyPrintDriverEnabled" = $collectionClient.RDEasyPrintDriverEnabled;
            "SecurityLayer" = $collectionSecurity.SecurityLayer;
            "TemporaryFoldersDeletedOnExit" = $collectionConnection.TemporaryFoldersDeletedOnExit;
            "UserGroup" = $collectionUserGroup.UserGroup;
        }
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

        [Parameter()]
        [uint32]
        $ActiveSessionLimitMin,

        [Parameter()]
        [boolean]
        $AuthenticateUsingNLA,

        [Parameter()]
        [boolean] 
        $AutomaticReconnectionEnabled,

        [Parameter()]
        [string] 
        $BrokenConnectionAction,

        [Parameter()]
        [string]
        $ClientDeviceRedirectionOptions,

        [Parameter()]
        [boolean]
        $ClientPrinterAsDefault,

        [Parameter()]
        [boolean]
        $ClientPrinterRedirected,

        [Parameter()]
        [string] 
        $CollectionDescription,

        [Parameter()]
        [string] 
        $ConnectionBroker,

        [Parameter()]
        [string]
        $CustomRdpProperty,

        [Parameter()]
        [uint32] 
        $DisconnectedSessionLimitMin,

        [Parameter()]
        [string] 
        $EncryptionLevel,

        [Parameter()]
        [uint32] 
        $IdleSessionLimitMin,

        [Parameter()]
        [uint32] 
        $MaxRedirectedMonitors,

        [Parameter()]
        [boolean] 
        $RDEasyPrintDriverEnabled,

        [Parameter()]
        [string] 
        $SecurityLayer,

        [Parameter()]
        [boolean] 
        $TemporaryFoldersDeletedOnExit,

        [Parameter()]
        [string] 
        $UserGroup
    )
    Write-Verbose "Setting DSC collection properties"
    $localhost = Get-Localhost
    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker

    $discoveredCollectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker |
        ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker } |
        Where-Object {$_.SessionHost -ieq $localhost} |
        ForEach-Object {$_.CollectionName}

    if ($collectionName -ne $discoveredCollectionName) {$PSBoundParameters.collectionName = $discoveredCollectionName}
    $PSBoundParameters.Remove("ConnectionBroker")
    Set-RDSessionCollectionConfiguration @PSBoundParameters -ConnectionBroker $ConnectionBroker 
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

        [Parameter()]
        [uint32] 
        $ActiveSessionLimitMin,

        [Parameter()]
        [boolean] 
        $AuthenticateUsingNLA,

        [Parameter()]
        [boolean] 
        $AutomaticReconnectionEnabled,

        [Parameter()]
        [string] 
        $BrokenConnectionAction,

        [Parameter()]
        [string] 
        $ClientDeviceRedirectionOptions,

        [Parameter()]
        [boolean]
        $ClientPrinterAsDefault,

        [Parameter()]
        [boolean]
        $ClientPrinterRedirected,

        [Parameter()]
        [string]
        $CollectionDescription,

        [Parameter()]
        [string]
        $ConnectionBroker,

        [Parameter()]
        [string]
        $CustomRdpProperty,

        [Parameter()]
        [uint32] 
        $DisconnectedSessionLimitMin,

        [Parameter()]
        [string] 
        $EncryptionLevel,

        [Parameter()]
        [uint32]
        $IdleSessionLimitMin,

        [Parameter()]
        [uint32] 
        $MaxRedirectedMonitors,

        [Parameter()]
        [boolean] 
        $RDEasyPrintDriverEnabled,

        [Parameter()]
        [string]
        $SecurityLayer,

        [Parameter()]
        [boolean]
        $TemporaryFoldersDeletedOnExit,

        [Parameter()]
        [string] 
        $UserGroup
    )
    
    Write-Verbose "Testing DSC collection properties"
    $localhost = Get-Localhost
    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker

    $collectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker  | 
        ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker } | 
        Where-Object {$_.SessionHost -ieq $localhost} | 
        ForEach-Object {$_.CollectionName}

    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("ConnectionBroker") | out-null
    $Check = $true

    $Get = Get-TargetResource -CollectionName $CollectionName
    $PSBoundParameters.keys | ForEach-Object {if ($PSBoundParameters[$_] -ne $Get[$_]) {$Check = $false} }
    return $Check
}

Export-ModuleMember -Function *-TargetResource
