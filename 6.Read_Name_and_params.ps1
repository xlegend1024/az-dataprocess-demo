# You have to run this Poershell script after Azure Cli script 0. to 5.
# Make sure clouddrive is mounted
# Select Azure subscription should be same sa preivous cli
Select-AzureRMSubscription -SubscriptionName '<ReplaceToYourSubscription>'

cd $HOME

# Load resource group name and parameters from File (Shared file service from Azure Storage)
$params = Get-Content $HOME\clouddrive\psParam.dat | Out-String | ConvertFrom-StringData
$rgName=$params.rgName
$blobName=$params.blobName
$adlsName=$params.adlsName
$adlaName=$params.adlaName
$clusterName=$params.clusterName
$adfName=$params.adfName

# set localtion and it should be same as previous
$spName="Dataprocess_delete_ME"
$tenantID = (Get-AzureRmContext).Tenant.TenantId
