/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ComplaintTriggerHandler_Test.
* @Why   : Unit tests for ComplaintTriggerHandler, CMPL123CME_Complaint_AuditTrigger.
* @When  : 24-AUG-2018.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID        Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                   24-AUG-2018            N/A                    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                   07-APR-2020            CR 1661                Created 'CRTicketReopenTest' method.
* --------------------------------------------------------------------------------------------------------------------------------------
* dskak                   13-MAY-2020            CR 1661                Modified 'CRTicketReopenTest' method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                   03-JUN-2020            N/A                    Test class optimization
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                   10-JUN-2020            N/A                    Updated code part, which is related to Users' insertion. This
*                                                                       change designed to prevent a 'DUPLICATE_USERNAME' error during
*                                                                       deployment to Production environment. 
* --------------------------------------------------------------------------------------------------------------------------------------
* oober                   29-DEC-2020            TWD Upgrade Issue      Added clearReadyForclosureFlagWhenTicketIsReopenedWFRuleTest,
*                                                                       setComplaintCompleteDateWFRuleTest, setTicketCloseDateWFRuleTest,
*                                                                       updatePreToYesDateWFRuleTest methods.
*  --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   05-JAN-2021            Upgrade Issue #41      Adjusted test setup data, added testCustomerResponseClosing and
                                                                        testCustomerResponseReopening.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   14-JAN-2021            Upgrade Issue #84      AAdded reopenComplaintTest, reopenInquiryTest and
                                                                        reopenServiceTest methods.
* --------------------------------------------------------------------------------------------------------------------------------------
* COE                     30-May-2023            IPDR 506(Release3.1)   Added new methods 'closeandReopenComplaintTest', 'doNotPopulateInquiryTicketFieldsTest',
                                                                        'refreshTicket' and 'ticketCreatedDateLessthanOriginalTicketEffectiveDateTest'
                                                                        Updated method 'insertTestData' to add test users 
                                                                        'complaintAccessorUser' and 'systemAdmin'
* --------------------------------------------------------------------------------------------------------------------------------------
* Soumith                 20-Sep-2024                                    Added customerResponseTicketTypeUpdateTest methods.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class ComplaintTriggerHandler_Test {
     private static final string EMAIL_STD_ONE = 'complaintAccessorUsertest506ipdr@test.com';
     private static final string EMAIL_ADMIN_ONE = 'systemAdminUsertest506ipdr@test.com';
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    private static void setup() {
        insertTestData();
    }

    /*
    * @Method       : insertTestData.
    * @Description  : Helper to insert test data with increased limits.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    static void insertTestData() {
        //Start- CHARM 3.1- IPDR 506 - To fetch the Static resource value for the "Original Ticket date Effective from" which stores the Date/Time value.
        Test.loadData(CHaRM_Misc_Settings__c.sObjectType, 'CHARM_Misc_Static_Resource');
        //End - CHARM 3.1- IPDR 506
        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Open'),
                true
        );
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Voided'),
                true
        );
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Void'),
                true
        );

        // Create Customer Response WF Rule start
        CMPL123__WF_Status__c startCRStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Opened'),
                false
        );
        CMPL123__WF_Status__c endCRStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Voided'),
                false
        );

        insert new List<CMPL123__WF_Status__c> { startCRStatus, endCRStatus };
        
        CMPL123__WF_Action__c voidActionCustomerResponse = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Void',
                        CMPL123__Is_ESign_Required__c = false),
                false
        );
        CMPL123__WF_Action__c reopenActionCustomerResponse = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Reopen',
                        CMPL123__Is_ESign_Required__c = false),
                false
        );
        insert new List<CMPL123__WF_Action__c> { voidActionCustomerResponse, reopenActionCustomerResponse };

        CMPL123__WF_Rule__c wfRuleCustomerResponse = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Complaint_Customer_Response',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'Complaint_Customer_Response',
                        CMPL123__Target_Object__c = 'Customer_Response__c(Complaint_Customer_Response)'),
                true
        );
        insert new List<CMPL123__WF_Step__c> {
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRuleCustomerResponse.Id,
                        CMPL123__Action__c = voidActionCustomerResponse.Id,
                        CMPL123__End_Status__c = endCRStatus.Id,
                        CMPL123__Start_Status__c = startCRStatus.Id,
                        CMPL123__Is_Start_Step__c = true,
                        CMPL123__Order__c = 1.0
                ),
                new CMPL123__WF_Step__c(
                        CMPL123__WF_Rule__c = wfRuleCustomerResponse.Id,
                        CMPL123__Action__c = reopenActionCustomerResponse.Id,
                        CMPL123__End_Status__c = startCRStatus.Id,
                        CMPL123__Start_Status__c = endCRStatus.Id,
                        CMPL123__Order__c = 1.0
                )
        };
        // Create Customer Response WF Rule end

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        //CHaRM-R5
        String inquiryRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId();
        
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'INDIA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Void',
                        Likely_Cause__c = 'Yes',
                        Customer_Reply_Required__c = false,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                        CMPL123CME__CMPL123_WF_Action__c = 'Void',
                        Overall_Reportable_Status__c = 'Reportable',
                        Is_Product_Evaluation_Investigation_chil__c = true,
                        Med_Evaluator_Pending_MDCs__c = false),
                true
        );
        CMPL123CME__Complaint__c complaint2 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'USA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        //Ticket_Type__c = 'Inquiry',
                        CMSNext_Ticket_Number__c = 'CN-164835',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress',
                        CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved'),
                true
        );
        //CHaRM R5: Start: Creted the test data setup
        CMPL123CME__Complaint__c complaint3 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'China',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        Ticket_Type__c = 'Complaint',
                        CMSNext_Ticket_Number__c = 'CN-1648358',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress',
                        CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved'),
                true
        );
         CMPL123CME__Complaint__c complaint4 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'Germany',
                        RecordTypeId = inquiryRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        Ticket_Type__c = 'Inquiry',
                        CMSNext_Ticket_Number__c = 'CN-16483590',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );//CHaRM R5: End
        CMPL123CME__Investigation__c investigation = (CMPL123CME__Investigation__c) TestDataFactory.createSObject(
                new CMPL123CME__Investigation__c(
                        CMPL123CME__Complaint__c = complaint.Id,
                        CMPL123_WF_Status__c = 'Opened',
                        CMPL123_WF_Action_Performed_On__c = System.today()),
                true
        );

        CMPL123__WF_Rule__c wfRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(
                new CMPL123__WF_Rule__c(
                        Name = 'Test123',
                        CMPL123__Is_Active__c = true,
                        CMPL123__Has_Multiple_Actions__c = true,
                        CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW',
                        CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(COMPLAINT_WORKFLOW)'),
                true
        );
        insert new CMPL123__WF_Step__c(
                CMPL123__WF_Rule__c = wfRule.Id,
                CMPL123__Action__c = wfAction.Id,
                CMPL123__End_Status__c = endStatus.Id,
                CMPL123__Start_Status__c = startStatus.Id,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__Order__c = 1.0
        );

        //Create Workflow Status
        CMPL123__WF_Status__c status = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
                Name = 'Opened'),true);

        //Create Workflow Status
        CMPL123__WF_Status__c inProcessStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
                Name = 'In Process'),true);

        //Create Workflow Status
        CMPL123__WF_Status__c inProcessStatusEvaluation = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
                Name = 'In Process-Evaluation'),true);

        //Create Workflow Status
        CMPL123__WF_Status__c assessStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c(
                Name = 'Assess'),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c  assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'CMPL123CME__Investigation__c(PRODEVAL_WORKFLOW)',
                CMPL123__Record_Type__c  = 'PRODEVAL_WORKFLOW',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = assessStatus.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = assessProdRule.Id),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessProdRuleTask = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'Task__c(Prod_Eval_Task)',
                CMPL123__Record_Type__c  = 'Prod_Eval_Task',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = startStatus.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = assessProdRuleTask.Id),true);


        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessMedRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'CMPL123CME__Questionnaire__c(MEDICAL_EVALUATION_WORKFLOW)',
                CMPL123__Record_Type__c  = 'MEDICAL_EVALUATION_WORKFLOW',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = inProcessStatusEvaluation.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = assessMedRule.Id),true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessMedTaskRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'Medical_Evaluation_Task__c(MEDICAL_EVALUATION_TASK_WORKFLOW)',
                CMPL123__Record_Type__c  = 'MEDICAL_EVALUATION_TASK_WORKFLOW',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for Prod Eval Assess
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = inProcessStatus.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = assessMedTaskRule.Id),true);

        //Create Workflow rule for customer response
        CMPL123__WF_Rule__c returnRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'Return__c(RETURN_WORKFLOW)',
                CMPL123__Record_Type__c  = 'RETURN_WORKFLOW',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for customer response
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = startStatus.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = returnRule.Id),true);

        //Create Return
        TestDataFactory.createSObject(new Return__c(Ticket__c = complaint.Id, CMPL123_WF_Status__c = 'Opened'),true);

        //Create Workflow rule for customer response
        CMPL123__WF_Rule__c  translationTaskRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'Translation_Task__c(Translation_Task)',
                CMPL123__Record_Type__c  = 'Translation_Task',
                CMPL123__Is_Active__c  = true,
                CMPL123__Has_Multiple_Actions__c = true),true);

        //Create workflow step for customer response
        TestDataFactory.createSObject(new CMPL123__WF_Step__c(
                CMPL123__Start_Status__c = inProcessStatus.Id,
                CMPL123__End_Status__c  = endStatus.Id,
                CMPL123__Action__c  = wfAction.Id,
                CMPL123__Order__c = 1.0,
                CMPL123__Is_Start_Step__c = true,
                CMPL123__WF_Rule__c = translationTaskRule.Id),true);

        insert new List<Customer_Response__c>{
                new Customer_Response__c(
                        Event__c = complaint.Id,
                        Customer_Reply__c = 'Test Customer reply'),
                new Customer_Response__c(
                        Event__c = complaint2.Id,
                        Customer_Reply__c = 'Test Customer reply',
                        CMPL123_WF_Status__c ='Opened'),
                new Customer_Response__c(
                        Event__c = complaint3.Id,
                        Customer_Reply__c = 'Test Customer reply',
                        CMPL123_WF_Status__c ='Opened',
                        Ticket_Type__c = 'Complaint'),
                new Customer_Response__c(
                        Event__c = complaint4.Id,
                        Customer_Reply__c = 'Test Customer reply',
                        CMPL123_WF_Status__c ='Opened',
                        Ticket_Type__c = 'Complaint')
        };
        insert new List<Ticket_Product_Evaluation_Investigation__c>{
                new Ticket_Product_Evaluation_Investigation__c(
                        Investigation_Evaluation__c = investigation.Id,
                        Ticket__c = complaint.Id),
                new Ticket_Product_Evaluation_Investigation__c(
                        Investigation_Evaluation__c = investigation.Id,
                        Ticket__c = complaint2.Id)
        }; 
        
        //Start - IPDR 506 - R3.1
        //Fetch relevant Profiles (Aspen User and System Admin)
        Map<String, Profile> profileNameToRec = new Map<String, Profile>();
        for (Profile prof : [SELECT Id, Name FROM Profile
            WHERE Name = :AspenConstants.PROFILE_STD OR
            Name = :AspenConstants.PROFILE_ADMIN
        ]) {
            profileNameToRec.put(prof.Name, prof);
        }
        Id profileIdStd = profileNameToRec.get(AspenConstants.PROFILE_STD).Id;
        Id profileIdAdmin = profileNameToRec.get(AspenConstants.PROFILE_ADMIN).Id;

        //Creating a test user 'complaintAccessorUser'
        User complaintAccessorUser = TestUtil.insertTestUser(
                profileIdStd,
                EMAIL_STD_ONE,
                EMAIL_STD_ONE
        );

        //Creating a system admin user 'systemAdmin'. This user will be used to assign permission sets to test user.
        User systemAdmin = TestUtil.insertTestUser(
                profileIdAdmin,
                EMAIL_ADMIN_ONE,
                EMAIL_ADMIN_ONE
        );

        //Fetch permission sets that are needed to be assigned to 'complaintAccessorUser'
        Map<String, PermissionSet> permissionsetNameToRec = new Map<String, PermissionSet>();
        for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet
            WHERE Name = 'Complaint_Assessor' OR
            Name = 'Complaint_Evaluator_Investigator' OR
            Name = 'X123Compliance_Permission_Set_for_Platform_User'
        ]) {
            permissionsetNameToRec.put(ps.Name, ps);
        }

        //Running as systemAdmin to assign PS to test user complaintAccessorUser
        //This is to avoid Mixed DML excpetion as both setup and non-setup objects cannot be updated in same transaction.
        System.runAs(systemAdmin)
        {
            List<permissionSetAssignment> insertPermissionSetAssignmentList = New List<permissionSetAssignment>();
            for(String permissionsetName : permissionsetNameToRec.keySet()){
                permissionSetAssignment newPSAssign = New permissionSetAssignment();
                newPSAssign.AssigneeId = complaintAccessorUser.Id;
                newPSAssign.PermissionSetId = permissionsetNameToRec.get(permissionsetName).Id;
                insertPermissionSetAssignmentList.add(newPSAssign);
            }
            insert insertPermissionSetAssignmentList;
        }

        //Insert ticket of type complaint 
        /*CMPL123CME__Complaint__c testComplaint506 = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        pRE_Status__c = 'No',
                        CMSNext_Ticket_Number__c = 'TestComplaintIPDR506',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );

        String inquiryRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId();
        CMPL123CME__Complaint__c inquiry = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = inquiryRTId,
                        Ticket_Type__c = 'Inquiry',
                        pRE_Status__c = 'No',
                        CMSNext_Ticket_Number__c = 'TestInquiryIPDR506',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );*/
        //End - IPDR 506 - R3.1
    }

    /*
    * @Method       : test.
    * @Description  : Covers logic in moveChildrenOpenToClose, processAutomatedHistoryRecord
    *                 and createCustomerResponse methods of ComplaintTriggerHandler class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test() {
        CMPL123CME__Complaint__c complaint = [SELECT Id, CMSNext_Ticket_Number__c FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'INDIA'];
        CMPL123CME__Complaint__c complaint2 = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'USA'];
        update complaint2;

        Test.startTest();
        ADDUpdateTicketStatus.boolIsExcuted = false;
        ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag = true;
        ComplaintTriggerHandler.updatedFieldsSet = new Set<String>{
                'CMPL123Task_Key_Value__c',
                'Customer_Reply_Required__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'pRE_Status__c',
                'CMSNext__c'
        };
        complaint.Customer_Reply_Required__c = false;
        complaint.CMSNext__c = 'Open';
        complaint.Ticket_Type__c = 'Inquiry';
        complaint.Overall_Reportable_Status__c = 'TPM Responsible';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
        complaint.Reopen_Rationale__c = 'test reopen';
        update complaint;
        ComplaintTriggerHandler.moveChildrenOpenToClose(
                new List<CMPL123CME__Complaint__c>{
                        complaint2
                },
                false
        );
        ComplaintTriggerHandler.moveChildrenOpenToClose(
                new List<CMPL123CME__Complaint__c>{
                        complaint2
                },
                true
        );
        ComplaintTriggerHandler.processAutomatedHistoryRecord(complaint2.Id, [
                SELECT CMPL123__Action__r.Name, CMPL123__End_Status__r.Name, CMPL123__Start_Status__r.Name
                FROM CMPL123__WF_Step__c
                LIMIT 1
        ]);
        ComplaintTriggerHandler.createInvestigation(complaint2.Id, null, 'ADD', 'Test');
        Set<Id> ticketIds = new Set<Id>();
        ticketIds.add(complaint.Id);
        ticketIds.add(complaint2.Id);
        ComplaintTriggerHandler.createCustomerResponse(complaint.Id, 'Test', 'Test', complaint.CMSNext_Ticket_Number__c, 'false');
       
        Test.stopTest();
        delete complaint;
        delete complaint2;

        System.assertEquals(2, [SELECT COUNT() FROM CMPL123CME__Complaint__c]);
    }

    /*
    * @Method       : test1.
    * @Description  : Covers logic in updatedFieldsSet method of ComplaintTriggerHandler class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test1() {
        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Final Review In Progress'),
                true
        );
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'),
                true
        );
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Void',
                        CMPL123__Is_ESign_Required__c = true),
                true
        );
        CMPL123__WF_Rule__c wfRule = [SELECT Id FROM CMPL123__WF_Rule__c 
                                        WHERE CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(COMPLAINT_WORKFLOW)'];
        CMPL123__WF_Step__c step = [SELECT Id FROM CMPL123__WF_Step__c LIMIT 1];
        step.CMPL123__WF_Rule__c = wfRule.Id;
        step.CMPL123__Action__c = wfAction.Id;
        step.CMPL123__End_Status__c = endStatus.Id;
        step.CMPL123__Start_Status__c = startStatus.Id;
        update step;

        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'INDIA'];
        CMPL123CME__Complaint__c complaint2 = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'USA'];
        //update complaint2;

        Test.startTest();
        ADDUpdateTicketStatus.boolIsExcuted = false;
        ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag = true;
        complaint.Customer_Reply_Required__c = false;
        complaint.CMSNext__c = 'Open';
        complaint.Ticket_Type__c = 'Inquiry';
        complaint.Overall_Reportable_Status__c = 'TPM Responsible';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
        complaint.Reopen_Rationale__c = 'test reopen';
        ComplaintTriggerHandler.updatedFieldsSet = new Set<String>{
                'CMPL123Task_Key_Value__c',
                'Customer_Reply_Required__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'pRE_Status__c',
                'CMSNext__c'
        };
        update complaint;
        Test.stopTest();
        delete complaint;
        delete complaint2;

        System.assertEquals(2, [SELECT COUNT() FROM CMPL123CME__Complaint__c]);
    }

    /*
    * @Method       : test2.
    * @Description  : Covers logic in updatedFieldsSet method of ComplaintTriggerHandler class.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test2() {
        CMPL123__WF_Status__c startStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Final Review In Progress'),
                true
        );
        CMPL123__WF_Status__c endStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Closed-Done'),
                true
        );
        CMPL123__WF_Action__c wfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Void',
                        CMPL123__Is_ESign_Required__c = true),
                true
        );
        CMPL123__WF_Rule__c wfRule = [SELECT Id FROM CMPL123__WF_Rule__c 
                                        WHERE CMPL123__Target_Object__c = 'CMPL123CME__Complaint__c(COMPLAINT_WORKFLOW)'];
        CMPL123__WF_Step__c step = [SELECT Id FROM CMPL123__WF_Step__c LIMIT 1];
        step.CMPL123__WF_Rule__c = wfRule.Id;
        step.CMPL123__Action__c = wfAction.Id;
        step.CMPL123__End_Status__c = endStatus.Id;
        step.CMPL123__Start_Status__c = startStatus.Id;
        update step;

        CMPL123CME__Complaint__c complaint2 = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'USA'];
        ComplaintTriggerHandler.updatedFieldsSet = new Set<String>{
                'CMPL123Task_Key_Value__c',
                'Customer_Reply_Required__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'pRE_Status__c',
                'CMSNext__c'
        };

        Test.startTest();
        try {
            update complaint2;
        } catch (System.DmlException ex) {

        }
        ADDUpdateTicketStatus.boolIsExcuted = false;
        ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag = true;
        ComplaintTriggerHandler.updatedFieldsSet = new Set<String>{
                'CMPL123Task_Key_Value__c',
                'Customer_Reply_Required__c',
                'CMPL123CME__CMPL123_WF_Status__c',
                'pRE_Status__c',
                'CMSNext__c'
        };
        delete complaint2;
        Test.stopTest();

        System.assertEquals(4, [SELECT COUNT() FROM CMPL123CME__Complaint__c ALL ROWS]);
    }

    /*
    * @Method       : test3.
    * @Description  : Verifies that complaint cannot be deleted.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void test3() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = new CMPL123CME__Complaint__c(
                Ticket_Type__c = 'Complaint',
                CMSNext__c = 'Void',
                RecordTypeId = complaintRTId,
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                Business_Unit__c = 'IA-CC',
                Likely_Cause__c = 'Yes',
                Investigation_Status__c = 'Assess',
                CMSNext_Ticket_Number__c = 'CN-164835',
                Is_Product_Evaluation_Investigation_chil__c = false,
                Customer_Reply_Required__c = true,
                Follow_up_Status__c = 'Further Review',
                CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved',
                pRE_to_Yes_Date__c = System.today()
        );

        Test.startTest();
        insert complaint;
        ComplaintTriggerHandler.updatedFieldsSet = new Set<String>{
                'CMPL123CME__CMPL123_WF_Status__c',
                'CMSNext__c'
        };
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
        complaint.Med_Evaluator_Pending_MDCs__c = false;
        ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag = true;
        update complaint;
        ADDUpdateTicketStatus.boolIsExcuted = false;
        ADDMDCTicketTriggerHandler.MDCTriggerUpdateFlag = true;

        delete complaint;
        Test.stopTest();

        System.assertEquals(5, [SELECT COUNT() FROM CMPL123CME__Complaint__c ALL ROWS]);
    }

    /*
    * @Method       : testInvestigationCreatingPopulating.
    * @Description  : Verifies that child investigation record is created when ticket is routed for review
    *                 and it's Created_Date__c is equal to Product_Evaluation_Start_Date__c of parent ticket.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testInvestigationCreatingPopulating() {
        Test.startTest();
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'USA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Open',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        Ticket_Type__c = 'Complaint',
                        CMSNext_Ticket_Number__c = 'CN-164835',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        Follow_up_Status__c = 'Further Review',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress',
                        CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved'),
                true
        );
        CMPL123CME__Investigation__c autocreatedInvestigation = [
                SELECT Created_Date__c FROM CMPL123CME__Investigation__c
                WHERE CMPL123CME__Complaint__c = :complaint.Id
        ];
        CMPL123CME__Complaint__c updatedComplaint = [
                SELECT Product_Evaluation_Start_Date__c FROM CMPL123CME__Complaint__c
                WHERE Id = :complaint.Id
        ];
        System.assert(autocreatedInvestigation.Created_Date__c == updatedComplaint.Product_Evaluation_Start_Date__c);
        Test.stopTest();
    }

    /*
    * @Method       : testComplaintReopening.
    * @Description  : Verifies that ticket is moved to "Open" status in CHaRM when it is opened in CMSNext.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void testComplaintReopening() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        pRE_Status__c = 'Yes',
                        Country_of_origin__c = 'USA',
                        RecordTypeId = complaintRTId,
                        Business_Unit__c = 'IA-CC',
                        CMSNext__c = 'Closed',
                        Likely_Cause__c = 'Yes',
                        Investigation_Status__c = 'Assess',
                        Ticket_Type__c = 'Complaint',
                        CMSNext_Ticket_Number__c = 'CN-164835',
                        Is_Product_Evaluation_Investigation_chil__c = false,
                        Customer_Reply_Required__c = true,
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Registration Closed'),
                true
        );

        Test.startTest();
        complaint.CMSNext__c = 'Open';
        update complaint;
        CMPL123CME__Complaint__c updatedComplaint = [
                SELECT CMPL123Task_Key_Value__c FROM CMPL123CME__Complaint__c
                WHERE Id = :complaint.Id
        ];
        System.assert(updatedComplaint.CMPL123Task_Key_Value__c == 'REOPENRCTICKET');
        Test.stopTest();
    }
    
    //  Created to test CR 1661 (CHARM-1884) by dskak
    @IsTest
    private static void CRTicketReopenTest() {
        Test.startTest();
        CMPL123__WF_Rule__c wfRule = [SELECT Id, CMPL123__Record_Type__c FROM CMPL123__WF_Rule__c 
                                        WHERE CMPL123__Record_Type__c = 'COMPLAINT_WORKFLOW'];
        CMPL123__WF_Step__c wfStep = [SELECT Id FROM CMPL123__WF_Step__c WHERE CMPL123__WF_Rule__c = :wfRule.Id];
        CMPL123__WF_Status__c bysAdmStartStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Complaint Complete'), true);
        CMPL123__WF_Status__c  bysAdmEndStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Opened'), true);
        CMPL123__WF_Action__c  bysAdmWfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Go to Opened',
                        CMPL123__Is_ESign_Required__c = false
                ), true);
        

        wfStep.CMPL123__Action__c = bysAdmWfAction.Id;
        wfStep.CMPL123__End_Status__c = bysAdmEndStatus.Id;
        wfStep.CMPL123__Start_Status__c = bysAdmStartStatus.Id;
        wfStep.CMPL123__Permission_Group__c = 'Business Admin';
        wfStep.CMPL123__Is_Start_Step__c = true;
        wfStep.CMPL123__Order__c = 1.0;
        update wfStep;

        CMPL123__WF_Status__c sysAdmStartStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Complaint Complete'), true);
        CMPL123__WF_Status__c sysAdmEndStatus = (CMPL123__WF_Status__c) TestDataFactory.createSObject(
                new CMPL123__WF_Status__c(Name = 'Opened'), true);
        CMPL123__WF_Action__c sysAdmWfAction = (CMPL123__WF_Action__c) TestDataFactory.createSObject(
                new CMPL123__WF_Action__c(
                        Name = 'Go to Opened',
                        CMPL123__Is_ESign_Required__c = false
                ), true);

        insert new CMPL123__WF_Step__c(
                CMPL123__WF_Rule__c = wfRule.Id,
                CMPL123__Action__c = sysAdmWfAction.Id,
                CMPL123__End_Status__c = sysAdmEndStatus.Id,
                CMPL123__Start_Status__c = sysAdmStartStatus.Id,
                    CMPL123__Permission_Group__c = 'System Admin',
                CMPL123__Order__c = 2.0
        );

        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();

        CMPL123CME__Complaint__c busAdmComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        CMPL123Rule_Key_Value__c = wfRule.CMPL123__Record_Type__c,
                        CMPL123CME__CMPL123_WF_Status__c = bysAdmStartStatus.Name,
                        CMPL123CME__CMPL123_WF_Action__c = 'Complete'
                ), true);

        CMPL123CME__Complaint__c sysAdminComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        CMPL123Rule_Key_Value__c = wfRule.CMPL123__Record_Type__c,
                        CMPL123CME__CMPL123_WF_Status__c = sysAdmStartStatus.Name,
                        CMPL123CME__CMPL123_WF_Action__c = 'Complete'
                ), true);

        Id busAdminGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'Business_Admin'].Id;
        Id aspenUserProfileId = [SELECT Id FROM Profile WHERE Name = 'Aspen User'].Id;
        User businessAdmin = TestUtil.insertTestUser(
                aspenUserProfileId,
                'businessAdminTest1661CR@test.com',
                'businessAdminTest1661CR@test.com'
        );

        Id sysAdminGroupId = [SELECT Id FROM Group WHERE DeveloperName = 'System_Admin'].Id;
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        User systemAdmin = TestUtil.insertTestUser(
                systemAdminProfileId,
                'systemAdminTest1661CR@test.com',
                'systemAdminTest1661CR@test.com'
        );

        System.runAs(systemAdmin) {
            insert new GroupMember(
                GroupId = busAdminGroupId,
                UserOrGroupId = businessAdmin.Id
            );

        insert new GroupMember(
                GroupId = sysAdminGroupId,
                UserOrGroupId = systemAdmin.Id
            );
        }

        System.runAs(businessAdmin) {
                busAdmComplaint.CMPL123CME__CMPL123_WF_Status__c = bysAdmEndStatus.Name;
                busAdmComplaint.CMPL123CME__CMPL123_WF_Action__c = bysAdmWfAction.Name;
                update busAdmComplaint;
        }

        System.runAs(businessAdmin) {
                sysAdminComplaint.CMPL123CME__CMPL123_WF_Status__c = sysAdmEndStatus.Name;
                sysAdminComplaint.CMPL123CME__CMPL123_WF_Action__c = sysAdmWfAction.Name;
                update sysAdminComplaint;
        }
        Test.stopTest();

        CMPL123CME__Complaint__c bysAdmResult = [SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c
                                           FROM CMPL123CME__Complaint__c
                                           WHERE Id =: busAdmComplaint.Id];

        System.assertEquals(busAdmComplaint.CMPL123CME__CMPL123_WF_Status__c, bysAdmResult.CMPL123CME__CMPL123_WF_Status__c);
        System.assertEquals(busAdmComplaint.CMPL123CME__CMPL123_WF_Action__c, bysAdmResult.CMPL123CME__CMPL123_WF_Action__c);

        CMPL123CME__Complaint__c sysAdmResult = [SELECT Id, CMPL123CME__CMPL123_WF_Status__c, CMPL123CME__CMPL123_WF_Action__c
                                           FROM CMPL123CME__Complaint__c
                                           WHERE Id =: sysAdminComplaint.Id];

        System.assertEquals(sysAdminComplaint.CMPL123CME__CMPL123_WF_Status__c, sysAdmResult.CMPL123CME__CMPL123_WF_Status__c);
        System.assertEquals(sysAdminComplaint.CMPL123CME__CMPL123_WF_Action__c, sysAdmResult.CMPL123CME__CMPL123_WF_Action__c);
    }
    
    /*
    * @Method       : testCustomerResponseClosing.
    * @Description  : Tests Customer Response closing when Customer_Reply_Required__c updated to false.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testCustomerResponseClosing() {
        
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'USA'];
        Test.startTest();
        complaint.Customer_Reply_Required__c = false;
        update complaint;
        Test.stopTest();
         Customer_Response__c customeResponse = [SELECT CMPL123_WF_Status__c FROM Customer_Response__c 
                                                        WHERE Event__r.Country_of_origin__c = 'USA'];

        System.assertEquals('Closed-Voided', customeResponse.CMPL123_WF_Status__c);
    }

    /*
    * @Method       : testCustomerResponseReopening.
    * @Description  : Tests Customer Response closing when Customer_Reply_Required__c updated to true.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void testCustomerResponseReopening() {
        
        CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'INDIA'];
        Customer_Response__c customeResponse = [SELECT CMPL123_WF_Status__c FROM Customer_Response__c 
                                                        WHERE Event__c = :complaint.Id];
        customeResponse.CMPL123_WF_Status__c = 'Closed-Voided';
        update customeResponse;
        Test.startTest();
        complaint.Customer_Reply_Required__c = true;
        ComplaintTriggerHandler.executeOnceAfterUpdate = false;
        ComplaintTriggerHandler.executeOnceBeforeUpdate = false;
        update complaint;
        Test.stopTest();
        Customer_Response__c customeResponseReopened = [SELECT CMPL123_WF_Status__c FROM Customer_Response__c 
                                                        WHERE Event__c = :complaint.Id];

        System.assertEquals('Opened', customeResponseReopened.CMPL123_WF_Status__c);
    }

    /*
    * @Method       : clearReadyForclosureFlagWhenTicketIsReopenedWFRuleTest.
    * @Description  : To test moved to Apex Clear ready for closure flag when ticket is reopened WF Rule functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void clearReadyForclosureFlagWhenTicketIsReopenedWFRuleTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        Ready_to_Close__c = 'Yes',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress'),
                true
        );
        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        update complaint;
        complaint.CMPL123CME__CMPL123_WF_Action__c = 'Reopen';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Opened';
        update complaint;
        Test.stopTest();

        System.assertEquals(null, [SELECT Id, Ticket_Close_Date__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].Ticket_Close_Date__c, 'Ticket Close Date should be null');
    }
    
    /*
    * @Method       : setComplaintCompleteDateWFRuleTest.
    * @Description  : To test moved to Apex Set Complaint Complete Date & When Complete action is performed Ready For Closure should be set to yes WF Rules functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    static void setComplaintCompleteDateWFRuleTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );
        
        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Action__c = 'Complete';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Complaint Complete';
        complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c = Date.today();
        update complaint;
        Test.stopTest();
        
        System.assertEquals(complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c.date(), 
                            [SELECT Id, Complaint_Complete_Date__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].Complaint_Complete_Date__c, 
                            'Compalint Complete Date should be equals CMPL123CME__CMPL123_WF_Action_Performed_On__c');
        
       System.assertEquals('Yes', 
                           [SELECT Id, Ready_to_Close__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].Ready_to_Close__c, 
                           'Ready to Close should be Yes');
    }
    
    /*
    * @Method       : setTicketCloseDateWFRuleTest.
    * @Description  : To test moved to Apex Set Ticket Close Date WF Rule functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void setTicketCloseDateWFRuleTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        Ready_to_Close__c = 'Yes',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress'),
                true
        );
        
        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Action__c = 'Final Review Approved';
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c = Date.today();
        update complaint;
        Test.stopTest();
        
        System.assertEquals(complaint.CMPL123CME__CMPL123_WF_Action_Performed_On__c.dateGMT(), 
                            [SELECT Id, Ticket_Close_Date__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].Ticket_Close_Date__c, 
                            'Ticket Close Date should be equals CMPL123CME__CMPL123_WF_Action_Performed_On__c');
    }
    
    /*
    * @Method       : updatePreToYesDateWFRuleTest.
    * @Description  : To test moved to Apex Update pRE to Yes Date WF Rule functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void updatePreToYesDateWFRuleTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        pRE_Status__c = 'Yes',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Final Review In Progress'),
                true
        );
        
        System.assertEquals(Date.today(), 
                            [SELECT Id, pRE_to_Yes_Date__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].pRE_to_Yes_Date__c, 
                            'pRE to Yes Date should be current day if pRE Status = Yes');
    }

    /*
    * @Method       : reopenComplaintTest.
    * @Description  : To test reopening Complaint ticket from CMSNext.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void reopenComplaintTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Complaint')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Complaint',
                        pRE_Status__c = 'No',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );

        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        complaint.CMSNext__c = 'Closed';
        update complaint;
        ComplaintTriggerHandler.executeOnceBeforeUpdate = false;
        complaint.CMSNext__c = 'Open';
        complaint.Registration_Ticket_Status__c = 'Open';
        complaint.Reopen_Rationale__c = 'Reopened by CMSNext';
        TicketServiceHandler.ticketOpenFromCMSFlag = true;
        update complaint;

        System.assertEquals('ReopenClosedComplaint', 
                            [SELECT CMPL123Task_Key_Value__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].CMPL123Task_Key_Value__c, 
                            'ReopenClosedComplaint 123 Task should be assigned when Complaint ticket reopened in CMSNext');
        
        Test.stopTest();
    }

    /*
    * @Method       : reopenInquiryTest.
    * @Description  : To test reopening Inquiry ticket from CMSNext.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void reopenInquiryTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Inquiry')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = 'Inquiry',
                        pRE_Status__c = 'No',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );

        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        complaint.CMSNext__c = 'Closed';
        update complaint;
        ComplaintTriggerHandler.executeOnceBeforeUpdate = false;
        complaint.CMSNext__c = 'Open';
        complaint.Registration_Ticket_Status__c = 'Open';
        complaint.Reopen_Rationale__c = 'Reopened by CMSNext';
        TicketServiceHandler.ticketOpenFromCMSFlag = true;
        update complaint;

        System.assertEquals('openInquiryClose', 
                            [SELECT CMPL123Task_Key_Value__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].CMPL123Task_Key_Value__c, 
                            'openInquiryClose 123 Task should be assigned when Inquiry ticket reopened in CMSNext');
        Test.stopTest();
    }

    /*
    * @Method       : reopenServiceTest.
    * @Description  : To test reopening Service ticket from CMSNext.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void reopenServiceTest() {
        String serviceRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get('Service')
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = serviceRTId,
                        Ticket_Type__c = 'Service',
                        pRE_Status__c = 'No',
                        CMPL123CME__CMPL123_WF_Status__c = 'Opened'),
                true
        );

        Test.startTest();
        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Done';
        complaint.CMSNext__c = 'Closed';
        update complaint;
        ComplaintTriggerHandler.executeOnceBeforeUpdate = false;
        complaint.CMSNext__c = 'Open';
        complaint.Registration_Ticket_Status__c = 'Open';
        complaint.Reopen_Rationale__c = 'Reopened by CMSNext';
        TicketServiceHandler.ticketOpenFromCMSFlag = true;
        update complaint;

        System.assertEquals('reopenServiceClosed', 
                            [SELECT CMPL123Task_Key_Value__c FROM CMPL123CME__Complaint__c WHERE Id =: complaint.Id].CMPL123Task_Key_Value__c, 
                            'reopenServiceClosed 123 Task should be assigned when Service ticket reopened in CMSNext');
        Test.stopTest();
    }
    
    /*
     * @Method       : closeandReopenComplaintTest.
     * @Description  : To test 'Original Ticket Close Date' and 'Last Reopened Date' field population
     *               : upon Complaint ticket closure and reopen actions respectively. This is part of IPDR 506 of Release 3.1
     *               : Test mothod to cover main method 'BeforeUpdateComplaintDateField'
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Release      : CHARM 3.1- IPDR 506
     */
    @isTest
    static void closeandReopenComplaintTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get(AspenConstants.STR_Complaint)
                .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = complaintRTId,
                        Ticket_Type__c = AspenConstants.STR_Complaint,
                        pRE_Status__c = 'No',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),
                true
        );

        User complaintAccessorUser = [SELECT Id, Email FROM User WHERE Email =: EMAIL_STD_ONE];
        Test.startTest();
        System.runAs(complaintAccessorUser){

            //Close complaint ticket
            complaint.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
            update complaint;

            System.assertEquals(System.now().dateGmt(), 
                                 refreshTicket(complaint.Id).Original_Ticket_Close_Date__c,
                                 'Original Ticket Close Date was not populated when the Ticket was closed'
                               );

            //Reopen complaint ticket
            complaint.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
            update complaint;

            System.assertEquals(System.now().dateGmt(), 
                                 refreshTicket(complaint.Id).Last_Reopened_Date__c,
                                 'Last Reopned Date was not populated when the Ticket was reopened'
                               );

            //Updating Original Ticket Close Date and Last Reopened Date fields with past date
            Date manuallyUpdatedOriginalCloseDate = System.today()-2;
            complaint.Original_Ticket_Close_Date__c = manuallyUpdatedOriginalCloseDate;
            complaint.Last_Reopened_Date__c =  System.now().dateGmt()-1;
            update complaint;

            //Closing the complaint again
            complaint.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
            update complaint;

            System.assertEquals(manuallyUpdatedOriginalCloseDate, 
                                 refreshTicket(complaint.Id).Original_Ticket_Close_Date__c,
                                 'Original ticket close date got auto-updated by system again when complaint closed for second time'
                               );

            //Re-opening the complaint again
            complaint.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
            update complaint;

            System.assertEquals(System.now().dateGmt(), 
                                refreshTicket(complaint.Id).Last_Reopened_Date__c,
                                'Last reopened date have not updated when complaint reopened for second time'
                               );
        }
        Test.stopTest();
    }

    /*
     * @Method       : doNotPopulateInquiryTicketFieldsTest.
     * @Description  : To test 'Original Ticket Close Date' and 'Last Reopened Date' field is not populated
     *               : upon Inquiry ticket closure and reopen actions respectively. This is part of IPDR 506 of Release 3.1
     *               : Test mothod to cover main method 'BeforeUpdateComplaintDateField'
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Release      : CHARM 3.1- IPDR 506
     */
    @isTest
    static void doNotPopulateInquiryTicketFieldsTest() {
        String inquiryRTId = Schema.SObjectType.CMPL123CME__Complaint__c
                .getRecordTypeInfosByName()
                .get(AspenConstants.STR_Inquiry)
                .getRecordTypeId();
        CMPL123CME__Complaint__c inquiry = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        Division__c = 'ADD',
                        RecordTypeId = inquiryRTId,
                        Ticket_Type__c = AspenConstants.STR_Inquiry,
                        pRE_Status__c = 'No',
                        //CMSNext_Ticket_Number__c = 'TestInquiryIPDR506',
                        CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                        CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),
                true
        );
        User complaintAccessorUser = [SELECT Id, Email FROM User WHERE Email =: EMAIL_STD_ONE];

        Test.startTest();
        System.runAs(complaintAccessorUser){

            //Close inquiry ticket
            inquiry.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
            update inquiry;

            System.assertEquals(Null, 
                                refreshTicket(inquiry.Id).Original_Ticket_Close_Date__c,
                                'Original Ticket Close Date field got populated even for Inquiry ticket when ticket is closed'
                               );

            //Reopen complaint ticket
            inquiry.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
            update inquiry;

            System.assertEquals(Null, 
                                refreshTicket(inquiry.Id).Last_Reopened_Date__c,
                                'Last Reopend Date field got populated even for Inquiry ticket when ticket is reopened'
                               );
        }
        Test.stopTest();
    }

    /**
     * Queries for ticket record with the Id received as parameter
     * Helper for closeandReopenComplaintTest and doNotPopulateInquiryTicketFieldsTest
     * @author Arjun Melinakeri
     * Charm R3.1 - IPDR 506
     * @date 16-JUN-2023
     */
    private static CMPL123CME__Complaint__c refreshTicket(Id ticketId){
        return [SELECT Id, Last_Reopened_Date__c, Original_Ticket_Close_Date__c, CMPL123CME__CMPL123_WF_Status__c
                FROM CMPL123CME__Complaint__c
                WHERE Id =: ticketId
                ];
    }
    
     /*
     * @Method       : ticketCreatedDateLessthanOriginalTicketEffectiveDateTest.
     * @Description  : To test 'Original Ticket Close Date' is not populated if the Complaint Ticket Created date is less
     *                 than the Custom setting value Original TicketClosed Date Effective From
     * @Invoke       : N/A.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Release      : CHARM 3.1- IPDR 506
     */
    @isTest
    static void ticketCreatedDateLessthanOriginalTicketEffectiveDateTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                RecordTypeId = complaintRTId,
                Ticket_Type__c = AspenConstants.STR_Complaint,
                pRE_Status__c = 'No',
                CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened),
            true
        );
        //insert complaint;
        //Setting Created Date of test complaint record, older than 'Original Ticket Close Date EffectiveFrom' 
        //so that Original Ticket Close Date on complaint record is not auto-populated
        DateTime complaintCreatedDate = DateTime.newInstance(2022,12,12);
        Test.setCreatedDate(complaint.Id, complaintCreatedDate);
        User complaintAccessorUser = [SELECT Id, Email FROM User WHERE Email =: EMAIL_STD_ONE];
        Test.startTest();
        System.runAs(complaintAccessorUser){
            
            //Close complaint ticket
            complaint.CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
            update complaint;
            
            System.assert(complaintCreatedDate < AddUtil.getOriginalTicketCloseDateEffectiveFrom(),
                          'Setup bug: Test method should be set to a date earlier than the custom setting'
                         );
            System.assertEquals(Null, 
                                refreshTicket(complaint.Id).Original_Ticket_Close_Date__c,
                                'Original Ticket Close Date was not populated when the Ticket was closed even though created date is lesser than Original Ticket Close Date EffectiveFrom'
                               );
        }
        Test.stopTest();
    }
    
      /*
    * @Method       : customerResponseTicketTypeUpdateTest.
    * @Description  : CHaRM R5: To check the Ticket Type field in Customer Response object is populating when a Ticket object
    *                 elevated or demoted.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    private static void customerResponseTicketTypeUpdateTest() {
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c
            .getRecordTypeInfosByName()
            .get(AspenConstants.STR_Complaint)
            .getRecordTypeId();
        Test.startTest(); 
        
        CMPL123CME__Complaint__c complaintTestData1 = [SELECT CMPL123Task_Key_Value__c,Ticket_Type__c FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'China'];
        
        complaintTestData1.Ticket_Type__c = 'Inquiry';
        Update complaintTestData1;
        
        System.assertEquals('Inquiry',[SELECT CMPL123_WF_Status__c,Ticket_Type__c, Event__r.Country_of_origin__c FROM Customer_Response__c 
                                       WHERE Event__r.Country_of_origin__c = 'China'].Ticket_Type__c);
       
        CMPL123CME__Complaint__c complaintTestData2 = [SELECT CMPL123Task_Key_Value__c,Ticket_Type__c FROM CMPL123CME__Complaint__c WHERE Country_of_origin__c = 'Germany'];
        
        complaintTestData2.Ticket_Type__c = 'Complaint';
        Update complaintTestData2;
        
        
        System.assertEquals('Complaint',[SELECT CMPL123_WF_Status__c,Ticket_Type__c, Event__r.Country_of_origin__c FROM Customer_Response__c 
                                         WHERE Event__r.Country_of_origin__c = 'Germany'].Ticket_Type__c);
        
        Test.stopTest();
    }
}