/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : ConcomitantProductTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__Concomitant_Product__c object.
* @When  : 07-FEB-2019	
* @Where : From 	CMPL123CME__Concomitant_Product__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin    			    07-FEB-2019			    Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger ConcomitantProductTrigger on CMPL123CME__Concomitant_Product__c (before insert, before update, after insert, after delete, after update) {
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                ConcomitantProductTriggerHandler.beforeInsertEventhandler();    
            } 
            if(Trigger.isUpdate){
                ConcomitantProductTriggerHandler.beforeUpdateEventHandler();    
            } 
        }
        
        if(Trigger.isAfter){
            
            if(Trigger.isInsert){
                ConcomitantProductTriggerHandler.afterInsertEventHandler();    
            }
            
            if(Trigger.isDelete){
                ConcomitantProductTriggerHandler.afterDeleteEventHandler();
            }
            
            ReportsRelatedDataUtil.updateEmdrWithConcomitantProductsData(Trigger.old, Trigger.new);
        }
        
    }
    
}