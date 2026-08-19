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
* Admin                    12-DEC-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class ReopenjustWithInqTicketsMDCCustomTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @testSetup static void setupData() {
        TestUtil.setupMDC(
            ReopenjustWithInqTicketsMDCCustom.class,
            Re_Open_Justification__c.getSObjectType(),
            Re_Open_Justification__c.Re_Open_Justification_Added__c
        );

        Re_Open_Justification__c record = new Re_Open_Justification__c(Re_Open_Justification_Added__c = 'T');
        Insert record;
    }

    /**
    * @Method       : customValidationTest
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    private static void customValidationTest() {
        Re_Open_Justification__c record = [SELECT Id, Re_Open_Justification_Added__c FROM Re_Open_Justification__c];
        
        Test.startTest();
        record.Re_Open_Justification_Added__c = 'TBD';
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