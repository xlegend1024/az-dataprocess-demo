# Data Process Demo 
# This script will create demo environment
# for Adanvaced Data Analtyics
cd $HOME
$params = Get-Content $HOME\clouddrive\psParam.dat | Out-String | ConvertFrom-StringData
$rgName=$params.rgName
$blobName=$params.blobName
$adlsName=$params.adlsName
$adlaName=$params.adlaName
$clusterName=$params.clusterName
$adfName=$params.adfName 
$loc="eastus2"
$spName="Dataprocess_delete_ME"
$spNameHDI="Dataprocess_delete_ME_HDI"
$spPWDHDI="1q2w3e4r5t^Y"
$certificateFilePath="$HOME\clouddrive\3.HDI\cert-download.pfx"
$storageAccountName = $adlsName # Data Lake Store account name
$storageRootPath = "/clusters/hdiadlcluster" # E.g. /clusters/hdiadlcluster
$clusterNodes = 2 # The number of nodes in the HDInsight cluster
write-host "*** Type HDInsight admin ID and PW ***"
write-host "*** For example, azureadmin ***"
$httpCredentials = Get-Credential
write-host "*** Type HDInsight user id and PW ***"
write-host "*** For example, azureuser ***"
$sshCredentials = Get-Credential
$tenantID = (Get-AzureRmContext).Tenant.TenantId

$app = (Get-AzureRmADApplication -DisplayName $spName)[0]
$myrootdir = "/"
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/data
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/data/output
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/clusters
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/clusters/hdiadlcluste

Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path / -AceType User -Id $app.ApplicationId -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /system -AceType User -Id $app.ApplicationId -Permissions All 
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /catalog -AceType User -Id $app.ApplicationId -Permissions All 
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /data -AceType User -Id $app.ApplicationId -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /data/output -AceType User -Id $app.ApplicationId -Permissions All
#Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /clusters -AceType User -Id $app.ApplicationId -Permissions All
#Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /clusters/hdiadlcluster -AceType User -Id $app.ApplicationId -Permissions All

Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/data -Permission 777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/data/output -Permission 777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/clusters -Permission 777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/clusters/hdiadlcluste -Permission 777

$adf=New-AzureRmDataFactory -ResourceGroupName $rgName -Name $adfName –Location "West US" 
New-AzureRmDataFactoryLinkedService $adf -File $HOME\CloudDrive\1.ADF\ADFJson\Source-WWIDW.json
New-AzureRmDataFactoryLinkedService $adf -File $HOME\CloudDrive\1.ADF\ADFJson\USQLScript.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\input-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\input-dim-date.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\input-fact-sale.json

New-AzureRmDataFactoryLinkedService $adf -File $HOME\CloudDrive\1.ADF\ADFJson\Destination-WWIDataLake.json
New-AzureRmDataFactoryLinkedService $adf -File $HOME\CloudDrive\1.ADF\ADFJson\AzureDataLakeAnalyticsLinkedService.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\ADLAOutput.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\output-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\output-dim-date.json
New-AzureRmDataFactoryDataset $adf -File $HOME\CloudDrive\1.ADF\ADFJson\output-fact-sale.json

New-AzureRmDataFactoryPipeline $adf -File $HOME\CloudDrive\1.ADF\ADFJson\CopyData_WWIDWtoADL.json

#HDI with ADLS
$servicePrincipalHDI = Get-AzureRmADServicePrincipal -SearchString $spNameHDI
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path / -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters/hdiadlcluster -AceType User -Id $servicePrincipalHDI.Id -Permissions All

# Set these variables
New-AzureRmHDInsightCluster -ClusterType Spark -OSType Linux -ClusterSizeInNodes $clusterNodes -ResourceGroupName $rgName -ClusterName $clusterName -HttpCredential $httpCredentials -Location $loc -DefaultStorageAccountType AzureDataLakeStore -DefaultStorageAccountName "$storageAccountName.azuredatalakestore.net" -DefaultStorageRootPath $storageRootPath -Version "3.6" -SshCredential $sshCredentials -AadTenantId $tenantId -ObjectId $servicePrincipalHDI.Id -CertificateFilePath $certificateFilePath -CertificatePassword $spPWDHDI
