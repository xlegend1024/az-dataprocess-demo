Login-AzureRmAccount;

$adla="adla12437"
$sqlsvradd="wwimsvr19530.database.windows.net"
$sqldbName="wwimdb"
$credName="sqldbCred"


# AZURESQLDB
New-AzureRmDataLakeAnalyticsCatalogCredential -AccountName $adla -DatabaseName $sqldbName -CredentialName $credName -Credential (Get-Credential) -DatabaseHost $sqlsvradd -Port 1433;

