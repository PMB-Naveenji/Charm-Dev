/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDUtilTest.
* @Why   : ADDUtilTest class for the ADDUtil class.
* @When  : 13-DEC-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                13-DEC-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                03-JUN-2020            N/A                           Test class optimization.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                10-JUN-2020            N/A                           Changed test email.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                18-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Juneid                27-JAN-2021            Error Fix                   Updated the code to fix the Workflow key value error
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class ADDUtilTest {
    /*
    * @Method       : setup.
    * @Description  : To setup test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup static void setup() {
        insertTestData();
    }

    /*
    * @Method       : setupData.
    * @Description  : To insert test data asynchronously.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @future
    static void insertTestData() {
            // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);

        Country_Submission_Type__c objCountrySubmissionType = (Country_Submission_Type__c) TestDataFactory.createSObject(
                new Country_Submission_Type__c(
                        Name = '30 Days',
                        Calendar_Days__c = 30,
                        Country__c = objCountry.Id
                ), true);

        // Create Complaint
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();
        CMPL123CME__Complaint__c objComplaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'INDIA',
                RecordTypeId = complaintRTId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                Overall_Reportable_Status__c = 'Not Reportable'
        ), true);

        //Create Workflow Status
        CMPL123__WF_Status__c status = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Opened'), true);

        //Create Workflow Status
        CMPL123__WF_Status__c statusClosed = (CMPL123__WF_Status__c) TestDataFactory.createSObject(new CMPL123__WF_Status__c (
                Name = 'Closed-Voided'), true);

        //Create Workflow Action
        CMPL123__WF_Action__c action = (CMPL123__WF_Action__c) TestDataFactory.createSObject(new CMPL123__WF_Action__c (
                Name = 'Void'), true);

        //Create Workflow rule for Prod Eval Assess
        CMPL123__WF_Rule__c assessProdRule = (CMPL123__WF_Rule__c) TestDataFactory.createSObject(new CMPL123__WF_Rule__c(
                CMPL123__Target_Object__c = 'CMPL123CME__Investigation__c(PRODEVAL_WORKFLOW)',
                CMPL123__Record_Type__c = 'PRODEVAL_WORKFLOW',
                CMPL123__Is_Active__c = true,
                CMPL123__Has_Multiple_Actions__c = true), true);

        //Create workflow step
        CMPL123__WF_Step__c wFStep = (CMPL123__WF_Step__c) TestDataFactory.createSObject(new CMPL123__WF_Step__c(
            CMPL123__Start_Status__c = status.Id,
            CMPL123__End_Status__c = statusClosed.Id,
            CMPL123__Action__c = action.Id,
            CMPL123__Order__c = 1.0,
            CMPL123__WF_Rule__c = assessProdRule.Id,
            CMPL123__Is_Start_Step__c = true), true); //Juneid 27 Jan 2021,Added CMPL123__Is_Start_Step__c as true to fix workflow key value Error
    }

    /*
    * @Method       : generateNotificationTest.
    * @Description  : To test the ADDUtil class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void generateNotificationTest() {
        CMPL123CME__Complaint__c objComplaint = [SELECT Id from CMPL123CME__Complaint__c LIMIT 1];

        Messaging.SingleEmailMessage objEmail = ADDUtil.generateNotification('Test Body.', objComplaint.Id, 'Test subject.', new List<String>{
                'test@test.com'
        });

        System.assertEquals(false, objEmail != null ? false : true);
    }

    /*
    * @Method       : processAutomatedHistoryRecordTest.
    * @Description  : To test the ADDUtil class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processAutomatedHistoryRecordTest() {

        CMPL123CME__Complaint__c objComplaint = [SELECT Id from CMPL123CME__Complaint__c LIMIT 1];
        CMPL123__WF_Step__c wFStep = [SELECT Id,CMPL123__Action__r.Name,CMPL123__End_Status__r.Name,CMPL123__Start_Status__r.Name FROM CMPL123__WF_Step__c LIMIT 1];

        CMPL123__WF_History__c objWfHistory = ADDUtil.processAutomatedHistoryRecord(objComplaint.Id, wFStep);
        System.assertEquals(false, objWfHistory != null ? false : true);
    }

    /*
    * @Method       : getObjectDetailsTest.
    * @Description  : To test the ADDUtil class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void getObjectDetailsTest() {
        Boolean hasComplaint = false;
        for (ADDSearchController.ObjectDetail objDetail : ADDUtil.getObjectDetails()) {
            if (objDetail.objectAPI == 'CMPL123CME__Complaint__c') {
                hasComplaint = true;
                break;
            }
        }
        System.assert(hasComplaint);
    }

    /*
    * @Method       : processTicketSearchResultsTest.
    * @Description  : To test the ADDUtil class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void processTicketSearchResultsTest() {
        Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(
                new Ticket_Review__c(
                        FA_CAPA_Short_Description__c = 'test',
                        CAPA_Number__c = 'test',
                        Search_Frequency__c = 'Two Weeks (14 days)',
                        Division__c = 'ADD',
                        Pending_Batch_Jobs__c = '7070j00000OO6fAAAT',
                        Status__c = 'Active',
                        Medical_Assignee_Name__c = Userinfo.getUserId()
                ), true);
        String complaintRTId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId();

        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(
                new CMPL123CME__Complaint__c(
                        RecordTypeId = complaintRTId
                ), true);

        Ticket_Search_Result__c objTicketSearchResult = (Ticket_Search_Result__c) TestDataFactory.createSObject(
                new Ticket_Search_Result__c(
                        Ticket_Review__c = ticketReview.Id,
                        Ticket_Review_Status__c = 'Related with Malfunction',
                        Ticket__c = complaint.Id,
                        Unique_Identifier__c = ticketReview.Id + '-' + complaint.Id
                ), true);
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial,
                        CMPL123CME__Complaint__c = complaint.Id
                ), true);
        Test.startTest();
        ADDUtil.processTicketSearchResults(new List<Id>{objTicketSearchResult.Id});
        Test.stopTest();
        Ticket_Search_Result__c ticketSearchresultUpdated = [SELECT Submission_Information__c FROM Ticket_Search_Result__c WHERE Id = :objTicketSearchResult.id];
        System.assertEquals('Initial~eMDR~Opened', ticketSearchresultUpdated.Submission_Information__c);

    }
}