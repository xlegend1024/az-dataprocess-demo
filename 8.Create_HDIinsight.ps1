# You have to run this Poershell script after Azure Cli script 0. to 5.

# Select Azure subscription should be same sa preivous cli
$loc="eastus2"
$spName="Dataprocess_delete_ME"
# Password for certification
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
