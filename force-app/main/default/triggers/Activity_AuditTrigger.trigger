/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Activity_AuditTrigger
* @Why   : To Handles all the customization involved on     Activity__c object.
* @When  : 13-FEB-2019  
* @Where : From     Activity__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    13-FEB-2019            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    29-DEC-2020            TWD Updgrade issue   Added before insert event.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Activity_AuditTrigger on Activity__c (before insert, before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDCustomActivityTriggerhandler().run();
    }

}