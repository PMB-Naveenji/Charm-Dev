/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketNoteTicketNoteAddedMDCCustom
* @Why   : Global class to check if "Ticket Note Added" field is changed in Ticket Note
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    09-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketNoteTicketNoteAddedMDCCustom implements CMPL123.IMDCCustomValidation{
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
            Ticket_Note__c newTicketNote = (Ticket_Note__c) newRecord;
            Ticket_Note__c oldTicketNote = (Ticket_Note__c) oldRecord;

            if (newTicketNote.Ticket_Note_Added__c != oldTicketNote.Ticket_Note_Added__c) {
                TicketQDNumMDCCustom.setDefaults(newTicketNote.Ticket__c);
                return TicketQDNumMDCCustom.inquiryTT != null && TicketQDNumMDCCustom.inquiryTT;
            }
        }
        return false;
    }
}