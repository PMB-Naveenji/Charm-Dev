/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : FeedItem_AuditTrigger
* @Why   : To Handles all the customization involved on FeedItem object.
* @When  : 07-FEB-2019	
* @Where : From FeedItem object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			    07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger FeedItem_AuditTrigger on FeedItem (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        
        if(Trigger.isInsert && Trigger.isBefore){
            // Place your code. 
        }
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore){
        }
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore){
            CMPL123.AuditHandler.handleAudit();
        }
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter){
            // Place your code. 
        }
        
    }
    
}