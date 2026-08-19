/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Trend_Item_Maintenance_Product_AuditTrigger
* @Why   : To Handles all the customization involved on Trend_Item_Maintenance_Product__c object.
* @When  : 07-FEB-2019  
* @Where : From Trend_Item_Maintenance_Product__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID            Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   oivan                   13-MAY-2020             Defect #96 (CHARM-2507)    Updated. Added audit trail code on BeforeUpdate
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                   15-06-2020              Code Audit                 Updated Jira reference with reference from Defect Tracker. 
*                                                                              Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Trend_Item_Maintenance_Product_AuditTrigger on Trend_Item_Maintenance_Product__c (before update,before delete,after insert,after update,after delete){

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
            //Defect #96 (CHARM-2507) start. Added audit on before Update
            CMPL123.AuditHandler.handleAudit();
            //Defect #96 (CHARM-2507) end.

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