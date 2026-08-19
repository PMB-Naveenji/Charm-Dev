/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TktPEAdhocEvaluatorMDCCustom
* @Why   : Global class to check if Ticket Ad hoc Medical Evaluator MDC field is changed and if yes and
           ticket has prod eval child records, then create MDC trigger record.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    24-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/

global class TktPEAdhocEvaluatorMDCCustom implements CMPL123.IMDCCustomValidation {
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
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (newTicket.Ad_hoc_Evaluator_Investigator_MDC__c != oldTicket.Ad_hoc_Evaluator_Investigator_MDC__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newTicket.Id);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}