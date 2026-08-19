/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TicketCustomerReplyRequestMDCCustom
* @Why   : Global class to check if Customer Reply Requested? field is changed in ticket.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    09-Jan-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-Dec-2019            Defect #1439         Modified.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketCustomerReplyRequestMDCCustom implements CMPL123.IMDCCustomValidation {
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
            CMPL123CME__Complaint__c newComplaint = (CMPL123CME__Complaint__c) newRecord;
            CMPL123CME__Complaint__c oldComplaint = (CMPL123CME__Complaint__c) oldRecord;
            TicketQDNumMDCCustom.setDefaults(newComplaint.Id);
            //Added : W-000150; Modified due to Defect #1439
            return newComplaint.Customer_Reply_Required__c != oldComplaint.Customer_Reply_Required__c 
                    && newComplaint.Customer_Reply_Required__c == true 
                    && TicketQDNumMDCCustom.isTicketInquiry == true;
        }
        return false;
    }
}