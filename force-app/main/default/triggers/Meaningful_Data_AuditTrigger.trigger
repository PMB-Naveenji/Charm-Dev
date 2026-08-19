/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Meaningful_Data_AuditTrigger
* @Why   : To Handles all the customization involved on Meaningful_Data__c object.
* @When  : 07-FEB-2019  
* @Where : From Meaningful_Data__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Meaningful_Data_AuditTrigger on Meaningful_Data__c (before insert,before update,before delete,after insert,after update,after delete){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDMeaningfulDataTriggerHandler().run();
    }   
}