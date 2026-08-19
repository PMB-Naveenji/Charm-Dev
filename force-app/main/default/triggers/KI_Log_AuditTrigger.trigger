/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : KI_Log_AuditTrigger
* @Why   : To Handles all the customization involved on KI_Log__c object.
* @When  : 07-FEB-2019	
* @Where : From KI_Log__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			    07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger KI_Log_AuditTrigger on KI_Log__c (before insert,before update,before delete,after insert,after update,after delete){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('KI_Log_AuditTrigger');
        new ADDKILogTriggerHandler().run();
    }
    
}