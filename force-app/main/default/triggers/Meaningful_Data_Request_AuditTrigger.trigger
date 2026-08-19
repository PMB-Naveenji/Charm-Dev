/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Meaningful_Data_Request_AuditTrigger
* @Why   : To Handles all the customization involved on Meaningful_Data_Request__c object.
* @When  : 07-FEB-2019  
* @Where : From Meaningful_Data_Request__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Meaningful_Data_Request_AuditTrigger on Meaningful_Data_Request__c (before insert, 
    before update, before delete, after insert, after update) {

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDMDRequestTriggerHandler().run();
    } 
}