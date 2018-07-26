Function azlogin([string] $AZURE_SUBSCRIPTION_ID,[string] $AZURE_CLIENT_ID,
[string] $AZURE_CLIENT_SECRET,[string] $AZURE_TENANT_ID) {
    #Azure Login
    $SecurePassword = $AZURE_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
    $cred = new-object -typename System.Management.Automation.PSCredential `
        -argumentlist $AZURE_CLIENT_ID, $SecurePassword

    Login-AzureRmAccount -Credential $cred -Tenant $AZURE_TENANT_ID -SubscriptionId $AZURE_SUBSCRIPTION_ID -ServicePrincipal
    #Select-AzureRmSubscription -SubscriptionId $AZURE_SUBSCRIPTION_ID
}

