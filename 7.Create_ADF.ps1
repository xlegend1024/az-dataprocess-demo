# You have to run this Poershell script after Azure Cli script 0. to 5.
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
