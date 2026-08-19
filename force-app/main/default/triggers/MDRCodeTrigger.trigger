/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : MDRCodeTrigger
* @Why   : To Handles all the customization involved on CMPL123CME__MDR_Code__c object.
* @When  : 07-FEB-2019  
* @Where : From CMPL123CME__MDR_Code__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID             Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID           Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   rsitc                   05-22-2020              Defect #123/CHARM-2729      Added MDRCodeTriggerHandler.isAfterUpdate() call                                                                           
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger MDRCodeTrigger on CMPL123CME__MDR_Code__c (after insert, after update, after delete) {
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                MDRCodeTriggerHandler.isAfterInsert();
            }
            
            if(Trigger.isDelete){
                MDRCodeTriggerHandler.isAfterDelete();
            }
            
            if(Trigger.isUpdate){
                // Defect #123/CHARM-2729: Added method call to update parent EMDR LastModifiedDate
                MDRCodeTriggerHandler.isAfterUpdate();
            }
        }      
    }
}