/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : TicketCMSNEXTSRCOMPLMDCCustom
* @Why   : Global class to check if "CMSNext" field is changed check MDC Ticket record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    19-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketCMSNEXTSRCOMPLMDCCustom implements CMPL123.IMDCCustomValidation{
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
            system.debug('TicketQDNumMDCCustom.hasProdEval----->'+TicketQDNumMDCCustom.hasProdEval);
            system.debug('TicketQDNumMDCCustom.isTicketInquiry1----->'+TicketQDNumMDCCustom.isTicketInquiry);

            //Added : W-000150
            if (TicketQDNumMDCCustom.hasProdEval == null || TicketQDNumMDCCustom.isTicketInquiry == null) {
                TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            }
            system.debug('TicketQDNumMDCCustom.isTicketInquiry2----->'+TicketQDNumMDCCustom.isTicketInquiry);
            system.debug('TicketQDNumMDCCustom.hasProdEval----->'+TicketQDNumMDCCustom.hasProdEval);
            system.debug('newComplaint.CMSNext__c----->'+newComplaint.CMSNext__c);
            system.debug('oldComplaint.CMSNext__c----->'+oldComplaint.CMSNext__c);
            system.debug('newComplaint.Reopen_Rationale__c----->'+newComplaint.Reopen_Rationale__c);
            system.debug('oldComplaint.Reopen_Rationale__c----->'+oldComplaint.Reopen_Rationale__c);
            return TicketQDNumMDCCustom.isTicketInquiry == false && TicketQDNumMDCCustom.hasProdEval == true
                    && ((newComplaint.CMSNext__c == 'Open' && oldComplaint.CMSNext__c == 'Closed')
                    || (newComplaint.Reopen_Rationale__c != oldComplaint.Reopen_Rationale__c));
        }
        return false;
    }
}