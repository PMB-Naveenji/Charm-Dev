/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : CMPL123CME_Registered_Site_AuditTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__Registered_Site__c object.
* @When  : 07-FEB-2019  
* @Where : From     CMPL123CME__Registered_Site__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger CMPL123CME_Registered_Site_AuditTrigger on CMPL123CME__Registered_Site__c (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDRegisterSiteTriggerhandler().run();
    }
}