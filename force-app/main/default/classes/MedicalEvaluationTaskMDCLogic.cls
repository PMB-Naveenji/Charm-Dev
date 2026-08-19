/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithTckMedEvalMDCCustom
* @Why   : Global class to check if medical evaluation task record workfloe is changed, and if yes then
           create the MDC trigger for that change.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    18-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Removed commented code. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class MedicalEvaluationTaskMDCLogic implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            //Modified the above lines because of a security issue. "AvoidDirectAccessTriggerMap"
            //FYI : https://pmd.github.io/pmd/pmd_rules_apex_errorprone.html#avoiddirectaccesstriggermap
            Medical_Evaluation_Task__c newMedEvalTasks, oldMedEvalTasks;
            newMedEvalTasks = (Medical_Evaluation_Task__c) newRecord;
            oldMedEvalTasks = (Medical_Evaluation_Task__c) oldRecord;

            if (newMedEvalTasks.CMPL123_WF_Status__c == 'Closed-Done'
                && newMedEvalTasks.CMPL123_WF_Status__c != oldMedEvalTasks.CMPL123_WF_Status__c) {
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newMedEvalTasks.Parent_Ticket_Id__c);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}