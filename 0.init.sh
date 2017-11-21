subId=$(az account list --query [].[id] --output tsv)
sleep 3
tenantId=$(az account list --query [].[tenantId] --output tsv)
sleep 3
rgName=data-$RANDOM-rg #Save it as ps1
loc=eastus2
blobName=demo$RANDOM #Save it as ps1
containerName=sampledata
sqlsvrName=wwimsvr$RANDOM #Save it as ps1
sqldbName=wwimdb
sqladm=sqladmin
sqlpwd=1q2w3e4r5t6Y
adlsName=adls$RANDOM #Save it as ps1
adlaName=adla$RANDOM #Save it as ps1
clusterName=hdi$RANDOM # Save it as ps1
adfName=adf$RANDOM #Save it as ps1
spName=Dataprocess_delete_ME
containerName2=scripts
myTags="Env=demo"
echo $subId, $tenantId, $rgName, $myTags
echo $blobName, $sqlsvrName, $adlsName, $adlaName

mkdir $HOME/clouddrive/1.ADF/
mkdir $HOME/clouddrive/1.ADF/ADFJson
cp ./1.ADF/ADFJson/* $HOME/clouddrive/1.ADF/ADFJson/

echo "Creating the Resource Group"
az group create --name $rgName --location $loc --tags $myTags

echo "Creating the Storage Account..."
az storage account create --name $blobName --resource-group $rgName --sku Standard_LRS --location $loc --tags $myTags

blobConn=$(az storage account show-connection-string --name $blobName --resource-group $rgName --output tsv)
echo $blobConn

echo "Creating the container..."
az storage container create --name $containerName --connection-string $blobConn

echo "Download Sample DB"
file_to_upload="./WideWorldImportersDW-Standard.bacpac"
objName=WideWorldImportersDW-Standard.bacpac
wget -O $file_to_upload https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-Standard.bacpac

echo "Uploading a SQLDB Backup file..."
az storage blob upload --container-name $containerName --file $file_to_upload --name $objName --connection-string $blobConn

echo "Listing the blobs..."
az storage blob list --container-name $containerName --connection-string $blobConn --output table

echo "Creating the SQL Server"
az sql server create --admin-user $sqladm --admin-password $sqlpwd --location $loc --name $sqlsvrName --resource-group $rgName #--tags $myTags
echo "Update Firewall rules"
az sql server firewall-rule create -n openall --start-ip-address 1.1.1.1 --end-ip-addres 255.1.1.1 -g $rgName -s $sqlsvrName
echo "Creating the SQL DB..."
az sql db create --name $sqldbName --resource-group $rgName --server $sqlsvrName --service-objective S3  #--tags $myTags

echo "Restore SQL DB"
bloburi="https://$blobName.blob.core.windows.net/$containerName/$objName"
time=2018-01-01T00:00:00Z
sas=$(az storage blob generate-sas --account-name $blobName --container-name $containerName --name $objName --permissions r --expiry $time --output tsv)
echo $sas
az sql db import -s $sqlsvrName -n $sqldbName -g $rgName -p $sqlpwd -u $sqladm --storage-key $sas --storage-key-type SharedAccessKey --storage-uri $bloburi

read sp_id sp_password <<< $(az ad sp create-for-rbac -n $spName --role contributor --scopes /subscriptions/$subId/resourceGroups/$rgName --password "1q2w3e4r5t6y7u8i9o0p-[=" --query [appId,password] -o tsv)
#az ad sp delete --id 'http://'$spName

echo "Create ADLS"
az dls account create --account $adlsName --resource-group $rgName --encryption-type ServiceManaged --tier Consumption --tags $myTags
echo "Create ADLA"
az dla account create --account $adlaName --default-data-lake-store $adlsName --resource-group $rgName --tags $myTags

# Create Output folders
az dls fs create --account $adlsName --path /data/ --folder
az dls fs create --account $adlsName --path /data/output --folder
az dls fs create --account $adlsName --path /clusters --folder
az dls fs create --account $adlsName --path /clusters/hdiadlcluster --folder

az dls fs access set-owner --account $adlsName --path / --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /system --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /catalog --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /data --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /data/output --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /clusters --owner $sp_id --group $sp_id
az dls fs access set-owner --account $adlsName --path /clusters/hdiadlcluster --owner $sp_id --group $sp_id
az dls fs access set-permission --account $adlsName --path / --permission 777
az dls fs access set-permission --account $adlsName --path /system --permission 777
az dls fs access set-permission --account $adlsName --path /catalog --permission 777
az dls fs access set-permission --account $adlsName --path /data --permission 777
az dls fs access set-permission --account $adlsName --path /data/output --permission 777
az dls fs access set-permission --account $adlsName --path /clusters --permission 777
az dls fs access set-permission --account $adlsName --path /clusters/hdiadlcluster --permission 777
#az dls fs access set-entry --account $adlsName --path / --acl-spec user:$sp_id:rwx
#az dls fs access set-entry --account $adlsName --path /system --acl-spec user:$sp_id:rwx
#az dls fs access set-entry --account $adlsName --path /catalog --acl-spec user:$sp_id:rwx
#az dls fs access set-entry --account $adlsName --path /data --acl-spec user:$sp_id:rwx
#az dls fs access set-entry --account $adlsName --path /data/output --acl-spec user:$sp_id:rwx
#az dls fs access show --account $adlsName --path /data/output

echo "Create Conatiner for ASLA script"
az storage container create --name $containerName2 --connection-string $blobConn

file_to_upload="./1.ADF/ADFUSQLScript/ProcessData.usql"
objName="ProcessData.usql"
echo "Upload a script"
az storage blob upload --container-name $containerName2 --file $file_to_upload --name $objName --connection-string $blobConn

az storage blob list --container-name $containerName2 --connection-string $blobConn --output table

azStorageLinkedSvr='{
    "name": "USQLScript",
    "properties": {
        "description": "",
        "hubName": "'$adfName'_hub",
        "type": "AzureStorage",
        "typeProperties": {
            "connectionString": "'$blobConn'"
        }
    }
}
'
echo $azStorageLinkedSvr > ./1.ADF/ADFJson/USQLScript.json
# on Cloud Shell .\CloudDrive\
echo $azStorageLinkedSvr > $HOME/clouddrive/1.ADF/ADFJson/USQLScript.json

adlslinkedsvr='
{
    "name": "Destination-WWIDataLake",
    "properties": {
        "type": "AzureDataLakeStore",
        "typeProperties": {
            "dataLakeStoreUri": "https://'$adlsName'.azuredatalakestore.net/webhdfs/v1",
            "servicePrincipalId": "'$sp_id'",
            "servicePrincipalKey": "'$sp_password'",
            "tenant": "'$tenantId'",
            "subscriptionId": "'$subId'",
            "resourceGroupName": "'$rgName'"
        }
    }
}
'

echo $adlslinkedsvr > ./1.ADF/ADFJson/Destination-WWIDataLake.json
# on Cloud Shell .\CloudDrive\
echo $azStorageLinkedSvr > $HOME/clouddrive/1.ADF/ADFJson/Destination-WWIDataLake.json

azADLAlink='
{
    "name": "AzureDataLakeAnalyticsLinkedService",
    "properties": {
        "type": "AzureDataLakeAnalytics",
        "typeProperties": {
            "accountName": "'$adlaName'",
            "servicePrincipalId": "'$sp_id'",
            "servicePrincipalKey": "'$sp_password'",
            "tenant": "'$tenantId'",
            "subscriptionId": "'$subId'",
            "resourceGroupName": "'$rgName'"
        }
    }
}'
echo $azADLAlink > ./1.ADF/ADFJson/AzureDataLakeAnalyticsLinkedService.json
# on Cloud Shell .\CloudDrive\
echo $azStorageLinkedSvr > $HOME/clouddrive/1.ADF/ADFJson/AzureDataLakeAnalyticsLinkedService.json

srcwwidw='
{
    "name": "Source-WWIDW",
    "properties": {
        "hubName": "'$adfName'_hub",
        "type": "AzureSqlDatabase",
        "typeProperties": {
            "connectionString": "Data Source='$sqlsvrName'.database.windows.net;Initial Catalog=wwimdb;Integrated Security=False;User ID=sqladmin;Password=1q2w3e4r5t6Y;Connect Timeout=30;Encrypt=True"
        }
    }
}
'
echo $srcwwidw > ./1.ADF/ADFJson/Source-WWIDW.json
# on Cloud Shell .\CloudDrive\
echo $srcwwidw > $HOME/clouddrive/1.ADF/ADFJson/Source-WWIDW.json

pipeline='
{
    "name": "CopyData_WWIDWtoADL",
    "properties": {
        "activities": [
            {
                "type": "Copy",
                "typeProperties": {
                    "source": {
                        "type": "SqlSource",
                        "sqlReaderQuery": "select * from [Dimension].[Customer]"
                    },
                    "sink": {
                        "type": "AzureDataLakeStoreSink",
                        "writeBatchSize": 0,
                        "writeBatchTimeout": "00:00:00"
                    }
                },
                "inputs": [
                    {
                        "name": "InputDatasets-dim-customer"
                    }
                ],
                "outputs": [
                    {
                        "name": "OutputDatasets-dim-customer"
                    }
                ],
                "policy": {
                    "timeout": "1.00:00:00",
                    "concurrency": 1,
                    "executionPriorityOrder": "NewestFirst",
                    "style": "StartOfInterval",
                    "retry": 3,
                    "longRetry": 0,
                    "longRetryInterval": "00:00:00"
                },
                "scheduler": {
                    "frequency": "Day",
                    "interval": 1
                },
                "name": "Export_SQLDB_to_ADLS_Dimension_Customer"
            },
            {
                "type": "Copy",
                "typeProperties": {
                    "source": {
                        "type": "SqlSource",
                        "sqlReaderQuery": "select * from [Dimension].[Date]"
                    },
                    "sink": {
                        "type": "AzureDataLakeStoreSink",
                        "writeBatchSize": 0,
                        "writeBatchTimeout": "00:00:00"
                    }
                },
                "inputs": [
                    {
                        "name": "InputDatasets-dim-date"
                    }
                ],
                "outputs": [
                    {
                        "name": "OutputDatasets-dim-date"
                    }
                ],
                "policy": {
                    "timeout": "1.00:00:00",
                    "concurrency": 1,
                    "executionPriorityOrder": "NewestFirst",
                    "style": "StartOfInterval",
                    "retry": 3,
                    "longRetry": 0,
                    "longRetryInterval": "00:00:00"
                },
                "scheduler": {
                    "frequency": "Day",
                    "interval": 1
                },
                "name": "Export_SQLDB_to_ADLS_Dimension_Date"
            },
            {
                "type": "Copy",
                "typeProperties": {
                    "source": {
                        "type": "SqlSource",
                        "sqlReaderQuery": "select * from [Fact].[Sale]"
                    },
                    "sink": {
                        "type": "AzureDataLakeStoreSink",
                        "writeBatchSize": 0,
                        "writeBatchTimeout": "00:00:00"
                    }
                },
                "inputs": [
                    {
                        "name": "InputDatasets-fact-sale"
                    }
                ],
                "outputs": [
                    {
                        "name": "OutputDatasets-fact-sale"
                    }
                ],
                "policy": {
                    "timeout": "1.00:00:00",
                    "concurrency": 1,
                    "executionPriorityOrder": "NewestFirst",
                    "style": "StartOfInterval",
                    "retry": 3,
                    "longRetry": 0,
                    "longRetryInterval": "00:00:00"
                },
                "scheduler": {
                    "frequency": "Day",
                    "interval": 1
                },
                "name": "Export_SQLDB_to_ADLS_Fact_Sale"
            },
            {
                "type": "DataLakeAnalyticsU-SQL",
                "typeProperties": {
                    "scriptPath": "scripts\\ProcessData.usql",
                    "scriptLinkedService": "USQLScript",
                    "degreeOfParallelism": 5,
                    "priority": 1000,
                    "parameters": {}
                },
                "inputs": [
                    {
                        "name": "OutputDatasets-dim-customer"
                    },
                    {
                        "name": "OutputDatasets-dim-date"
                    },
                    {
                        "name": "OutputDatasets-fact-sale"
                    }
                ],
                "outputs": [
                    {
                        "name": "ADLAOutput"
                    }
                ],
                "policy": {
                    "timeout": "01:00:00",
                    "concurrency": 1,
                    "retry": 3
                },
                "scheduler": {
                    "frequency": "Day",
                    "interval": 1
                },
                "name": "ProcessTransactions",
                "linkedServiceName": "AzureDataLakeAnalyticsLinkedService"
            }
        ],
        "start": "2017-10-31T20:30:36.467Z",
        "end": "2099-12-31T08:00:00Z",
        "isPaused": false,
        "hubName": "'$adfName'_hub",
        "pipelineMode": "Scheduled"
    }
}
'
echo $pipeline > ./1.ADF/ADFJson/CopyData_WWIDWtoADL.json
# on Cloud Shell .\CloudDrive\
echo $pipeline > $HOME/clouddrive/1.ADF/ADFJson/CopyData_WWIDWtoADL.json

cp ./3.HDI/cert-download.pfx $HOME/clouddrive/3.HDI/cert-download.pfx

psParam='
$blobName="'$blobName'"

$adlsName="'$adlsName'"

$adlaName="'$adlaName'"

$clusterName="'$clusterName'"

$adfName="'$adfName'"

$rgName="'$rgName'"
'

echo $psParam > $HOME/clouddrive/psParam.ps1

cp ./1.init-CreateADF.ps1 $HOME/clouddrive/1adfinit.ps1

