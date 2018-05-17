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

# Update permission of ADLS folders
# Following script won't run on cloud shell
# This may be done on local PC or Azure Portal GUI
$app = Get-AzureRmADServicePrincipal -SearchString $spName
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path /data/
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path /data/WWIdw
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path /data/output
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path /clusters

Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path / -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path /system -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path /data/WWIdw -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path /data/output -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path / -Permission 0777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path /system -Permission 0777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path /data/WWIdw -Permission 0777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path /data/output -Permission 0777 
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path / -AceType User -Id $app.Id -Permissions All -Default
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path /system -AceType User -Id $app.Id -Permissions All -Default
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path /data -AceType User -Id $app.Id -Permissions All -Default
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path /data/WWIdw -AceType User -Id $app.Id -Permissions All -Default
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path /data/output -AceType User -Id $app.Id -Permissions All -Default
