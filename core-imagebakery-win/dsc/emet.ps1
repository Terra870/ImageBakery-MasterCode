configuration InstallEMET
{
    param (
        [string[]] $computername
    )
    
    Node $computername
    {
        # Install EMET
        Script installEMET
        {
            SetScript = {
                Write-Verbose -Verbose "Installing EMET"
                invoke-webrequest https://download.microsoft.com/download/8/E/E/8EEFD9FC-46B1-4A8B-9B5D-13B4365F8CA0/EMET%20Setup.msi `
                    -outfile "c:\fidelity\EMET.msi"
                
                #MSI Related Install/Uninstall
                $MSIExecPath = "`"$env:systemroot\system32\msiexec.exe`""
                $ArgumentListInstallMSI = "/i ""c:\fidelity\EMET.msi"" /qb /NoRestart"    
                
                $EventLog_Test = [System.Diagnostics.EventLog]::SourceExists('Fidelity_PowerShell_Script_Installer')
                IF (!($EventLog_Test)) {
                    New-EventLog -LogName "Application" -Source "Fidelity_PowerShell_Script_Installer"
                }
                
                #MSI Install - Un-Remark line below if using an .MSI-based installer
                Write-Verbose -Verbose "Starting the Installation"
                Start-Process -FilePath $MSIExecPath -argumentlist $ArgumentListInstallMSI -Wait -windowstyle hidden
            }
            GetScript = {
                $appstatus = Get-WmiObject -Class win32_product | where-object {$_.Name -match "EMET"}
                Return @{
                    'appstatus' = $appstatus.count
                }
            }
            TestScript = { 
                If (Get-WmiObject -Class win32_product | where-object {$_.Name -match "EMET"}) {
                    # EMET is installed and return true
                    Return $True
                }
                # EMET is not installed and return false
                Return $False
            }
        }
    }
}