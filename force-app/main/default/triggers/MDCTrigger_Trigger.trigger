/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : MDCTrigger_Trigger.
* @Why   : Handles all the customization involved on CMPL123__MDC_Trigger__c object.
* @When  : 28-DEC-2020.
* @Where : From CMPL123__MDC_Trigger__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger MDCTrigger_Trigger on CMPL123__MDC_Trigger__c (before insert, before update) {
    if (ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) { return; }

    new MDCTrigger_TriggerHandler().run();
}