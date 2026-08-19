/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketChangeQNCMDCCustom
* @Why   : Global class to check if ticket Additional Ticket Observations Comments field is changed to create the MDC trigger
           record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID         Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    27-MAR-2017            Work ID / Case ID       Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   DSkak                    04-06-2020             Code Audit              Removed 'System.debug()'.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    25-06-2020             Code Audit              Formatting. Removed commented code.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Oober                    30-JUL-2020            Defect #155/CHARM-2852  Added check if Ticket Inquiry.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues      Modified entry condition to execute MDC logic at beforeUpdate
*                                                                           event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketChangeQNCMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From Ticket Change for Adhoc Quality Non Complaint Observation Assignee Trigger
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c) oldRecord;

            if (newTicket.Additional_Ticket_Observations_Comments__c != oldTicket.Additional_Ticket_Observations_Comments__c) {
                //Defect #155 fix(added check if Ticket Inquiry)
                return TicketQDNumMDCCustom.isTicketInquiry == true;
            }
        }
        return false;
    }
}