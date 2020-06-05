$subId = "eced600c-1185-4ae6-8b70-868d11f0e810"
$DataFactoryName = "whhenderDFTrainingDF"
$DataLakeName = "whhenderdftrainingadl"
$SPKey = "aFEn.ssz6O3.u8t36.GXgB.YyA9Lj.6_DF"
$SPID = "62b13d06-5780-4431-b2c4-56d3c0888884"
$Tenant = (Get-AzSubscription -SubscriptionId $subId).TenantId
$DataLakeStoreURI = "https://" + $DataLakeName + ".azuredatalakestore.net/webhdfs/v1"
$RGName = "DFTrainingScenariosRG"

$FilePath = "parametersedit.json"
$FilePath2 = "parameterseditcompare.json"

$fileContent = Get-Content $FilePath -raw | ConvertFrom-Json 

$fileContent.parameters.factoryName.value = $DataFactoryName
$fileContent.parameters.accounts_whhenderdftrainingadl_name.value = $DataLakeName
$fileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_dataLakeStoreUri.value = $DataLakeStoreURI
$fileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_resourceGroupName.value = $RGName
$fileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_servicePrincipalId.value = $SPID
$fileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_subscriptionId.value = $subId
$fileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_tenant.value = $Tenant
$fileContent.parameters.AzureDataLakeStoreGen1_servicePrincipalKey.value = $SPKey

$fileContent | ConvertTo-Json -depth 32| set-content $FilePath2

