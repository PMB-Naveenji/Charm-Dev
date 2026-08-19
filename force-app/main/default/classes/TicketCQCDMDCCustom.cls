/**
 *  --------------------------------------------------------------------------------------------------------------------------------------
 * @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
 * @What  : TicketCQCDMDCCustom
 * @Why   : Controls the creation of a Meaningful Data Change (MDC) if a
 * Ticket's "Complaint Quality Closure Date" is changed to a non-null value.
 * @When  : 05-JAN-2021
 * @Where : From Audit Class
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID       Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    09-Jan-2017            Work ID / Case ID     Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   DSkak                    04-06-2020             Code Audit            Removed 'System.debug()'.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    15-06-2020             Code Audit            Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                         event instead of after update. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Larry Resnik             05-JAN-2023            CHaRM R3.1, IPDR 299  MDC will now be created even if the ProdEval 
 * child goes to "Closed-Done" WorkFlow Status with code 80064 or 80067 instead of just 80067.
 * Reworded @Why in this docstring for clarity.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 **/
global class TicketCQCDMDCCustom implements CMPL123.IMDCCustomValidation {

    /**
     * @Method       : customValidation
     * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
     * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
     * @Return       : Boolean
     * @Params       : Trigger Context
     * @Revision     : R3.1, Larry: Most logic now offloaded to the helper class.
     * Notably, (hasReportableMedEval == false) now replaces
     * the meaningless (isMedEvalNotReportable == true || isMedEvalNotReportable == false)
     **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (newTicket.Complaint_Quality_Closure_Date__c != null &&
                newTicket.Complaint_Quality_Closure_Date__c != oldTicket.Complaint_Quality_Closure_Date__c
            ) {
                ComplaintQualityClosureDateMDCCustom.setDefaults(newTicket.Id);
                return ComplaintQualityClosureDateMDCCustom.isMeetingAnyCase;
            }
        }
        return false;
    }
}