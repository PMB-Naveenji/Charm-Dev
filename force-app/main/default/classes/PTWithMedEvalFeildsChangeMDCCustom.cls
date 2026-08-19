/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTWithMedEvalFeildsChangeMDCCustom
* @Why   : Global class to check if Product-Ticket Batch/Lot/Serial#,List Number and Likely Cause
           fields are changed and if yes create the MDC trigger record.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    16-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    20-May-2020            #115 / CHARM-2665    Removed condition to check if Likely_Cause__c has different values in new/old records.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PTWithMedEvalFeildsChangeMDCCustom implements CMPL123.IMDCCustomValidation {
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
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;

            //Defect #115 / CHARM-2665 fix start
            if (oldComplaint.Product_Ticket_Added__c != null && newComplaint.Product_Ticket_Added__c != oldComplaint.Product_Ticket_Added__c) {
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }

        return false;
    }
}