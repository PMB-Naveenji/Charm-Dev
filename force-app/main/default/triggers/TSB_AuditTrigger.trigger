/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : TSB_AuditTrigger
* @Why   : To Handles all the customization involved on TSB__c object.
* @When  : 07-FEB-2019  
* @Where : From TSB__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger TSB_AuditTrigger on TSB__c (before update, before delete, after insert, after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDTSBTriggerhandler().run();
    }       
}