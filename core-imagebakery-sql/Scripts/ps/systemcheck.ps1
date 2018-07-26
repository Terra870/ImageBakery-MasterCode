Function systemcheck ([string] $computername) {
    start-sleep -seconds 20
    Test-WSMan -computername $computername -ErrorAction SilentlyContinue #-OutVariable $null
    if ($? -eq "True") {
        Write-Host "System is back after restart"
    } else {
        Write-Host "Waiting for 30 Sec for system to come up"
        start-sleep -seconds 10
        systemcheck -computername $computername   
    }
}