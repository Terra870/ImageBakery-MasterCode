function checkerror ([string]$msg,[string]$err) {
    if($? -ne $true) {
         Write-Verbose "ERROR: $msg"
         exit 1
    }
}