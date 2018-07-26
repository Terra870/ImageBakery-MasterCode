configuration DeployFeatureSet
{
    param (
        [string[]] $computername
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $computername
    {
        <#WindowsFeatureSet DotNetFramwork4.6
        {
            Name                    = @("Net-Framework-45-Core", "Net-Framework-45-Features")
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } #>

        WindowsFeatureSet PowerShellISE
        {
            Name                    = "PowerShell-ISE"
            Ensure                  = 'Absent'
            IncludeAllSubFeature    = $false
        } 

        WindowsFeatureSet RemoveSMB1.1
        {
            Name                    = "FS-SMB1"
            Ensure                  = 'Absent'
            IncludeAllSubFeature    = $true
        } 

        WindowsFeatureSet XPSViewer
        {
            Name                    = "XPS-Viewer"
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 
    }
}