Param (
    
     # Use to set scope to resource group. If no value is provided, scope is set to subscription.
     [Parameter(Mandatory=$false)]
     [String] $ResourceGroup,
    
     # Use to set subscription. If no value is provided, default subscription is used. 
     [Parameter(Mandatory=$false)]
     [String] $SubscriptionId,
    
     [Parameter(Mandatory=$true)]
     [String] $ApplicationDisplayName,
    
     [Parameter(Mandatory=$true)]
     [String] $Password
    )
    
     Login-AzureRmAccount
     Import-Module AzureRM.Resources
    
     if ($SubscriptionId -eq "") 
     {
        $SubscriptionId = (Get-AzureRmContext).Subscription.Id
     }
     else
     {
        Set-AzureRmContext -SubscriptionId $SubscriptionId
     }
    
     if ($ResourceGroup -eq "")
     {
        $Scope = "/subscriptions/" + $SubscriptionId
     }
     else
     {
        $Scope = (Get-AzureRmResourceGroup -Name $ResourceGroup -ErrorAction Stop).ResourceId
     }
    
    
     # Create Service Principal for the AD app
     $ServicePrincipal = New-AzureRMADServicePrincipal -DisplayName $ApplicationDisplayName -Password $Password
     Get-AzureRmADServicePrincipal -ObjectId $ServicePrincipal.Id 
    
     $NewRole = $null
     $Retries = 0;
     While ($NewRole -eq $null -and $Retries -le 6)
     {
        # Sleep here for a few seconds to allow the service principal application to become active (should only take a couple of seconds normally)
        Sleep 15
        New-AzureRMRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $ServicePrincipal.ApplicationId -Scope $Scope | Write-Verbose -ErrorAction SilentlyContinue
        $NewRole = Get-AzureRMRoleAssignment -ObjectId $ServicePrincipal.Id -ErrorAction SilentlyContinue
        $Retries++;
     }