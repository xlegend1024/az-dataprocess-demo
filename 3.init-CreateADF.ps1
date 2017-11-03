# Data Process Demo 
# This script will create demo environment
# for Adanvaced Data Analtyics
# for ADF

#Login-AzureRmAccount
$rgName="bigdata-demo-rg"
#$loc="eastus2"
$adfName="bigdatademoadf"
$myTags="Env=demo"

$adf=New-AzureRmDataFactory -ResourceGroupName $rgName -Name $adfName –Location "West US" 
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\Source-WWIDW.json
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\Destination-WWIDataLake.json
New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\USQLScript.json
# Can't get authorization via PowerShell
#New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\AzureDataLakeAnalyticsLinkedService.json

New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\ADLAOutput.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-dim-date.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\input-fact-sale.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-dim-cust.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-dim-date.json
New-AzureRmDataFactoryDataset $adf -File .\1.ADF\ADFJson\output-fact-sale.json

New-AzureRmDataFactoryLinkedService $adf -File .\1.ADF\ADFJson\CopyData_WWIDWtoADL.json
