
Function bootstrap ([string] $SPNAME,[string]$KVNAME) {
    $hostname=$KVNAME
    Write-Host "Fetch Token for Managed Service Idenity - Core Security Jenkins VM"
    $response = Invoke-WebRequest -Uri http://localhost:50342/oauth2/token -Method GET -Body @{resource="https://vault.azure.net"} -Headers @{Metadata="true"} -usebasicparsing
    $content =$response.Content | ConvertFrom-Json
    $access_token = $content.access_token
    
    if ($access_token) {
        $creddetails = (Invoke-WebRequest -Uri https://${hostname}-kv.vault.azure.net/secrets/${SPNAME}?api-version=2016-10-01 `
        -Method GET -Headers @{Authorization="Bearer $access_token"} -usebasicparsing).content | ConvertFrom-Json
    } else {
        write-local "error fetching token. please investigate"
        exit 1
    }
    
    Write-Host "Setting environment variable for AZURE_CLIENT_SECRET"
    $env:AZURE_CLIENT_SECRET=$creddetails.value
}






