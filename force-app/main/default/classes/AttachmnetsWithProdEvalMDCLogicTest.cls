/**
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : Test class
* @Why   : Handles all the customization involved on custom MDC Ticket object
* @When  : 13-JAN-2021
* @Where : From Audit Class
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    14-JUN-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class AttachmnetsWithProdEvalMDCLogicTest {
    /**
    * @Method       : setup
    * @Description  : Create records needed in test method(s)
    * @Return       : N/A
    * @Params       : N/A
    **/
    @TestSetup
    private static void setup() {
        insert new Attachment__c(
                Name = 'TranslationTaskAttachment',
                Attachment_Type__c = 'Registration',
                Registartion_Attachment__c = 'Old'
        );

        TestUtil.setupMDC(
                AttachmnetsWithProdEvalMDCLogic.class,
                Attachment__c.getSObjectType(),
                Attachment__c.Registartion_Attachment__c
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
        Attachment__c attachment = [SELECT Registartion_Attachment__c FROM Attachment__c LIMIT 1];

        Test.startTest();
        TicketQDNumMDCCustom.isTicketInquiry = true;
        attachment.Registartion_Attachment__c = 'New';
        TestDataFactory.updateSObject(attachment);
        Test.stopTest();

        System.assertEquals('Update', [
                SELECT CMPL123__Action__c
                FROM CMPL123__Audit_Trail_Entry__c
                WHERE CMPL123__ParentId__c =: attachment.Id
                        AND CMPL123__Action__c = 'Update'].CMPL123__Action__c);
    }
}