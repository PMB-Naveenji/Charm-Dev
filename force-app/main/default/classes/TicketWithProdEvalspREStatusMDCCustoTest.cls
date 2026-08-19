/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : TicketWithProdEvalspREStatusMDCCustoTest.
* @Why   : TicketWithProdEvalspREStatusMDCCustoTest test class for the TicketWithProdEvalspREStatusMDCCustom class.
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
public class TicketWithProdEvalspREStatusMDCCustoTest {
    
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */ 
    @testSetup static void setupData() {
        TestUtil.setupMDC(
                TicketWithProdEvalspREStatusMDCCustom.class,
                CMPL123CME__Complaint__c.getSObjectType(),
                CMPL123CME__Complaint__c.pRE_Status__c
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
    * @Description  : To test the TicketWithProdEvalspREStatusMDCCustom functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    static void customValidationTest() {
        CMPL123CME__Complaint__c record = [SELECT Id, pRE_Status__c FROM CMPL123CME__Complaint__c];
        
        Test.startTest();
        
        record.pRE_Status__c = 'Yes';
        TestDataFactory.updateSObject(record);
        
        TicketQDNumMDCCustom.hasProdEval = false;
        record.pRE_Status__c = 'No';
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