/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 14-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    21-DEC-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class PTWithProdEvalFieldsChangeMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
        //Create Complaint
        insert new CMPL123CME__Complaint__c (
            Ticket_Type__c = 'Inquiry',
            Follow_up_Status__c = 'Responded',
            Customer_Reply_Required__c = true,
            Ticket_Description__c = 'Test Desc',
            Product_Ticket_Added__c = 'TBD'
        );

        TestUtil.setupMDC (
            PTWithProdEvalFieldsChangeMDCCustom.class,
            CMPL123CME__Complaint__c.getSObjectType(),
            CMPL123CME__Complaint__c.Product_Ticket_Added__c
        );
    }

    /**
    * @Method       : customValidationTest
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    private static void customValidationTest() {
        CMPL123CME__Complaint__c record = [SELECT Id, Product_Ticket_Added__c FROM CMPL123CME__Complaint__c];
        record.Product_Ticket_Added__c = 'Likely Cause';
        Test.startTest();
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