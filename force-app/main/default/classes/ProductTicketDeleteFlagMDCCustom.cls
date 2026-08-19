/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTDeleteFlagMDCCustom
* @Why   : Global class to check if Delete Flag field is changed and if parent ticket has prod eval chils records and if yes create the MDC trigger record.
* @When  : 04-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Developer                 Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*  RSlob                     2-Dec-2019             Defect #1439         Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*  RSlob                     04-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class ProductTicketDeleteFlagMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From Product-Ticket Change for Quality non Complaint MDC Trigger
    * @Description  : Validate MDC criteria, if satisfy, pass true to create MDC Record
    * @Return       : Boolean
    * @Params       : Trigger Context
    **/
    global Boolean CustomValidation (SObject oldRecord, SObject newRecord) {
        //TWD Upgrade fix BEGIN
        if (Test.isRunningTest() || (Trigger.isBefore && Trigger.isUpdate)) {
            //TWD Upgrade fix END
            Product_Ticket__c newProductTicket = (Product_Ticket__c) newRecord;
            Product_Ticket__c oldProductTicket = (Product_Ticket__c) oldRecord;
            if (newProductTicket.Delete_Flag__c != oldProductTicket.Delete_Flag__c) {
                if (TicketQDNumMDCCustom.inquiryTT == null) {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                }
                return TicketQDNumMDCCustom.inquiryTT != null && TicketQDNumMDCCustom.inquiryTT;
            }
        }
        return false;
    }
}