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
* Admin                    29-MAY-2019            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class AttachmnetsWithQNCMDCLogicTest {
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @IsTest
    private static void test () {
        AttachmnetsWithQNCMDCLogic controller = new AttachmnetsWithQNCMDCLogic();
        Attachment__c oldAttachment = new Attachment__c(Registartion_Attachment__c = 'asdf');
        Attachment__c newAttachment = new Attachment__c(Registartion_Attachment__c = 'hjkl');

        Test.startTest();
        TicketQDNumMDCCustom.isTicketInquiry = true;
        Boolean firstResult = controller.customValidation(oldAttachment, newAttachment);
        TicketQDNumMDCCustom.isTicketInquiry = false;
        Boolean secpndResult = controller.customValidation(oldAttachment, newAttachment);
        Test.stopTest();

        System.assertEquals(true, firstResult);
        System.assertEquals(false, secpndResult);
    }
}