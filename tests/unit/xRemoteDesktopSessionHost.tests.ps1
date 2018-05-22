#region HEADER

# Unit Test Template Version: 1.2.1
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Write-Output @('clone','https://github.com/PowerShell/DscResource.Tests.git',"'"+(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests')+"'")

if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'),'--verbose')
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

Import-module "$moduleRoot\xRemoteDesktopSessionHostCommon.psm1" -force
Write-Verbose -Message "$moduleRoot\DscResources\*.psm1" -Verbose
$global:resourceModules = Get-ChildItem -Path "$moduleRoot\DscResources\*.psm1" -Recurse
Write-Verbose -Message "$($resourceModules.Count)" -Verbose 

#endregion HEADER

function Invoke-TestSetup {

}

function Invoke-TestCleanup {

}

#endregion

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{
    #region Pester Tests
    Invoke-TestSetup

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope xRemoteDesktopSessionHostCommon {

        #region Function Test-xRemoteDesktopSessionHostOsRequirement
        Describe "Test-xRemoteDesktopSessionHostOsRequirement" {
            Context 'Windows 10' {
                Mock -CommandName Get-OsVersion `
                    -MockWith {return (new-object 'Version' 10,1,1,1)} `
                    -Verifiable

                It 'Should return true' {
                    Test-xRemoteDesktopSessionHostOsRequirement | Should -Be $true
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Windows 8.1' {
                Mock -CommandName Get-OsVersion `
                    -MockWith {return (new-object 'Version' 6,3,1,1)} `
                    -Verifiable

                It 'Should return true' {
                    Test-xRemoteDesktopSessionHostOsRequirement | Should -Be $true
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Windows 8' {
                Mock -CommandName Get-OsVersion `
                    -MockWith {return (new-object 'Version' 6,2,9200,0)} `
                    -Verifiable

                It 'Should return true' {
                    Test-xRemoteDesktopSessionHostOsRequirement | Should -Be $true
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Windows 7' {
                Mock -CommandName Get-OsVersion `
                    -MockWith {return (new-object 'Version' 6,1,1,0)} `
                    -Verifiable

                It 'Should return false' {
                    Test-xRemoteDesktopSessionHostOsRequirement | Should -Be $false
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }
        }
        #endregion

        Describe "Import-RDModule" {
            Context 'Import Module runs successfully' {
                Mock -CommandName Get-Module `
                    -MockWith {return @{ModuleType='Manifest';Version=[Version]::new(2,0,0,0);Name='RemoteDesktop';ExportedCommands='{Some-Command}'}} `
                    -Verifiable
                Mock -CommandName Import-Module `
                    -MockWith {return $null} `
                    -Verifiable
                Mock -CommandName Get-Command `
                    -MockWith {@{CommandType='Function';Name='Get-Server';Version=[Version]::new(2,0,0,0);Source='RemoteDesktop'}} `
                    -Verifiable
                It 'Import-RDModule Runs successfully' {
                    {Import-RDModule} | Should -Not -Throw
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }
        }

        Describe 'Get-ActiveConnectionBroker' {

            Context 'No Connection Broker' {
                Mock -CommandName Get-RDConnectionBrokerHighAvailability `
                    -ModuleName RemoteDesktop `
                    -MockWith {throw 'Invalid Connection Broker'} `
                    -Verifiable
                $script:ConnectionBroker = "SRV01.contoso.com"
                
                It 'Should Not Throw' {
                    {Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ConnectionBroker
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Not HA Local Connection Broker' {
                Mock -CommandName Get-RDConnectionBrokerHighAvailability `
                    -ModuleName RemoteDesktop `    
                    -MockWith {return $null} `
                    -Verifiable
                $script:ConnectionBroker = "SRV01.contoso.com"
                
                It 'Should Not Throw' {
                    {Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ConnectionBroker
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Local HA Connection Broker' {
                $script:ConnectionBroker = "SRV01.contoso.com"
                $script:ActiveServer = $script:ConnectionBroker
                Mock -CommandName Get-RDConnectionBrokerHighAvailability `
                    -ModuleName RemoteDesktop `
                    -MockWith {return @{ActiveManagementServer=$script:ActiveServer}} `
                    -Verifiable
                
                It 'Should Not Throw' {
                    {Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ActiveServer
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Remote HA Connection Broker' {
                $script:ConnectionBroker = 'SRV01.contoso.com'
                $script:ActiveServer = 'SRV02.contoso.com'
                Mock -CommandName Get-RDConnectionBrokerHighAvailability `
                    -ModuleName RemoteDesktop `
                    -MockWith {return @{ActiveManagementServer=$script:ActiveServer}} `
                    -Verifiable
                
                It 'Should Not Throw' {
                    {Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ActiveConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ActiveServer
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }
        }

        Describe 'Get-ConnectionBroker' {
            $script:ConnectionBroker = 'SRV01.contoso.com'
            Context 'No parameter' {
                Mock -CommandName Get-LocalHost `
                    -MockWith {return $script:ConnectionBroker} `
                    -Verifiable
                Mock -CommandName Get-ActiveConnectionBroker `
                    -MockWith {return $script:ConnectionBroker} `
                    -Verifiable
                
                It 'Should Not Throw' {
                    {Get-ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ConnectionBroker | Should -Be $script:ConnectionBroker
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Local ConnectionBroker' {
                Mock -CommandName Get-LocalHost `
                    -MockWith {return $script:ConnectionBroker} `
                    -Verifiable
                Mock -CommandName Get-ActiveConnectionBroker `
                    -MockWith {return $script:ConnectionBroker} `
                    -Verifiable
                
                It 'Should Not Throw' {
                    {Get-ConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Current Server' {
                    Get-ConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ConnectionBroker
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }

            Context 'Remote Connection Broker' {
                $script:ActiveConnectionBroker = 'SRV02.contoso.com'
                Mock -CommandName Get-LocalHost `
                    -MockWith {return $script:ConnectionBroker} `
                    -Verifiable
                Mock -CommandName Get-ActiveConnectionBroker `
                    -MockWith {return $script:ActiveConnectionBroker} `
                    -Verifiable
                
                It 'Should Not Throw' {
                    {Get-ConnectionBroker -ConnectionBroker $script:ConnectionBroker} | Should -Not -Throw
                }

                It 'Returns Remote Server' {
                    Get-ConnectionBroker -ConnectionBroker $script:ConnectionBroker | Should -Be $script:ActiveConnectionBroker
                }

                It 'All Mocks should have run'{
                    {Assert-VerifiableMock} | Should -Not -Throw
                }
            }
        }
    }
    #endregion
}
finally
{
    Invoke-TestCleanup
}
