$dscconfig=@{
    AllNodes = @(
        @{
            NodeName = "azsql2k14temp"
            PSDscAllowPlainTextPassword = $true
            #PSDscAllowDomainUser = $true
        }
    )
}

configuration sqldeploy
{
    param (
        [string] $computername,
        [string[]] $computerip,
        [string] $SQLCollation,
        [string] $sqlversion,
        [string] $installfolder
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xSQLServer -ModuleVersion 8.2.0.0
    
    Node $computerip
    {
        
	    $mountpointdrive=[Environment]::GetEnvironmentVariable("mountpointdrive","Machine")
        $sqlinstalldrive=[Environment]::GetEnvironmentVariable("sqlinstalldrive","Machine")

        xSQLServerSetup 'sqldeploy'
        {
            InstanceName          = 'MSSQLSERVER'
            Features              = 'SQLENGINE,SSMS,ADV_SSMS'
            SQLCollation          = "${SQLCollation}"
            #SQLSvcAccount        = $SqlServiceCredential
            #AgtSvcAccount        = $SqlAgentServiceCredential
            #ASSvcAccount         = $SqlServiceCredential
            SQLSysAdminAccounts   = "Harlequin","${computername}\administrators"
            #SecurityMode          = 'SQL'
            #SAPwd                 = "Sabmiller@010"  

            InstallSharedDir      = "G:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir   = "G:\Program Files (x86)\Microsoft SQL Server"
            InstanceDir           = "F:\SQLSystemDB01\Microsoft SQL Server"
            InstallSQLDataDir     = "F:\SQLSystemDB01\Microsoft SQL Server\MSSQL12.INST2014\MSSQL\Data"
            SQLUserDBDir          = "F:\SQLUserDBData01\Program Files\Microsoft SQL Server\${installfolder}\MSSQL\Data"
            SQLUserDBLogDir       = "F:\SQLUserDBLogs01\Program Files\Microsoft SQL Server\${installfolder}\MSSQL\Data"
            SQLTempDBDir          = "F:\SQLTempDBData01\Program Files\Microsoft SQL Server\${installfolder}\MSSQL\Data"
            SQLTempDBLogDir       = "F:\SQLTempDBLogs01\Program Files\Microsoft SQL Server\${installfolder}\MSSQL\Data"
            SQLBackupDir          = "F:\SQLBackups01\Program Files\Microsoft SQL Server\${installfolder}\MSSQL\Backup"
            SourcePath            = "D:\SQLServer${sqlversion}\_standard_edition_sp1"
            UpdateEnabled         = 'True'
            #UpdateSource          = ""
            ForceReboot           = $false
            BrowserSvcStartupType = 'Automatic'
            #PsDscRunAsCredential  = $SqlInstallCredential
        }
    }
}