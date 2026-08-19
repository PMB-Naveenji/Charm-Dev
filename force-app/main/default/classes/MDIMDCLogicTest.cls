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
* Admin                    27-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    14-JAN-2021            TWD Upgrade          Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class MDIMDCLogicTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup() {
        insert new ADD_App_Settings__c(Restrict_Validation_Rules__c = true);
        Product_Ticket__c product = (Product_Ticket__c) TestDataFactory.createSObject(
                new Product_Ticket__c(),true);

        insert new CMPL123CME__MEDDEV__c(
                CMPL123_WF_Status__c = 'Regulatory',
                Product__c = product.Id
        );

        TestUtil.setupMDC(
                MDIMDCLogic.class,
                CMPL123CME__MEDDEV__c.getSObjectType(),
                CMPL123CME__MEDDEV__c.CMPL123_WF_Status__c
        );
    }
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test() {
        CMPL123CME__MEDDEV__c meddev = [SELECT CMPL123_WF_Status__c FROM CMPL123CME__MEDDEV__c LIMIT 1];

        Test.startTest();
        TicketQDNumMDCCustom.isTicketInquiry = true;
        meddev.CMPL123_WF_Status__c = 'Pending Final Review';
        TestDataFactory.updateSObject(meddev);
        Test.stopTest();

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c =: meddev.Id
                        AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);
    }
}