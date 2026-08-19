/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : TicketCMSNEXTSRCOMPLAINTMDCCustom
 * @Why   : Global class to check if "CMSNext" field is changed check MDC Ticket record creation.
 * @When  : 05-JAN-2021
 * @Where : From Audit Class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    19-NOV-2017            Work ID / Case ID    Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                        event instead of after update. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             25-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class TicketCMSNEXTSRCOMPLAINTMDCCustom implements CMPL123.IMDCCustomValidation{
    /**
     * @Method       : customValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 25-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;

            //Added : W-000150
            TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            // 25-JAN-2023 Larry: Validation now uses hasActiveTicketSearch instead of hasTicketSearch
			return !TicketQDNumMDCCustom.isTicketInquiry
                    && TicketQDNumMDCCustom.hasActiveTicketSearch
                    && ((newComplaint.CMSNext__c == 'Open' && oldComplaint.CMSNext__c == 'Closed')
                    || (newComplaint.Reopen_Rationale__c != oldComplaint.Reopen_Rationale__c));
            /*return TicketQDNumMDCCustom.hasActiveTicketSearch
                    && ((newComplaint.CMSNext__c == 'Open' && oldComplaint.CMSNext__c == 'Closed')
                    || (newComplaint.Reopen_Rationale__c != oldComplaint.Reopen_Rationale__c));*/ // Fix for IPDR #403 added by Naveen on 5/14/2026.
        }
        return false;
    }
}