/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Product_Ticket_AuditTrigger
* @Why   : To Handles all the customization involved on Product_Ticket__c object.
* @When  : 07-FEB-2019  
* @Where : From Product_Ticket__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Product_Ticket_AuditTrigger on Product_Ticket__c (before insert, before update,before delete,after insert,after update,after delete){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDProductTicketTriggerHandler().run();
        if (Trigger.isAfter) {
            ReportsRelatedDataUtil.updateComplaintWithRegisteredSiteNames(Trigger.old, Trigger.new);
        }
    }
    
}