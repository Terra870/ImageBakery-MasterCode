configuration unzip
{
    param (
        [string[]] $computername,
        [string] $zipfile,
        [string] $destinationfol
    )
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $computername
    {
        Archive unzip {
            Ensure = "Present"
            Path = $zipfile
            Destination = $destinationfol
        }
    }
}
