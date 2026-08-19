/*
    Description : Global class to check if Product-Ticket Batch/Lot/Serial#,List Number
                  fields are changed and if yes create the MDC trigger record.
    Created On  : 13th NOV 2018
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *  Modification Log:
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Developer                Date                   Modification ID       Description
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   Admin                    13-NOV-2018            N/A                   Created.
 *  --------------------------------------------------------------------------------------------------------------------------------------
 *   RSlob                    04-JAN-2021            TWD Upgrade Issues    Modified entry condition to execute MDC logic at beforeUpdate
 *                                                                         event instead of after update. Formatting.
 *  --------------------------------------------------------------------------------------------------------------------------------------
*/
global class PTInquiryProductListMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From Product-Ticket Change for Evaluator/Investigator MDC Trigger
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

            if(TicketQDNumMDCCustom.inquiryTT == null){
                TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
            }
            return TicketQDNumMDCCustom.inquiryTT != null 
                    &&  TicketQDNumMDCCustom.inquiryTT  
                    && newProductTicket.Product_List_Number_Static__c != oldProductTicket.Product_List_Number_Static__c;
        }
        return false;
    }
}