param(
    [string] $CONFPATH,
    [string] $MODE,
    [string] $AZURE_SUBSCRIPTION_ID, 
    [string] $AZURE_CLIENT_ID, 
    [string] $AZURE_CLIENT_SECRET,
    [string] $AZURE_TENANT_ID
    #[string] $IMAGETYPE
)
  
write-host "mode $env:mode"
write-host "sub id $AZURE_SUBSCRIPTION_ID client id $AZURE_CLIENT_ID"

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
#$AZURE_SUBSCRIPTION_ID=($xmlinfo.config.general.subscriptionid.name)
#$AZURE_TENANT_ID=($xmlinfo.config.general.tenantid.name)
$SPNAME=($xmlinfo.config.general.spname.name)
#$AZURE_CLIENT_ID=($xmlinfo.config.general.spid.name)
$VMNAME=($xmlinfo.config.general.VM.name)
$RGNAME=($xmlinfo.config.general.resourcegroup.name)
$Img_Name=($xmlinfo.config.general.Image.name)

$sqlcollation=($xmlinfo.config.sqlsettings.collation.name)
$sqlversion=($xmlinfo.config.sqlsettings.version.name)
$installfolder=($xmlinfo.config.sqlsettings.installfolder.name)
$sqlsp=($xmlinfo.config.sqlsettings.sp.name)
$sqlspversion=($xmlinfo.config.sqlsettings.sp.version)
$sqlcu=($xmlinfo.config.sqlsettings.cu.name)
$sqlcuversion=($xmlinfo.config.sqlsettings.cu.version)

Write-Host "Set unique Image Name"
$FNDSuffix = Get-Date -Format "yyMMdd"
$FNTSuffix = Get-Date -Format "HHmmss"
$FNSuffix = $FNDSuffix + "-" + $FNTSuffix
$imageName = "$Img_Name-$FNSuffix.vhd"
  
#bootstrap -SPNAME $SPNAME -KVNAME "imagebakery"
#write-host "env variable $env:AZURE_CLIENT_SECRET"
#login to Azure
$env:arm_subscription_id = $AZURE_SUBSCRIPTION_ID
$env:arm_client_id = $AZURE_CLIENT_ID
$env:arm_client_secret = $AZURE_CLIENT_SECRET
$env:arm_tenant_id = $AZURE_TENANT_ID
  
Format-AnsiColor -Message "Logging into Azure RM Account" -Style bold -ForegroundColor magenta
azlogin -AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID -AZURE_CLIENT_ID $AZURE_CLIENT_ID `
    -AZURE_CLIENT_SECRET $AZURE_CLIENT_SECRET -AZURE_TENANT_ID $AZURE_TENANT_ID
  
#Find Temp VM instance details
Write-Host "fetching temp VM instance details"
$tempvm=Find-AzureRmResource -TagName Name -TagValue $VMNAME | Where-Object {$_.ResourceType -match "virtualMachines"}
$privateip=(Get-AzureRmNetworkInterface -Name $VMNAME-ni -ResourceGroupName $tempvm.ResourceGroupName).IpConfigurations.PrivateIpAddress
$region=(Get-AzureRmVM -ResourceGroupName $tempvm.ResourceGroupName -Name $tempvm.Name).Location

Format-AnsiColor -Message "restarting temp vm instance" -ForegroundColor black
Restart-AzureRmVM -Name $VMNAME -ResourceGroupName $tempvm.ResourceGroupName -Confirm:$false 
#Format-AnsiColor -Message "Waiting for System to come online" -ForegroundColor black
start-sleep -Seconds 180
#systemcheck -computername $privateip
Format-AnsiColor -Message "restart completed" -ForegroundColor black
  
$sUserName =  "$VMNAME\Harlequin"
$sSecPassword =  "Password123789456" | ConvertTo-SecureString -AsPlainText -Force
$oADCredential = New-Object System.Management.Automation.PSCredential ($sUserName, $sSecPassword)
  
$hosts = "$VMNAME,$privateip"
Format-AnsiColor -Message "Running WsManInstance command for the following hosts $hosts"
Set-WSManInstance -ResourceURI winrm/config/client -ValueSet @{TrustedHosts=$hosts}

$dvddrivechange = {
    #Delete sysprep.bat file if any
    if (test-path -path "C:\Windows\system32\sysprep\Sysprep.bat") {
        Remove-Item -Path "C:\Windows\system32\sysprep\Sysprep.bat" -Force -Confirm:$false
    }
    
    <##change dvd drive
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
        Format-AnsiColor -Message "Connect to Temp Instance $privateip"
        $curValue = (get-item wsman:\localhost\Client\TrustedHosts).value
        set-item wsman:\localhost\Client\TrustedHosts -value "$privateip" -force
        $cimSession = New-CimSession -ComputerName $privateip -Credential $oADCredential -Authentication Negotiate

        Format-AnsiColor -Message "Loading all DSC Modules"
        Get-ChildItem $directorypath\dsc | ForEach-Object {
            . $_.FullName
        }

        $dscmodules=($xmlinfo.config.dsc.module)  
        
        Set-Location $directorypath\bin
        Format-AnsiColor -Message "Compiling server feature dscmodule"
        serverfeature -computername $privateip

        ForEach ($dscmodule in $dscmodules) {
            $modulename=$dscmodule.name 
            $moduleversion=$dscmodule.version
            Write-Host "Module Name $modulename and version $moduleversion"
            <#ForEach ($dscmodule in $dscmodules) {
            Format-AnsiColor -Message "Compiling dsc module dscmodule with name " $dscmodule.name " and version " $dscmodule.version
            dscmodule -computername $privateip -dscmodulesname $dscmodule.name -dscmodulesversion $dscmodule.version

            Format-AnsiColor -Message "Run DSC Module to deploy required DSC modules"
            Start-DscConfiguration -Verbose -Wait -Path ".\dscmodule\" -Force -CimSession $cimSession
            Format-AnsiColor -Message "Deployed all required dsc modules - Completed"
            }#>

            $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
            $PS_Session_State = $PS_Session.State
            Format-AnsiColor -Message "Created a PS Session with the following details: $PS_Session_State"
          
            $dscdeploy = {
                param([string]$modulename,[string]$moduleversion)  
                Write-Host -Message "Deploy dsc module $modulename and Version $moduleversion"
                Save-Module -Name $modulename -RequiredVersion $moduleversion -Path "C:\Program Files\WindowsPowerShell\Modules" -Confirm:$false -Force
                Install-Module -Name $modulename -RequiredVersion $moduleversion -Confirm:$false -Force
            }
            Invoke-Command -session $PS_Session -ScriptBlock $dscdeploy -ArgumentList $modulename,$moduleversion
        }   
        
        Format-AnsiColor -Message "change dvd drive letter"
        Invoke-Command -session $PS_Session -ScriptBlock $dvddrivechange

        Format-AnsiColor -Message "Compiling dsc module diskconfiguration"
        diskconfiguration -computername $privateip

        Format-AnsiColor -Message "Compiling unzip module "
        unzip -computername $privateip -zipfile "D:\SQLServer$sqlversion.zip" -destinationfol "D:\"

        Format-AnsiColor -Message "Compiling dsc module for sql $sqlversion"
        #$secpasswd = ConvertTo-SecureString "Sabmiller@010" -AsPlainText -Force
        #$sacred = New-Object System.Management.Automation.PSCredential ("sa", $secpasswd)
        sqldeploy -computername $tempvm.Name -computerip $privateip -SQLCollation $sqlcollation `
            -sqlversion $sqlversion -installfolder $installfolder
        
        Format-AnsiColor -Message "Compiling imagecleanup module" 
        imagecleanup -computername $privateip #-imagetype $IMAGETYPE

        Format-AnsiColor -Message "Compiling sql sp module for SQL $sqlversion $sqlsp"
        sqlsp -computername $privateip -sqlversion $sqlversion -sqlsp $sqlsp -sqlspversion $sqlspversion

        Format-AnsiColor -Message "Compiling sql cu module $sqlversion $sqlcu"
        sqlcu -computername $privateip -sqlversion $sqlversion -sqlsp $sqlsp -sqlspversion $sqlspversion `
            -sqlcu $sqlcu -sqlcuversion $sqlcuversion
        
        Format-AnsiColor -Message "Run DSC Module to deploy server feature required from SQL"
        Start-DscConfiguration -Verbose -Wait -Path ".\serverfeature\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Deployed feature dsc modules - Completed"

        Format-AnsiColor -Message "Run diskconfiguration Module to deploy required DSC modules"
        Start-DscConfiguration -Verbose -Wait -Path ".\diskconfiguration\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Deployed all required disk configuration dsc modules - Completed"

        Format-AnsiColor -Message "Copy SQL Installer from storage account"
        $rand= $AZURE_SUBSCRIPTION_ID.Split("-")[4].ToLower()
        $SA="imagebakery$rand"
        $SAKEY=Get-AzureRmStorageAccountKey -ResourceGroupName $tempvm.ResourceGroupName -Name $SA
        #checkerror "Storage account is not accesible or permission denied"
        $CTX=New-AzureStorageContext -StorageAccountName $SA -StorageAccountKey ($SAKEY| `
          where-object {$_.Keyname -eq 'key1'}).value

        if ((Test-path -path "C:\SQLServer$sqlversion.zip") -eq $true)  {
            Format-AnsiColor -Message "SQL Installer Already present jut need to copy to local instance"
        } else {
            Get-AzureStorageBlobContent -Container "installer" -Blob "SQLServer$sqlversion.zip" -Destination "C:\" `
            -Context $CTX -Force
        }

        Format-AnsiColor -Message "Copy SQL Installer to local instance"
        if (PSDRIVE | where-object {$_.Name -eq "Z"}) {
            Remove-PSDrive Z
            New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\d$ -Description "Temp drive" -Credential $oADCredential
        } else {
            New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\d$ -Description "Temp drive" -Credential $oADCredential
        }

        if (Test-Path -path "Z:") {
            if ((Test-Path -path "Z:\SQLServer${sqlversion}.zip") -eq $false) {
                Copy-Item -Path C:\SQLServer${sqlversion}.zip -Destination Z:\ -Recurse -Force -Confirm:$false -verbose
                Format-AnsiColor -Message "SQL installer copied successfully"
                Copy-Item -Path $directorypath\bin\fidelity\ -Destination Z:\ -Recurse -Force -Confirm:$false -verbose
                Format-AnsiColor -Message "bin files copied successfully"
            } else {
                Format-AnsiColor -Message "SQL installer already there"
            }
            Remove-Item -Path C:\SQLServer$sqlversion.zip -Confirm:$false -Force
        } else {
            Format-AnsiColor -Message "Failed to map temp instance drive to copy bin data"
            exit 1
        }

        Format-AnsiColor -Message "Unzip SQL installer"
        Start-DscConfiguration -Verbose -Wait -Path ".\unzip\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Unzip dsc module - Completed"

        Format-AnsiColor -Message "Run SQL $sqlversion DSC module"
        Start-DscConfiguration -Verbose -Wait -Path ".\sqldeploy\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "SQL DSC Module - Completed"

        Format-AnsiColor -Message "Run SQL $sqlversion SP $sqlsp DSC module"
        Start-DscConfiguration -Verbose -Wait -Path ".\sqlsp\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "SQL 2k12 SP - Completed"

        Format-AnsiColor -Message "Run SQL $sqlversion $sqlsp $sqlcu DSC module"
        Start-DscConfiguration -Verbose -Wait -Path ".\sqlcu\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "SQL $sqlversion cu $sqlcu - Completed"

        Format-AnsiColor -Message "Run DSC Module for Image Cleanup tasks"
        Start-DscConfiguration -Verbose -Wait -Path ".\imagecleanup\" -Force -CimSession $cimSession
        Format-AnsiColor -Message "Run DSC Module for Image Cleanup Task - Completed"
        Remove-CimSession -ComputerName $privateip -Confirm:$false 
    }

    "sysprep" { 
        Write-Verbose -Message "Running SysPrep"
        $PS_Session = New-PSSession -Computername $privateip -credential $oADCredential
        Write-Verbose -Message "Running SysPrep"
        Invoke-Command -session $PS_Session -ScriptBlock {CMD /C ""C:\Windows\System32\Sysprep\Sysprep.bat""}
        start-Sleep -Seconds 90
        #systemcheck -computername $privateip
          
        Remove-PSSession -session $PS_Session

        Format-AnsiColor -Message "Make sure the VM has been deallocated."
        Stop-AzureRmVM -ResourceGroupName $tempvm.ResourceGroupName -Name $VMNAME -Force
          
        Format-AnsiColor -Message "Set the status of the virtual machine to Generalized."
        Set-AzureRmVm -ResourceGroupName $tempvm.ResourceGroupName -Name $VMNAME -Generalized
          
        Format-AnsiColor -Message "Get the virtual machine."
        $vm = Get-AzureRmVM -Name $VMNAME -ResourceGroupName $tempvm.ResourceGroupName
          
        Format-AnsiColor -Message "Create the image configuration"
        $curdate=(get-date).ToString()
        $image = New-AzureRmImageConfig -Location $region -SourceVirtualMachineId $vm.ID -Tag @{collation=$sqlcollation;datecreated=$curdate}
          
        Format-AnsiColor -Message "Create the image."
        New-AzureRmImage -Image $image -ImageName $imageName -ResourceGroupName $tempvm.ResourceGroupName 
    }

    Default { 
        Write-Host "Wrong mode supplied; either pass config or sysprep as mode value"
        exit 1
    }
}