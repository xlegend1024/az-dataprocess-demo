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

$app = Get-AzureRmADServicePrincipal -SearchString $spName
$myrootdir = "/"
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/data
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/data/output
New-AzureRmDataLakeStoreItem -Folder -AccountName $adlsName -Path $myrootdir/clusters

Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path $myrootdir/data -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemOwner -Account $adlsName -Path $myrootdir/data/output -Type User -Id $app.Id
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/data -Permission 777
Set-AzureRmDataLakeStoreItemPermission -Account $adlsName -Path $myrootdir/data/output -Permission 777
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path $myrootdir/data -AceType User -Id $app.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -Account $adlsName -Path $myrootdir/data/output -AceType User -Id $app.Id -Permissions All

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
$certificatePFX = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificateFilePath, $spPWDHDI)
$rawCertificateData = $certificatePFX.GetRawCertData()
$credential = [System.Convert]::ToBase64String($rawCertificateData)
$HDIApp = New-AzureRmADApplication -DisplayName "HDIADL" -HomePage "https://contoso.com" -IdentifierUris "https://mycontoso.com" -CertValue $credential -StartDate $certificatePFX.NotBefore -EndDate $certificatePFX.NotAfter
$HDIAppId = $HDIApp.ApplicationId
$servicePrincipalHDI = New-AzureRmADServicePrincipal -ApplicationId $HDIAppId
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path / -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters/hdiadlcluster -AceType User -Id $servicePrincipalHDI.Id -Permissions All

# Set these variables
# https://docs.microsoft.com/en-us/azure/data-lake-store/data-lake-store-hdinsight-hadoop-use-powershell
New-AzureRmHDInsightCluster -ClusterType Spark -OSType Linux -ClusterSizeInNodes $clusterNodes -ResourceGroupName $rgName -ClusterName $clusterName -HttpCredential $httpCredentials -Location $loc -DefaultStorageAccountType AzureDataLakeStore -DefaultStorageAccountName "$storageAccountName.azuredatalakestore.net" -DefaultStorageRootPath $storageRootPath -Version "3.6" -SshCredential $sshCredentials -AadTenantId $tenantId -ObjectId $servicePrincipalHDI.Id -CertificateFilePath $certificateFilePath -CertificatePassword $spPWDHDI
