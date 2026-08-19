/**
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2021  Sparta Systems, Inc.
* @What  : PTWithProdEvalFeildsMDCCustom
* @Why   : Global class to check if Product-Ticket Batch/Lot/Serial#,List Number and Likely Cause
           fields are changed and if parent ticket has prod eval chils records
            and if yes create the MDC trigger record.
* @When  : 05-JAN-2021
* @Where : From Audit Class
*  --------------------------------------------------------------------------------------------------------------------------------------
*  Modification Log:
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                Date                   Modification ID      Description
*  --------------------------------------------------------------------------------------------------------------------------------------
*   Admin                    16-JAN-2017            Work ID / Case ID    Created.
*  --------------------------------------------------------------------------------------------------------------------------------------
*   RSlob                    05-JAN-2021            TWD Upgrade Issues   Modified entry condition to execute MDC logic at beforeUpdate
*                                                                        event instead of after update. Formatting.
*  --------------------------------------------------------------------------------------------------------------------------------------
**/
global class PTWithProdEvalFeildsMDCCustom implements CMPL123.IMDCCustomValidation {
    /**
    * @Method       : CustomValidation
    * @Invoke       : From TranslationTaskWithTckMedEvalMDCCustom Class
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

            if (newProductTicket.Product_List_Number_Static__c != oldProductTicket.Product_List_Number_Static__c) {
                if (TicketQDNumMDCCustom.hasProdEval == null) {
                    TicketQDNumMDCCustom.setDefaults(newProductTicket.Event_Ticket__c);
                }
                return TicketQDNumMDCCustom.hasProdEval != null && TicketQDNumMDCCustom.hasProdEval;
            }
        }
        return false;
    }
}