configuration lgpo
{
    param (
        [string[]] $computername,
        [string[]] $IMAGETYPE
    )
    
    Node $computername
    {
        Script lgpo
        {
            SetScript = {
                Write-Verbose -Message "Image Type - $using:IMAGETYPE"
                $ArgumentListMSL1 = "/g ""C:\fidelity\LGPO\$IMAGETYPE"""
				                          
                #$ArgumentListUserL1 = '/v /g "C:\Fidelity\ref-build\AZ_Repo\Applications\Microsoft\LGPO\Server2016v1.0.0\USER-L1"'
                $FileCheck = "C:\Windows\LGPO.EXE"
                $lgpopath="C:\Fidelity\LGPO"
                
                Write-Verbose -Verbose "Downloading latest LGPO Tool"
                invoke-webrequest "https://download.microsoft.com/download/8/5/C/85C25433-A1B0-4FFA-9429-7E023E7DA8D8/LGPO.zip" `
                    -outfile "$lgpopath\lgpo.zip"

                #unzip install
                Add-Type -assembly "system.io.compression.filesystem"
                [io.compression.zipFile]::ExtractToDirectory("$lgpopath\lgpo.zip", "$lgpopath\")     

                Copy-Item -Path "$lgpopath\LGPO.exe" -Destination "c:\Windows\" `
                -Force -PassThru

                #Write-Verbose -Verbose "Applying Windows 2016 CIS Standards"
                #c:\Windows\LGPO.exe /g "C:\fidelity\LGPO\$using:IMAGETYPE"
				Write-Verbose "LGPO Command Argument - $ArgumentListMSL1"
                
                Write-Verbose -Verbose "Applying User-L1 CIS Standards"
                Start-Process -FilePath "$FileCheck" -argumentlist $ArgumentListMSL1 -Wait -NoNewWindow
                
            }

            GetScript = {
                $appstatus = (Test-Path -Path "$lgpopath\LGPO.exe")
                Return @{
                    'appstatus' = $appstatus
                }
            }

            TestScript = { 
                If (Test-Path -Path $lgpopath\LGPO.exe) {
                    # LGPO Tool Present and return true
                    Return $True
                } 
                # LGPO Tool not present and return false
                Return $False
            }
        }
    }
}