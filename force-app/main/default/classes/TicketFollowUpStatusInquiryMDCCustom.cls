/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketFollowUpStatusInquiryMDCCustom
* @Why   : Global class to check if "Follow-Up Status" field is changed and has prodEval record to
           check MDC Ticket record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    03-NOV-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketFollowUpStatusInquiryMDCCustom implements CMPL123.IMDCCustomValidation{
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
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;

            //Added : W-000150
            TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            return TicketQDNumMDCCustom.inquiryTT == true
                    && newComplaint.Follow_up_Status__c != oldComplaint.Follow_up_Status__c
                    && ((oldComplaint.Follow_up_Status__c == 'Further Review' && newComplaint.Follow_up_Status__c == 'Complete')
                    || (oldComplaint.Follow_up_Status__c == 'Responded' && newComplaint.Follow_up_Status__c == 'Further Review')
                    || (oldComplaint.Follow_up_Status__c == 'Complete' && newComplaint.Follow_up_Status__c == 'Further Review'));
        }
        return false;
    }
}