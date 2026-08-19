/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Additional_Approval_AuditTrigger.
* @Why   : Handles all the customization involved on Additional_Approval__c object.
* @When  : 07-FEB-2019.
* @Where : From Additional_Approval__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    07-FEB-2019            Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    28-DEC-2020            TWD Upgrade issue                 Added 'before insert' event to trigger.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

trigger Additional_Approval_AuditTrigger on Additional_Approval__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update
) {
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c
            && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false) {
        new ADDAdditionalApprovalHandler().run();
    }
}