/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : TicketQDNWithTicketSearchesMDCCustom
 * @Why   : Global class to check if ticket QD Number field is changed to check the MDC trigger
            record creation when ticket has ticket version child records.
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
 *   Larry Resnik             12-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class TicketQDNWithTicketSearchesMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
     * @Method       : customValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 12-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation. Defined isDefaultsAssigned to
     * clarify what why hasTicketSearch is being checked against null.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (newTicket.Quality_Directive_Number__c != oldTicket.Quality_Directive_Number__c) {
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                if (!isDefaultsAssigned) {
                    TicketQDNumMDCCustom.setDefaults(newTicket.Id);
                    isDefaultsAssigned = true;
                }
                // 12-JAN-2023 Larry: Validation now uses hasActiveTicketSearch and isDefaultsAssigned
                // instead of hasTicketSearch for both
                return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch && !TicketQDNumMDCCustom.isTicketInquiry;
            }
        }
        return false;
    }
}