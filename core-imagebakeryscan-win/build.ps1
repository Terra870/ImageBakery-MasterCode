param(
    [string] $CONFPATH,
    [string] $MODE
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
 
Format-AnsiColor -Message "Starting to run Build.ps1 in $MODE mode" -Style bold -ForegroundColor blue
Format-AnsiColor -Message "Script Parent location is -> $directorypath" -ForegroundColor black
Format-AnsiColor -Message "Terraform script location is -> $directorypath\terraform" -ForegroundColor black
 
Format-AnsiColor -Message  "Look for config file $CONFPATH and load"
If(Test-Path ("${CONFPATH}\config.xml")) {
    Format-AnsiColor -Message "Config file found. So will load"
    Format-AnsiColor -Message "conf value $CONFPATH"
    Format-AnsiColor -Message "Getting Variables from Config.xml" -Style bold -ForegroundColor green
    [xml]$xmlinfo = Get-Content ${CONFPATH}\config.xml
    $AZURE_SUBSCRIPTION_ID=($xmlinfo.config.general.subscriptionid.name)
    $AZURE_TENANT_ID=($xmlinfo.config.general.tenantid.name)
    $SPNAME=($xmlinfo.config.general.spname.name)
    $AZURE_CLIENT_ID=($xmlinfo.config.general.spid.name)
} else {
    Format-AnsiColor -Message "Config not found. Stop!!"
    exit    
}

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

$customimageid=(Get-AzureRmImage | Where-Object {$_.Tags.build_status -match "readyforscan"}).Id
$customimagename=(Get-AzureRmImage | Where-Object {$_.Tags.build_status -match "readyforscan"}).Name

# Settings Variables
Format-AnsiColor -Message "Intializing Terraform State" -ForegroundColor black
#fetch tf detail
$tfinfo=configxml_tfinfo -CONFPATH $CONFPATH
$temptfvars=$tfinfo[1]
$initarg=$tfinfo[2]
Write-Host $temptfvars
Write-Host $initarg

#update image id in tempt tf file
$Config = Get-Content -Path $temptfvars
$NewConfig = $Config -replace "image_id=""%image_id%""","image_id=""$customimageid"""
Set-Content -Path $temptfvars -Value $NewConfig -Force

if ($customimagename -match "2k12") {
  $image_type="win2k12"
  $AZ_engg_VM1_Name="tempwin2k12"
} 
if ($customimagename -match "2k16") {
    $image_type="win2k16"
    $AZ_engg_VM1_Name="tempwin2k16"
}
Write-Host "custom Image Name $customimagename ; Image type - $image_type and temp VM Name - $AZ_engg_VM1_Name"
#update image_type and image_name in tempt tf file
$Config = Get-Content -Path $temptfvars
$NewConfig = $Config `
  -replace "image_type=""%image_type%""","image_type=""$image_type""" `
  -replace "AZ_engg_VM1_Name=""%AZ_engg_VM1_Name%""","AZ_engg_VM1_Name=""$AZ_engg_VM1_Name""" 
Set-Content -Path $temptfvars -Value $NewConfig -Force

Push-Location $tfdir

Write-Host "terraform get"
. $terraform get
checkerror -msg "terraform get failed" -err  $_.Exception.Message

Write-Host "Terraform Initialization stage"
$initarglist = 'init',"-backend-config=""path=/customconfig/$IMAGETYPE/terraform.tfstate"""
Write-Host $initarglist
. $terraform $initarglist 
checkerror -msg "terraform init failed" -err  $_.Exception.Message

switch ($MODE.ToLower()) {
  "destroyplan" { 
    $arglistplan = 'plan',"-var-file=$temptfvars",'-destroy' 
  }
  {"apply" -or "plan"} { 
    $arglistplan = $MODE.ToLower(),"-var-file=$temptfvars"
  }
  "destroy" { 
    $arglistplan = $MODE.ToLower(),"-var-file=$temptfvars",'-force'
  }
  Default { 
    Write-Host "Wrong mode supplied"
    exit 1
  }
}

Write-Host "arglist $arglistplan"
Write-Host "terraform $MODE"
. $terraform $arglistplan
checkerror -msg "terraform $MODE failed" -err  $_.Exception.Message

Format-AnsiColor -Message "The last exit code from the execution was $LastExitCode." -Style bold -ForegroundColor magenta 
Pop-Location