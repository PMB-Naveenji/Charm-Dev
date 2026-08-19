/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : PTWithTktSearcheBatchLotNumberMDCCustom
 * @Why   : Global class to check if Product-Ticket Batch/Lot/Serial# field is changed and create the MDC ticket
            record for that change, only when ticket has ticket searches child records.
 * @When  : 05-JAN-2021
 * @Where : From Audit Class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID      Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    11-Jan-2017            Work ID / Case ID    Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                        event instead of after update. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             27-JAN-2023            CHaRM R3.0, IPDR 411 Replace some hasTicketSearch references with the new hasActiveTicketSearch
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class PTWithTktSearcheBatchLotNumberMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
     * @Method       : CustomValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : 27-JAN-2023 Larry: Replaced hasTicketSearch with 
     * hasActiveTicketSearch for the validation. Defined isDefaultsAssigned to
     * clarify what why hasTicketSearch is being checked against null.
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord){
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Product_Ticket__c newProductTicket = (Product_Ticket__c) newRecord;
            Product_Ticket__c oldProductTicket = (Product_Ticket__c) oldRecord;
            system.debug('3 ::::::::::::::::::::::::::::::::::::::;');
            if (newProductTicket.Batch_Lot_Serial__c != oldProductTicket.Batch_Lot_Serial__c) {
                Boolean isDefaultsAssigned = TicketQDNumMDCCustom.hasTicketSearch != null;
                if (!isDefaultsAssigned) {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                    isDefaultsAssigned = true;
                }
                // 27-JAN-2023 Larry: Validation now uses hasActiveTicketSearch and isDefaultsAssigned
                // instead of hasTicketSearch for both
                //return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch && !TicketQDNumMDCCustom.isTicketInquiry;
                return isDefaultsAssigned && TicketQDNumMDCCustom.hasActiveTicketSearch;
            }
        }
        return false;
    }
}