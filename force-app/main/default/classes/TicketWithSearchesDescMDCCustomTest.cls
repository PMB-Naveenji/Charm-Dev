/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketWithSearchesDescMDCCustomTest.
* @Why   : TicketWithSearchesDescMDCCustomTest test class for the TicketWithSearchesDescMDCCustom class.
* @When  : 09-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 24-JUL-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Kishor                10-MAY-2023         CHaRM R3.1, Defect IPDR# 186 Removed a Check "isTicketInquiry=False" for an Inquiry ticket
* --------------------------------------------------------------------------------------------------------------------------------------

*/
@isTest
public class TicketWithSearchesDescMDCCustomTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */ 
    @testSetup static void setupData() {
        
        TestUtil.setupMDC(
                TicketWithSearchesDescMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Ticket_Description__c
        );
        
        String compRecTypeId = Schema.SObjectType.CMPL123CME__Complaint__c.getRecordTypeInfosByName().get('Complaint').getRecordTypeId(); 
        //Create Complaint
        insert new CMPL123CME__Complaint__c(
                    	RecordTypeId = compRecTypeId,
                        Ticket_Type__c = 'Complaint',
                        Overall_Reportable_Status__c = 'Not Reportable',
                        Issue_code__c = 'TBDD',
                        pRE_Status__c = 'No');
    }

    /*
    * @Method       : customValidationTest.
    * @Description  : To test the TicketWithSearchesDescMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void customValidationTest() {
        
        CMPL123CME__Complaint__c record = [SELECT Id, Ticket_Description__c FROM CMPL123CME__Complaint__c];
        
        Test.startTest();
        
        record.Ticket_Description__c = 'TBD';
        TestDataFactory.updateSObject(record);
        
        TicketQDNumMDCCustom.hasTicketSearch = true;
        // 10-MAY-2023 Kishor: CHaRM R3.1, Defect IPDR# 186 Removed a Check "isTicketInquiry=False" for an Inquiry ticket 
        record.Ticket_Description__c = 'test';
        TestDataFactory.updateSObject(record);
        
        Test.stopTest();
        
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Insert']) {
             System.assertEquals('Insert', entry.CMPL123__Action__c);
        }
        for (CMPL123__Audit_Trail_Entry__c entry : [SELECT CMPL123__Action__c  FROM CMPL123__Audit_Trail_Entry__c  WHERE CMPL123__ParentId__c =: record.Id AND CMPL123__Action__c = 'Update']) {
             System.assertEquals('Update', entry.CMPL123__Action__c);
        }
        
    }
}