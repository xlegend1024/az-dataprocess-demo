# Setup Environment

Run following scripts to setup an demo environment on [Azure portal](https://portal.azure.com).
To save time use [Cloud Shell](https://azure.microsoft.com/en-us/features/cloud-shell/) on the portal.

0. [0.Set Sub and pwd.azcli]('https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/0.Set_and_pwd.azcli')
    - Define subscription name and password 

1. [1.Set Service Names.azcli](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/1.Set_Service_Names.azcli)
    - Declear parameter name such as, resource group, blob and so on

1. [2.Create Blob.azcli](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/2.Create_Blob.azcli)
    - Create a blob storage 
    - Upload SQL backup file and U-SQL script

1. [3.Restore SQL DB.azcli](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/3.Restore_SQL_DB.azcli)
    - Create a SQL database 
    - Restore backup to SQL DB

1. [4.Create ADL.azcli](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/4.Create_ADL.azcli)
    - Create ADLS and ADLA
    - Update permission on folders

1. [5.Build ADF Activities.azcli](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/5.Build_ADF_Activities.azcli)
    - Build activities and pipeline

1. [6.Read Name and params.ps1](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/6.Read_Name_and_params.ps1)
    - Before you run this powershell script, make sure you're runing PowerShell on cloud shell.

1. [7.Create ADF.ps1](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/7.Create_ADF.ps1)
    - Create ADF service
    - Upload activities and pipeline

1. [8.Create_HDInsight.ps1](https://raw.githubusercontent.com/xlegend1024/az-dataprocess-demo/master/8.Create_HDInsight.ps1)
    - Create HDInsight on ADLS
