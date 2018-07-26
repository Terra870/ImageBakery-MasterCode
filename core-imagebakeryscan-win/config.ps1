param(
    [string] $CONFPATH
)
  
#set current directory path in variable
$Script_Name = $MyInvocation.MyCommand.Name
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$ErrorActionPreference = "Stop"
$tfdir="$directorypath\terraform"
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
  
$USERNAME=($xmlinfo.config.terraform.var | where-object {$_.name -eq "AZ_engg_VM1_UserName"}).value
$PASS=($xmlinfo.config.terraform.var | where-object {$_.name -eq "AZ_engg_VM1_Pass"}).value
    
    
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
$tempvm=Find-AzureRmResource -TagName instancetype -TagValue "tempimagebakeryvm" | Where-Object {$_.ResourceType -match "virtualMachines"}
$VMNAME=$tempvm.name
$privateip=(Get-AzureRmNetworkInterface -Name $VMNAME-ni -ResourceGroupName $tempvm.ResourceGroupName).IpConfigurations.PrivateIpAddress
$region=(Get-AzureRmVM -ResourceGroupName $tempvm.ResourceGroupName -Name $tempvm.Name).Location

Format-AnsiColor -Message "restarting temp instance" -ForegroundColor black
Restart-AzureRmVM -Name $VMNAME -ResourceGroupName $tempvm.ResourceGroupName -Confirm:$false 
Format-AnsiColor -Message "Waiting for System to come online" -ForegroundColor black
start-sleep -Seconds 120
Format-AnsiColor -Message "restart completed" -ForegroundColor black  
 
$sUserName =  "$VMNAME\$USERNAME"
$sSecPassword =  "$PASS" | ConvertTo-SecureString -AsPlainText -Force
$oADCredential = New-Object System.Management.Automation.PSCredential ($sUserName, $sSecPassword)
  
$hosts = "$VMNAME,$privateip"
Format-AnsiColor -Message "Running WsManInstance command for the following hosts $hosts"
Set-WSManInstance -ResourceURI winrm/config/client -ValueSet @{TrustedHosts=$hosts}
  
  
Format-AnsiColor -Message "Copy CISCAT Binaries from storage account"
$SA="imagebakerysa"
$SAKEY=Get-AzureRmStorageAccountKey -ResourceGroupName $tempvm.ResourceGroupName -Name $SA
#checkerror "Storage account is not accesible or permission denied"
$CTX=New-AzureStorageContext -StorageAccountName $SA -StorageAccountKey ($SAKEY| `
  where-object {$_.Keyname -eq 'key1'}).value

if ((Test-path -path "D:\cis-cat-dissolvable.zip") -eq $true)  {
    Format-AnsiColor -Message "CISCAT Binaries already present jut need to copy to local instance"
} else {
    Get-AzureStorageBlobContent -Container "installer" -Blob "cis-cat-dissolvable.zip" -Destination "D:\" `
    -Context $CTX -Force
}

Format-AnsiColor -Message "Copy CISCAT Binaries to local instance"
if (PSDRIVE | where-object {$_.Name -eq "Z"}) {
    Remove-PSDrive Z
    New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\d$ -Description "Temp drive" -Credential $oADCredential
} else {
    New-PSDrive -Name Z -PSProvider FileSystem -Root \\$privateip\d$ -Description "Temp drive" -Credential $oADCredential
}

if (Test-Path -path "Z:") {
    if ((Test-Path -path "Z:\cis-cat-dissolvable.zip") -eq $false) {
        Copy-Item -Path D:\cis-cat-dissolvable.zip -Destination Z:\ -Recurse -Force -Confirm:$false -verbose
        Format-AnsiColor -Message "CISCAT Binaries copied successfully"
    } else {
        Format-AnsiColor -Message "CISCAT binaries already there"
    }
    Remove-Item -Path D:\cis-cat-dissolvable.zip -Confirm:$false -Force
} else {
    Format-AnsiColor -Message "Failed to map temp instance drive to copy bin data"
    exit 1
}     

#execute ciscat tool on temp server
$PS_Session = New-PSSession -Computername $privateip -credential $oADCredential

#ciscat scan code that will execute on remote temp instance
$ciscat_scan = {
    If (test-path -path D:\cis-cat-dissolvable.zip) {
        Write-Verbose -Message "unzip CISCAT binaries"
        Add-Type -assembly "system.io.compression.filesystem"
        [io.compression.zipFile]::ExtractToDirectory("D:\cis-cat-dissolvable.zip", "D:\")

        Write-Verbose -Message "Running CISCAT.BAT file in cli mode"
        Set-Location "D:\cis-cat-dissolvable\cis-cat-full"
        Start-Process -FilePath "D:\cis-cat-dissolvable\cis-cat-full\cis-cat-autodetect-os.bat" -Wait -NoNewWindow

        Write-Verbose -Message "Check CISCAT score"
        Get-Content -Path "D:\cis-cat-dissolvable\cis-cat-full\temp*.txt" | Select-Object -last 1
        $cisscore=(Get-Content -Path "D:\cis-cat-dissolvable\cis-cat-full\temp*.txt" | Select-Object -last 1).substring(7,2)
        return $cisscore
    } else {
        Write-Verbose -Message "ciscat binaries not available"
        exit 1
    }
}  
$cisscore=Invoke-Command -session $PS_Session -ScriptBlock $ciscat_scan

Write-Host "CIS SCORE - $cisscore"
#assign variable for tags
$tagExists = $false
$tagbuildstatus = "build_status"
$tagValuebuildstatus = "scanned"
$tagscanstatus = "scan_status"

if ($cisscore -ge 90) {$tagvaluescanstatus = "pass"} else {$tagvaluescanstatus = "fail"}
$toAddbuildstatus = @{Name="$tagbuildstatus";Value="$tagvaluebuildstatus"}
$toAddscanstatus = @{Name="$tagscanstatus";Value="$tagvaluescanstatus"}

#Fetch azure vm tags 
$TagsOriginal = (Get-AzureRmImage | Where-Object {$_.Tags.build_status -match "readyforscan"}).tags
$customimagename=(Get-AzureRmImage | Where-Object {$_.Tags.build_status -match "readyforscan"}).Name
#Logic to remove tag with old value from vm tag list
if($TagsOriginal)
{
    #validate if tag already exists
    $hash=$null
    $hash=@{}
    [System.Collections.ArrayList]$vmTagsArrayList = $TagsOriginal
    foreach($tag in $vmTagsArrayList) {
        $hash[$tag.Key]=$tag.Value
        if($tag.Key -eq "build_status" ) {
	        $hash[$tag.Key] = "scanned"
        }
        if($tag.Key -eq "scan_status" ) {
	        $hash[$tag.Key] = $tagvaluescanstatus
        }
        if($tag.Key -eq "publish_status" -and $tagvaluescanstatus -eq "pass") {
            $hash[$tag.Key] = "published"
        }
    }
}

#update azure vm with new tag list
Set-AzureRmResource -ResourceGroupName $tempvm.ResourceGroupName -ResourceName $customimagename `
    -ResourceType "Microsoft.Compute/images" -Tag $hash -Force

