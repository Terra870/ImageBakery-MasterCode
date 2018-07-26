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
                Write-Verbose -Message "Deploying DSC Module $using:dscmodulename and version $using:dscmoduleversion"
                Save-Module -Name $using:dscmodulename -RequiredVersion $using:dscmoduleversion -Path "C:\Program Files\WindowsPowerShell\Modules"
                install-module -Name $using:dscmodulename -RequiredVersion $using:dscmoduleversion -confirm:$false
            }
            GetScript = {
                    $module=(find-module -Name $using:dscmodulename -RequiredVersion $using:dscmoduleversion)
                    Return @{
                        'modulename' = $using:dscmodulename
                        'moduleversion' = $using:dscmoduleversion
                    }
            }
            TestScript = {
                $overalldscmodulestate=$false
                if (find-module -Name $using:dscmodulename -RequiredVersion $using:dscmoduleversion) {
                    $overalldscmodulestate=$true
                }
                return $overalldscmodulestate
            }
        }
   }
}
