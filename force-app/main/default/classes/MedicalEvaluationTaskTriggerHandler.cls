/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MedicalEvaluationTaskTriggerHandler.
* @Why   : Medical Evaluation Task TriggerHandler.
* @When  : 06-APR-2017.
* @Where : From MedicalEvaluationTaskTriggerHandler.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                    06-APR-2017            Work ID / Case ID    Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                    21-AUG-2020            Code Audit           Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

public class MedicalEvaluationTaskTriggerHandler {

    /*
    * @Method       : afterEventHandler.
    * @Invoke       : Events from afterEventHandler.
    * @Description  : To handle after Event Handler.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    public static void afterEventHandler(){
        List<Medical_Evaluation_Task__c> newMedTask = (List<Medical_Evaluation_Task__c>) (Trigger.isDelete ? Trigger.Old : Trigger.New) ;
        List<Medical_Evaluation_Task__c> newMedTaskCompleted = new List<Medical_Evaluation_Task__c> ();
        Id medTaskRecTypeId = Schema.SObjectType.Medical_Evaluation_Task__c.getRecordTypeInfosByName().get('RCML Review Task').getRecordTypeId();
        for(Medical_Evaluation_Task__c medTask: newMedTask){
            if(medTask.CMPL123_WF_Action__c == 'Complete' && medTask.RecordTypeId == medTaskRecTypeId ){
                newMedTaskCompleted.add(medTask);
            }
        }
        if(newMedTaskCompleted != null && newMedTaskCompleted.size()>0){
            UpdateProductReportableFields prodUpdate = new updateProductReportableFields();
            prodUpdate.updateFields(newMedTaskCompleted);
            prodUpdate.validationRuleCheck(newMedTaskCompleted);
        }
    }
}