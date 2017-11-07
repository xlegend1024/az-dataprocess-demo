# Data Process Demo 
# This script will create demo environment
# for Adanvaced Data Analtyics
# for ADF

Login-AzureRmAccount
$rgName="bigdata-demo-rg"
#$loc="eastus2"
$adfName="bigdatademoadf"
$myTags="Env=demo"

<#
$spName = "Dataprocess_delete_ME"
$dataLakeStoreName = "bigdataprocadls"
$app = Get-AzureRmADApplication -DisplayName $spName
$servicePrincipal = Get-AzureRmADServicePrincipal -SearchString $spName
##New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $servicePrincipal.ApplicationId
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path / -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /system -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /system/jobservice -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /system/jobservice/jobs -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /catalog -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
Set-AzureRmDataLakeStoreItemAclEntry -AccountName $dataLakeStoreName -Path /usqlext -AceType User -Id $servicePrincipal.ApplicationId -Permissions All -Verbose
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
