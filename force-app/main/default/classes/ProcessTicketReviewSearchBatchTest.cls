/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ProcessTicketReviewSearchBatchTest.
* @Why   : ProcessTicketReviewSearchBatchTest test class for the ProcessTicketReviewSearchBatch class.
* @When  : 06-AUG-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 06-AUG-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class ProcessTicketReviewSearchBatchTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {
        //Create Ticket Review
        String ticketReviewRecTypeId = Schema.SObjectType.Ticket_Review__c.getRecordTypeInfosByName().get('Recurrence Search').getRecordTypeId();
        User qaUser = [SELECT Id FROM User WHERE Profile.Name = 'Aspen User' AND isActive = true LIMIT 1];
        Ticket_Review__c ticketReview = (Ticket_Review__c) TestDataFactory.createSObject(new Ticket_Review__c(
        	RecordTypeId = ticketReviewRecTypeId,
            FA_CAPA_Short_Description__c = 'Description',
            CAPA_Number__c = '123',
            Quality_Assignee_Name__c = qaUser.Id,
            Search_Frequency__c = 'Two Weeks (14 days)',
            Division__c = 'ADD', 
            Status__c = 'Active',
            Medical_Assignee_Name__c = qaUser.Id
        ), true);
        
        //Create Ticket
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(); 
        CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = compRecTypeId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345',
            	Registration_Ticket_Owner_email__c = 'test@test.com',
        		Was_an_Adverse_Event_Identified__c = 'No'),
                true
        );
        
        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);
        
        //Create Country Submission type
        TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);
        
        //Create EMDR
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId = initialRTId,
            CMPL123CME__Complaint__c = complaint.Id,
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id
        ), true);
    }
    
    /*
    * @Method       : processTicketReviewSearchBatchParentTest.
    * @Description  : To test the ProcessTicketReviewSearchBatch functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processTicketReviewSearchBatchParentTest() {

        String strQuery = 'SELECT Id, Was_an_Adverse_Event_Identified__c FROM CMPL123CME__Complaint__c';
        String strTicketReviewId = [SELECT Id FROM Ticket_Review__c].id;
        Map<String,String> mapChildObjectAPIAndTicketField = New Map<String,String>{'CMPL123CME__EMDR__c' => 'CMPL123CME__Complaint__c'};
        Map<String,String> mapChildObjectAPINameAndQuery = New Map<String,String>{'CMPL123CME__EMDR__c' => 'SELECT Id FROM CMPL123CME__EMDR__c'};
        Set<String> setobjectsIncludedInSearch = New Set<String>{[SELECT Id FROM CMPL123CME__Complaint__c].Id};
            
        Test.startTest();
        ProcessTicketReviewSearchBatch ptrsb = new ProcessTicketReviewSearchBatch(strQuery, strTicketReviewId, true, mapChildObjectAPIAndTicketField, mapChildObjectAPINameAndQuery, setobjectsIncludedInSearch);
        Database.executeBatch(ptrsb);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM Ticket_Search_Result__c].size(), 'Ticket Search Result record should be created');
    }
    
    /*
    * @Method       : processTicketReviewSearchBatchChildTest.
    * @Description  : To test the ProcessTicketReviewSearchBatch functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processTicketReviewSearchBatchChildTest() {

        String strQuery = 'SELECT Id, CMPL123CME__Complaint__c FROM CMPL123CME__EMDR__c';
        String strTicketReviewId = [SELECT Id FROM Ticket_Review__c].id;
        Map<String,String> mapChildObjectAPIAndTicketField = New Map<String,String>{'CMPL123CME__EMDR__c' => 'CMPL123CME__Complaint__c'};
        Map<String,String> mapChildObjectAPINameAndQuery = New Map<String,String>();
        Set<String> setobjectsIncludedInSearch = New Set<String>{[SELECT Id FROM CMPL123CME__Complaint__c].Id};
            
        Test.startTest();
        ProcessTicketReviewSearchBatch ptrsb = new ProcessTicketReviewSearchBatch(strQuery, strTicketReviewId, false, mapChildObjectAPIAndTicketField, mapChildObjectAPINameAndQuery, setobjectsIncludedInSearch);
        Database.executeBatch(ptrsb);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM Ticket_Search_Result__c].size(), 'Ticket Search Result record should be created');
    }
}