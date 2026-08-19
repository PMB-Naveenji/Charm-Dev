/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : TicketNoteWithTickteSearchesMDCCustom
 * @Why   : Global class to check if Ticket Note record is created and check if parent ticket has active Ticket Search
            child records. If yes, create an MDC ticket.
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
 *   Larry Resnik             31-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class TicketNoteWithTickteSearchesMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
     * @Method       : customValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 31-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation. Defined isDefaultsAssigned to
     * clarify what why hasTicketSearch is being checked against null.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Ticket_Note__c newTicketNote = (Ticket_Note__c) newRecord;
            Ticket_Note__c oldTicketNote = (Ticket_Note__c) oldRecord;

            if (newTicketNote.Ticket_Note_Added__c != oldTicketNote.Ticket_Note_Added__c) {
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                if (!isDefaultsAssigned) {
                    TicketQDNumMDCCustom.setDefaults(newTicketNote.Ticket__c);
                    isDefaultsAssigned = true;
                }
                // 31-JAN-2023 Larry: Validation now uses hasActiveTicketSearch and isDefaultsAssigned
                // instead of hasTicketSearch for both
                return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch && !TicketQDNumMDCCustom.isTicketInquiry;
            }
        }
        return false;
    }
}