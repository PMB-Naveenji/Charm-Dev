/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : pRE_Question_AuditTrigger
* @Why   : To Handles all the customization involved on pRE_Question__c object.
* @When  : 07-FEB-2019  
* @Where : From pRE_Question__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   10-JUN-2020            #96.1 (CHARM-2842)    Updated. Removed wrong condition from trigger.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger pRE_Question_AuditTrigger on pRE_Question__c (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('pRE_Question_AuditTrigger');
        //#96.1 (CHARM-2842) start. This condition should not be here: if(Trigger.isUpdate)
        //#96.1 (CHARM-2842) end.
        new ADDpREQuestionTriggerHandler().run();
    }
}