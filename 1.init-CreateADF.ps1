# Data Process Demo 
# This script will create demo environment
# for Adanvaced Data Analtyics
Select-AzureRMSubscription -SubscriptionName 'Field: hyssh'
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
#>

# Create Azure Data Factory V1
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

#Remove 
$tmp=Get-AzureRmADServicePrincipal -SearchString "HDIADL"
Remove-AzureRmADApplication -ObjectId (Get-AzureRmADApplication -ApplicationId $tmp.ApplicationId).ObjectId -Force

#HDI with ADLS
$certificatePFX = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificateFilePath, $spPWDHDI)
$rawCertificateData = $certificatePFX.GetRawCertData()
$credential = [System.Convert]::ToBase64String($rawCertificateData)
$HDIApp = New-AzureRmADApplication -DisplayName "HDIADL" -HomePage "https://c0nt0s0.com" -IdentifierUris "https://myc0nt0s0.com" -CertValue $credential -StartDate $certificatePFX.NotBefore -EndDate $certificatePFX.NotAfter
$HDIAppId = $HDIApp.ApplicationId
$servicePrincipalHDI = New-AzureRmADServicePrincipal -ApplicationId $HDIAppId
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path / -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /clusters -AceType User -Id $servicePrincipalHDI.Id -Permissions All

# Set these variables
# https://docs.microsoft.com/en-us/azure/data-lake-store/data-lake-store-hdinsight-hadoop-use-powershell
New-AzureRmHDInsightCluster -ClusterType Spark -OSType Linux -ClusterSizeInNodes $clusterNodes -ResourceGroupName $rgName -ClusterName $clusterName -HttpCredential $httpCredentials -Location $loc -DefaultStorageAccountType AzureDataLakeStore -DefaultStorageAccountName "$adlsName.azuredatalakestore.net" -DefaultStorageRootPath $storageRootPath -Version "3.6" -SshCredential $sshCredentials -AadTenantId $tenantId -ObjectId $servicePrincipalHDI.Id -CertificateFilePath $certificateFilePath -CertificatePassword $spPWDHDI
