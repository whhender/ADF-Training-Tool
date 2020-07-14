# ADF-Training-Tool
PowerShell Script and Package to Deploy ADF Training to New Support Engineers

## What is This Tool
What is DFTrainingEnvManager?

This is a PowerShell Script that creates a Data Factory Training environment within an azure subscription.
It then deploys several scenarios that can be used to practice troubleshooting.

Once you are finished with the environment, you can use this tool to remove the environment from your subscription.

The scenarios can be used for:
1. Kusto Training
2. Troubleshooting Training
3. Case Management Training

The tool is meant to be deployed by Data Factory SMEs/Mentors to train new engineers.

New scenarios can be added to the troubleshooting tool as well. If you do add scenarios, please feel free
to upload the changes/additions to git so all can enjoy.

## How to Use

   ./DFTrainingEnvManager

    = How to Use:
    = 1. Use -SetUp to initialize training environment in your subscription.
    = 2. Use -Scenario to run a particular training scenario on the training environment.
    = 3. Use -CleanUp to remove training environment from your subscription.
    =
    =
    = -SetUp  (Set up training environment):
    = -------------------------------------------
    = Description:
    = This function will deploy all resources necessary to run all traning scenarios
    = to your Azure Subscription under a resource group
    =
    = Parameters to Run:
    = -SetUp -Subscription <subscription Id>
    =
    = Optional Parameters: 
    = -Region -ResourceGroupName -DataLakeName -DataFactoryName -ServicePrincipalName -SFTPUserName -SFTPPassword -SFTPName -BlobStoreName -FileShareName
    =
    = Default Values of Optional Parameters can be seen in script.
    =
    = -Scenario [0,1,2,3,4] (Launch Scenario):
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
    = 4. Data Lake Copy Activity Failing because of Parameters/Expression Language Issue
    =
    =
    = -CleanUp (Remove/Delete Training Environment):
    = -------------------------------------------
    = Description:
    = This function will remove the resource group, all resources, and service principal associated with 
    = your training scenarios. It will also clear the parameters file associated with this PowerShell Script.
    = So you will not be able to run another scenario without running -SetUp again.
    =
    = Parameters to Run:
    = -CleanUp

## Instructions for Trainers

1. Run PowerShell tool on SetUp mode to spin up environment.
2. Read through Scenarios doc to choose a scenario.
3. For Scenario 0:
a. Run PowerShell tool on -Scenario 0
b. Gather one of the run Ids from your Data Factory environment.
c. Either use this run ID to take your engineer through kusto basics or
           send run ID and questions for scenario to engineer so they can practice kusto skills.
4. For Scenarios 1-4:
a. Run PowerShell tool for Scenario
b. Gather run ID and/or Scenario customer verbatim to send to engineer.
c. Send Trainee instructions to trainee engineer.
d. Either create a test case (as outlined in Make A Test Service Desk Case) or email ID and verbatim to engineer to troubleshoot.
e. During troubleshooting process act as Customer, Mentor, Product Team, and collaborators for trainee.
f. On completion of troubleshooting review these aspects of the case for engineer growth:
i. Troubleshooting Process
ii. Customer Communications (including FQR and LQR)
iii. Case Notes

## Make a Test Service Desk Case

To open a test case in Service desk to pair with these cases, use +Case in the service desk
home page.

To make sure that test cases are appropriately deleted and NOT counted toward any products stats, 
follow all these instructions:


1. Test cases should have a Support Area Path of Windows / PSS Other
2. Test cases should have documentation that it is in fact a test case in following fields:
	· Customer Statement
	· Internal Title
	· Case Title
	· Notes (as needed)
3. Provide a Root Cause or Symptom if required. Some taxonomies have Other/Test/etc. as options. 
   Otherwise, select a value that is most appropriate.
4. Close the case with Status of Duplicate.

https://microsoft.sharepoint.com/:w:/t/LegacyUploaded_BemisRepository/Bemis/EQfKFBQEJ1ZKpkJp2hqdqqwB-C6_5skrki0zgNyMSIgwHw?e=GiAlFk

## Instructions for Trainees

1. Please send emails and meeting requests as you would to a real customer.
2. If you need a collab opened to another team, create a normal collab task but assign it to your
   trainer/mentor/the engineer delivering these scenarios. They will act as the engineer from another team.
3. If you want to open an ICM, create a collab task and provide all the information you would normally
   provide the product team, but assign the collab task to your trainer/mentor/the engineer delivering
   these scenarios. They will act as the product team for these cases.
4. Though the ASC search function is a great tool for troubleshooting customer cases, please do not use it 
   for these test cases. These test cases have been delivered to multiple engineers and will show up in ASC
   so please use other tools/troubleshooting processes to resolve.
5. If you need help troubleshooting, your mentor/trainer/the engineer delivering these scenarios can provide
   help as if they are a TA/peer who is helping you with a case. Do reach out to them!
6. Once you are finished with a case, please assign to your trainer/mentor/the engineer delivering training so
   they can appropriately close it as a test case.

## Scenarios

Scenario 0
======================================================================
Description:
---------------------------
Scenario 0 is a kusto training scenario.
I tend to take my engineers through this scenario twice.

1st Run- I give them a run ID and we walk through everything we can find in Activity Runs and Custom Log Events 
together so they can get familiar with kusto and query writing.

2nd Run- I gven them a run ID, the below list of questions, and the kusto guide link from the TSG
and have them answer all the questions by looking through kusto themselves. And I help them with any questions
they might have about finding the data.


List of Questions:
---------------------------
	1. Pipeline Run ID                      
	2. Activity Run ID(s)
	3. How many activities did this pipeline have? What was its/their name(s)?                    
	4. Activity Type(s)                          
	5. Data Factory Name
	6. Subscription ID
	7. What Region the Pipeline Ran In
	8. For each activity, Self-Hosted Integration Runtime or Azure Integration Runtime
	9. For each activity, Successful or Failed
	10. Pipeline Start Time
	11. Pipeline End Time
	12. Has this Pipeline Run more than once? If so, how many times?
	 
For any one of the copy activities (in the original pipeline run):
	
	13. What kind of source?
	14. What kind of sink?
	15. Name of the source resource?
	16. Name of the sink resource?
	17. Were retries set on the pipeline? If so, how many?
	18. What Timeout is set on this pipeline?
	19. What was the path of the source data?
	20. What was the path of the sink data?

For one successful copy activity please answer the following:

	22. Activity Run ID
	23. How many files went through the activity? 
	24. What was the size of the data?
	25. Was parallelization used? If so, how much?
	26. How many DIUs were used?
	27. How long did the pipeline queue?
	28. How long did it read from the source?
	29. How long did it write to the sink?

For one failed copy activity please answer the following:

	30. Activity Run ID
	31. Successful or Failed
	32. How many files went through the activity? 
	33. What was the size of the data?
	34. Was parallelization used? If so, how much?
	35. How many DIUs were used?
	36. How long did the pipeline queue?
	37. How long did it read from the source?
	38. How long did it write to the sink?


Skills we're looking for:
---------------------------
Comfort with navigating kusto and kusto query skills.


Scenario 1
======================================================================
Description:
---------------------------
Unable to run copy pipeline between source folder and sink folder in the same ADLS Gen 1.
Get an ACL error on running the copy activity.

Customer Verbatim:
---------------------------
Pipeline Run Id: <PROVIDE PIPELINE RUN ID>

My copy pipeline is failing with this error - 
\"CREATE failed with error 0x83090aa2 (Forbidden. ACL verification failed. Either the resource does not exist or the user is not authorized to perform the requested operation.).
Can you help me fix it?

Information to Provide:
---------------------------
1. If engineer "Opens a collab" to "Storage Team" for information on the sink (all collabs should be assigned not to the correct team, but to the mentor/trainer)
   the "storage team" should indicated that the command is failing not at the root, but at the sink folder.
   Storage team should indicate that at least write execute permissions are required on the parent folder to complete action.

Solution:
---------------------------
Write permission is missing for the service principal on the output folder for the ADLS Gen 1 sink.
Adding this write permission will resolve the issue.


Skills we're looking for:
---------------------------
1. In the FQR(First Quality Response) email they should provide a link to the documentation for the Azure Data Lake Store linked service
OR
The link for Azure Data lake Store permissions, as they should be able to tell this is the problem from the get-go.

2. Once they have provided this information, get them into a call and have them walk you through the steps to fix it themselves.

3. They could also choose to 'bring in' the Azure Data Lake store team, where they need to write a collab task explaining the issue,
and then assign the collab to you. Expect to have error timestamp and name of ADLS in the collab task.
Then you provide the above information as if you were from ADLS team.

Still have the engineer guide the customer through the process of setting the permissions even after having been given the right answer.

Scenario 2
======================================================================
Description:
---------------------------
Blob store linked service is unable to connect.
No pipeline is running, this is just a failing linked service.


Customer Verbatim:
---------------------------

Error message: <PROVIDE FULL ERROR MESSAGE FROM FAILED LINKED SERVICE CONNECTION>

I am trying to create a blob linked service, and I have the right account key, but it can't connect??
I know I have the correct account key.

Solution:
---------------------------
Customer is attempting to connect to an Azure Blob Store that has a firewall enabled and they are using an account key.
https://docs.microsoft.com/en-us/azure/data-factory/connector-azure-blob-storage#linked-service-properties

This is not allowed at this time and they will not be able to connect.

There are several possible solutions:
1. Use a self-hosted IR and add the ip address of the IR to the firewall.
2. Changed the identity type to a managed identitity and leave the firewall as is.
3. Remove the firewall from the blob store. (Not an acceptable solution though. This will work, but push for keeping the firewall.)

Skills we're looking for:
---------------------------
They should gather some further information from the customer either in a call or through email to realize what settings
are in place in the linked service and blob store.

They should also eventually provide the link posted above and know that the settings the customer has in place 
won't work.

If they recommend removing the firewall, push them that the customer wants/needs the firewall until they arrive at another solution.


Scenario 3
======================================================================
Description:
---------------------------
Copying a single large file from Blob to SFTP. Currently, the SFTP connector can only write in parallel to 
multiple files, but cannot write in parallel to a single file. This means that writing large files to an SFTP
server will go much more slowly than anticipated.

The file size needed to get a really good repro is at least 5gb, which takes a long time to upload
to the data lake using PS or the portal for the same reason.

If you want a really good repro of this, upload a single, very large file to your S3 Source folder.
As it is, the pipeline runs in 3-4 minutes.


Customer Verbatim:
---------------------------
I am copying ~2GB from Data Lake to SFTP. Using just SFTP it takes SECONDS, 
but it's taking minutes when I'm using ADF. If I move more data, this is gonna take forever! How can we make this faster?

Solution:
---------------------------
Currently, the SFTP connector can only write in parallel to multiple files, but cannot write in parallel to a single file.
I don't expect the engineer to know this or be able to find it in the documentation.

This case is purely to teach troubleshooting/performance troubleshooting skills.
The engineer will need to obtain this information from the "product team" (mentor/trainer) after gathering the appropriate information.

Once the above information is provided, the engineer should be asked for workarounds to this issue.
Workarounds include:
1. Breaking the large file into multiple, smaller failes to be able to take advantage of copying in parallel.
2. Installing the SHIR closer to the sftp to reduce any network time (though that isn't the root of the problem.)
3. Using a tool other than Azure Data Factory to move the data.

Information to Provide:
---------------------------
1. If engineer "Opens a collab" to "Storage Team" for information on the source performance (all collabs should be assigned not to the correct team, but to the mentor/trainer)
   the "storage team" should indicated that there is no problem or latency at the time.
2. If engineer asks 'customer' results of moving data using a script or other tool, 'customer' should indicate that the operation takes seconds using another tool.
3. If engineer attempts to "open a collab" with the SFTP team, they should be told that the SFTP is on the customer side.
4. If engineer asks about SFTP performance on customer side, they should be told that SFTP is not seeing any latency and is processing requests quickly.
   But that the sftp can only see data coming in in small chunks.
5. If engineer "Opens an ICM" (all 'ICMs' should be a collab task assigned to mentor/trainer) to the ADF team they should be asked to provide:
a. Source Connector Type
b. Sink Connector Type
c. How Many files are being moved
d. Size of file being moved
e. Parallelism Used
f. Run ID 

g. Once the information a-f is provided, 'product group' should request:
i. A network trace from the SFTP during copy. (results will be provided from 'customer') Results of this collected network trace will be that during the whole copy, SFTP saw a consistant network traffic of 11mb. Traffic was no higher than this at any time during the copy.
ii. That the pipeline be tried with a self-hosted integration runtime.
iii. That a network trace be taken from self-hosted ir machine.

h. Once information from g is provided, the product team should indicate that Currently, the SFTP connector can only write in parallel to multiple files, but cannot write in parallel to a single file. This is therefore the best performance the customer is going to get from the SFTP connector for a single, large file.


Skills we're looking for:
---------------------------
1. Engineer should note that all the copy time is spent moving data to the sink while little time is spent reading the data.
2. Engineer should note that 'peak connections' to SFTP is always 1. 
3. Engineer should reach out to product team for assistance.
4. Once engineer has learned about the limitations of ADF, engineer should consider workarounds for the customer.

Scenario 4
======================================================================
Description:
---------------------------
Customer wants to make a pipeline that uses a copy activity to read a name from a file using a 'Lookup' activity
and then the sink folder of the copy activity should be dynamically created using that name.

So lookup is reading a file, and the Copy Activity is pulling the output from Lookup to dynamically name the folder.
In this instance, we want the folder to be named the first value in the first column of the folder,
which is "puppy".

Be sure to attach full copy activity support files on the case so the engineer can attempt to repro.

Customer Verbatim:
---------------------------

Operation on target Copy data1 failed: Failed to convert the value in 'folderPath' property to 'System.String' type. Please make sure the payload structure and value are correct. 


I have a pipeline that is creating a folder from the text in the source file, but its failing with a super weird error.
My Pipeline details are attached!

Solution:
---------------------------

The expression for the FolderName parameter is incorrect and should be:
	
@activity('Lookup1').output.firstRow.Prop_0

Skills we're looking for:
---------------------------
1. Understand how to see the Output of the lookup
2. Understanding how to use this output to correctly define the expression needed.