/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021 Sparta Systems, Inc.
* @What  : PTWithMedEvalLikelyCauseMDCCustom
* @Why   : Global class to check if Product-Ticket Batch/Lot/Serial# field is changed and create the MDC ticket
           record for that change, only when ticket has medical evaluation child records.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    11-JAN-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit           Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PTWithMedEvalLikelyCauseMDCCustom implements CMPL123.IMDCCustomValidation {

    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord){
        // Changed the code for 860,61 & 62
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TicketUtil.addTrace('PTWithMedEvalLikelyCauseMDCCustom');
            //TWD Upgrade fix END
            Product_Ticket__c newProductTicket = (Product_Ticket__c)newRecord ;
            Product_Ticket__c oldProductTicket = (Product_Ticket__c)oldRecord;

            if (newProductTicket.Likely_Cause__c != null && oldProductTicket.Likely_Cause__c != null
                && newProductTicket.Likely_Cause__c != oldProductTicket.Likely_Cause__c) {
                if (TicketQDNumMDCCustom.hasMedEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                }
                return TicketQDNumMDCCustom.hasMedEval != null && TicketQDNumMDCCustom.hasMedEval;
            }
        }
        return false;
    }
}