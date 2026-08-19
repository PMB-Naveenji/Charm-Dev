/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Customer_Response_Master_AuditTrigger.
* @Why   : Handles all the customization involved on Customer_Response_Master__c object.
* @When  : 07-FEB-2019.
* @Where : From Customer_Response_Master__c object Events.
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

trigger Customer_Response_Master_AuditTrigger on Customer_Response_Master__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update
) {
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('Customer_Response_Master_AuditTrigger');

        new ADDCustomerResponseMasterHandler().run();
    }
}