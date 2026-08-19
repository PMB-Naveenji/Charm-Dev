/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : CMPL123_Product_AuditTrigger
* @Why   : To Handles all the customization involved on CMPL123__Product__c object.
* @When  : 07-FEB-2019  
* @Where : From CMPL123__Product__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    07-FEB-2019            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger CMPL123_Product_AuditTrigger on CMPL123__Product__c (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        //if(Trigger.size == 1) {}  // 23MAY19 - Added condition to avoid 101 SOQL error in TODS Integration
        new ADDProductTriggerhandler().run();
            
    }
}