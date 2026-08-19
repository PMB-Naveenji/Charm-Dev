/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ProcessMigratedAuditTest.
* @Why   : ProcessMigratedAuditTest test class for the ProcessMigratedAudit class.
* @When  : 31-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 31-JUL-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 08-SEP-2020         PMD                               Added assertion into 
*                                                                             'processMigratedAuditPMedicalEvaluationTest' method.
* ---------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class ProcessMigratedAuditTest {
    
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup static void setupData() {
        
        //Create Complaints
        List<CMPL123CME__Complaint__c > complaints = new List<CMPL123CME__Complaint__c >();
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(); 
        for(Integer i=0 ;i < 2; i++) {
            CMPL123CME__Complaint__c complaint = (CMPL123CME__Complaint__c) TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
                Division__c = 'ADD',
                pRE_Status__c = 'Yes',
                Country_of_origin__c = 'USA',
                RecordTypeId = compRecTypeId,
                Business_Unit__c = 'IA-CC',
                CMPL123CME__CMPL123_WF_Status__c = 'Opened',
                CMSNext_Ticket_Number__c = '12345' + i,
            	Registration_Ticket_Owner_email__c = 'test@test.com'),
                true
        );
            complaints.add(complaint);
        }
        
        //Create Country
        Country__c objCountry = (Country__c)TestDataFactory.createSObject(new Country__c(), true);
        
        //Create Country Submission type
        TestDataFactory.createSObject(new Country_Submission_Type__c(Name = '30 Days', Calendar_Days__c = 30, Country__c = objCountry.Id), true);
        
        //Create EMDR
        Id initialRTId = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c emdr = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(new CMPL123CME__EMDR__c(
            RecordTypeId = initialRTId,
            CMPL123CME__Complaint__c = complaints[0].Id,
            Submission_Type__c = [SELECT Id FROM Country_Submission_Type__c LIMIT 1].Id
        ), true);
        
        //Create Product-Tickets
        for(Integer i=0 ;i < 2; i++) {
            Product_Ticket__c pt = (Product_Ticket__c) TestDataFactory.createSObject(new Product_Ticket__c(
            	Event_Ticket__c = complaints[0].Id
            ), true);
        }
        
        //Create Medical Evaluations
        for(Integer i=0 ;i < 2; i++) {
            CMPL123CME__Questionnaire__c me = (CMPL123CME__Questionnaire__c) TestDataFactory.createSObject(new CMPL123CME__Questionnaire__c(
                CMPL123CME__Complaint__c = complaints[0].Id
            ), true);
        }
    }
    
    /*
    * @Method       : processMigratedAuditComplaintTest.
    * @Description  : To test the ProcessMigratedAudit functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processMigratedAuditComplaintTest() {
        Set<Id> complaintIds = (new Map<Id, CMPL123CME__Complaint__c>([SELECT Id FROM CMPL123CME__Complaint__c])).keySet();
        Test.startTest();
        
        ProcessMigratedAudit processMA = new ProcessMigratedAudit('CMPL123CME__Complaint__c', complaintIds);
        Database.executeBatch(processMA);
        
        Test.stopTest();
        System.assertEquals([SELECT Id FROM CMPL123CME__Complaint__c].size(), [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit Trail Entries should be created');
    }
    
    /*
    * @Method       : processMigratedAuditEMDRTest.
    * @Description  : To test the ProcessMigratedAudit functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processMigratedAuditEMDRTest() {
        Set<Id> emdrIds = (new Map<Id, CMPL123CME__EMDR__c>([SELECT Id FROM CMPL123CME__EMDR__c])).keySet();
        Test.startTest();
        
        ProcessMigratedAudit processMA = new ProcessMigratedAudit('CMPL123CME__EMDR__c', emdrIds);
        Database.executeBatch(processMA);
        
        Test.stopTest();
        System.assertEquals([SELECT Id FROM CMPL123CME__EMDR__c].size(), [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit Trail Entries should be created');
    }
    
    /*
    * @Method       : processMigratedAuditProductTicketTest.
    * @Description  : To test the ProcessMigratedAudit functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processMigratedAuditProductTicketTest() {
        Set<Id> productTicketIds = (new Map<Id, Product_Ticket__c>([SELECT Id FROM Product_Ticket__c])).keySet();
        Test.startTest();
        
        ProcessMigratedAudit processMA = new ProcessMigratedAudit('Product_Ticket__c', productTicketIds);
        Database.executeBatch(processMA);
        
        Test.stopTest();
        System.assertEquals([SELECT Id FROM Product_Ticket__c].size(), [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit Trail Entries should be created');
    }
    
    /*
    * @Method       : processMigratedAuditPMedicalEvaluationTest.
    * @Description  : To test the ProcessMigratedAudit functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void processMigratedAuditPMedicalEvaluationTest() {
        Test.startTest();
        ProcessMigratedAudit processMA = new ProcessMigratedAudit('CMPL123CME__Questionnaire__c');
        Id batchId = Database.executeBatch(processMA);
        Test.stopTest();

        System.assertNotEquals(null, batchId);
    }
    
    /*
    * @Method       : createAuditHistoryRecordsTest.
    * @Description  : To test the createAuditHistoryRecords functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void createAuditHistoryRecordsTest() {
        List<CMPL123CME__EMDR__c> records = [SELECT Id FROM CMPL123CME__EMDR__c];
        Set<Id> emdrIds = (new Map<Id, CMPL123CME__EMDR__c>([SELECT Id FROM CMPL123CME__EMDR__c])).keySet();
        Test.startTest();
        
        ProcessMigratedAudit ProcessMigratedAudit = new ProcessMigratedAudit('CMPL123CME__EMDR__c', emdrIds);
        ProcessMigratedAudit.createAuditHistoryRecords(records);
        
        Test.stopTest();
        
        System.assertEquals(records.size(), [SELECT Id FROM CMPL123__Audit_Trail_Entry__c].size(), 'Audit Trail Entries should be created');
    }
}