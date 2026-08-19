/**
 * @why  : Test class for the CustomerResponseTriggerHandler.
 * @when : CreatedDate : N/A.
 * @what : Class to handle different scenarios from CustomerResponseTriggerHandler.
 * Modification Log:
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Developer            Date                   Modification ID         Description
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                10-JUN-2020            N/A                     Updated code part, which is related to Users' insertion.
 *                                                                       This change designed to prevent a 'DUPLICATE_USERNAME'
 *                                                                       error during deployment to Production environment.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DSkak                28-DEC-2020            TWD Upgrade issue       Added 'executeLogicFromWFRulesTest()' method to test moved logic from
 *                                                                       Workflow Rules with Field Updates on Customer Response to Apex.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * rsitc                14-JAN-2021            TWD Upgrade #92         Added logic for division assignment test.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Larry Resnik         06-JUN-2023            CHaRM R3.1, IPDR 116    Added pos/neg tests for prepTranslationItemsForVoiding.
 * Replaced many magic words with constants. Moved most record creation into testSetup for huge speedups.
 * Commented out a test against unreachable code in testValidation.
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Dinesh Kumar         05-DEC-2023            CHaRM-R4/BTSIT10110         Updated the Method "executeLogicFromWFRulesTest"
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Charm COE            06-AUG-2025            IPDR-746                    Added new test methods "testCustomerResponseWFResponded" and "testCustomerResponseWFRespondedInfoOnLabeling" 
 * 																			validation error is thrown when customer response is updated to 'Closed-Done'and translation items are not in closed status.
 * --------------------------------------------------------------------------------------------------------------------------------------
 */

 @IsTest
private class CustomerResponseTriggerHandlerTest {
    private static final String TICKET_ONE = 'ONE';
    private static final String TICKET_TWO = 'TWO';
    private static final String TICKET_THREE = 'THREE';
    private static final String TICKET_FOUR = 'FOUR';
    private static final String TICKET_FIVE = 'FIVE';
    private static final String TICKET_SIX = 'SIX';
    private static final String TICKET_SEVEN = 'SEVEN';
    private static final String EMAIL_STD_ONE = 'standard_one_test@test.com';
    private static final String EMAIL_ADMIN_ONE = 'admin_one_testAdmin@test.com';
    private static final String EMAIL_STD_TWO = 'standard_two_test@test.com';
    private static final String EMAIL_STD_THREE = 'standard_three_test@test.com';
    private static final String EMAIL_ADMIN_THREE_QA = 'admin_three_qa_testSysAdmin@test.com';
    private static final String EMAIL_STD_FOUR = 'standard_four_test@test.com';
    private static final String GROUP_DEFAULT = 'PEI3';
    private static final String GROUP_TRANSLATOR = 'Tran10';
    private static final String TRANSLATED_TEXT = 'Translate me, too!';
    private static final String TRANS_FIELD_NAME = 'Additional Reply Expectation';
    private static final String PRE_TRANSLATED_FIELD = 'Additional_Reply_Expectation_Translated__c';
    private static final String ERROR_POS = TestUtil.ERROR_POS;
    private static final String ERROR_NEG = TestUtil.ERROR_NEG;
    private static final String ERROR_SETUP = TestUtil.ERROR_SETUP;
    private static final String TRANS_TASK_WFSTATUS_PENDING = 'Translation Pending Review';

    @TestSetup
    static void makeData(){
        Map<String, User> emailToUser = setupMakeUsers();

        // Make Tickets
        Map<String, Schema.RecordTypeInfo> ticketRecTypeToId =
            Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName();
        String complaintRtId = ticketRecTypeToId.get(AspenConstants.STR_Complaint).getRecordTypeId();
        String inquiryRtId = ticketRecTypeToId.get(AspenConstants.STR_Inquiry).getRecordTypeId();
        String serviceRtId = ticketRecTypeToId.get(AspenConstants.STR_Service).getRecordTypeId();
        CMPL123CME__Complaint__c ticketOne = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
            new CMPL123CME__Complaint__c(
                CMSNext_Ticket_ID__c = TICKET_ONE,
                Division__c = AspenConstants.DIVISION_DIAGNOSTICS,
                pRE_Status__c = AspenConstants.STR_Yes,
                Country_of_origin__c = 'USA',
                RecordTypeId = complaintRtId,
                Business_Unit__c = 'IA-CC',
                CMSNext__c = AspenConstants.CMSNEXT_STATUS_VOID,
                Likely_Cause__c = AspenConstants.STR_Yes,
                Customer_Reply_Required__c = false,
                Follow_up_Status__c = 'Further Review',
                CMPL123Rule_Key_Value__c = 'COMPLAINT_WORKFLOW',
                CMPL123CME__CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                CMPL123CME__CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void,
                Overall_Reportable_Status__c = AspenConstants.REPORTABILITY_YES,
                Is_Product_Evaluation_Investigation_chil__c = true,
                Med_Evaluator_Pending_MDCs__c = false),
            false
        );
        CMPL123CME__Complaint__c ticketTwo = ticketOne.clone();
        ticketTwo.CMSNext_Ticket_ID__c = TICKET_TWO;
        ticketTwo.Investigation_Status__c = 'Closed-Done';
        CMPL123CME__Complaint__c ticketThree = ticketOne.clone();
        ticketThree.CMSNext_Ticket_ID__c = TICKET_THREE;
        ticketThree.RecordTypeId = inquiryRtId;
        ticketThree.CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW';
        CMPL123CME__Complaint__c ticketFour = ticketOne.clone();
        ticketFour.CMSNext_Ticket_ID__c = TICKET_FOUR;
        ticketFour.RecordTypeId = inquiryRtId;
        ticketFour.CMPL123Rule_Key_Value__c = 'INQUIRY_WORKFLOW';
        // R3.1, Larry: Before R3.1, CMSNext__c was incorrectly set to Opened here.
        // Hopefully there is no consequence to setting it to the valid value Open.
        ticketFour.CMSNext__c = AspenConstants.CMSNEXT_STATUS_OPEN;
        ticketFour.CMPL123CME__CMPL123_WF_Action__c = null;
        CMPL123CME__Complaint__c ticketFive = ticketOne.clone();
        ticketFive.CMSNext_Ticket_ID__c = TICKET_FIVE;
        ticketFive.Translation_Required_flag__c = true;
        CMPL123CME__Complaint__c ticketSix = ticketOne.clone();
        ticketSix.CMSNext_Ticket_ID__c = TICKET_SIX;
        ticketSix.Translation_Required_flag__c = true;
        CMPL123CME__Complaint__c ticketSeven = ticketOne.clone();
        ticketSeven.CMSNext_Ticket_ID__c = TICKET_SEVEN;
        ticketSeven.Ticket_Type__c = AspenConstants.STR_Service;
        ticketSeven.RecordTypeId = serviceRtId;
        insert new CMPL123CME__Complaint__c[]{ ticketOne, ticketTwo,
            ticketThree, ticketFour, ticketFive, ticketSix, ticketSeven };

        // Make Translation Tasks if needed

        // Make Customer Responses to affiliate to Tickets
        User testUserOne = emailToUser.get(EMAIL_STD_ONE);
        Customer_Response__c responseFive = (Customer_Response__c) TestDataFactory.createSObject(
            new Customer_Response__c(
                Event__c = ticketFive.Id,
                Assign_To__c = testUserOne.Id,
                Quality_Approver__c = testUserOne.Id,
                Customer_Expectation__c = 'これを翻訳してください',
                CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                CMPL123Task_Key_Value__c = 'Inquiry_Customer_Response'),
            false
        );
        Customer_Response__c responseSix = responseFive.clone();
        responseSix.Event__c = ticketSix.Id;
        responseSix.Customer_Expectation__c = null;
        Customer_Response__c responseSeven = responseFive.clone();
        responseSeven.Event__c = ticketSeven.Id;
        insert new Customer_Response__c[]{ responseFive, responseSix, responseSeven };
    }

    private static Map<String, User> setupMakeUsers() {
        // Fetch relevant Profiles
        Map<String, Profile> profileNameToRec = new Map<String, Profile>();
        for (Profile prof : [SELECT Id, Name FROM Profile
            WHERE Name = :AspenConstants.PROFILE_STD OR
            Name = :AspenConstants.PROFILE_ADMIN
        ]) {
            profileNameToRec.put(prof.Name, prof);
        }
        Id profileIdStd = profileNameToRec.get(AspenConstants.PROFILE_STD).Id;
        Id profileIdAdmin = profileNameToRec.get(AspenConstants.PROFILE_ADMIN).Id;

        // Create Users
        Map<String, User> emailToUser = new Map<String, User>{
            EMAIL_STD_ONE => TestUtil.makeTestUser(
                profileIdStd,
                EMAIL_STD_ONE,
                EMAIL_STD_ONE,
                GROUP_TRANSLATOR,
                false
            ),
            EMAIL_STD_TWO => TestUtil.makeTestUser(
                profileIdStd,
                EMAIL_STD_TWO,
                EMAIL_STD_TWO,
                GROUP_TRANSLATOR,
                false
            ),
            EMAIL_ADMIN_ONE => TestUtil.makeTestUser(
                profileIdAdmin,
                EMAIL_ADMIN_ONE,
                EMAIL_ADMIN_ONE,
                GROUP_DEFAULT,
                false
            ),
            EMAIL_STD_THREE => TestUtil.makeTestUser(
                profileIdStd,
                EMAIL_STD_THREE,
                EMAIL_STD_THREE,
                GROUP_DEFAULT,
                false
            ),
            EMAIL_ADMIN_THREE_QA => TestUtil.makeTestUser(
                profileIdAdmin,
                EMAIL_ADMIN_THREE_QA,
                EMAIL_ADMIN_THREE_QA,
                GROUP_TRANSLATOR,
                false
            ),
            EMAIL_STD_FOUR => TestUtil.makeTestUser(
                profileIdStd,
                EMAIL_STD_FOUR,
                EMAIL_STD_FOUR,
                GROUP_DEFAULT,
                false
            )
        };
        User aspenUserFour = emailToUser.get(EMAIL_STD_FOUR);
        aspenUserFour.FirstName = 'FirstName';
        aspenUserFour.LastName = 'LastName';
        insert emailToUser.values();

        // Apply Permission Sets and Groups
        System.runAs(emailToUser.get(EMAIL_ADMIN_ONE)) {
            User approverUserThree = emailToUser.get(EMAIL_STD_THREE);
            TestDataFactory.createSObject(new ADD_App_Settings__c(
                Restrict_Validation_Rules__c = false,
                SetupOwnerId = approverUserThree.Id),
            true);

            Map<String, Group> groupNameToRec = new Map<String, Group>();
            for (Group gr : [SELECT Id, DeveloperName FROM Group
                WHERE DeveloperName = :AspenConstants.GROUP_QC OR
                DeveloperName = :AspenConstants.GROUP_QNC
            ]) {
                groupNameToRec.put(gr.DeveloperName, gr);
            }

            User testUserTwo = emailToUser.get(EMAIL_STD_TWO);
            insert new GroupMember[]{
                new GroupMember(
                    GroupId = groupNameToRec.get(AspenConstants.GROUP_QC).Id,
                    UserOrGroupId = testUserTwo.Id
                ),
                new GroupMember(
                    GroupId = groupNameToRec.get(AspenConstants.GROUP_QNC).Id,
                    UserOrGroupId = testUserTwo.Id
                ),
                new GroupMember(
                    GroupId = groupNameToRec.get(AspenConstants.GROUP_QNC).Id,
                    UserOrGroupId = aspenUserFour.Id
                )
            };

            List<PermissionSetAssignment> newPermissionSetAssignments = new List<PermissionSetAssignment> ();
            for (PermissionSet ps : [SELECT Id, Name FROM PermissionSet
                WHERE Name = :AspenConstants.GROUP_QNC OR
                Name = 'Quality_Customer_Letter_Approver'
            ]) {
                newPermissionSetAssignments.add(new PermissionSetAssignment(
                    PermissionSetId = ps.Id,
                    AssigneeId = approverUserThree.Id
                ));
            }
            insert newPermissionSetAssignments;
        }

        return emailToUser;
    }

    @IsTest
    private static void test() {
        Integer numRespBefore = [SELECT COUNT() FROM Customer_Response__c];

        CMPL123CME__Complaint__c complaint;
        CMPL123CME__Complaint__c complaintClosed;
        for (CMPL123CME__Complaint__c ticket : [
            SELECT Id, CMSNext_Ticket_ID__c
            FROM CMPL123CME__Complaint__c
            WHERE CMSNext_Ticket_ID__c = :TICKET_ONE OR
            CMSNext_Ticket_ID__c = :TICKET_TWO
        ]) {
            if (ticket.CMSNext_Ticket_ID__c == TICKET_ONE) {
                complaint = ticket;
            } else if (ticket.CMSNext_Ticket_ID__c == TICKET_TWO) {
                complaintClosed = ticket;
            }
        }

        List<Customer_Response__c> customerResponses = new List<Customer_Response__c> {
            new Customer_Response__c(
                Event__c = complaint.Id,
                Customer_Reply__c = 'Test Customer reply'
            ),
            new Customer_Response__c(
                Event__c = complaintClosed.Id,
                Customer_Reply__c = 'Test Customer reply'
            )
        };
        User testUserOne = [SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1];

        Test.startTest();
        insert customerResponses;
        Customer_Response__c response1 = customerResponses.get(0);
        response1.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL;
        response1.Additional_Approvals__c = 'Tech Approval';
        response1.Assign_To__c = UserInfo.getUserId();
        response1.Quality_Approver__c = testUserOne.Id;

        Customer_Response__c response2 = customerResponses.get(1);
        response2.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
        response2.Assign_To__c = UserInfo.getUserId();
        response2.Quality_Approver__c = testUserOne.Id;

        Set<Id> thisResponseIdSet = new Set<Id>{ response1.Id, response2.Id };

        update customerResponses;
        delete customerResponses;

        CustomerResponseTriggerHandler.processEligibleComplaintsToComplete(
            new Set<String>{
                complaint.Id
            }
        );
        Test.stopTest();

        // R3.1, Larry: Made this assert and the one after it succeed even if more
        // Customer Responses are made in testSetup.
        System.assertEquals(customerResponses.size(), [
            SELECT COUNT() FROM Customer_Response__c
            WHERE Id IN :thisResponseIdSet ALL ROWS]);
        Integer numRespAfter = [SELECT COUNT() FROM Customer_Response__c];
        System.assertEquals(0, numRespBefore - numRespAfter,
            'Should have as many Customer Response records as we started with');
    }

    @isTest
    static void testAutomaticTask() {
         User aspenUserFour;
         User adminUserFour;
         for (User usr : [
             SELECT Id, Email FROM User
             WHERE Email = :EMAIL_STD_FOUR OR
             Email = :EMAIL_ADMIN_ONE
             LIMIT 2
         ]) {
             if (usr.Email == EMAIL_STD_FOUR) {
                 aspenUserFour = usr;
             } else if (usr.Email == EMAIL_ADMIN_ONE) {
                 adminUserFour = usr;
             }
         }
         Assert.isNotNull(aspenUserFour);
         Assert.isNotNull(adminUserFour);
 
         CMPL123CME__Complaint__c complaint = [SELECT Id FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_ID__c = :TICKET_FOUR];
 
         Customer_Response__c newCR = new Customer_Response__c(
             Event__c = complaint.Id,
             Assign_To__c = UserInfo.getUserId(),
             Quality_Approver__c = UserInfo.getUserId(),
             Customer_Reply__c = 'Test Customer reply',
             Reopened_By_New__c = 'test test',
             Responded_By_New__c = 'test test',
             CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
             CMPL123_WF_Action__c = null,
             CMPL123Task_Key_Value__c = 'Inquiry_Customer_Response'
         );
 
         insert newCR;
         // R3.1, Larry: I tried to leverage Ticket #4 from testSetup, but could not get it to work.
         // If someone performs this optimization, the query below would be helpful...
         // Customer_Response__c newCR = [
         //     SELECT Id, CMPL123_WF_Status__c, CMPL123_WF_Action__c
         //     FROM Customer_Response__c
         //     WHERE Event__r.CMSNext_Ticket_ID__c = :TICKET_FOUR
         //     LIMIT 1];
 
         Assert.isNotNull(newCR);
 
         Test.startTest();
         System.runAs(aspenUserFour) {
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Responded_Info_On_Labeling;
             update newCR;
 
             newCR = [SELECT Reopened_By_New__c, Responded_By_New__c, Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR.Id];//CHaRM-R4: Last Modified Date Time Field in the Query
             System.assertEquals(null, newCR.Reopened_By_New__c);
             System.assertEquals('test test', newCR.Responded_By_New__c);
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is getting updated when the workflow status is Closed-Done.
             System.assertEquals(String.valueOf(DateTime.now()).substring(0, 11), String.valueOf(newCR.Last_Modified_Date_Time__c).substring(0, 11));
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
             update newCR;
 
             newCR = [SELECT Responded_By_New__c, Reopened_By_New__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals(null, newCR.Responded_By_New__c);
             System.assertEquals('FirstName LastName', newCR.Reopened_By_New__c);
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
             update newCR;
 
             newCR = [SELECT Voided_By_New__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals('FirstName LastName', newCR.Voided_By_New__c);
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
             update newCR;
 
             newCR = [SELECT CMPL123_WF_Status__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals(AspenConstants.STR_WF_Opened, newCR.CMPL123_WF_Status__c);
 
             newCR.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL;
             newCR.CMPL123_WF_Action__c = 'Route for approval';
             newCR.Assign_To__c = UserInfo.getUserId();//CHaRM-R4: updating the Assignee Name Field
             update newCR;
 
             newCR = [SELECT CMPL123_WF_Status__c,Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR.Id];//CHaRM-R4: Last Modified Date Time Field in the Query
             System.assertEquals(AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL, newCR.CMPL123_WF_Status__c);
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is getting updated when the Assignee Name field is updated 
             System.assertEquals(String.valueOf(DateTime.now()).substring(0, 11), String.valueOf(newCR.Last_Modified_Date_Time__c).substring(0, 11));
 
             newCR.CMPL123_WF_Status__c = 'Quality Approval In Process';
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Process_Team_Approval;
             update newCR;
 
             newCR = [SELECT Routed_for_Approval_By_New__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals('FirstName LastName', newCR.Routed_for_Approval_By_New__c);
 
             newCR.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_PROMOTE_TO_RESPOND;
             newCR.CMPL123_WF_Action__c = 'Quality Approve Response';
             update newCR;
 
             newCR = [SELECT Quality_Approve_By__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals('FirstName LastName', newCR.Quality_Approve_By__c);
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Responded;
             newCR.Additional_Approvals__c = 'Regulatory Approval';
             update newCR;
 
             newCR = [SELECT Follow_up_Status__c, Responded_By_New__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals('FirstName LastName', newCR.Responded_By_New__c);
             System.assertEquals(AspenConstants.STR_Responded, newCR.Follow_up_Status__c);

             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
             update newCR;
 
             newCR.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL;
             newCR.CMPL123_WF_Action__c = 'Route for approval';
             update newCR;
 
             newCR.CMPL123_WF_Status__c = 'Quality,Tech,Regulatory Approval In Process';
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Process_Team_Approval;
             newCR.Regulatory_Approver__c = adminUserFour.Id;
             newCR.Technical_Approver__c = aspenUserFour.Id;
             update newCR;
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Quality_Reject;
             newCR.Rejection_Reason__c = 'test test';
             update newCR;
 
             newCR = [SELECT Reject_By__c FROM Customer_Response__c WHERE Id = :newCR.Id];
             System.assertEquals('FirstName LastName', newCR.Reject_By__c);

             newCR.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL;
             newCR.CMPL123_WF_Action__c = 'Route for approval';
             update newCR;
 
             newCR.CMPL123_WF_Status__c = 'Quality Approval In Process';
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Process_Team_Approval;
             update newCR;
 
             newCR.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_PROMOTE_TO_RESPOND;
             newCR.CMPL123_WF_Action__c = 'Quality Approve Response';
             update newCR;
 
             newCR.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
             newCR.CMPL123_WF_Action__c = AspenConstants.STR_Responded;
             newCR.Additional_Approvals__c = 'Tech Approval';
             update newCR;
 
             newCR = [SELECT Responded_By_New__c FROM Customer_Response__c WHERE Id = :newCR.Id];
         }
         //CHaRM-R4: Commented the below code and moved to end of the method
        // Test.stopTest();
 
         System.assertEquals('FirstName LastName', newCR.Responded_By_New__c);
         
         //CHaRM-R4: Created the below Customer Response record to Check the Negative scenario, where the Last Modified Date and Time field is not populated.
         Customer_Response__c newCR1 = new Customer_Response__c(
             Event__c = complaint.Id,
             Quality_Approver__c = UserInfo.getUserId(),
             Customer_Reply__c = 'Test Customer reply',
             Reopened_By_New__c = 'test test',
             Responded_By_New__c = 'test test',
             CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
             CMPL123_WF_Action__c = null,
             CMPL123Task_Key_Value__c = 'Inquiry_Customer_Response'
         );
         
         insert newCR1;
         
         System.runAs(aspenUserFour) {
             
             newCR1.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
             newCR1.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
             update newCR1;
             
             newCR1 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR1.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is not getting updated when the workflow status is Closed-Voided.
             System.assertEquals(null, newCR1.Last_Modified_Date_Time__c);
             
             newCR1.CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened;
             newCR1.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
             update newCR1;
 
             newCR1 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR1.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is not getting updated when the workflow status is Opened.
             System.assertEquals(null, newCR1.Last_Modified_Date_Time__c);
 
             newCR1.CMPL123_WF_Status__c = AspenConstants.WF_STATUS_PENDING_QUALITY_APPROVAL;
             newCR1.CMPL123_WF_Action__c = 'Route for approval';
             newCR1.Customer_Reply__c = 'Test Customer reply for test';
             update newCR1;
 
             newCR1 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR1.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is not getting updated when the workflow status is Pending Quality Approval.
             System.assertEquals(null, newCR1.Last_Modified_Date_Time__c);
             
             newCR1.Customer_Reply__c = 'Test Customer';
             update newCR1;
             
             newCR1 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR1.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is not getting updated when any other fields are getting Updated and Saved.
             System.assertEquals(null, newCR1.Last_Modified_Date_Time__c);
 
             newCR1.CMPL123_WF_Status__c = 'Quality Approval In Process';
             newCR1.CMPL123_WF_Action__c = AspenConstants.STR_Process_Team_Approval;
             newCR1.Assign_To__c = UserInfo.getUserId();
             update newCR1;
 
             newCR1 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR1.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is getting updated when the Assignee Name is added for the first time in
             // "Quality Approval In Process".
             System.assertEquals(String.valueOf(DateTime.now()).substring(0, 11), String.valueOf(newCR1.Last_Modified_Date_Time__c).substring(0, 11));
 
             //CHaRM-R4: Created the below Customer Response record to Check the scenario, where the Last Modified Date and Time field is populated when Assignee Name
             // is first populated.
             Customer_Response__c newCR2 = new Customer_Response__c(
                 Event__c = complaint.Id,
                 Assign_To__c = UserInfo.getUserId(),
                 Quality_Approver__c = UserInfo.getUserId(),
                 Customer_Reply__c = 'Test Customer reply',
                 Reopened_By_New__c = 'test test',
                 Responded_By_New__c = 'test test',
                 CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened,
                 CMPL123_WF_Action__c = null,
                 CMPL123Task_Key_Value__c = 'Inquiry_Customer_Response'
             );
             
             insert newCR2;
             newCR2 = [SELECT Last_Modified_Date_Time__c FROM Customer_Response__c WHERE Id = :newCR2.Id];
             //CHaRM-R4:Added Below Assert to check the Last Modified Date Time Field is getting updated when the Assignee Name is inserted for the first time.
             System.assertEquals(String.valueOf(DateTime.now()).substring(0, 11), String.valueOf(newCR2.Last_Modified_Date_Time__c).substring(0, 11));
             
         }
         Test.stopTest();
     }
 
     /**
      * Accessibility test for prepTranslationItemsForVoiding
      * 
      * Tests that voiding a Customer Response should also void Translation Items pointing to it
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingFull() {
         User usr = [SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1];
 
         System.runAs(usr) {
             Customer_Response__c resp = [
                 SELECT Id, Event__c
                 FROM Customer_Response__c
                 WHERE Event__r.CMSNext_Ticket_ID__c = :TICKET_FIVE
                 LIMIT 1];
             List<Translation_Item__c> tItemList = [
                 SELECT Id, Translated__c, Field_Name__c, Related_Record_Id__c
                 FROM Translation_Item__c
                 WHERE Translation_Task__r.Parent_Ticket__r.CMSNext_Ticket_ID__c = :TICKET_FIVE];
             Assert.isFalse(tItemList.isEmpty(),
                 ERROR_SETUP + 'Should automatically make a Translation Item for a ' +
                 'Customer Response with Customer Expection (Native) filled out ' +
                 'under a translation-required Ticket');
             for (Translation_Item__c tItem : tItemList) {
                 Assert.isTrue(String.isBlank(tItem.Translated__c),
                     ERROR_SETUP + 'All Translation Items should still lack a translation');
             }
 
             Test.startTest();
             resp.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
             resp.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
             update resp;
             Test.stopTest();
 
             tItemList = [
                 SELECT Id, Translated__c, Related_Record_Id__c, Is_Voided__c
                 FROM Translation_Item__c
                 WHERE Translation_Task__r.Parent_Ticket__r.CMSNext_Ticket_ID__c = :TICKET_FIVE];
             Integer hits = 0;
             for (Translation_Item__c tItem : tItemList) {
                 if (tItem.Related_Record_Id__c == resp.Id) {
                     Assert.isTrue(tItem.Is_Voided__c,
                         ERROR_POS + 'The Flow should void the Translation Item ' +
                         'related to the Customer Response that was voided');
                     Assert.isTrue(tItem.Translated__c.contains(AspenConstants.TRANSLATION_NOT_NEEDED),
                         ERROR_POS + 'The Flow should have populated the ' +
                         'relevant Translation Item with the templatized text');
                     hits += 1;
                 } else {
                     Assert.isTrue(String.isBlank(tItem.Translated__c),
                         ERROR_POS + 'The Flow should ignore Translation Items ' +
                         'that are different than the Customer Response that was voided');
                 }
             }
             Assert.areEqual(1, hits, ERROR_POS + 'Should have exactly one Translation Item ' +
                 'related to the Customer Response that was voided because the only ' +
                 'field needing translation is Customer Expectation');
         }
     }
 
     /**
      * Pos tests for prepTranslationItemsForVoiding such that translations happen AFTER voiding
      * 
      * Specifically, we verify that voiding a Customer Response will cause
      * its related Translation Items to also get voided.
      * Since the Customer Response gets voided before the translations are provided,
      * the Translation Items should state that they have been voided.
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingPosVoidBeforeTranslate() {
         CMPL123CME__Complaint__c ticket = [
             SELECT Id, CMSNext_Ticket_ID__c,
             (
                 SELECT Id, CMPL123_WF_Action__c
                 FROM Customer_Responses__r
             )
             FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_ID__c = :TICKET_FIVE
             LIMIT 1
         ];
         // Verify that we are starting the test with good data
         Assert.isFalse(ticket.Customer_Responses__r.isEmpty(),
             ERROR_SETUP + 'The Ticket must HAVE a Customer Response');
         Customer_Response__c respOld = ticket.Customer_Responses__r[0];
         List<Translation_Item__c> transItemList = [
             SELECT Id, Is_Voided__c, Translated__c
             FROM Translation_Item__c
             WHERE Related_Record_Id__c = :respOld.Id
         ];
         Assert.isFalse(transItemList.isEmpty(),
             ERROR_SETUP + 'There SHOULD be Translation Item(s) for the Ticket');
 
         // Prepare variables to call the function and run the test
         Customer_Response__c respNew = respOld.clone();
         respNew.Id = respOld.Id; // clone does not copy the Id, but we DO need it
         respNew.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
         respOld.CMPL123_WF_Action__c = AspenConstants.STR_Quality_Reject;
         List<Customer_Response__c> triggerNewList = new List<Customer_Response__c>{
             respNew
         };
         Map<Id, Customer_Response__c> triggerOldMap = new Map<Id, Customer_Response__c>{
             respOld.Id => respOld
         };
 
         System.runAs((User)[SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1]) {
             Test.startTest();
             Integer queriesBefore = Limits.getQueries();
             Map<Id, Translation_Item__c> updatableTransItemToRecord =
                 CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(
                     triggerNewList, triggerOldMap);
             Integer queriesAfter = Limits.getQueries();
             Test.stopTest();
 
             Assert.areEqual(queriesBefore + 1, queriesAfter,
                 ERROR_POS + 'Expected a single query to get all Translation Items');
             Assert.areEqual(transItemList.size(), updatableTransItemToRecord.size(),
                 ERROR_POS + 'Should have processed ALL Translation Items');
             for (Translation_Item__c tItem : updatableTransItemToRecord.values()) {
                 Assert.isTrue(tItem.Translated__c.endsWith(AspenConstants.TRANSLATION_NOT_NEEDED),
                     ERROR_POS + 'Translated text needs a specific suffix to drive the Flow ' +
                     '"Void Translation Items after Customer Response is Voided"');
             }
         }
     }
 
     /**
      * Pos tests for prepTranslationItemsForVoiding such that translations happen BEFORE voiding
      * 
      * Specifically, we verify that voiding a Customer Response will cause
      * its related Translation Items to also get voided.
      * Since translations were provided before voiding,
      * the Translation Items should retain the text provided by the translator.
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingPosTranslateOnTime() {
         CMPL123CME__Complaint__c ticket = [
             SELECT Id, CMSNext_Ticket_ID__c,
             (
                 SELECT Id, CMPL123_WF_Action__c
                 FROM Customer_Responses__r
             )
             FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_ID__c = :TICKET_FIVE
             LIMIT 1
         ];
         // Verify that we are starting the test with good data
         Assert.isFalse(ticket.Customer_Responses__r.isEmpty(),
             ERROR_SETUP + 'The Ticket must HAVE a Customer Response');
         Customer_Response__c respOld = ticket.Customer_Responses__r[0];
         List<Translation_Item__c> transItemList = [
             SELECT Id, Is_Voided__c, Translated__c
             FROM Translation_Item__c
             WHERE Related_Record_Id__c = :respOld.Id
         ];
         Assert.areEqual(1, transItemList.size(),
             ERROR_SETUP + 'There SHOULD be Translation Item(s) for the Ticket');
 
         // This code block represents the Translation Item getting the translation
         // back from the translator via email, and the translation applied to
         // the Customer Response
         {
             respOld.Customer_Expectation_Translated__c = TRANSLATED_TEXT;
             transItemList[0].Translated__c = TRANSLATED_TEXT;
             update new SObject[]{ respOld, transItemList[0] };
         }
 
         // Prepare variables to call the function and run the test
         Customer_Response__c respNew = respOld.clone();
         respNew.Id = respOld.Id; // clone does not copy the Id, but we DO need it
         respNew.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
         respOld.CMPL123_WF_Action__c = AspenConstants.STR_Quality_Reject;
         List<Customer_Response__c> triggerNewList = new List<Customer_Response__c>{
             respNew
         };
         Map<Id, Customer_Response__c> triggerOldMap = new Map<Id, Customer_Response__c>{
             respOld.Id => respOld
         };
 
         System.runAs((User)[SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1]) {
             Test.startTest();
             Integer queriesBefore = Limits.getQueries();
             Map<Id, Translation_Item__c> updatableTransItemToRecord =
                 CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(
                     triggerNewList, triggerOldMap);
             Integer queriesAfter = Limits.getQueries();
             Test.stopTest();
 
             Assert.areEqual(queriesBefore + 1, queriesAfter,
                 ERROR_POS + 'Expected a single query to get all Translation Items');
             Assert.areEqual(transItemList.size(), updatableTransItemToRecord.size(),
                 ERROR_POS + 'Should have processed ALL Translation Items');
             for (Translation_Item__c tItem : updatableTransItemToRecord.values()) {
                 Assert.areEqual(TRANSLATED_TEXT, tItem.Translated__c,
                     ERROR_POS + 'Translated text from the vendor should not be ' +
                     'replaced by the translation-is-voided template text');
             }
         }
     }
 
     /**
      * Neg tests for prepTranslationItemsForVoiding which should result in avoiding queries
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingNegNoSoql() {
         Test.startTest();
         final String ERROR_MUST_BE_EMPTY = ERROR_NEG +
             'Should return an empty collection if no work is needed';
         List<Customer_Response__c> emptyTriggerNewList = new List<Customer_Response__c>();
         Map<Id, Customer_Response__c> emptyTriggerOldMap = new Map<Id, Customer_Response__c>();
         Map<Id, Translation_Item__c> returnValue;
         Integer queriesAfter;
         Integer queriesBefore = Limits.getQueries();
         Customer_Response__c respNew = (Customer_Response__c) TestDataFactory.createSObject(
             new Customer_Response__c(CMPL123_WF_Action__c = AspenConstants.STR_Responded),
             false
         );
         Customer_Response__c respOld = respNew.clone();
         respOld.CMPL123_WF_Action__c = AspenConstants.STR_Reopen;
 
         // Test that SOQL is avoided when the inputs are empty or null
         {
             returnValue = CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(
                 emptyTriggerNewList, emptyTriggerOldMap);
             queriesAfter = Limits.getQueries();
             Assert.areEqual(queriesBefore, queriesAfter,
                 ERROR_NEG + 'Should not do SOQL when both input parameters are empty. This should never happen');
             Assert.isTrue(returnValue.isEmpty(), ERROR_MUST_BE_EMPTY);
 
             returnValue = CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(emptyTriggerNewList, null);
             queriesAfter = Limits.getQueries();
             Assert.areEqual(queriesBefore, queriesAfter,
                 ERROR_NEG + 'Should not do SOQL when Trigger.oldMap is empty. Implies a After-Insert scenario');
             Assert.isTrue(returnValue.isEmpty(), ERROR_MUST_BE_EMPTY);
         }
 
         // Test that SOQL is avoided if the Customer Response is in the wrong WorkFlow Action
         {
             List<Customer_Response__c> triggerNew = new List<Customer_Response__c>{respNew};
             Map<Id, Customer_Response__c> triggerOldMap = new Map<Id, Customer_Response__c>{
                 TestUtil.getFakeId(Customer_Response__c.SObjectType) => respOld
             };
             returnValue = CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(triggerNew, null);
             queriesAfter = Limits.getQueries();
             Assert.areEqual(queriesBefore, queriesAfter,
                 ERROR_NEG + 'Should not do SOQL on After-Insert if the Customer Response is in the wrong Action');
             Assert.isTrue(returnValue.isEmpty(), ERROR_MUST_BE_EMPTY);
 
             returnValue = CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(triggerNew, triggerOldMap);
             queriesAfter = Limits.getQueries();
             Assert.areEqual(queriesBefore, queriesAfter,
                 ERROR_NEG + 'Should not do SOQL on Before-Update if the Customer Response is in the wrong Action');
             Assert.isTrue(returnValue.isEmpty(), ERROR_MUST_BE_EMPTY);
         }
         Test.stopTest();
     }
 
     /**
      * Neg tests for prepTranslationItemsForVoiding such that a voided Customer Response has NO Translation Items
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingNegNoTransItem() {
         CMPL123CME__Complaint__c ticket = [
             SELECT Id, CMSNext_Ticket_ID__c,
             (
                 SELECT Id, CMPL123_WF_Action__c
                 FROM Customer_Responses__r
             )
             FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_ID__c = :TICKET_SIX
             LIMIT 1
         ];
         // Verify that we are starting the test with good data
         Assert.isFalse(ticket.Customer_Responses__r.isEmpty(),
             ERROR_SETUP + 'The Ticket must HAVE a Customer Response');
         Customer_Response__c respOld = ticket.Customer_Responses__r[0];
         List<Translation_Item__c> transItemList = [
             SELECT Id, Is_Voided__c, Translated__c
             FROM Translation_Item__c
             WHERE Related_Record_Id__c = :respOld.Id
         ];
         Assert.isTrue(transItemList.isEmpty(),
             ERROR_SETUP + 'There should NOT be Translation Items for the Ticket');
 
         // Prepare variables to call the function and run the test
         Customer_Response__c respNew = respOld.clone();
         respNew.Id = respOld.Id; // clone does not copy the Id, but we DO need it
         respNew.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
         respOld.CMPL123_WF_Action__c = AspenConstants.STR_Quality_Reject;
         List<Customer_Response__c> triggerNewList = new List<Customer_Response__c>{
             respNew
         };
         Map<Id, Customer_Response__c> triggerOldMap = new Map<Id, Customer_Response__c>{
             respOld.Id => respOld
         };
 
         System.runAs((User)[SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1]) {
             Test.startTest();
             Integer queriesBefore = Limits.getQueries();
             Map<Id, Translation_Item__c> updatableTransItemToRecord =
                 CustomerResponseTriggerHandler.prepTranslationItemsForVoiding(
                     triggerNewList, triggerOldMap);
             Integer queriesAfter = Limits.getQueries();
             Test.stopTest();
 
             Assert.areEqual(queriesBefore + 1, queriesAfter,
                 ERROR_NEG + 'Expected a single query to get all Translation Items');
             Assert.isTrue(updatableTransItemToRecord.isEmpty(),
                 ERROR_NEG + 'Should have processed NO Translation Items');
         }
     }
 
     /**
      * Neg test to verify that Translation Items are not updated if their parent is locked
      * 
      * This scenario can happen if a Complaint Ticket is demoted to a Service Ticket.
      * This will cause the Customer Response to Closed-Voided WorkFlow Status.
      * That will cause any Translation Items pointing to that Customer Response
      * to be put through CustomerResponseTriggerHandler's
      * prepTranslationItemsForVoiding function.
      * 
      * If the Translation Task was already locked, then the Translation Items
      * cannot be updated.
      * @author R3.1, Larry Resnik
      */
     @isTest
     static void testPrepTranslationItemsForVoidingNegOnVoidResponse() {
         CMPL123CME__Complaint__c ticket = [
             SELECT Id, CMSNext_Ticket_ID__c,
             (
                 SELECT Id, CMPL123_WF_Action__c
                 FROM Customer_Responses__r
             )
             FROM CMPL123CME__Complaint__c
             WHERE CMSNext_Ticket_ID__c = :TICKET_SEVEN
             LIMIT 1
         ];
         Customer_Response__c resp = ticket.Customer_Responses__r[0];
 
         // Create a Translation Task for each potential WorkFlow Status it can be in.
         // Since they are locked in Closed-Done and Closed-Voided WorkFlow Status,
         // we must initialize them in a not-locked WorkFlow Status.
         Map<String, Translation_Task__c> wfStatusToTransTask = new Map<String, Translation_Task__c>{
             AspenConstants.STR_WF_Opened =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
                 ), false),
             AspenConstants.STR_In_Process =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = AspenConstants.STR_In_Process
                 ), false),
             AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = AspenConstants.WF_STATUS_TASK_SENT_TO_VENDOR
                 ), false),
             TRANS_TASK_WFSTATUS_PENDING =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = TRANS_TASK_WFSTATUS_PENDING
                 ), false),
             AspenConstants.STR_WF_Closed_Done =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
                 ), false),
             AspenConstants.STR_WF_Closed_Voided =>
                 (Translation_Task__c) TestDataFactory.createSObject(new Translation_Task__c(
                     Parent_Ticket__c = ticket.Id,
                     CMPL123_WF_Status__c = AspenConstants.STR_WF_Opened
                 ), false)
         };
         insert wfStatusToTransTask.values();
 
         // Create Translation Items under the to-be-locked Translation Tasks
         Translation_Task__c transTaskDone = wfStatusToTransTask.get(AspenConstants.STR_WF_Closed_Done);
         Translation_Task__c transTaskVoid = wfStatusToTransTask.get(AspenConstants.STR_WF_Closed_Voided);
         List<Translation_Item__c> transItemsWithLockedParents = new List<Translation_Item__c>{
             (Translation_Item__c) TestDataFactory.createSObject(new Translation_Item__c(
                 Translation_Task__c = transTaskDone.Id,
                 Field_Name__c = TRANS_FIELD_NAME,
                 Related_Record_Id__c = resp.Id,
                 Translated__c = 'This is for Closed-Done'
             ), false),
             (Translation_Item__c) TestDataFactory.createSObject(new Translation_Item__c(
                 Translation_Task__c = transTaskVoid.Id,
                 Field_Name__c = TRANS_FIELD_NAME,
                 Related_Record_Id__c = resp.Id,
                 Translated__c = 'This is for Closed-Voided'
             ), false)
         };
         insert transItemsWithLockedParents;
 
         // Obtain the LastModifiedDates from the Translation Items with
         // to-be-locked parent Translation Tasks
         Map<Id, Translation_Item__c> transItemIdToRec = new Map<Id, Translation_Item__c>([
             SELECT Id, LastModifiedDate
             FROM Translation_Item__c
             WHERE Id IN :transItemsWithLockedParents
         ]);
 
         // Finally, the to-be-locked Translation Tasks can be moved to their "locked" WorkFlow Statuses
         transTaskDone.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Done;
         transTaskVoid.CMPL123_WF_Status__c = AspenConstants.STR_WF_Closed_Voided;
         update new Translation_Task__c[]{ transTaskDone, transTaskVoid };
 
         // Verify that the Translation Items under locked Translation Tasks
         // (those that are Closed-Done or Closed-Voided) do not get updated
         Customer_Response__c response = [SELECT Id, Event__c, CMPL123_WF_Status__c, CMPL123_WF_Action__c
             FROM Customer_Response__c LIMIT 1];
         response.CMPL123_WF_Action__c = AspenConstants.STR_WF_Action_Void;
 
         Test.startTest();
         update response;
         Test.stopTest();
 
         // Verify that Translation Items under locked Translation Tasks were untouched
         for (Translation_Item__c transItemNew : [
             SELECT Id, LastModifiedDate
             FROM Translation_Item__c
             WHERE Id IN :transItemsWithLockedParents
         ]) {
             Translation_Item__c transItemOld = transItemIdToRec.get(transItemNew.Id);
             Assert.areEqual(transItemOld.LastModifiedDate, transItemNew.LastModifiedDate,
                 ERROR_NEG + 'Should not update Translation Items under locked Translation Tasks');
         }
     }
     
     
      /*
     * @Method       : testCustomerResponseWFResponded.
     * @Description  : validation error is thrown when workflow action is Responded and having Translation items which are not in closed status.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Release      : CHARM 7- IPDR 746
     */
     @isTest
     static void testCustomerResponseWFResponded() {
         User usr = [SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1];
         System.runAs(usr) {
             Customer_Response__c resp = [SELECT Id, Event__c,CMPL123_WF_Status__c FROM Customer_Response__c WHERE Event__r.CMSNext_Ticket_ID__c = :TICKET_FIVE LIMIT 1];
             List<Translation_Item__c> tItemList = [SELECT Id, Translated__c, Field_Name__c, Related_Record_Id__c FROM Translation_Item__c WHERE Translation_Task__r.Parent_Ticket__r.CMSNext_Ticket_ID__c = :TICKET_FIVE];
             Test.startTest();
             try{
                 resp.CMPL123_WF_Status__c = 'Closed-Done';
                 resp.CMPL123_WF_Action__c = AspenConstants.STR_Responded;
                 update resp;
             }
             catch (Exception e) {
                 String msg = e.getmessage();
                 if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                     Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                     String errorMessage = msg.substring(startIndex).trim();
                     // Assert to check - validation error is thrown when customer response is updated to 'Closed-Done'and translation items are not in closed status
                     system.assertEquals(True, errorMessage.contains(Label.CR_Validation_Message));
                 }
             }    
             Test.stopTest();
         }
     }
     
     /*
     * @Method       : testCustomerResponseWFRespondedInfoOnLabeling.
     * @Description  : validation error is thrown when workflow action is RespondedInfoOnLabeling and having Translation items which are not in closed status.
     * @Return       : N/A.
     * @Params       : N/A.
     * @Release      : CHARM 7- IPDR 746
     */
     @isTest
     static void testCustomerResponseWFRespondedInfoOnLabeling() {
         User usr = [SELECT Id FROM User WHERE Email = :EMAIL_STD_ONE LIMIT 1];
         System.runAs(usr) {
             Customer_Response__c resp = [SELECT Id, Event__c,CMPL123_WF_Status__c FROM Customer_Response__c WHERE Event__r.CMSNext_Ticket_ID__c = :TICKET_FIVE LIMIT 1];
             List<Translation_Item__c> tItemList = [SELECT Id, Translated__c, Field_Name__c, Related_Record_Id__c FROM Translation_Item__c WHERE Translation_Task__r.Parent_Ticket__r.CMSNext_Ticket_ID__c = :TICKET_FIVE];
             Test.startTest();
             try{
                 resp.CMPL123_WF_Status__c = 'Closed-Done';
                 resp.CMPL123_WF_Action__c = 'Responded Info on Labeling';
                 update resp;
             }
             catch (Exception e) {
                 String msg = e.getmessage();
                 if (msg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                     Integer startIndex = msg.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION'.length();
                     String errorMessage = msg.substring(startIndex).trim();
                     // Assert to check - validation error is thrown when customer response is updated to 'Closed-Done'and translation items are not in closed status
                     system.assertEquals(True, errorMessage.contains(Label.CR_Validation_Message));
                 }
             }    
             Test.stopTest();
         }
     }
 }