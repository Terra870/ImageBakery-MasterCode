configuration sqlsp
{
    param (
        [string[]] $computername,
        [string] $sqlversion,
        [string] $sqlsp,
        [string] $sqlspversion
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $computername
    {
        Script sqlspdeploy
        {
            SetScript = {
                Write-Verbose -Message "Deploying SQL $using:sqlversion $using:sqlsp"
                $folderpath="D:\SQLServer$using:sqlversion\SQL$using:sqlversion" + "_$using:sqlsp\SQLServer$using:sqlversion$using:sqlsp*"
                $spfile=(Get-ChildItem -Path $folderpath).Name

                Write-Verbose -Message "SP Folder Path $folderpath"
                Write-Verbose -Message "SP file name $spfile"

                $sprootfolder=$folderpath.replace("SQLServer$using:sqlversion$using:sqlsp*","").trim()
                Start-Process -FilePath "$sprootfolder\$spfile" `
                    -argument "/allinstances /quiet /IAcceptSQLServerLicenseTerms" -NoNewWindow -Wait
                
                Write-Verbose -Message "Deployed SQL $using:sqlversion $using:sqlsp"
            }

            GetScript = {
                $instance = "localhost"
                $dbName = "master"
                $query = "select @@version"
                $spversioninfo=Invoke-SQLCmd -Query $query -ServerInstance $instance -Database $dbName
                Return @{
                   'spstatus' = $spversioninfo
                }
            }

            TestScript = {
                $instance = "localhost"
                $dbName = "master"
                $query = "select @@version"
                $spversioninfo=Invoke-SQLCmd -Query $query -ServerInstance $instance -Database $dbName

                if ($spversioninfo -contains $spversion) {
                    Write-Verbose -Verbose "$using:sqlversion $using:sqlsp already deployed"
                    return $true
                } else {
                    Write-Verbose -Verbose "$using:sqlversion $using:sqlsp Missing"
                    return $false
                }
            }
        }
   }
}
