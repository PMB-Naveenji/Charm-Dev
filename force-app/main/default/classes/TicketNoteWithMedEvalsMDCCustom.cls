/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketNoteWithMedEvalsMDCCustom
* @Why   :Global class to check if Ticket Note record is created anf check if parent ticket has med eval
          child records, if yes trigger the MDC and create a MDC ticket.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:  
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description 
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    23-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    15-06-2020             Code Audit           Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketNoteWithMedEvalsMDCCustom implements CMPL123.IMDCCustomValidation {
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
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newTicketNote.Ticket__c);     
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;    
    }
}