# Data Process Demo 
# This script will create demo environment
# for Adanvaced Data Analtyics
# for ADF

#Login-AzureRmAccount
$rgName="bigdata-demo-rg"
$loc="eastus2"
$adfName="bigdatademoadf"
$myTags="Env=demo"
$spName = "Dataprocess_delete_ME"
$spNameHDI="Dataprocess_delete_ME_HDI"
$spPWDHDI="1q2w3e4r5t^Y"
$certificateFilePath="./3.HDI/cert-download.pfx"
$dataLakeStoreName = "bigdataprocadls"
$storageAccountName = $dataLakeStoreName                       # Data Lake Store account name
$storageRootPath = "/clusters/hdiadlcluster" # E.g. /clusters/hdiadlcluster
$clusterName = "bigdatahdispk"
$clusterNodes = 2            # The number of nodes in the HDInsight cluster
$httpCredentials = Get-Credential
$sshCredentials = Get-Credential
$tenantID = (Get-AzureRmContext).Tenant.TenantId

<#
$app = Get-AzureRmADApplication -DisplayName $spName
$servicePrincipal = Get-AzureRmADServicePrincipal -SearchString $spName

Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path / -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /system -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /catalog -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /data -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /data/output -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /clusters -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /clusters/hdiadlcluster -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
#>

$adf=New-AzureRmDataFactory -ResourceGroupName $rgName -Name $adfName –Location "West US" 
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\Source-WWIDW.json
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\USQLScript.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-dim-date.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-fact-sale.json

New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\Destination-WWIDataLake.json
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\AzureDataLakeAnalyticsLinkedService.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\ADLAOutput.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-dim-date.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-fact-sale.json

New-AzureRmDataFactoryPipeline $adf -File .\1.ADF\ADFJson\CopyData_WWIDWtoADL.json

#HDI with ADLS
$servicePrincipalHDI = Get-AzureRmADServicePrincipal -SearchString $spNameHDI
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path / -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters -AceType User -Id $servicePrincipalHDI.Id -Permissions All
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $storageAccountName -Path /clusters/hdiadlcluster -AceType User -Id $servicePrincipalHDI.Id -Permissions All

# Set these variables
New-AzureRmHDInsightCluster `
       -ClusterType Spark `
       -OSType Linux `
       -ClusterSizeInNodes $clusterNodes `
       -ResourceGroupName $rgName `
       -ClusterName $clusterName `
       -HttpCredential $httpCredentials `
       -Location $loc `
       -DefaultStorageAccountType AzureDataLakeStore `
       -DefaultStorageAccountName "$storageAccountName.azuredatalakestore.net" `
       -DefaultStorageRootPath $storageRootPath `
       -Version "3.6" `
       -SshCredential $sshCredentials `
       -AadTenantId $tenantId `
       -ObjectId $servicePrincipalHDI.Id `
       -CertificateFilePath $certificateFilePath `
       -CertificatePassword $spPWDHDI
