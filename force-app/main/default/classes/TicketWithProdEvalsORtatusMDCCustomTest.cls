/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketWithProdEvalsORtatusMDCCustomTest.
* @Why   : TicketWithProdEvalsORtatusMDCCustomTest test class for the TicketWithProdEvalsORtatusMDCCustom class.
* @When  : 09-JUL-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 13-JUL-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TicketWithProdEvalsORtatusMDCCustomTest {
    
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */ 
    @testSetup static void setupData() {
        TestUtil.setupMDC(
                TicketWithProdEvalsORtatusMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.Overall_Reportable_Status__c
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
    * @Description  : To test the TicketWithProdEvalsORtatusMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void customValidationTest() {
        CMPL123CME__Complaint__c record = [SELECT Id, Overall_Reportable_Status__c FROM CMPL123CME__Complaint__c];
        
        Test.startTest();
        
        record.Overall_Reportable_Status__c = 'TPM Responsible';
        TestDataFactory.updateSObject(record);
        
        TicketQDNumMDCCustom.hasProdEval = false;
        record.Overall_Reportable_Status__c = 'Reportable';
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