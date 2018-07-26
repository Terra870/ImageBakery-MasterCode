Function configxml_tfinfo ([string] $CONFPATH) {
    
    Write-Host "Dynamic tfvars based upon config.xml"

    Write-Host "Configuation xml path - $CONFPATH\config.xml"
    if (Test-Path $CONFPATH\config.xml) {
        Write-Host "Config file found. So will load"
        [xml]$Config = Get-Content $CONFPATH\config.xml
    } else {
        Write-Host "Config not found. Stop!!"
        exit 1
    }

    Write-Host "Time to work out some variables for terraform arguments."
    $terraformVars = $Config.config.terraform.var
    New-Item -ItemType file -path $CONFPATH\temp.tfvars -Confirm:$false -Force
    
    foreach($var in $terraformVars){
        $name=$var.name
        $value=$var.value
        Add-Content -path $CONFPATH\temp.tfvars "$name=""$value"""
    }

    $tmptfvars="$CONFPATH\temp.tfvars"
    Write-Host $tmptfvars

    Write-Host "Setting parameter for initializing remote state"
    $remote_resource_group_name=($terraformVars | where-object {$_.Name -eq "state_resource_group_name"}).value
    $remote_storage_account_name=($terraformVars | where-object {$_.Name -eq "state_storage_account_name"}).value
    $remote_container_name=($terraformVars | where-object {$_.Name -eq "state_container_name"}).value
    $remote_key=($terraformVars | where-object {$_.Name -eq "state_key"}).value

    $initarglist = 'init',"-backend-config=""storage_account_name=$remote_storage_account_name""",`
"-backend-config=""container_name=$remote_container_name""","-backend-config=""key=$remote_key""",`
"-backend-config=""resource_group_name=$remote_resource_group_name"""
    
    $tfinfo=New-Object System.Collections.ArrayList
    $tfinfo.Add($tmptfvars) | out-null
    $tfinfo.Add($initarglist) | out-null
    
    return $tfinfo
} 