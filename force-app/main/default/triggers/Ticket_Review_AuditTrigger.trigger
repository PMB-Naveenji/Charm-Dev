/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Ticket_Review_AuditTrigger
* @Why   : To Handles all the customization involved on Ticket_Review__c object.
* @When  : 07-FEB-2019	
* @Where : From Ticket_Review__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			   07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Ticket_Review_AuditTrigger on Ticket_Review__c (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(System.UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDTicketReviewTriggerHandler().run();
    }
    
}