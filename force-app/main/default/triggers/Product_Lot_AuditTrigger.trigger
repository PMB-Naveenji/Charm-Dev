/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Product_Lot_AuditTrigger
* @Why   : To Handles all the customization involved on Product_Lot__c object.
* @When  : 07-FEB-2019  
* @Where : From Product_Lot__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*   rsitc                   09-June-2020            #123/CHARM-2729      Adjusted parents Last Modified Date updating.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Product_Lot_AuditTrigger on Product_Lot__c (before insert,before update,before delete,after insert,after update,after delete){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        TicketUtil.addTrace('Product_Lot_AuditTrigger');
        new ADDProductLotTriggerHandler().run();
        
        /* After Insert */
        if(Trigger.isInsert && Trigger.isAfter){
            // #123/CHARM-2729: update parents Last Modified Date
            ADDProductLotTriggerHandler.updateProductTicketsAndInvestigations();
        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            // #123/CHARM-2729: update parents Last Modified Date
            ADDProductLotTriggerHandler.updateProductTicketsAndInvestigations();
        }
               
    }    
}