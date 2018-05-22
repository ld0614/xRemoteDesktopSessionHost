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
        $CollectionName, #eg Tenant

        [Parameter(Mandatory = $true)]
        [string] 
        $DisplayName, #eg Calculator

        [Parameter(Mandatory = $true)]
        [string] 
        $FilePath, #eg C:\Windows\System32\calc.exe

        [Parameter(Mandatory = $true)]
        [string] 
        $Alias, #eg calc

        [Parameter()]
        [string] 
        $FileVirtualPath,

        [Parameter()]
        [string] 
        $FolderName,

        [Parameter()]
        [string] 
        $CommandLineSetting,

        [Parameter()]
        [string] 
        $RequiredCommandLine,

        [Parameter()]
        [uint32] 
        $IconIndex,

        [Parameter()]
        [string] 
        $IconPath,

        [Parameter()]
        [string] 
        $UserGroups,

        [Parameter()]
        [boolean] 
        $ShowInWebAccess
    )
        $localhost = Get-Localhost
        Write-Verbose "Getting published RemoteApp program $DisplayName, if one exists."
        $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
        $CollectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker | ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker} | Where-Object {$_.SessionHost -ieq $localhost} | ForEach-Object {$_.CollectionName}
        $remoteApp = Get-RDRemoteApp -CollectionName $CollectionName -DisplayName $DisplayName -Alias $Alias -ConnectionBroker $ConnectionBroker

        @{
        "CollectionName" = $remoteApp.CollectionName;
        "DisplayName" = $remoteApp.DisplayName;
        "FilePath" = $remoteApp.FilePath;
        "Alias" = $remoteApp.Alias;
        "FileVirtualPath" = $remoteApp.FileVirtualPath;
        "FolderName" = $remoteApp.FolderName;
        "CommandLineSetting" = $remoteApp.CommandLineSetting;
        "RequiredCommandLine" = $remoteApp.RequiredCommandLine;
        "IconIndex" = $remoteApp.IconIndex;
        "IconPath" = $remoteApp.IconPath;
        "UserGroups" = $remoteApp.UserGroups;
        "ShowInWebAccess" = $remoteApp.ShowInWebAccess;
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

        [Parameter(Mandatory = $true)]
        [string] 
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [string] 
        $FilePath,

        [Parameter(Mandatory = $true)]
        [string] 
        $Alias,

        [Parameter()]
        [string] 
        $FileVirtualPath,

        [Parameter()]
        [string] 
        $FolderName,

        [Parameter()]
        [string] 
        $CommandLineSetting,

        [Parameter()]
        [string] 
        $RequiredCommandLine,

        [Parameter()]
        [uint32] 
        $IconIndex,

        [Parameter()]
        [string] 
        $IconPath,

        [Parameter()]
        [string] 
        $UserGroups,

        [Parameter()]
        [boolean] 
        $ShowInWebAccess
    )
    Write-Verbose "Making updates to RemoteApp."
    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    $CollectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker | ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker} | Where-Object {$_.SessionHost -ieq $localhost} | ForEach-Object {$_.CollectionName}
    $PSBoundParameters.collectionName = $CollectionName
    if (!$(Get-RDRemoteApp -Alias $Alias -ConnectionBroker $ConnectionBroker)) 
    {
        New-RDRemoteApp @PSBoundParameters -ConnectionBroker $ConnectionBroker
    }
    else 
    {
        Set-RDRemoteApp @PSBoundParameters -ConnectionBroker $ConnectionBroker
    }
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
        [string] 
        $DisplayName,

        [Parameter(Mandatory = $true)]
        [string] 
        $FilePath,

        [Parameter(Mandatory = $true)]
        [string] 
        $Alias,

        [Parameter()]
        [string] 
        $FileVirtualPath,

        [Parameter()]
        [string] 
        $FolderName,

        [Parameter()]
        [string] 
        $CommandLineSetting,

        [Parameter()]
        [string] 
        $RequiredCommandLine,

        [Parameter()]
        [uint32] 
        $IconIndex,

        [Parameter()]
        [string] 
        $IconPath,

        [Parameter()]
        [string] 
        $UserGroups,

        [Parameter()]
        [boolean] 
        $ShowInWebAccess
    )
    Write-Verbose "Testing if RemoteApp is published."
    $Localhost = Get-Localhost
    $ConnectionBroker = Get-ConnectionBroker -ConnectionBroker $ConnectionBroker #resolves to localhost / active connection broker
    $collectionName = Get-RDSessionCollection -ConnectionBroker $ConnectionBroker | ForEach-Object {Get-RDSessionHost $_.CollectionName -ConnectionBroker $ConnectionBroker} | Where-Object {$_.SessionHost -ieq $localhost} | ForEach-Object {$_.CollectionName}
    $PSBoundParameters.Remove("Verbose") | out-null
    $PSBoundParameters.Remove("Debug") | out-null
    $PSBoundParameters.Remove("ConnectionBroker") | out-null
    $Check = $true
    
    $Get = Get-TargetResource -CollectionName $CollectionName -DisplayName $DisplayName -FilePath $FilePath -Alias $Alias
    $PSBoundParameters.keys | ForEach-Object {if ($PSBoundParameters[$_] -ne $Get[$_]) {$Check = $false} }
    return $Check
}

Export-ModuleMember -Function *-TargetResource
