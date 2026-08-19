/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithProdEvalMDCCustom
* @Why   : Global class to check if Transaltion task is completed and it's parent ticket has medical evaluation
*          child record and if yes then create the MDC ticket records.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    25-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TranslationTaskWithProdEvalMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : customValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/ 
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TicketUtil.addTrace('TranslationTaskWithProdEvalMDCCustom');
            //TWD Upgrade fix END
            Translation_Task__c newTranslationTask = (Translation_Task__c) newRecord;
            Translation_Task__c oldTranslationTask = (Translation_Task__c) oldRecord;
            
            if (newTranslationTask.CMPL123_WF_Status__c != oldTranslationTask.CMPL123_WF_Status__c 
                && newTranslationTask.CMPL123_WF_Status__c == 'Closed-Done') {
                    if (TicketQDNumMDCCustom.isInprocessTranslationTask == null) {
                        TicketQDNumMDCCustom.setDefaults(newTranslationTask.Parent_Ticket__c);            
                    }
                    return TicketQDNumMDCCustom.isInprocessTranslationTask != null && TicketQDNumMDCCustom.isInprocessTranslationTask;
               }
        }
        return false;    
    }
}