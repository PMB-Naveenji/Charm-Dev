/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDS3LeveragedTaskListControllerHelper.
* @Why   : Handles to delete Source tasks that are related to Evaluation/Investigation.
* @When  : 20-AUG-2018.
* @Where : From ADDS3LeveragedTaskListController class .
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID           Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin  				   20-AUG-2018			  Work ID / Case ID         Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                    04-JUN-2020            Code Audit                Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                    15-JUN-2020            Code Audit                Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                    12-AUG-2020            Code Audit                Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class ADDS3LeveragedTaskListControllerHelper {
    /*
    * @Method       : deleteTasks.
    * @Description  : To delete Source tasks that are related to Evaluation/Investigation.
    * @Invoke		: From ADDS3LeveragedTaskListController class.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public  static void deleteTasks(String disconnectedId){
        if(disconnectedId != null && disconnectedId != ''){
            List<Id> taskIdSet = disconnectedId.split(';');
            List<Task_Product_Evaluation_Investigation__c> lstTaskProductEvaluationInvestigationsToDelete = New List<Task_Product_Evaluation_Investigation__c>();
            List<Task__c> lstTasksToDelete = New List<Task__c>();
            // get all selected records
            for(Task_Product_Evaluation_Investigation__c objTaskProductEvaluationInvestigation : [SELECT Id,Task__c FROM Task_Product_Evaluation_Investigation__c WHERE Id IN: taskIdSet]){
                lstTaskProductEvaluationInvestigationsToDelete.add(objTaskProductEvaluationInvestigation);
                lstTasksToDelete.add(New Task__c(Id = objTaskProductEvaluationInvestigation.Task__c));
            }

            //delete junction object
            if(lstTaskProductEvaluationInvestigationsToDelete.size() > 0){
                delete lstTaskProductEvaluationInvestigationsToDelete;
            }
            //delete task object
            if(lstTasksToDelete.size() > 0){
                // delete tasks
                delete lstTasksToDelete;
            }
        }
    }
}