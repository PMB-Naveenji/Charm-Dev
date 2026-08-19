/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : RMF_AuditTrigger
* @Why   : To Handles all the customization involved on RMF__c object.
* @When  : 07-FEB-2019
* @Where : From RMF__c object Events
--------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    07-FEB-2019            Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                    12-MAY-2020            Defect #96 (CHARM-2507)    Modified (Audit trail code added on beforeUpdate)
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger RMF_AuditTrigger on RMF__c (before update,before delete,after insert,after update){
    
    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c && ADDS4RiskManagementTriggerHandler.stopRecursionForClonedRecord == false){
        if(Trigger.isInsert && Trigger.isBefore){
            // Place your code. 
        }
        /* After Insert */
        else if(Trigger.isInsert && Trigger.isAfter){
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Update */
        else if(Trigger.isUpdate && Trigger.isBefore){
            //Defect #96 (CHARM-2507) start. Fields should be tracked in before Update
            CMPL123.AuditHandler.handleAudit();
            //Defect #96 (CHARM-2507) end
        }
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            CMPL123.AuditHandler.handleAudit();
        }
        /* Before Delete */
        else if(Trigger.isDelete && Trigger.isBefore){
            RMF_AuditTriggerHandler.beforeDelete(Trigger.old);
            CMPL123.AuditHandler.handleAudit();
         }
        /* After Delete */
        else if(Trigger.isDelete && Trigger.isAfter){
            // Place your code. 
        }
    }
    
}