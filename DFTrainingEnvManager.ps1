[CmdletBinding(DefaultParameterSetName = 'LaunchScenario')]

param
(
    [Parameter(Mandatory=$true,ParameterSetName='SetUp')]
    [string] $Subscription,
    [Parameter(ParameterSetName='SetUp')]
    [string] $Region = "centralus",
    [Parameter(ParameterSetName='SetUp')]
    [string] $ResourceGroupName = "datafactorytrainingrg"+($env:UserName),
    [Parameter(ParameterSetName='SetUp')]
    [string] $DataLakeName = "dftrainingadl"+($env:UserName),
    [Parameter(ParameterSetName='SetUp')]
    [string] $DataFactoryName = "dftrainingadf"+($env:UserName),
    [Parameter(ParameterSetName='SetUp')]
    [string] $ServicePrincipalName = "dftrainingsp"+($env:UserName),
    [Parameter(ParameterSetName='SetUp')]
    [string] $SFTPUserName = "sftpuser1",
    [Parameter(ParameterSetName='SetUp')]
    [string] $SFTPPassword = "sm4rtW@ter!",
    [Parameter(ParameterSetName='SetUp')]
    [string] $SFTPName = "sftp-group",
    [Parameter(Mandatory=$true, ParameterSetName='SetUp')]
    [switch] $SetUp,
    [Parameter (ParameterSetName = 'SetUp')]
    [string] $BlobStoreName = "dftrainingabs"+($env:UserName),
    [Parameter (ParameterSetName = 'SetUp')]
    [string] $FileShareName = "dftrainingafs"+($env:UserName),
    [Parameter(ParameterSetName='CleanUp')]
    [switch] $CleanUp,
    [Parameter(ParameterSetName='LaunchScenario')]
    [ValidateSet(0,1,2,3,4)]
    [string] $Scenario
)

##################################################
# Functions
##################################################

###################
# Deploy Data Factory Linked Services, Datasets, and Pipelines
###################
Function Deploy-DFScenario{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ScenarioNumber,
        [Parameter(Mandatory=$true)]
        [string]$DataFactoryName,
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [string]$SPKey,
        [Parameter(Mandatory=$true)]
        [string]$SPID,
        [Parameter(Mandatory=$true)]
        [string]$Tenant,
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionId,
        [string] $DataLakeName,
        [string] $BlobStoreName,
        [switch] $ManagedIdentity,
        [string] $SFTPUser,
        [string] $SFTPPassword
    )

    ###################
    # Set Up
    ###################
    $scenarioFolderPath = ".\dfjsons\"+ "s"+$ScenarioNumber+"\"

    $datasetFiles = $scenarioFolderPath+"dataset\"
    $linkedServiceFiles = $scenarioFolderPath+"linkedService\"
    $pipelineFiles = $scenarioFolderPath+"pipeline\"

    ###################
    # LinkedServices
    ###################
    if(Test-Path $linkedServiceFiles){
        $linkedServiceFiles = Get-ChildItem -Path $linkedServiceFiles
        ForEach ($linkedServiceFile in $linkedServiceFiles)
        {
            $linkedServiceFilePath = $scenarioFolderPath + "linkedService\" + $linkedServiceFile

            $lsFileContent = Get-Content $linkedServiceFilePath -raw | ConvertFrom-Json 

            if($lsFileContent.properties.type -eq "AzureDataLakeStore"){

                if($ManagedIdentity){

                    $lsFileContent.properties.typeProperties.dataLakeStoreUri = "https://" + $DataLakeName + ".azuredatalakestore.net/webhdfs/v1"
                    $lsFileContent.properties.typeProperties.tenant = $Tenant
                    $lsFileContent.properties.typeProperties.subscriptionId = $SubscriptionId
                    $lsFileContent.properties.typeProperties.resourceGroupName = $ResourceGroupName
                    $lsFileContent | ConvertTo-Json -depth 32| set-content $linkedServiceFilePath


                }
                else{

                    $lsFileContent.properties.typeProperties.dataLakeStoreUri = "https://" + $DataLakeName + ".azuredatalakestore.net/webhdfs/v1"
                    $lsFileContent.properties.typeProperties.servicePrincipalId = $SPID
                    $lsFileContent.properties.typeProperties.servicePrincipalKey.value = $SPKey
                    $lsFileContent.properties.typeProperties.tenant = $Tenant
                    $lsFileContent.properties.typeProperties.subscriptionId = $SubscriptionId
                    $lsFileContent.properties.typeProperties.resourceGroupName = $ResourceGroupName
                    $lsFileContent | ConvertTo-Json -depth 32| set-content $linkedServiceFilePath


                }
            }
            elseif($lsFileContent.properties.type -eq "AzureBlobStorage"){

                $lsFileContent.properties.typeProperties.connectionString = "DefaultEndpointsProtocol=https;AccountName=" + $BlobStoreName + ";AccountKey=" + (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $BlobStoreName).Value[0]
                $lsFileContent | ConvertTo-Json -depth 32| set-content $linkedServiceFilePath

            }
            elseif($lsFileContent.properties.type -eq "Sftp"){

                $lsFileContent.properties.typeProperties.host = "dfscenaiorcontainergroup"+ ($env:UserName) + ".centralus.azurecontainer.io"
                $lsFileContent.properties.typeProperties.userName = $SFTPUser
                $lsFileContent.properties.typeProperties.password.value = $SFTPPassword
                $lsFileContent | ConvertTo-Json -depth 32| set-content $linkedServiceFilePath

            }

            [void](Set-AzDataFactoryV2LinkedService -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Name $lsFileContent.Name -DefinitionFile $linkedServiceFilePath)
    
        }
    }


    ###################
    # DataSets
    ###################
    if(Test-Path $datasetFiles){
        $datasetFiles = Get-ChildItem -Path $datasetFiles
        ForEach ($datasetFile in $datasetFiles)
        {
            $datasetFilePath = $scenarioFolderPath + "dataset\" + $datasetFile

            $dsFileContent = Get-Content $datasetFilePath -raw | ConvertFrom-Json

            [void](Set-AzDataFactoryV2Dataset -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Name $dsFileContent.Name -DefinitionFile $datasetFilePath)
    }
    }


    ###################
    # Pipelines
    ###################
    if(Test-Path $pipelineFiles){
        $pipelineFiles = Get-ChildItem -Path $pipelineFiles
        ForEach ($pipelineFile in $pipelineFiles)
        {

            $pipelineFilePath = $scenarioFolderPath + "pipeline\" + $pipelineFile

            $pFileContent = Get-Content $pipelineFilePath -raw | ConvertFrom-Json

            [void](Set-AzDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -Name $pFileContent.Name -DefinitionFile $pipelineFilePath)
    }
    }
}

Function Run-DFPipeline{
    Param (
        [Parameter(Mandatory=$true)]
        [string] $ScenarioNumber,
        [Parameter(Mandatory=$true)]
        [string]$DataFactoryName,
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName
    )

    $PipelineName = "S" + $ScenarioNumber + "Pipeline"

    Write-Output "Running Pipeline "$PipelineName

    $runId = Invoke-AzDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineName $PipelineName

    Write-Output "Pipeline Running"

        $pipelineRunning = $true

        while($pipelineRunning){
            $result = Get-AzDataFactoryV2PipelineRun -PipelineRunId $runId -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
            if($result.Status -eq "InProgress"){
                Write-Host "."
                Start-Sleep -s 15
            }
            else{
                Write-Host "Pipeline "$runId
                Write-Host $result.Status
                $pipelineRunning = $false
            }

        }
}


##################################################
# Login & Set Context
##################################################
#[void](Login-AzAccount)


##################################################
# Globals
##################################################
$ParametersFilePath = ".\runfiles\arm_template_parameters.json"
$ContextFilePath = ".\runfiles\context.json"
$armTemplatePath = ".\runfiles\arm_template.json"
$sftparmTemplatePath = ".\runfiles\SFTPDeploymentJSON.json"
$sftpParametersFilePath = ".\runfiles\SFTPDeploymentParameters.json"


##################################################
# Set up Scenario Environment
##################################################
if($SetUp){

    [void](Set-AzContext -SubscriptionId $Subscription)

    ######################
    # Env Varibles
    ######################
    $Tenant = (Get-AzSubscription -SubscriptionId $Subscription).TenantId
    [void](Register-AzResourceProvider -ProviderNamespace "Microsoft.DataLakeStore")


    ######################
    # Create SP
    ######################
    $servicePrincipal = New-AzADServicePrincipal -DisplayName $ServicePrincipalName
    $SPID = $servicePrincipal.ApplicationId
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrincipal.Secret)
    $SPKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)



    ##################################################
    # Resource Group Deployment
    ##################################################

    [void](New-AzResourceGroup -Name $ResourceGroupName -Location $Region)

    ##################################################
    # Update Parameter Values
    ##################################################

    $fileContent = Get-Content $ParametersFilePath -raw | ConvertFrom-Json 
    $fileContent.parameters.factoryName.value = $DataFactoryName
    $fileContent.parameters.accounts_whhenderdftrainingadl_name.value = $DataLakeName
    $fileContent.parameters.factoryName.value = $DataFactoryName
    $fileContent.parameters.resourceLocation.value = $Region
    $fileContent.parameters.blobstorename.value = $BlobStoreName
    $fileContent.parameters.sftpUser.value = $SFTPUserName
    $fileContent.parameters.sftpPassword.value = $SFTPPassword
    $fileContent.parameters.containerGroupDNSLabel.value = 'dfscenaiorcontainergroup' + ($env:UserName)
    $fileContent.parameters.resourcegroupname.value = $ResourceGroupName
    $fileContent | ConvertTo-Json -depth 32| set-content $ParametersFilePath


    $contextFileContent = Get-Content $ContextFilePath -raw | ConvertFrom-Json 
    $contextFileContent.parameters.subscriptionId.value = $Subscription
    $contextFileContent.parameters.servicePrincipalId.value = $SPID
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_dataLakeStoreUri.value = "https://" + $DataLakeName + ".azuredatalakestore.net/webhdfs/v1"
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_resourceGroupName.value = $ResourceGroupName
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_servicePrincipalId.value = $SPID
    $contextFileContent.parameters.AzureDataLakeStoreGen1_servicePrincipalKey.value = $SPKey
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_subscriptionId.value = $Subscription
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_tenant.value = $Tenant
    $contextFileContent | ConvertTo-Json -depth 32| set-content $ContextFilePath

    $SFTPFileContent = Get-Content $sftpParametersFilePath -raw | ConvertFrom-Json 
    $SFTPFileContent.parameters.existingStorageAccountResourceGroupName.value = $ResourceGroupName
    $SFTPFileContent.parameters.existingStorageAccountName.value = $BlobStoreName
    $SFTPFileContent.parameters.sftpUser.value = $SFTPUserName
    $SFTPFileContent.parameters.sftpPassword.value = $SFTPPassword
    $SFTPFileContent.parameters.containerGroupDNSLabel.value = "dfscenaiorcontainergroup"+ ($env:UserName)
    $SFTPFileContent | ConvertTo-Json -depth 32| set-content $sftpParametersFilePath

    ##################################################
    # Deploy ARM Templates
    ##################################################

    [void](New-AzResourceGroupDeployment -Name DFTrainingDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $armTemplatePath -TemplateParameterFile $ParametersFilePath)

    [void](New-AzResourceGroupDeployment -Name DFTrainingSFTP -ResourceGroupName $ResourceGroupName -TemplateFile $sftparmTemplatePath -TemplateParameterFile $sftpParametersFilePath)

    ##################################################
    # Stop SFTP
    ##################################################

    az container stop --name $SFTPName --resource-group $ResourceGroupName

    ##################################################
    # Add Managed Identity
    ##################################################

    $ManagedIdentity = (Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName).Identity.PrincipalId

    [void](New-AzRoleAssignment -ObjectId $ManagedIdentity -ResourceGroupName $ResourceGroupName -ResourceName $DataLakeName -RoleDefinitionName Owner -ResourceType Microsoft.DataLakeStore/accounts)


}

##################################################
# Remove Scenario Environment
##################################################
elseif($CleanUp){

    ##################################################
    # Remove RG and SP
    ##################################################
    
    $fileContent = Get-Content $ParametersFilePath -raw | ConvertFrom-Json 
    
    $contextFileContent = Get-Content $ContextFilePath -raw | ConvertFrom-Json 
    $Subscription = $contextFileContent.parameters.subscriptionId.value 


    [void](Set-AzContext -SubscriptionId $Subscription)

    [void](Remove-AzResourceGroup -Name $ResourceGroupName -Force)
    [void] (Remove-AzADServicePrincipal -DisplayName $ServicePrincipalName -Force)
    [void](Remove-AzADApplication -DisplayName $ServicePrincipalName -Force)

    ##################################################
    # Clear Context and Parameters Files
    ##################################################
    $fileContent.parameters.factoryName.value = ""
    $fileContent.parameters.accounts_whhenderdftrainingadl_name.value = ""
    $fileContent.parameters.resourceLocation.value = ""
    $fileContent.parameters.blobstorename.value = ""
    $fileContent | ConvertTo-Json -depth 32| set-content $ParametersFilePath


    $contextFileContent = Get-Content $ContextFilePath -raw | ConvertFrom-Json 
    $contextFileContent.parameters.subscriptionId.value = ""
    $contextFileContent.parameters.servicePrincipalId.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_dataLakeStoreUri.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_resourceGroupName.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_servicePrincipalId.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_servicePrincipalKey.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_subscriptionId.value = ""
    $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_tenant.value = ""
    $contextFileContent | ConvertTo-Json -depth 32| set-content $ContextFilePath

    $SFTPFileContent = Get-Content $sftpParametersFilePath -raw | ConvertFrom-Json 
    $SFTPFileContent.parameters.existingStorageAccountResourceGroupName.value = ""
    $SFTPFileContent.parameters.existingStorageAccountName.value = ""
    $SFTPFileContent.parameters.sftpUser.value = ""
    $SFTPFileContent.parameters.sftpPassword.value = ""
    $SFTPFileContent.parameters.containerGroupDNSLabel.value = ""
    $SFTPFileContent | ConvertTo-Json -depth 32| set-content $sftpParametersFilePath
    Write-Host "Clean Up Completed"
    return

}

##################################################
# Launch Scenarios
##################################################

elseif($Scenario){

    # Getting Subscription ID from Context File
    $contextFileContent = Get-Content "runFiles\context.json" -raw | ConvertFrom-Json
    $fileContent = Get-Content $ParametersFilePath -raw | ConvertFrom-Json
    $templateContent = Get-Content $armTemplatePath -raw |ConvertFrom-Json

    $Subscription = $contextFileContent.parameters.subscriptionId.value
    $SPKey = $contextFileContent.parameters.AzureDataLakeStoreGen1_servicePrincipalKey.value
    $SPID = $contextFileContent.parameters.AzureDataLakeStoreGen1_properties_typeProperties_servicePrincipalId.value
    [void](Set-AzContext -SubscriptionId $Subscription)

    ######################################
    # Scenario 0 - Insufficient Data Lake Permissions
    ######################################
    if($Scenario -eq "0"){    
        ######################################
        # Scenario 1 Variables
        ######################################
        $s0SourcePath = "/S0Source"
        $s0DataLocation = ".\data\"
        $s0DataLocation2 = ".\data2\"

        ######################################
        # Create Data Lake Folders, Upload File
        ######################################
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s0SourcePath -Folder)

        [void](Import-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s0DataLocation -Destination $s0SourcePath)

        ######################################
        # Deploy Pipelines and Linked Services
        ######################################
        Deploy-DFScenario -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SPKey $SPKey -SPID $SPID -Tenant (Get-AzSubscription -SubscriptionId $Subscription).TenantId -SubscriptionId $Subscription -DataLakeName $DataLakeName -ManagedIdentity -BlobStoreName $BlobStoreName


        ######################################
        # Confirm Friendly Blob Store
        ######################################
        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Allow)

        ######################################
        # Run Pipeline 2 times
        ######################################
        
        Run-DFPipeline -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
        
        Run-DFPipeline -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName     
         
        
        ######################################
        # Modify Blob Store Firewall for Failure
        ######################################   
        
        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Deny)


        ######################################
        # Run Pipeline Again (Should Fail)
        ######################################
        
        Run-DFPipeline -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName


        ######################################
        # Correct Blob Store Firewall
        ######################################

        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Allow)

        ######################################
        # Upload Additional Data
        ######################################

        [void](Import-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s0DataLocation2 -Destination $s0SourcePath)

        ######################################
        # Run Pipeline Again (Should Succeed)
        ######################################
        
        Run-DFPipeline -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
    
    }


    ######################################
    # Scenario 1 - Insufficient Data Lake Permissions
    ######################################
    elseif($Scenario -eq "1"){    
        ######################################
        # Scenario 1 Variables
        ######################################
        $s1SourcePath = "/S1SourceData"
        $s1SinkPath = "/S1SinkData"
        $s1DataLocation = ".\data\s1data.csv"

        ######################################
        # Create Data Lake Folders, Upload File
        ######################################
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s1SourcePath -Folder)
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s1SinkPath -Folder)

        [void](Import-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s1DataLocation -Destination ($s1SourcePath + "\s1data.csv"))

        ######################################
        # Set Incomplete Permissions
        ######################################
        [void](Set-AzDataLakeStoreItemAclEntry -AccountName $DataLakeName -Path / -AceType User -Id (Get-AzADServicePrincipal -ApplicationId $contextFileContent.parameters.servicePrincipalId.value).Id -Permissions Execute)
        [void](Set-AzDataLakeStoreItemAclEntry -AccountName $DataLakeName -Path $s1SourcePath -AceType User -Id (Get-AzADServicePrincipal -ApplicationId $contextFileContent.parameters.servicePrincipalId.value).Id -Permissions ReadExecute -Recurse)
        [void](Set-AzDataLakeStoreItemAclEntry -AccountName $DataLakeName -Path $s1SinkPath -AceType User -Id (Get-AzADServicePrincipal -ApplicationId $contextFileContent.parameters.servicePrincipalId.value).Id -Permissions ReadExecute)

        ######################################
        # Deploy Pipelines and Linked Services
        ######################################
        Deploy-DFScenario -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SPKey $SPKey -SPID $SPID -Tenant (Get-AzSubscription -SubscriptionId $Subscription).TenantId -SubscriptionId $Subscription -DataLakeName $DataLakeName


        ######################################
        # Run Pipeline
        ######################################      

        $runId = Invoke-AzDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineName 'S1Pipeline'
    
    }

    ######################################
    # Scenario 2 - Firewall on Blob
    ######################################
    elseif($Scenario -eq "2"){
        
        ######################################
        # Set Blob Firewall
        ######################################

        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Deny)

        ######################################
        # Deploy Blob Linked Service
        ######################################

        Deploy-DFScenario -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SPKey $SPKey -SPID $SPID -Tenant (Get-AzSubscription -SubscriptionId $Subscription).TenantId -SubscriptionId $Subscription -BlobStoreName $BlobStoreName

    }

    ######################################
    # Scenario 3 - SFTP Performance
    ######################################
    elseif($Scenario -eq "3"){

        
        Write-Warning "This scenario may take up to 30 minutes to deploy. Continue?" -WarningAction Inquire

        ######################################
        # Confirm Blob Firewall
        ######################################

        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Allow)

        ######################################
        # Scenario 3 Variables
        ######################################
        $s3SourcePath = "/S3SourceData"
        $s3SinkPath = "/S3SinkData"
        $s3DataLocation = ".\data\bigfile.csv"

        ######################################
        # Create Data Lake Folders, Upload File
        ######################################
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s3SourcePath -Folder)

        Write-Output 'Start File Upload'

        [void](Import-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s3DataLocation -ForceBinary -Concurrency 22 -Destination ($s3SourcePath + "\bigfile.csv"))

        Write-Output 'File Upload Completed'

        
        ######################################
        # Start File Share
        ######################################

        Write-Output "Starting SFTP"
        
        az container start --name $SFTPName --resource-group $ResourceGroupName
       
        Write-Output "SFTP Started"

        ######################################
        # Deploy DF Pipelines
        ######################################
        Write-Output "Deploying Data Factory Resources"

        Deploy-DFScenario -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SPKey $SPKey -SPID $SPID -Tenant (Get-AzSubscription -SubscriptionId $Subscription).TenantId -SubscriptionId $Subscription -DataLakeName $DataLakeName -ManagedIdentity -SFTPUser $SFTPUserName -SFTPPassword $SFTPPassword

        Write-Output "Resources Deployed"

        Write-Output "Running Pipeline"

        $runId = Invoke-AzDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineName 'S3Pipeline'
    
        Write-Output "Pipeline Running"

        $pipelineRunning = $true

        while($pipelineRunning){
            $result = Get-AzDataFactoryV2PipelineRun -PipelineRunId $runId -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName
            if($result.Status -eq "InProgress"){
                Write-Host "."
                Start-Sleep -s 15
            }
            else{
                Write-Host "Pipeline "$runId" "$result.Status
                $pipelineRunning = $false
            }

        }

        Write-Output "Stopping SFTP"
        az container stop --name $SFTPName --resource-group $ResourceGroupName
        Write-Output "SFTP Stopped"

        Write-Output "Resetting Blob Firewall"
        ######################################
        # Resetting Blob Firewall
        ######################################

        [void](Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $ResourceGroupName -Name $BlobStoreName -DefaultAction Deny)

        Write-Output "Scenario Complete"


    }

    ######################################
    # Scenario 4 - Insufficient Data Lake Permissions
    ######################################
    elseif($Scenario -eq "4"){    
        ######################################
        # Scenario 1 Variables
        ######################################
        $s4SourcePath = "/S4SourceData"
        $s4SinkPath = "/S4SinkData"
        $s4DataLocation = ".\data\s1data.csv"

        ######################################
        # Create Data Lake Folders, Upload File
        ######################################
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s4SourcePath -Folder)
        [void](New-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s4SinkPath -Folder)

        [void](Import-AzDataLakeStoreItem -AccountName $DataLakeName -Path $s4DataLocation -Destination ($s4SourcePath + "\s4data.csv"))

      
        ######################################
        # Deploy Pipelines and Linked Services
        ######################################
        Deploy-DFScenario -ScenarioNumber $Scenario -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -SPKey $SPKey -SPID $SPID -Tenant (Get-AzSubscription -SubscriptionId $Subscription).TenantId -SubscriptionId $Subscription -DataLakeName $DataLakeName -ManagedIdentity

        ######################################
        # Grant Managed Identity Permissions
        ######################################
        $ManagedIdentity = (Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName).Identity.PrincipalId

        [void](New-AzRoleAssignment -ObjectId $ManagedIdentity -ResourceGroupName $ResourceGroupName -ResourceName $DataLakeName -RoleDefinitionName Owner -ResourceType Microsoft.DataLakeStore/accounts)


        ######################################
        # Run Pipeline
        ######################################      

        $runId = Invoke-AzDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName -PipelineName 'S4Pipeline'
    
    }
    else{
        "No Scenario. End"
    }
}
else{
    "
    
    =========================================================================
    = Data Factory Training Scenario Deployment
    =========================================================================
    = How to Use:
    = 1. Use -SetUp to initialize training environment in your subscription.
    = 2. Use -Scenario to run a particular training scenario on the training environment.
    = 3. Use -CleanUp to remove training environment from your subscription.
    =
    =
    = Set up training environment:
    = -------------------------------------------
    = Description:
    = This function will deploy all resources necessary to run all traning scenarios
    = to your Azure Subscription under a resource group
    =
    = Parameters to Run:
    = -SetUp -Subscription <subscription Id>
    =
    = Optional Parameters: 
    = -Region -ResourceGroupName -DataLakeName -DataFactoryName -ServicePrincipalName
    =
    = Default Values of Optional Parameters:
    = -Region 'centralus'
    = -ResourceGroupName 'DataFactoryTrainingRG<alias>'
    = -DataLakeName 'dftrainingadl<alias>
    = -DataFactoryName 'dftrainingadf<alias>
    = -ServicePrincipalName 'DFTrainingSP<alias>
    =
    = Launch Scenario:
    = -------------------------------------------
    = Description:
    = This function will deploy data and permissions necessary to run one of the training scenarios.
    = Once the scenario is deployed, a customer description will be provided to give to your
    = trainee engineer, as well as a description of the issue.
    =
    = Parameters to Run:
    = -Scenario [0,1,2,3,4]
    =
    = Available Scenarios:
    = 0. Multiple Pipeline Runs With Some Failure and Some Success to Teach Kusto Skills
    = 1. Data Factory Run Fails Due to Incomplete Permissions on Data Lake Store
    = 2. Blob Linked Service Cannot Connect Due to Firewall & Using Account Key
    = 3. SFTP Copy Activity Running More Slowly than Desired
    = 4. Data Lake Copy Activity Failing because of Parameters Issue
    =
    =
    = Remove/Delete Training Environment:
    = -------------------------------------------
    = Description:
    = This function will remove the resource group and service principal associated with 
    = your training scenarios. It will also clear the parameters file associated with this PowerShell Script.
    = So you will not be able to run another scenario without running -SetUp again.
    =
    = Parameters to Run:
    = -CleanUp
    =========================================================================
    =========================================================================
   "

}