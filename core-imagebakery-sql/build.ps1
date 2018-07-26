param(
  [string] $CONFPATH,
  [string] $MODE,
  [string] $AZURE_SUBSCRIPTION_ID, 
  [string] $AZURE_CLIENT_ID, 
  [string] $AZURE_CLIENT_SECRET,
  [string] $AZURE_TENANT_ID
)

write-host "sub id $AZURE_SUBSCRIPTION_ID client id $AZURE_CLIENT_ID"
#set current directory path in variable
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

Format-AnsiColor -Message  "Look for config file and load"
If(Test-Path ("${CONFPATH}\config.xml")) {
  Format-AnsiColor -Message "Config file found. So will load"
  Format-AnsiColor -Message "conf value $CONFPATH"
  Format-AnsiColor -Message "Getting Variables from Config.xml" -Style bold -ForegroundColor green
  [xml]$xmlinfo = Get-Content ${CONFPATH}\config.xml
  #$AZURE_SUBSCRIPTION_ID=($xmlinfo.config.general.subscriptionid.name)
  $AZURE_TENANT_ID=($xmlinfo.config.general.tenantid.name)
  $SPNAME=($xmlinfo.config.general.spname.name)
  #$AZURE_CLIENT_ID=($xmlinfo.config.general.spid.name)
} else {
  Format-AnsiColor -Message "Config not found. Stop!!"
  exit    
}

#bootstrap -SPNAME $SPNAME -KVNAME "imagebakery"
#write-host "env variable $env:AZURE_CLIENT_SECRET"
#login to Azure
$env:arm_subscription_id = $AZURE_SUBSCRIPTION_ID
$env:arm_client_id = $AZURE_CLIENT_ID
$env:arm_client_secret = $AZURE_CLIENT_SECRET
$env:arm_tenant_id = $AZURE_TENANT_ID

# Settings Variables
Format-AnsiColor -Message "Intializing Terraform State" -ForegroundColor black
#fetch tf detail
$tfinfo=configxml_tfinfo -CONFPATH $CONFPATH
$temptfvars=$tfinfo[1]
$initarg=$tfinfo[2]
Write-Host $temptfvars
Write-Host $initarg

Format-AnsiColor -Message "Logging into Azure RM Account" -Style bold -ForegroundColor magenta
azlogin -AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID -AZURE_CLIENT_ID $AZURE_CLIENT_ID `
    -AZURE_CLIENT_SECRET $AZURE_CLIENT_SECRET -AZURE_TENANT_ID $AZURE_TENANT_ID

$images=Get-AzureRmImage | Where-Object {$_.Tags.scan_status -match "pass" -and $_.Name -match "azimg-2k12"}
$imagename=$null
$imagedate=(get-date).AddDays(-30)
foreach($image in $images) {
  if ([datetime]$image.tags.datecreated -gt $imagedate) {
    $imagedate=$image.tags.datecreated
    $imagename=$image.name
  }
}  

#update image id in tempt tf file
$Config = Get-Content -Path $temptfvars
$NewConfig = $Config -replace "imagename=""%imagename%""","imagename=""$imagename"""
Set-Content -Path $temptfvars -Value $NewConfig -Force

Push-Location $tfdir

Write-Host "terraform get"
. $terraform get
checkerror -msg "terraform get failed" -err  $_.Exception.Message

Write-Host "Terraform Initialization stage"
$initarglist = 'init',"-backend-config=""path=/customconfig/terraform.tfstate"""
Write-Host $initarglist
. $terraform $initarglist 
checkerror -msg "terraform init failed" -err  $_.Exception.Message

switch ($MODE.ToLower()) {
"destroyplan" { 
  $arglistplan = 'plan',"-var-file=$temptfvars",'-destroy' 
}
"plan" {
  $arglistplan = $MODE.ToLower(),"-var-file=$temptfvars"
}
"apply" { 
  $arglistplan = $MODE.ToLower(),"-var-file=$temptfvars",'-auto-approve'
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