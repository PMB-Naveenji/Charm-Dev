/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : TranslationTaskWithTckMedEvalMDCCustom
* @Why   : Global class to check if ticket Ticket description field is changed to check the MDC trigger
           record creation.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID       Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    13-Jan-2017            Work ID / Case ID     Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
*                                                                         event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class TicketDescInquiryMDCCustom implements CMPL123.IMDCCustomValidation {
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
            //CMPL123CME__Complaint__c newTicket = (CMPL123CME__Complaint__c)Trigger.new[0];
            //CMPL123CME__Complaint__c oldTicket = (CMPL123CME__Complaint__c)Trigger.old[0];
            CMPL123CME__Complaint__c newTicket,oldTicket;
            for(CMPL123CME__Complaint__c cmpl : (List<CMPL123CME__Complaint__c>)Trigger.new){
                newTicket = cmpl;
                break;
            }
            for(CMPL123CME__Complaint__c cmpl : (List<CMPL123CME__Complaint__c>)Trigger.old){
                oldTicket = cmpl;
                break;
            }

            TicketQDNumMDCCustom.setDefaults(newTicket.Id);
            return newTicket.Ticket_Description__c != oldTicket.Ticket_Description__c && TicketQDNumMDCCustom.inquiryTT == true;
        }
        return false;

    }
}