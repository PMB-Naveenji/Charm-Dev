/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Task_AuditTrigger
* @Why   : To Handles all the customization involved on Task__c object.
* @When  : 07-FEB-2019
* @Where : From Task__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                  07-FEB-2019              Work ID / Case ID    Created.
*   rsitc                  09-JUNE-2020             #123/CHARM-2729      Modified parent Investigation's LastModifiedDate updating.
*   rsitc                  22-DEC-2020              Upgrade issue #41    Added isDemotedOrPromoted flag logic.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

trigger Task_AuditTrigger on Task__c (before insert,before update,before delete,after insert,after update){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDInvestigationTaskTriggerHandler().run();
        
        /* After Insert */
        if(Trigger.isInsert && Trigger.isAfter && !ADDDemoteToServiceHandler.isDemotedOrPromoted){
            // #123/CHARM-2729: update parent Investigation LastModifiedDate
            ADDInvestigationTaskTriggerHandler.updateInvestigationLastModifiedDate();
        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter && !ADDDemoteToServiceHandler.isDemotedOrPromoted){
            // #123/CHARM-2729: update parent Investigation LastModifiedDate
            ADDInvestigationTaskTriggerHandler.updateInvestigationLastModifiedDate();
        }
    } 
}