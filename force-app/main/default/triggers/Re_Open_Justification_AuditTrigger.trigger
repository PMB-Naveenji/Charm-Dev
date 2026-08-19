/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Re_Open_Justification_AuditTrigger
* @Why   : To Handles all the customization involved on Re_Open_Justification__c object.
* @When  : 07-JUL-2019	
* @Where : From Re_Open_Justification__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			   07-JUL-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan    			   05-JAN-2021			    TWD Upgrade issue    Added before insert event.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Re_Open_Justification_AuditTrigger on Re_Open_Justification__c (before insert, before update,before delete,after insert,after update){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDReopenJustificationTriggerHandler().run();
    }
}