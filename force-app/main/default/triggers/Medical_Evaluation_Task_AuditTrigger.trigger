/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2019  Sparta Systems, Inc.
* @What  : Medical_Evaluation_Task_AuditTrigger
* @Why   : To Handles all the customization involved on Medical_Evaluation_Task__c object.
* @When  : 07-FEB-2019  
* @Where : From Medical_Evaluation_Task__c object Events
 --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                   07-FEB-2019             Work ID / Case ID    Created.
*   rsitc                   09-June-2020            #123/CHARM-2729      Refactored parent Med Eval Last Modofied Date updating.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
trigger Medical_Evaluation_Task_AuditTrigger on Medical_Evaluation_Task__c (before insert,before update,before delete,after insert,after update){

    if(!ADD_App_Settings__c.getInstance(UserInfo.getUserId()).Restrict_Triggers__c) {
        new ADDMedEvalTaskTriggerHandler().run();
        
        //MedicalEvaluationTaskTriggerHandler.afterEventHandler();
        
        /* After Insert */
        if(Trigger.isInsert && Trigger.isAfter){
            // #123/CHARM-2729: update parent Med Eval Last Modofied Date  
            ADDMedEvalTaskTriggerHandler.updateMedEvalLastModifiedDate();
        }
        
        /* After Update */
        else if(Trigger.isUpdate && Trigger.isAfter){
            // #123/CHARM-2729: update parent Med Eval Last Modofied Date  
            ADDMedEvalTaskTriggerHandler.updateMedEvalLastModifiedDate();
        }                
    }
}