/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : NoteTrigger
* @Why   : To Handles all the customization involved on Note object.
* @When  : 12-JUNE-2019 
* @Where : From Note object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    12-JUNE-2019           Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger NoteTrigger on Note (before insert, before update) {
    if (!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDNoteTriggerHandler().run();
    }
}