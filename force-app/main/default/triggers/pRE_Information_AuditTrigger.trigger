/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : pRE_Information_AuditTrigger
* @Why   : To Handles all the customization involved on pRE_Information__c object.
* @When  : 07-FEB-2019  
* @Where : From pRE_Information__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger pRE_Information_AuditTrigger on pRE_Information__c (before insert,before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDpREInformationTriggerHandler().run();
    }
}