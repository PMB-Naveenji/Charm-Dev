/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MDCTicketTrigger.
* @Why   : Handles all the customization involved on CMPL123__AcknowledgementMapping__c object.
* @When  : 28-DEC-2020.
* @Where : From CMPL123__AcknowledgementMapping__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger MDCAckMappingTrigger on CMPL123__AcknowledgementMapping__c (before insert) {
    if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) { return; }

    new MDCAckMappingTriggerHandler().run();
}