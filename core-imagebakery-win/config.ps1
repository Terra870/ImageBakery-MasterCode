param(
    [string] $CONFPATH,
    [string] $MODE,
    [string] $IMAGETYPE
)
  
write-host "mode $mode"

#set current directory path in variable
$Script_Name = $MyInvocation.MyCommand.Name
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$ErrorActionPreference = "Stop"

$terraform = $env:terraform
#run all ps1 files under scripts\ps directory
Get-ChildItem $directorypath\scripts\ps | ForEach-Object {
    . $_.FullName
}
  
Write-Host "Fetch workloadinfo info from conf repo"
[xml]$xmlinfo=get-content $CONFPATH\config.xml
$AZURE_SUBSCRIPTION_ID=($xmlinfo.config.general.subscriptionid.name)
$AZURE_TENANT_ID=($xmlinfo.config.general.tenantid.name)
$SPNAME=($xmlinfo.config.general.spname.name)
$AZURE_CLIENT_ID=($xmlinfo.config.general.spid.name)
$VMNAME=($xmlinfo.config.general.VM.name)
$RGNAME=($xmlinfo.config.general.resourcegroup.name)
$Img_Name=($xmlinfo.config.general.Image.name)
$USERNAME=($xmlinfo.config.terraform.var | where-object {$_.name -eq "AZ_engg_VM1_UserName"}).value
$PASS=($xmlinfo.config.terraform.var | where-object {$_.name -eq "AZ_engg_VM1_Pass"}).value
    
Write-Host "Set unique Image Name"
$FNDSuffix = Get-Date -Format "yyMMdd"
$FNTSuffix = Get-Date -Format "HHmmss"
$FNSuffix = $FNDSuffix + "-" + $FNTSuffix
$imageName = "$Img_Name-$FNSuffix.vhd"
  
bootstrap -SPNAME $SPNAME -KVNAME "imagebakery"
write-host "env variable $env:AZURE_CLIENT_SECRET"
#login to Azure
$env:arm_subscription_id = $AZURE_SUBSCRIPTION_ID
$env:arm_client_id = $AZURE_CLIENT_ID
$env:arm_client_secret = $env:AZURE_CLIENT_SECRET
$env:arm_tenant_id = $AZURE_TENANT_ID
  
Format-AnsiColor -Message "Logging into Azure RM Account" -Style bold -ForegroundColor magenta
azlogin -AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID -AZURE_CLIENT_ID $AZURE_CLIENT_ID `
    -AZURE_CLIENT_SECRET $env:AZURE_CLIENT_SECRET -AZURE_TENANT_ID $AZURE_TENANT_ID
  
#Find Temp VM instance details
Write-Host "fetching temp VM instance details"
$tempvm=Find-AzureRmResource -TagName Name -TagValue $VMNAME | Where-Object {$_.ResourceType -match "virtualMachines"}
$privateip=(Get-AzureRmNetworkInterface -Name $VMNAME-ni -ResourceGroupName $tempvm.ResourceGroupName).IpConfigurations.PrivateIpAddress
$region=(Get-AzureRmVM -ResourceGroupName $tempvm.ResourceGroupName -Name $tempvm.Name).Location

Format-AnsiColor -Message "Starting to run $Script_Name" -Style bold -ForegroundColor blue
Format-AnsiColor -Message "In Customize-ps1" -Style bold -ForegroundColor green
  
$sUserName =  "$VMNAME\$USERNAME"
$sSecPassword =  "$PASS" | ConvertTo-SecureString -AsPlainText -Force
$oADCredential = New-Object System.Management.Automation.PSCredential ($sUserName, $sSecPassword)
  
$hosts = "$VMNAME,$privateip"
Format-AnsiColor -Message "Running WsManInstance command for the following hosts $hosts"
Set-WSManInstance -ResourceURI winrm/config/client -ValueSet @{TrustedHosts=$hosts}
  
$FPSharing = {
    #Enable-PSRemoting -Force
    Winrm QC -quiet -force
    #netsh advfirewall firewall set rule group=”File and Printer Sharing” new enable=Yes 
    Set-NetFirewallRule -Name 'FPS-SMB-In-TCP' -Enabled True
    Get-NetFirewallRule | Where-Object { $_.Name -like '*FPS*' } | Select-Object Name,Enabled,Direction
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force

    <#change dvd drive
    # Get Available CD/DVD Drive - Drive Type 5
    $DvdDrv = Get-WmiObject -Class Win32_Volume -Filter "DriveType=5"
    $NewDrvLetter="V:"
    # Check if CD/DVD Drive is Available
    if ($DvdDrv -ne $null) {
        # Get Current Drive Letter for CD/DVD Drive
        $DvdDrvLetter = $DvdDrv | Select-Object -ExpandProperty DriveLetter
        Write-Output "Current CD/DVD Drive Letter is $DvdDrvLetter"
        # Confirm New Drive Letter is NOT used
        if (-not (Test-Path -Path $NewDrvLetter)) {
            # Change CD/DVD Drive Letter
            $DvdDrv | Set-WmiInstance -Arguments @{DriveLetter="$NewDrvLetter"}
            Write-Output "Updated CD/DVD Drive Letter as $NewDrvLetter"
        }
    }#>
}
  
  
switch ($MODE.ToLower()) {
    "config" { 
        $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
        $PS_Session_State = $PS_Session.State

        If ($IMAGETYPE -eq "win2k12") {
            $PS5_deploy = {
                Write-Verbose -Message "Enable .Net Framwork feature"
                Install-WindowsFeature Net-Framework-45-Core -Confirm:$false
                Install-WindowsFeature Net-Framework-45-Features -Confirm:$false

                Write-host "Download WMF 5"
                Invoke-WebRequest "https://download.microsoft.com/download/2/C/6/2C6E1B4A-EBE5-48A6-B225-2D2058A9CEFB/Win8.1AndW2K12R2-KB3134758-x64.msu" -ErrorAction Ignore -usebasicparsing -OutFile "c:\windows\temp\ps5.msu"
                Write-host "Install WMF in Slient mode"
                Start-Process -FilePath wusa.exe -ArgumentList "C:\windows\temp\ps5.msu /extract:c:\windows\temp\ps5" -Wait
                Start-Process -FilePath dism.exe -ArgumentList "/online /add-package /PackagePath:c:\windows\temp\ps5 /IgnoreCheck /quiet /norestart" -NoNewWindow -PassThru -wait
            }  
            $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
            Invoke-Command -session $PS_Session -ScriptBlock $PS5_deploy
            Format-AnsiColor -Message "Deployed PS 5.0" -Style bold -ForegroundColor green
            Remove-PSSession -session $PS_Session -Confirm:$false
              
            #Restart-Computer -ComputerName $VMNAME -Credential $oADCredential -Wait -Timeout 300 
            Format-AnsiColor -Message "restarting win2k12 temp instance" -ForegroundColor black
            Restart-AzureRmVM -Name $VMNAME -ResourceGroupName $RGNAME -Confirm:$false 
            Format-AnsiColor -Message "Waiting for System to come online" -ForegroundColor black
            start-sleep -Seconds 120
            Format-AnsiColor -Message "restart completed" -ForegroundColor black
        }

        $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
        $PS_Session_State = $PS_Session.State
        Format-AnsiColor -Message "Created a PS Session with the following details:"
        Format-AnsiColor -Message "Session State          : $PS_Session_State"
  
        Format-AnsiColor -Message "Enable WinrM and File & Print Sharing" -Style bold -ForegroundColor green
        Invoke-Command -session $PS_Session -ScriptBlock $FPSharing
        Format-AnsiColor -Message "Removing PSSession" -ForegroundColor black
        Remove-PSSession -session $PS_Session -Confirm:$false

        write-host "get and delete active ps session"
        Get-PSSession | Remove-PSSession 
        #net use "\\$privateip\c$" /delete
                    
        if (PSDRIVE | where-object {$_.Name -eq "Z"}) {
            Remove-PSDrive Z
            New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\c$ -Description "Temp drive" -Credential $oADCredential
        } else {
            New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\c$ -Description "Temp drive" -Credential $oADCredential
        }
          
        if (Test-Path Z:) {
            Copy-Item -Path $directorypath\bin\fidelity\ -Destination Z:\ -Recurse -Force -Confirm:$false -verbose
            Format-AnsiColor -Message "bin files copied successfully"
        } else {
            Format-AnsiColor -Message "Failed to map temp instance drive to copy bin data"
            exit 1
        }

        Format-AnsiColor -Message "Deploy DSC module and configuartion to Temp Instance $privateip"
        $curValue = (get-item wsman:\localhost\Client\TrustedHosts).value
        set-item wsman:\localhost\Client\TrustedHosts -value "$privateip" -force
        $cimSession = New-CimSession -ComputerName $privateip -Credential $oADCredential -Authentication Negotiate
          
          
        #run all ps1 files under scripts\ps directory
        Get-ChildItem $directorypath\dsc | ForEach-Object {
            . $_.FullName
        }
        
        [xml]$xmlinfo=get-content $CONFPATH\config.xml
        $dscmodules=($xmlinfo.config.dsc.module)
        $dscmodules
        Set-Location $directorypath\bin
           
        ForEach ($dscmodule in $dscmodules) {
            $modulename=$dscmodule.name 
            $moduleversion=$dscmodule.version
            Write-Host "Module Name $modulename and version $moduleversion"
            <#Write-Host "Compiling dsc module dscmodule with name $modulename and version $moduleversion"
            dscmodule -computername $privateip -dscmodulename $modulename -dscmoduleversion $moduleversion
  
            Write-Host "Run DSC Module to deploy DSC module $modulename with version $moduleversion"
            Start-DscConfiguration -Verbose -Wait -Path "$directorypath\bin\dscmodule\" -Force -CimSession $cimSession
            Write-Host -Message "Deployed all required dsc modules - Completed"#>

            #temp workaround to deploy dsc modules
            $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
            $PS_Session_State = $PS_Session.State
            Format-AnsiColor -Message "Created a PS Session with the following details:"
              
            $dscdeploy = {
                param([string]$modulename,[string]$moduleversion)  
                Write-Host -Message "Deploy dsc module $modulename and Version $moduleversion"
                Save-Module -Name $modulename -RequiredVersion $moduleversion -Path "C:\Program Files\WindowsPowerShell\Modules" -Confirm:$false -Force
                Install-Module -Name $modulename -RequiredVersion $moduleversion -Confirm:$false -Force
            }
            Invoke-Command -session $PS_Session -ScriptBlock $dscdeploy -ArgumentList $modulename,$moduleversion

            #fetch xnetworking dsc module version
            if ($modulename -match "xNetworking") {
                $xnetworkingversion=$moduleversion
            }
        }

        ##Create mof files
        DeployFeatureSet -computername $privateip
        InstallEMET -computername $privateip
        Write-Host "OS type choosen $env:mode"
        imagecleanup -computername $privateip -imagetype $IMAGETYPE
        firewall -computername $privateip -xnetworkingversion $xnetworkingversion
        lgpo -computername $privateip -imagetype $IMAGETYPE
          
          
        Format-AnsiColor -Message "Run DSC Module for DeployFeatureSet"
        Start-DscConfiguration -Verbose -Wait -Path ".\DeployFeatureSet\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module for DeployFeatureSet - Completed"
          
        Format-AnsiColor -Message "Run DSC Module for EMET Installation"
        Start-DscConfiguration -Verbose -Wait -Path ".\InstallEMET\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module for EMET Installation - Completed"

        Format-AnsiColor -Message "Run DSC Module to enable firewall port"
        Start-DscConfiguration -Verbose -Wait -Path ".\firewall\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module to enable firewall port - Completed"
  
        Format-AnsiColor -Message "Run DSC Module for LGPO"
        Start-DscConfiguration -Verbose -Wait -Path ".\LGPO\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module for LGPO - Completed"
  
        Format-AnsiColor -Message "Run DSC Module for Image Cleanup tasks"
        Start-DscConfiguration -Verbose -Wait -Path ".\imagecleanup\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module for Image Cleanup Task - Completed"
        Remove-CimSession -ComputerName $privateip -Confirm:$false 
          
    }
    "sysprep" { 
        $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
        Write-Verbose -Message "Running SysPrep"
        Invoke-Command -session $PS_Session -ScriptBlock {CMD /C ""C:\Windows\System32\Sysprep\Sysprep.bat""}
        Start-Sleep -Seconds 60
          
        Remove-PSSession -session $PS_Session

        Format-AnsiColor -Message "Make sure the VM has been deallocated."
        Stop-AzureRmVM -ResourceGroupName $tempvm.ResourceGroupName -Name $VMNAME -Force
          
        Format-AnsiColor -Message "Set the status of the virtual machine to Generalized."
        Set-AzureRmVm -ResourceGroupName $tempvm.ResourceGroupName -Name $VMNAME -Generalized
          
        Format-AnsiColor -Message "Get the virtual machine."
        $vm = Get-AzureRmVM -Name $VMNAME -ResourceGroupName $tempvm.ResourceGroupName
          
        Format-AnsiColor -Message "Create the image configuration"
	    $curdate=(get-date).ToString()
        $image = New-AzureRmImageConfig -Location $region -SourceVirtualMachineId $vm.ID `
	      	-Tag @{ build_status="readyforscan"; scan_status="blank"; publish_status="blank";datecreated=$curdate; app_id="test_appid"; billing_id="test_billingid" }
          
        Format-AnsiColor -Message "Create the image."
        New-AzureRmImage -Image $image -ImageName $imageName -ResourceGroupName $tempvm.ResourceGroupName 
    }
    Default { 
        Write-Host "Wrong mode supplied; either pass config or sysprep as mode value"
        exit 1
    }
}
    
  
  
  
  
    