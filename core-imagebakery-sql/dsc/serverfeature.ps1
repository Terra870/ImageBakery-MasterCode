configuration serverfeature
{
    param (
        [string[]] $computername
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node $computername
    {
        WindowsFeatureSet DotNetFramwork3.5
        {
            Name                    = @("Net-Framework-Core", "Net-Framework-Features")
            Ensure                  = 'Present'
            IncludeAllSubFeature    = $true
        } 
        
    }
}