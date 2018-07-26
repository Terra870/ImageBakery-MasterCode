configuration firewall
{
    param (
        [string[]] $computername,
        [string[]] $xnetworkingversion
    )
    
    Import-DSCResource -ModuleName "xNetworking" -ModuleVersion "5.3.0.0"

    Node $computername
    {
        xFirewall firewall
        {
            Name                  = 'fileaccessFirewallRule'
            DisplayName           = 'Firewall Rule for Network File Access'
            #Group                 = 'NotePad Firewall Rule Group'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'InBound'
            #RemotePort            = ('*')
            LocalPort             = ('139','445')
            Protocol              = 'TCP'
            Description           = 'Firewall Rule for Network File Access'
        }
    }
}        