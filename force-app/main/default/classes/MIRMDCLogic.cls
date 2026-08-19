/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) Capgemini.
* @What  : MIRMDCLogic
* @Why   : Global class to check if MIR record workflow is changed, and if yes then create the MDC trigger for that changes.
* @When  : 30-AUG-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Lakshman                 30-AUG-2021            MIR Project          Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class MIRMDCLogic implements CMPL123.IMDCCustomValidation {
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
            CMPL123CME__EU_MIR__c newMIRs = (CMPL123CME__EU_MIR__c)newRecord;
            CMPL123CME__EU_MIR__c oldMIRs = (CMPL123CME__EU_MIR__c)oldRecord;

            if (newMIRs.CMPL123_WF_Status__c == 'Pending Final Review' && newMIRs.CMPL123_WF_Status__c != oldMIRs.CMPL123_WF_Status__c) {
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newMIRs.CMPL123CME__Complaint__c);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}