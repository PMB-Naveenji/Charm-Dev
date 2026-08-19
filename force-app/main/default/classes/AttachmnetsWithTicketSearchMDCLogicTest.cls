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
* Admin                    21-DEC-2018            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    13-JAN-2021            TWD Upgrade          TWD Upgrade issue related to MDCs generation. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* Nicholas D Sutanto       7-FEB-2023             CHaRM R3.0           Fixed test by initializing static variables to false instead of null.
* --------------------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class AttachmnetsWithTicketSearchMDCLogicTest {
    /**
    * @Method       : test
    * @Description  : Contains verification logic
    * @Return       : N/A
    * @Params       : N/A
    **/
    @isTest
    private static void customValidationTest () { 
        AttachmnetsWithTicketSearchMDCLogic objTicket = new AttachmnetsWithTicketSearchMDCLogic();

        // Added 7-FEB-2023: Initialized to false instead of leaving null
        TicketQDNumMDCCustom.hasActiveTicketSearch = false;
        TicketQDNumMDCCustom.isTicketInquiry = false;

        Attachment__c newAttachment = new Attachment__c(Registartion_Attachment__c = 'asdf');
        Attachment__c oldAttachment = new Attachment__c(Registartion_Attachment__c = 'hjkl');
        System.assertEquals(false, objTicket.CustomValidation(oldAttachment, newAttachment));
    }
}