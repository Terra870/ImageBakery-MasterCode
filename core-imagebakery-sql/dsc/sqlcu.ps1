configuration sqlcu
{
    param (
        [string[]] $computername,
        [string] $sqlversion,
        [string] $sqlsp,
        [string] $sqlspversion,
        [string] $sqlcu,
        [string] $sqlcuversion
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $computername
    {
        Script sqlcudeploy
        {
            SetScript = {
                Write-Verbose -Message "Deploying SQL $using:sqlversion $using:sqlcu"
                $folderpath="D:\SQLServer$using:sqlversion\SQL$using:sqlversion$using:sqlsp" + "_$using:sqlcu\SQLServer$using:sqlversion*"
                $cufile=(Get-ChildItem -Path $folderpath ).Name

                Write-Verbose -Message "Folder path $folderpath"
                Write-Verbose -Message "CU file $cufile"

                $curootfolder=$folderpath.replace("SQLServer$using:sqlversion*","").trim()

                Start-Process -FilePath "$curootfolder\$cufile" `
                    -argument "/allinstances /quiet /IAcceptSQLServerLicenseTerms" -NoNewWindow -Wait
                Write-Verbose -Message "Deployed SQL $using:sqlversion $using:sqlcu"
                $instance = "localhost"
                $dbName = "master"
                
                $query = "ALTER LOGIN sa ENABLE ;  
                GO  
                ALTER LOGIN sa WITH PASSWORD = 'Sabmiller@010123' ;  
                GO
                EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
                N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
                "
                Invoke-SQLCmd -Query $query -ServerInstance $instance -Database $dbName
                Restart-Service -Name MSSQLSERVER -Confirm:$false -Force
            }

            GetScript = {
                $instance = "localhost"
                $dbName = "master"
                $query = "select @@version"
                $spversion=Invoke-SQLCmd -Query $query -ServerInstance $instance -Database $dbName
                Return @{
                   'spstatus' = $spversion
                }
            }
            TestScript = {
                $instance = "localhost"
                $dbName = "master"
                $query = "select @@version"
                $spversion=Invoke-SQLCmd -Query $query -ServerInstance $instance -Database $dbName
                if ($spversion -contains $sqlcuversion) {
                    Write-Verbose -Verbose "$using:sqlversion $using:sqlcu Deployed"
                    return $true
                } else {
                    Write-Verbose -Verbose "$using:sqlversion $using:sqlcu Missing"
                    return $false
                }
            }
        }
   }
}
