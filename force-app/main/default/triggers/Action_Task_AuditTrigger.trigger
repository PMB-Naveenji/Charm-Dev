/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ADDActionTaskTriggerhandler
* @Why   : To Handles all the customization involved on 	Action_Task__c object.
* @When  : 13-FEB-2019	
* @Where : From 	Action_Task__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			     13-FEB-2019		    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Action_Task_AuditTrigger on Action_Task__c (before insert,before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false) {
        new ADDActionTaskTriggerhandler().run();
    }

}