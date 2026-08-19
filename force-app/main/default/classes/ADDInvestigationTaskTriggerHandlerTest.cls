/** 
 * @why  : ADDInvestigationTaskTriggerHandlerTest class for the Task_AuditTrigger,
 * @when : CreatedDate : 31-AUG-2018         ModifiedDate : 24-APR-2019
 * @what : Class to Handle Different scenarios from UpdateParentUtility.
 *  Modification Log:  
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID         Description 
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                25-FEB-2020            [CR] 1029/1198           Modified.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rslob                03-June-2020           N/A                      Test class optimization
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                10-June-2020           N/A                      Updated code part, which is related to Users' insertion. 
                                                                             This change designed to prevent a 'DUPLICATE_USERNAME'
                                                                             error during deployment to Production environment
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      RSlob                15-06-2020             Code Audit               Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                06-24-2020             #123.1/CHARM-2878        Adjusted testTaskFromInvestigationInProcess method.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *      oivan                29-DEC-2020            TWD Upgrade issue        Added methods to cover WF logic.
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *      rsitc                18-FEB-2021            TWD Upgrade issue        Splitted up taskWFTest and testWfActions methods 
 *                                                                           to reduce DML operations in a single test method.
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *      Larry Resnik         07-FEB-2023            CHaRM R3.0               Removed reference to unused field so that it can be deleted in the future
 * ---------------------------------------------------------------------------------------------------------------------------------------
 *   Dinesh Kumar(COE)       02-Jun-2023.           CHARM R3.1.             Modified the test method "testCreatingTaskFromInvestigation","testTaskFromInvestigationClosedDone",
 *                                                                          "testTaskFromInvestigationClosedVoided" to capture the error message and code coverage.
                                                                            Added the code for test users creation 'complaintAccessorUser','complaintInvestigatorUser' and
                                                                            'systemAdmin'. Created new methods "deleteTaskRecordInClosedDoneWithCorrectUser",
                                                                            "deleteTaskRecordInOpenedWithWrongUser","deleteTaskRecordInOpenedWithCorrectUser".
 * ---------------------------------------------------------------------------------------------------------------------------------------
 * Charm COE               07-Jul-2025.             IPDR-575                Added new test methods "testafterEventHandler" and "testRegularSearch" to support both sublot-based and 
																	         regular lot-based matching for Product_Ticket__c.
																			Added new test methods "testLotToReviewLengthRequiredVRLessThan9" and "testLotToReviewLengthRequiredVRGreaterThan9" 
																			 to test the LotToReview_LengthRequired_IfSublotInclu validation rule
																			Modified test methods "testafterEventHandler" and "testRegularSearch" to check that two Ticket Searches are generated, 
																			 when two Product-Tickets are linked to same Ticket which are having first 7 characters same and to check that two 
																			 Ticket Searches are generated, regardless of character casing (uppercase or lowercase)
* ---------------------------------------------------------------------------------------------------------------------------------------
 * Charm COE               14-Jan-2026.             IPDR-792                Updated the test methods "testTaskFromInvestigationInOpen" and "testTaskFromInvestigationInProcess" to get the 
																			 number of ticket searches and added the assert statement
																			Updated test method "testafterEventHandler" to return the the results for SOSL query.
* ----------------------------------------------------------------------------------------------------------------------------------------------*/

@isTest
public class ADDInvestigationTaskTriggerHandlerTest {

    @testSetup static void setup(){

        // Get profiles
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        Id aspenInteg = [SELECT Id FROM Profile WHERE Name = 'ASPEN Integration'].Id;

        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        // Create Users
        User u = TestUtil.insertTestUser(
            p.Id,
            'raj@test.com',
            'hiii12@test.com',
            'PEA2'
        );
        User u1 = TestUtil.insertTestUser(
            p.Id,
            'raj@test.com',
            'hiii@test.com',
            'PEI3'
        );
        User u2 = TestUtil.insertTestUser(
            p.Id,
            'raj@test.com',
            'hiii23@test.com',
            'PEA4'
        );
        
        User ssTestUser = TestUtil.insertTestUser(
            aspenInteg,
            'ssTestUser@test.com',
            'ssTestUser@test.com.test'
        );
        //Start - IPDR 82 - R3.1
        //Creating a test user 'complaintAccessorUser'
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User complaintAccessorUser = TestUtil.insertTestUser(
                aspenUserProfileId,
                'complaintAccessorUsertest82ipdr@test.com',
                'complaintAccessorUsertest82ipdr@test.com'
        );
        //Creating a test user 'complaintInvestigatorUser'
        User complaintInvestigatorUser = TestUtil.insertTestUser(
                aspenUserProfileId,
                'complaintInvestigatorUsertest82ipdr@test.com',
                'complaintInvestigatorUsertest82ipdr@test.com'
        );
        
        //Creating a system admin user 'systemAdmin'. This user will be used to assign permission sets to test user.
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User systemAdmin = TestUtil.insertTestUser(
                systemAdminProfileId,
                'systemAdminUsertest82ipdr@test.com',
                'systemAdminUsertest82ipdr@test.com'
        );
        
        //Fetch permission sets that are needed to be assigned to 'complaintAccessorUser' and 'complaintInvestigatorUser'
        PermissionSet PS1 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'Complaint_Assessor'
        ];
        
        PermissionSet PS2 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'Complaint_Evaluator_Investigator'
        ];
        
        PermissionSet PS3 = [
            SELECT Id FROM PermissionSet
            WHERE Name= 'X123Compliance_Permission_Set_for_Platform_User'
        ];
        
        //Running as systemAdmin to assign PS to test user complaintAccessorUser and complaintInvestigatorUser
        //This is to avoid Mixed DML excpetion as both setup and non-setup objects cannot be updated in same transaction.
        System.runAs(systemAdmin)
        {
            insert new permissionSetAssignment(
                AssigneeId = complaintAccessorUser.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = complaintAccessorUser.Id,
                PermissionSetId = PS2.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = complaintAccessorUser.Id,
                PermissionSetId = PS3.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = complaintInvestigatorUser.Id,
                PermissionSetId = PS1.Id
            );
            
            insert new permissionSetAssignment(
                AssigneeId = complaintInvestigatorUser.Id,
                PermissionSetId = PS2.Id
            );
        }
        //End - IPDR 82 - R3.1

        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c  = 'ADD',
                pRE_Status__c  = AspenConstants.STR_Yes,
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = AspenConstants.STR_Complaint,
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = AspenConstants.STR_WF_Opened,
                CMSNext_Ticket_Number__c = '123456',
                Trending_issue_Bucket__c = 'ProdEvel',
                Receipt_Date__c = System.today() - 5
        ), true);

        // Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Update Investigation
        objInvestigation.Assessor__c = u.Id;
        objInvestigation.Evaluator_Investigator__c = u1.Id;
        objInvestigation.Conclusion_Summary__c = 'Test';
        objInvestigation.Conclusion_Disposition__c = AspenConstants.STR_80064_NO_Deficiency_Malfunction;
        objInvestigation.Product_Evaluation_Type__c = 'Lot to lot variability';
        objInvestigation.Approver__c = u2.Id;
        objInvestigation.Additional_Action_Taken__c = AspenConstants.STR_No;
        objInvestigation.Close_to_Threshold__c = AspenConstants.STR_Yes;
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = AspenConstants.STR_No;
        objInvestigation.Not_Requested_Rationale__c = 'Test';
        objInvestigation.CMPL123_WF_Status__c = AspenConstants.STR_Assess;
        
        TestDataFactory.updateSObject(objInvestigation);

        System.runAs(ssTestUser) {
            // Create Product record
            CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'M2K OPT ADHSV CVR',
                    CMPL123__Lot_No__c = '1234',
                    Product_Registration_Number__c = 'TEST_REG_NUMB',
                    List_Number__c = '0AM16-40',
                    List_Base__c = '123 Dxt CVR'
            ), true);

            //Get Product ticket
            Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Event_Ticket__c = complaint.Id,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Batch_Lot_Serial__c = '123 Lot Serial Number',
                    Product__c = prod1.Id), true);

            //Get Product ticket
            Product_Ticket__c prodTicket1 = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                    Event_Ticket__c = complaint.Id,
                    Likely_Cause__c = AspenConstants.STR_Yes,
                    Batch_Lot_Serial__c = '123 Lot Serial Number',
                    Product__c = prod1.Id), true); 
        }
        
        insertData();
    }

    @future
    public static void insertData () {
        User ssTestUser = [SELECT Id FROM User WHERE Username LIKE 'ssTestUser@test.com.test%' LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Division__c = 'ADD'
                                              AND pRE_Status__c  = :AspenConstants.STR_Yes
                                              AND Country_of_origin__c  = 'INDIA'
                                              AND Business_Unit__c  = 'IA-CC'
                                              AND CMSNext_Ticket_Number__c = '123456'
                                              LIMIT 1];
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Product List Number').getRecordTypeId();
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Event_Ticket__c = :complaint.Id
                                        AND Likely_Cause__c = :AspenConstants.STR_Yes
                                        ORDER BY CreatedDate
                                        LIMIT 1];

        //Create Task
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                Parent_Ticket__C = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ), true);

        System.runAs(ssTestUser) {
            //Create Product Lot
            Product_Lot__c prodLot = (Product_Lot__c) TestDataFactory.createSObject(new Product_Lot__c(
                    Product_Evaluation_Investigation__c = objInvestigation.Id,
                    Product_Name__c = prodTicket.Id,
                    Related_Ticket__c = complaint.Id,
                    Device_Expiration_Date__c = System.today(),
                    Device_Expiration_Date_NA__c = false,
                    Device_Expiration_Date_Unknown__c = false,
                    Device_Manufacturing_Date__c = System.today(),
                    Device_Manufacturing_Date_NA__c = false

            ), true);
        }
    }

    /**
    * @Method       : testCreatingTaskFromInvestigationInOpen
    * @Description  : To test the Task_AuditTrigger.
    * @Return       : N/A
    * @Params       : N/A
    **/
    //when the workFlow status is Closed-Done
    static testmethod void testCreatingTaskFromInvestigationInOpen(){
        Test.startTest();
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Task
        Task__c Objtsk = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c = :objInvestigation.Id LIMIT 1];

        //Assert Requestor Name Updated?
        System.assertEquals(Objtsk.Requestor_Name__c,userinfo.getUserId());

        Objtsk.CMPL123_WF_Status__c =AspenConstants.STR_Closed_Done;
        Objtsk.Conclusion__c = 'closed';
        Objtsk.Result__c = 'result';
        TestDataFactory.updateSObject(Objtsk);
        Test.stopTest();
    }

    /**
    * @Method       : testTaskFromInvestigationInOpen
    * @Description  : To test the Task_AuditTrigger.
    * @Return       : N/A
    * @Params       : N/A
    **/
    //when the workFlow status is In-Process
    static testmethod void testTaskFromInvestigationInOpen(){
        Test.startTest();
        User objUser = [Select Id FROM User LIMIT 1];
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Product Ticket
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Event_Ticket__c =: complaint.Id LIMIT 1];

        //Get Task
        Task__c Objtsk = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c = :objInvestigation.Id LIMIT 1];

        //Assert Junction Object Created?
        System.assertEquals(1, [SELECT Count() FROM Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__c =:objInvestigation.Id AND Source_Leveraged__c ='Source']);

        Objtsk.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
        Objtsk.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_SUBMIT;
        Objtsk.Product_Ticket__c = prodTicket.Id;
        Objtsk.Parent_Ticket__c = complaint.Id;
        Objtsk.Assignee_Name__c=objUser.Id;
        TestDataFactory.updateSObject(Objtsk);
        //IPDR 792 - Added the below query to get number of ticket searches generated
        List<Ticket_Serach__c> ticketSearchList = [Select Id,Product_List_Part_Number__c,Batch_Lot_Serial__c,Trending_Issue_Bucket__c from Ticket_Serach__c where Evaluation_Investigation_Task__c = :Objtsk.Id];
        //Assert to check - one ticket search is generated when task status is updated from 'Opened' to 'In Process'
        System.assertEquals(1,ticketSearchList.size());
        Test.stopTest();
    }
    
    /**
    * @Method       : testTaskFromInvestigationInProcess
    * @Description  : To test the Task_AuditTrigger.
    * @Return       : N/A
    * @Params       : N/A
    **/
    //when the workFlow status is In-Process
    static testmethod void testTaskFromInvestigationInProcess(){

        String errorMessage = '';
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,LastModifiedDate,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get User
        User u = [SELECT ID FROM USER WHERE Email = 'raj@test.com' LIMIT 1];

        //Get Task
        Task__c objTask = [SELECT Id FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id LIMIT 1];

        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c WHERE Batch_Lot_Serial__c = '123 Lot Serial Number' LIMIT 1];

        Test.startTest();
        //Create Task
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
        Task__c objTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                Parent_Ticket__c = complaint.Id,
                RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ),true);

        //Update Investigation
        objInvestigation.Voided_Rationale__c = 'Test';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = AspenConstants.STR_Yes;
        objInvestigation.CMPL123_WF_Action__c = AspenConstants.STR_Invest_Req;
        objInvestigation.CMPL123_WF_Status__c =AspenConstants.STR_In_Process_Investigation;
        TestDataFactory.updateSObject(objInvestigation);


        try {
            objTask.Result__c = 'Result';
            objTask.Conclusion__c ='Conclusion';
            objTask.Include_Complaints__c = True ;
            objTask.Include_Demand_Service_Tickets__c = True ;
            objTask.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_SUBMIT;
            objTask.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
            objTask.Assignee_Name__c = u.Id;
            objTask.Product_Ticket__c = prodTicket.Id;
            TestDataFactory.updateSObject(objTask);
            //IPDR 792 - Added the below query to get number of ticket searches generated
            List<Ticket_Serach__c> ticketSearchList = [Select Id,Product_List_Part_Number__c,Batch_Lot_Serial__c,Trending_Issue_Bucket__c from Ticket_Serach__c where Evaluation_Investigation_Task__c = :objTask.Id];
            //Assert to check - one ticket search is generated when task status is updated from 'Opened' to 'In Process'
        	System.assertEquals(1,ticketSearchList.size());
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        try {
            objTaskRecord.Result__c = 'Result';
            objTaskRecord.Conclusion__c ='Conclusion';
            objTaskRecord.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_SUBMIT;
            objTaskRecord.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
            objTaskRecord.Assignee_Name__c = u.Id;
            objTaskRecord.Product_Ticket__c = prodTicket.Id;
            TestDataFactory.updateSObject(objTaskRecord);
            //IPDR 792 - Added the below query to get number of ticket searches generated
            List<Ticket_Serach__c> ticketSearchList = [Select Id,Product_List_Part_Number__c,Batch_Lot_Serial__c,Trending_Issue_Bucket__c from Ticket_Serach__c where Evaluation_Investigation_Task__c = :objTask.Id];
            //Assert to check - one ticket search is generated when task status is updated from 'Opened' to 'In Process'
        	System.assertEquals(1,ticketSearchList.size());
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        CMPL123CME__Investigation__c updatedInvestigation = [SELECT Id, LastModifiedDate, CMPL123_WF_Status__c 
            FROM CMPL123CME__Investigation__c WHERE Id =: objInvestigation.Id];

        System.assert('' == errorMessage);
        //Assert the LastModifiedDate field got updated
        System.assert(updatedInvestigation.LastModifiedDate > objInvestigation.LastModifiedDate);
        TestDataFactory.deleteSObject(objTask);
        TestDataFactory.deleteSObject(objTaskRecord);
        Test.stopTest();

    }

    /**
     * @Method       : testTaskFromInvestigationClosedDone
     * @Description  : To test the Task_AuditTrigger.
     * @Return       : N/A
     * @Params       : N/A
     **/
    //to check when the worfFlow status in Closed-Done
    static testmethod void testTaskFromInvestigationClosedDone(){
        Test.startTest();
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Task
        Task__c objTask = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id LIMIT 1];

        //Update Investigation
        objInvestigation.Voided_Rationale__c = 'Test';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = AspenConstants.STR_Yes;
        objInvestigation.CMPL123_WF_Action__c = AspenConstants.STR_Invest_Req;
        objInvestigation.CMPL123_WF_Status__c =AspenConstants.STR_In_Process_Investigation;
        try {
            TestDataFactory.updateSObject(objInvestigation);
        } catch (Exception E) {
            System.debug('===Exception==='+E);
        }
        try{
            objTask.Result__c = 'Result';
            objTask.Conclusion__c ='Conclusion';
            objTask.Include_Complaints__c = True ;
            objTask.Include_Demand_Service_Tickets__c = True ;
            objTask.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_COMPLETE_TASK;
            objTask.CMPL123_WF_Status__c = AspenConstants.STR_Closed_Done;
            TestDataFactory.updateSObject(objTask);
        } Catch(Exception E) {
            System.debug('===Exception==='+E);
        }
        //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)
        String exceptionMsg = null;
        try{
            //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)
            TestDataFactory.deleteSObject(objTask);
            //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)
        } Catch(Exception E) {
            exceptionMsg= e.getMessage();
        }

        //Assert statement to verify the error
        System.AssertEquals(
            true, 
            exceptionMsg.contains(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status), 
            'Did not find the expected message'
        );

        //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)
        Test.stopTest();

    }

    /**
     * @Method       : testTaskFromInvestigationClosedVoided
     * @Description  : To test the Task_AuditTrigger.
     * @Return       : N/A
     * @Params       : N/A
     **/
    //to check when the worfFlow status in Closed-Voided
    static testmethod void testTaskFromInvestigationClosedVoided(){

        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Task
        Task__c objTask = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id LIMIT 1];

        Test.startTest();
        //Update Investigation
        objInvestigation.Voided_Rationale__c = 'Test';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = AspenConstants.STR_Yes;
        objInvestigation.CMPL123_WF_Action__c = AspenConstants.STR_Invest_Req;
        objInvestigation.CMPL123_WF_Status__c =AspenConstants.STR_In_Process_Investigation;
        try {
            TestDataFactory.updateSObject(objInvestigation);
        } catch (Exception E) {
            System.debug('===Exception==='+E);
        }

        try{
            objTask.Result__c = 'Result';
            objTask.Conclusion__c ='Conclusion';
            objTask.Include_Complaints__c = True ;
            objTask.Include_Demand_Service_Tickets__c = True ;
            objTask.CMPL123_WF_Action__c =AspenConstants.STR_WF_Action_Void;
            objTask.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
            TestDataFactory.updateSObject(objTask);
        }Catch(Exception E){
            System.debug('===Exception==='+E);
        }
          //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)
          String exceptionMsg = null;
        try{
            //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)    
            TestDataFactory.deleteSObject(objTask);
            //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)    
        } Catch(Exception E) {
            exceptionMsg =  e.getMessage();
        }

        //Assert statement to verify the error
        System.AssertEquals(
            true, 
            exceptionMsg.contains(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status), 
            'Did not find the expected message'
        );
        //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)
        Test.stopTest();

    }

    /**
    * @Method       : testTaskFromInvestigationReopen
    * @Description  : To test the Task_AuditTrigger.
    * @Return       : N/A
    * @Params       : N/A
    **/
    //to check when the worfFlow status in In Process by Reopen Action
    static testmethod void testTaskFromInvestigationReopen(){


        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Task
        Task__c objTask = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id LIMIT 1];

        Test.startTest();
        //Update Investigation
        objInvestigation.Voided_Rationale__c = 'Test';
        objInvestigation.Prod_Eval_Returns_to_be_Requested__c = AspenConstants.STR_Yes;
        objInvestigation.CMPL123_WF_Action__c = AspenConstants.STR_Invest_Req;
        objInvestigation.CMPL123_WF_Status__c =AspenConstants.STR_In_Process_Investigation;
        try {
            TestDataFactory.updateSObject(objInvestigation);
        } catch (Exception E) {
            System.debug('===Exception==='+E);
        }

        try{
            objTask.Result__c = 'Result';
            objTask.Conclusion__c ='Conclusion';
            objTask.CMPL123_WF_Action__c =AspenConstants.STR_Reopen;
            objTask.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
            TestDataFactory.updateSObject(objTask);
        }Catch(Exception E){
            System.debug('===Exception==='+E);
        }

        //Get Task Product Evaluation Investigation
        Task_Product_Evaluation_Investigation__c TaskProEvaInv = [SELECT Id, Name,
                Investigation_Evaluation__c, Task__c, Source_Leveraged__c FROM
                Task_Product_Evaluation_Investigation__c WHERE Investigation_Evaluation__c =:objInvestigation.Id
        AND Source_Leveraged__c ='Source' LIMIT 1];

        //Update Task Product Evaluation Investigation
        TaskProEvaInv.Source_Leveraged__c = 'Leveraged';
        TestDataFactory.updateSObject(TaskProEvaInv);

        //Assert the error message when delete
        try{
            TestDataFactory.deleteSObject(objTask);
        }Catch(Exception E){
            String message = e.getMessage();
            //Assert for delete task when
            System.assert(message.contains('The task cant be deleted as it is a leveraged task. Disconnect the task from related Product Evaluation/Investigation records before deleting the task or change the task source.'),
                    'message=' + message);
        }

        Test.stopTest();

    }

    /*
     * @Method       :
     * @Description  :   To test the Hazard_Assessment_AuditTriggerfunctionality.
     * @Return       : N/A
     * @Params       : N/A
     */
    //when the workFlow status is Closed
    static testmethod void testCreatingTaskFromInvestigation(){

        Test.startTest();
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];
        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Create Task
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id,RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),true);
        //System.assertEquals(1, [SELECT count() FROM Task_Product_Evaluation_Investigation__c]);
        objTask.Result__c = 'Test';
        objTask.Conclusion__c ='Test';
        //objTask.Include_Complaints__c = true;
        objTask.CMPL123_WF_Status__c = AspenConstants.STR_Closed_Done;
        TestDataFactory.updateSObject(objTask);
        //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)
        String exceptionMsg = null;
        try{
            //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE)    
            DELETE objTask;
            //IPDR 82 start - CHARM 3.1 - added the below code to capture the error message and for code coverage By Dinesh Kumar(COE)    
        } 
        Catch(Exception E) {
            exceptionMsg= e.getMessage();
        }

        //Assert statement to verify the error
        System.AssertEquals(
            true, 
            exceptionMsg.contains(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status), 
            'Did not find the expected message'
        );
        //IPDR 82 End - CHARM 3.1 By Dinesh Kumar(COE) 
        Test.stopTest();
    }

    //to check when the worfFlow status in In-Process
    static testmethod void testCreatingTaskFromInvestigationInProcess(){

        Test.startTest();
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Create Task
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Product List Number').getRecordTypeId();
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id,RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),true);

        objTask.Include_Complaints__c = true;
        objTask.Include_Demand_Service_Tickets__c=true;
        objTask.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
        TestDataFactory.updateSObject(objTask);
        DELETE objTask;
        Test.stopTest();

    }

    // [CR] 1029/1198 
    @IsTest
    private static void taskReopenTest() {
        Test.startTest();
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User admin = TestUtil.insertTestUser(
                adminProfileId,
                'admin@test.com',
                'adminTest@test.com'
        );

        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_Closed_Done), true);
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = AspenConstants.STR_In_Process), true);
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = AspenConstants.STR_Reopen,
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Ticket based Task workflow',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'Tickets_Task',
                        CMPL123__Target_Object__c = 'Task__c(Tickets_Task)'),
                true
        );

        CMPL123__WF_Step__c wfStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRule.Id,
                        CMPL123__Action__c = wfAction.Id,
                        CMPL123__End_Status__c = endStatus.Id,
                        CMPL123__Start_Status__c = startStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Permission_Group__c = 'Evaluator/Investigator',
                        CMPL123__Order__c = 1.0
                ), true);

        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('Ticket History Review By Product List Number').getRecordTypeId();
        Task__c objTaskClosed = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                Conclusion__c = 'Test',
                Result__c = 'Test',
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = AspenConstants.STR_Closed_Done
        ),true);

        Id evaInvestGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Evaluator_Investigator'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;

        User evalInvestigator = TestUtil.insertTestUser(
                aspenUserProfileId,
                'test@test.com',
                'medEvalTest@test.com'
        );

        System.runAs(admin) {
            insert new GroupMember(
                    GroupId = evaInvestGroupId,
                    UserOrGroupId = evalInvestigator.Id
            );
        }
        System.runAs(evalInvestigator) {
            objTaskClosed.CMPL123_WF_Status__c = endStatus.Name;
            objTaskClosed.CMPL123_WF_Action__c = wfAction.Name;
            update objTaskClosed;
        }
        Test.stopTest();

        Task__c result = [
                SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
                FROM Task__c
                WHERE Id =: objTaskClosed.Id
        ];

        System.assertEquals(endStatus.Name, result.CMPL123_WF_Status__c);
        System.assertEquals(wfAction.Name, result.CMPL123_WF_Action__c);
    }
    
    /*
    * @Method       : taskWFTest.
    * @Description  : To test WF functionality that was moved to trigger handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void taskWFTest() {
        //WF: Auto set Assigned Date
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        Test.startTest();
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('Ticket History Review By Product List Number').getRecordTypeId();
        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                Conclusion__c = 'Test',
                Result__c = 'Test',
                CMPL123_WF_Action_Performed_On__c = date.today(),
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = AspenConstants.STR_In_Process
        ),true);
        System.assertEquals(date.today(), [SELECT Assigned_Date__c FROM Task__c WHERE Id =: task.Id].Assigned_Date__c);
        //WF: Update workflow based on record type   
        System.assertEquals('Tickets_Task', [SELECT CMPL123Rule_Key_Value__c FROM Task__c WHERE Id =: task.Id].CMPL123Rule_Key_Value__c);
        task.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
        task.Assigned_Date__c = null;
        update task;
        task.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
        update task;
        System.assertEquals(date.today(), [SELECT Assigned_Date__c FROM Task__c WHERE Id =: task.Id].Assigned_Date__c);
        
        //WF: Autoset Product Registration Number & Legal Manufacturer
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c LIMIT 1];

        taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('China GSP Regulation').getRecordTypeId();
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                Conclusion__c = 'Test',
                Result__c = 'Test',
                Parent_Ticket__c = complaint.Id, 
                Product_Ticket__c = prodTicket.Id, 
                CMPL123_WF_Action_Performed_On__c = date.today(),
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = AspenConstants.STR_In_Process
        ),true);
        System.assertEquals('TEST_REG_NUMB', [SELECT Product_Ticket__r.Product__r.Product_Registration_Number__c, Product_Registration_Number__c FROM Task__c WHERE Id =: task.Id].Product_Registration_Number__c);
        //WF: Update workflow based on record type   
        System.assertEquals('Prod_Eval_Task', [SELECT CMPL123Rule_Key_Value__c FROM Task__c WHERE Id =: task.Id].CMPL123Rule_Key_Value__c);
        Test.stopTest();
    }

    /*
    * @Method       : taskWFTest2.
    * @Description  : To test WF functionality that was moved to trigger handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void taskWFTest2() {
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c LIMIT 1];
        
        Test.startTest();
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('China GSP Regulation').getRecordTypeId();
        Product_Ticket__c prodTicket = [SELECT Id FROM Product_Ticket__c LIMIT 1];
        //WF: Autoset TPM fields
        TPM__c tpm =  (TPM__c) TestDataFactory.createSObject(
                new TPM__c(Name = 'Test',
                        TPM_Contact_Email__c = 'test@contact.email',
                        TPM_Contact_Name__c = 'Test name'), true);
        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                Conclusion__c = 'Test',
                Result__c = 'Test',
                Parent_Ticket__c = complaint.Id, 
                Product_Ticket__c = prodTicket.Id, 
                CMPL123_WF_Action_Performed_On__c = date.today(),
                RecordTypeId = taskRTId,
                CMPL123_WF_Status__c = AspenConstants.STR_In_Process,
                CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId(),
                TPM__c = tpm.Id
        ),true);
        System.assertEquals('Test name', [SELECT TPM_Contact_Name__c FROM Task__c WHERE Id =: task.Id].TPM_Contact_Name__c);

        tpm =  (TPM__c) TestDataFactory.createSObject(
                new TPM__c(Name = 'Test2',
                        TPM_Contact_Email__c = 'test2@contact.email',
                        TPM_Contact_Name__c = 'Test name2'), true);
        task.TPM__c = tpm.Id;
        update task;
        System.assertEquals('Test name2', [SELECT TPM_Contact_Name__c FROM Task__c WHERE Id =: task.Id].TPM_Contact_Name__c);
        //WF: Clear Reject fields and Skip Pre Approval if Is Protocol Pre-Approval is yes  
        task.Rejected_By__c = UserInfo.getUserId();
        task.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_SUBMIT;
        // 07-FEB-2023 Larry: This field is not interacted with by automated processes nor by actual people
        // task.Is_Protocol_Pre_approved__c  = 'Yes';
        task.Assignee_Name__c = UserInfo.getUserId();
        update task;
        System.assertEquals(null, [SELECT Rejected_By__c FROM Task__c WHERE Id =: task.Id].Rejected_By__c);
        System.assertNotEquals('PostInProgessTask', [SELECT CMPL123Task_Key_Value__c FROM Task__c WHERE Id =: task.Id].CMPL123Task_Key_Value__c,
            'This 123Task was not accessible in the first place, and should be removed from the org');
        //WF:Update Task performed by and time for custom fields
        System.assertEquals(UserInfo.getFirstName() + ' ' + UserInfo.getLastName(), [SELECT Task_Item_Submitted_By__c FROM Task__c WHERE Id =: task.Id].Task_Item_Submitted_By__c );
        Test.stopTest();
    }
    
    /*
    * @Method       : testWf.
    * @Description  : To test WF functionality that was moved to trigger handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testWf() {
        //WF: Autoset Registration Number
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('Ticket History Review By Product List Number').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_Number__c = '123456' LIMIT 1];
        
        Test.startTest();
        //Create Task
        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                Parent_Ticket__c = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ), true);
        System.assertEquals('123456(Complaint)', [SELECT Registration_Number__c FROM Task__c WHERE Id =: task.Id].Registration_Number__c);
        //WF: Update Time Frame 
        System.assertEquals(12, [SELECT Timeframe_in_Months__c FROM Task__c WHERE Id =: task.Id].Timeframe_in_Months__c);
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Service').getRecordTypeId();
        CMPL123CME__Complaint__c service = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Complaint_Demotion_rationale__c = '',
                Demotion_rationale__c = '',
                Complaint_Demoted_By__c = UserInfo.getName(),
                Complaint_Demotion_Date__c = System.Now(),
                Division__c  = 'ADD',
                pRE_Status__c  = AspenConstants.STR_Yes,
                Country_of_origin__c = 'INDIA',
                RecordTypeId = serviceRTId,
                Service_Type__c = 'Planned',
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = 'Service',
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = AspenConstants.STR_WF_Opened,
                CMSNext_Ticket_Number__c = '12345678',
                CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
                Trending_issue_Bucket__c = 'ProdEvel',
                Receipt_Date__c = System.today() - 5
        ), true);
        objInvestigation.CMPL123CME__Complaint__c = service.Id;
        update objInvestigation;
        //Create Task
        task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                Parent_Ticket__c = service.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ), true);
        Test.stopTest();
        System.assertEquals('12345678(Planned Service)', [SELECT Registration_Number__c FROM Task__c WHERE Id =: task.Id].Registration_Number__c);
        //WF: Update Threshold URL  
        System.assertNotEquals(null, [SELECT Threshold_Report_URL_Part_1__c FROM Task__c WHERE Id =: task.Id].Threshold_Report_URL_Part_1__c);
        
    }
    
     /*
    * @Method       : testWfActions.
    * @Description  : To test WF functionality that was moved to trigger handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testWfActions() {
        
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('Ticket History Review By Product List Number').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_Number__c = '123456' LIMIT 1];
        
        Test.startTest();
        //Create Task
        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                Parent_Ticket__c = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ), true);
        //WF: Workflow - Complete
        task.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_COMPLETE_TASK;
        task.Reopened_By__c = UserInfo.getUserId();
        update task;
        System.assertEquals(null, [SELECT Reopened_By__c FROM Task__c WHERE Id =: task.Id].Reopened_By__c );
        //WF: Workflow - Reopen
        task.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
        task.Task_Item_Completed_By__c= UserInfo.getUserId();
        update task;
        System.assertEquals(null, [SELECT Task_Item_Completed_By__c FROM Task__c WHERE Id =: task.Id].Task_Item_Completed_By__c);
        Test.stopTest();
    }

    /*
    * @Method       : testWfActions2.
    * @Description  : To test WF functionality that was moved to trigger handler.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testWfActions2() {
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id, CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c LIMIT 1];
        String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName()
                .get('Ticket History Review By Product List Number').getRecordTypeId();
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE CMSNext_Ticket_Number__c = '123456' LIMIT 1];
        
        Test.startTest();
        //Create Task
        Task__c task = (Task__c) TestDataFactory.createSObject(new Task__c(
                Related_Investigation_Evaluation__c = objInvestigation.Id,
                RecordTypeId = taskRTId,
                Parent_Ticket__c = complaint.Id,
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
        ), true);
        //WF: Workflow - Request More Information
        task.CMPL123_WF_Action__c = AspenConstants.STR_Request_More_Information;
        task.Task_Item_Approved_By__c = UserInfo.getUserId();
        task.Request_More_Information__c = 'TEST';
        update task;
        System.assertEquals(null, [SELECT Task_Item_Approved_By__c FROM Task__c WHERE Id =: task.Id].Task_Item_Approved_By__c );
        //WF: Update Task performed by and time for custom fields
        task.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_REJECT;
        task.CMPL123_WF_Action_Performed_By__c = UserInfo.getUserId();
        task.CMPL123_WF_Action_Performed_On__c = datetime.now();
        task.Rejection_Rationale__c = 'TEST';
        update task;
        System.assertNotEquals(null, [SELECT Rejected_By__c FROM Task__c WHERE Id =: task.Id].Rejected_By__c );
        task.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Approve;
        update task;
        System.assertNotEquals(null, [SELECT Task_Item_Approved_By__c FROM Task__c WHERE Id =: task.Id].Task_Item_Approved_By__c );
        task.CMPL123_WF_Action__c = AspenConstants.STR_WF_ACTION_SUBMIT_PRE_APPROVAL;
        task.Assignee_Name__c = UserInfo.getUserId();
        update task;
        System.assertNotEquals(null, [SELECT Task_Item_Submit_for_Pre_Approval_By__c FROM Task__c WHERE Id =: task.Id].Task_Item_Submit_for_Pre_Approval_By__c );
        Test.stopTest();
    }
    
    /**
     * @Method       : deleteTaskRecordInClosedDoneWithCorrectUser
     * @Description  : Testing the Assert by capturing the Error when Deleting the Task record in Closed Done status and by the User Populated in Assignee Name field. 
     * @Return       : N/A
     * @Params       : N/A
     * @Release      : CHARM 3.1- IPDR 82
     **/
    static testmethod void deleteTaskRecordInClosedDoneWithCorrectUser(){

        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,Last_Modified_Date_Time__c,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get Task
        Task__c objTask = [SELECT Id,Requestor_Name__c FROM Task__c WHERE Related_Investigation_Evaluation__c =: objInvestigation.Id LIMIT 1];
        User complaintAccessorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintAccessorUsertest82ipdr@test.com'];

        objTask.Result__c = 'Result';
        objTask.Conclusion__c ='Conclusion';
        objTask.Include_Complaints__c = True ;
        objTask.Include_Demand_Service_Tickets__c = True ;
        objTask.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_COMPLETE_TASK;
        objTask.CMPL123_WF_Status__c = AspenConstants.STR_Closed_Done;
        objTask.Assignee_Name__c = complaintAccessorUser.Id;
        TestDataFactory.updateSObject(objTask);

        String exceptionMsg = null;
        try{
            System.runAs(complaintAccessorUser){
                Test.startTest();
                TestDataFactory.deleteSObject(objTask);
                Test.stopTest();
            }
        } Catch(Exception E) {
            exceptionMsg = e.getMessage();
        }

        //Assert statement to verify the error
        System.AssertEquals(
            true, 
            exceptionMsg.contains(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status), 
            'Did not find the expected message'
        );
    }

    /**
     * @Method       : deleteTaskRecordInOpenedWithWrongUser
     * @Description  : Testing the Assert by capturing the Error when Deleting the Task record in Opened status and by the User not Populated in Assignee Name field.  
     * @Return       : N/A
     * @Params       : N/A
     * @Release      : CHARM 3.1- IPDR 82
     **/

    static testmethod void deleteTaskRecordInOpenedWithWrongUser(){

        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];
        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];
        User complaintAccessorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintAccessorUsertest82ipdr@test.com'];
        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
        //Create Task
       // String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),true);
        objTask.Assignee_Name__c = complaintAccessorUser.Id;
        TestDataFactory.updateSObject(objTask);

        String exceptionMsg = null;
        try{
            System.runAs(complaintInvestigatorUser){
                Test.startTest();
                DELETE objTask;
                Test.stopTest();
            }
        } Catch(Exception E) {
            exceptionMsg = e.getMessage();
        }

        //Assert statement to verify the error
        System.AssertEquals(
            true, 
            exceptionMsg.contains(System.Label.Cannot_delete_evaluation_Investigation_Task_if_not_in_Opened_or_Inprocess_status), 
            'Did not find the expected message'
        );
    }

   /*
    * @Method       : deleteTaskRecordInOpenedWithCorrectUser
    * @Description  : Successfully Deleting the Task record in Opened status with the User populated in the Assignee Name field
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM 3.1- IPDR 82
    */
  static testmethod void deleteTaskRecordInOpenedWithCorrectUser(){

        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];
        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
        //Create Task
        Task__c objTask = (Task__c) TestDataFactory.createSObject(new Task__c(Related_Investigation_Evaluation__c = objInvestigation.Id,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),true);
        objTask.Assignee_Name__c = complaintInvestigatorUser.Id;
        TestDataFactory.updateSObject(objTask);

        System.runAs(complaintInvestigatorUser){
            Test.startTest();
            DELETE objTask;
            Test.stopTest();
        }
        Task__c deletedTask = [Select Id, IsDeleted  from Task__c where Id = :objTask.Id ALL ROWS ];

        //Assert statement to check if task is deleted
        System.AssertEquals(deletedTask.IsDeleted, true, 'Task record has not been deleted'); 
    }
    /**
    * @Method       : testafterEventHandler
    * @Description  : To test the Include Sublot functionality.
    * @Return       : N/A
    * @Params       : N/A
    **/
    //when the workFlow status is In-Process
    static testmethod void testafterEventHandler(){
        String errorMessage = '';
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,LastModifiedDate,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get User
        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
		
        CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'M2K OPT ADHSV CVR',
                    CMPL123__Lot_No__c = '1234',
                    Product_Registration_Number__c = 'TEST_REG_NUMB',
                    List_Number__c = '0AM16-40',
                    List_Base__c = '123 Dxt CVR'
            ), true);
    
                //Get Product ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'LotSerial',
                Product__c = prod1.Id), true);
        Product_Ticket__c prodTicket2 = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'LotSeri12',
                Product__c = prod1.Id), true);
        System.runAs(complaintInvestigatorUser){
            //IPDR-792: Used specifically to define the results returned by SOSL queries within a test method. 
            //by default, SOSL queries in test contexts return empty results to ensure predictable test behavior, regardless of the test data inserted in the test class.
            Test.setFixedSearchResults(new List<Id>{ prodTicket.Id, prodTicket2.Id });
            Test.startTest();
            //Create Task
            String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
            Task__c objTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                    Related_Investigation_Evaluation__c = objInvestigation.Id,
                    Parent_Ticket__c = complaint.Id,
                    RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                    Product_Ticket__c = prodTicket.Id,
                    Include_Sublot__c = True
            ),true);
            
            try {
                objTaskRecord.Result__c = 'Result';
                objTaskRecord.Conclusion__c ='Conclusion';
                objTaskRecord.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_SUBMIT;
                objTaskRecord.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
                objTaskRecord.Assignee_Name__c = complaintInvestigatorUser.Id;
                TestDataFactory.updateSObject(objTaskRecord);
            } catch (Exception e) {
                errorMessage = e.getMessage();
            }
            Test.stopTest();
            //Query added on 7th-Jan-2025 as part of IPDR-792.
             List<Ticket_Serach__c> ticketSearchList = [Select Id from Ticket_Serach__c where Evaluation_Investigation_Task__c = :objTaskRecord.Id];
            // Assert to check that two Ticket Searches are generated, when two Product-Tickets are linked to same Ticket which are having first 7 characters same
            System.assertEquals(2,ticketSearchList.size());
    	}
        System.assertEquals('', errorMessage, 'There should be no unexpected error');
    }
    
    /*
    * @Method       : testRegularSearch
    * @Description  : To test the regular search functionality when Include Sublot is false.
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM 7- IPDR 575
    */    
    static testmethod void testRegularSearch(){
        String errorMessage = '';
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,LastModifiedDate,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get User
        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
		
        CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'M2K OPT ADHSV CVR',
                    CMPL123__Lot_No__c = '1234',
                    Product_Registration_Number__c = 'TEST_REG_NUMB',
                    List_Number__c = '0AM16-40',
                    List_Base__c = '123 Dxt CVR'
            ), true);
		
            //Create Product ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'LotSerial',
                Product__c = prod1.Id), true);
        
        Test.startTest();
        // Create Second Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get(AspenConstants.STR_Complaint).getRecordTypeId();
        CMPL123CME__Complaint__c complaint2 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c  = 'ADD',
                pRE_Status__c  = AspenConstants.STR_Yes,
                Country_of_origin__c  = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c  = 'IA-CC',
                Ticket_Type__c = AspenConstants.STR_Complaint,
                Is_Product_Evaluation_Investigation_chil__c = false,
                CMPL123CME__CMPL123_WF_Status__c  = AspenConstants.STR_WF_Opened,
                CMSNext_Ticket_Number__c = '123789',
                Trending_issue_Bucket__c = 'ProdEvel',
                Receipt_Date__c = System.today() - 5
        ), true);
        //Create Second Product ticket
        Product_Ticket__c prodTicket1 = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint2.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'lotSerial',
                Product__c = prod1.Id), true);
        System.runAs(complaintInvestigatorUser){
            //Create Task
            String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
            Task__c objTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                    Related_Investigation_Evaluation__c = objInvestigation.Id,
                    Parent_Ticket__c = complaint.Id,
                    RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                    Product_Ticket__c = prodTicket.Id,
                    Include_Sublot__c = False
            ),true);
            
            try {
                objTaskRecord.Result__c = 'Result';
                objTaskRecord.Conclusion__c ='Conclusion';
                objTaskRecord.CMPL123_WF_Action__c =AspenConstants.STR_WF_ACTION_SUBMIT;
                objTaskRecord.CMPL123_WF_Status__c = AspenConstants.STR_In_Process;
                objTaskRecord.Assignee_Name__c = complaintInvestigatorUser.Id;
                TestDataFactory.updateSObject(objTaskRecord);
            } catch (Exception e) {
                errorMessage = e.getMessage();
            }
            Test.stopTest();
            //Query added on 7th-Jan-2025 as part of IPDR-792.
            List<Ticket_Serach__c> ticketSearchList = [Select Id from Ticket_Serach__c where Evaluation_Investigation_Task__c = :objTaskRecord.Id];
            // Assert to check that two Ticket Searches are generated, regardless of character casing (uppercase or lowercase)
            System.assertEquals(2,ticketSearchList.size());
        }
        System.assertEquals('', errorMessage, 'There should be no unexpected error');
    }
    
    /*
    * @Method       : testLotToReviewLengthRequiredVRLessThan9
    * @Description  : Validation error is thrown when try to make 'Include_Sublot__c' field as True and 'Lot_to_Review__c' is having less than 9 characters
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM 7- IPDR 575
    */
  	static testmethod void testLotToReviewLengthRequiredVRLessThan9(){
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,LastModifiedDate,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get User
        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
		
        CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'M2K OPT ADHSV CVR',
                    CMPL123__Lot_No__c = '1234',
                    Product_Registration_Number__c = 'TEST_REG_NUMB',
                    List_Number__c = '0AM16-40',
                    List_Base__c = '123 Dxt CVR'
            ), true);

        //Get Product ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'Serial',
                Product__c = prod1.Id), true);
        System.runAs(complaintInvestigatorUser){
        	Test.startTest();       
            try {
                //Create Task
                String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
                Task__c objTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                        Related_Investigation_Evaluation__c = objInvestigation.Id,
                        Parent_Ticket__c = complaint.Id,
                        RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                        Product_Ticket__c = prodTicket.Id,
                        Include_Sublot__c = TRUE
                ),true);      	
            } 
            catch (Exception e) {
                String msg = e.getmessage();
                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                    String errorMessage = msg.substring(startIndex).trim();
                    // Assert to check - Include Sub-Lots’ can be checked only when Lot to Review field length is 9 characters is throwing
                    system.assertEquals(True, errorMessage.contains('Include Sub-Lots’ can be checked only when Lot to Review field length is 9 characters.'));
                }
            }
            Test.stopTest();
        }
  	}
    
    /*
    * @Method       : testLotToReviewLengthRequiredVRGreaterThan9
    * @Description  : Validation error is thrown when try to make 'Include_Sublot__c' field as True and 'Lot_to_Review__c' is having less than 9 characters
    * @Return       : N/A
    * @Params       : N/A
    * @Release      : CHARM 7- IPDR 575
    */
  	static testmethod void testLotToReviewLengthRequiredVRGreaterThan9(){
        //Get the Complaint Record
        CMPL123CME__Complaint__c complaint = [SELECT Id,CMSNext_Ticket_Number__c,CMPL123CME__CMPL123_WF_Status__c FROM CMPL123CME__Complaint__c WHERE pRE_Status__c = :AspenConstants.STR_Yes LIMIT 1];

        //Get Investigation
        CMPL123CME__Investigation__c objInvestigation = [SELECT Id,LastModifiedDate,CMPL123_WF_Status__c FROM CMPL123CME__Investigation__c WHERE CMPL123CME__Complaint__c =: complaint.Id];

        //Get User
        User complaintInvestigatorUser = [SELECT Id, Email FROM User WHERE Email =: 'complaintInvestigatorUsertest82ipdr@test.com'];
		
        CMPL123__Product__c prod1 = (CMPL123__Product__c) TestDataFactory.createSObject(new CMPL123__Product__c(
                    Name = 'M2K OPT ADHSV CVR',
                    CMPL123__Lot_No__c = '1234',
                    Product_Registration_Number__c = 'TEST_REG_NUMB',
                    List_Number__c = '0AM16-40',
                    List_Base__c = '123 Dxt CVR'
            ), true);

        //Get Product ticket
        Product_Ticket__c prodTicket = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
                Event_Ticket__c = complaint.Id,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Batch_Lot_Serial__c = 'BatchLotSerial',
                Product__c = prod1.Id), true);
        System.runAs(complaintInvestigatorUser){
            Test.startTest(); 
            //Create Task
            String taskRTId = Schema.SObjectType.Task__c.getRecordTypeInfosByName().get('Ticket History Review By Lot Number').getRecordTypeId();
            Task__c objTaskRecord = (Task__c) TestDataFactory.createSObject(new Task__c(
                    Related_Investigation_Evaluation__c = objInvestigation.Id,
                    Parent_Ticket__c = complaint.Id,
                    RecordTypeId = taskRTId,CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                    Product_Ticket__c = prodTicket.Id,
                    Include_Sublot__c = False
            ),true);    
            try {
                objTaskRecord.Include_Sublot__c = True;
                update objTaskRecord;
            } 
            catch (Exception e) {
                String msg = e.getmessage();
                if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                    String errorMessage = msg.substring(startIndex).trim();
                    // Assert to check - Include Sub-Lots’ can be checked only when Lot to Review field length is 9 characters is throwing
                    system.assertEquals(True, errorMessage.contains('Include Sub-Lots’ can be checked only when Lot to Review field length is 9 characters.'));
                }
            }
            Test.stopTest();
        }
  	}
}