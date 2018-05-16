# You have to run this Poershell script after Azure Cli script 0. to 5.

# Select Azure subscription should be same sa preivous cli
Select-AzureRMSubscription -SubscriptionName 'Field: hyssh'

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
$loc="eastus2"
$spName="Dataprocess_delete_ME"
$spPWDHDI="1q2w3e4r5t^Y"
$certificateFilePath="$HOME\clouddrive\3.HDI\cert-download.pfx"
$storageRootPath = "/clusters/hdiadlcluster" # E.g. /clusters/hdiadlcluster
$clusterNodes = 2 # The number of nodes in the HDInsight cluster
write-host "*** Type HDInsight admin ID and PW ***"
write-host "*** For example, azureadmin ***"
$httpCredentials = Get-Credential
write-host "*** Type HDInsight user id and PW ***"
write-host "*** For example, azureuser ***"
$sshCredentials = Get-Credential
$tenantID = (Get-AzureRmContext).Tenant.TenantId

<# Not running on cloud shell
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