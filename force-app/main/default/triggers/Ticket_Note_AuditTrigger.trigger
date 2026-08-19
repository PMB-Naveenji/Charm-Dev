/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Ticket_Note_AuditTrigger
* @Why   : To Handles all the customization involved on Ticket_Note__c object.
* @When  : 07-FEB-2019  
* @Where : From Ticket_Note__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Ticket_Note_AuditTrigger on Ticket_Note__c (before insert, before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDTicketNoteTriggerhandler().run();
        if (Trigger.isAfter) {
            ReportsRelatedDataUtil.updateComplaintWithTicketNotesData(Trigger.old, Trigger.new);
        }
        System.debug(' After :Limit.getCpuTime() : '+Limits.getCpuTime());
        System.debug(' After :Limit.getLimitCpuTime() : '+Limits.getLimitCpuTime());  }
}