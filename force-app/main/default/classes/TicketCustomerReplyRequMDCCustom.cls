/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketCustomerReplyRequestMDCCustom
* @Why   : Global class to check if Customer Reply Requested? field is changed in ticket and has prodEval record
*          to check MDC Ticket record creation
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    15-NOV-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketCustomerReplyRequMDCCustom implements CMPL123.IMDCCustomValidation{
    /**
    * @Method       : customValidation
    * @Invoke       : Events from CustomValidation
    * @Description  : To Custom Validation
    * @Return       : N/A
    * @Params       : N/A
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            //CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) Trigger.new[0];
            //CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) Trigger.old[0];

            CMPL123CME__Complaint__c newComplaint,oldComplaint;
            for (CMPL123CME__Complaint__c cmpl : (List<CMPL123CME__Complaint__c>) Trigger.new) {
                newComplaint = cmpl;
                break;
            }
            for (CMPL123CME__Complaint__c cmpl : (List<CMPL123CME__Complaint__c>) Trigger.old) {
                oldComplaint = cmpl;
                break;
            }

            if (newComplaint.Customer_Reply_Required__c!=oldComplaint.Customer_Reply_Required__c && newComplaint.Ticket_Type__c =='Complaint') {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}