configuration dscmodule
{
    param (
        [string[]] $computername,
        [string[]] $dscmodulename,
        [string[]] $dscmoduleversion
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $computername
    {
        Script dscmodule
        {
            SetScript = {
                # deploy dsc modules
                Write-Verbose -Message "Deploying DSC Module $dscmodulename and version $dscmoduleversion"
                Save-Module -Name $dscmodulename -Path "C:\Program Files\WindowsPowerShell\Modules" -RequiredVersion $dscmoduleversion
                install-module -Name $dscmodulename -RequiredVersion $dscmoduleversion

                #Write-Verbose -Message "Delete old sysprep file"
                #Remove-Item -Path "C:\Windows\System32\sysprep\sysprep.bat" -Confirm:$false -Force
            }
            GetScript = {
                foreach ($dscmodule in $dscmoduleslist) {
                    $module=(Get-DscResource -Module $dscmodulename |  Where-Object {$_.version -eq $dscmoduleversion})
                    Return @{
                        'appstatus' = $module.count
                    }
                }
            }
            TestScript = {
                $overalldscmodulestate=$false
                if (Get-DscResource -Module $dscmodulename |  Where-Object {$_.version -eq $dscmoduleversion}) {
                    $overalldscmodulestate=$true
                }
                return $overalldscmodulestate
            }
        }
   }
}
