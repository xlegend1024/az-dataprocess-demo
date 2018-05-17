# You have to run this Poershell script after Azure Cli script 0. to 5.

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

# Set Azure Region, it should be same as where ADLS is
$loc="eastus2"

# Set SP Name
$spName="Dataprocess_delete_ME"

# Password for certification
$spPWDHDI="1q2w3e4r5t^Y"
$certificateFilePath="$HOME\clouddrive\3.HDI\cert-download.pfx"

# Set HDI root path on ADLS
$storageRootPath = "/clusters/hdiadlcluster" # E.g. /clusters/hdiadlcluster

# The number of nodes in the HDInsight cluster
$clusterNodes = 2 

# Set HDInsight admin cred
write-host "*** Type HDInsight admin ID and PW ***"
write-host "*** For example, azureadmin ***"

#
$httpCredentials = Get-Credential
write-host "*** Type HDInsight user id and PW ***"
write-host "*** For example, azureuser ***"
$sshCredentials = Get-Credential
$tenantID = (Get-AzureRmContext).Tenant.TenantId

# Remove exsiting SP 
$tmp=Get-AzureRmADServicePrincipal -SearchString "HDIADL"
Remove-AzureRmADApplication -ObjectId (Get-AzureRmADApplication -ApplicationId $tmp.ApplicationId).ObjectId -Force

# Create SP for HDInsight with ADLS
# May work with Azure Key Vault for more secure environment 
$certificatePFX = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificateFilePath, $spPWDHDI)
$rawCertificateData = $certificatePFX.GetRawCertData()
$credential = [System.Convert]::ToBase64String($rawCertificateData)
$HDIApp = New-AzureRmADApplication -DisplayName "HDIADL" -HomePage "https://c0nt0s0.com" -IdentifierUris "https://myc0nt0s0.com" -CertValue $credential -StartDate $certificatePFX.NotBefore -EndDate $certificatePFX.NotAfter
$HDIAppId = $HDIApp.ApplicationId
$servicePrincipalHDI = New-AzureRmADServicePrincipal -ApplicationId $HDIAppId
# Update permission
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path / -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $adlsName -Path /clusters -AceType User -Id $servicePrincipalHDI.Id -Permissions All

# Set these variables
# https://docs.microsoft.com/en-us/azure/data-lake-store/data-lake-store-hdinsight-hadoop-use-powershell
New-AzureRmHDInsightCluster -ClusterType Spark -OSType Linux -ClusterSizeInNodes $clusterNodes -ResourceGroupName $rgName -ClusterName $clusterName -HttpCredential $httpCredentials -Location $loc -DefaultStorageAccountType AzureDataLakeStore -DefaultStorageAccountName "$adlsName.azuredatalakestore.net" -DefaultStorageRootPath $storageRootPath -Version "3.6" -SshCredential $sshCredentials -AadTenantId $tenantId -ObjectId $servicePrincipalHDI.Id -CertificateFilePath $certificateFilePath -CertificatePassword $spPWDHDI
