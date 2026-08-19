/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : MeanigfulDataQuestionMDC
* @Why   : Global class to check if "Meaningful Data Question" is changed in Meanigful Data object
            and has prodEval record in ticket to check the MDC trigger record creations.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    11-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class MeanigfulDataQuestionMDC implements CMPL123.IMDCCustomValidation {
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
            Meaningful_Data__c newMeaningfulData = (Meaningful_Data__c) newRecord;
            Meaningful_Data__c oldMeaningfulData = (Meaningful_Data__c) oldRecord;

            if (newMeaningfulData.Mean__c != oldMeaningfulData.Mean__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newMeaningfulData.Compliant__c);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return null;
    }
}